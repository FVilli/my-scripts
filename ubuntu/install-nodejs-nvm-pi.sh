#!/usr/bin/env bash
# ============================================================================
# install-nodejs-nvm-pi.sh
# ============================================================================
#
# ┌─────────────────────────────────────────────────────────────────────────┐
# │  PERCHÉ QUESTO SCRIPT ESISTE                                            │
# ├─────────────────────────────────────────────────────────────────────────┤
# │                                                                         │
# │  Installa Node.js tramite NVM (Node Version Manager) e il coding agent │
# │  pi globalmente tramite npm, senza modificare l'installazione di       │
# │  Node.js del sistema.                                                   │
# │                                                                         │
# └─────────────────────────────────────────────────────────────────────────┘
#
# ┌─────────────────────────────────────────────────────────────────────────┐
# │  QUANDO ESEGUIRLO                                                       │
# ├─────────────────────────────────────────────────────────────────────────┤
# │                                                                         │
# │  • Eseguirlo con l'utente che userà Node.js e pi, non con sudo.         │
# │  • Può essere rieseguito: NVM e Node.js vengono riutilizzati se già     │
# │    presenti.                                                             │
# │  • Il comando installato sarà "pi" e il pacchetto npm è                │
# │    @mariozechner/pi-coding-agent.                                      │
# │                                                                         │
# └─────────────────────────────────────────────────────────────────────────┘
#
# ┌─────────────────────────────────────────────────────────────────────────┐
# │  DETTAGLI TECNICI E AVVERTENZE                                          │
# ├─────────────────────────────────────────────────────────────────────────┤
# │                                                                         │
# │  NVM viene installato in ~/.nvm e il profilo della shell viene          │
# │  aggiornato per caricarlo automaticamente.                              │
# │  Node.js installato: ultima versione LTS disponibile.                  │
# │  Dipendenze richieste: curl e una shell Bash.                           │
# │                                                                         │
# │  Dopo l'esecuzione, una shell già aperta potrebbe non conoscere         │
# │  "nvm" o "pi": aprire una nuova shell oppure eseguire:                  │
# │      source ~/.bashrc                                                    │
# │                                                                         │
# │  Per cambiare versione Node in seguito:                                 │
# │      nvm install --lts                                                    │
# │      nvm alias default <versione>                                         │
# │                                                                         │
# └─────────────────────────────────────────────────────────────────────────┘
#
# ============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_ok()   { echo -e "${GREEN}[OK]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_err()  { echo -e "${RED}[ERR]${NC} $*" >&2; }

if [[ $EUID -eq 0 ]]; then
    log_err "Non eseguire questo script come root."
    exit 1
fi

if [[ -z "${HOME:-}" ]]; then
    log_err "La variabile HOME non è impostata."
    exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
    log_err "curl non è installato. Esegui: sudo apt install curl"
    exit 1
fi

NVM_DIR="${NVM_DIR:-${HOME}/.nvm}"
NVM_VERSION="v0.40.7"
NVM_INSTALL_URL="https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh"

PI_PACKAGE="${PI_PACKAGE:-@earendil-works/pi-coding-agent}"

printf '\n============================================================\n'
printf ' Installazione Node.js tramite NVM e pi\n'
printf ' Utente: %s\n' "${USER:-$(id -un)}"
printf '============================================================\n\n'

# --- NVM ---
if [[ ! -s "${NVM_DIR}/nvm.sh" ]]; then
    log_warn "NVM non trovato: installazione ${NVM_VERSION}..."
    curl -fsSL "${NVM_INSTALL_URL}" | bash
    log_ok "NVM installato"
else
    log_ok "NVM già presente in ${NVM_DIR}"
fi

set +u
# shellcheck disable=SC1090
source "${NVM_DIR}/nvm.sh"
set -u

if ! declare -F nvm >/dev/null 2>&1; then
    log_err "NVM non è disponibile dopo l'installazione."
    exit 1
fi

# --- Node.js LTS ---
log_warn "Installazione/selezione Node.js LTS..."
nvm install --lts
nvm alias default 'lts/*' >/dev/null
nvm use --lts >/dev/null

log_ok "Node.js $(node --version)"
log_ok "npm $(npm --version)"

# --- Pi ---
log_warn "Installazione ${PI_PACKAGE}..."
npm install --global "${PI_PACKAGE}"

# --- Verifica ---
if ! command -v pi >/dev/null 2>&1; then
    log_err "Il comando 'pi' non è disponibile."
    exit 1
fi

log_ok "pi installato in: $(command -v pi)"

pi --version 2>/dev/null || true

echo
echo "============================================================"
echo " Installazione completata."
echo "============================================================"
echo
echo "Node: $(node --version)"
echo "npm:  $(npm --version)"
echo "pi:   $(command -v pi)"
echo "Se una shell già aperta non trova nvm/pi, esegui:"
echo "  source ~/.bashrc"
