# Based on https://github.com/Bforartists/Bforartists/wiki/Building-a-Bforartists-(or-Blender)-3.5-release-build-on-Rocky8-Linux
# and https://rocm.docs.amd.com/en/latest/deploy/linux/os-native/install.html

# Use the base image
FROM rockylinux:8-minimal

# Set metadata for the image
LABEL maintainer="iyadahmed430@gmail.com"

# Update the system and install required packages
RUN microdnf -y install sudo
RUN sudo microdnf -y update
RUN sudo microdnf -y install wget
RUN sudo microdnf -y install scl-utils gcc-toolset-11 bash python3 libSM
RUN sudo microdnf -y install pulseaudio-libs-devel
RUN sudo microdnf -y --enablerepo=powertools install libstdc++-static
RUN sudo microdnf -y install gcc gcc-c++ git subversion make cmake mesa-libGL-devel mesa-libEGL-devel libX11-devel libXxf86vm-devel libXi-devel libXcursor-devel libXrandr-devel libXinerama-devel
RUN sudo microdnf -y install wayland-devel wayland-protocols-devel libxkbcommon-devel dbus-devel kernel-headers

# Install Jack Audio Library
WORKDIR /jack
RUN git clone --depth 1 https://github.com/jackaudio/jack2.git
WORKDIR /jack/jack2
RUN ./waf configure
RUN ./waf install

# Install CUDA
WORKDIR /cuda
COPY ./cuda-repo-rhel8-12-2-local-12.2.0_535.54.03-1.x86_64.rpm /cuda/cuda-repo-rhel8-12-2-local-12.2.0_535.54.03-1.x86_64.rpm
RUN sudo rpm -i cuda-repo-rhel8-12-2-local-12.2.0_535.54.03-1.x86_64.rpm
RUN sudo microdnf -y clean all
RUN sudo microdnf -y install cuda-toolkit-12-2

# Install OptiX
RUN sudo microdnf -y install tar
WORKDIR /optix
COPY ./NVIDIA-OptiX-SDK-7.3.0-linux64-x86_64.sh /optix/NVIDIA-OptiX-SDK-7.3.0-linux64-x86_64.sh
RUN chmod +x ./NVIDIA-OptiX-SDK-7.3.0-linux64-x86_64.sh
RUN sudo ./NVIDIA-OptiX-SDK-7.3.0-linux64-x86_64.sh --prefix=/usr/local --include-subdir --skip-license

# HIP compiler pre-requisites
RUN sudo microdnf -y install kernel-headers kernel-devel
RUN wget https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
RUN sudo rpm -ivh epel-release-latest-8.noarch.rpm
RUN sudo crb enable

# Add ROCm repository
WORKDIR /rocm
COPY ./install_rocm_repo.sh /rocm/install_rocm_repo.sh
RUN chmod +x ./install_rocm_repo.sh
RUN sudo ./install_rocm_repo.sh

# This is the actual HIP compiler package
# powertools repo is needed for perl-File-BaseDir which is in turn needed by hip-devel
RUN sudo microdnf -y --enablerepo=powertools install rocm-hip-sdk

WORKDIR /rocm
COPY ./rocm_post_install.sh /rocm/rocm_post_install.sh
RUN chmod +x ./rocm_post_install.sh
RUN sudo ./rocm_post_install.sh

WORKDIR /workdir

CMD source /root/.bashrc
# && cd blender && BUILD_CMAKE_ARGS="-DOPTIX_ROOT_DIR=/usr/local/NVIDIA-OptiX-SDK-7.3.0-linux64-x86_64" make release
