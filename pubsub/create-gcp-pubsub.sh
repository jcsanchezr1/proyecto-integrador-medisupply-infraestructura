#!/bin/bash

# Configuración
PROJECT_ID="clean-result-473723-t3"
TOPIC_NAME="inventory.processing.products"
SUBSCRIPTION_NAME="inventory.processing.products.processor"
ENDPOINT_URL="https://medisupply-inventory-processor-ms-1034901101791.us-central1.run.app/inventory-procesor/products/files"

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
if gcloud pubsub topics create "$TOPIC_NAME" 2>/dev/null; then
    print_message "$GREEN" "✓ Tópico creado exitosamente"
else
    if gcloud pubsub topics describe "$TOPIC_NAME" &>/dev/null; then
        print_message "$YELLOW" "→ El tópico ya existe"
    else
        print_message "$RED" "Error al crear el tópico"
        exit 1
    fi
fi

# Crear la suscripción push
print_message "$YELLOW" "Creando suscripción ${SUBSCRIPTION_NAME}..."
if gcloud pubsub subscriptions create "$SUBSCRIPTION_NAME" \
    --topic="$TOPIC_NAME" \
    --push-endpoint="$ENDPOINT_URL" \
    --message-retention-duration="7d" \
    --ack-deadline="10" 2>/dev/null; then
    print_message "$GREEN" "✓ Suscripción creada exitosamente"
else
    if gcloud pubsub subscriptions describe "$SUBSCRIPTION_NAME" &>/dev/null; then
        print_message "$YELLOW" "→ La suscripción ya existe"
        
        # Actualizar la configuración de la suscripción existente
        print_message "$YELLOW" "Actualizando configuración de la suscripción..."
        gcloud pubsub subscriptions modify-push-config "$SUBSCRIPTION_NAME" \
            --push-endpoint="$ENDPOINT_URL"
        print_message "$GREEN" "✓ Configuración de suscripción actualizada"
    else
        print_message "$RED" "Error al crear la suscripción"
        exit 1
    fi
fi

print_message "$GREEN" "¡Configuración completada exitosamente!"
print_message "$GREEN" "Resumen:"
print_message "$GREEN" "- Proyecto: ${PROJECT_ID}"
print_message "$GREEN" "- Tópico: ${TOPIC_NAME}"
print_message "$GREEN" "- Suscripción: ${SUBSCRIPTION_NAME}"
print_message "$GREEN" "- Endpoint: ${ENDPOINT_URL}"