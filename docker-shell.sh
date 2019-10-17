#!/bin/sh

set -e

# TODO try to determine host-IP from current context
: "${DOCKER_SHELL_HOST:=localhost}"
: "${DOCKER_SHELL_IMAGE:="thajeztah/dockershell:latest"}"
: "${DOCKER_SHELL_NONINTERACTIVE:=0}"
: "${DOCKER_SHELL_NO_WARNING:=0}"

docker_cli_plugin_metadata() {
	vendor="thaJeztah"
	version="v0.0.1"
	url="https://github.com/thaJeztah/docker-shell"
	description="Open a browser shell on the Docker Host."
	cat <<-EOF
	{"SchemaVersion":"0.1.0","Vendor":"${vendor}","Version":"${version}","ShortDescription":"${description}","URL":"${url}"}
EOF
}


get_shell_port() {
	: "${1?USAGE: get_shell_port SHELL-ID}"
	docker container inspect \
	--format '{{ with (index (index .NetworkSettings.Ports "8080/tcp") 0) }}{{ .HostPort }}{{ end }}' "${1}"
}

get_shell_address() {
	: "${1?USAGE: get_shell_address SHELL-ID}"
	printf "http://%s:%d" "${DOCKER_SHELL_HOST}" "$(get_shell_port "${1}")"
}

create_container_shell() {
	if [ "${1}" = "-q" ] || [ "${1}" = "--quiet" ]; then
		quiet=1
		shift
	fi
	shellid=$(docker container create --rm -P \
		--label com.thajeztah.docker-shell=1 \
		--pid=container:"${1}" \
		--privileged "${DOCKER_SHELL_IMAGE}")
	[ -n "${quiet}" ] || echo "Shell ${shellid} created" >&2
	echo "${shellid}"
}


create_host_shell() {
	shellid=$(docker container create --rm -P \
		--label com.thajeztah.docker-shell=1 \
		--pid=host \
		--privileged "${DOCKER_SHELL_IMAGE}")
	[ "${1}" = "-q" ] || echo "Shell ${shellid} created" >&2
	echo "${shellid}"
}

start_docker_shell() {
	: "${1?USAGE: start_docker_shell SHELL-ID}"
	docker container start "${1}" > /dev/null
	if [ "${2}" != "-q" ] && [ "${2}" != "--quiet" ]; then
		echo "Shell started and accessible at $(get_shell_address "${1}")" >&2
	fi
	echo "${1}"
}

shell_logs() {
	: "${1?USAGE: shell_logs SHELL-ID}"
		docker container logs "${@}"
}

shell_remove() {
	: "${1?USAGE: shell_remove SHELL-ID}"
	# TODO check if it's a shell container (by inspecting the label)
	docker container rm -f "${@}"
}

open_in_browser() {
	: "${1?USAGE: open_in_browser SHELL-ID}"
	open "$(get_shell_address "${1}")"
}

list_docker_shells() {
	if [ "${1}" = "-q" ] || [ "${1}" = "--quiet" ]; then
		docker ps -aq --filter label=com.thajeztah.docker-shell
	else
		docker ps -a --format 'table {{.ID}}\t{{.RunningFor}}\t{{.Status}}\t{{.Ports}}' --filter label=com.thajeztah.docker-shell | sed 's/CONTAINER\ ID/SHELL\ ID    /'
	fi
}

prune_docker_shells() {
	if [ "${1}" = "-f" ] || [ "${1}" = "--force" ]; then
		answ=y
	else
			echo "WARNING: This will terminate all running shells"
			printf "Are you sure you want to continue? [y/N] "
			read -r answ
	fi

	if [ "${answ}" = "y" ]; then
			ids=$(list_docker_shells -q)
			if [ -n "${ids}" ]; then
				# shellcheck disable=SC2086
				docker container rm -f ${ids}
			fi
		fi
}

