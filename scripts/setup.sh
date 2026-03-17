#!/usr/bin/env bash
set -euo pipefail

# ╔══════════════════════════════════════════════════════════════════╗
# ║  Claude Code + Agent Teams Setup                                ║
# ║  Drop this script into any repo and run it.                     ║
# ║  First run:  full setup (tmux, agents, commands, settings).     ║
# ║  Repeat run: verify everything is in place, then launch.        ║
# ╚══════════════════════════════════════════════════════════════════╝

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

log()  { echo -e "${GREEN}[✓]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
info() { echo -e "${CYAN}[i]${NC} $1"; }
fail() { echo -e "${RED}[✗]${NC} $1"; }

EXPECTED_AGENTS=("lead" "frontend" "backend" "devops" "skeptic" "qa" "researcher")
EXPECTED_COMMANDS=("prime" "build-with-agent-team" "deploy" "cleo-install" "research")
VSCODE_EXTENSIONS=("dbaeumer.vscode-eslint" "bradlc.vscode-tailwindcss" "esbenp.prettier-vscode")
CREATED_ANYTHING=false

# ═══════════════════════════════════════════════════════════════════
# XCODE COMMAND LINE TOOLS — required for git, compilers, headers
# ═══════════════════════════════════════════════════════════════════

ensure_xcode_clt() {
  # Only relevant on macOS
  [[ "$(uname -s)" != "Darwin" ]] && return 0

  if xcode-select -p >/dev/null 2>&1; then
    log "Xcode Command Line Tools found"
    return 0
  fi

  warn "Xcode Command Line Tools not installed (required for git and build tools)"
  echo ""
  read -rp "  Install Xcode Command Line Tools now? (y/n) " INSTALL_CLT
  echo ""
  if [[ "$INSTALL_CLT" != "y" ]]; then
    fail "Xcode CLT is required. Install manually: xcode-select --install"
    return 1
  fi

  info "Installing Xcode Command Line Tools (a system dialog will appear)..."
  xcode-select --install 2>/dev/null || true

  # Wait for installation — the install happens in a separate GUI process
  info "Waiting for installation to complete (this may take a few minutes)..."
  echo "  Close the installer dialog when it finishes, then this script will continue."
  until xcode-select -p >/dev/null 2>&1; do
    sleep 5
  done

  log "Xcode Command Line Tools installed"
  return 0
}

# ═══════════════════════════════════════════════════════════════════
# HOMEBREW — macOS package manager
# ═══════════════════════════════════════════════════════════════════

ensure_homebrew() {
  # Only relevant on macOS
  [[ "$(uname -s)" != "Darwin" ]] && return 0

  if command -v brew >/dev/null 2>&1; then
    log "Homebrew found: $(brew --version | head -1)"
    return 0
  fi

  # Check Apple Silicon path before giving up
  if [[ -f /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
    log "Homebrew found (Apple Silicon): $(brew --version | head -1)"
    return 0
  fi

  warn "Homebrew is not installed (required for installing Node.js, tmux, etc.)"
  echo ""
  read -rp "  Install Homebrew now? (y/n) " INSTALL_BREW
  echo ""
  if [[ "$INSTALL_BREW" != "y" ]]; then
    fail "Homebrew is required on macOS. Install manually:"
    echo '    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
    return 1
  fi

  info "Installing Homebrew (this may take a minute)..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # On Apple Silicon, Homebrew installs to /opt/homebrew — add to PATH
  if [[ -f /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
    export PATH="/opt/homebrew/bin:$PATH"
  fi

  if command -v brew >/dev/null 2>&1; then
    log "Homebrew installed: $(brew --version | head -1)"

    # Persist Homebrew PATH for Apple Silicon
    local SHELL_RC="$HOME/.zshrc"
    [[ "$(basename "${SHELL:-}")" != "zsh" ]] && SHELL_RC="$HOME/.bashrc"
    if [[ -f /opt/homebrew/bin/brew ]] && ! grep -qF '/opt/homebrew/bin/brew' "$SHELL_RC" 2>/dev/null; then
      echo '' >> "$SHELL_RC"
      echo '# Homebrew (added by setup.sh)' >> "$SHELL_RC"
      echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$SHELL_RC"
      info "Added Homebrew to $SHELL_RC (Apple Silicon path)"
    fi
    return 0
  else
    fail "Homebrew installation failed"
    return 1
  fi
}

# ═══════════════════════════════════════════════════════════════════
# GIT — verify availability and configure identity
# ═══════════════════════════════════════════════════════════════════

ensure_git() {
  if ! command -v git >/dev/null 2>&1; then
    if [[ "$(uname -s)" == "Darwin" ]] && command -v brew >/dev/null 2>&1; then
      warn "git not found — installing via Homebrew..."
      brew install git || { fail "git installation failed"; return 1; }
    else
      fail "git is not installed. Install it manually."
      return 1
    fi
  fi
  log "Git found: $(git --version)"

  # Check if user.name and user.email are configured
  local GIT_NAME GIT_EMAIL
  GIT_NAME="$(git config --global user.name 2>/dev/null || true)"
  GIT_EMAIL="$(git config --global user.email 2>/dev/null || true)"

  if [[ -z "$GIT_NAME" ]]; then
    warn "Git user.name is not configured (required for commits)"
    read -rp "  Enter your name for git commits: " INPUT_NAME
    if [[ -n "$INPUT_NAME" ]]; then
      git config --global user.name "$INPUT_NAME"
      log "Set git user.name: $INPUT_NAME"
    fi
  fi

  if [[ -z "$GIT_EMAIL" ]]; then
    warn "Git user.email is not configured (required for commits)"
    read -rp "  Enter your email for git commits: " INPUT_EMAIL
    if [[ -n "$INPUT_EMAIL" ]]; then
      git config --global user.email "$INPUT_EMAIL"
      log "Set git user.email: $INPUT_EMAIL"
    fi
  fi

  return 0
}

# ═══════════════════════════════════════════════════════════════════
# VS CODE — CLI setup + recommended extensions
# ═══════════════════════════════════════════════════════════════════

setup_vscode() {
  # Check if 'code' command is available
  if ! command -v code >/dev/null 2>&1; then
    # Try common macOS VS Code paths
    local VSCODE_BIN=""
    for trypath in \
      "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code" \
      "$HOME/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"; do
      if [[ -f "$trypath" ]]; then
        VSCODE_BIN="$trypath"
        break
      fi
    done

    if [[ -n "$VSCODE_BIN" ]]; then
      warn "VS Code found but 'code' command is not in PATH"
      echo ""
      read -rp "  Add VS Code 'code' command to PATH? (y/n) " ADD_CODE
      if [[ "$ADD_CODE" == "y" ]]; then
        local TARGET="/usr/local/bin/code"
        sudo mkdir -p /usr/local/bin 2>/dev/null || true
        if sudo ln -sf "$VSCODE_BIN" "$TARGET" 2>/dev/null; then
          log "'code' command added to PATH"
        else
          warn "Could not add 'code' to PATH automatically"
          info "Open VS Code → Cmd+Shift+P → 'Shell Command: Install code command in PATH'"
          return 0
        fi
      else
        info "Skipping — add it later: VS Code → Cmd+Shift+P → 'Shell Command: Install code command in PATH'"
        return 0
      fi
    else
      info "VS Code not detected — skipping extension setup"
      info "If VS Code is installed elsewhere, open it → Cmd+Shift+P → 'Shell Command: Install code command in PATH'"
      return 0
    fi
  fi

  # 'code' is available — install recommended extensions
  log "VS Code CLI found: $(code --version 2>/dev/null | head -1)"
  echo ""
  info "Recommended extensions for this project:"
  echo "    ESLint              (dbaeumer.vscode-eslint)"
  echo "    Tailwind CSS        (bradlc.vscode-tailwindcss)"
  echo "    Prettier            (esbenp.prettier-vscode)"
  echo ""
  read -rp "  Install recommended VS Code extensions? (y/n) " INSTALL_EXT
  if [[ "$INSTALL_EXT" == "y" ]]; then
    for ext in "${VSCODE_EXTENSIONS[@]}"; do
      if code --list-extensions 2>/dev/null | grep -qi "$ext"; then
        log "Already installed: $ext"
      else
        info "Installing: $ext"
        code --install-extension "$ext" --force 2>/dev/null || warn "Failed to install $ext"
      fi
    done
    log "VS Code extensions installed"
  else
    info "Skipping. Install later:"
    for ext in "${VSCODE_EXTENSIONS[@]}"; do
      echo "    code --install-extension $ext"
    done
  fi
}

# ═══════════════════════════════════════════════════════════════════
# PROJECT DEPENDENCIES — npm install
# ═══════════════════════════════════════════════════════════════════

install_project_deps() {
  if [[ -d node_modules ]]; then
    log "Project dependencies already installed (node_modules exists)"
    return 0
  fi

  if [[ ! -f package.json ]]; then
    info "No package.json found — skipping npm install"
    return 0
  fi

  if ! command -v npm >/dev/null 2>&1; then
    warn "npm not available — cannot install project dependencies"
    return 1
  fi

  info "Installing project dependencies (npm install)..."
  npm install
  if [[ -d node_modules ]]; then
    log "Project dependencies installed"
    return 0
  else
    fail "npm install failed"
    return 1
  fi
}

# ═══════════════════════════════════════════════════════════════════
# TMUX — detect, install, configure
# ═══════════════════════════════════════════════════════════════════

install_tmux() {
  local OS
  OS="$(uname -s)"

  case "$OS" in
    Darwin)
      if command -v brew >/dev/null 2>&1; then
        info "Installing tmux via Homebrew..."
        brew install tmux
      elif command -v port >/dev/null 2>&1; then
        info "Installing tmux via MacPorts..."
        sudo port install tmux
      else
        fail "No package manager found. Install Homebrew first:"
        echo "    /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        echo "  Then re-run this script."
        return 1
      fi
      ;;
    Linux)
      if command -v apt-get >/dev/null 2>&1; then
        info "Installing tmux via apt..."
        sudo apt-get update -qq && sudo apt-get install -y tmux
      elif command -v dnf >/dev/null 2>&1; then
        info "Installing tmux via dnf..."
        sudo dnf install -y tmux
      elif command -v yum >/dev/null 2>&1; then
        info "Installing tmux via yum..."
        sudo yum install -y tmux
      elif command -v pacman >/dev/null 2>&1; then
        info "Installing tmux via pacman..."
        sudo pacman -S --noconfirm tmux
      elif command -v apk >/dev/null 2>&1; then
        info "Installing tmux via apk..."
        sudo apk add tmux
      else
        fail "No supported package manager found."
        echo "  Install tmux manually: https://github.com/tmux/tmux/wiki/Installing"
        return 1
      fi
      ;;
    *)
      fail "Unsupported OS: $OS"
      echo "  Install tmux manually: https://github.com/tmux/tmux/wiki/Installing"
      return 1
      ;;
  esac

  if command -v tmux >/dev/null 2>&1; then
    log "tmux installed: $(tmux -V)"
    return 0
  else
    fail "tmux installation failed"
    return 1
  fi
}

# ═══════════════════════════════════════════════════════════════════
# NODE.JS — detect, install
# ═══════════════════════════════════════════════════════════════════

install_node() {
  local OS
  OS="$(uname -s)"

  case "$OS" in
    Darwin)
      if command -v brew >/dev/null 2>&1; then
        info "Installing Node.js via Homebrew..."
        brew install node
      else
        fail "No package manager found. Install Homebrew first:"
        echo "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        return 1
      fi
      ;;
    Linux)
      if command -v apt-get >/dev/null 2>&1; then
        info "Installing Node.js via apt..."
        sudo apt-get update -qq && sudo apt-get install -y nodejs npm
      elif command -v dnf >/dev/null 2>&1; then
        info "Installing Node.js via dnf..."
        sudo dnf install -y nodejs npm
      elif command -v pacman >/dev/null 2>&1; then
        info "Installing Node.js via pacman..."
        sudo pacman -S --noconfirm nodejs npm
      else
        fail "No supported package manager found."
        echo "  Install Node.js manually: https://nodejs.org"
        return 1
      fi
      ;;
    *)
      fail "Unsupported OS: $OS"
      echo "  Install Node.js manually: https://nodejs.org"
      return 1
      ;;
  esac

  if command -v node >/dev/null 2>&1; then
    log "Node.js installed: $(node --version)"
    return 0
  else
    fail "Node.js installation failed"
    return 1
  fi
}

