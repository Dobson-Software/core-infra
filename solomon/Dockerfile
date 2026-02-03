# Build stage
FROM golang:1.22-alpine AS builder

RUN apk add --no-cache git ca-certificates

WORKDIR /app

# Download dependencies
COPY go.mod go.sum ./
RUN go mod download

# Build
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-w -s" -o /solomon ./cmd/solomon

# Final stage
FROM alpine:3.19

RUN apk add --no-cache ca-certificates tzdata

# Create non-root user
RUN addgroup -g 1000 solomon && \
    adduser -u 1000 -G solomon -s /bin/sh -D solomon

WORKDIR /app

COPY --from=builder /solomon .
COPY --from=builder /app/migrations ./migrations

RUN chown -R solomon:solomon /app

USER solomon

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD wget -qO- http://localhost:8080/health || exit 1

ENTRYPOINT ["./solomon"]
