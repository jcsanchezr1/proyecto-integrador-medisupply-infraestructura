#!/bin/bash

# Script para verificar la configuración de credenciales de Google Cloud Storage

echo "Verificando configuración de credenciales de Google Cloud Storage..."
echo ""

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Función para logging
log() {
    echo -e "${GREEN} $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}  $1${NC}"
}

log_error() {
    echo -e "${RED} $1${NC}"
}

# Verificar si existe el archivo de credenciales
CREDENTIALS_FILE="./gcp-credentials.json"
if [ -f "$CREDENTIALS_FILE" ]; then
    log "Archivo de credenciales encontrado: $CREDENTIALS_FILE"
    
    # Verificar que sea un JSON válido
    if python3 -m json.tool "$CREDENTIALS_FILE" > /dev/null 2>&1; then
        log "Archivo JSON válido"
        
        # Verificar campos requeridos
        REQUIRED_FIELDS=("type" "project_id" "private_key" "client_email")
        for field in "${REQUIRED_FIELDS[@]}"; do
            if grep -q "\"$field\"" "$CREDENTIALS_FILE"; then
                log "Campo '$field' presente"
            else
                log_error "Campo '$field' faltante en el archivo de credenciales"
                exit 1
            fi
        done
        
        # Mostrar información del proyecto
        PROJECT_ID=$(grep '"project_id"' "$CREDENTIALS_FILE" | cut -d'"' -f4)
        CLIENT_EMAIL=$(grep '"client_email"' "$CREDENTIALS_FILE" | cut -d'"' -f4)
        
        echo ""
        log "Información de las credenciales:"
        echo "   Proyecto: $PROJECT_ID"
        echo "   Cuenta de servicio: $CLIENT_EMAIL"
        
    else
        log_error "El archivo de credenciales no es un JSON válido"
        exit 1
    fi
else
    log_error "Archivo de credenciales no encontrado: $CREDENTIALS_FILE"
    echo ""
    echo "   Para configurar las credenciales:"
    echo "   1. Descarga el archivo JSON desde Google Cloud Console"
    echo "   2. Renómbralo a 'gcp-credentials.json'"
    echo "   3. Colócalo en esta carpeta: $(pwd)"
    echo "   4. Ejecuta este script nuevamente"
    echo ""
    echo "  Ver documentación completa en: README.md"
    exit 1
fi

# Verificar que gcloud esté instalado
if command -v gcloud &> /dev/null; then
    log "Google Cloud CLI instalado"
    
    # Verificar autenticación
    if gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
        ACTIVE_ACCOUNT=$(gcloud auth list --filter=status:ACTIVE --format="value(account)")
        log "Cuenta activa: $ACTIVE_ACCOUNT"
    else
        log_warning "No hay cuentas autenticadas en gcloud"
    fi
else
    log_warning "Google Cloud CLI no está instalado"
fi

# Verificar que el bucket existe (si gcloud está disponible)
if command -v gcloud &> /dev/null; then
    BUCKET_NAME="medisupply-images-bucket"
    if gcloud storage buckets describe gs://$BUCKET_NAME &> /dev/null; then
        log "Bucket '$BUCKET_NAME' existe"
    else
        log_warning "Bucket '$BUCKET_NAME' no existe o no tienes permisos para acceder"
        echo "    Ejecuta: cd ../buckets && ./create-bucket.sh"
    fi
fi

echo ""
log "Verificación completada!"
echo ""
echo " Próximos pasos:"
echo "   1. Asegúrate de que el bucket existe: cd ../buckets && ./create-bucket.sh"
echo "   2. Levanta los servicios: docker-compose up -d"
echo "   3. Prueba crear un proveedor con imagen"
