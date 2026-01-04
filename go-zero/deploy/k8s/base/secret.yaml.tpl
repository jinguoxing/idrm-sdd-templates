apiVersion: v1
kind: Secret
metadata:
  name: {{PROJECT_NAME}}-secret
type: Opaque
stringData:
  # Base64 encoding is handled by Kustomize or K8s
  db-password: "{{DB_PASSWORD}}"
  access-secret: "{{ACCESS_SECRET}}"
