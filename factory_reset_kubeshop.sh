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
