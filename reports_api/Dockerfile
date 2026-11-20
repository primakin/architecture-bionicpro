# ---------- Stage 1: build ----------
FROM golang:1.26-alpine AS builder

RUN apk add --no-cache git ca-certificates

WORKDIR /src

COPY go.mod go.sum ./
RUN go mod download

COPY . .

ENV CGO_ENABLED=0
ENV GOOS=linux

RUN go build -trimpath -ldflags="-s -w" -o /out/reports-service .

# ---------- Stage 2: runtime ----------
FROM alpine:3.20

RUN apk add --no-cache ca-certificates tzdata \
    && addgroup -S app \
    && adduser -S -G app app

WORKDIR /app

COPY --from=builder /out/reports-service /app/reports-service

USER app

EXPOSE 8080

ENTRYPOINT ["/app/reports-service"]