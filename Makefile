.PHONY: image install

# TODO enable buildkit once https://github.com/moby/moby/issues/38254 is resolved
image:
	cat Dockerfile | DOCKER_BUILDKIT=0 docker build -t thajeztah/dockershell https://github.com/yudai/gotty.git#v2.0.0-alpha.3 -f -

install:
	cp ./docker-shell.sh ~/.docker/cli-plugins/docker-shell 
