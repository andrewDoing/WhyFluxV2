#!/usr/bin/bash
# The flux getting started steps in one script.

: ${AZURE_LOCATION:="westus"}
: ${MY_RESOURCE_GROUP:="fluxv2-rg"}
: ${STAGING_CLUSTER_NAME:="aks-fleet-infra-stage"}
: ${PROD_CLUSTER_NAME:="aks-fleet-infra-prod"}

# Check that GITHUB_TOKEN is set
if [[ -v GITHUB_TOKEN ]];
then
    echo -e "\u2705 GITHUB_TOKEN"
else
    echo -e "\u274C GITHUB_TOKEN env var is not set"
    exit 1
fi

# Check that GITHUB_USER is set
if [[ -v GITHUB_USER ]];
then
    echo -e "\u2705 GITHUB_USER"
else
    echo -e "\u274C GITHUB_USER env var is not set"
    exit 1
fi

# Install flux by downloading precompiled binaries
curl -s https://toolkit.fluxcd.io/install.sh | sudo bash

# Login to Azure and create 2 clusters
az login
az group create --name $MY_RESOURCE_GROUP --location $AZURE_LOCATION
az aks create -g $MY_RESOURCE_GROUP -n $STAGING_CLUSTER_NAME
az aks create -g $MY_RESOURCE_GROUP -n $PROD_CLUSTER_NAME

# Get staging context
az aks get-credentials -n $STAGING_CLUSTER_NAME -g $MY_RESOURCE_GROUP

# Staging bootstrap
flux check --pre

flux bootstrap github \
  --owner=$GITHUB_USER \
  --repository=fleet-infra \
  --branch=main \
  --path=staging-cluster \
  --personal

# Staging workflow
git clone https://github.com/$GITHUB_USER/fleet-infra
cd fleet-infra

# Point flux to a sample app
flux create source git webapp \
  --url=https://github.com/stefanprodan/podinfo \
  --branch=master \
  --interval=30s \
  --export > ./staging-cluster/webapp-source.yaml

flux create kustomization webapp-common \
  --source=webapp \
  --path="./deploy/webapp/common" \
  --prune=true \
  --validation=client \
  --interval=1h \
  --export > ./staging-cluster/webapp-common.yaml

flux create kustomization webapp-backend \
  --depends-on=webapp-common \
  --source=webapp \
  --path="./deploy/webapp/backend" \
  --prune=true \
  --validation=client \
  --interval=10m \
  --health-check="Deployment/backend.webapp" \
  --health-check-timeout=2m \
  --export > ./staging-cluster/webapp-backend.yaml

flux create kustomization webapp-frontend \
  --depends-on=webapp-backend \
  --source=webapp \
  --path="./deploy/webapp/frontend" \
  --prune=true \
  --validation=client \
  --interval=10m \
  --health-check="Deployment/frontend.webapp" \
  --health-check-timeout=2m \
  --export > ./staging-cluster/webapp-frontend.yaml

# Push the manifests
git add -A && git commit -m "add staging webapp" && git push

# Get prod context
az aks get-credentials -n $STAGING_CLUSTER_NAME -g $MY_RESOURCE_GROUP

# Prod bootstrap
flux bootstrap github \
  --owner=$GITHUB_USER \
  --repository=fleet-infra \
  --path=prod-cluster \
  --personal

git pull

# Prod workflow
flux create source git webapp \
  --url=https://github.com/stefanprodan/podinfo \
  --tag-semver=">=4.0.0 <4.0.2" \
  --interval=30s \
  --export > ./prod-cluster/webapp-source.yaml

flux create kustomization webapp \
  --source=webapp \
  --path="./deploy/overlays/production" \
  --prune=true \
  --validation=client \
  --interval=10m \
  --health-check="Deployment/frontend.production" \
  --health-check="Deployment/backend.production" \
  --health-check-timeout=2m \
  --export > ./prod-cluster/webapp-production.yaml

git add -A && git commit -m "add prod webapp" && git push

flux get sources git

flux get kustomizations
