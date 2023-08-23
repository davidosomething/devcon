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
  jq \
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
  python3-venv \
  && rm -rf /var/lib/apt/lists/* \
  && locale-gen en_US.UTF-8 \
  && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# python3-virtualenv is a hack fix, too lazy to fix rtx venv right now

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

RUN wget -qO - https://rtx.pub/gpg-key.pub \
  | gpg --dearmor \
  | tee /usr/share/keyrings/rtx-archive-keyring.gpg 1> /dev/null
RUN echo "deb [signed-by=/usr/share/keyrings/rtx-archive-keyring.gpg arch=amd64] https://rtx.pub/deb stable main" \
  | tee /etc/apt/sources.list.d/rtx.list
RUN apt update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y rtx


RUN curl -LO https://github.com/neovim/neovim/releases/download/nightly/nvim-linux64.tar.gz \
  && tar -xzf nvim-linux64.tar.gz \
  && rm -rf nvim-linux64.tar.gz \
  && ln -fs /nvim-linux64/bin/nvim /usr/local/bin/nvim

ARG DEVCON_USERNAME=davidosomething
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
ENV XDG_CACHE_HOME="${HOME}/.cache"

SHELL ["zsh", "-c"]

# cache bust
ADD --chown="${DEVCON_USERNAME}:${DEVCON_USERNAME}" \
  https://api.github.com/repos/davidosomething/dotfiles/git/refs/heads/master \
  "${XDG_CACHE_HOME}/dotfiles-version.json"
ADD --chown="${DEVCON_USERNAME}:${DEVCON_USERNAME}" \
  https://api.github.com/repos/zdharma-continuum/zinit/git/refs/heads/main \
  "${XDG_CACHE_HOME}/zinit-version.json"

RUN cat "${XDG_CACHE_HOME}/dotfiles-version.json" \
  && cat "${XDG_CACHE_HOME}/zinit-version.json" \
  && git clone https://github.com/zdharma-continuum/zinit "${XDG_DATA_HOME}/zinit/bin" \
  && git clone https://github.com/davidosomething/dotfiles.git "${HOME}/.dotfiles" \
  && DKO_AUTO=1 "${HOME}/.dotfiles/bootstrap/symlink"

ARG GO_VER=1.21
ARG NODE_VER=20
ARG PYTHON_VER=3.11.3
RUN source "${HOME}/.dotfiles/zsh/dot.zshrc" \
  && rtx install go@"${GO_VER}" \
  && rtx global go "${GO_VER}" \
  && rtx install nodejs@"${NODE_VER}" \
  && rtx global nodejs "${NODE_VER}" \
  && rtx install python@"${PYTHON_VER}" \
  && rtx global python "${PYTHON_VER}" \
  && cat "${HOME}/.tool-versions"

RUN source "${HOME}/.dotfiles/zsh/dot.zshrc" && rtx reshim && export PATH="$HOME/.local/share/rtx/shims:$PATH" \
  && nvim --headless -c 'Lazy! sync' -c 'qa'

RUN source "${HOME}/.dotfiles/zsh/dot.zshrc" && rtx reshim && export PATH="$HOME/.local/share/rtx/shims:$PATH" \
  && MASON_TOOLS="$(nvim --headless +'lua vim.print(vim.json.encode(require("dko.tools").get_tools()))' +q 2>&1 | jq -r 'sort | .[]')" \
  nvim --headless -c "MasonInstall ${MASON_TOOLS}" -c 'qa'

RUN source "${HOME}/.dotfiles/zsh/dot.zshrc" && rtx reshim && export PATH="$HOME/.local/share/rtx/shims:$PATH" \
  && MASON_LSPS="$(nvim --headless +'lua vim.print(vim.json.encode(require("dko.tools").get_mason_lsps()))' +q 2>&1 | jq -r 'sort | .[]')" \
  nvim --headless -c "MasonInstall ${MASON_LSPS}" -c 'qa'

ENTRYPOINT [ "/usr/bin/zsh" ]
