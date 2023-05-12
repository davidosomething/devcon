FROM ubuntu:jammy

RUN apt-get update && apt-get install -y \
    curl \
    fzf \
    git \
    software-properties-common \
    wget \
    zsh \
    && add-apt-repository -y ppa:neovim-ppa/stable \
    && apt-get update -y && apt-get install -y neovim \
    && rm -rf /var/lib/apt/lists/*

RUN useradd --create-home --groups sudo --shell /usr/bin/zsh davidosomething

USER davidosomething
WORKDIR /home/davidosomething
RUN git clone https://github.com/davidosomething/dotfiles.git .dotfiles
