.PHONY: image install

image:
	docker build -t thajeztah/dockershell .

install:
	cp ./docker-shell.sh ~/.docker/cli-plugins/docker-shell 

release:
	docker buildx build --platform=linux/amd64,linux/arm64 -t thajeztah/dockershell --push .
