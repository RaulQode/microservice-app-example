#!/bin/bash
# 📊 Script de Monitoreo en Tiempo Real
# Este script proporciona monitoreo continuo de la arquitectura

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

show_header() {
    clear
    echo -e "${CYAN}📊 $1${NC}"
    echo -e "${CYAN}$(printf '=%.0s' {1..50})${NC}"
    echo -e "${YELLOW}⏰ $(date '+%H:%M:%S')${NC}"
    echo ""
}

get_service_status() {
    docker-compose ps --format "table {{.Name}}\t{{.Service}}\t{{.State}}\t{{.Ports}}"
}

get_resource_usage() {
    if command -v docker &> /dev/null; then
        docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}" 2>/dev/null || echo "Stats no disponibles"
    else
        echo "Docker no disponible"
    fi
}

test_endpoints() {
    declare -A endpoints=(
        ["API Gateway"]="http://localhost/health"
        ["Users API"]="http://localhost/api/users/"
        ["Zipkin"]="http://localhost:9411/health"
    )
    
    for name in "${!endpoints[@]}"; do
        url=${endpoints[$name]}
        start_time=$(date +%s%3N)
        if curl -sf "$url" >/dev/null 2>&1; then
            end_time=$(date +%s%3N)
            time=$((end_time - start_time))
            echo -e "✅ $name : ${time}ms"
        else
            echo -e "❌ $name : ERROR"
        fi
    done
}

get_cache_stats() {
    if docker-compose ps redis | grep -q "Up\|healthy"; then
        keys_count=$(docker-compose exec -T redis redis-cli KEYS "*" 2>/dev/null | wc -l || echo "0")
        memory=$(docker-compose exec -T redis redis-cli INFO memory 2>/dev/null | grep "used_memory_human" | cut -d: -f2 | tr -d '\r' || echo "N/A")
        hits=$(docker-compose exec -T redis redis-cli INFO stats 2>/dev/null | grep "keyspace_hits" | cut -d: -f2 | tr -d '\r' || echo "0")
        misses=$(docker-compose exec -T redis redis-cli INFO stats 2>/dev/null | grep "keyspace_misses" | cut -d: -f2 | tr -d '\r' || echo "0")
        
        echo "Keys: $keys_count"
        echo "Memory: $memory"
        echo "Hits: $hits"
        echo "Misses: $misses"
    else
        echo "Keys: ERROR"
        echo "Memory: ERROR"
        echo "Hits: ERROR"
        echo "Misses: ERROR"
    fi
}

start_monitoring() {
    local refresh_interval=5
    
    while true; do
        show_header "DASHBOARD DE MONITOREO"
        
        # 1. Estado de servicios
        echo -e "${GREEN}🐳 ESTADO DE CONTENEDORES:${NC}"
        echo "------------------------------"
        get_service_status
        echo ""
        
        # 2. Uso de recursos
        echo -e "${YELLOW}⚡ USO DE RECURSOS:${NC}"
        echo "--------------------"  
        get_resource_usage
        echo ""
        
        # 3. Health checks
        echo -e "${MAGENTA}🩺 HEALTH CHECKS:${NC}"
        echo "----------------"
        test_endpoints
        echo ""
        
        # 4. Cache statistics
        echo -e "${CYAN}🚀 ESTADÍSTICAS DE CACHE:${NC}"
        echo "-------------------------"
        cache_stats=$(get_cache_stats)
        echo "$cache_stats" | while read line; do
            echo "  📦 $line"
        done
        echo ""
        
        # 5. Instancias escaladas
        echo -e "${GREEN}📈 AUTOSCALING STATUS:${NC}"
        echo "---------------------"
        users_count=$(docker-compose ps users-api 2>/dev/null | grep -c "users-api" || echo "0")
        todos_count=$(docker-compose ps todos-api 2>/dev/null | grep -c "todos-api" || echo "0")
        auth_count=$(docker-compose ps auth-api 2>/dev/null | grep -c "auth-api" || echo "0")
        
        echo "  👥 Users API: $users_count instancias"
        echo "  📝 Todos API: $todos_count instancias"  
        echo "  🔐 Auth API: $auth_count instancias"
        echo ""
        
        # 6. URLs de acceso rápido
        echo -e "${BLUE}🌐 ACCESO RÁPIDO:${NC}"
        echo "---------------"
        echo "  🏠 Aplicación:    http://localhost/"
        echo "  🔧 API Gateway:   http://localhost:8888/"
        echo "  📊 Zipkin:        http://localhost:9411/"
        echo "  ❤️  Health Check:  http://localhost/health"
        echo ""
        
        # Controles
        echo -e "${YELLOW}🎮 CONTROLES:${NC}"
        echo "  [Ctrl+C] Salir del monitor"
        echo "  Actualizando cada $refresh_interval segundos..."
        
        # Esperar
        sleep $refresh_interval
    done
}