ensure_node() {
  if command -v node >/dev/null 2>&1; then
    log "Node.js found: $(node --version)"
    return 0
  fi

  warn "Node.js is not installed (required for Claude CLI and npm packages)"
  echo ""
  read -rp "  Install Node.js now? (y/n) " INSTALL_NODE
  echo ""
  if [[ "$INSTALL_NODE" == "y" ]]; then
    install_node
  else
    fail "Node.js is required. Install manually: https://nodejs.org"
    return 1
  fi
}

# ═══════════════════════════════════════════════════════════════════
# CLAUDE CLI — detect, install
# ═══════════════════════════════════════════════════════════════════

install_claude() {
  if ! command -v npm >/dev/null 2>&1; then
    fail "npm not available — install Node.js first"
    return 1
  fi

  info "Installing Claude CLI via npm..."
  npm install -g @anthropic-ai/claude-code

  if command -v claude >/dev/null 2>&1; then
    log "Claude CLI installed: $(claude --version 2>/dev/null | head -1)"
    return 0
  else
    fail "Claude CLI installation failed"
    echo "  Try manually: npm install -g @anthropic-ai/claude-code"
    return 1
  fi
}

ensure_claude() {
  if command -v claude >/dev/null 2>&1; then
    local CLAUDE_VERSION
    CLAUDE_VERSION="$(claude --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "unknown")"
    log "Claude CLI found: $CLAUDE_VERSION"

    # Check minimum version for agent teams (>= 2.1.32)
    if [ "$CLAUDE_VERSION" != "unknown" ]; then
      local MAJOR MINOR PATCH
      MAJOR="$(echo "$CLAUDE_VERSION" | cut -d. -f1)"
      MINOR="$(echo "$CLAUDE_VERSION" | cut -d. -f2)"
      PATCH="$(echo "$CLAUDE_VERSION" | cut -d. -f3)"
      if [ "$MAJOR" -lt 2 ] || { [ "$MAJOR" -eq 2 ] && [ "$MINOR" -lt 1 ]; } || \
         { [ "$MAJOR" -eq 2 ] && [ "$MINOR" -eq 1 ] && [ "$PATCH" -lt 32 ]; }; then
        warn "Claude $CLAUDE_VERSION — agent teams require >= 2.1.32"
        info "Update: npm install -g @anthropic-ai/claude-code@latest"
      fi
    fi
    return 0
  fi

  warn "Claude CLI is not installed"
  echo ""
  read -rp "  Install Claude CLI now? (y/n) " INSTALL_CLAUDE
  echo ""
  if [[ "$INSTALL_CLAUDE" == "y" ]]; then
    install_claude
  else
    fail "Claude CLI is required. Install: npm install -g @anthropic-ai/claude-code"
    return 1
  fi
}

ensure_tmux() {
  if command -v tmux >/dev/null 2>&1; then
    log "tmux found: $(tmux -V)"
    return 0
  fi

  warn "tmux is not installed (required for agent team orchestration)"
  echo ""
  read -rp "  Install tmux now? (y/n) " INSTALL_TMUX
  echo ""
  if [[ "$INSTALL_TMUX" == "y" ]]; then
    install_tmux
  else
    fail "tmux is required. Install manually and re-run this script."
    echo ""
    case "$(uname -s)" in
      Darwin) echo "    brew install tmux" ;;
      Linux)  echo "    sudo apt install tmux  # or your distro's package manager" ;;
      *)      echo "    https://github.com/tmux/tmux/wiki/Installing" ;;
    esac
    echo ""
    exit 1
  fi
}

