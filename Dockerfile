#
# Build an Ubuntu installation for UCERF3-ETAS in Jupyter
# Sourced from https://strike.scec.org/scecpedia/OpenSHA-Jupyter
#
FROM ubuntu:jammy
LABEL org.opencontainers.image.authors="bhatthal@usc.edu"

# Define Build and runtime arguments
# These accept userid and groupid from the command line
#ARG APP_UNAME
#ARG APP_GRPNAME
#ARG APP_UID
#ARG APP_GID
#ARG BDATE

# The following ENV set the username for this testcase: scecuser
# Hardcode the user and userID here for testing
ENV APP_UNAME=scecuser \
APP_GRPNAME=scec \
APP_UID=1000 \
APP_GID=20 \
BDATE=20250213

# Retrieve the userid and groupid from the args so 
# Define these parameters to support building and deploying on EC2 so user is not root
# and for building the model and adding the correct date into the label
RUN echo $APP_UNAME $APP_GRPNAME $APP_UID $APP_GID $BDATE

RUN apt-get -y update
RUN apt-get -y upgrade
ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=America/Los_Angeles

RUN apt-get install -y build-essential git wget rsync openjdk-21-jdk jupyter \
	libproj-dev proj-data proj-bin libgeos-dev vim nano emacs \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Setup Owners
# Group add duplicates "staff" so just continue if it doesn't work
RUN groupadd -f --non-unique --gid $APP_GID $APP_GRPNAME
RUN useradd -ms /bin/bash -G $APP_GRPNAME --uid $APP_UID $APP_UNAME

#Define interactive user
USER $APP_UNAME

# Move to the user directory where the gmsvtoolkit is installed and built

ENV PATH="/home/$APP_UNAME/miniconda3/bin:${PATH}"
ARG PATH="/home/$APP_UNAME/miniconda3/bin:${PATH}"

WORKDIR /home/$APP_UNAME

RUN ARCH=$(uname -m) \
	&& if [ "$ARCH" = "x86_64" ]; then \
        wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O /tmp/miniconda.sh; \
    elif [ "$ARCH" = "aarch64" ]; then \
        wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-aarch64.sh -O /tmp/miniconda.sh; \
    else \
        echo "Unsupported architecture: $ARCH" && exit 1; \
    fi \
    && mkdir /home/$APP_UNAME/.conda \
    && bash /tmp/miniconda.sh -b \
    && rm -f /tmp/miniconda.sh \
    && echo "Running $(conda --version)" \
    && conda update conda \
    && conda create -n scec-dev \
    && conda init bash

RUN echo 'conda activate scec-dev' >> /home/$APP_UNAME/.bashrc \
    && bash /home/$APP_UNAME/.bashrc \
    && conda install python=3.10 pip numpy notebook

RUN conda install -c conda-forge jupyterlab jupyterhub

# Get a copy of the launcher and test cases
WORKDIR /home/$APP_UNAME
RUN git clone https://github.com/opensha/ucerf3-etas-launcher.git
RUN git clone https://github.com/sceccode/ucerf3_etas_test_cases.git

# UCERF3-ETAS environment
ENV ETAS_LAUNCHER=/home/$APP_UNAME/ucerf3-etas-launcher
ENV ETAS_SIM_DIR=/home/$APP_UNAME/target
ENV PATH="$PATH:$ETAS_LAUNCHER/sbin"

# Build UCERF3-ETAS
WORKDIR /home/$APP_UNAME
RUN u3etas_opensha_update.sh -d

# Output mount
VOLUME /home/$APP_UNAME/target
WORKDIR /home/$APP_UNAME/target

# Add metadata to dockerfile using labels
LABEL "org.scec.project"="U3ETAS-Jupyter"
LABEL org.scec.responsible_person="Akash Bhatthal"
LABEL org.scec.primary_contact="bhatthal@usc.edu"
LABEL version="$BDATE"

WORKDIR /home/$APP_UNAME

VOLUME ["/home/scecuser/notebooks"]

#ENTRYPOINT ["/bin/bash"]
ENTRYPOINT ["/usr/bin/jupyter","lab","--ip=0.0.0.0","--port=8080", \
			"--notebook-dir=/home/scecuser/notebooks","--allow-root","--no-browser"]

