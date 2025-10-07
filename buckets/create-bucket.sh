#!/bin/bash

# Script para crear bucket de Google Cloud Storage para MediSupply
# Configurable mediante variables de entorno

set -e

# Configuración por defecto para MediSupply (basada en api-gateway existente)
PROJECT_ID="${GCP_PROJECT_ID:-clean-result-473723-t3}"
BUCKET_NAME="${BUCKET_NAME:-medisupply-images-bucket}"
LOCATION="${BUCKET_LOCATION:-us-central1}"
STORAGE_CLASS="${STORAGE_CLASS:-STANDARD}"
PUBLIC_ACCESS="${PUBLIC_ACCESS:-false}"

# Carpetas que se crearán en el bucket
BUCKET_FOLDERS=("providers" "products")

# Función para mostrar ayuda
show_help() {
    echo "Script para crear bucket de Google Cloud Storage - MediSupply"
    echo ""
    echo "Uso: $0 [OPCIONES]"
    echo ""
    echo "Configuración por defecto para MediSupply:"
    echo "  Proyecto: clean-result-473723-t3"
    echo "  Bucket: medisupply-images-bucket"
    echo "  Ubicación: us-central1"
    echo "  Acceso: privado (URLs firmadas - 3 meses)"
    echo "  Carpetas: providers/, products/"
    echo ""
    echo "Opciones:"
    echo "  -p, --project-id ID     ID del proyecto de GCP (default: clean-result-473723-t3)"
    echo "  -b, --bucket-name NAME  Nombre del bucket (default: medisupply-images-bucket)"
    echo "  -l, --location LOC      Ubicación del bucket (default: us-central1)"
    echo "  -s, --storage-class SC  Clase de almacenamiento (default: STANDARD)"
    echo "  --public                Hacer el bucket público (URLs directas)"
    echo "  --private               Hacer el bucket privado (URLs firmadas) (default)"
    echo "  -h, --help              Mostrar esta ayuda"
    echo ""
    echo "Variables de entorno:"
    echo "  GCP_PROJECT_ID          ID del proyecto de GCP"
    echo "  BUCKET_NAME             Nombre del bucket"
    echo "  BUCKET_LOCATION         Ubicación del bucket"
    echo "  STORAGE_CLASS           Clase de almacenamiento"
    echo "  PUBLIC_ACCESS           true/false para acceso público"
    echo ""
    echo "Ejemplos:"
    echo "  # Usar configuración por defecto"
    echo "  $0"
    echo ""
    echo "  # Personalizar proyecto"
    echo "  $0 --project-id mi-proyecto-gcp"
    echo ""
    echo "  # Con variables de entorno"
    echo "  GCP_PROJECT_ID=mi-proyecto $0"
}

# Función para logging
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

log_error() {
    echo "[ERROR] $1" >&2
}

log_warning() {
    echo "[WARNING] $1"
}

# Función para verificar si gcloud está instalado
check_gcloud() {
    if ! command -v gcloud &> /dev/null; then
        log_error "gcloud CLI no está instalado. Por favor instálalo primero."
        exit 1
    fi
}

# Función para verificar autenticación
check_auth() {
    if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
        log_error "No hay cuentas autenticadas en gcloud. Ejecuta 'gcloud auth login' primero."
        exit 1
    fi
}

# Función para verificar si el proyecto existe
check_project() {
    if ! gcloud projects describe "$PROJECT_ID" &> /dev/null; then
        log_error "El proyecto '$PROJECT_ID' no existe o no tienes acceso."
        exit 1
    fi
}

# Función para crear el bucket
create_bucket() {
    log "Creando bucket '$BUCKET_NAME' en el proyecto '$PROJECT_ID'..."
    
    # Crear bucket con uniform bucket level access (privado por defecto)
    CREATE_CMD="gcloud storage buckets create gs://$BUCKET_NAME"
    CREATE_CMD="$CREATE_CMD --project=$PROJECT_ID"
    CREATE_CMD="$CREATE_CMD --location=$LOCATION"
    CREATE_CMD="$CREATE_CMD --default-storage-class=$STORAGE_CLASS"
    CREATE_CMD="$CREATE_CMD --uniform-bucket-level-access"
    
    # Configurar acceso público/privado
    if [ "$PUBLIC_ACCESS" = "true" ]; then
        log "Bucket será público (URLs directas)"
    else
        log "Bucket será privado (URLs firmadas)"
    fi
    
    # Ejecutar comando de creación
    if eval $CREATE_CMD; then
        log "Bucket '$BUCKET_NAME' creado exitosamente!"
        
        # Configurar acceso público si es necesario
        if [ "$PUBLIC_ACCESS" = "true" ]; then
            set_public_access
        fi
        
        # Crear carpetas dentro del bucket
        create_bucket_folders
        
        # Mostrar información del bucket
        echo ""
        log "Información del bucket:"
        echo "  Nombre: $BUCKET_NAME"
        echo "  Proyecto: $PROJECT_ID"
        echo "  Ubicación: $LOCATION"
        echo "  Clase de almacenamiento: $STORAGE_CLASS"
        echo "  Acceso: $([ "$PUBLIC_ACCESS" = "true" ] && echo "Público (URLs directas)" || echo "Privado (URLs firmadas - 3 meses)")"
        echo "  URL: gs://$BUCKET_NAME"
        
        # Mostrar información de acceso
        if [ "$PUBLIC_ACCESS" = "true" ]; then
            echo "  URL pública: https://storage.googleapis.com/$BUCKET_NAME"
        else
            echo "  URLs firmadas: Generadas por la aplicación (válidas por 3 meses)"
        fi
        
        echo ""
        log "Estructura de carpetas creada:"
        for folder in "${BUCKET_FOLDERS[@]}"; do
            echo "  - $folder/"
        done
        
        echo ""
        log "Configuración para microservicios MediSupply:"
        echo ""
        echo "Proveedores (docker-compose.yml):"
        echo "  - BUCKET_NAME=$BUCKET_NAME"
        echo "  - BUCKET_FOLDER=providers"
        echo "  - GCP_PROJECT_ID=$PROJECT_ID"
        echo ""
        echo "Inventarios (docker-compose.yml):"
        echo "  - BUCKET_NAME=$BUCKET_NAME"
        echo "  - BUCKET_FOLDER=products"
        echo "  - GCP_PROJECT_ID=$PROJECT_ID"
        echo ""
        echo "URLs de ejemplo:"
        if [ "$PUBLIC_ACCESS" = "true" ]; then
            echo "  Proveedores: https://storage.googleapis.com/$BUCKET_NAME/providers/logo_uuid.jpg"
            echo "  Productos: https://storage.googleapis.com/$BUCKET_NAME/products/product_uuid.jpg"
        else
            echo "  Proveedores: URLs firmadas con expiración de 3 meses (generadas por la app)"
            echo "  Productos: URLs firmadas con expiración de 3 meses (generadas por la app)"
            echo ""
            echo "  Ejemplo de generación de URL firmada:"
            echo "  from google.cloud import storage"
            echo "  from datetime import datetime, timedelta"
            echo ""
            echo "  client = storage.Client()"
            echo "  bucket = client.bucket('$BUCKET_NAME')"
            echo "  blob = bucket.blob('providers/logo_uuid.jpg')"
            echo "  url = blob.generate_signed_url(expiration=datetime.utcnow() + timedelta(days=90))"
        fi
        
    else
        log_error "Error al crear el bucket '$BUCKET_NAME'"
        exit 1
    fi
}