# ─── Agent tmux config ───────────────────────────────────────────

ensure_tmux_config() {
  local CONF="$PROJECT_DIR/.tmux.agent.conf"

  if [ -f "$CONF" ]; then
    log "Agent tmux config exists (.tmux.agent.conf)"
    return 0
  fi

  cat > "$CONF" <<'TMUXCONF'
# ╔══════════════════════════════════════════════════════════════════╗
# ║  Agent Orchestration — tmux config                              ║
# ║  Sourced by scripts/start.sh via: tmux -f .tmux.agent.conf     ║
# ╚══════════════════════════════════════════════════════════════════╝

# ─── Mouse (resize panes, click to focus, scroll) ────────────────
set -g mouse on

# ─── Pane borders with agent labels ──────────────────────────────
set -g pane-border-status top
set -g pane-border-format " #[bold]#{pane_title} #[default]"
set -g pane-border-style "fg=colour240"
set -g pane-active-border-style "fg=colour39,bold"

# ─── Status bar ──────────────────────────────────────────────────
set -g status on
set -g status-position bottom
set -g status-style "bg=colour235,fg=colour248"
set -g status-left "#[fg=colour39,bold] #{session_name} #[default]│ "
set -g status-left-length 30
set -g status-right " #[fg=colour240]%H:%M "

# ─── Pane navigation (Alt + arrow) ──────────────────────────────
bind -n M-Left  select-pane -L
bind -n M-Right select-pane -R
bind -n M-Up    select-pane -U
bind -n M-Down  select-pane -D

# ─── Pane splitting (keep cwd) ──────────────────────────────────
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"

# ─── Scrollback ─────────────────────────────────────────────────
set -g history-limit 50000

# ─── Stability ───────────────────────────────────────────────────
set -g allow-rename off
set -sg escape-time 10
set -g default-terminal "screen-256color"
set -g focus-events on
TMUXCONF

  log "Created .tmux.agent.conf (mouse, pane labels, navigation, scrollback)"
  CREATED_ANYTHING=true
}

# ═══════════════════════════════════════════════════════════════════
# DETECT REPEAT vs FIRST RUN
# ═══════════════════════════════════════════════════════════════════

is_setup_complete() {
  [ -f .claude/settings.json ]  || return 1
  [ -f scripts/start.sh ]       || return 1
  [ -f .tmux.agent.conf ]       || return 1
  [ -d .claude/agents ]         || return 1
  [ -d .claude/commands ]       || return 1
  [ -d .claude/snapshots ]      || return 1
  for agent in "${EXPECTED_AGENTS[@]}"; do
    [ -f ".claude/agents/${agent}.md" ] || return 1
  done
  for cmd in "${EXPECTED_COMMANDS[@]}"; do
    [ -f ".claude/commands/${cmd}.md" ] || return 1
  done
  return 0
}

# ═══════════════════════════════════════════════════════════════════
# REPEAT RUN — verify + launch
# ═══════════════════════════════════════════════════════════════════

if is_setup_complete; then
  echo ""
  echo "╔══════════════════════════════════════╗"
  echo "║  Claude Code — Already Set Up        ║"
  echo "╚══════════════════════════════════════╝"
  echo ""

  ISSUES=0

  # ─── Foundation ──────────────────────────────────────────────
  if command -v git >/dev/null 2>&1; then
    log "Git found: $(git --version | sed 's/git version //')"
  else
    warn "Git not found"
    ISSUES=$((ISSUES+1))
  fi

  if [[ "$(uname -s)" == "Darwin" ]]; then
    if command -v brew >/dev/null 2>&1; then
      log "Homebrew found"
    else
      warn "Homebrew not found — some tools may not install"
      ISSUES=$((ISSUES+1))
    fi
  fi

  # ─── Tools ────────────────────────────────────────────────────
  ensure_node  || ISSUES=$((ISSUES+1))
  ensure_claude || ISSUES=$((ISSUES+1))

  # tmux: verify or offer install
  if command -v tmux >/dev/null 2>&1; then
    log "tmux found ($(tmux -V))"
  else
    warn "tmux not found"
    ISSUES=$((ISSUES+1))
    read -rp "  Install tmux now? (y/n) " FIX_TMUX
    if [[ "$FIX_TMUX" == "y" ]]; then
      install_tmux && ISSUES=$((ISSUES-1))
    fi
  fi

  # ─── tmux agent config ───────────────────────────────────────
  if [ -f .tmux.agent.conf ]; then
    log "Agent tmux config (.tmux.agent.conf)"
  else
    warn ".tmux.agent.conf missing"
    ISSUES=$((ISSUES+1))
  fi

  # ─── Project dependencies ──────────────────────────────────────
  if [ ! -f package.json ]; then
    log "No package.json — no project dependencies needed"
  elif [ -d node_modules ]; then
    log "Project dependencies installed (node_modules)"
  else
    warn "node_modules missing — run 'npm install'"
    ISSUES=$((ISSUES+1))
  fi

  # ─── VS Code extensions ───────────────────────────────────────
  if command -v code >/dev/null 2>&1; then
    log "VS Code CLI found"
    MISSING_EXT=0
    for ext in "${VSCODE_EXTENSIONS[@]}"; do
      if ! code --list-extensions 2>/dev/null | grep -qi "$ext"; then
        MISSING_EXT=$((MISSING_EXT+1))
      fi
    done
    if [ "$MISSING_EXT" -gt 0 ]; then
      warn "$MISSING_EXT recommended VS Code extension(s) missing"
      info "Re-run setup to install, or: code --install-extension <id>"
      ISSUES=$((ISSUES+1))
    else
      log "VS Code extensions: all recommended installed"
    fi
  else
    info "VS Code 'code' command not in PATH (optional)"
  fi

  # ─── start.sh sources config ─────────────────────────────────
  if grep -q "tmux.agent.conf" scripts/start.sh 2>/dev/null; then
    log "start.sh sources agent tmux config"
  else
    warn "start.sh does not source .tmux.agent.conf"
    ISSUES=$((ISSUES+1))
  fi

  # ─── User-level settings ─────────────────────────────────────
  USER_SETTINGS="$HOME/.claude/settings.json"
  if [ -f "$USER_SETTINGS" ]; then
    grep -q "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS" "$USER_SETTINGS" 2>/dev/null \
      && log "Agent teams enabled (user settings)" \
      || { warn "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS missing in $USER_SETTINGS"; ISSUES=$((ISSUES+1)); }
    grep -q '"teammateMode"' "$USER_SETTINGS" 2>/dev/null \
      && log "teammateMode set (user settings)" \
      || { warn "teammateMode missing in $USER_SETTINGS"; ISSUES=$((ISSUES+1)); }
  else
    warn "No user settings at $USER_SETTINGS"
    ISSUES=$((ISSUES+1))
  fi

  # ─── Project artifacts ───────────────────────────────────────
  log "Project settings:  .claude/settings.json"
  log "Agents (${#EXPECTED_AGENTS[@]}):        ${EXPECTED_AGENTS[*]}"
  log "Commands (${#EXPECTED_COMMANDS[@]}):      ${EXPECTED_COMMANDS[*]}"
  log "Launcher:          scripts/start.sh"

  # ─── Shell alias ─────────────────────────────────────────────
  SHELL_RC="$HOME/.zshrc"
  [ "$(basename "${SHELL:-}")" != "zsh" ] && SHELL_RC="$HOME/.bashrc"

  if grep -qF "scripts/start.sh" "$SHELL_RC" 2>/dev/null; then
    ALIAS_LINE="$(grep "scripts/start.sh" "$SHELL_RC" | head -1)"
    log "Shell alias configured: $ALIAS_LINE"
  else
    warn "No quick-launch alias in $SHELL_RC"
    ISSUES=$((ISSUES+1))
  fi

  # ─── Global commands ─────────────────────────────────────────
  if grep -qF 'cc-setup()' "$SHELL_RC" 2>/dev/null; then
    log "Global commands registered (cc, cc-setup)"
  else
    warn "Global commands (cc, cc-setup) not in $SHELL_RC"
    ISSUES=$((ISSUES+1))
  fi

  # CLEO
  if [ -f .cleo/config.json ]; then
    log "CLEO initialized"
  else
    info "CLEO not initialized (run /cleo-install inside Claude)"
  fi

  if [ "$ISSUES" -gt 0 ]; then
    echo ""
    warn "$ISSUES issue(s) found above — review before continuing"
    echo ""
    read -rp "Launch anyway? (y/n) " LAUNCH_ANYWAY
    [[ "$LAUNCH_ANYWAY" != "y" ]] && exit 0
  fi

  echo ""
  log "Launching Claude session..."
  echo ""
  exec ./scripts/start.sh
