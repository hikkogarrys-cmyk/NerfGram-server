# ==========================================
# Этап 1: Сборка (Builder)
# ==========================================
FROM golang:1.25-alpine AS builder

# Устанавливаем git и ca-certificates для скачивания зависимостей
RUN apk add --no-cache git ca-certificates

WORKDIR /app

# Копируем файлы модулей для кэширования слоя Docker (ускоряет повторные сборки)
COPY go.mod go.sum ./
RUN go mod download

# Копируем весь исходный код
COPY . .

# Собираем оба бинарных файла с отключенным CGO для статической линковки 
# (это делает их маленькими и независимыми от системных библиотек ОС)
# Флаги -ldflags="-w -s" удаляют отладочную информацию, уменьшая размер
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-w -s" -o /build/gramsrv ./cmd/telesrv
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-w -s" -o /build/telesrv-admin ./cmd/telesrv-admin

# ==========================================
# Этап 2: Финальный минимальный образ
# ==========================================
FROM alpine:latest

# Устанавливаем корневые сертификаты (ОБЯЗАТЕЛЬНО для HTTPS запросов к Supabase/Upstash) 
# и часовые пояса (для корректного времени в логах и токенах)
RUN apk --no-cache add ca-certificates tzdata

WORKDIR /app

# Копируем только собранные бинарные файлы из этапа builder
COPY --from=builder /build/gramsrv /app/gramsrv
COPY --from=builder /build/telesrv-admin /app/telesrv-admin

# Делаем их исполняемыми
RUN chmod +x /app/gramsrv /app/telesrv-admin

# Команду запуска мы укажем прямо в интерфейсе NorthFlank для каждого сервиса отдельно
