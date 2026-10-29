#!/bin/sh
# ============================================================================
# install-avahi.sh
# ============================================================================
#
# ┌─────────────────────────────────────────────────────────────────────────────┐
# │  PERCHÉ QUESTO SCRIPT ESISTE                                                │
# ├─────────────────────────────────────────────────────────────────────────────┤
# │                                                                             │
# │  Installa e configura Avahi (mDNS/DNS-SD) su Ubuntu: nome host              │
# │  raggiungibile come <hostname>.local e scoperta dei servizi in rete         │
# │  locale. Oltre ad apt: controlla conflitti con systemd-resolved, la         │
# │  porta 5353/udp, /etc/nsswitch.conf e il firewall.                          │
# │                                                                             │
# └─────────────────────────────────────────────────────────────────────────────┘
#
# ┌─────────────────────────────────────────────────────────────────────────────┐
# │  QUANDO ESEGUIRLO                                                           │
# ├─────────────────────────────────────────────────────────────────────────────┤
# │                                                                             │
# │  • Su un server che deve essere raggiungibile via <hostname>.local          │
# │    o che deve scoprire stampanti, NAS, TV, HA, ecc.                         │
# │  • Richiede root e una rete con multicast abilitato.                        │
# │  • Rieseguibile: non reinstalla nulla se già a posto.                       │
# │                                                                             │
# └─────────────────────────────────────────────────────────────────────────────┘
#
# ┌─────────────────────────────────────────────────────────────────────────────┐
# │  USO                                                                        │
# ├─────────────────────────────────────────────────────────────────────────────┤
# │                                                                             │
# │  sudo sh install-avahi.sh [opzioni]                                         │
# │                                                                             │
# │    --no-firewall  non tocca le regole ufw                                   │
# │    -h, --help     mostra questo aiuto                                       │
# │                                                                             │
# └─────────────────────────────────────────────────────────────────────────────┘
#
# ┌─────────────────────────────────────────────────────────────────────────────┐
# │  DETTAGLI TECNICI E AVVERTENZE                                              │
# ├─────────────────────────────────────────────────────────────────────────────┤
# │                                                                             │
# │  • Pacchetti: avahi-daemon, libnss-mdns, avahi-utils.                       │
# │  • Se systemd-resolved è attivo, può contendere 5353/udp: lo script         │
# │    avvisa e stampa il comando per disabilitarne mDNS.                       │
# │  • Se in /etc/nsswitch.conf manca mdns4_minimal, la riga hosts:             │
# │    viene riscritta (backup in /etc/nsswitch.conf.bak-<data>).               │
# │  • Con ufw attivo apre 5353/udp (saltabile con --no-firewall).              │
# │  • Non pubblica servizi: quelli si dichiarano con file in                   │
# │    /etc/avahi/services/.                                                    │
# │                                                                             │
# └─────────────────────────────────────────────────────────────────────────────┘
#
# ============================================================================

set -eu

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
install-avahi.sh - installa e verifica Avahi (mDNS) su Ubuntu

Uso:
  sudo sh install-avahi.sh [opzioni]

Opzioni:
  --no-firewall  non tocca le regole ufw
  -h, --help     mostra questo aiuto
EOF
}

export DEBIAN_FRONTEND=noninteractive

NO_FIREWALL=0

while [ $# -gt 0 ]; do
    case "$1" in
        --no-firewall) NO_FIREWALL=1; shift ;;
        -h|--help)     usage; exit 0 ;;
        *)             die "Opzione sconosciuta: $1 (usa --help)" ;;
    esac
done

# ------------------------------------------------------------ precontrolli ---
[ "$(id -u)" -eq 0 ] || die "Esegui come root: sudo sh $0 [opzioni]"
[ -r /etc/os-release ] || die "/etc/os-release non trovato"
# shellcheck disable=SC1091
. /etc/os-release

case "${ID:-}" in
    ubuntu|debian|raspbian) ;;
    *) die "Distribuzione non supportata: ${PRETTY_NAME:-${ID:-unknown}}" ;;
esac

command -v systemctl >/dev/null 2>&1 || die "systemd non disponibile: avahi-daemon non gestibile"

HOSTNAME_LOCAL="$(hostname).local"

printf '\n============================================================\n'
printf ' Installazione Avahi (mDNS)\n'
printf ' Sistema: %s\n' "${PRETTY_NAME:-${ID:-}}"
printf ' Nome:    %s\n' "$HOSTNAME_LOCAL"
printf '============================================================\n\n'