fi

# ═══════════════════════════════════════════════════════════════════
# FIRST RUN — full setup
# ═══════════════════════════════════════════════════════════════════

echo ""
echo "╔══════════════════════════════════════╗"
echo "║  Claude Code + Agent Teams Setup     ║"
echo "╚══════════════════════════════════════╝"
echo ""

# ─── Pre-flight ───────────────────────────────────────────────────

# macOS foundation: Xcode CLT → Homebrew → Git
if [[ "$(uname -s)" == "Darwin" ]]; then
  ensure_xcode_clt || { fail "Xcode Command Line Tools are required. Cannot continue."; exit 1; }
  ensure_homebrew  || { fail "Homebrew is required on macOS. Cannot continue."; exit 1; }
fi
ensure_git || { warn "Git configuration incomplete — some features may not work."; }

ensure_node || { warn "Continuing without Node.js — CLEO and some features will not be available."; }
ensure_claude || { fail "Claude CLI is required. Cannot continue."; exit 1; }
ensure_tmux

log "Pre-flight passed"
echo ""

# ─── Tmux agent config ───────────────────────────────────────────

ensure_tmux_config

# ─── User-level settings ─────────────────────────────────────────

USER_SETTINGS="$HOME/.claude/settings.json"
mkdir -p "$HOME/.claude"

if [ -f "$USER_SETTINGS" ]; then
  NEEDS_UPDATE=false

  grep -q "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS" "$USER_SETTINGS" 2>/dev/null || NEEDS_UPDATE=true
  grep -q '"teammateMode"' "$USER_SETTINGS" 2>/dev/null || NEEDS_UPDATE=true

  if [ "$NEEDS_UPDATE" = true ]; then
    info "Updating user settings for agent teams..."
    python3 -c "
import json, sys
path = sys.argv[1]
with open(path) as f:
    s = json.load(f)
s.setdefault('env', {})['CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS'] = '1'
s.setdefault('teammateMode', 'tmux')
with open(path, 'w') as f:
    json.dump(s, f, indent=2)
    f.write('\n')
" "$USER_SETTINGS" && log "Updated $USER_SETTINGS (agent teams + tmux mode)" \
                   || warn "Could not auto-update $USER_SETTINGS — add manually: env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=\"1\", teammateMode=\"tmux\""
  else
    log "User settings: agent teams + teammateMode already configured"
  fi
else
  cat > "$USER_SETTINGS" <<'JSON'
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  },
  "teammateMode": "tmux"
}
JSON
  log "Created $USER_SETTINGS (agent teams + tmux mode)"
fi

# ─── Project-level settings ──────────────────────────────────────

mkdir -p .claude

if [ -f .claude/settings.json ]; then
  # Ensure agent teams keys are present in existing project settings
  PROJ_NEEDS_UPDATE=false
  grep -q "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS" .claude/settings.json 2>/dev/null || PROJ_NEEDS_UPDATE=true
  grep -q '"teammateMode"' .claude/settings.json 2>/dev/null || PROJ_NEEDS_UPDATE=true

  if [ "$PROJ_NEEDS_UPDATE" = true ]; then
    python3 -c "
import json
with open('.claude/settings.json') as f:
    s = json.load(f)
s.setdefault('env', {})['CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS'] = '1'
s.setdefault('teammateMode', 'tmux')
with open('.claude/settings.json', 'w') as f:
    json.dump(s, f, indent=2)
    f.write('\n')
" && log "Updated .claude/settings.json (agent teams + tmux mode)" \
   || warn "Could not auto-update .claude/settings.json"
  else
    log "Project settings already configured (.claude/settings.json)"
  fi
else
  cat > .claude/settings.json <<'JSON'
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  },
  "teammateMode": "tmux"
}
JSON
  log "Created .claude/settings.json (agent teams + tmux mode)"
  CREATED_ANYTHING=true
fi

# ─── Agents (only create missing ones) ───────────────────────────

mkdir -p .claude/agents

if [ ! -f .claude/agents/lead.md ]; then
cat > .claude/agents/lead.md <<'AGENT'
---
description: Lead/PM — owns scope, task breakdown, merges, prevents redesign.
allowed-tools: Read, Glob, Edit, Bash
---

# ROLE: Lead / PM

## Responsibilities
1. Analyze the task and produce a SHARED EXECUTION CONTRACT:
   - Scope (what's in, what's out)
   - File ownership per agent (non-overlapping)
   - Acceptance criteria
   - Merge order
2. Split tasks for Frontend/Backend/DevOps with non-overlapping outputs.
3. Enforce "LOCK & PATCH": change only what is requested.
4. Ensure the project builds after each merge.
5. Do NOT implement UI/business logic — only contract, coordination, and merge.

## CRITICAL: Lead MUST NOT implement fixes
When skeptic or QA report bugs/findings:
1. **Create fix tasks** with clear descriptions of what to fix
2. **Spawn the relevant agent(s)** (frontend, backend, etc.) to implement fixes
3. **Re-run skeptic + QA** after fixes land to verify
4. **Repeat** until all checks pass

Lead's role is CONTRACT + COORDINATION + VERIFICATION ORCHESTRATION only.
Never write implementation code, UI logic, or bug fixes directly.

## Output format
- Task list per agent (bullets)
- Merge order
- Definition of Done
AGENT
CREATED_ANYTHING=true
fi

if [ ! -f .claude/agents/frontend.md ]; then
cat > .claude/agents/frontend.md <<'AGENT'
---
description: Frontend — implements UI pages, components, and client-side logic.
allowed-tools: Read, Glob, Edit, Bash
---

# ROLE: Frontend

## Lock
- Use existing UI-kit components and design tokens.
- No redesign, no new components unless Lead requests.
- Follow the project's folder patterns for pages and components.

## Responsibilities
- Implement pages/routes as specified in the contract.
- Match designs exactly: spacing, typography, layout.
- Wire forms to API endpoints per the contract.
- Handle all UI states: loading, empty, error, success.

## Deliverables
- Routes/pages + minimal layout scaffolding
- No backend logic; consume agreed contract only
- Build passes
AGENT
CREATED_ANYTHING=true
fi

if [ ! -f .claude/agents/backend.md ]; then
cat > .claude/agents/backend.md <<'AGENT'
---
description: Backend — API endpoints, database, auth, server logic.
allowed-tools: Read, Glob, Edit, Bash
---

# ROLE: Backend

## Lock
- Do NOT touch UI layout/styles.
- Keep scope to what the contract specifies.

## Responsibilities
- Implement API endpoints or server actions per the contract.
- Database schema and migrations as needed.
- Standard error format: { error: { code, message, details? } }
- Document required env vars.

## Deliverables
- API endpoints / server actions
- DB setup + migrations (if applicable)
- `.env.example` updates
- Build passes
AGENT
CREATED_ANYTHING=true
fi

if [ ! -f .claude/agents/devops.md ]; then
cat > .claude/agents/devops.md <<'AGENT'
---
description: DevOps — local/dev/prod setup, env vars, deployment, CI.
allowed-tools: Read, Glob, Edit, Bash
---

# ROLE: DevOps

## Lock
- Do not change UI or business logic code.

## Responsibilities
- Maintain `.env.example` based on backend requirements.
- Recommend and configure hosting/deployment.
- Add minimal CI checks (lint + typecheck + build).
- Document local setup steps.

