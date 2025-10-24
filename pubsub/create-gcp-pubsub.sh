#!/bin/bash

# Configuración
PROJECT_ID="clean-result-473723-t3"
TOPIC_NAME="inventory.processing.products"
SUBSCRIPTION_NAME="inventory.processing.products.processor"
ENDPOINT_URL="https://medisupply-inventory-processor-ms-1034901101791.us-central1.run.app/inventory-procesor/products"
DLT_TOPIC_NAME="inventory.processing.products.dlt"
DLT_SUBSCRIPTION_NAME="inventory.processing.products.dlt.processor"
MAX_DELIVERY_ATTEMPTS="5"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Función para imprimir mensajes con formato
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Verificar si gcloud está instalado
if ! command -v gcloud &> /dev/null; then
    print_message "$RED" "Error: gcloud CLI no está instalado. Por favor, instálalo primero."
    exit 1
fi

# Verificar si el usuario está autenticado
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" &> /dev/null; then
    print_message "$RED" "Error: No hay una cuenta de GCP activa. Por favor, ejecuta 'gcloud auth login' primero."
    exit 1
fi

# Verificar y configurar el proyecto
print_message "$YELLOW" "Verificando y configurando el proyecto ${PROJECT_ID}..."
if ! gcloud projects describe "$PROJECT_ID" &> /dev/null; then
    print_message "$RED" "Error: El proyecto ${PROJECT_ID} no existe o no tienes acceso."
    exit 1
fi

# Configurar el proyecto actual
gcloud config set project "$PROJECT_ID"

# Habilitar la API de Pub/Sub si no está habilitada
print_message "$YELLOW" "Habilitando la API de Pub/Sub..."
gcloud services enable pubsub.googleapis.com

# Crear el tópico
print_message "$YELLOW" "Creando tópico ${TOPIC_NAME}..."
gcloud pubsub topics create "$TOPIC_NAME"
print_message "$GREEN" "✓ Tópico creado exitosamente"

# Crear el Dead Letter Topic
print_message "$YELLOW" "Creando Dead Letter Topic ${DLT_TOPIC_NAME}..."
gcloud pubsub topics create "$DLT_TOPIC_NAME"
print_message "$GREEN" "✓ Dead Letter Topic creado exitosamente"

# Crear suscripción para el Dead Letter Topic (pull subscription)
print_message "$YELLOW" "Creando suscripción para Dead Letter Topic ${DLT_SUBSCRIPTION_NAME}..."
gcloud pubsub subscriptions create "$DLT_SUBSCRIPTION_NAME" \
    --topic="$DLT_TOPIC_NAME" \
    --message-retention-duration="1800s"
print_message "$GREEN" "✓ Suscripción DLT creada exitosamente"

# Crear la suscripción push con Dead Letter Topic
print_message "$YELLOW" "Creando suscripción ${SUBSCRIPTION_NAME} con Dead Letter Topic..."
gcloud pubsub subscriptions create "$SUBSCRIPTION_NAME" \
    --topic="$TOPIC_NAME" \
    --push-endpoint="$ENDPOINT_URL" \
    --message-retention-duration="7d" \
    --ack-deadline="10" \
    --dead-letter-topic="$DLT_TOPIC_NAME" \
    --max-delivery-attempts="$MAX_DELIVERY_ATTEMPTS"
print_message "$GREEN" "✓ Suscripción creada exitosamente con Dead Letter Topic"
print_message "$GREEN" "  - Máximo de reintentos: ${MAX_DELIVERY_ATTEMPTS}"
print_message "$GREEN" "  - Dead Letter Topic: ${DLT_TOPIC_NAME}"

print_message "$GREEN" "¡Configuración completada exitosamente!"
print_message "$GREEN" "Resumen:"
print_message "$GREEN" "- Proyecto: ${PROJECT_ID}"
print_message "$GREEN" "- Tópico: ${TOPIC_NAME}"
print_message "$GREEN" "- Suscripción: ${SUBSCRIPTION_NAME}"
print_message "$GREEN" "- Endpoint: ${ENDPOINT_URL}"
print_message "$GREEN" "- Dead Letter Topic: ${DLT_TOPIC_NAME}"
print_message "$GREEN" "- Suscripción DLT: ${DLT_SUBSCRIPTION_NAME}"
print_message "$GREEN" "- Máximo de reintentos: ${MAX_DELIVERY_ATTEMPTS}"