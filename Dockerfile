FROM ubuntu:jammy

RUN apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y \
  software-properties-common \
  tzdata \
  bsdmainutils \
  build-essential \
  curl \
  file \
  fzf \
  git \
  locales \
  rsync \
  sudo \
  unzip \
  wget \
  zsh \
  libbz2-dev \
  libffi-dev \
  liblzma-dev \
  libncursesw5-dev \
  libreadline-dev \
  libsqlite3-dev \
  libssl-dev \
  libxml2-dev \
  libxmlsec1-dev \
  llvm \
  make \
  tk-dev \
  xz-utils \
  zlib1g-dev \
  && rm -rf /var/lib/apt/lists/* \
  && locale-gen en_US.UTF-8

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# ============================================================================
# unstable neovim PPA, will break dockerfile cache nightly :p
# ============================================================================

ARG DEVCON_USERNAME=davidosomething
RUN DEBIAN_FRONTEND=noninteractive add-apt-repository -y ppa:neovim-ppa/unstable \
  && apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y neovim \
  && rm -rf /var/lib/apt/lists/* \
  && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
RUN useradd \
  --create-home \
  --groups sudo,users \
  --shell /usr/bin/zsh \
  "${DEVCON_USERNAME}"
USER "${DEVCON_USERNAME}"
WORKDIR "/home/${DEVCON_USERNAME}"

# need this for ADD, USER does not change for all commands
ENV HOME="/home/${DEVCON_USERNAME}"
ENV XDG_DATA_HOME="${HOME}/.local/share"
ENV ASDF_DIR="${XDG_DATA_HOME}/asdf"
ENV XDG_CACHE_HOME="${HOME}/.cache"

SHELL ["zsh", "-c"]

# cache bust
ADD --chown="${DEVCON_USERNAME}:${DEVCON_USERNAME}" \
  https://api.github.com/repos/davidosomething/dotfiles/git/refs/heads/master \
  "${XDG_CACHE_HOME}/dotfiles-version.json"
ADD --chown="${DEVCON_USERNAME}:${DEVCON_USERNAME}" \
  https://api.github.com/repos/zdharma-continuum/zinit/git/refs/heads/main \
  "${XDG_CACHE_HOME}/zinit-version.json"

ARG NODE_VER=latest
ARG PYTHON_VER=3.11.3
ARG MASON_PKGS="\
  ansible-language-server \
  beautysh \
  black \
  css-lsp \
  cssmodules-language-server \
  docker-compose-language-service \
  dockerfile-language-server \
  editorconfig-checker \
  eslint-lsp \
  html-lsp \
  isort \
  jdtls \
  jedi-language-server \
  json-lsp \
  lua-language-server \
  markdownlint \
  prettier \
  ruff-lsp \
  selene \
  shellcheck \
  shfmt \
  stylelint-lsp \
  stylua \
  tailwindcss-language-server \
  typescript-language-server \
  vim-language-server \
  vint \
  yaml-language-server \
  yamllint \
"
# zinit will load OMZP:asdf to init this
RUN cat "${XDG_CACHE_HOME}/dotfiles-version.json" \
  && cat "${XDG_CACHE_HOME}/zinit-version.json" \
  && git clone https://github.com/asdf-vm/asdf.git "$ASDF_DIR" --branch v0.11.3 \
  && git clone https://github.com/zdharma-continuum/zinit "${XDG_DATA_HOME}/zinit/bin" \
  && git clone https://github.com/davidosomething/dotfiles.git "${HOME}/.dotfiles" \
  && DKO_AUTO=1 "${HOME}/.dotfiles/bootstrap/symlink"

RUN source "${HOME}/.dotfiles/zsh/dot.zshrc" \
  && asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git \
  && asdf install nodejs ${NODE_VER} \
  && asdf global nodejs ${NODE_VER} \
  && asdf plugin add python \
  && asdf install python ${PYTHON_VER} \
  && asdf global python ${PYTHON_VER} \
  && cat "${HOME}/.tool-versions" \
  && nvim --headless -c 'Lazy! sync' -c 'qa' \
  && nvim --headless -c "MasonInstall ${MASON_PKGS}" -c 'qa'

ENTRYPOINT [ "/usr/bin/zsh" ]
