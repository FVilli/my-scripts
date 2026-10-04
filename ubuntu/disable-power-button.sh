#!/usr/bin/env bash
# ============================================================================
# disable-power-button.sh
# ============================================================================
#
# ┌─────────────────────────────────────────────────────────────────────────┐
# │  PERCHÉ QUESTO SCRIPT ESISTE                                            │
# ├─────────────────────────────────────────────────────────────────────────┤
# │                                                                         │
# │  Su questo server Ubuntu (AMD Ryzen 7 5700U, bare-metal) il pulsante   │
# │  fisico di alimentazione / standby è gestito da systemd-logind, che     │
# │  di default esegue "poweroff" quando viene premuto.                     │
# │                                                                         │
# │  L'obiettivo è impedire che qualsiasi pressione del tasto fisico        │
# │  provochi uno spegnimento o un suspend/hibernate: il pulsante deve      │
# │  essere completamente inattivo.                                         │
# │                                                                         │
# │  Se si vuole spegnere il server, l'unica via consentita è             │
# │  esplicita e tramite terminale:                                         │
# │      sudo poweroff                                                      │
# │      sudo reboot                                                        │
# │                                                                         │
# │  Questo script applica la configurazione in modo permanente,           │
# │  creando un drop-in per systemd-logind che sopravvive anche agli       │
# │  aggiornamenti del pacchetto.                                           │
# │                                                                         │
# └─────────────────────────────────────────────────────────────────────────┘
#
# ┌─────────────────────────────────────────────────────────────────────────┐
# │  QUANDO ESEGUIRLO                                                       │
# ├─────────────────────────────────────────────────────────────────────────┤
# │                                                                         │
# │  • Dopo aver configurato i modelli in /home/federico/.pi/agent          │
# │    (provider monster-unsloth, 24 modelli caricati).                     │
# │                                                                         │
# │  • Su qualsiasi server Ubuntu con systemd-logind che gestisce           │
# │    le chiavi di alimentazione via ACPI.                                 │
# │                                                                         │
# │  • Prima o dopo il riavvio: la configurazione persiste grazie al       │
# │    drop-in in /etc/systemd/logind.conf.d/, quindi basta eseguire        │
# │    una sola volta per sessione (o prima del primo avvio).               │
# │                                                                         │
# └─────────────────────────────────────────────────────────────────────────┘
#
# ┌─────────────────────────────────────────────────────────────────────────┐
# │  DETTAGLI TECNICI                                                      │
# ├─────────────────────────────────────────────────────────────────────────┤
# │                                                                         │
# │  Hardware: AMD Ryzen 7 5700U con Radeon Graphics                       │
# │  Virtualizzazione: none (bare-metal)                                    │
# │  Sistema: Ubuntu (systemd-based)                                        │
# │                                                                         │
# │  systemd-logind gestisce i tasti fisici tramite le seguenti            │
# │  proprietà D-Bus di org.freedesktop.login1.Manager:                    │
# │                                                                         │
# │    HandlePowerKey   → default "poweroff" (premuto = spegnimento)       │
# │    HandleSuspendKey → default "suspend"                                 │
# │    HandleHibernateKey → default "hibernate"                             │
# │    HandleLidSwitch  → default "suspend" (se laptop/mini-PC)            │
# │                                                                         │
# │  Lo script imposta tutte a "ignore", creando un drop-in in:           │
# │    /etc/systemd/logind.conf.d/ignore-power-keys.conf                   │
# │                                                                         │
# │  Il drop-in contiene:                                                  │
# │    [Login]                                                              │
# │    HandlePowerKey=ignore                                                │
# │    HandleSuspendKey=ignore                                              │
# │    HandleHibernateKey=ignore                                            │
# │    HandleLidSwitch=ignore                                               │
# │                                                                         │
# │  Dopo il restart di systemd-logind, la modifica è attiva.             │
# │  Le chiavi esplicithe (sudo poweroff, sudo reboot) non sono            │
# │  influenzate: logind gestisce solo gli eventi hardware.                 │
# │                                                                         │
# └─────────────────────────────────────────────────────────────────────────┘
#
# ┌─────────────────────────────────────────────────────────────────────────┐
# │  CHI HA SCRITTO QUESTO SCRIPT                                          │
# ├────────────────────────────────═════════════════════════════════════════┤
# │                                                                         │
# │  Questo script è stato generato durante una sessione di                 │
# │  configurazione del server Ubuntu con l'agente pi (pi-coding-agent      │
# │  v1.0.2, https://github.com/earendil-works/pi-coding-agent).            │
# │                                                                         │
# │  Modello utilizzato nella sessione:                                     │
# │    • Predefinito attuale: monster-unsloth / unsloth/Qwen3.8-27B-GGUF   │
# │    • Provider locale: http://monster.local:8888/v1                     │
# │    • Modello Cloud (sessione): openai-codex / gpt-5.6-luna             │
# │                                                                         │
# │  L'agente pi è un coding agent che opera in modalità TUI/RPC,          │
# │  con accesso a tool bash, read/write/edit su file, e integrazione       │
# │  con provider LLM multipli.                                             │
# │                                                                         │
# └─────────────────────────────────────────────────────────────────────────┘
#
# ┌─────────────────────────────────────────────────────────────────────────┐
# │  AVVERTENZE                                                           │
# ├─────────────────────────────────────────────────────────────────────────┤
# │                                                                         │
# │  ⚠️  Il restart di systemd-logind chiude le sessioni utente attive,    │
# │     incluse le connessioni SSH. Se lo esegui da remoto, ricollegati    │
# │     dopo il completamento.                                              │
# │                                                                         │
# │  ⚠️  Verifica sempre con "busctl get-property ..." dopo l'esecuzione.   │
# │                                                                         │
# └─────────────────────────────────────────────────────────────────────────┘
#
# ============================================================================
# Data di creazione: $(date +%Y-%m-%d) (sessione pi)
# Autore: agente pi (pi-coding-agent v1.0.2)
# Modello sessione corrente: monster-unsloth / unsloth/Qwen3.8-27B-GGUF
# ============================================================================

