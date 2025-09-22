# Scripts de Automatización - Arquitectura de Microservicios

Esta carpeta contiene scripts automatizados para gestionar completamente la arquitectura de microservicios con patrones de diseño en la nube.

## 📋 **SCRIPTS DISPONIBLES**

### ** 1. CONFIGURACIÓN Y SETUP**
```bash
./setup.sh
```
- **Función**: Configura y define la arquitectura completa
- **Qué hace**: Verifica Docker, construye imágenes, prepara el entorno
- **Cuándo usar**: Primera vez o después de cambios en código

---

### ** 2. DEPLOYMENT Y EJECUCIÓN**  
```bash
./deploy.sh
```
- **Función**: Despliega toda la arquitectura con autoscaling
- **Qué hace**: Inicia servicios, escala instancias, verifica patrones
- **Cuándo usar**: Para iniciar el entorno completo

---

### ** 3. TESTING AUTOMATIZADO**
```bash
./test-patterns.sh
```
- **Función**: Prueba sistemáticamente todos los patrones
- **Qué hace**: Tests de API Gateway, Cache-Aside, Autoscaling, Performance
- **Cuándo usar**: Para verificar que todo funciona correctamente

---

### ** 4. MONITOREO EN TIEMPO REAL**
```bash
./monitor.sh
```
- **Función**: Dashboard interactivo de monitoreo
- **Qué hace**: Métricas en vivo, health checks, estadísticas de cache
- **Cuándo usar**: Para observar el comportamiento del sistema

---

### ** 5. LIMPIEZA Y RESET**
```bash
./cleanup.sh
```
- **Función**: Limpia y resetea el entorno
- **Qué hace**: Múltiples opciones de limpieza (suave, completa, total)
- **Cuándo usar**: Para limpiar el entorno o solucionar problemas

---

## **FLUJO DE USO RECOMENDADO**
### ** Primera vez / Setup inicial:**
```bash
# 1. Configurar arquitectura
./setup.sh

# 2. Desplegar servicios  
./deploy.sh

# 3. Probar patrones
./test-patterns.sh

# 4. Monitorear (opcional)
./monitor.sh
```
---

## 📊 **OUTPUTS Y RESULTADOS**

### **✅ Indicadores de Éxito:**
- ✅ Verde: Operación exitosa
- ⏳ Amarillo: En progreso  
- ❌ Rojo: Error o falla
- ℹ️ Azul: Información
- ⚠️ Amarillo: Advertencia

### **📈 Métricas Monitoreadas:**
- **Contenedores**: Estado, puertos, salud
- **Performance**: Tiempos de respuesta, throughput
- **Cache**: Hits, misses, memoria usada
- **Autoscaling**: Número de instancias activas
- **Load Balancing**: Distribución de requests

---

## 🔧 **CONFIGURACIÓN DE SCRIPTS**

### **Prerrequisitos:**
- ✅ Docker Desktop instalado y ejecutándose
- ✅ Bash shell (Git Bash, WSL, Linux, macOS)
- ✅ curl (para tests de endpoints)

### **Ejecución en Windows:**
```bash
# Usar Git Bash o WSL
# Los scripts funcionan directamente en Linux/macOS
```

### **Variables Configurables:**
Los scripts usan estas configuraciones por defecto:
- **Users API**: 3 instancias
- **Todos API**: 2 instancias  
- **Auth API**: 1 instancia
- **Cache TTL**: 3600 segundos
- **Health Check Timeout**: 30 segundos

---

