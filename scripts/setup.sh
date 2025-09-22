#!/bin/bash
# Este script define y configura toda la arquitectura de microservicios

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

echo -e "${CYAN}🏗️  CONFIGURANDO ARQUITECTURA DE MICROSERVICIOS${NC}"
echo -e "${CYAN}=================================================${NC}"

# Verificar que Docker está corriendo
show_progress "Verificando Docker"
if ! command -v docker &> /dev/null; then
    show_error "Docker no está instalado. Por favor, instala Docker primero"
    exit 1
fi

if ! docker version &> /dev/null; then
    show_error "Docker no está corriendo. Por favor, inicia Docker"
    exit 1
fi

show_success "Docker está corriendo"

# Limpiar contenedores previos
show_progress "Limpiando contenedores previos"
docker-compose down --remove-orphans 2>/dev/null
show_success "Limpieza completada"

# Construir imágenes
show_progress "Construyendo imágenes Docker"
if docker-compose build; then
    show_success "Todas las imágenes construidas exitosamente"
else
    show_error "Error construyendo imágenes"
    exit 1
fi

echo ""
echo -e "${MAGENTA}🎯 DEFINICIÓN DE PATRONES IMPLEMENTADOS:${NC}"
echo -e "${MAGENTA}========================================${NC}"
echo -e "✅ 1. ${CYAN}🌐 API Gateway Pattern${NC}   → Nginx (Puerto 80/8888)"
echo -e "✅ 2. ${CYAN}🚀 Cache-Aside Pattern${NC}   → Redis + Spring Boot"  
echo -e "✅ 3. ${CYAN}📈 Autoscaling Pattern${NC}   → Docker Compose Scaling"
echo -e "✅ 4. ${CYAN}🔍 Tracing Pattern${NC}       → Zipkin (Puerto 9411)"
echo ""

echo -e "${GREEN}🏆 ARQUITECTURA LISTA PARA DEPLOYMENT${NC}"
echo -e "${YELLOW}Ejecuta './deploy.sh' para iniciar todos los servicios${NC}"
