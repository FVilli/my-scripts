#!/bin/sh
# ============================================================================
# install-docker.sh
# ============================================================================
#
# ┌─────────────────────────────────────────────────────────────────────────────┐
# │  PERCHÉ QUESTO SCRIPT ESISTE                                                │
# ├─────────────────────────────────────────────────────────────────────────────┤
# │                                                                             │
# │  Installa Docker Engine (docker-ce) e i plugin ufficiali (buildx,           │
# │  compose) dal repository APT di Docker, lasciando il sistema                │
# │  aggiornabile con un normale 'apt upgrade'.                                 │
# │                                                                             │
# │  Non usa lo script get.docker.com né lo snap: il repository APT è           │
# │  più trasparente, versionabile e controllabile.                             │
# │                                                                             │
# └─────────────────────────────────────────────────────────────────────────────┘
#
# ┌─────────────────────────────────────────────────────────────────────────────┐
# │  QUANDO ESEGUIRLO                                                           │
# ├─────────────────────────────────────────────────────────────────────────────┤
# │                                                                             │
# │  • Su un server Ubuntu/Debian appena installato, prima di                   │
# │    distribuire container o stack compose.                                   │
# │  • Richiede root: lo script va lanciato con sudo.                           │
# │  • È rieseguibile: se Docker è già installato, aggiorna i pacchetti         │
# │    e non tocca i container, le immagini o /var/lib/docker.                  │
# │                                                                             │
# └─────────────────────────────────────────────────────────────────────────────┘
#
# ┌─────────────────────────────────────────────────────────────────────────────┐
# │  USO                                                                        │
# ├─────────────────────────────────────────────────────────────────────────────┤
# │                                                                             │
# │  sudo sh install-docker.sh [opzioni]                                        │
# │                                                                             │
# │    --user NOME    aggiunge NOME al gruppo docker                            │
# │                   (default: utente che ha invocato sudo)                    │
# │    --no-group     non modifica l'appartenenza al gruppo docker              │
# │    -h, --help     mostra questo aiuto                                       │
# │                                                                             │
# │  Esempio rapido (senza clonare il repo):                                    │
# │    curl -fsSL https://raw.githubusercontent.com/FVilli/my-scripts/          │
# │    main/ubuntu/install-docker.sh | sudo sh                                  │
# │                                                                             │
# └─────────────────────────────────────────────────────────────────────────────┘
#
# ┌─────────────────────────────────────────────────────────────────────────────┐
# │  DETTAGLI TECNICI E AVVERTENZE                                              │
# ├─────────────────────────────────────────────────────────────────────────────┤
# │                                                                             │
# │  • Rimuove i pacchetti in conflitto se presenti: docker.io,                 │
# │    docker-doc, docker-compose, docker-compose-v2, podman-docker,            │
# │    containerd, runc. Se usi podman o containerd standalone, NON             │
# │    eseguire questo script.                                                  │
# │  • Chiave GPG: /etc/apt/keyrings/docker.asc                                 │
# │    Repository: /etc/apt/sources.list.d/docker.list                          │
# │  • Architetture supportate: amd64, arm64, armhf.                            │
# │  • Abilita e avvia il servizio systemd 'docker'.                            │
# │  • L'aggiunta al gruppo docker ha effetto solo dopo un nuovo login          │
# │    (oppure 'newgrp docker'). Fino ad allora serve sudo.                     │
# │  • Scritto in POSIX sh: funziona anche con 'curl ... | sudo sh'.            │
# │                                                                             │
# └─────────────────────────────────────────────────────────────────────────────┘
#
# ============================================================================

set -eu

# pipefail: supportato da bash, non da dash (sh su Ubuntu)
if (set -o pipefail) 2>/dev/null; then
    set -o pipefail
fi

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_ok()   { printf '%b\n' "${GREEN}[OK]${NC} $*"; }
log_warn() { printf '%b\n' "${YELLOW}[WARN]${NC} $*"; }
log_err()  { printf '%b\n' "${RED}[ERR]${NC} $*" >&2; }
die()      { log_err "$*"; exit 1; }

