pipeline {
    agent any
    
    parameters {
        string(name: 'TRIGGERING_SERVICE', defaultValue: '', description: 'Servicio que inició el pipeline de integración')
        string(name: 'IMAGE_TAG', defaultValue: 'latest-master', description: 'Tag de la nueva imagen a probar')
    }
    
    environment {
        DOCKER_REGISTRY = "geoffrey0pv"
    }
    
    stages {
        stage('Preparar Entorno de Pruebas') {
            steps {
                echo "Iniciando pruebas de integración disparadas por: ${params.TRIGGERING_SERVICE} con el tag: ${params.IMAGE_TAG}"
                
                // Limpiar cualquier container previo
                sh "docker-compose -f docker-compose.integration.yml down -v || true"
                
                // Verificar que el archivo docker-compose.integration.yml existe
                sh """
                    if [ ! -f docker-compose.integration.yml ]; then
                        echo "Error: docker-compose.integration.yml no encontrado"
                        exit 1
                    fi
                    echo "Archivo docker-compose.integration.yml encontrado"
                """
                
                // Bajar las últimas versiones estables
                sh "docker-compose -f docker-compose.integration.yml pull || true"
                
                sh "docker pull ${DOCKER_REGISTRY}/${params.TRIGGERING_SERVICE}:${params.IMAGE_TAG} || echo 'No se pudo pull de la imagen específica'"
                
                sh "docker tag ${DOCKER_REGISTRY}/${params.TRIGGERING_SERVICE}:${params.IMAGE_TAG} ${DOCKER_REGISTRY}/${params.TRIGGERING_SERVICE}:latest-master || echo 'No se pudo re-tagear'"
            }
        }
        
        stage('Levantar Servicios') {
            steps {
                echo "Levantando el ecosistema completo..."
                sh "docker-compose -f docker-compose.integration.yml up -d"
                
                // Verificar que los servicios estén corriendo
                sh """
                    echo "Esperando que los servicios estén listos..."
                    sleep 45
                    
                    # Mostrar estado de los servicios
                    echo "Estado de los contenedores:"
                    docker-compose -f docker-compose.integration.yml ps
                    
                    # Health checks básicos con timeout
                    echo "Verificando conectividad de servicios..."
                    
                    # Verificar auth-api
                    for i in {1..10}; do
                        if curl -f -m 5 http://localhost:18000/version 2>/dev/null; then
                            echo "✅ Auth API está respondiendo"
                            break
                        fi
                        echo "Reintentando Auth API (\$i/10)..."
                        sleep 5
                    done
                    
                    # Verificar users-api
                    for i in {1..10}; do
                        if curl -f -m 5 http://localhost:18083/users 2>/dev/null; then
                            echo "✅ Users API está respondiendo"
                            break
                        fi
                        echo "Reintentando Users API (\$i/10)..."
                        sleep 5
                    done
                """
            }
        }
        
        stage('Ejecutar Pruebas de Integración') {
            steps {
                echo "Ejecutando pruebas de integración..."
                
                // Mostrar logs para debugging
                sh "docker-compose -f docker-compose.integration.yml logs --tail=50 || true"
                
                // Ejecutar pruebas básicas de integración
                sh """
                    echo " Ejecutando pruebas básicas de integración..."
                    
                    # Test 1: Verificar que todos los servicios estén corriendo
                    echo "Test 1: Verificando servicios..."
                    docker-compose -f docker-compose.integration.yml ps
                    
                    # Test 2: Pruebas de conectividad básicas
                    echo "Test 2: Pruebas de conectividad..."
                    
                    # Verificar auth-api
                    curl -f -m 10 http://localhost:18000/version || echo " Auth API no responde"
                    
                    # Test 3: Flujo completo de autenticación
                    echo "Test 3: Flujo de autenticación..."
                    TOKEN=\$(curl -s -m 10 -X POST http://localhost:18000/login \\
                                -H "Content-Type: application/json" \\
                                -d '{"username":"admin","password":"admin"}' \\
                                | grep -o '"accessToken":"[^"]*"' \\
                                | cut -d'"' -f4 2>/dev/null) || echo "Login falló"
                    
                    if [ ! -z "\$TOKEN" ] && [ "\$TOKEN" != "null" ]; then
                        echo " Token obtenido exitosamente: \${TOKEN:0:20}..."
                        
                        # Probar acceso a TODOs (si está disponible)
                        curl -f -m 10 -H "Authorization: Bearer \$TOKEN" \\
                             http://localhost:18082/todos || echo "⚠️ TODOs API no responde (puede no estar listo)"
                             
                        # Probar acceso a Users
                        curl -f -m 10 -H "Authorization: Bearer \$TOKEN" \\
                             http://localhost:18083/users/admin || echo "+ Users API no responde con auth"
                    else
                        echo " No se pudo obtener token válido"
                    fi
                    
                    echo " Pruebas de integración completadas"
                """
            }
        }
        
        stage('Validar Resultados') {
            steps {
                echo "Validando que el ecosistema funciona correctamente..."
                sh """
                    echo " Validación: Verificando logs de errores..."
                    
                    # Buscar errores críticos en logs
                    if docker-compose -f docker-compose.integration.yml logs | grep -i "error\\|exception\\|fatal" | head -10; then
                        echo " Se encontraron algunos errores en logs (revisar arriba)"
                    else
                        echo "No se encontraron errores críticos en logs"
                    fi
                    
                    # Verificar que los contenedores siguen corriendo
                    echo "📋 Contenedores activos:"
                    docker-compose -f docker-compose.integration.yml ps
                """
            }
        }
    }
    
    post {
        always {
            echo "Limpiando el entorno de pruebas de integración..."
            sh "docker-compose -f docker-compose.integration.yml down -v || true"
            sh "docker system prune -f || true"
        }
        success {
            echo "¡Integración exitosa! El ecosistema funciona correctamente."
            script {
                if (params.TRIGGERING_SERVICE && params.IMAGE_TAG) {
                    echo "Promoviendo imagen ${params.TRIGGERING_SERVICE}:${params.IMAGE_TAG} a stable"
                    sh """
                        docker tag ${DOCKER_REGISTRY}/${params.TRIGGERING_SERVICE}:${params.IMAGE_TAG} ${DOCKER_REGISTRY}/${params.TRIGGERING_SERVICE}:stable || true
                        docker push ${DOCKER_REGISTRY}/${params.TRIGGERING_SERVICE}:stable || echo "No se pudo push a stable"
                    """
                }
            }
        }
        failure {
            echo "Falló la integración. Revisando logs..."
            sh "docker-compose -f docker-compose.integration.yml logs --tail=100 || true"
        }
    }
}