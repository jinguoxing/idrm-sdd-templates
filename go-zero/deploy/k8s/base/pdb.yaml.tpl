apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: {{PROJECT_NAME}}-api-pdb
spec:
  minAvailable: 1
  selector:
    matchLabels:
      app: {{PROJECT_NAME}}
      component: api
