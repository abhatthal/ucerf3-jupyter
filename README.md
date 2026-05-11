# UCERF3 Jupyter
This Docker project provides a Jupyerlab session with a web terminal for executing UCERF3 scripts.
## Download
Download latest build of the ucerf3_jup image. This image is prebuilt and will use OpenJDK 21 with the latest version of OpenSHA from opensha/opensha:etas-launcher-stable.

> docker pull sceccode/ucerf3_jup:latest

[DockerHub Repository](https://hub.docker.com/repository/docker/sceccode/ucerf3_jup): sceccode/ucerf3_jup

## Build
If you want to ensure you have the latest changes, you can build the image yourself in a few minutes.

> docker build -t sceccode/ucerf3_jup .

## Run
> docker run -p 8888:8888 --name ucerf3_jup sceccode/ucerf3_jup:latest

You can also mount a volume for notebooks or target UCERF3 outputs.
> docker run --rm -p 8888:8888 -v $HOME/notebooks:/home/scecuser/notebooks -v $HOME/target:/home/scecuser/target sceccode/ucerf3_jup:latest

After the container is running, access Jupyterlab with the link specified in the Docker logs.

## Debugging
Get interactive bash shell for active container
> docker exec -it $(docker ps | awk '{print $1}' | tail -n 1) /bin/bash


