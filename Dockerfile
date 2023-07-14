# CUDA 11.8.0 base Ubuntu 20.04
FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu20.04

ARG USERNAME
ARG UID
ARG GID

ARG DEBIAN_FRONTEND=noninteractive
ARG DEBCONF_NOWARNINGS=yes

USER root

#python3.9 torch2.0.1(latest)
RUN apt-get update
RUN apt-get install -y software-properties-common tzdata
ENV TZ=Asia/Tokyo
RUN apt-get -y install python3.9 python3.9-distutils python3-pip
RUN python3.9 -m pip install -U pip wheel setuptools
#RUN python3.9 -m pip install torch==1.7.1+cu110 -f https://download.pytorch.org/whl/torch_stable.html
RUN python3.9 -m pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118

# Install jupyter notebook
RUN apt-get update
RUN apt-get -y upgrade
RUN python3.9 -m pip install notebook
RUN python3.9 -m pip install jupyter
#RUN python3.9 -m pip install jupyterlab

#aptget
RUN apt-get update && apt-get install -y \
    git \ 
    less \
    curl \
    sudo \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

#add user
# echo "username:password" | chpasswd
# root password is "root"
RUN echo "root:root" | chpasswd && \
    groupadd -g "${GID}" "${USERNAME}" && \
    adduser --disabled-password --uid "${UID}" --gid "${GID}" --gecos "" "${USERNAME}" && \
    echo "${USERNAME}:${USERNAME}" | chpasswd && \
    echo "%${USERNAME}    ALL=(ALL)   NOPASSWD:    ALL" >> /etc/sudoers.d/${USERNAME} && \
    chmod 0440 /etc/sudoers.d/${USERNAME}

# working directory
WORKDIR /home/${USERNAME}/work
RUN chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/work
#copy scripts
COPY ./scripts /home/${USERNAME}/scripts
RUN chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/scripts
RUN chmod -R 777 /home/${USERNAME}/scripts/
USER ${USERNAME}
#RUN jupyter notebook --generate-config

WORKDIR /home/${USERNAME}/work
# Port
EXPOSE 8888
