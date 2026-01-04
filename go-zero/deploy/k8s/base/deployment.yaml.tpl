apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{PROJECT_NAME}}-api
  labels:
    app: {{PROJECT_NAME}}
    component: api
spec:
  replicas: 2
  selector:
    matchLabels:
      app: {{PROJECT_NAME}}
      component: api
  template:
    metadata:
      labels:
        app: {{PROJECT_NAME}}
        component: api
    spec:
      containers:
        - name: api
          image: {{DOCKER_REGISTRY}}/{{PROJECT_NAME}}:latest
          imagePullPolicy: Always
          ports:
            - containerPort: 8888
              protocol: TCP
          envFrom:
            # 从 ConfigMap 加载非敏感配置
            - configMapRef:
                name: {{PROJECT_NAME}}-config
            # 从 Secret 加载敏感配置
            - secretRef:
                name: {{PROJECT_NAME}}-secret
          env:
            - name: TZ
              value: "Asia/Shanghai"
          resources:
            requests:
              cpu: "100m"
              memory: "128Mi"
            limits:
              cpu: "500m"
              memory: "512Mi"
          readinessProbe:
            httpGet:
              path: /health
              port: 8888
            initialDelaySeconds: 5
            periodSeconds: 10
          livenessProbe:
            httpGet:
              path: /health
              port: 8888
            initialDelaySeconds: 15
            periodSeconds: 20
