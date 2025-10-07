#!/bin/bash

# Script simple para desplegar API Gateway
set -e

PROJECT_ID="clean-result-473723-t3"
REGION="us-central1"
GATEWAY_NAME="medisupply-gateway"

echo "Desplegando API Gateway..."

# Configurar proyecto
gcloud config set project $PROJECT_ID

# Habilitar APIs
gcloud services enable apigateway.googleapis.com
gcloud services enable servicemanagement.googleapis.com
gcloud services enable servicecontrol.googleapis.com

# Crear API
gcloud api-gateway apis create $GATEWAY_NAME \
    --project=$PROJECT_ID \
    --display-name="MediSupply API Gateway"

# Crear configuración
gcloud api-gateway api-configs create ${GATEWAY_NAME}-config \
    --api=$GATEWAY_NAME \
    --openapi-spec=openapi-gateway.yaml \
    --project=$PROJECT_ID

# Crear gateway
gcloud api-gateway gateways create ${GATEWAY_NAME}-gw \
    --api=$GATEWAY_NAME \
    --api-config=${GATEWAY_NAME}-config \
    --location=$REGION \
    --project=$PROJECT_ID

# Obtener URL
GATEWAY_URL=$(gcloud api-gateway gateways describe ${GATEWAY_NAME}-gw \
    --location=$REGION \
    --project=$PROJECT_ID \
    --format="value(defaultHostname)")

echo ""
echo "¡API Gateway desplegado!"
echo "URL: https://$GATEWAY_URL"
echo "Health Check: https://$GATEWAY_URL/auth/ping"