## Deliverables
- Deployment configuration
- Env var checklist
- CI config (if applicable)
AGENT
CREATED_ANYTHING=true
fi

if [ ! -f .claude/agents/skeptic.md ]; then
cat > .claude/agents/skeptic.md <<'AGENT'
---
description: Skeptic — security, UX, and accessibility devil's advocate. Challenges decisions before they ship.
allowed-tools: Read, Glob, Grep, Bash, Edit
---

# ROLE: Skeptic

## Purpose
Challenge every implementation decision for security holes, UX pitfalls, accessibility gaps, edge cases, and scope creep.

## Lock
- Do NOT implement code. Your output is analysis + recommendations.
- Do NOT block progress with hypothetical risks. Every risk must be concrete and actionable.
- Do NOT redesign. Flag issues with the current approach, suggest minimal fixes.

## Review scope
1. **Security**: injection, XSS, CSRF, auth bypass, exposed secrets, missing RLS, insecure token handling.
2. **UX**: confusing flows, missing feedback (loading/error/empty states), broken mobile layouts.
3. **Accessibility**: missing labels, keyboard navigation, color contrast, screen reader support.
4. **Edge cases**: empty data, long strings, concurrent requests, network failures.
5. **Scope creep**: features or abstractions that weren't requested.

## Output format
For each finding:
```
[SEVERITY: critical | high | medium | low]
WHAT: one-line description
WHERE: file path + line or component name
WHY: concrete risk (what breaks, for whom)
FIX: minimal change to resolve it
```

## Findings automation (MANDATORY)
After every review, you MUST update `.claude/findings.md`:
- Add new findings under the appropriate section and severity heading
- Use the checkbox format: `- [ ] **Title** — description`
- Include source attribution: `Source: Skeptic review, YYYY-MM-DD`
- If a section for the reviewed component doesn't exist, create one
- Do NOT mark items as resolved — only Lead does that after fixes are verified

## Deliverables
- Structured findings list, severity-ordered (criticals first)
- `.claude/findings.md` updated with all new findings
- No fix suggestions requiring new dependencies or architectural changes unless asked
AGENT
CREATED_ANYTHING=true
fi

if [ ! -f .claude/agents/qa.md ]; then
cat > .claude/agents/qa.md <<'AGENT'
---
description: QA — structured pass/fail verification, regression checks, and contract compliance.
allowed-tools: Read, Glob, Grep, Bash
---

# ROLE: QA

## Purpose
Verify implementations meet acceptance criteria, catch regressions, and flag contract violations. Final gate before work is considered done.

## Lock
- Do NOT implement features or fix bugs. Report findings to Lead.
- Do NOT invent requirements. Test against what was specified.
- Every claim must be backed by evidence (command output, file content, build result).

## Verification process
1. **Build check**: build must pass with zero new errors.
2. **Lint check**: lint must not introduce new errors.
3. **Route verification**: new/changed routes render without runtime errors.
4. **Contract compliance**: implementation matches the execution contract.
5. **Regression check**: existing functionality still works after changes.

## Output format
```
## QA Report — [feature/task name]

### Build
- [ ] Build passes (0 new errors)
- [ ] Lint passes (0 new errors)

### Acceptance criteria
- [ ] Criterion — PASS/FAIL (evidence)

### Regression
- [ ] Existing routes still render
- [ ] No removed exports or broken imports

### Contract violations
- (list or "None")

### Verdict: PASS / FAIL
Blockers: (list if FAIL)
```

## Deliverables
- Structured pass/fail checklist per task
- Evidence-backed verdicts
AGENT
CREATED_ANYTHING=true
fi

if [ ! -f .claude/agents/researcher.md ]; then
cat > .claude/agents/researcher.md <<'AGENT'
---
description: Researcher — technical research, best practices analysis, and trade-off evaluation. Read-only.
allowed-tools: Read, Glob, Grep, WebSearch, WebFetch, Write
---

# ROLE: Researcher

## Purpose
Research best practices, patterns, and industry standards. Produce concise, actionable reports with clear recommendations.

## Lock
- Read-only: does NOT edit project source files
- Outputs research ONLY to `.claude/research/` directory
- No implementation — analysis and recommendations only

## Responsibilities
- Research best practices, patterns, and industry standards
- Analyze trade-offs between competing approaches (3-5 options)
- Check existing research in `.claude/research/` to build on prior findings
- Consider security, performance, complexity, and compatibility
- Cite real-world examples and framework documentation

## Output format
Write reports to `.claude/research/<topic-slug>.md` with:
1. Executive summary (recommended approach in 2-3 sentences)
2. Detailed analysis of each approach (pros/cons)
3. Final recommendation with implementation steps
4. Sources

## Deliverables
- Research report in `.claude/research/`
- Clear recommendation with rationale
- No code changes to project source files
AGENT
CREATED_ANYTHING=true
fi

AGENT_COUNT=0
for agent in "${EXPECTED_AGENTS[@]}"; do
  [ -f ".claude/agents/${agent}.md" ] && AGENT_COUNT=$((AGENT_COUNT+1))
done
log "Agents ready: $AGENT_COUNT/${#EXPECTED_AGENTS[@]} (${EXPECTED_AGENTS[*]})"

# ─── Commands (only create missing ones) ─────────────────────────

mkdir -p .claude/commands .claude/snapshots

if [ ! -f .claude/commands/prime.md ]; then
cat > .claude/commands/prime.md <<'CMD'
---
description: Lean codebase prime — context load + CLEO handoff (Claude Code)
allowed-tools: Read, Glob
---

# /prime — Lean Prime

Role: GSD Execution Partner (senior engineer + pragmatic PM). Ship smallest correct change. Be direct. Prevent scope creep.

## 1) Codebase prime (Glob-first, minimal reads)

CLAUDE.md is ALREADY in system context. Do NOT re-read it. Do NOT read style/token CSS files (conventions are documented in CLAUDE.md).

**Glob only** (structure scan, no file reads):
- `src/app/**/page.tsx` — route inventory
- `src/app/**/route.ts` — API endpoints
- `src/components/ui/*/index.ts` — UI-kit inventory
- `src/lib/**/*.ts` — utilities
- `src/components/**/index.ts` — feature components
- `.claude/agents/*.md` — agent roster
- `scripts/*.sh` — available scripts

**Read only these** (2-3 files max):
- `package.json` — scripts, deps, versions
- `.claude/snapshots/last-deploy.md` — previous session context (if exists)

**Report** (compact, no duplication of CLAUDE.md):
```
Routes: [list from glob]
API: [list from glob]
UI-kit: [component names from glob]
Lib: [utility files from glob]
Feature components: [from glob]
Agents: [names from .claude/agents/ glob]
Scripts: [from scripts/ glob + package.json]
Deps: [key deps from package.json]
Missing/unexpected: [anything notable]
```

## 2) MCP check (non-blocking)

Glob for `.mcp.json`. If found, note "MCP configured." If Figma work comes up later, user can verify Figma Desktop is running then. Do NOT block session on MCP verification.

## 3) CLEO session (skip — not configured)

CLEO is NOT configured for this project (no `.cleo/config.json` exists).
Do NOT call `mcp__cleo__query` or `mcp__cleo__mutate` — these tools are not in allowed-tools and will hang.
Report: `CLEO: not configured`

## 4) Session template

Output once after prime, then proceed to work:
```
Goal: (1 sentence)
Plan: (3-7 steps)
Lock: (files not to touch)
Change: (files to edit)
CLEO: [session ID + active task, or "not initialized"]
Next: (first action)
```

## Rules (always active)
- Ask only truly blocking questions; otherwise state assumptions
- LOCK & PATCH: change only what's required
- Include: exact file paths, patches, commands
- Handle states: loading / empty / error / success
- HARD NO: no new deps, no global tooling changes, no rewrites unless asked

