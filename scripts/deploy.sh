#!/bin/bash
# Este script despliega toda la arquitectura con autoscaling

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Funciones auxiliares
show_progress() {
    echo -e "${YELLOW}⏳ $1...${NC}"
}

show_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

show_error() {
    echo -e "${RED}❌ $1${NC}"
}

show_info() {
    echo -e "${CYAN}ℹ️  $1${NC}"
}

wait_for_service() {
    local url=$1
    local service_name=$2
    local max_attempts=${3:-30}
    
    show_progress "Esperando que $service_name esté listo"
    
    for i in $(seq 1 $max_attempts); do
        if curl -sf "$url" >/dev/null 2>&1; then
            show_success "$service_name está listo"
            return 0
        fi
        printf "${YELLOW}.${NC}"
        sleep 2
    done
    echo ""
    show_error "$service_name no respondió después de $((max_attempts * 2)) segundos"
    return 1
}

echo -e "${CYAN}🚀 DESPLEGANDO ARQUITECTURA DE MICROSERVICIOS${NC}"
echo -e "${CYAN}==============================================${NC}"

# FASE 1: Deployment básico
echo ""
echo -e "${MAGENTA}📦 FASE 1: DEPLOYMENT BÁSICO${NC}"
show_progress "Iniciando servicios base"

if docker-compose up -d; then
    show_success "Servicios base iniciados"
else
    show_error "Error iniciando servicios base"
    exit 1
fi

# Esperar servicios críticos
wait_for_service "http://localhost/health" "API Gateway"
wait_for_service "http://localhost:9411/health" "Zipkin"

# FASE 2: Autoscaling
echo ""
echo -e "${MAGENTA}📈 FASE 2: AUTOSCALING PATTERN${NC}"
show_progress "Escalando Users API a 3 instancias"
docker-compose up -d --scale users-api=3

show_progress "Escalando Todos API a 2 instancias"  
docker-compose up -d --scale users-api=3 --scale todos-api=2

sleep 5

# Verificar escalado
show_success "Autoscaling completado:"
docker-compose ps | grep -E "(users-api|todos-api)" | while read line; do
    echo -e "${GREEN}$line${NC}"
done

# FASE 3: Verificación de patrones
echo ""
echo -e "${MAGENTA}🎯 FASE 3: VERIFICACIÓN DE PATRONES${NC}"

# 1. API Gateway Pattern
show_progress "Verificando API Gateway Pattern"
if curl -sf "http://localhost/health" >/dev/null 2>&1; then
    show_success "✅ API Gateway Pattern: FUNCIONANDO"
else
    show_error "❌ API Gateway Pattern: ERROR"
fi

# 2. Cache-Aside Pattern
show_progress "Verificando Cache-Aside Pattern"
if docker-compose ps redis | grep -q "healthy\|Up"; then
    show_success "✅ Cache-Aside Pattern: Redis HEALTHY"
else
    show_error "❌ Cache-Aside Pattern: Redis ERROR"
fi

# 3. Autoscaling Pattern
show_progress "Verificando Autoscaling Pattern"
users_count=$(docker-compose ps users-api | grep -c "users-api")
todos_count=$(docker-compose ps todos-api | grep -c "todos-api")

if [ "$users_count" -ge 3 ] && [ "$todos_count" -ge 2 ]; then
    show_success "✅ Autoscaling Pattern: $users_count Users API + $todos_count Todos API"
else
    show_error "❌ Autoscaling Pattern: Escalado insuficiente"
fi

# FASE 4: Resumen final
echo ""
echo -e "${GREEN}🏆 DEPLOYMENT COMPLETADO${NC}"
echo -e "${GREEN}========================${NC}"
echo -e "🌐 Aplicación:     http://localhost/"
echo -e "🔧 API Gateway:    http://localhost:8888/"  
echo -e "📊 Zipkin:         http://localhost:9411/"
echo -e "🎯 Health Check:   http://localhost/health"
echo ""
echo -e "${YELLOW}🧪 Ejecuta './test-patterns.sh' para probar los patrones${NC}"
echo -e "${YELLOW}📊 Ejecuta './monitor.sh' para monitoreo en tiempo real${NC}"
