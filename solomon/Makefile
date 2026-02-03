.PHONY: build run test lint migrate docker-build docker-run clean

# Variables
BINARY_NAME=solomon
VERSION?=dev
COMMIT=$(shell git rev-parse --short HEAD 2>/dev/null || echo "unknown")
BUILD_TIME=$(shell date -u +"%Y-%m-%dT%H:%M:%SZ")
LDFLAGS=-ldflags "-X main.version=$(VERSION) -X main.commit=$(COMMIT) -X main.buildTime=$(BUILD_TIME)"

# Go commands
build:
	go build $(LDFLAGS) -o bin/$(BINARY_NAME) ./cmd/solomon

run:
	go run ./cmd/solomon

test:
	go test -v -race -cover ./...

test-coverage:
	go test -v -race -coverprofile=coverage.out ./...
	go tool cover -html=coverage.out -o coverage.html

lint:
	golangci-lint run ./...

# Database migrations
migrate-up:
	migrate -path migrations -database "$(DATABASE_URL)" up

migrate-down:
	migrate -path migrations -database "$(DATABASE_URL)" down 1

migrate-create:
	@read -p "Migration name: " name; \
	migrate create -ext sql -dir migrations -seq $$name

# Docker
docker-build:
	docker build -t solomon:$(VERSION) .

docker-run:
	docker-compose up -d

docker-down:
	docker-compose down

# Frontend
web-install:
	cd web && pnpm install

web-dev:
	cd web && pnpm dev

web-build:
	cd web && pnpm build

# Development
dev:
	@echo "Starting development environment..."
	docker-compose -f docker-compose.dev.yml up -d postgres redis
	@sleep 2
	$(MAKE) migrate-up
	@echo "Starting API server..."
	$(MAKE) run

# Clean
clean:
	rm -rf bin/
	rm -rf web/dist/
	rm -f coverage.out coverage.html

# Generate
generate:
	go generate ./...

# All
all: lint test build
