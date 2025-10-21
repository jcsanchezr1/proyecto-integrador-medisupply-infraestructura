#!/bin/bash

# Iniciar el emulador de PubSub en segundo plano
gcloud beta emulators pubsub start --project=clean-result-473723-t3 --host-port=0.0.0.0:8120 &
PUBSUB_PID=$!

# Esperar a que el emulador esté listo
echo "Esperando que el emulador de PubSub esté listo..."
while ! curl -s http://localhost:8120 > /dev/null; do
    sleep 1
done

echo "Creando tópicos y suscripciones..."
# Crear el tópico
curl -X PUT http://localhost:8120/v1/projects/clean-result-473723-t3/topics/inventory.processing.products

# Crear la suscripción
curl -X PUT -H "Content-Type: application/json" -d '{
  "topic": "projects/clean-result-473723-t3/topics/inventory.processing.products",
  "pushConfig": {
    "pushEndpoint": "http://medisupply-procesador-inventarios:8080/inventory/products/files/process"
  }
}' http://localhost:8120/v1/projects/clean-result-473723-t3/subscriptions/inventory.processing.products.processor

# Mantener el script ejecutándose y esperar señales de terminación
wait $PUBSUB_PID