#!/bin/bash
# logging.sh - Système de logging avancé

# Récupérer le niveau de log depuis l'environnement ou utiliser une valeur par défaut
LOG_LEVEL=${LOG_LEVEL:-1}
SHOW_SEPARATORS=${SHOW_SEPARATORS:-true}
USE_COLORS=${USE_COLORS:-1}

# Définition des constantes (seulement à la première exécution)
if [[ -z "${_LOGGING_INITIALIZED+x}" ]]; then
    readonly _LOGGING_INITIALIZED=true
    
    # Niveaux de log
    readonly LOG_LEVEL_MINIMAL=0
    readonly LOG_LEVEL_NORMAL=1
    readonly LOG_LEVEL_VERBOSE=2
    readonly LOG_LEVEL_DEBUG=3
    
    # Couleurs (uniquement si activées)
    if [[ "$USE_COLORS" == "1" ]]; then
        readonly COLOR_HEADER="\033[1;34m"     # Bleu gras
        readonly COLOR_INFO="\033[1;36m"       # Cyan gras
        readonly COLOR_SUCCESS="\033[1;32m"    # Vert gras
        readonly COLOR_WARNING="\033[1;33m"    # Jaune gras
        readonly COLOR_ERROR="\033[1;31m"      # Rouge gras
        readonly COLOR_DEBUG="\033[1;35m"      # Magenta gras
        readonly COLOR_RESET="\033[0m"         # Reset
    else
        readonly COLOR_HEADER=""
        readonly COLOR_INFO=""
        readonly COLOR_SUCCESS=""
        readonly COLOR_WARNING=""
        readonly COLOR_ERROR=""
        readonly COLOR_DEBUG=""
        readonly COLOR_RESET=""
    fi
fi

# Fonctions de log

# Affiche un en-tête
log_header() {
    [[ "$LOG_LEVEL" -ge "$LOG_LEVEL_MINIMAL" ]] || return 0
    
    if [[ "$SHOW_SEPARATORS" == "true" ]]; then
        echo -e "${COLOR_HEADER}"
        echo "======================================"
        echo " $1"
        echo "======================================"
        echo -e "${COLOR_RESET}"
    else
        echo -e "${COLOR_HEADER}### $1 ###${COLOR_RESET}"
    fi
}

# Affiche un message d'information
log_info() {
    [[ "$LOG_LEVEL" -ge "$LOG_LEVEL_NORMAL" ]] || return 0
    echo -e "${COLOR_INFO}[INFO]${COLOR_RESET} $1"
}

# Affiche un message de succès
log_success() {
    [[ "$LOG_LEVEL" -ge "$LOG_LEVEL_MINIMAL" ]] || return 0
    echo -e "${COLOR_SUCCESS}[SUCCESS]${COLOR_RESET} $1"
}

# Affiche un avertissement
log_warning() {
    [[ "$LOG_LEVEL" -ge "$LOG_LEVEL_NORMAL" ]] || return 0
    echo -e "${COLOR_WARNING}[WARNING]${COLOR_RESET} $1" >&2
}

# Affiche une erreur
log_error() {
    [[ "$LOG_LEVEL" -ge "$LOG_LEVEL_MINIMAL" ]] || return 0
    echo -e "${COLOR_ERROR}[ERROR]${COLOR_RESET} $1" >&2
}

# Affiche un message de débogage
log_debug() {
    [[ "$LOG_LEVEL" -ge "$LOG_LEVEL_DEBUG" ]] || return 0
    echo -e "${COLOR_DEBUG}[DEBUG]${COLOR_RESET} $1"
}

# Affiche un message détaillé (niveau verbose)
log_verbose() {
    [[ "$LOG_LEVEL" -ge "$LOG_LEVEL_VERBOSE" ]] || return 0
    echo -e "$1"
}

# Affiche une barre de progression
# Usage: log_progress "Message" 50 100
log_progress() {
    [[ "$LOG_LEVEL" -ge "$LOG_LEVEL_NORMAL" ]] || return 0
    local message="$1"
    local current="${2:-0}"
    local total="${3:-100}"
    local percent=$((current * 100 / total))
    local width=50
    local num_chars=$((width * percent / 100))
    
    # Création de la barre
    local bar=""
    for ((i=0; i<num_chars; i++)); do bar+="#"; done
    for ((i=num_chars; i<width; i++)); do bar+="-"; done
    
    # Affichage
    printf "\r${COLOR_INFO}[%3d%%]${COLOR_RESET} [%s] %s" "$percent" "$bar" "$message"
    [[ "$percent" -eq 100 ]] && echo
}

# Fonction de validation d'environnement
validate_env() {
    if [ -z "${DB_PATH}" ]; then
        log_error "DB_PATH non défini"
        exit 1
    fi
}