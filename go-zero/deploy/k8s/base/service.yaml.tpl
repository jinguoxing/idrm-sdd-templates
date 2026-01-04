apiVersion: v1
kind: Service
metadata:
  name: {{PROJECT_NAME}}-api
  labels:
    app: {{PROJECT_NAME}}
    component: api
spec:
  type: ClusterIP
  ports:
    - port: 8888
      targetPort: 8888
      protocol: TCP
      name: http
  selector:
    app: {{PROJECT_NAME}}
    component: api
---
apiVersion: v1
kind: Service
metadata:
  name: {{PROJECT_NAME}}-api-nodeport
  labels:
    app: {{PROJECT_NAME}}
    component: api
spec:
  type: NodePort
  ports:
    - port: 8888
      targetPort: 8888
      nodePort: 30888
      protocol: TCP
      name: http
  selector:
    app: {{PROJECT_NAME}}
    component: api