print_warning() {
		[ "${DOCKER_SHELL_NO_WARNING}" = "1" ] && return
		echo "WARNING! This shell is unsecured and gives root access on your machine. Use at your own risk!" >&2
}

print_help() {
	cat <<-EOF
Usage:	docker shell COMMAND

Manage browser shells for your Docker host and containers

WARNING!
shells started by this plugin use an unsecured connection, have no password
protection, and can provide root access to your host. Use at your own risk!

Commands:
  create      Create a new shell and print its URL
  logs        View logs of the shell container
  open        Start a new shell and open it in the default browser
  rm          Terminate and remove a shell
  prune       Kill and prune all shells on the current host
EOF
	print_usage_common

}

create_shell() {
	if [ "${1}" = "-c" ] || [ "${1}" = "--container" ]; then
			shift
			start_docker_shell "$(create_container_shell -q "${@}")" > /dev/null
			return
	fi

	print_warning

	if [ "${1}" = "-y" ] || [ "${DOCKER_SHELL_NONINTERACTIVE}" = "1" ]; then
			[ "${1}" = "-y" ] && shift
			answ="Y"
	else
			printf "Start shell? [Y/n]: "
			read -r answ
	fi

	if [ "${answ}" = "n" ]; then
			return
	fi

	start_docker_shell "$(create_host_shell -q)" > /dev/null
}

open_shell() {
	if [ "${1}" = "--help" ]; then
			print_open_shell_help
			return
	fi

	if [ "${1}" = "-c" ] || [ "${1}" = "--container" ]; then
			shift
			open_container_shell "${@}"
			return
	fi

	shellid="$(create_host_shell -q)"
	print_warning

	if [ "${1}" != "-y" ] && [ "${1}" != "--yes" ] && [ "${DOCKER_SHELL_NONINTERACTIVE}" = "0" ]; then
			printf "Start and open shell in browser? [Y/n]: "
			read -r answ
	fi

	if [ "${answ}" = "n" ]; then
			return
	fi
	open_in_browser "$(start_docker_shell "${shellid}")"
}

print_open_shell_help() {
	cat <<-EOF
Usage:	docker shell open [OPTIONS]

Open an browser shell on your Docker host or in another container

Options:
  -c --container string    Create a shell in the given container
     --help                Print usage information and exit
  -y --yes                 Do not ask for confirmation before starting and opening the shell

EOF

	print_usage_common
}

print_usage_common() {
	cat <<-EOF

Environment variables:

  DOCKER_SHELL_HOST            The host/public IP of the docker host. Used to generate
                               the URL to open the shell in the browser (default: localhost)
  DOCKER_SHELL_IMAGE           The Docker image to use for the shell. The default is
                               "thaJeztah/dockershell:latest". The Dockerfile for the
                               image can be found on GitHub.
  DOCKER_SHELL_NONINTERACTIVE  IF set to a non-zero value, don't ask for confirmation
                               before starting and opening the shell.
  DOCKER_SHELL_NO_WARNING      If set to a non-zero value, do not warning about this
                               plugin being dangerous (default: unset)


WARNING!
shells started by this plugin use an unsecured connection, have no password
protection, and provide root access to your machine. Use at your own risk!
EOF
}

open_container_shell() {
	shellid="$(create_container_shell -q "${1}")"
	open_in_browser "$(start_docker_shell "${shellid}")"
}

case "$1" in
	docker-cli-plugin-metadata)
		docker_cli_plugin_metadata
		;;
	shell)
		shift
		case "$1" in
			create)
				shift
				create_shell "${@}"
				;;
			list|ls)
				shift
				list_docker_shells "${@}"
				;;
			logs)
				shift
				shell_logs "${@}"
				;;
			open)
				shift
				open_shell "${@}"
				;;
			prune)
				shift
				prune_docker_shells "${@}"
				;;
			rm|remove|terminate)
				shift
				remove_shell "${@}"
				;;
			*)
				print_help
				;;
		esac
		;;
esac
