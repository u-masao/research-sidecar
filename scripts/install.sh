#!/bin/bash
set -e

# Configuration
REPO_OWNER="u-masao"
REPO_NAME="research-sidecar"
BRANCH="main"
BASE_URL="https://raw.githubusercontent.com/${REPO_OWNER}/${REPO_NAME}/${BRANCH}"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO] $1${NC}"
}

log_warn() {
    echo -e "${YELLOW}[WARN] $1${NC}"
}

log_error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

# 1. Prerequisites Check
log_info "Checking prerequisites..."
for cmd in git uv make; do
    if ! command -v $cmd &> /dev/null; then
        log_error "$cmd is not installed. Please install it first."
        exit 1
    fi
done

# 2. Download Scripts
log_info "Downloading workflow scripts..."
mkdir -p scripts
for script in cycle.sh run_core.sh run_experiment.sh test_workflow.sh; do
    log_info "Fetching scripts/$script..."
    curl -fsSL "${BASE_URL}/scripts/${script}" -o "scripts/${script}"
    chmod +x "scripts/${script}"
done

# 3. Download Root Files
log_info "Downloading configuration files..."
log_info "Fetching AGENTS.md..."
TEMP_AGENTS=$(mktemp)
curl -fsSL "${BASE_URL}/AGENTS.md" -o "$TEMP_AGENTS"

AGENTS_MD="AGENTS.md"
if [ ! -f "$AGENTS_MD" ]; then
    mv "$TEMP_AGENTS" "$AGENTS_MD"
    log_info "Created $AGENTS_MD"
else
    # Check if content already exists to avoid duplication
    # Using the first line of the file as a signature
    SIGNATURE="# 役割: 研究パートナー & 実験ノート管理者"
    if ! grep -q "$SIGNATURE" "$AGENTS_MD"; then
        echo -e "\n" >> "$AGENTS_MD"
        cat "$TEMP_AGENTS" >> "$AGENTS_MD"
        log_info "Appended workflow agents instructions to $AGENTS_MD"
    else
        log_info "$AGENTS_MD already contains workflow instructions"
    fi
    rm -f "$TEMP_AGENTS"
fi

# 4. Update .gitignore
log_info "Configuring .gitignore..."
GITIGNORE=".gitignore"
if [ ! -f "$GITIGNORE" ]; then
    touch "$GITIGNORE"
fi

# Content to add
IGNORE_CONTENT="
# Research Workflow
.current_exp
trials/
"

if ! grep -q "Research Workflow" "$GITIGNORE"; then
    echo "$IGNORE_CONTENT" >> "$GITIGNORE"
    log_info "Added workflow rules to .gitignore"
else
    log_info ".gitignore already contains workflow rules"
fi

# 5. Update Makefile
log_info "Fetching scripts/rs.mk..."
curl -fsSL "${BASE_URL}/scripts/rs.mk" -o "scripts/rs.mk"

# 5. Update Makefile
log_info "Updating Makefile..."
MAKEFILE="Makefile"

if [ ! -f "$MAKEFILE" ]; then
    echo "include scripts/rs.mk" > "$MAKEFILE"
    log_info "Created Makefile with include directive"
else
    if ! grep -q "scripts/rs.mk" "$MAKEFILE"; then
        echo -e "\ninclude scripts/rs.mk" >> "$MAKEFILE"
        log_info "Appended include directive to Makefile"
    else
        log_info "Makefile already includes rs.mk"
    fi
fi


log_info "Installation Complete! 🚀"
log_info "Next steps:"
log_info "1. Edit 'scripts/run_core.sh' to match your project's command (default is 'uv run dvc repro')."
log_info "2. Run 'make rs-setup' to initialize the environment."