## Team orchestration
- Agent teams use the **official Agent Teams** mechanism (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`, `teammateMode: "tmux"`)
- Split pane (tmux) is **mandatory** for team work
- Launch with `./scripts/start.sh` (tmux: Claude left pane + git watch right pane)
- Agents are defined in `.claude/agents/*.md`: lead, frontend, backend, devops, skeptic, qa
- When `/build-with-agent-team` is invoked, Lead creates the team and delegates via the official mechanism
- Unknown agent names: infer role from task context → create `.claude/agents/<name>.md`, or ask user if unclear

## Iteration close
What changed · How to verify · Next action

## Session close
Done · Remaining · Next step · Risks
CMD
CREATED_ANYTHING=true
fi

if [ ! -f .claude/commands/build-with-agent-team.md ]; then
cat > .claude/commands/build-with-agent-team.md <<'CMD'
# Agent Team Orchestration (Official Agent Teams)

Use the **official Agent Teams mechanism** (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`).
Split pane mode is automatic when running inside tmux (`teammateMode: "auto"`).

## Agent roster

Agent definitions live in `.claude/agents/*.md`:
- **lead** — Contract owner + orchestrator (you)
- **frontend** — UI + client logic
- **backend** — API + database + server logic
- **devops** — Infrastructure + deployment
- **skeptic** — Security + UX devil's advocate (review-only, no code). **Must update `.claude/findings.md`** after every review.
- **qa** — Structured pass/fail verification + regression checks

## Unknown agents

If the task references an agent name NOT in `.claude/agents/`:
1. Infer the agent's role from the task context
2. If unclear, **STOP and ask the user** what the agent does
3. Create `.claude/agents/<name>.md` with the role definition before proceeding

## Workflow

### Phase 0: Contract (Lead only)
1. Analyze the task
2. Produce a SHARED EXECUTION CONTRACT:
   - Scope (what's in, what's out)
   - File ownership per agent (non-overlapping)
   - Acceptance criteria
   - Merge order
3. Create team and spawn teammates

### Phase 1: Spawn team (official mechanism — MANDATORY)

**Use ONLY the official Agent Teams tools:**

1. **`TeamCreate`** — create the team with a descriptive name
2. **`TaskCreate`** — create tasks with descriptions, acceptance criteria, and dependencies (`addBlockedBy`)
3. **`Agent`** tool with `team_name` and `name` params — spawn each teammate with:
   - `team_name`: the team name from step 1
   - `name`: agent name (e.g., "frontend", "backend", "skeptic", "qa")
   - `mode`: "bypassPermissions" (inherits lead's permissions)
   - `run_in_background`: true (teammates work asynchronously)
   - `prompt`: full task context — teammates do NOT inherit lead's conversation history
4. Teammates appear as **split panes automatically** in tmux — no manual pane management needed

**Anti-patterns (DO NOT DO):**
- ❌ Manually creating tmux panes with `tmux split-window`
- ❌ Running `claude --dangerously-skip-permissions` via `tmux send-keys`
- ❌ Using `cat prompt.md | claude` pipe patterns
- ❌ Any manual tmux pane management for agents

**After spawning:** Stay quiet. Teammates send messages automatically when done. Only speak when there's a blocker or all agents finish.

### Phase 2: Coordination
- Teammates claim tasks via `TaskUpdate` and mark them completed when done
- Use `TaskUpdate` with `addBlockedBy` to set dependencies (e.g., QA blocked by implementation tasks)
- Teammates communicate via `SendMessage` — messages are delivered automatically
- Lead reviews outputs against contract when teammates report back

### Phase 3: Fix Cycle (MANDATORY when skeptic/QA find issues)

When skeptic or QA report findings (HIGH or MEDIUM severity):

1. **Lead MUST NOT fix bugs directly** — lead is coordination only
2. **Create fix tasks** with clear descriptions referencing the findings
3. **Spawn the relevant agent(s)** (frontend, backend, etc.) to implement fixes
4. **After fixes land**, re-run skeptic + QA:
   - Create new review/verification tasks blocked by the fix tasks
   - Spawn fresh skeptic + QA agents to re-verify
5. **Repeat** until skeptic + QA report clean (no HIGH/MEDIUM findings)

**Anti-patterns (DO NOT DO):**
- ❌ Lead editing implementation files to fix bugs found by reviewers
- ❌ Skipping re-verification after fixes
- ❌ Marking findings resolved without agent-verified fixes

### Phase 4: Cleanup
1. Send `SendMessage` with `type: "shutdown_request"` to each teammate
2. Wait for all shutdown confirmations
3. Run `TeamDelete` to clean up team resources
4. Update `.claude/findings.md` with resolved items

## Findings automation
- **Skeptic** must update `.claude/findings.md` after every review:
  - Add new findings under the appropriate section and severity heading
  - Mark resolved items with ~~strikethrough~~ and commit context
- **Lead** marks findings resolved when fixes are verified and merged

## Rules
- Agents MUST NOT edit files outside their contracted scope
- **Lead MUST NOT implement code, fix bugs, or write patches** — only contract, coordination, task creation, agent spawning, and verification orchestration
- When reviewers find bugs: create tasks → spawn agents → re-verify. Never self-fix.
- `npm run build` must pass after all changes
- If an agent starts doing another agent's job, STOP and redirect

## Launch
If not already in tmux, user should start with: `./scripts/start.sh`
CMD
CREATED_ANYTHING=true
fi

if [ ! -f .claude/commands/deploy.md ]; then
cat > .claude/commands/deploy.md <<'CMD'
---
description: Commit, deploy, verify, and snapshot session state for next prime
allowed-tools: Bash, Read, Edit, Write, Glob, Grep
---

# /deploy — Commit & Deploy

## 1) Pre-flight (parallel)

Run all at once:
- `git status` — uncommitted changes?
- `git remote -v` — remote configured?
- `git branch --show-current` — current branch?
- Glob `.vercel/project.json` OR `netlify.toml` — hosting connected?
- Glob `.cleo/config.json` — CLEO active?

**If no remote**: STOP — "No git remote."
**If no changes**: Ask — "Working tree clean. Force deploy? (y/n)"

## 2) Build gate

```bash
npm run build
```

**If build fails**: STOP. Show error. Do NOT commit broken code.

## 3) Lint gate (if script exists)

```bash
npm run lint 2>&1 || true
```

Report warnings but don't block. Only block on errors.

## 4) Commit

Analyze changes with `git diff --stat` and `git status`.

Stage changed files (specific files, NOT `git add -A`):
- Stage source code changes
- Stage `.claude/commands/` if modified
- Stage `CLAUDE.md` if modified
- Do NOT stage `.env*`, credentials, `.cleo/*.db*`

Conventional commit message:
- Format: `type(scope): description`
- Types: feat, fix, chore, refactor, style, docs
- Keep subject under 72 chars

## 5) Push

```bash
git push origin <current-branch>
```

## 6) Session snapshot (for next /prime)

Create/overwrite `.claude/snapshots/last-deploy.md`:

```markdown
# Last Deploy Snapshot
Generated: [ISO timestamp]
Branch: [branch]
Commit: [short hash] [commit message]

## Changes deployed
[git diff --stat output]

## Build status
[pass/fail + any warnings]

## Context for next /prime
- Key files changed: [list]
- New components added: [list, if any]
- New routes added: [list, if any]
- Breaking changes: [none / description]
- Follow-up needed: [none / description]
```

## 7) CLEO update (if .cleo/ exists)

If `.cleo/config.json` exists and session is active, record deployment event.

## 8) Output report

```
Deploy Complete
═══════════════
Commit:   [hash] [message]
Branch:   [branch] → origin/[branch]
Build:    [pass/fail]
Snapshot: .claude/snapshots/last-deploy.md

Next prime will auto-load this snapshot for context.
```
CMD
CREATED_ANYTHING=true
fi

if [ ! -f .claude/commands/cleo-install.md ]; then
cat > .claude/commands/cleo-install.md <<'CMD'
---
description: Install CLEO and adapt it to the current project's stack, conventions, and structure
allowed-tools: Bash, Read, Edit, Write, Glob, Grep
---

# /cleo-install — Inject CLEO into Project

## 1) Pre-flight (parallel)

Run all at once:
- `which cleo` — CLI installed?
- `node -v` — Node.js available?
- Glob `.cleo/config.json` — already initialized?
- Glob `CLAUDE.md` — project conventions present?

**If no Node.js**: STOP — "CLEO requires Node.js."
**If .cleo/config.json exists**: Ask — "CLEO already initialized. Reinitialize? (preserves tasks.db)"

## 2) Install CLEO (if `which cleo` fails)

```bash
npm install -g @cleocode/cleo
```

Verify: `cleo --version`

## 3) Initialize

```bash
cleo init
```

## 4) Detect project context (token-lean)

**CLAUDE.md is in system context — do NOT re-read.** Extract from memory:
- Framework + version
- Language + strictness
- Styling approach
- Key conventions
- Existing team structure (.claude/agents/)

**Read only** `package.json` for stack confirmation.

## 5) Adapt .cleo/config.json

| Field | Value | Source |
|---|---|---|
| `defaults.labels` | `["<framework>", "<styling>"]` | CLAUDE.md / package.json |
| `session.sessionTimeoutHours` | `24` | Active dev default |
| `session.autoStartSession` | `true` | Reduce ceremony |
| `validation.maxActiveTasks` | `1` | Focus enforcement |

## 6) Inject into CLAUDE.md (append only)

If CLAUDE.md exists AND does not already contain "## CLEO":

```markdown

## CLEO Task Management
- Session: `ct-cleo` skill or MCP (`mcp__cleo__query` / `mcp__cleo__mutate`)
- Task discovery: `query tasks find` (NOT `tasks list` — too expensive)
- Memory: BRAIN 3-layer (search → timeline → fetch)
- Skills: ct-cleo, ct-orchestrator, ct-research-agent, ct-epic-architect, ct-task-executor, ct-dev-workflow
```

**Do NOT touch existing sections.** Append at end only.

## 7) Update prime.md (conditional)

If `.claude/commands/prime.md` exists, ensure the CLEO session step is present.
prime.md already has a conditional CLEO section — verify it's there.

## 8) Preserve (do NOT modify)

- `.claude/agents/*` — agent definitions
- `.claude/settings.json` — project settings (teammateMode, etc.)
- `scripts/start.sh` — tmux launcher
- Existing CLAUDE.md conventions (sections above the append)
- `src/` — no source code changes

## 9) Verify

```bash
cleo --version && ls .cleo/ && echo "CLEO ready"
```

## 10) Output report

```
CLEO Injected
═════════════
Version:    [cleo --version]
Project:    [package.json name]
Config:     .cleo/config.json (adapted)
Database:   .cleo/tasks.db

Next → Run /prime to start a CLEO-integrated session
```
CMD
CREATED_ANYTHING=true
fi

if [ ! -f .claude/commands/research.md ]; then
cat > .claude/commands/research.md <<'CMD'
---
description: Spawn a researcher agent to analyze best practices, patterns, or trade-offs
allowed-tools: Bash, Read, Write, Glob, Grep
---

# /research — Research Agent

Spawn a researcher agent that produces an actionable report. The agent writes
findings to `.claude/research/`.

## Arguments

`/research <topic or question>`

If no arguments provided, infer the research topic from the current conversation context.

## Procedure

### 1) Gather prior research context

Scan `.claude/research/` for existing reports. For each, read the first 10 lines
(title + summary) to check relevance. Include relevant prior research as context
so the agent builds on previous findings instead of starting from scratch.

### 2) Spawn the researcher

Use the **Agent** tool (subagent) — NOT manual tmux panes:

- `name`: "researcher"
- `run_in_background`: true
- `prompt`: Include project context (from CLAUDE.md in system context),
  prior research summaries, and the research task.
  The agent must write its report to `.claude/research/<topic-slug>.md`.

### 3) Report

Tell the user:
- Topic being researched
- Output file path
- The agent is running in background and will notify when done

## Notes

- The researcher is READ-ONLY for project source files
- Writes ONLY to `.claude/research/`
- Previous research is reused as context, not duplicated
- Agent definition: `.claude/agents/researcher.md`
CMD
CREATED_ANYTHING=true
fi

CMD_COUNT=0
for cmd in "${EXPECTED_COMMANDS[@]}"; do
  [ -f ".claude/commands/${cmd}.md" ] && CMD_COUNT=$((CMD_COUNT+1))
done
log "Commands ready: $CMD_COUNT/${#EXPECTED_COMMANDS[@]} (${EXPECTED_COMMANDS[*]})"

# ─── Tmux launcher (only create if missing) ──────────────────────

mkdir -p scripts

if [ ! -f scripts/start.sh ]; then
cat > scripts/start.sh <<'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail

# Derive session name from project directory (portable across projects)
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SESSION="$(basename "$PROJECT_DIR" | tr '[:upper:].' '[:lower:]-')"
TMUX_CONF="$PROJECT_DIR/.tmux.agent.conf"

command -v tmux  >/dev/null 2>&1 || { echo "tmux not found — run ./scripts/setup.sh to install"; exit 1; }
command -v claude >/dev/null 2>&1 || { echo "claude not found"; exit 1; }

# Kill previous session if exists
tmux kill-session -t "$SESSION" 2>/dev/null || true

# Build tmux flags — use agent config if present
TMUX_FLAGS=()
if [ -f "$TMUX_CONF" ]; then
  TMUX_FLAGS+=(-f "$TMUX_CONF")
fi

# Create session in project dir
tmux "${TMUX_FLAGS[@]}" new-session -d -s "$SESSION" -c "$PROJECT_DIR"

# Set agent teams env var for the session (inherited by teammate panes)
tmux set-environment -t "$SESSION" CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS 1

# Layout: left 60% (Claude), right 40% (git watch)
tmux split-window -h -p 40 -t "$SESSION:0.0" -c "$PROJECT_DIR"

# Pane labels
tmux set-option -t "$SESSION" pane-border-status top
tmux set-option -t "$SESSION" pane-border-format " #{pane_title} "
tmux select-pane -t "$SESSION:0.0" -T "CLAUDE"
tmux select-pane -t "$SESSION:0.1" -T "GIT WATCH"

# Left pane: launch Claude with agent teams enabled
# Official Agent Teams: teammates auto-appear as tmux split panes
# Requires: CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1 (env) + teammateMode: "tmux" (settings)
tmux send-keys -t "$SESSION:0.0" "export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1 && claude --dangerously-skip-permissions" C-m

# Right pane: git status + diff watch loop
tmux send-keys -t "$SESSION:0.1" "while true; do clear; date; echo '── git status ──'; git status -sb; echo; echo '── changed files ──'; git diff --stat; sleep 3; done" C-m

# Focus Claude pane
tmux select-pane -t "$SESSION:0.0"
exec tmux attach -t "$SESSION"
SCRIPT
chmod +x scripts/start.sh
log "Created scripts/start.sh (tmux launcher with agent teams support)"
CREATED_ANYTHING=true
else
  log "scripts/start.sh already exists"
fi

# ─── CLEO install (optional, first run only) ─────────────────────

if [ ! -f .cleo/config.json ]; then
  echo ""
  if command -v node >/dev/null 2>&1; then
    read -rp "Install CLEO now? (y/n) " INSTALL_CLEO
    if [[ "$INSTALL_CLEO" == "y" ]]; then
      if command -v cleo >/dev/null 2>&1; then
        log "CLEO already installed: $(cleo --version)"
      else
        info "Installing CLEO..."
        npm install -g @cleocode/cleo || { warn "npm install failed. Install manually."; }
      fi
      if command -v cleo >/dev/null 2>&1; then
        info "Initializing CLEO..."
        cleo init || warn "cleo init failed. Run manually: cleo init"
      fi
    else
      info "Skipping CLEO. Run /cleo-install inside Claude later."
    fi
  else
    warn "Node.js not found — skipping CLEO. Install Node.js first."
  fi
else
  log "CLEO already initialized"
fi

# ─── .gitignore additions ────────────────────────────────────────

if [ -f .gitignore ]; then
  IGNORE_ENTRIES=(".cleo/*.db" ".cleo/*.db-*" ".cleo/brain.db" ".env" ".env.*")
  for entry in "${IGNORE_ENTRIES[@]}"; do
    if ! grep -qF "$entry" .gitignore 2>/dev/null; then
      echo "$entry" >> .gitignore
    fi
  done
  log "Updated .gitignore (CLEO DBs, env files)"
else
  info "No .gitignore found — skipping"
fi

# ─── Project dependencies ──────────────────────────────────────

install_project_deps

# ─── VS Code setup ─────────────────────────────────────────────

setup_vscode

# ─── Shell alias for quick launch ─────────────────────────────

register_shell_alias() {
  local PROJECT_NAME
  PROJECT_NAME="$(basename "$PROJECT_DIR" | tr '[:upper:]' '[:lower:]')"

  # Derive short alias: first letter of each word, or first 2 chars
  # e.g., "paypong" → "pp", "my-app" → "ma"
  local ALIAS_NAME
  if [[ "$PROJECT_NAME" == *-* ]]; then
    # Hyphenated: take first letter of each segment → "my-cool-app" → "mca"
    ALIAS_NAME="$(echo "$PROJECT_NAME" | sed 's/\([a-z]\)[a-z]*-*/\1/g')"
  else
    # Single word: take first two chars → "paypong" → "pp"
    ALIAS_NAME="${PROJECT_NAME:0:1}${PROJECT_NAME:0:1}"
  fi

  # Detect shell config file
  local SHELL_RC
  if [ -n "${ZSH_VERSION:-}" ] || [ "$(basename "${SHELL:-}")" = "zsh" ]; then
    SHELL_RC="$HOME/.zshrc"
  else
    SHELL_RC="$HOME/.bashrc"
  fi

  echo ""
  info "Quick-launch alias: type '$ALIAS_NAME' from the project dir to start Claude"
  read -rp "  Alias name [$ALIAS_NAME]: " CUSTOM_ALIAS
  ALIAS_NAME="${CUSTOM_ALIAS:-$ALIAS_NAME}"

  # Check for conflicts
  if grep -qF "alias ${ALIAS_NAME}=" "$SHELL_RC" 2>/dev/null; then
    warn "Alias '$ALIAS_NAME' already exists in $SHELL_RC — skipping"
    return 0
  fi

  local ALIAS_CMD="alias ${ALIAS_NAME}='cd \"${PROJECT_DIR}\" && ./scripts/start.sh'"
  local COMMENT="# ${PROJECT_NAME} — Claude session launcher"

  echo "" >> "$SHELL_RC"
  echo "$COMMENT" >> "$SHELL_RC"
  echo "$ALIAS_CMD" >> "$SHELL_RC"

  log "Added alias '${ALIAS_NAME}' to $SHELL_RC"
  info "Run 'source $SHELL_RC' or open a new terminal to use it"
}

