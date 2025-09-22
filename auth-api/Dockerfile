# Build stage
FROM golang:1.18-alpine AS builder

WORKDIR /app

# Install git for go modules
RUN apk add --no-cache git

# Copy source code first
COPY . .

# Initialize go module and download dependencies
ENV GO111MODULE=on
RUN go mod init github.com/bortizf/microservice-app-example/tree/master/auth-api || true
RUN go mod tidy
RUN go mod download

# Build the application
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o auth-api .

# Final stage
FROM alpine:latest

RUN apk --no-cache add ca-certificates
WORKDIR /root/

# Copy the binary from builder stage
COPY --from=builder /app/auth-api .

# Expose port
EXPOSE 8000

# Run the application
CMD ["./auth-api"] 