usage() {
    cat <<'EOF'
install-docker.sh - installa Docker Engine dal repository APT ufficiale

Uso:
  sudo sh install-docker.sh [opzioni]

Opzioni:
  --user NOME    aggiunge NOME al gruppo docker
                 (default: utente che ha invocato sudo)
  --no-group     non modifica l'appartenenza al gruppo docker
  -h, --help     mostra questo aiuto

Documentazione completa: header ASCII in cima allo script
(su GitHub: ubuntu/install-docker.sh).
EOF
}

export DEBIAN_FRONTEND=noninteractive

# ---------------------------------------------------------------- opzioni ---
TARGET_USER=""
ADD_TO_GROUP=1

while [ $# -gt 0 ]; do
    case "$1" in
        --user)
            [ $# -ge 2 ] || die "--user richiede un nome utente"
            TARGET_USER="$2"
            shift 2
            ;;
        --user=*)
            TARGET_USER="${1#--user=}"
            shift
            ;;
        --no-group)
            ADD_TO_GROUP=0
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            die "Opzione sconosciuta: $1 (usa --help)"
            ;;
    esac
done

# ------------------------------------------------------------ precontrolli ---
[ "$(id -u)" -eq 0 ] || die "Esegui come root: sudo sh $0 [opzioni]"

[ -r /etc/os-release ] || die "/etc/os-release non trovato: distribuzione non supportata"
# shellcheck disable=SC1091
. /etc/os-release

DISTRO_ID="${ID:-}"
CODENAME="${VERSION_CODENAME:-}"

case "$DISTRO_ID" in
    ubuntu|debian|raspbian) ;;
    *) die "Distribuzione non supportata: ${PRETTY_NAME:-$DISTRO_ID} (serve Ubuntu o Debian)" ;;
esac

[ -n "$CODENAME" ] || die "Impossibile determinare VERSION_CODENAME da /etc/os-release"

ARCH="$(dpkg --print-architecture 2>/dev/null || true)"
case "$ARCH" in
    amd64|arm64|armhf) ;;
    "") die "Impossibile determinare l'architettura (dpkg mancante?)" ;;
    *) die "Architettura non supportata: $ARCH" ;;
esac

if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ] && [ -z "$TARGET_USER" ]; then
    TARGET_USER="$SUDO_USER"
fi

if [ "$ADD_TO_GROUP" -eq 1 ] && [ -n "$TARGET_USER" ]; then
    id "$TARGET_USER" >/dev/null 2>&1 || die "Utente inesistente: $TARGET_USER"
fi

printf '\n============================================================\n'
printf ' Installazione Docker Engine\n'
printf ' Sistema: %s\n' "${PRETTY_NAME:-$DISTRO_ID $CODENAME}"
printf ' Arch:    %s\n' "$ARCH"
printf ' Repo:    %s %s\n' "$DISTRO_ID" "$CODENAME"
if [ -n "$TARGET_USER" ]; then
    printf ' Utente gruppo docker: %s\n' "$TARGET_USER"
fi
printf '============================================================\n\n'

# ----------------------------------------------------- pacchetti conflitto ---
CONFLICTS="docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc"
TO_REMOVE=""
for pkg in $CONFLICTS; do
    if dpkg -s "$pkg" >/dev/null 2>&1; then
        TO_REMOVE="$TO_REMOVE $pkg"
    fi
done

if [ -n "$TO_REMOVE" ]; then
    log_warn "Rimozione pacchetti in conflitto:$TO_REMOVE"
    # shellcheck disable=SC2086
    apt-get remove -y --purge $TO_REMOVE </dev/null \
        || die "Rimozione dei pacchetti in conflitto fallita"
    log_ok "Pacchetti in conflitto rimossi"
else
    log_ok "Nessun pacchetto in conflitto presente"
fi

# --------------------------------------------------------- prerequisiti APT ---
log_warn "Installo i prerequisiti (ca-certificates, curl, gnupg)..."
apt-get update -qq </dev/null || die "apt-get update fallito"
apt-get install -y --no-install-recommends ca-certificates curl gnupg </dev/null \
    || die "Installazione dei prerequisiti fallita"
log_ok "Prerequisiti presenti"

