#!/bin/bash

export ACR_NAME=$(az acr list  -g ${RESOURCE_GROUP_NAME} --query [0].name -o tsv)
export ACR_SERVER=$(az acr show -n $ACR_NAME -g ${RESOURCE_GROUP_NAME} --query 'loginServer' -o tsv)
export ACR_USER_NAME=$(az acr credential show -n $ACR_NAME -g ${RESOURCE_GROUP_NAME} --query 'username' -o tsv)
export ACR_PASSWORD=$(az acr credential show -n $ACR_NAME -g ${RESOURCE_GROUP_NAME} --query 'passwords[0].value' -o tsv)

# Build and push docker image to ACR
echo "Get image name and version......"

IMAGE_NAME=$(mvn help:evaluate "-Dexpression=project.artifactId" -q -DforceStdout)
IMAGE_VERSION=$(mvn help:evaluate "-Dexpression=project.version" -q -DforceStdout)

echo "Docker build and push to ACR Server ${ACR_SERVER} with image name ${IMAGE_NAME} and version ${IMAGE_VERSION}"

mvn clean package -DskipTests
cd target

docker login -u ${ACR_USER_NAME} -p ${ACR_PASSWORD} ${ACR_SERVER}

export DOCKER_BUILDKIT=1
docker buildx create --use
docker buildx build --platform linux/amd64 -t ${ACR_SERVER}/${IMAGE_NAME}:${IMAGE_VERSION} --pull --file=Dockerfile . --load
docker push ${ACR_SERVER}/${IMAGE_NAME}:${IMAGE_VERSION}

# Enable Helm support
azd config set alpha.aks.helm on