set -euo pipefail

# --- Colori e log ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_ok()  { echo -e "${GREEN}[OK]${NC} $*"; }
log_warn(){ echo -e "${YELLOW}[WARN]${NC} $*"; }
log_err() { echo -e "${RED}[ERR]${NC} $*" >&2; }

# --- Controllo privilegi ---
if [[ $EUID -ne 0 ]]; then
    log_err "Questo script deve essere eseguito come root (o con sudo)."
    exit 1
fi

DROPIN_DIR="/etc/systemd/logind.conf.d"
DROPIN_FILE="${DROPIN_DIR}/ignore-power-keys.conf"

echo ""
echo "============================================================"
echo " disable-power-button.sh — Disabilita pulsante fisico di alimentazione"
echo " Server: $(hostname)  |  Data: $(date)"
echo "============================================================"
echo ""

# --- 1. Verifica che systemd-logind sia attivo ---
if ! systemctl is-active --quiet systemd-logind; then
    log_err "systemd-logind non è attivo. Impossibile procedere."
    exit 1
fi
log_ok "systemd-logind è attivo"

# --- 2. Mostra le impostazioni attuali ---
echo ""
echo "--- Impostazioni correnti (prima della modifica) ---"
busctl get-property org.freedesktop.login1 /org/freedesktop/login1 \
    org.freedesktop.login1.Manager HandlePowerKey 2>/dev/null || echo "(non leggibile via D-Bus)"
busctl get-property org.freedesktop.login1 /org/freedesktop/login1 \
    org.freedesktop.login1.Manager HandleSuspendKey 2>/dev/null || echo "(non leggibile via D-Bus)"

# --- 3. Crea il drop-in ---
echo ""
log_warn "Creazione del drop-in in ${DROPIN_FILE} ..."

mkdir -p "${DROPIN_DIR}"

cat > "${DROPIN_FILE}" <<'CONF'
# Il pulsante fisico di alimentazione/standby non deve fare nulla.
# Spegnimento solo esplicito: sudo poweroff / sudo reboot
[Login]
HandlePowerKey=ignore
HandleSuspendKey=ignore
HandleHibernateKey=ignore
HandleLidSwitch=ignore
CONF

chmod 644 "${DROPIN_FILE}"
log_ok "Drop-in creato: ${DROPIN_FILE}"

# --- 4. Riavvia systemd-logind ---
echo ""
log_warn "Riavvio di systemd-logind..."
log_warn "ATTENZIONE: le sessioni utente attive (incluso SSH) verranno chiuse."
log_warn "Ricollegati dopo il completamento."
sleep 3

systemctl restart systemd-logind

# --- 5. Verifica post-riavvio ---
echo ""
echo "--- Impostazioni correnti (dopo la modifica) ---"
HPK=$(busctl get-property org.freedesktop.login1 /org/freedesktop/login1 \
    org.freedesktop.login1.Manager HandlePowerKey 2>/dev/null || echo "LEGGIBILE_FALLITA")
HSK=$(busctl get-property org.freedesktop.login1 /org/freedesktop/login1 \
    org.freedesktop.login1.Manager HandleSuspendKey 2>/dev/null || echo "LEGGIBILE_FALLITA")

echo "HandlePowerKey   = ${HPK}"
echo "HandleSuspendKey = ${HSK}"

if [[ "${HPK}" == *'"ignore"'* ]]; then
    log_ok "CONFIGURAZIONE APPLICATA CON SUCCESSO"
    echo ""
    echo "Il pulsante fisico di alimentazione ora è inattivo."
    echo "Per spegnere il server:  sudo poweroff"
    echo "Per riavviare il server: sudo reboot"
else
    log_err "VERIFICA FALLITA: HandlePowerKey non è impostato a ignore."
    exit 1
fi

echo ""
echo "============================================================"
echo " Fatto."
echo "============================================================"
