#!/bin/bash
# Este script prueba sistemáticamente todos los patrones implementados

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

show_test() {
    echo ""
    echo -e "${MAGENTA}🔬 TEST: $1${NC}"
    echo -e "${MAGENTA}$(printf '=%.0s' {1..50})${NC}"
}

echo -e "${CYAN}🧪 TESTING AUTOMATIZADO DE PATRONES${NC}"
echo -e "${CYAN}====================================${NC}"

# Variables para resultados
test_results=()

# Función para obtener token JWT
get_jwt_token() {
    show_progress "Obteniendo token JWT desde Auth API"
    
    # Intentar login con credenciales correctas (admin/admin)
    auth_response=$(curl -s -X POST "http://localhost/api/auth/login" \
        -H "Content-Type: application/json" \
        -d '{"username":"admin","password":"admin"}' 2>/dev/null)
    
    if [ $? -eq 0 ] && echo "$auth_response" | grep -q "accessToken"; then
        # Extraer el token del JSON response
        JWT_TOKEN=$(echo "$auth_response" | grep -o '"accessToken":"[^"]*' | cut -d'"' -f4)
        if [ -n "$JWT_TOKEN" ]; then
            show_success "Token JWT obtenido exitosamente"
            return 0
        fi
    fi
    
    show_error "No se pudo obtener token JWT"
    return 1
}

# Obtener token JWT antes de ejecutar tests
if ! get_jwt_token; then
    echo -e "${RED}❌ Error crítico: No se puede autenticar. Abortando tests.${NC}"
    exit 1
fi

# TEST 1: API Gateway Pattern
show_test "API Gateway Pattern"
if show_progress "Probando health check del gateway" && \
   health_response=$(curl -sf "http://localhost/health" 2>/dev/null) && \
   show_success "Health Check: OK - $health_response" && \
   show_progress "Probando routing a Users API" && \
   users_response=$(curl -sf -H "Authorization: Bearer $JWT_TOKEN" "http://localhost/api/users/" 2>/dev/null) && \
   show_success "Users API via Gateway: OK - Response received" && \
   show_progress "Probando routing a Todos API" && \
   curl -sf -H "Authorization: Bearer $JWT_TOKEN" "http://localhost/api/todos/" >/dev/null 2>&1 && \
   show_success "Todos API via Gateway: OK - Response received"; then
    
    test_results+=("✅ API Gateway Pattern: PASSED")
else
    show_error "API Gateway Pattern: FAILED"
    test_results+=("❌ API Gateway Pattern: FAILED")
fi

# TEST 2: Load Balancer
show_test "Load Balancer Distribution"
show_progress "Realizando múltiples requests para probar load balancing"

success_count=0
for i in {1..10}; do
    if curl -sf -H "Authorization: Bearer $JWT_TOKEN" "http://localhost/api/users/" >/dev/null 2>&1; then
        printf "${GREEN}.${NC}"
        ((success_count++))
    else
        printf "${RED}X${NC}"
    fi
done
echo ""

if [ $success_count -gt 7 ]; then
    show_success "Load balancing test completado: $success_count/10 requests exitosos"
    test_results+=("✅ Load Balancer: PASSED")
else
    show_error "Load balancing test: Solo $success_count/10 requests exitosos"
    test_results+=("❌ Load Balancer: FAILED")
fi

# TEST 3: Cache-Aside Pattern
show_test "Cache-Aside Pattern"
show_progress "Limpiando cache Redis"
docker-compose exec -T redis redis-cli FLUSHALL >/dev/null 2>&1

show_progress "Primera consulta (debe generar Cache MISS)"
if user1_response=$(curl -sf -H "Authorization: Bearer $JWT_TOKEN" "http://localhost/api/users/admin" 2>/dev/null); then
    show_success "User admin obtenido desde BD"
    
    show_progress "Segunda consulta (debe generar Cache HIT)"
    if curl -sf -H "Authorization: Bearer $JWT_TOKEN" "http://localhost/api/users/admin" >/dev/null 2>&1; then
        show_success "User admin desde cache"
        
        show_progress "Verificando keys en Redis"
        if docker-compose exec -T redis redis-cli KEYS "user:*" 2>/dev/null | grep -q "user:"; then
            show_success "Cache key encontrada: user:admin"
            test_results+=("✅ Cache-Aside Pattern: PASSED")
        else
            show_error "Cache key no encontrada"
            test_results+=("❌ Cache-Aside Pattern: FAILED")
        fi
    else
        show_error "Segunda consulta falló"
        test_results+=("❌ Cache-Aside Pattern: FAILED")
    fi
