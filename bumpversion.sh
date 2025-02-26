#!/bin/bash
set -e

VERSION_BUMP_TYPE=$1

echo "Bumping version..."
bump2version ${VERSION_BUMP_TYPE}


echo "Starting tagging process..."

DOCKER_REGISTRY="registry.insight-centre.org/sit/mps/felipe-phd/"

SERVICE_PROJECT_LIST="access-point adaptation-analyser adaptation-monitor adaptation-planner client-manager event-dispatcher forwarder matcher object-detection-service-gpu object-detection-service preprocessing-service query-planner scheduler slr-worker-ranking videostreamforwarder window-manager worker-profile-rating"

NEW_VERSION=v`cat VERSION`


echo 'Tagging containers and git repositories...'
echo 'Ensure latest version of all images are available...'
for SERVICE_NAME in $SERVICE_PROJECT_LIST; do
    IMAGE=${DOCKER_REGISTRY}${SERVICE_NAME}
    IMAGE_AND_TAG=${IMAGE}:master
    NEW_TAG=${IMAGE}':'${NEW_VERSION}
    if [[ $SERVICE_NAME == "object-detection-service-gpu" ]]
    then
        SERVICE_NAME="object-detection-service"
        IMAGE=${DOCKER_REGISTRY}${SERVICE_NAME}
        IMAGE_AND_TAG=${IMAGE}:master-gpu
        NEW_TAG=${IMAGE}':'${NEW_VERSION}'-gpu'
    else
        echo "Creating GIT tag in gitlab for ${SERVICE_NAME} with ${NEW_VERSION}"
        python tag_repositories.py ${SIT_TOKEN} ${SERVICE_NAME} ${NEW_VERSION}
    fi

    echo "Re-pulling latest image: ${IMAGE_AND_TAG}"
    docker pull ${IMAGE_AND_TAG}

    echo "Tagging Docker image: " $IMAGE_AND_TAG " > " $NEW_TAG
    docker tag $IMAGE_AND_TAG $NEW_TAG
    echo "pushing new Docker Image Tag to repository"
    docker push $NEW_TAG
    echo " "
done

git push origin refs/tags/${NEW_VERSION}