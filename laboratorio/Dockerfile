# 🐳 Dockerfile Profissional para Android Kernel Build (Moonstone/Lahaina)
# Base: Ubuntu 20.04 LTS (compatível com NDK r23b)
# Target: Snapdragon 695 (moonstone) - MSM 5.4
# Toolchain: Clang r416183b (Android Clang 12.0.8)

ARG UBUNTU_VERSION=20.04
FROM ubuntu:${UBUNTU_VERSION}

# Metadados
LABEL maintainer="DevSan AGI <devsan@deivisan.dev>"
LABEL description="Android Kernel Build Environment - Moonstone (Snapdragon 695)"
LABEL version="1.0.0"

# Variáveis de ambiente
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=America/Sao_Paulo
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# Usuário non-root
ARG USERNAME=builder
ARG USER_UID=1000
ARG USER_GID=1000

# Instalar dependências base
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    bc \
    bison \
    ca-certificates \
    cpio \
    curl \
    flex \
    git \
    gnupg \
    kmod \
    libelf-dev \
    libssl-dev \
    lsb-release \
    make \
    openssh-client \
    python3 \
    python3-pip \
    rsync \
    software-properties-common \
    sudo \
    wget \
    xz-utils \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

# Instalar ccache para acelerar rebuilds
RUN apt-get update && apt-get install -y ccache \
    && rm -rf /var/lib/apt/lists/*

# Criar usuário builder
RUN groupadd -g ${USER_GID} ${USERNAME} && \
    useradd -m -u ${USER_UID} -g ${USER_GID} -s /bin/bash ${USERNAME} && \
    echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/builder

# Criar diretórios de trabalho
RUN mkdir -p /kernel /output /ccache && \
    chown -R ${USERNAME}:${USERNAME} /kernel /output /ccache

# Configurar ccache
RUN echo "max_size = 50G" > /home/${USERNAME}/.ccache/ccache.conf && \
    echo "compression = true" >> /home/${USERNAME}/.ccache/ccache.conf && \
    chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/.ccache

# Baixar Android NDK r23b (contém Clang r416183b)
# URL oficial: https://dl.google.com/android/repository/android-ndk-r23b-linux.zip
WORKDIR /tmp
RUN wget -q --show-progress --progress=bar:force https://dl.google.com/android/repository/android-ndk-r23b-linux.zip && \
    unzip -q android-ndk-r23b-linux.zip && \
    rm android-ndk-r23b-linux.zip && \
    mv android-ndk-r23b /opt/android-ndk-r23b && \
    rm -rf /tmp/*

# Verificar versão do Clang r416183b
RUN /opt/android-ndk-r23b/toolchains/llvm/prebuilt/linux-x86_64/bin/clang --version | head -1

WORKDIR /kernel
USER ${USERNAME}

# Variáveis de ambiente para build
ENV PATH="/opt/android-ndk-r23b/toolchains/llvm/prebuilt/linux-x86_64/bin:${PATH}"
ENV CC=clang
ENV CXX=clang++
ENV AR=llvm-ar
ENV NM=llvm-nm
ENV LD=ld.lld
ENV STRIP=llvm-strip
ENV OBJCOPY=llvm-objcopy
ENV OBJDUMP=llvm-objdump
ENV READELF=llvm-readelf

# Configurar ccache para LLVM
ENV CCACHE_DIR="/ccache"
ENV PATH="/usr/lib/ccache:${PATH}"

# Volumes padrão
VOLUME ["/kernel", "/output", "/ccache"]

# Entrypoint
ENTRYPOINT ["/bin/bash"]
CMD ["--login"]

# Healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD clang --version || exit 1
