# Build en el Dockerfile (más simple y confiable)
FROM golang:1.22-alpine AS builder

WORKDIR /app

# Instalar git
RUN apk add --no-cache git

# Copiar archivos go.mod primero para cache
COPY go.mod go.sum ./

# Solo si hay conexión, sino usar dependencias locales
RUN go mod download || echo "Usando dependencias locales"

# Copiar todo el código fuente
COPY . .

# Compilar el binario
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o auth-api .

# Imagen final mínima
FROM alpine:latest

RUN apk --no-cache add ca-certificates
WORKDIR /root/

# Copiar el binario desde la etapa de build
COPY --from=builder /app/auth-api .

# Hacer ejecutable por si acaso
RUN chmod +x auth-api

EXPOSE 8000

CMD ["./auth-api"] 