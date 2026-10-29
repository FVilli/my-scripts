# AGENTS.md — my-scripts

## Contesto

Questo **non è un repo di sviluppo**. È una libreria personale di script shell/bash
raccolti nel tempo per automazioni di sysadmin su Ubuntu (bare-metal server, AMD Ryzen 7 5700U).

Non ci sono test, CI, build system, package.json, Makefile o qualsiasi altra infrastruttura
da sviluppo. Solo script `.sh` / `.bash` organizzati in sottocartelle per piattaforma/uso.

## Struttura

```
my-scripts/
├── AGENTS.md          ← questo file (regole per l'agente)
├── README.md          ← solo lista script + one-liner curl
└── ubuntu/            ← script specifici per Ubuntu
    ├── disable-power-button.sh
    ├── install-docker.sh
    └── install-nodejs-nvm-pi.sh
```

Nient'altro: **niente INDEX.md, niente COPY_AND_PASTE.md, niente docs/**.
La documentazione vive esclusivamente negli header degli script.

## Come aggiungere un nuovo script

1. Sottocartella per piattaforma: `ubuntu/`, `arch/`, `windows/`, ecc.
2. Nome file descrittivo in kebab-case: `install-docker.sh`, `disable-power-button.sh`.
3. Header ASCII obbligatorio in cima, **in italiano**, con bordi `┌─┐` larghi 77 caratteri
   interni (come gli script esistenti) e le sezioni:
   *PERCHÉ QUESTO SCRIPT ESISTE* — *QUANDO ESEGUIRLO* — *USO* (parametri e opzioni) —
   *DETTAGLI TECNICI E AVVERTENZE*.
4. Aggiungere in `README.md` **solo**: header `## nome:piattaforma`, una riga di cosa fa,
   il blocco ```sh``` con il comando `curl -fsSL https://raw.githubusercontent.com/FVilli/my-scripts/main/<cartella>/<script>.sh | sh` (o `| sudo sh`).
5. `chmod +x` sullo script.

## Stile del codice

- `set -euo pipefail` sempre (con bash). Se lo script deve funzionare con
  `curl … | sh` (dash su Ubuntu), scrivilo in **POSIX sh** (`#!/bin/sh`, `set -eu` e
  `pipefail` attivato solo se supportato).
- Colori ANSI (`RED`, `GREEN`, `YELLOW`, `NC`) + funzioni `log_ok`, `log_warn`, `log_err`
  (e `die` dove utile).
- Controllo privilegi all'inizio se serve root (`[[ $EUID -ne 0 ]]` o `[ "$(id -u)" -eq 0 ]`).
- Script **idempotenti** e rieseguibili: controlla prima di installare/scrivere, non
  distruggere dati (container, immagini, config utente) a ogni run.
- `apt-get` sempre con `-y` e `DEBIAN_FRONTEND=noninteractive`; `< /dev/null` sui comandi
  che potrebbero leggere stdin (quando lo script è piped).
- Autonomi: nessuna dipendenza esterna non di base (apt, systemd, dbus-tools sono ok).

## Quando mi aiuti a usare uno script

- Leggi l'header dello script prima di suggerire comandi — è la documentazione principale.
- Tieni conto che gli script possono chiudere sessioni SSH (es. restart di systemd service).
- Verifica sempre lo stato post-esecuzione quando possibile.

## Regole operative

1. **Niente boilerplate da sviluppo** — no `.editorconfig`, no `.prettierrc`, no linter config, no CI.
2. **Niente commit message elaborate** — messaggi descrittivi in italiano, una riga.
3. **Script = fonte di verità** — nessuna documentazione duplicata fuori dagli header.
4. **README minimale** — solo la lista degli script invocabili con `curl`, niente prosa.
5. **Sicurezza prima** — molti script girano come root; suggerisci sempre verifica dello stato prima/dopo.