# Función para configurar acceso público al bucket
set_public_access() {
    log "Configurando acceso público al bucket..."
    
    # Asignar permisos de lectura a todos los usuarios
    if gcloud storage buckets add-iam-policy-binding gs://$BUCKET_NAME \
        --member=allUsers \
        --role=roles/storage.objectViewer \
        --project=$PROJECT_ID; then
        log "Acceso público configurado exitosamente"
    else
        log_warning "No se pudo configurar el acceso público (puede que ya esté configurado)"
    fi
}

# Función para crear carpetas dentro del bucket
create_bucket_folders() {
    log "Creando estructura de carpetas en el bucket..."
    
    for folder in "${BUCKET_FOLDERS[@]}"; do
        log "Creando carpeta: $folder/"
        
        # Crear un archivo temporal para inicializar la carpeta
        temp_file="/tmp/.folder_marker_$folder"
        echo "# Carpeta $folder para MediSupply" > "$temp_file"
        
        # Subir el archivo marcador a la carpeta
        if gcloud storage cp "$temp_file" "gs://$BUCKET_NAME/$folder/.folder_marker" --quiet; then
            log "Carpeta '$folder/' creada exitosamente"
        else
            log_warning "No se pudo crear la carpeta '$folder/' (puede que ya exista)"
        fi
        
        # Limpiar archivo temporal
        rm -f "$temp_file"
    done
}

# Función para verificar si el bucket ya existe
check_bucket_exists() {
    if gcloud storage buckets describe "gs://$BUCKET_NAME" --project="$PROJECT_ID" &> /dev/null; then
        log_warning "El bucket '$BUCKET_NAME' ya existe en el proyecto '$PROJECT_ID'"
        read -p "¿Deseas continuar de todas formas? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log "Operación cancelada"
            exit 0
        fi
    fi
}

# Parsear argumentos de línea de comandos
while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--project-id)
            PROJECT_ID="$2"
            shift 2
            ;;
        -b|--bucket-name)
            BUCKET_NAME="$2"
            shift 2
            ;;
        -l|--location)
            LOCATION="$2"
            shift 2
            ;;
        -s|--storage-class)
            STORAGE_CLASS="$2"
            shift 2
            ;;
        --public)
            PUBLIC_ACCESS="true"
            shift
            ;;
        --private)
            PUBLIC_ACCESS="false"
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            log_error "Opción desconocida: $1"
            show_help
            exit 1
            ;;
    esac
done

# Validar parámetros
if [ -z "$PROJECT_ID" ] || [ -z "$BUCKET_NAME" ]; then
    log_error "PROJECT_ID y BUCKET_NAME son requeridos"
    show_help
    exit 1
fi

# Validar nombre del bucket
if [[ ! "$BUCKET_NAME" =~ ^[a-z0-9][a-z0-9._-]*[a-z0-9]$ ]] && [[ ! "$BUCKET_NAME" =~ ^[a-z0-9]$ ]]; then
    log_error "Nombre de bucket inválido. Debe contener solo letras minúsculas, números, puntos, guiones y guiones bajos."
    exit 1
fi

# Ejecutar verificaciones y creación
log "Iniciando creación de bucket..."
log "Configuración:"
echo "  Proyecto: $PROJECT_ID"
echo "  Bucket: $BUCKET_NAME"
echo "  Ubicación: $LOCATION"
echo "  Clase de almacenamiento: $STORAGE_CLASS"
echo "  Acceso público: $PUBLIC_ACCESS"
echo ""

check_gcloud
check_auth
check_project
check_bucket_exists
create_bucket

log "¡Proceso completado exitosamente!"
