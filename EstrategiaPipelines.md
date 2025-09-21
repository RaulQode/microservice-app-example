# Estrategia de CI/CD con Jenkins para el Taller de Microservicios

Este documento describe la estrategia de Integración Continua y Despliegue Continuo (CI/CD) para el proyecto de microservicios. El objetivo es automatizar la construcción, prueba y empaquetado de cada servicio de forma individual y, posteriormente, validar la integración del ecosistema completo.

La implementación se basa en **Pipelines as Code** utilizando **Jenkins** y **Docker** con **trabajos Multibranch independientes** por cada microservicio.

## 1. Estrategia General de Pipelines

La estrategia se fundamenta en un modelo de dos niveles para gestionar la autonomía de los microservicios y la estabilidad del sistema completo.

### Principios Clave

* **Pipelines as Code:** Cada microservicio tiene su propio `Jenkinsfile` en su directorio. Esto permite que el pipeline evolucione junto al código y sea versionado.
* **Autonomía de Servicios:** Cada microservicio tiene su propio trabajo Multibranch en Jenkins, optimizando el uso de recursos y proporcionando aislamiento completo.
* **Validación de Integración:** Un cambio exitoso en la rama `master` de cualquier servicio dispara un pipeline secundario que prueba la interoperabilidad de todo el ecosistema.

### Jerarquía de Orquestación

El flujo de trabajo sigue este modelo:

1. **Pipeline de Microservicio (CI):** Se enfoca en un único servicio.
   * **Disparador:** Un commit que afecte cualquier archivo del servicio.
   * **Responsabilidades:** Compilar, ejecutar pruebas unitarias, construir una imagen de Docker y publicarla en un registro.

2. **Pipeline de Integración:** Actúa como el orquestador global.
   * **Disparador:** Un build exitoso del pipeline de CI en la rama `master`.
   * **Responsabilidades:** Levantar un entorno completo con la nueva imagen y las últimas versiones estables de los demás servicios, ejecutar pruebas de integración y reportar el estado del ecosistema.

#### Flujo Visual

```
[Commit en /todos-api]
       |
       V
[microservices-todos-api/master] --(Éxito)--> [microservices-integration/master]
       |                                                |
       V                                                V
- Compila y prueba todos-api                          - Levanta TODOS los servicios
- Crea y publica imagen Docker                        - Ejecuta pruebas de flujo completo
- Dispara pipeline integración                        - Promueve imagen a 'stable'
       |                                                |
       V                                                V
[Imagen 'todos-api:latest-master']                    [Sistema validado y listo para CD]
```

## 2. Configuración del Entorno Jenkins

### Prerrequisitos

* Jenkins instalado y accesible.
* **Docker** y **Docker Compose** instalados y funcionando en la máquina donde se ejecutarán los builds de Jenkins.
* El usuario de Jenkins debe tener permisos para ejecutar comandos de Docker.
* Acceso a Docker Registry (Docker Hub configurado con credenciales `geoffrey0pv`).

### a) Instalación de Plugins Esenciales

Ve a `Manage Jenkins` > `Plugins` > `Available` e instala los siguientes plugins:

* **`Pipeline: Multibranch`**: Para crear trabajos independientes por servicio.
* **`Docker Pipeline`**: Integración nativa con Docker y Docker Compose.
* **`Git`**: Para la integración con el repositorio de GitHub.
* **`Credentials Binding`**: Para manejar los secretos de forma segura.

### b) Configuración de Credenciales

1. Ve a `Manage Jenkins` > `Credentials`.
2. Haz clic en `(global)` y luego en `Add Credentials`.
3. **Kind:** `Username with password`.
4. **Username:** `geoffrey0pv` (usuario de Docker Hub).
5. **Password:** Tu contraseña o token de acceso de Docker Hub.
6. **ID:** `dockerhub-credentials` **(Este ID se usa en todos los Jenkinsfiles)**.
7. Guarda la credencial.

### c) Creación de Trabajos Multibranch Independientes

**IMPORTANTE:** En lugar de un solo trabajo Multibranch, crearás **6 trabajos separados**:

#### Trabajos de Microservicios:

1. **microservices-auth-api**
   - Tipo: `Multibranch Pipeline`
   - Repository HTTPS URL: `https://github.com/RaulQode/microservice-app-example.git`
   - Script Path: `auth-api/Jenkinsfile`

2. **microservices-frontend**
   - Tipo: `Multibranch Pipeline`
   - Repository HTTPS URL: `https://github.com/RaulQode/microservice-app-example.git`
   - Script Path: `frontend/Jenkinsfile`

3. **microservices-todos-api**
   - Tipo: `Multibranch Pipeline`
   - Repository HTTPS URL: `https://github.com/RaulQode/microservice-app-example.git`
   - Script Path: `todos-api/Jenkinsfile`

4. **microservices-users-api**
   - Tipo: `Multibranch Pipeline`
   - Repository HTTPS URL: `https://github.com/RaulQode/microservice-app-example.git`
   - Script Path: `users-api/Jenkinsfile`

5. **microservices-log-processor**
   - Tipo: `Multibranch Pipeline`
   - Repository HTTPS URL: `https://github.com/RaulQode/microservice-app-example.git`
   - Script Path: `log-message-processor/Jenkinsfile`

#### Trabajo de Integración:

6. **microservices-integration**
   - Tipo: `Multibranch Pipeline`
   - Repository HTTPS URL: `https://github.com/RaulQode/microservice-app-example.git`
   - Script Path: `Jenkinsfile` (en la raíz)