register_shell_alias

# ─── Global commands (cc, cc-setup) ──────────────────────────────

register_global_commands() {
  local SHELL_RC="$HOME/.zshrc"
  [[ "$(basename "${SHELL:-}")" != "zsh" ]] && SHELL_RC="$HOME/.bashrc"

  # Check if already registered
  if grep -qF 'cc-setup()' "$SHELL_RC" 2>/dev/null; then
    log "Global commands already registered (cc, cc-setup)"
    return 0
  fi

  echo ""
  info "Global commands: 'cc' starts Claude, 'cc-setup' runs setup — work in any project"
  read -rp "  Add 'cc' and 'cc-setup' to $SHELL_RC? (y/n) " ADD_GLOBAL
  if [[ "$ADD_GLOBAL" != "y" ]]; then
    info "Skipping global commands. Add manually later."
    return 0
  fi

  cat >> "$SHELL_RC" <<'GLOBALCMDS'

# Claude Code — global commands (added by setup.sh)
cc() {
  if [[ -f scripts/start.sh ]]; then
    ./scripts/start.sh "$@"
  elif [[ -f start.sh ]]; then
    ./start.sh "$@"
  else
    echo "No start script found. Run cc-setup first."
    return 1
  fi
}
cc-setup() {
  if [[ -f scripts/setup.sh ]]; then
    bash scripts/setup.sh "$@"
  elif [[ -f setup.sh ]]; then
    bash setup.sh "$@"
  else
    echo "No setup.sh found. Copy it into scripts/ from an existing project."
    return 1
  fi
}
GLOBALCMDS

  log "Added 'cc' and 'cc-setup' to $SHELL_RC"
  info "Run 'source $SHELL_RC' or open a new terminal to use them"
}

