: "${CONTAINER_REGISTRY:=ghcr.io}"
: "${GITHUB_REPOSITORY_OWNER:=terrateamio}"
: "${BASE_IMAGE_NAME:=terrat-base}"
BASE_IMAGE_TAG="20241206-1440-ba8518c"
BASE_IMAGE="${CONTAINER_REGISTRY}/${GITHUB_REPOSITORY_OWNER}/${BASE_IMAGE_NAME}:${BASE_IMAGE_TAG}"
