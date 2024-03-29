FROM ubuntu:jammy

ENV CLICOLOR=0

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

# python3-virtualenv is a hack fix, too lazy to fix mise venv right now

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

RUN wget -qO - https://mise.jdx.dev/gpg-key.pub \
  | gpg --dearmor \
  | tee /usr/share/keyrings/mise-archive-keyring.gpg 1> /dev/null
RUN echo "deb [signed-by=/usr/share/keyrings/mise-archive-keyring.gpg arch=amd64] https://mise.jdx.dev/deb stable main" \
  | tee /etc/apt/sources.list.d/mise.list
RUN apt update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y mise

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
ENV NVIM_INSTALL_ALL=1

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
  && mise install go@"${GO_VER}" \
  && mise global go "${GO_VER}" \
  && mise install nodejs@"${NODE_VER}" \
  && mise global nodejs "${NODE_VER}" \
  && mise install python@"${PYTHON_VER}" \
  && mise global python "${PYTHON_VER}"

RUN source "${HOME}/.dotfiles/zsh/dot.zshrc" \
  && mise reshim \
  && export PATH="$HOME/.local/share/mise/shims:$PATH" \
  && nvim --headless -c 'Lazy! sync' -c 'qa'

RUN source "${HOME}/.dotfiles/zsh/dot.zshrc" \
  && mise reshim \
  && export PATH="$HOME/.local/share/mise/shims:$PATH" \
  && nvim --headless +'lua vim.print(vim.json.encode(require("dko.tools").get_tools()))' +qa 2>&1 > "${HOME}/mason-tools.json" \
  && cat "${HOME}/mason-tools.json"

RUN jq -r '.[]' "${HOME}/mason-tools.json" | while read line; \
  do \
  nvim --headless -c "MasonInstall $line" +qa 2>&1; \
  done

RUN source "${HOME}/.dotfiles/zsh/dot.zshrc" \
  && mise reshim \
  && export PATH="$HOME/.local/share/mise/shims:$PATH" \
  && nvim --headless +'lua vim.print(vim.json.encode(require("dko.tools").get_mason_lsps()))' +qa 2>&1 > "${HOME}/mason-lsps.json" \
  && cat "${HOME}/mason-lsps.json"

RUN jq -r '.[]' "${HOME}/mason-lsps.json" | while read line; \
  do \
  nvim --headless -c "MasonInstall $line" +qa 2>&1; \
  done

# unset
ENV CLICOLOR=

ENTRYPOINT [ "/usr/bin/zsh" ]
