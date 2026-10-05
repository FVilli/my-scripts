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

#!/usr/bin/env bash

set -eo pipefail

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

# --- 1. Installa NVM se necessario ---
if [[ ! -s "${NVM_DIR}/nvm.sh" ]]; then
    log_warn "NVM non trovato: installazione ${NVM_VERSION}..."
    curl -fsSL "${NVM_INSTALL_URL}" | bash
    log_ok "NVM installato"
else
    log_ok "NVM già presente in ${NVM_DIR}"
fi

# --- 2. Carica NVM nella shell corrente dello script ---
# shellcheck disable=SC1090
source "${NVM_DIR}/nvm.sh"

if ! declare -F nvm >/dev/null 2>&1; then
    log_err "NVM non è disponibile dopo l'installazione."
    exit 1
fi

# --- 3. Installa/seleziona Node.js LTS ---
log_warn "Installazione/selezione Node.js LTS..."

nvm install --lts
nvm alias default 'lts/*' >/dev/null
nvm use --lts >/dev/null

log_ok "Node.js $(node --version)"
log_ok "npm $(npm --version)"

# --- 4. Installa Pi ---
log_warn "Installazione globale di ${PI_PACKAGE}..."

npm install --global "${PI_PACKAGE}"

# --- 5. Verifica ---
if ! command -v pi >/dev/null 2>&1; then
    log_err "Il comando 'pi' non è disponibile nel PATH."
    exit 1
fi

log_ok "pi installato in: $(command -v pi)"

if pi --version >/dev/null 2>&1; then
    log_ok "pi versione $(pi --version)"
else
    log_warn "pi installato, ma impossibile leggere la versione."
fi

echo
echo "============================================================"
echo " Installazione completata"
echo "============================================================"
echo
echo "Node: $(node --version)"
echo "npm:  $(npm --version)"
echo "pi:   $(pi --version 2>/dev/null || echo 'installato')"
echo
echo "IMPORTANTE:"
echo "Per rendere NVM, Node.js e pi disponibili normalmente nella tua sessione,"
echo "esci dalla sessione SSH e ricollegati:"
echo
echo "  exit"
echo
echo "poi riconnettiti al server."
echo
