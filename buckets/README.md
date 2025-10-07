# Bucket de Google Cloud Storage

## Crear Bucket

### Configuración por Defecto
```bash
./create-bucket.sh
```

### Bucket Público
```bash
./create-bucket.sh --public
```

### Configuración Personalizada
```bash
GCP_PROJECT_ID=mi-proyecto \
BUCKET_NAME=mi-bucket \
./create-bucket.sh
```

## Estructura del Bucket
```
medisupply-images-bucket/
├── providers/    # Logos de proveedores
└── products/     # Imágenes de productos
```

## URLs de Ejemplo
```
# Proveedores
https://storage.googleapis.com/medisupply-images-bucket/providers/logo_uuid.jpg

# Productos
https://storage.googleapis.com/medisupply-images-bucket/products/product_uuid.jpg
```

## Prerrequisitos
- Google Cloud SDK instalado
- Proyecto `clean-result-473723-t3` configurado
- Permisos de Storage Admin