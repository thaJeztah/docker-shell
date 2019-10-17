## Docker Shell Docker CLI plugin

Just a fun experiment to try to provide a browser-based shell for Docker hosts
and containers.

> **WARNING!**
> Shells started by this plugin use an unsecured connection, have no password
> protection, and provide root access to your machine. Use at your own risk!

To use it:

1. create the plugins directory

    ```bash
    mkdir -p ~/.docker/cli-plugins
    ```
3. download the "plugin", save it as ` ~/.docker/cli-plugins/docker-shell` (note:
   no `.sh` extension!), and make it executable

    ```bash
    curl https://raw.githubusercontent.com/thaJeztah/docker-shell/master/docker-shell.sh > ~/.docker/cli-plugins/docker-shell
    chmod +x ~/.docker/cli-plugins/docker-shell
    ```

4. run `docker help` command to verify the plugin was installed succesfully. It
   should be listed under "Management Commands":

    ```bash
    docker help
    ...
    Management Commands:
      ...
      service     Manage services
      shell*      Open a browser shell on the Docker Host. (thaJeztah, v0.0.1)
      stack       Manage Docker stacks
      ...
    ```

5. run `docker shell help` to see use information

    ```bash
    Usage:	docker shell COMMAND
    
    Manage browser shells for your Docker host and containers
    
    WARNING!
    shells started by this plugin use an unsecured connection, have no password
    protection, and can provide root access to your host. Use at your own risk!
    
    Commands:
      create      Create a new shell without starting
      logs        View logs of the shell container
      open        Start a new shell and open it in the default browser
      rm          Terminate and remove a shell
      start       Start a new shell and print its URL
      prune       Kill and prune all shells on the current host
    ```

### Start your first shell

Type `docker shell open`, and press `ENTER` to start the shell, and open it
in your browser.

```console
docker shell open

WARNING! This shell is unsecured and gives root access on your machine. Use at your own risk!
Start and open shell in browser? [Y/n]: 

Shell started and accessible at http://localhost:32840
```

Close your browser to terminate the shell.

For more help on the `open` subcommand, type `docker shell open --help`:

```console
docker shell open --help

Usage:	docker shell open [OPTIONS]

Open an browser shell on your Docker host or in another container

Options:
  -c --container string    Create a shell in the given container
     --help                Print usage information and exit
  -y --yes                 Do not ask for confirmation before starting and opening the shell


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
```

### View open shells

```console
docker shell ls

SHELL ID            CREATED             STATUS              PORTS
2efb3eaa14af        12 seconds ago      Up 10 seconds       0.0.0.0:32847->8080/tcp
83dd896066ff        14 seconds ago      Up 12 seconds       0.0.0.0:32846->8080/tcp
ca5e6d6c3166        16 seconds ago      Up 14 seconds       0.0.0.0:32845->8080/tcp
```

### Terminate and remove all shells

Run `docker shell prune` to terminate and remove all shells:

```console
docker shell prune

WARNING: This will terminate all running shells
Are you sure you want to continue? [y/N] y
2efb3eaa14af
83dd896066ff
ca5e6d6c3166
```
