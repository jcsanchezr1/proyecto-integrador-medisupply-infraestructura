# Credenciales de Google Cloud Storage

## Pasos Esenciales

### 1. Crear Cuenta de Servicio
```bash
gcloud iam service-accounts create medisupply-storage-service \
  --display-name="MediSupply Storage Service" \
  --project=soluciones-cloud-2024-02
```

### 2. Asignar Permisos
```bash
gcloud projects add-iam-policy-binding soluciones-cloud-2024-02 \
  --member="serviceAccount:medisupply-storage-service@soluciones-cloud-2024-02.iam.gserviceaccount.com" \
  --role="roles/storage.objectAdmin"
```

### 3. Generar Credenciales
```bash
gcloud iam service-accounts keys create gcp-credentials.json \
  --iam-account=medisupply-storage-service@soluciones-cloud-2024-02.iam.gserviceaccount.com \
  --project=soluciones-cloud-2024-02
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

