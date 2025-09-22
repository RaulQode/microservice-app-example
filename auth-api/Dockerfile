# Imagen final minimalista - Solo copia el binario ya compilado
FROM alpine:latest

RUN apk --no-cache add ca-certificates
WORKDIR /root/

# Copiar el binario ya compilado desde Jenkins
COPY auth-api .

# Expose port
EXPOSE 8000

# Run the application
CMD ["./auth-api"] 