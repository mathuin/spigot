docker login -e="$DOCKER_EMAIL" -u="$DOCKER_USERNAME" -p="$DOCKER_PASSWORD" $DOCKER_REGISTRY
docker build -t $DOCKER_REGISTRY/$IMAGE .
docker push $DOCKER_REGISTRY/$IMAGE