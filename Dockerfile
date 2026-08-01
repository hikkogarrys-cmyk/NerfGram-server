FROM golang:1.25 AS builder

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 go build -o /build/telesrv ./cmd/telesrv

FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y ca-certificates

WORKDIR /app

COPY --from=builder /build/telesrv /app/telesrv
COPY . .

EXPOSE 8080

CMD ["/app/telesrv"]
