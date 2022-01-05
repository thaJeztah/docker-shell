.PHONY: image install run

image:
	docker build -t thajeztah/ddshell .

install:
	docker extension install thajeztah/ddshell

uninstall:
	docker extension rm thajeztah/ddshell

run:
	docker run -d --rm --pid=host --privileged -p 8129:8080 thajeztah/ddshell

release:
	docker buildx build --platform=linux/amd64,linux/arm64 -t thajeztah/ddshell --push .
