FROM golang:1.25 AS builder

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN mkdir -p /build

RUN CGO_ENABLED=0 go build -o /build/gramsrv ./cmd/telesrv
RUN CGO_ENABLED=0 go build -o /build/telesrv-admin ./cmd/telesrv-admin

FROM debian:bookworm-slim

RUN apt-get update && \
    apt-get install -y ca-certificates && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --from=builder /build/gramsrv .
COPY --from=builder /build/telesrv-admin .
COPY .env .

EXPOSE 8080

CMD sh -c "./gramsrv & ./telesrv-admin" 