register_global_commands

# ─── Clean up obsolete files ──────────────────────────────────────

if [ -f .claude/team-session.sh ]; then
  warn "Found obsolete .claude/team-session.sh (old manual tmux approach)"
  info "Agent teams now use the official mechanism — teammates auto-create split panes"
  read -rp "  Remove .claude/team-session.sh? (y/n) " REMOVE_OLD
  if [[ "$REMOVE_OLD" == "y" ]]; then
    rm .claude/team-session.sh
    log "Removed .claude/team-session.sh"
  fi
fi

if [ -f .claude/team.md ]; then
  info "Found .claude/team.md (team description) — keeping for reference"
fi

# ─── Summary + Launch ────────────────────────────────────────────

echo ""
echo "╔══════════════════════════════════════╗"
echo "║  Setup Complete                      ║"
echo "╚══════════════════════════════════════╝"
echo ""
echo "  Tmux:"
echo "    .tmux.agent.conf             Agent-optimized config (mouse, pane labels, nav)"
echo "    scripts/start.sh             Launcher (sources .tmux.agent.conf)"
echo ""
echo "  Agent Teams (Official Mechanism):"
echo "    CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1  Enabled in settings + tmux environment"
echo "    teammateMode: tmux                      Teammates auto-create split panes"
echo "    .claude/settings.json                   Project-level settings"
echo "    ~/.claude/settings.json                 User-level settings"
echo "    .claude/agents/              ${#EXPECTED_AGENTS[@]} agents: ${EXPECTED_AGENTS[*]}"
echo ""
echo "  Commands:"
echo "    .claude/commands/            ${#EXPECTED_COMMANDS[@]} commands: ${EXPECTED_COMMANDS[*]}"
echo "    .claude/snapshots/           Deploy snapshot dir"
echo ""
echo "  Dev Environment:"
echo "    Xcode CLT + Homebrew + Git   Foundation tools"
echo "    Node.js + npm                Runtime + package manager"
echo "    node_modules/                Project dependencies"
if command -v code >/dev/null 2>&1; then
echo "    VS Code extensions:          ESLint, Tailwind CSS, Prettier"
fi
echo ""
echo "  Quick launch:"
echo "    cc                           Start Claude session (any project)"
echo "    cc-setup                     Run setup (any project)"
echo ""
echo "  Inside Claude:"
echo "    /prime                       Prime the session with codebase context"
echo "    /build-with-agent-team       Spawn agent team (split panes auto-created)"
echo "    /research <topic>            Spawn research agent for best practices"
echo "    /deploy                      Commit, push, snapshot"
echo "    /cleo-install                Install + configure CLEO (if skipped)"
echo ""
echo "  How agent teams work:"
echo "    1. start.sh launches Claude inside tmux"
echo "    2. /build-with-agent-team creates team via official Agent Teams API"
echo "    3. Teammates auto-appear as tmux split panes"
echo "    4. Shift+Down cycles between teammates, click pane to interact"
echo "    5. Lead coordinates via shared task list + messaging"
echo ""
echo "  Tmux shortcuts (inside session):"
echo "    Alt + Arrow keys             Navigate between panes"
echo "    Shift + Down                 Cycle through teammates (in-process mode)"
echo "    Prefix + |                   Split pane horizontally"
echo "    Prefix + -                   Split pane vertically"
echo "    Prefix + z                   Zoom/unzoom current pane"
echo "    Mouse                        Click to focus, drag to resize"
echo ""

log "Launching Claude session..."
echo ""
exec ./scripts/start.sh
