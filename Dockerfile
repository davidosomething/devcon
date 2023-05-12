FROM ubuntu:jammy

RUN DEBIAN_FRONTEND=noninteractive apt-get update \
  && apt-get install -y tzdata software-properties-common \
  && add-apt-repository ppa:neovim-ppa/unstable -y \
  && DEBIAN_FRONTEND=noninteractive apt-get update \
  && apt-get install -y \
    build-essential \
    curl \
    file \
    fuse \
    fzf \
    git \
    libfuse2 \
    locales \
    neovim \
    ripgrep \
    software-properties-common \
    sudo \
    wget \
    zsh \
  && rm -rf /var/lib/apt/lists/*

RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8 LANGUAGE en_US:en LC_ALL en_US.UTF-8

RUN useradd --create-home --groups sudo --shell /usr/bin/zsh davidosomething
USER davidosomething
WORKDIR /home/davidosomething

RUN DKO_AUTO=1 \
  git clone https://github.com/davidosomething/dotfiles.git .dotfiles \
  && cd .dotfiles \
  && ./bootstrap/symlink

ENTRYPOINT [ "/usr/bin/zsh" ]
