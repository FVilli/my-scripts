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

# --- Colori e log ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_ok()   { echo -e "${GREEN}[OK]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_err()  { echo -e "${RED}[ERR]${NC} $*" >&2; }

# --- Controlli iniziali ---
if [[ $EUID -eq 0 ]]; then
    log_err "Non eseguire questo script come root: NVM deve essere installato nell'utente corrente."
    exit 1
fi

if [[ -z "${HOME:-}" ]]; then
    log_err "La variabile HOME non è impostata."
    exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
    log_err "curl non è installato. Installalo prima, ad esempio: sudo apt install curl"
    exit 1
fi

NVM_DIR="${NVM_DIR:-${HOME}/.nvm}"
NVM_INSTALL_URL="https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh"
PI_PACKAGE="${PI_PACKAGE:-@mariozechner/pi-coding-agent}"

printf '\n============================================================\n'
printf ' Installazione Node.js tramite NVM e pi\n'
printf ' Utente: %s\n' "${USER:-$(id -un)}"
printf '============================================================\n\n'

# --- 1. Installa o carica NVM ---
if [[ ! -s "${NVM_DIR}/nvm.sh" ]]; then
    log_warn "NVM non trovato: installazione in ${NVM_DIR} ..."
    curl -fsSL "${NVM_INSTALL_URL}" | bash
    log_ok "NVM installato"
else
    log_ok "NVM già presente in ${NVM_DIR}"
fi

# shellcheck disable=SC1090
source "${NVM_DIR}/nvm.sh"

if ! command -v nvm >/dev/null 2>&1; then
    log_err "NVM non è disponibile dopo l'installazione."
    exit 1
fi

# --- 2. Installa e seleziona Node.js LTS ---
log_warn "Installazione/selezione dell'ultima versione LTS di Node.js ..."
nvm install --lts
nvm alias default 'lts/*' >/dev/null
nvm use --lts >/dev/null
log_ok "Node.js $(node --version) attivo"
log_ok "npm $(npm --version) attivo"

# --- 3. Installa pi globalmente ---
log_warn "Installazione globale di ${PI_PACKAGE} ..."
npm install --global "${PI_PACKAGE}"

# --- 4. Verifica ---
if ! command -v pi >/dev/null 2>&1; then
    log_err "Installazione completata ma il comando 'pi' non è nel PATH corrente."
    log_warn "Apri una nuova shell oppure esegui: source ~/.bashrc"
    exit 1
fi

log_ok "pi installato: $(command -v pi)"
pi --version 2>/dev/null || log_warn "pi è disponibile, ma non espone l'opzione --version"

echo ""
echo "============================================================"
echo " Installazione completata."
echo "============================================================"
echo "Se una shell già aperta non trova nvm/pi, esegui:"
echo "  source ~/.bashrc"
