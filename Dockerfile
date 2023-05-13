FROM ubuntu:jammy

RUN apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    tzdata \
    software-properties-common \
  && add-apt-repository ppa:neovim-ppa/unstable -y \
  && apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    bsdmainutils \
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
    unzip \
    wget \
    zsh \
  && rm -rf /var/lib/apt/lists/* \
  && locale-gen en_US.UTF-8

ENV LANG en_US.UTF-8 LANGUAGE en_US:en LC_ALL en_US.UTF-8

RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers \
  && useradd --create-home --groups sudo --shell /usr/bin/zsh davidosomething
USER davidosomething
WORKDIR /home/davidosomething

RUN git clone https://github.com/davidosomething/dotfiles.git .dotfiles \
  && cd .dotfiles \
  && DKO_AUTO=1 ./bootstrap/symlink

RUN git clone \
  https://github.com/zdharma-continuum/zinit \
  /home/davidosomething/.local/share/zinit/bin

RUN nvim --headless -c 'Lazy! sync' -c 'qa'

ENTRYPOINT [ "/usr/bin/zsh" ]
