#!/bin/bash
# common.sh - Fonctions utilitaires communes

# Style visuel cohérent
if [[ -z "${COLOR_HEADER+x}" ]]; then
    readonly COLOR_HEADER="\033[1;34m"
    readonly COLOR_INFO="\033[1;36m"
    readonly COLOR_SUCCESS="\033[1;32m"
    readonly COLOR_ERROR="\033[1;31m"
    readonly COLOR_RESET="\033[0m"
    readonly COLOR_WARNING="\033[1;33m"
fi

log_header() {
    echo -e "${COLOR_HEADER}"
    echo "======================================"
    echo " $1"
    echo "======================================"
    echo -e "${COLOR_RESET}"
}

log_info() {
    echo -e "${COLOR_INFO}[INFO]${COLOR_RESET} $1"
}

log_success() {
    echo -e "${COLOR_SUCCESS}[SUCCESS]${COLOR_RESET} $1"
}

log_error() {
    echo -e "${COLOR_ERROR}[ERROR]${COLOR_RESET} $1" >&2
}

log_warning() {
    echo -e "${COLOR_WARNING}[WARNING]${COLOR_RESET} $1"
}

validate_env() {
    if [ -z "${DB_PATH}" ]; then
        log_error "DB_PATH non défini"
        exit 1
    fi
}