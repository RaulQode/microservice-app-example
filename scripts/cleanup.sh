#!/bin/bash
# Este script limpia completamente el entorno

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

show_progress() {
    echo -e "${YELLOW}⏳ $1...${NC}"
}

show_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

show_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

show_error() {
    echo -e "${RED}❌ $1${NC}"
}

echo -e "${CYAN}🧹 LIMPIEZA COMPLETA DEL ENTORNO${NC}"
echo -e "${CYAN}================================${NC}"

echo ""
echo -e "${YELLOW}🗑️  OPCIONES DE LIMPIEZA:${NC}"
echo "1. 🔄 Restart suave (mantener volúmenes)"
echo "2. 🧹 Limpieza completa (eliminar contenedores y volúmenes)"
echo "3. 💥 Reset total (incluir imágenes Docker)"
echo "4. 🚀 Limpieza + Rebuild automático"
echo "0. ❌ Cancelar"
echo ""

read -p "Selecciona una opción (1-4, 0 para cancelar): " choice

case $choice in
    1) 
        echo ""
        echo -e "${GREEN}🔄 RESTART SUAVE${NC}"
        echo -e "${GREEN}===============${NC}"
        
        show_progress "Deteniendo contenedores"
        docker-compose stop
        show_success "Contenedores detenidos"
        
        show_progress "Reiniciando servicios"  
        docker-compose start
        show_success "Servicios reiniciados"
        
        echo ""
        show_success "✅ Restart completado. Los datos se mantuvieron."
        echo -e "${YELLOW}🚀 Ejecuta './deploy.sh' si necesitas reescalar servicios${NC}"
        ;;
    
    2)
        echo ""
        echo -e "${YELLOW}🧹 LIMPIEZA COMPLETA${NC}"
        echo -e "${YELLOW}===================${NC}"
        show_warning "Esto eliminará todos los contenedores y volúmenes"
        
        read -p "¿Estás seguro? (y/N): " confirm
        if [[ $confirm == "y" || $confirm == "Y" ]]; then
            show_progress "Deteniendo y eliminando contenedores"
            docker-compose down --remove-orphans
            
            show_progress "Eliminando volúmenes"
            docker-compose down --volumes
            
            show_progress "Limpiando networks huérfanas"
            docker network prune -f >/dev/null 2>&1
            
            show_success "✅ Limpieza completa terminada"
            echo -e "${YELLOW}🚀 Ejecuta './setup.sh' y './deploy.sh' para reiniciar${NC}"
        else
            show_warning "Operación cancelada"
        fi
        ;;
    
    3)
        echo ""
        echo -e "${RED}💥 RESET TOTAL${NC}"
        echo -e "${RED}=============${NC}"
        show_warning "Esto eliminará TODO: contenedores, volúmenes E IMÁGENES"
        show_warning "Tendrás que reconstruir todo desde cero"
        
        read -p "¿Estás COMPLETAMENTE seguro? (y/N): " confirm
        if [[ $confirm == "y" || $confirm == "Y" ]]; then
            show_progress "Deteniendo todos los contenedores"
            docker-compose down --remove-orphans --volumes
            
            show_progress "Eliminando imágenes del proyecto"
            images=$(docker images --filter "reference=microservice-app-example*" -q)
            if [ -n "$images" ]; then
                docker rmi $images -f >/dev/null 2>&1
                show_success "Imágenes del proyecto eliminadas"
            fi
            
            show_progress "Limpiando Docker system"
            docker system prune -f >/dev/null 2>&1
            
            show_success "✅ Reset total completado"
            echo -e "${YELLOW}🚀 Ejecuta './setup.sh' para reconstruir desde cero${NC}"
        else
            show_warning "Operación cancelada"
        fi
        ;;
    
    4)
        echo ""
        echo -e "${MAGENTA}🚀 LIMPIEZA + REBUILD AUTOMÁTICO${NC}"
        echo -e "${MAGENTA}===============================${NC}"
        
        show_progress "Limpiando entorno actual"
        docker-compose down --remove-orphans --volumes
        
        show_progress "Reconstruyendo imágenes"
        docker-compose build --no-cache
        
        show_progress "Iniciando servicios limpios"
        docker-compose up -d
        
        show_progress "Aplicando autoscaling por defecto"
        sleep 5
        docker-compose up -d --scale users-api=3 --scale todos-api=2
        
        show_success "✅ Rebuild automático completado"
        echo -e "${YELLOW}🧪 Ejecuta './test-patterns.sh' para verificar${NC}"
        ;;
    
    0)
        show_warning "Operación cancelada"
        exit 0
        ;;
    
    *)
        show_error "Opción inválida"
        exit 1
        ;;
esac

# Información adicional de limpieza
echo ""
echo -e "${CYAN}🔧 COMANDOS ADICIONALES DE LIMPIEZA:${NC}"
echo -e "${CYAN}====================================${NC}"
echo "• docker system df           # Ver espacio usado por Docker"
echo "• docker system prune -a     # Limpiar todo Docker (cuidado!)"
echo "• docker volume ls           # Ver volúmenes existentes"
echo "• docker network ls          # Ver redes existentes"

# Status final
echo ""
show_progress "Verificando estado final"
if running_containers=$(docker-compose ps --services --filter "status=running" 2>/dev/null) && [ -n "$running_containers" ]; then
    count=$(echo "$running_containers" | wc -l)
    show_success "$count servicios aún ejecutándose"
    echo -e "${YELLOW}📊 Ejecuta './monitor.sh' para ver el estado${NC}"
else
    show_success "Entorno completamente limpio"
    echo -e "${YELLOW}🚀 Ejecuta './deploy.sh' para iniciar servicios${NC}"
fi
