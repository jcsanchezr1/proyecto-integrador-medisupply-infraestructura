# Proyecto Integrador Medisupply - Infraestructura

Este repositorio contiene la configuración de infraestructura para el proyecto Medisupply.

## Estructura del Proyecto

```
├── api-gateway/             # Configuración del Google Cloud API Gateway
│   ├── openapi-gateway.yaml # Configuración OpenAPI del gateway
│   ├── deploy.sh            # Script de despliegue del gateway
│   └── delete.sh            # Script de eliminación del gateway
├── buckets/                 # Configuración de Google Cloud Storage
│   ├── create-bucket.sh     # Script para crear bucket de imágenes
│   └── README.md            # Documentación del bucket
├── credentials/             # Credenciales de Google Cloud (NO SUBIR A GIT)
│   ├── verify-setup.sh      # Script de verificación de configuración
│   └── README.md            # Documentación de credenciales
├── db/                      # Configuración de base de datos
│   └── init/                # Scripts de inicialización de BD
├── keycloak/                # Directorio con la configuracion de keycloak
│   ├── Dockerfile           # Imagen de Docker para Keycloak
│   ├── postman/             # Colección de Postman para pruebas de Keycloak
│   └── realm-export/        # Configuración del realm para importar en Keycloak
├── pubsub/                  # Configuración de Google Cloud Pub/Sub
│   ├── create-gcp-pubsub.sh # Script para crear tópicos y suscripciones en GCP
│   └── init-local.sh        # Script de inicialización para emulador local
├── docker-compose.yml       # Configuración para desarrollo local
└── README.md
```

## Servicios Incluidos

- **medisupply-db**: Base de datos PostgreSQL central para todo el sistema Medisupply
- **keycloak**: Servidor de autenticación y autorización
- **api-gateway**: Gateway para redirigir requests a los microservicios
- **autenticador**: Microservicio de gestión de usuarios y autenticación
- **autorizador**: Microservicio para manejo de autorización y permisos
- **proveedores**: Microservicio de gestión de proveedores con almacenamiento de imágenes
- **inventarios**: Microservicio de gestión de inventarios con almacenamiento de imágenes
- **pedidos**: Microservicio de gestión de pedidos
- **pubsub**: Emulador de Google Cloud Pub/Sub para desarrollo local

## Desarrollo Local

### Prerrequisitos

- Docker
- Docker Compose
- Google Cloud SDK (opcional, para crear bucket)
- Cuenta de Google Cloud con proyecto configurado

### Configuración Inicial

#### 1. Configurar credenciales de Google Cloud Storage

```bash
# Ir a la carpeta de credenciales
cd credentials

# Verificar configuración actual
./verify-setup.sh

# Si no tienes credenciales, sigue las instrucciones en credentials/README.md
```

#### 2. Crear bucket de Google Cloud Storage

```bash
# Ir a la carpeta de buckets
cd buckets

# Crear el bucket (usar configuración por defecto)
./create-bucket.sh

# O crear bucket público (opcional)
./create-bucket.sh --public
```

### Iniciar el entorno local

```bash
# Clonar el repositorio
git clone <repository-url>
cd proyecto-integrador-medisupply-infraestructura

# Configurar credenciales (ver sección anterior)
# Crear bucket (ver sección anterior)

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

## Desplegar API Gateway

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

### Eliminar API Gateway

```bash
cd api-gateway
chmod +x delete.sh
./delete.sh
```

El script elimina:
- Gateway
- Todas las configuraciones del API
- El API completo

El proyecto utiliza Google Cloud Storage para almacenar imágenes de proveedores y productos:

- **Bucket**: `medisupply-images-bucket` (configurable)
- **Carpetas**: 
  - `providers/` - Logos de proveedores
  - `products/` - Imágenes de productos
- **Acceso**: Privado con URLs firmadas (expiración: 3 meses)
- **Configuración**: Variables de entorno en `docker-compose.yml`

### URLs de Ejemplo

```
# Proveedores
https://storage.googleapis.com/medisupply-images-bucket/providers/logo_uuid.jpg

# Productos  
https://storage.googleapis.com/medisupply-images-bucket/products/product_uuid.jpg
```

### Configuración de Credenciales

Las credenciales se configuran mediante archivo JSON montado como volumen:

```yaml
volumes:
  - ./credentials/gcp-credentials.json:/app/credentials/gcp-credentials.json:ro
environment:
  - GOOGLE_APPLICATION_CREDENTIALS=/app/credentials/gcp-credentials.json
```

## Configuración de Base de Datos

El proyecto utiliza PostgreSQL como base de datos central para todo el sistema Medisupply. Esta se creará en el servicio de Cloud SQL.

## Creación de tópicos y suscripciones en PubSub

Para configurar el sistema de mensajería de Google Cloud Pub/Sub, se proporciona un script que crea automáticamente los tópicos y suscripciones necesarios.

### Prerrequisitos

- Google Cloud SDK instalado
- Autenticación en GCP configurada (`gcloud auth login`)
- Permisos necesarios en el proyecto GCP

### Configuración

```bash
# Hacer el script ejecutable
chmod +x pubsub/create-gcp-pubsub.sh

# Ejecutar el script de configuración
./pubsub/create-gcp-pubsub.sh
```

El script creará:
- Tópico: `inventory.processing.products`
- Suscripción push: `inventory.processing.products.processor`

El script es idempotente y puede ejecutarse múltiples veces de forma segura. Si los recursos ya existen, se actualizará su configuración.