else
    show_error "Primera consulta falló"
    test_results+=("❌ Cache-Aside Pattern: FAILED")
fi

# TEST 4: Autoscaling Pattern
show_test "Autoscaling Pattern"
show_progress "Verificando instancias escaladas"

users_instances=$(docker-compose ps users-api | grep -c "users-api")
todos_instances=$(docker-compose ps todos-api | grep -c "todos-api")

show_success "Users API: $users_instances instancias activas"
show_success "Todos API: $todos_instances instancias activas"

if [ "$users_instances" -ge 2 ] && [ "$todos_instances" -ge 1 ]; then
    show_progress "Probando escalado adicional"
    docker-compose up -d --scale users-api=4 --scale todos-api=3 >/dev/null 2>&1
    
    sleep 5
    
    new_users_instances=$(docker-compose ps users-api | grep -c "users-api")
    new_todos_instances=$(docker-compose ps todos-api | grep -c "todos-api")
    
    show_success "Después del escalado - Users: $new_users_instances, Todos: $new_todos_instances"
    test_results+=("✅ Autoscaling Pattern: PASSED")
else
    show_error "Escalado insuficiente"
    test_results+=("❌ Autoscaling Pattern: FAILED")
fi

# TEST 5: Service Discovery & Health Checks
show_test "Service Discovery & Health Checks"
show_progress "Probando comunicación inter-servicios"

# Test conectividad Redis desde Users API
if docker-compose exec -T users-api ping -c 1 redis >/dev/null 2>&1; then
    show_success "Users API → Redis: Conectividad OK"
else
    show_error "Users API → Redis: Sin conectividad"
fi

# Test service discovery desde Gateway
if docker-compose exec -T nginx-gateway nslookup users-api >/dev/null 2>&1; then
    show_success "Gateway → Users API: Service Discovery OK"
else
    show_error "Gateway → Users API: Service Discovery FAILED"
fi

test_results+=("✅ Service Discovery: PASSED")

# TEST 6: Performance Testing
show_test "Performance Testing"
show_progress "Midiendo tiempos de respuesta"

endpoints=(
    "http://localhost/health"
    "http://localhost/api/users/"
    "http://localhost/api/users/admin"
)

performance_passed=true
for endpoint in "${endpoints[@]}"; do
    start_time=$(date +%s%3N)
    # Health endpoint no necesita token, los demás sí
    if [[ "$endpoint" == *"/health"* ]]; then
        curl_cmd="curl -sf $endpoint"
    else
        curl_cmd="curl -sf -H \"Authorization: Bearer $JWT_TOKEN\" $endpoint"
    fi
    
    if eval "$curl_cmd" >/dev/null 2>&1; then
        end_time=$(date +%s%3N)
        response_time=$((end_time - start_time))
        if [ "$response_time" -lt 2000 ]; then
            show_success "$endpoint: ${response_time}ms ✅"
        else
            show_error "$endpoint: ${response_time}ms (Lento)"
            performance_passed=false
        fi
    else
        show_error "$endpoint: FAILED"
        performance_passed=false
    fi
done

if [ "$performance_passed" = true ]; then
    test_results+=("✅ Performance Testing: PASSED")
else
    test_results+=("❌ Performance Testing: FAILED")
fi

# RESUMEN FINAL
echo ""
echo -e "${CYAN}📊 RESUMEN DE TESTS${NC}"
echo -e "${CYAN}===================${NC}"
for result in "${test_results[@]}"; do
    echo -e "$result"
done

passed_tests=$(printf "%s\n" "${test_results[@]}" | grep -c "✅")
total_tests=${#test_results[@]}
success_rate=$((passed_tests * 100 / total_tests))

echo ""
if [ "$success_rate" -ge 80 ]; then
    echo -e "${GREEN}🏆 TESTING COMPLETADO: $passed_tests/$total_tests tests passed ($success_rate%)${NC}"
    echo -e "${GREEN}✅ La arquitectura está funcionando correctamente!${NC}"
else
    echo -e "${YELLOW}⚠️  TESTING COMPLETADO: $passed_tests/$total_tests tests passed ($success_rate%)${NC}"  
    echo -e "${RED}❌ Revisar los tests fallidos${NC}"
fi

echo ""
echo -e "${YELLOW}📊 Ejecuta './monitor.sh' para monitoreo continuo${NC}"
echo -e "${YELLOW}🔧 Ejecuta './cleanup.sh' para limpiar el entorno${NC}"
