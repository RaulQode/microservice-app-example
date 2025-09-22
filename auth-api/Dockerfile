# Multi-stage build optimizado
FROM golang:1.22-alpine AS builder

WORKDIR /app

# Install git for go modules
RUN apk add --no-cache git

# Copy go mod files first for better caching
COPY go.mod go.sum ./

# Download dependencies (this layer will be cached if go.mod/go.sum don't change)
ENV GO111MODULE=on
RUN go mod download

# Copy source code
COPY . .

# Build the application only if auth-api binary doesn't exist
RUN if [ ! -f auth-api ]; then \
        CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o auth-api .; \
    fi

# Final stage - minimal alpine image
FROM alpine:latest

RUN apk --no-cache add ca-certificates
WORKDIR /root/

# Copy the binary from builder stage
COPY --from=builder /app/auth-api .

# Expose port
EXPOSE 8000

# Run the application
CMD ["./auth-api"] 