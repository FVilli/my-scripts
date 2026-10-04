# AGENTS.md — my-scripts

## Contesto

Questo **non è un repo di sviluppo**. È una libreria personale di script shell/bash
raccolti nel tempo per automazioni di sysadmin su Ubuntu (bare-metal server, AMD Ryzen 7 5700U).

Non ci sono test, CI, build system, package.json, Makefile o qualsiasi altra infrastruttura
da sviluppo. Solo script `.sh` / `.bash` organizzati in sottocartelle per piattaforma/uso.

## Struttura

```
my-scripts/
├── AGENTS.md          ← questo file (guida per l'agente)
├── README.md          ← vuoto/minimale, ignorare
└── ubuntu/            ← script specifici per Ubuntu
    └── disable-power-button.sh
```

## Cosa mi aspetto dall'agente

### Quando creo/modifico script

- **Segui lo stile degli header esistenti**: blocchi descrittivi con bordi ASCII (`┌─┐`) che
  coprono: *perché esiste, quando usarlo, dettagli tecnici, avvertenze*.
- Gli header sono in **italiano** — mantieni la coerenza.
- Usa `set -euo pipefail` sempre.
- Colori terminali con ANSI (`RED`, `GREEN`, `YELLOW`, `NC`) + funzioni `log_ok`, `log_warn`, `log_err`.
- Controllo privilegi con `$EUID` all'inizio se serve root.
- Script autonomi: nessuna dipendenza esterna non di base (apt, systemd, dbus-tools sono ok).

### Quando mi aiuti a usare uno script

- Leggi l'header dello script prima di suggerire comandi — è la documentazione principale.
- Tieni conto che gli script possono chiudere sessioni SSH (es. restart di systemd service).
- Verifica sempre lo stato post-esecuzione quando possibile.

### Quando il repo cresce

- Sottocartelle per piattaforma: `ubuntu/`, `arch/`, ecc.
- Unscript alla volta — non c'è versioning semver, ogni script è ciò che è.
- README.md resta minimale (vuoto o un solo rigo). La documentazione vive negli header degli script.

## Regole operative

1. **Niente boilerplate da sviluppo** — no `.editorconfig`, no `prettier`, no linter config.
2. **Niente commit message elaborate** — se chiedi help con git, usa messaggi descrittivi in italiano.
3. **Script = fonte di verità** — non cercare documentazione altrove, leggila direttamente nello script.
4. **Sicurezza prima** — molti script girano come root; suggerisci sempre verifica dello stato prima/dopo.
