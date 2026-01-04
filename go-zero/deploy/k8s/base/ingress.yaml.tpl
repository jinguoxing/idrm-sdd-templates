apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{PROJECT_NAME}}-ingress
  annotations:
    # generic ingress annotation, can be overridden in overlays
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
    - host: api.{{PROJECT_NAME}}.local
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: {{PROJECT_NAME}}-api
                port:
                  number: 8888
