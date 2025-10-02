# Proyecto Integrador Medisupply - Infraestructura

Este repositorio contiene la configuración de infraestructura para el proyecto Medisupply.

## Estructura del Proyecto

```
├── keycloak/               # Directorio con la configuracion de keycloak
│   ├── Dockerfile          # Imagen de Docker para Keycloak
├── api-gateway/            # Configuración del API Gateway
│   ├── openapi-gateway.yaml # Configuración OpenAPI del gateway
│   └── deploy.sh           # Script de despliegue del gateway
├── docker-compose.yml      # Configuración para desarrollo local
└── README.md
```

## Servicios Incluidos

- **medisupply-db**: Base de datos PostgreSQL central para todo el sistema Medisupply
- **keycloak**: Servidor de autenticación y autorización
- **api-gateway**: Gateway para redirigir requests a los microservicios

## Desarrollo Local

### Prerrequisitos

- Docker
- Docker Compose

### Iniciar el entorno local

```bash
# Clonar el repositorio
git clone <repository-url>
cd proyecto-integrador-medisupply-infraestructura

# Iniciar los servicios
docker-compose up -d
```

### Importar automáticamente el realm en Keycloak

El servicio de Keycloak está configurado para importar un realm al arrancar usando `--import-realm` y un volumen con los archivos de importación.

- Archivo de importación: `keycloak/realm-export/medisupply-realm-realm.json`
- Realm creado: `medisupply-realm`
- Rol de realm creado: `Administrador` y demas roles de medisupply
- Usuario inicial creado: `medisupply05@gmail.com` con contraseña `admin` (no temporal)
- Cliente OIDC creado: `medisupply-app` (público, Direct Access Grants habilitado)

## Despliegue en Google Cloud Run

### Prerrequisitos

- Google Cloud SDK instalado y configurado
- Proyecto de Google Cloud configurado
- Base de datos PostgreSQL en Cloud SQL

### Cambiar variables antes de correr los comandos

- `$PROJECT_ID`: ID del proyecto en GCP
- `$IP_BD`: Ip de la base de datos
- `$PASSWORD_BD`: Password de la base de datos

### Desplegar keycloak

```bash
# Construir la imagen
docker build -t us-central1-docker.pkg.dev/$PROJECT_ID/medisupply-repository/keycloak:26.3 ./keycloak

# Construir la imagen arquitectura amd64
docker build --platform=linux/amd64 -t us-central1-docker.pkg.dev/$PROJECT_ID/medisupply-repository/keycloak:26.3 ./keycloak

# Subir la imagen
docker push us-central1-docker.pkg.dev/$PROJECT_ID/medisupply-repository/keycloak:26.3

# Desplegar en Cloud Run
gcloud run deploy keycloak \
  --image us-central1-docker.pkg.dev/$PROJECT_ID/medisupply-repository/keycloak:26.3 \
  --region us-central1 \
  --platform managed \
  --allow-unauthenticated \
  --port 8080 \
  --memory 2Gi \
  --cpu 2 \
  --min-instances 1 \
  --max-instances 1 \
  --set-env-vars KC_HTTP_ENABLED=true,KC_HTTP_PORT=8080,KC_PROXY=edge,KC_PROXY_HEADERS=xforwarded,KC_BOOTSTRAP_ADMIN_USERNAME=admin,KC_BOOTSTRAP_ADMIN_PASSWORD=admin,KC_HOSTNAME_STRICT=false,KC_DB=postgres,KC_DB_URL=jdbc:postgresql://$IP_BD:5432/postgres,KC_DB_USERNAME=postgres,KC_DB_PASSWORD=$PASSWORD_BD \
  --args=start,--import-realm
```

Notas para Cloud Run:

- El `Dockerfile` copia el directorio `keycloak/realm-export` a `/opt/keycloak/data/import`, por lo que al iniciar con `--import-realm` se cargará el realm automáticamente.
- Si actualizas el JSON del realm, vuelve a construir y publicar la imagen antes de desplegar.

### Desplegar API Gateway

```bash
cd api-gateway
chmod +x deploy.sh
./deploy.sh
```

El API Gateway redirige:
- `/auth/ping` al servicio de autenticación en Cloud Run
- Cualquier otra ruta retorna 404

Para probar:
```bash
curl https://[GATEWAY_URL]/auth/ping
```

## Configuración de Base de Datos

El proyecto utiliza PostgreSQL como base de datos central para todo el sistema Medisupply. Esta se creará en el servicio de Cloud SQL.
