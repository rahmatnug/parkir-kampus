# Stage 1: Build the static, optimized Go binary
FROM golang:1.26-alpine AS builder

# Install build tools and standard libraries
RUN apk add --no-cache git gcc musl-dev

WORKDIR /app

# Copy module configurations first to cache dependency layers
COPY go.mod go.sum ./
RUN go mod download

# Copy the entire backend source code
COPY . .

# Compile static binary with optimization flags to strip debug logs/size (-s -w)
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o parkir-kampus-api cmd/api/main.go

# Stage 2: Final minimal production image
FROM alpine:latest

# Install basic SSL certificates and timezone configurations for production stability
RUN apk add --no-cache ca-certificates tzdata

WORKDIR /app

# Copy compiled binary from building stage
COPY --from=builder /app/parkir-kampus-api .
# Copy environment configuration file if populated
COPY --from=builder /app/.env* ./

EXPOSE 8080

CMD ["./parkir-kampus-api"]
