# Estrategia de CI/CD con Jenkins para el Taller de Microservicios

Este documento describe la estrategia de Integración Continua y Despliegue Continuo (CI/CD) para el proyecto de microservicios. El objetivo es automatizar la construcción, prueba y empaquetado de cada servicio de forma individual y, posteriormente, validar la integración del ecosistema completo.

La implementación se basa en **Pipelines as Code** utilizando **Jenkins** y **Docker** en un repositorio único (monorepo).

-----

# \#\# 1. Estrategia General de Pipelines

La estrategia se fundamenta en un modelo de dos niveles para gestionar la autonomía de los microservicios y la estabilidad del sistema completo.

### \#\#\# Principios Clave

  * **Pipelines as Code:** Cada microservicio tiene su propio `Jenkinsfile` en su directorio. Esto permite que el pipeline evolucione junto al código y sea versionado.
  * **Autonomía de Servicios:** Un cambio en un microservicio solo dispara el pipeline de ese servicio, optimizando el uso de recursos.
  * **Validación de Integración:** Un cambio exitoso en la rama `main` de cualquier servicio dispara un pipeline secundario que prueba la interoperabilidad de todo el ecosistema.

### \#\#\# Jerarquía de Orquestación

El flujo de trabajo sigue este modelo:

1.  **Pipeline de Microservicio (CI):** Se enfoca en un único servicio.

      * **Disparador:** Un commit en el directorio del servicio.
      * **Responsabilidades:** Compilar, ejecutar pruebas unitarias, construir una imagen de Docker y publicarla en un registro.

2.  **Pipeline de Integración:** Actúa como el orquestador global.

      * **Disparador:** Un build exitoso del pipeline de CI en la rama `main`.
      * **Responsabilidades:** Levantar un entorno completo con la nueva imagen y las últimas versiones estables de los demás servicios, ejecutar pruebas de integración y reportar el estado del ecosistema.

#### \#\#\#\# Flujo Visual

```
[Commit en /users-api]
       |
       V
[Pipeline CI de users-api] --(Éxito en 'main')--> [Pipeline de Integración]
       |                                                |
       V                                                V
- Compila y prueba users-api                          - Levanta TODOS los servicios
- Crea y publica la imagen Docker                     - Ejecuta pruebas de flujo completo
       |                                                |
       V                                                V
[Imagen 'users-api' lista]                            [Sistema validado y listo para CD]
```

-----

## \#\# 2. Configuración del Entorno Jenkins

Para que esta estrategia funcione, Jenkins necesita la configuración adecuada.

### \#\#\# Prerrequisitos

  * Jenkins instalado y accesible.
  * **Docker** y **Docker Compose** instalados y funcionando en la máquina donde se ejecutarán los builds de Jenkins (el controlador o un agente).
  * El usuario de Jenkins debe tener permisos para ejecutar comandos de Docker.

### \#\#\# a) Instalación de Plugins Esenciales

Ve a `Manage Jenkins` \> `Plugins` \> `Available` e instala los siguientes plugins:

  * **`Pipeline: Multibranch`**: Esencial para detectar los `Jenkinsfile` en cada subdirectorio.
  * **`Docker Pipeline`**: Proporciona integración nativa con Docker y Docker Compose.
  * **`Git`**: Para la integración con el repositorio de GitHub.
  * **`Credentials Binding`**: Para manejar los secretos de forma segura.

### \#\#\# b) Configuración de Credenciales

Necesitamos guardar de forma segura las credenciales para publicar las imágenes de Docker.

1.  Ve a `Manage Jenkins` \> `Credentials`.
2.  Haz clic en `(global)` y luego en `Add Credentials`.
3.  **Kind:** `Username with password`.
4.  **Username:** Tu nombre de usuario de Docker Hub.
5.  **Password:** Tu contraseña o token de acceso de Docker Hub.
6.  **ID:** `dockerhub-credentials`. **(Este ID es el que se usa en los Jenkinsfiles)**.
7.  Guarda la credencial.

### \#\#\# c) Creación del Trabajo Multibranch

1.  En Jenkins, ve a `New Item`.
2.  Nombra el trabajo (ej. `taller-microservicios`) y selecciona el tipo **`Multibranch Pipeline`**.
3.  En la sección **`Branch Sources`**, haz clic en `Add source` y selecciona `GitHub`.
4.  **Credentials:** Selecciona las credenciales de GitHub (se recomienda usar un Personal Access Token).
5.  **Repository HTTPS URL:** Ingresa la URL de tu repositorio.
6.  En la sección **`Build Configuration`**, cambia el campo `Script Path` a **`**/Jenkinsfile`**. Esto le indica a Jenkins que busque un `Jenkinsfile` en cada subdirectorio del proyecto.
7.  Guarda el trabajo. Jenkins realizará un escaneo inicial y creará los pipelines para cada servicio encontrado.

-----

## \#\# 3. Cómo Probar la Orquestación de CI/CD

Sigue estos pasos para simular el flujo de trabajo de un desarrollador y verificar que toda la orquestación funciona.

### \#\#\# Paso 1: Crear y Subir una Rama de Característica

1.  Desde tu máquina local, crea una nueva rama:
    ```bash
    git checkout -b feature/test-todos-api
    ```
2.  Realiza un cambio menor en uno de los servicios. Por ejemplo, en el archivo `todos-api/server.js`, añade un `console.log`:
    ```javascript
    // ...
    app.listen(port, function () {
      console.log('TODO API V2 running!'); // <-- Cambio de prueba
      console.log('todo list RESTful API server started on: ' + port)
    })
    ```
3.  Haz commit y sube la rama a GitHub:
    ```bash
    git add .
    git commit -m "feat: test pipeline trigger for todos-api"
    git push origin feature/test-todos-api
    ```

### \#\#\# Paso 2: Verificar el Pipeline de CI

  * Ve a Jenkins. Deberías ver que tu trabajo `taller-microservicios` ha detectado la nueva rama y ha creado un pipeline para ella.
  * Observa el pipeline `feature/test-todos-api/todos-api`. Debería estar ejecutándose o haberse ejecutado. Revisa sus logs para confirmar que instaló dependencias, construyó y publicó una imagen Docker con un tag como `latest-feature-test-todos-api`.
  * **Importante:** Solo el pipeline del `todos-api` debe haberse ejecutado, no el de los otros servicios.

### \#\#\# Paso 3: Fusionar a `main` y Verificar la Orquestación

1.  En GitHub, crea un Pull Request desde tu rama `feature/test-todos-api` hacia `main` y fusiónalo (merge).
2.  Regresa a Jenkins y observa el pipeline `main/todos-api`. Se disparará y ejecutará todos sus pasos.
3.  **¡El Momento Clave\!** Una vez que el pipeline `main/todos-api` termine con éxito, el **pipeline de integración** (`taller-microservicios/main/integration` o como lo hayas nombrado) debe dispararse automáticamente.
4.  Revisa los logs de este pipeline de integración. Deberías ver cómo:
      * Descarga la nueva imagen `todos-api:latest-main` y las demás imágenes.
      * Ejecuta `docker-compose up`.
      * Ejecuta las pruebas de integración.
      * Finalmente, ejecuta `docker-compose down` en la sección `post` para limpiar.

Si todos los pipelines terminan en verde (azul en Jenkins), **¡felicidades\!** La orquestación de CI/CD está configurada y funcionando correctamente.