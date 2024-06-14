#!/bin/bash

# Variables
REPO_URL="https://github.com/justrashad/KubeShop.git"
REPO_NAME="KubeShop"
NAMESPACE="kubeshop"
CNI_PLUGIN_VERSION="v1.5.0"  # Replace with the desired version
CNI_PLUGIN_TAR="cni-plugins-linux-amd64-$CNI_PLUGIN_VERSION.tgz"  # Change arch if not on amd64
CNI_PLUGIN_INSTALL_DIR="/opt/cni/bin"
DOCKER_USERNAME="rashadw"

# Functions
function check_command {
  if ! command -v $1 &> /dev/null
  then
    echo "$1 could not be found, please install it first."
    exit 1
  fi
}

# Check for required commands
check_command git
check_command kubectl
check_command minikube
check_command crictl
check_command docker

# Install containernetworking-plugins if not already installed
if [ ! -d "$CNI_PLUGIN_INSTALL_DIR" ]; then
  echo "Installing containernetworking-plugins..."
  curl -LO "https://github.com/containernetworking/plugins/releases/download/$CNI_PLUGIN_VERSION/$CNI_PLUGIN_TAR"
  mkdir -p "$CNI_PLUGIN_INSTALL_DIR"
  tar -xf "$CNI_PLUGIN_TAR" -C "$CNI_PLUGIN_INSTALL_DIR"
  rm "$CNI_PLUGIN_TAR"
fi

# Ensure /etc/cni/net.d directory exists
if [ ! -d "/etc/cni/net.d" ]; then
  echo "Creating /etc/cni/net.d directory..."
  mkdir -p /etc/cni/net.d
fi

# Install cri-dockerd if not already installed
if ! command -v cri-dockerd &> /dev/null
then
  echo "Installing cri-dockerd..."
  git clone https://github.com/Mirantis/cri-dockerd.git
  cd cri-dockerd
  mkdir bin
  go build -o bin/cri-dockerd
  install -o root -g root -m 0755 bin/cri-dockerd /usr/local/bin/cri-dockerd
  cp -a packaging/systemd/* /etc/systemd/system
  sed -i 's,/usr/bin/dockerd,/usr/bin/dockerd --host=fd:// --add-runtime cri-dockerd=/usr/local/bin/cri-dockerd,' /etc/systemd/system/cri-docker.service
  systemctl daemon-reload
  systemctl enable cri-docker.service
  systemctl enable --now cri-docker.socket
  cd ..
fi

# Start Minikube with the 'none' driver
echo "Starting Minikube with the 'none' driver..."
minikube start --driver=none

# Clone the repository if it doesn't already exist
if [ ! -d "$REPO_NAME" ]; then
  echo "Cloning repository..."
  git clone $REPO_URL
else
  echo "Repository already exists. Pulling latest changes..."
  cd $REPO_NAME
  git pull
  cd ..
fi

cd $REPO_NAME

# Create example backend application if it doesn't already exist
if [ ! -d "backend" ]; then
  echo "Creating example backend application..."
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
  console.log(\`Backend app listening at http://localhost:\${port}\`);
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

  cd ..
else
  echo "Backend directory already exists. Skipping creation."
fi

# Build and push backend image
cd backend
docker build -t $DOCKER_USERNAME/backend:latest .
docker push $DOCKER_USERNAME/backend:latest
cd ..

# Create example frontend application if it doesn't already exist
if [ ! -d "frontend" ]; then
  echo "Creating example frontend application..."
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
  console.log(\`Frontend app listening at http://localhost:\${port}\`);
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

  cd ..
else
  echo "Frontend directory already exists. Skipping creation."
fi

# Build and push frontend image
cd frontend
docker build -t $DOCKER_USERNAME/frontend:latest .
docker push $DOCKER_USERNAME/frontend:latest
cd ..

# Delete all failed pods in the namespace
echo "Deleting all failed pods in the $NAMESPACE namespace..."
kubectl delete pods --namespace $NAMESPACE --field-selector=status.phase=Failed

# Delete all deployments in the namespace
echo "Deleting all deployments in the $NAMESPACE namespace..."
kubectl delete deployments --all -n $NAMESPACE

# Create Kubernetes namespace if it doesn't already exist
if ! kubectl get namespace $NAMESPACE; then
  echo "Creating namespace..."
  kubectl create namespace $NAMESPACE
else
  echo "Namespace $NAMESPACE already exists."
fi

# Create k8s directory and manifests if they do not exist
if [ ! -d "k8s" ]; then
  echo "Creating k8s directory and manifests..."
  mkdir k8s

  # Create backend deployment manifest
  cat <<EOF > k8s/backend-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend-deployment
  namespace: $NAMESPACE
spec:
  replicas: 3
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
      - name: backend
        image: $DOCKER_USERNAME/backend:latest
        ports:
        - containerPort: 8080
EOF

  # Create backend service manifest
  cat <<EOF > k8s/backend-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: backend-service
  namespace: $NAMESPACE
spec:
  selector:
    app: backend
  ports:
    - protocol: TCP
      port: 80
      targetPort: 8080
  type: LoadBalancer
EOF

  # Create frontend deployment manifest
  cat <<EOF > k8s/frontend-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend-deployment
  namespace: $NAMESPACE
spec:
  replicas: 3
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
      - name: frontend
        image: $DOCKER_USERNAME/frontend:latest
        ports:
        - containerPort: 80
EOF

  # Create frontend service manifest
  cat <<EOF > k8s/frontend-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
  namespace: $NAMESPACE
spec:
  selector:
    app: frontend
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
  type: LoadBalancer
EOF

else
  echo "k8s directory already exists."
fi

# Deploy the application
echo "Deploying the application..."
kubectl apply -f k8s/ -n $NAMESPACE

# Wait for the services to be up and running
echo "Waiting for services to be ready..."
kubectl wait --for=condition=available --timeout=600s deployment --all -n $NAMESPACE

# Get the Minikube service URL
echo "Getting the Minikube service URL..."
minikube service backend-service -n $NAMESPACE --url

echo "KubeShop has been successfully redeployed!"
