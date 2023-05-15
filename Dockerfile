FROM ubuntu:jammy

RUN apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y \
  software-properties-common \
  tzdata \
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
  rsync \
  sudo \
  unzip \
  wget \
  zsh \
  && rm -rf /var/lib/apt/lists/* \
  && locale-gen en_US.UTF-8

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

EXPOSE 22

RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers \
  && useradd --create-home --groups sudo --shell /usr/bin/zsh davidosomething
USER davidosomething
WORKDIR /home/davidosomething

# cache bust
ADD --chown=davidosomething:davidosomething \
  https://api.github.com/repos/davidosomething/dotfiles/git/refs/heads/master \
  dotfiles-version.json
RUN git clone https://github.com/davidosomething/dotfiles.git .dotfiles \
  && cd .dotfiles \
  && DKO_AUTO=1 ./bootstrap/symlink

ADD --chown=davidosomething:davidosomething \
  https://api.github.com/repos/zdharma-continuum/zinit/git/refs/heads/main \
  zinit-version.json
RUN git clone \
  https://github.com/zdharma-continuum/zinit \
  /home/davidosomething/.local/share/zinit/bin \
  && zsh -c "source /home/davidosomething/.dotfiles/zsh/dot.zshrc"

RUN nvim --headless -c 'Lazy! sync' -c 'qa'

ENTRYPOINT [ "/usr/bin/zsh" ]
