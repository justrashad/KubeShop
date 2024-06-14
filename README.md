# KubeShop

KubeShop is a microservices-based e-commerce application deployed on Kubernetes. This project demonstrates various Kubernetes features such as deployments, services, persistent storage, and monitoring.

## Features
- Microservices Architecture
- Persistent Storage
- Service Discovery and Load Balancing
- Monitoring and Logging
- CI/CD Pipeline

## Getting Started

### Prerequisites
- Docker
- Kubernetes (Minikube or a cloud provider)
- kubectl

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/justrashad/KubeShop.git
   cd KubeShop
   ```

2. Build and push Docker images for backend and frontend applications:

   ```bash
   # Create example backend application
   mkdir -p backend
   cd backend

   # Create package.json
   cat <<EOF > package.json
   {
     "name": "backend",
     "version": "1.0.0",
     "description": "Example backend application",
     "main": "server.js",
     "scripts": {
       "start": "node server.js"
     },
     "dependencies": {
       "express": "^4.17.1"
     }
   }
   EOF

   # Create server.js
   cat <<EOF > server.js
   const express = require('express');
   const app = express();
   const port = 8080;

   app.get('/', (req, res) => {
     res.send('Hello from the backend!');
   });

   app.listen(port, () => {
     console.log(`Backend app listening at http://localhost:${port}`);
   });
   EOF

   # Create Dockerfile
   cat <<EOF > Dockerfile
   # Use an official Node.js runtime as a parent image
   FROM node:14

   # Set the working directory
   WORKDIR /usr/src/app

   # Copy package.json and package-lock.json
   COPY package*.json ./

   # Install dependencies
   RUN npm install

   # Copy the rest of the application code
   COPY . .

   # Expose the port the app runs on
   EXPOSE 8080

   # Run the application
   CMD ["node", "server.js"]
   EOF

   # Build and push backend image
   docker build -t rashadw/backend:latest .
   docker push rashadw/backend:latest

   cd ..

   # Create example frontend application
   mkdir -p frontend
   cd frontend

   # Create package.json
   cat <<EOF > package.json
   {
     "name": "frontend",
     "version": "1.0.0",
     "description": "Example frontend application",
     "main": "server.js",
     "scripts": {
       "start": "node server.js"
     },
     "dependencies": {
       "express": "^4.17.1"
     }
   }
   EOF

   # Create server.js
   cat <<EOF > server.js
   const express = require('express');
   const app = express();
   const port = 80;

   app.get('/', (req, res) => {
     res.send('Hello from the frontend!');
   });

   app.listen(port, () => {
     console.log(`Frontend app listening at http://localhost:${port}`);
   });
   EOF

   # Create Dockerfile
   cat <<EOF > Dockerfile
   # Use an official Node.js runtime as a parent image
   FROM node:14

   # Set the working directory
   WORKDIR /usr/src/app

   # Copy package.json and package-lock.json
   COPY package*.json ./

   # Install dependencies
   RUN npm install

   # Copy the rest of the application code
   COPY . .

   # Expose the port the app runs on
   EXPOSE 80

   # Run the application
   CMD ["node", "server.js"]
   EOF

   # Build and push frontend image
   docker build -t rashadw/frontend:latest .
   docker push rashadw/frontend:latest

   cd ..
   ```

3. Deploy the application:
   ```bash
   kubectl apply -f k8s/ -n kubeshop
   ```

4. Access the application:
   ```bash
   minikube service backend-service -n kubeshop --url
   ```

## Monitoring and Logging

Prometheus and Grafana are used for monitoring, and the EFK stack is used for logging.

## CI/CD Pipeline

The CI/CD pipeline is implemented using GitHub Actions.

## Factory Reset

To reset the entire application by removing all resources in the `kubeshop` namespace, use the `factory_reset.sh` script.

### factory_reset.sh

```bash
#!/bin/bash

# Namespace to reset
NAMESPACE="kubeshop"

# Confirm the action
read -p "Are you sure you want to reset the entire application in the $NAMESPACE namespace? This action cannot be undone. (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
  echo "Action cancelled."
  exit 1
fi

# Delete all resources in the namespace
echo "Deleting all resources in the $NAMESPACE namespace..."

# Delete all deployments
kubectl delete deployments --all -n $NAMESPACE

# Delete all services
kubectl delete services --all -n $NAMESPACE

# Delete all pods
kubectl delete pods --all -n $NAMESPACE

# Delete all configmaps
kubectl delete configmaps --all -n $NAMESPACE

# Delete all secrets
kubectl delete secrets --all -n $NAMESPACE

# Delete all persistent volume claims
kubectl delete pvc --all -n $NAMESPACE

# Delete all statefulsets
kubectl delete statefulsets --all -n $NAMESPACE

# Delete all daemonsets
kubectl delete daemonsets --all -n $NAMESPACE

# Delete all jobs
kubectl delete jobs --all -n $NAMESPACE

# Delete all cronjobs
kubectl delete cronjobs --all -n $NAMESPACE

# Delete the namespace itself
kubectl delete namespace $NAMESPACE

echo "All resources in the $NAMESPACE namespace have been deleted."
```

## Contributing

Feel free to submit issues and pull requests.

## License

This project is licensed under the MIT License.
