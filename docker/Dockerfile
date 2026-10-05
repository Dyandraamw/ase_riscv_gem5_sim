# syntax=docker/dockerfile:1
#
# ASE RISC-V + gem5 simulation environment (RISC-V GNU toolchain + gem5 RISCV/opt).
# Works on amd64 (Intel/AMD, Windows, Linux) and arm64 (Apple Silicon): build natively on each.
#
#   docker build -t ase-riscv-gem5:local -f docker/Dockerfile .
#
# Build args (all optional):
#   GEM5_BRANCH   gem5 branch of cad-polito-it/gem5 (must match ase_studio_branches.json, "stable")
#   GEM5_JOBS     parallel jobs for the gem5 build; gem5 needs ~2 GB RAM per job (default 3)
#   TOOLCHAIN_JOBS parallel jobs for the toolchain build (default: all CPUs)

############################ RISC-V GNU toolchain ############################
FROM ubuntu:22.04 AS toolchain-build
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
        autoconf automake autotools-dev curl python3 python3-pip python3-tomli \
        libmpc-dev libmpfr-dev libgmp-dev gawk build-essential bison flex texinfo gperf \
        libtool patchutils bc zlib1g-dev libexpat-dev ninja-build git cmake \
        libglib2.0-dev libslirp-dev ca-certificates \
    && rm -rf /var/lib/apt/lists/*
RUN git clone https://github.com/riscv-collab/riscv-gnu-toolchain.git /src/riscv-gnu-toolchain
WORKDIR /src/riscv-gnu-toolchain
ARG TOOLCHAIN_JOBS=0
RUN ./configure --prefix=/opt/riscv --enable-multilib \
    && make -j"$([ "${TOOLCHAIN_JOBS}" -gt 0 ] && echo "${TOOLCHAIN_JOBS}" || nproc)" \
    && /opt/riscv/bin/riscv64-unknown-elf-gcc --version

################################### gem5 ####################################
FROM ubuntu:22.04 AS gem5-build
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential git m4 scons zlib1g zlib1g-dev libprotobuf-dev protobuf-compiler \
        libprotoc-dev libgoogle-perftools-dev python3-dev python3-tk libboost-all-dev \
        pkg-config virtualenv python3-venv ca-certificates \
    && rm -rf /var/lib/apt/lists/*
ARG GEM5_BRANCH=stable
RUN git clone --branch "${GEM5_BRANCH}" --single-branch https://github.com/cad-polito-it/gem5.git /opt/gem5
WORKDIR /opt/gem5
ARG GEM5_JOBS=3
RUN virtualenv -p python3.10 /opt/venv && /opt/venv/bin/pip install scons==4 \
    && . /opt/venv/bin/activate \
    && PYTHON=/usr/bin/python3.10 PYTHON_CONFIG=/usr/bin/python3.10-config \
       scons build/RISCV/gem5.opt -j"${GEM5_JOBS}" \
    # keep only the final binary: drops ~3 GB of object files
    && mv build/RISCV/gem5.opt /opt/gem5.opt && rm -rf build && mkdir -p build/RISCV \
    && mv /opt/gem5.opt build/RISCV/gem5.opt

################################### final ###################################
FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
        python3 python3-tk make git socat ca-certificates \
        libmpc3 libmpfr6 libgmp10 libexpat1 zlib1g libprotobuf23 libgoogle-perftools4 \
    && rm -rf /var/lib/apt/lists/* \
    && git config --system --add safe.directory '*'
COPY --from=toolchain-build /opt/riscv /opt/riscv
COPY --from=gem5-build /opt/gem5 /opt/gem5
# setup_default of the simulator repo honours these overrides (note the trailing slashes)
ENV RISCV_TOOLCHAIN_PATH=/opt/riscv/bin \
    GEM5_INSTALLATION_PATH=/opt/gem5/build/ \
    GEM5_SRC=/opt/gem5/ \
    HOME=/tmp
COPY docker/ase-sim docker/ase-studio /usr/local/bin/
RUN chmod +x /usr/local/bin/ase-sim /usr/local/bin/ase-studio \
    && /opt/gem5/build/RISCV/gem5.opt --version | head -1 \
    && /opt/riscv/bin/riscv64-unknown-elf-gcc --version | head -1
# The simulator repository (with its ase_studio submodule) is mounted here.
WORKDIR /work
