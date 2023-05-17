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

ARG DEVCON_USERNAME=davidosomething
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers \
  && useradd \
  --create-home \
  --groups sudo,users \
  --shell /usr/bin/zsh \
  "${DEVCON_USERNAME}"
USER "${DEVCON_USERNAME}"
WORKDIR "/home/${DEVCON_USERNAME}"

# need this for ADD, USER does not change for all commands
ENV HOME "/home/${DEVCON_USERNAME}"
ENV XDG_DATA_HOME "${HOME}/.local/share"
ENV ASDF_DIR "${XDG_DATA_HOME}/asdf"
ENV XDG_CACHE_HOME "${HOME}/.cache"

SHELL ["zsh", "-c"]

# cache bust
ADD --chown="${DEVCON_USERNAME}:${DEVCON_USERNAME}" \
  https://api.github.com/repos/davidosomething/dotfiles/git/refs/heads/master \
  "${XDG_CACHE_HOME}/dotfiles-version.json"
RUN cat "${XDG_CACHE_HOME}/dotfiles-version.json" \
  && git clone https://github.com/davidosomething/dotfiles.git \
  "${HOME}/.dotfiles" \
  && DKO_AUTO=1 "${HOME}/.dotfiles/bootstrap/symlink"

# zinit will load OMZP:asdf to init this
RUN git clone https://github.com/asdf-vm/asdf.git "$ASDF_DIR" --branch v0.11.3

ADD --chown="${DEVCON_USERNAME}:${DEVCON_USERNAME}" \
  https://api.github.com/repos/zdharma-continuum/zinit/git/refs/heads/main \
  "${XDG_CACHE_HOME}/zinit-version.json"
RUN cat "${XDG_CACHE_HOME}/zinit-version.json" \
  && git clone https://github.com/zdharma-continuum/zinit "${XDG_DATA_HOME}/zinit/bin"

RUN source "${HOME}/.dotfiles/zsh/dot.zshrc" \
  && asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git \
  && asdf install nodejs latest \
  && asdf global nodejs latest \
  && cat "${HOME}/.tool-versions"

RUN nvim --headless -c 'Lazy! sync' -c 'qa'

ENTRYPOINT [ "/usr/bin/zsh" ]
