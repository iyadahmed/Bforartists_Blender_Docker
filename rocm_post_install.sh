#!/bin/sh

sudo tee --append /etc/ld.so.conf.d/rocm.conf <<EOF
/opt/rocm/lib
/opt/rocm/lib64
EOF
sudo ldconfig

sudo tee --append ~/.bashrc <<EOF
export PATH=$PATH:/opt/rocm-5.5.1/bin:/opt/rocm-5.5.1/opencl/bin
source scl_source enable gcc-toolset-11
EOF
