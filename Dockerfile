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
  openssh-server \
  ripgrep \
  sudo \
  unzip \
  wget \
  zsh \
  && rm -rf /var/lib/apt/lists/* \
  && locale-gen en_US.UTF-8

ENV LANG en_US.UTF-8 LANGUAGE en_US:en LC_ALL en_US.UTF-8

RUN systemctl ssh start && systemctl ssh enable

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

RUN curl https://github.com/davidosomething.keys >> /home/davidosomething/.ssh/authorized_keys

ENTRYPOINT [ "/usr/bin/zsh" ]
