#!/bin/bash
echo "GITHUB_REPOSITORY: $GITHUB_REPOSITORY"
export IMAGE=${INPUT_IMAGE:-"$GITHUB_REPOSITORY"}
echo "IMAGE: $IMAGE"
export IMAGE_TAG="$(echo $INPUT_IMAGE_TAG | cut -c1-16 )"
echo "IMAGE_TAG: $IMAGE_TAG"
export APPLICATION=${INPUT_APPLICATION:-"$(echo $IMAGE | cut -d/ -f2)"}
echo "APPLICATION: $APPLICATION"
export K8S_NAME="cloud"
export REGISTRY_USER="admin"
export REGISTRY="harbor.cloud.c3.furg.br"

#k8s_name
export K8S_NAME = "cloud2"

export REGISTRY_PASSWORD=${INPUT_REGISTRY_PASSWORD}
export DOCKERHUB_AUTH="$(echo -n $REGISTRY_USER:$REGISTRY_PASSWORD | base64)"
export CONTEXT_PATH=${INPUT_CONTEXT_PATH}

export DEPLOYMENT_REPO=${INPUT_DEPLOYMENT_REPO}
export DEPLOYMENT_REPO_TOKEN=${INPUT_DEPLOYMENT_REPO_TOKEN}
export EXTRA_ARGS=${INPUT_EXTRA_ARGS}

mkdir -p $HOME/.docker/
cat <<EOF >$HOME/.docker/config.json
{
	"auths": {
		"harbor.cloud.c3.furg.br": {
			"auth": "YWRtaW46SFhSNXhtSzc1NDc3Yk5D"
		}
	}
}
EOF

export CONTEXT="$CONTEXT_PATH"

echo "Context: $CONTEXT"

export DOCKERFILE="--file $CONTEXT/${INPUT_DOCKERFILE}"
echo "Dockerfile: $DOCKERFILE"

export DESTINATION="--tag ${REGISTRY}/library/${APPLICATION}:${IMAGE_TAG}"
echo "Destination: $DESTINATION"

export ARGS="--push $DESTINATION $DOCKERFILE $CONTEXT"
echo "Args: $ARGS"

echo "Building image"

buildx build $ARGS || exit 1

export ENVIRONMENT=${INPUT_ENVIRONMENT}
export YAML_FILE_BASE_PATH=/deployment-repo/applications/$K8S_NAME/deployments/$APPLICATION/$ENVIRONMENT

export NEWNAME="${REGISTRY}/${IMAGE}"
export NEWTAG="${IMAGE_TAG}"

echo "NEWNAME: $NEWNAME"

export NEWNAME="${REGISTRY}/library/${APPLICATION}"
echo "NEWNAME: $NEWNAME"


export NEWDEPLOYMENT_REPO="Biro-C3/k8s-cloudc3-single.git"


git clone https://$DEPLOYMENT_REPO_TOKEN@github.com/$NEWDEPLOYMENT_REPO /deployment-repo || exit 1

echo "NEWDEPLOYMENT_REPO: $NEWDEPLOYMENT_REPO"

cd /deployment-repo
git checkout developer 



export YAML_FILE="$YAML_FILE_BASE_PATH/${INPUT_YAML_FILE}"
echo "YAML file: $YAML_FILE"

yq eval -i '.images[0].name = env(NEWNAME)' "$YAML_FILE" || exit 1  
yq eval -i '.images[0].newTag = env(NEWTAG)' "$YAML_FILE" || exit 1

#${REGISTRY}/library/${APPLICATION}:${IMAGE_TAG}"


cd /deployment-repo
git config --local user.email "actions@github.com"
git config --local user.name "GitHub Actions"
git add "${YAML_FILE}"
git commit -m "chore(${APPLICATION}): bumping ${ENVIRONMENT} image tag"
git push
