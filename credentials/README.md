# Credenciales de Google Cloud Storage

## Pasos Esenciales

### 1. Crear Cuenta de Servicio
```bash
gcloud iam service-accounts create medisupply-storage-service \
  --display-name="MediSupply Storage Service" \
  --project=clean-result-473723-t3
```

### 2. Asignar Permisos
```bash
gcloud projects add-iam-policy-binding clean-result-473723-t3 \
  --member="serviceAccount:medisupply-storage-service@clean-result-473723-t3.iam.gserviceaccount.com" \
  --role="roles/storage.objectAdmin"
```

### 3. Generar Credenciales
```bash
gcloud iam service-accounts keys create gcp-credentials.json \
  --iam-account=medisupply-storage-service@clean-result-473723-t3.iam.gserviceaccount.com \
  --project=clean-result-473723-t3
```

### 4. Verificar Configuración
```bash
./verify-setup.sh
```

### 5. Crear Bucket
```bash
cd ../buckets
./create-bucket.sh
```

## Estructura de Archivos
```
credentials/
├── gcp-credentials.json          # ← Tu archivo (NO subir a Git)
├── verify-setup.sh              # ← Verificación
└── README.md                    # ← Esta documentación
```