show_monitor_menu() {
    echo ""
    echo -e "${CYAN}📊 OPCIONES DE MONITOREO:${NC}"
    echo "1. 🔄 Monitor continuo (Dashboard)"
    echo "2. 📈 Solo métricas de performance"
    echo "3. 🚀 Solo estadísticas de cache"
    echo "4. 📋 Solo logs en tiempo real"
    echo "5. 🧪 Test de carga rápido"
    echo "0. ❌ Salir"
    echo ""
    
    read -p "Selecciona una opción (1-5, 0 para salir): " choice
    
    case $choice in
        1) start_monitoring ;;
        2) start_performance_monitoring ;;
        3) start_cache_monitoring ;;
        4) start_log_monitoring ;;
        5) start_load_test ;;
        0) 
            echo -e "${YELLOW}👋 Saliendo del monitor...${NC}"
            exit 0
            ;;
        *) 
            echo -e "${RED}❌ Opción inválida${NC}"
            show_monitor_menu 
            ;;
    esac
}

start_performance_monitoring() {
    echo -e "${YELLOW}⚡ MONITOR DE PERFORMANCE${NC}"
    while true; do
        clear
        echo -e "${YELLOW}⚡ MÉTRICAS DE PERFORMANCE - $(date '+%H:%M:%S')${NC}"
        echo "=================================================="
        
        test_endpoints
        
        echo ""
        get_resource_usage
        
        echo -e "\n${YELLOW}[Ctrl+C] para volver al menú${NC}"
        sleep 3
    done
}

start_cache_monitoring() {
    echo -e "${CYAN}🚀 MONITOR DE CACHE${NC}"
    while true; do
        clear
        echo -e "${CYAN}🚀 ESTADÍSTICAS DE CACHE - $(date '+%H:%M:%S')${NC}"
        echo "=================================================="
        
        get_cache_stats
        
        echo -e "\n${CYAN}🔍 Keys actuales en Redis:${NC}"
        if keys=$(docker-compose exec -T redis redis-cli KEYS "*" 2>/dev/null); then
            if [ -n "$keys" ]; then
                echo "$keys" | while read key; do
                    echo -e "  ${GREEN}- $key${NC}"
                done
            else
                echo -e "  ${YELLOW}(No hay keys en cache)${NC}"
            fi
        else
            echo -e "  ${RED}Error obteniendo keys${NC}"
        fi
        
        echo -e "\n${YELLOW}[Ctrl+C] para volver al menú${NC}"
        sleep 3
    done
}

start_log_monitoring() {
    echo -e "${MAGENTA}📋 MONITOR DE LOGS${NC}"
    echo -e "${YELLOW}Mostrando logs en tiempo real...${NC}"
    echo -e "${YELLOW}[Ctrl+C] para volver al menú${NC}"
    echo ""
    
    docker-compose logs -f --tail=20
}

start_load_test() {
    echo -e "${RED}🧪 TEST DE CARGA RÁPIDO${NC}"
    echo -e "${YELLOW}Enviando 20 requests al API Gateway...${NC}"
    
    successful=0
    failed=0
    total_time=0
    
    for i in {1..20}; do
        start_time=$(date +%s%3N)
        if curl -sf "http://localhost/api/users/" >/dev/null 2>&1; then
            end_time=$(date +%s%3N)
            time=$((end_time - start_time))
            total_time=$((total_time + time))
            ((successful++))
            echo -e "${GREEN}✅ Request $i: OK (${time}ms)${NC}"
        else
            ((failed++))
            echo -e "${RED}❌ Request $i: FAILED${NC}"
        fi
    done
    
    avg_time=$((total_time / successful))
    
    echo ""
    echo -e "${CYAN}📊 RESULTADOS DEL TEST DE CARGA:${NC}"
    echo -e "✅ Exitosos: $successful/20"
    echo -e "❌ Fallidos: $failed/20"
    echo -e "⏱️  Tiempo promedio: ${avg_time}ms"
    echo -e "🎯 Tasa de éxito: $((successful * 100 / 20))%"
    
    echo -e "\n${YELLOW}Presiona ENTER para volver al menú...${NC}"
    read
    show_monitor_menu
}

# Verificar que los servicios están corriendo
if ! running_containers=$(docker-compose ps --services --filter "status=running" 2>/dev/null) || [ -z "$running_containers" ]; then
    echo -e "${YELLOW}⚠️  No hay servicios corriendo.${NC}"
    echo -e "${YELLOW}Ejecuta './deploy.sh' primero para iniciar los servicios.${NC}"
    exit 1
fi

show_monitor_menu
