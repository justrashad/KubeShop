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

2. Deploy the application:
   ```bash
   kubectl apply -f k8s/
   ```

3. Access the application:
   ```bash
   minikube service backend-service
   ```

## Monitoring and Logging

Prometheus and Grafana are used for monitoring, and the EFK stack is used for logging.

## CI/CD Pipeline

The CI/CD pipeline is implemented using GitHub Actions.

## Contributing

Feel free to submit issues and pull requests.

## License

This project is licensed under the MIT License.
