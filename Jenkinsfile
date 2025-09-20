pipeline {
    agent any

    parameters {
        // Parámetro para saber qué servicio disparó esta prueba
        string(name: 'TRIGGERING_SERVICE', defaultValue: '', description: 'Servicio que inició el pipeline de integración')
        // Parámetro para saber qué tag de imagen usar para el servicio que cambió
        string(name: 'IMAGE_TAG', defaultValue: 'latest-main', description: 'Tag de la nueva imagen a probar')
    }

    environment {
        DOCKER_REGISTRY = "geoffrey0pv"
    }

    stages {    
        stage('Preparar Entorno de Pruebas') {
            steps {
                echo "Iniciando pruebas de integración disparadas por: ${params.TRIGGERING_SERVICE} con el tag: ${params.IMAGE_TAG}"
                
                // Baja las últimas versiones estables de todas las imágenes
                sh "docker-compose -f docker-compose.integration.yml pull"

                // Vuelve a traer específicamente la imagen recién construida (por si 'pull' trajo una versión anterior)
                sh "docker pull ${DOCKER_REGISTRY}/${params.TRIGGERING_SERVICE}:${params.IMAGE_TAG}"
                
                // Etiqueta la nueva imagen para que docker-compose la use
                sh "docker tag ${DOCKER_REGISTRY}/${params.TRIGGERING_SERVICE}:${params.IMAGE_TAG} ${DOCKER_REGISTRY}/${params.TRIGGERING_SERVICE}:latest-main"
            }
        }

        stage('Levantar Servicios') {
            steps {
                // Usa docker-compose para levantar el ecosistema completo en modo 'detached'
                sh "docker-compose -f docker-compose.integration.yml up -d"
                // Espera un poco para que todos los servicios inicien
                sh "sleep 30"
            }
        }

        stage('Ejecutar Pruebas de Integración') {
            steps {
                // Ejecuta el contenedor de pruebas de integración
                // Este script (ej. test_flow.py) haría peticiones a las APIs para probar el flujo
                sh "docker-compose -f docker-compose.integration.yml run integration-tester"
            }
        }
    }

    post {
        // Este bloque se ejecuta siempre, haya éxito o fallo
        always {
            echo "Limpiando el entorno de pruebas de integración..."
            // Destruye todos los contenedores creados para la prueba
            sh "docker-compose -f docker-compose.integration.yml down -v"
        }
    }
}