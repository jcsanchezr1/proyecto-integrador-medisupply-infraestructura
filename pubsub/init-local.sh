#!/usr/bin/env bash
# shellcheck disable=SC2086
set -euo pipefail

# Archivo: pubsub/init-local.sh
# Este script arranca el emulador de Pub/Sub y crea topic/subscription

PROJECT_ID="clean-result-473723-t3"
HOST_PORT="0.0.0.0:8120"
EMULATOR_URL="http://localhost:8120"

start_emulator() {
  echo "Iniciando emulador de Pub/Sub..."
  # Usar & para background y guardar PID
  gcloud beta emulators pubsub start --project=${PROJECT_ID} --host-port=${HOST_PORT} &
  PUBSUB_PID=$!

  # Cuando el script reciba SIGINT/SIGTERM, terminar el emulador
  trap "echo 'Terminando emulador...'; kill ${PUBSUB_PID} || true; wait ${PUBSUB_PID} 2>/dev/null || true; exit 0" SIGINT SIGTERM EXIT
}

wait_emulator() {
  echo "Esperando que el emulador de PubSub esté listo..."
  local tries=0
  local max=60
  until curl -s ${EMULATOR_URL} >/dev/null 2>&1; do
    tries=$((tries+1))
    if [ ${tries} -ge ${max} ]; then
      echo "El emulador no respondió después de ${max} intentos" >&2
      exit 1
    fi
    sleep 1
  done
  echo "Emulador listo"
}

create_topic_and_subscription() {
  echo "Creando tópico y suscripción..."

  # Crear tópico (PUT is accepted by the emulator)
  curl -fsS -X PUT "${EMULATOR_URL}/v1/projects/${PROJECT_ID}/topics/inventory.processing.products" || {
    echo "Advertencia: no se pudo crear el tópico (puede que ya exista)" >&2
  }

  # Crear la suscripción con pushEndpoint sin espacios finales
  SUB_PAYLOAD=$(cat <<JSON
{
  "topic": "projects/${PROJECT_ID}/topics/inventory.processing.products",
  "pushConfig": {
    "pushEndpoint": "http://medisupply-inventarios-procesador:8080/inventory-procesor/products/files"
  }
}
JSON
)

  curl -fsS -X PUT -H "Content-Type: application/json" -d "${SUB_PAYLOAD}" "${EMULATOR_URL}/v1/projects/${PROJECT_ID}/subscriptions/inventory.processing.products.processor" || {
    echo "Advertencia: no se pudo crear la suscripción (puede que ya exista)" >&2
  }
}

main() {
  start_emulator
  wait_emulator
  create_topic_and_subscription

  # Mantener el proceso en foreground para que el contenedor siga corriendo
  echo "El emulador y recursos están activos (PID=${PUBSUB_PID}). Esperando señal para terminar..."
  wait ${PUBSUB_PID}
}

main "$@"