# --------------------------------------------------------- 5353/udp in uso ---
if command -v ss >/dev/null 2>&1 && ss -lun 2>/dev/null | grep -q ':5353[[:space:]]'; then
    if ! systemctl is-active --quiet avahi-daemon; then
        log_warn "porta 5353/udp già occupata da un altro processo (systemd-resolved?)"
    fi
fi

# ---------------------------------------------------------- pacchetti APT ---
log_warn "Installo avahi-daemon, libnss-mdns, avahi-utils..."
apt-get update -qq </dev/null || die "apt-get update fallito"
apt-get install -y --no-install-recommends avahi-daemon libnss-mdns avahi-utils </dev/null \
    || die "Installazione dei pacchetti Avahi fallita"
log_ok "Pacchetti installati"

# ------------------------------------------------------------ nsswitch.conf ---
NSSWITCH=/etc/nsswitch.conf

if grep -Eq '^hosts:.*mdns4_minimal' "$NSSWITCH" 2>/dev/null; then
    log_ok "nsswitch.conf: mdns4_minimal già presente"
else
    cp -a "$NSSWITCH" "$NSSWITCH.bak-$(date +%Y%m%d%H%M%S)"
    if grep -q '^hosts:' "$NSSWITCH"; then
        sed -i -E 's/^hosts:.*/hosts:          files mdns4_minimal [NOTFOUND=return] dns/' "$NSSWITCH"
    else
        printf 'hosts:          files mdns4_minimal [NOTFOUND=return] dns\n' >> "$NSSWITCH"
    fi
    log_ok "nsswitch.conf: aggiunto mdns4_minimal (backup creato)"
fi

# ------------------------------------------------------------------ servizio ---
systemctl enable --now avahi-daemon >/dev/null 2>&1 || true

if systemctl is-active --quiet avahi-daemon; then
    log_ok "Servizio avahi-daemon attivo e abilitato"
else
    systemctl status avahi-daemon --no-pager -l 2>&1 | tail -n 15 || true
    die "avahi-daemon non parte (vedi output sopra)"
fi

# ------------------------------------------------------------------ firewall ---
if [ "$NO_FIREWALL" -eq 1 ]; then
    log_warn "Firewall non modificato (--no-firewall)"
elif command -v ufw >/dev/null 2>&1; then
    if ufw status 2>/dev/null | grep -q '^Status: active'; then
        if ufw status 2>/dev/null | grep -q '5353/udp'; then
            log_ok "ufw: 5353/udp già permesso"
        else
            ufw allow 5353/udp >/dev/null && log_ok "ufw: aperto 5353/udp"
        fi
    else
        log_ok "ufw inattivo: nessuna regola aggiunta"
    fi
else
    log_ok "ufw non installato: nessuna regola aggiunta"
fi

# ---------------------------------------------------- systemd-resolved (mDNS) ---
if systemctl is-active --quiet systemd-resolved 2>/dev/null; then
    if grep -Eq '^[[:space:]]*MulticastDNS=(yes|resolve)' /etc/systemd/resolved.conf 2>/dev/null; then
        log_warn "systemd-resolved ha mDNS attivo: possibile conflitto su 5353/udp"
        log_warn "Per disabilitarlo: sed -i 's/^#\\?MulticastDNS=.*/MulticastDNS=no/' /etc/systemd/resolved.conf && systemctl restart systemd-resolved"
    else
        log_ok "systemd-resolved attivo ma con mDNS disattivato"
    fi
fi

# ------------------------------------------------------------------ verifica ---
if timeout 5 avahi-resolve -n "$HOSTNAME_LOCAL" >/dev/null 2>&1; then
    log_ok "avahi risolve $HOSTNAME_LOCAL"
else
    log_warn "avahi non risolve ancora $HOSTNAME_LOCAL (multicast bloccato o DNS .local in cache)"
fi

SERVICES="$(timeout 5 avahi-browse -atr --terminate 2>/dev/null | grep -c '^=' || true)"
printf '\n'
log_ok "Servizi mDNS visti in rete: ${SERVICES:-0}"

printf '\n============================================================\n'
printf ' Installazione completata\n'
printf '============================================================\n\n'
printf 'Host:       %s\n' "$HOSTNAME_LOCAL"
printf 'Da altri host della LAN:\n'
printf '  ping %s\n' "$HOSTNAME_LOCAL"
printf '  getent hosts %s\n' "$HOSTNAME_LOCAL"
printf '\nDa questo server, per scoprire la rete:\n'
printf '  avahi-browse -atr\n\n'
printf 'Per pubblicare un servizio: file .service in /etc/avahi/services/\n\n'
