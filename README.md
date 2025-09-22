# 🏗️ Microservice App - Arquitectura Cloud-Native

Aplicación TODO diseñada con **arquitectura de microservicios** que implementa **patrones de diseño en la nube** para demostrar escalabilidad, alta disponibilidad y optimización de rendimiento.

## 🎯 **CARACTERÍSTICAS PRINCIPALES**

- **🌐 API Gateway Pattern**: Nginx como punto único de entrada con load balancing
- **🚀 Cache-Aside Pattern**: Redis para optimización de consultas
- **📈 Autoscaling Pattern**: Escalado horizontal automático
- **🔍 Distributed Tracing**: Zipkin para monitoreo
- **🛡️ Security**: JWT tokens y filtros de autenticación
- **🏗️ Multi-lenguaje**: Go, Python, Java, Node.js, Vue.js

---

## 📦 **COMPONENTES DE LA APLICACIÓN**

| Servicio | Tecnología | Puerto | Función |
|----------|------------|--------|---------|
| **API Gateway** | Nginx 1.29.1 | 80, 8888 | Punto único de entrada y load balancer |
| **Users API** | Spring Boot + Redis | 8083 | Gestión de perfiles de usuario con cache |
| **Auth API** | Go + JWT | 8000 | Autenticación y autorización |
| **Todos API** | Node.js + Express | 8082 | CRUD de tareas TODO |
| **Frontend** | Vue.js | 8080 | Interfaz de usuario |
| **Log Processor** | Python | - | Procesador de colas Redis |
| **Redis** | Redis 7.0 | 6379 | Cache y cola de mensajes |
| **Zipkin** | Zipkin 2.23.19 | 9411 | Tracing distribuido |

---

## 🚀 **INICIO RÁPIDO**

### **🎮 OPCIÓN 1: Scripts Automatizados (RECOMENDADO)**
```bash

# O ejecutar scripts individuales:
./setup.sh      # Configurar arquitectura  
./deploy.sh     # Desplegar con autoscaling
./test-patterns.sh  # Probar todos los patrones
./monitor.sh    # Monitoreo en tiempo real
```

### **⚡ OPCIÓN 2: Manual (Comandos Docker)**
```bash
# 1. Arrancar servicios
docker-compose up -d

# 2. Autoscaling
docker-compose up -d --scale users-api=3 --scale todos-api=2

# 3. Verificar estado
docker-compose ps
curl http://localhost/health
```

### **🌐 Acceso a la aplicación:**
```
🌐 Aplicación:      http://localhost/
📊 Zipkin:          http://localhost:9411/
🔧 API Gateway:     http://localhost:8888/
❤️  Health Check:   http://localhost/health
```

---

## 📈 **AUTOSCALING (Escalado Horizontal)**

### **Comandos de Escalado:**
```bash
# Escalar Users API a 3 instancias
docker-compose up -d --scale users-api=3

# Escalar múltiples servicios
docker-compose up -d --scale users-api=3 --scale todos-api=2

# Ver instancias escaladas
docker-compose ps
```

### **Load Balancer:**
El **Nginx API Gateway** distribuye automáticamente el tráfico entre todas las instancias usando **round-robin**.

---

## 🎯 **PATRONES DE DISEÑO IMPLEMENTADOS**

### **1. 🌐 API Gateway Pattern**
- **Punto único de entrada** para todos los servicios
- **Load balancing** automático con health checks
- **Routing inteligente** por rutas `/api/*`

### **2. 🚀 Cache-Aside Pattern**  
- **Redis integration** en Users API
- **Cache TTL** configurable (3600s por defecto)
- **Logging detallado** de Cache HIT/MISS

### **3. 📈 Autoscaling Pattern**
- **Escalado horizontal** con Docker Compose  
- **Puertos dinámicos** para múltiples instancias
- **Service discovery** automático

---

## 🔧 **ARQUITECTURA TÉCNICA**

### **Comunicación entre servicios:**
```
[Frontend] → [API Gateway] → [Backend Services]
                ↓
            [Load Balancer]
                ↓
    [Users API] ←→ [Redis Cache]
    [Todos API] ←→ [Redis Queue]  
    [Auth API]  ←→ [JWT Validation]
```

### **Cache Strategy:**
- **Cache-Aside** en Users API
- **Redis** como store principal
- **TTL automático** y **eviction policy**

---

## 🛠️ **DESARROLLO Y TESTING**

### **Logs en tiempo real:**
```bash
# Ver logs del API Gateway
docker-compose logs -f nginx-gateway

# Ver logs del cache
docker-compose logs users-api | grep -E "Cache (HIT|MISS)"

# Ver todas las instancias
docker-compose logs --tail=50
```

### **Health Monitoring:**
```bash
# Status de servicios
docker-compose ps

# Métricas de recursos  
docker stats

# Health endpoints
curl http://localhost/api/users/health
curl http://localhost/api/todos/health
```

---

## 📚 **ENDPOINTS PRINCIPALES**

### **API Gateway (Puerto 80):**
```
GET  /health                    # Health check del gateway
GET  /                         # Frontend application  
GET  /api/users/*              # Proxy a Users API
GET  /api/todos/*              # Proxy a Todos API  
POST /api/auth/*               # Proxy a Auth API
```

### **Cache Endpoints:**
```
GET  /api/users/1              # Genera Cache MISS → Cache HIT
GET  /api/users                # Lista con cache optimization
```

---

## 🔒 **SEGURIDAD**

- **JWT Authentication** en Auth API
- **CORS configurado** para desarrollo
- **Security filters** en Users API
- **Network isolation** con Docker networks

---

## 📊 **MONITOREO**

### **Zipkin Tracing:**
- **URL**: `http://localhost:9411/`
- **Traces distribuidos** entre servicios
- **Performance monitoring** automático

### **Redis Monitoring:**
```bash
# Conectar a Redis
docker-compose exec redis redis-cli

# Ver keys del cache
KEYS user:*

# Monitorear comandos
MONITOR
```

---

## 🚨 **TROUBLESHOOTING**

### **Problemas comunes:**

**1. Puerto ocupado:**
```bash
docker-compose down
netstat -ano | findstr :80
```

**2. Cache no funciona:**
```bash
docker-compose logs redis
docker-compose logs users-api | grep Redis
```

**3. Load balancer no distribuye:**
```bash
docker-compose logs nginx-gateway
curl -v http://localhost/api/users/
```

---

## 📋 **COMANDOS ÚTILES**

```bash
# Reinicio completo
docker-compose down && docker-compose up -d

# Rebuild con cambios
docker-compose up -d --build

# Logs específicos
docker-compose logs [service-name]

# Shell en contenedor
docker-compose exec [service-name] bash

# Estadísticas
docker stats --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}"
```
---

## 🎯 **PRÓXIMOS PASOS**

1. **CI/CD Pipeline** con Jenkins configurado
2. **Kubernetes deployment** para producción  
3. **API Rate Limiting** en Gateway
4. **Database clustering** para alta disponibilidad
5. **Metrics con Prometheus** y Grafana

---

## 🏆 **ARQUITECTURA CLOUD-READY**

Esta implementación demuestra **patrones de diseño enterprise** listos para **producción en la nube**, con escalabilidad, observabilidad y alta disponibilidad incorporadas.

![Arquitectura Microservicios](/arch-img/Microservices.png)