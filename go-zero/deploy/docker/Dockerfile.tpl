# Build stage
FROM golang:1.21-alpine AS builder

WORKDIR /app

# Install dependencies
RUN apk add --no-cache git ca-certificates tzdata

# Copy go mod files
COPY go.mod go.sum ./
RUN go mod download

# Copy source code
COPY . .

# Build the binary
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags="-w -s" -o /app/server ./api/api.go

# Runtime stage
FROM alpine:3.19

WORKDIR /app

# Install ca-certificates and timezone data
RUN apk --no-cache add ca-certificates tzdata

# Copy binary from builder
COPY --from=builder /app/server .
COPY --from=builder /app/api/etc/api.yaml ./etc/

# Set timezone
ENV TZ=Asia/Shanghai

# Expose port
EXPOSE 8888

# Run
CMD ["./server", "-f", "./etc/api.yaml"]
