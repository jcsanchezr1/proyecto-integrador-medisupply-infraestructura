#!/bin/bash

# Script para eliminar API Gateway y todos sus recursos
set -e

PROJECT_ID="clean-result-473723-t3"
REGION="us-central1"
GATEWAY_NAME="medisupply-gateway"

echo "Eliminando API Gateway y todos sus recursos..."

# Configurar proyecto
gcloud config set project $PROJECT_ID

# Eliminar gateway
echo "Eliminando gateway..."
gcloud api-gateway gateways delete ${GATEWAY_NAME}-gw \
    --location=$REGION \
    --project=$PROJECT_ID \
    --quiet || echo "Gateway no encontrado o ya eliminado"

# Listar y eliminar todas las configuraciones del API
echo "Eliminando configuraciones del API..."
CONFIGS=$(gcloud api-gateway api-configs list \
    --api=$GATEWAY_NAME \
    --project=$PROJECT_ID \
    --format="value(name)" 2>/dev/null || echo "")

if [ ! -z "$CONFIGS" ]; then
    for config in $CONFIGS; do
        echo "Eliminando configuración: $config"
        gcloud api-gateway api-configs delete $config \
            --api=$GATEWAY_NAME \
            --project=$PROJECT_ID \
            --quiet
    done
else
    echo "No se encontraron configuraciones para eliminar"
fi

# Eliminar el API
echo "Eliminando API..."
gcloud api-gateway apis delete $GATEWAY_NAME \
    --project=$PROJECT_ID \
    --quiet || echo "API no encontrado o ya eliminado"

echo "API Gateway eliminado completamente"