### d) Configuración de Webhooks

1. Ve a tu repositorio en GitHub.
2. Settings → Webhooks → Add webhook.
3. **Payload URL:** `http://tu-jenkins-url/github-webhook/`
4. **Content type:** `application/json`
5. **Events:** Push events, Pull request events.

## 3. Estructura de Archivos Requeridos

El repositorio debe tener esta estructura:

```
microservice-app-example/
├── auth-api/
│   └── Jenkinsfile              # Pipeline para auth-api
├── frontend/
│   └── Jenkinsfile              # Pipeline para frontend
├── log-message-processor/
│   └── Jenkinsfile              # Pipeline para log-processor
├── todos-api/
│   └── Jenkinsfile              # Pipeline para todos-api
├── users-api/
│   └── Jenkinsfile              # Pipeline para users-api
├── docker-compose.yml           # Compose para desarrollo
├── docker-compose.integration.yml  # Compose para testing (NUEVO)
├── Jenkinsfile                  # Pipeline de integración (en la raíz)
└── README.md
```

### Archivo docker-compose.integration.yml

Este archivo es una copia modificada del `docker-compose.yml` original con:

* Puertos diferentes para evitar conflictos (18000, 18080, 18082, 18083, etc.)
* Referencias a las imágenes de Docker Hub con el tag `latest-master`
* Configuración específica para el entorno de testing de integración

## 4. Cómo Funciona la Orquestación

### Flujo Paso a Paso:

1. **Developer hace commit en `/todos-api`**
2. **GitHub Webhook notifica a Jenkins**
3. **Solo el trabajo `microservices-todos-api/master` se ejecuta:**
   - Build y test del código
   - Construcción de imagen Docker
   - Push a Docker Hub como `geoffrey0pv/todos-api:latest-master`
4. **Al completarse exitosamente, dispara `microservices-integration/master`**
5. **Pipeline de Integración se ejecuta:**
   - Descarga todas las imágenes (incluyendo la nueva)
   - Levanta todo el ecosistema con `docker-compose.integration.yml`
   - Ejecuta pruebas de integración automatizadas
   - Si pasa, promueve la imagen a tag `stable`
   - Limpia el entorno de testing

### Ventajas de esta Aproximación:

* **Aislamiento Completo:** Cada servicio tiene su propio ciclo de vida
* **Paralelismo:** Múltiples servicios pueden buildear simultáneamente
* **Optimización de Recursos:** Solo se ejecuta lo necesario
* **Facilidad de Debugging:** Logs separados por servicio
* **Escalabilidad:** Fácil agregar nuevos microservicios

## 5. Cómo Probar la Orquestación

### Paso 1: Verificar la Configuración

1. Confirma que todos los 6 trabajos Multibranch estén creados en Jenkins
2. Verifica que cada trabajo haya escaneado el repositorio y detectado la rama `master`
3. Confirma que las credenciales `dockerhub-credentials` estén configuradas

### Paso 2: Realizar una Prueba de Cambio

1. Crear una rama de prueba:
   ```bash
   git checkout -b feature/test-integration
   ```

2. Hacer un cambio menor en `todos-api/server.js`:
   ```javascript
   app.listen(port, function () {
     console.log('TODO API v2.1 running!'); // Cambio de prueba
     console.log('todo list RESTful API server started on: ' + port)
   })
   ```

3. Commit y push:
   ```bash
   git add .
   git commit -m "feat: test pipeline integration"
   git push origin feature/test-integration
   ```

### Paso 3: Observar el Flujo

1. **Verificar que solo `microservices-todos-api/feature/test-integration` se ejecute**
2. **Crear un Pull Request y hacer merge a `master`**
3. **Observar que se ejecute `microservices-todos-api/master`**
4. **Verificar que se dispare automáticamente `microservices-integration/master`**
5. **Revisar los logs del pipeline de integración**

### Paso 4: Validar Resultados

Si todo funciona correctamente, deberías ver:

* Imagen `geoffrey0pv/todos-api:latest-master` en Docker Hub
* Imagen `geoffrey0pv/todos-api:stable` (después de la integración exitosa)
* Logs de pruebas de integración exitosas
* Entorno de testing limpio (sin contenedores corriendo)

## 6. Troubleshooting Común

### Problema: "Docker not found"
**Solución:** Verificar que Docker esté instalado en el nodo de Jenkins y que el usuario Jenkins tenga permisos.

### Problema: "dockerhub-credentials not found"
**Solución:** Verificar que las credenciales estén configuradas con el ID exacto `dockerhub-credentials`.

### Problema: Pipeline de integración no se dispara
**Solución:** Verificar que el nombre del trabajo sea exactamente `microservices-integration/master`.

### Problema: Puerto ya en uso durante integración
**Solución:** Verificar que `docker-compose.integration.yml` use puertos diferentes (18xxx).

## 7. Próximos Pasos

Una vez que la orquestación básica funcione:

1. **Agregar pruebas más sofisticadas** al pipeline de integración
2. **Implementar notificaciones** a Slack/Teams
3. **Configurar despliegue automático** a entornos de staging/producción
4. **Agregar análisis de calidad de código** (SonarQube)
5. **Implementar rollback automático** en caso de fallos

---

**Nota:** Esta estrategia proporciona un balance entre autonomía de servicios y validación de integración, asegurando que cada cambio sea probado tanto individualmente como en el contexto del sistema completo.