# ----------------------------------------------------------------- chiave GPG ---
KEYRING_DIR="/etc/apt/keyrings"
KEYRING="$KEYRING_DIR/docker.asc"
REPO_FILE="/etc/apt/sources.list.d/docker.list"

install -m 0755 -d "$KEYRING_DIR"

log_warn "Scarico la chiave GPG di Docker..."
curl -fsSL "https://download.docker.com/linux/$DISTRO_ID/gpg" -o "$KEYRING" \
    || die "Download della chiave GPG fallito"
chmod a+r "$KEYRING"
log_ok "Chiave GPG in $KEYRING"

# -------------------------------------------------------------- repository ---
REPO_LINE="deb [arch=$ARCH signed-by=$KEYRING] https://download.docker.com/linux/$DISTRO_ID $CODENAME stable"

if [ -f "$REPO_FILE" ] && [ "$(cat "$REPO_FILE")" = "$REPO_LINE" ]; then
    log_ok "Repository Docker già configurato"
else
    printf '%s\n' "$REPO_LINE" > "$REPO_FILE"
    log_ok "Repository Docker configurato in $REPO_FILE"
fi

apt-get update -qq </dev/null || die "apt-get update fallito dopo l'aggiunta del repository"

# ------------------------------------------------------------------ install ---
log_warn "Installo Docker Engine e i plugin..."
apt-get install -y --no-install-recommends \
    docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin </dev/null \
    || die "Installazione di Docker fallita"

log_ok "Pacchetti Docker installati"

# ------------------------------------------------------------------ servizio ---
if command -v systemctl >/dev/null 2>&1; then
    systemctl enable --now docker >/dev/null 2>&1 || true
    if systemctl is-active --quiet docker; then
        log_ok "Servizio docker attivo e abilitato all'avvio"
    else
        log_warn "Servizio docker non attivo: controlla 'systemctl status docker'"
        systemctl status docker --no-pager -l 2>&1 | tail -n 15 || true
    fi
else
    log_warn "systemd non disponibile: avvia il daemon docker manualmente"
fi

# ------------------------------------------------------------------ verifica ---
# Il socket può impiegare qualche istante dopo l'avvio del servizio.
TRIES=0
while ! docker info >/dev/null 2>&1; do
    TRIES=$((TRIES + 1))
    if [ "$TRIES" -ge 10 ]; then
        log_err "Il daemon Docker non risponde: verifica 'docker info'"
        exit 1
    fi
    sleep 1
done

log_ok "Daemon Docker operativo"

# ------------------------------------------------------------ gruppo docker ---
if [ "$ADD_TO_GROUP" -eq 1 ] && [ -n "$TARGET_USER" ]; then
    if id -nG "$TARGET_USER" | tr ' ' '\n' | grep -qx docker; then
        log_ok "$TARGET_USER è già nel gruppo docker"
    else
        usermod -aG docker "$TARGET_USER" || die "usermod fallito per $TARGET_USER"
        log_ok "$TARGET_USER aggiunto al gruppo docker"
    fi
elif [ "$ADD_TO_GROUP" -eq 0 ]; then
    log_warn "Gruppo docker non modificato (--no-group)"
fi

# ------------------------------------------------------------------- riepilogo ---
if command -v docker >/dev/null 2>&1 && command -v snap >/dev/null 2>&1; then
    if [ -x /snap/bin/docker ]; then
        log_warn "Esiste anche /snap/bin/docker: potrebbe avere precedenza nel PATH"
    fi
fi

printf '\n============================================================\n'
printf ' Installazione completata\n'
printf '============================================================\n\n'
printf 'docker:  %s\n' "$(docker --version)"
printf 'compose: %s\n' "$(docker compose version --short 2>/dev/null || echo 'plugin installato')"
printf '\n'
printf 'Test rapido:\n'
printf '  docker run --rm hello-world\n\n'

if [ "$ADD_TO_GROUP" -eq 1 ] && [ -n "$TARGET_USER" ]; then
    printf "IMPORTANTE: l'appartenenza al gruppo docker vale dal prossimo login.\n"
    printf 'Esci e rientra dalla sessione SSH, oppure usa:\n'
    printf '  newgrp docker\n\n'
fi
