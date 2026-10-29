# my-scripts

Libreria personale di script per automazioni sysadmin. Piattaforma corrente: Ubuntu (AMD Ryzen 7 5700U bare-metal), ma non limitato — spazio per PowerShell su Windows e altro.

## Struttura

```
ubuntu/            ← script Ubuntu
├── disable-power-button.sh
├── install-docker.sh
└── install-nodejs-nvm-pi.sh
```

Pianificato: `windows/` con PowerShell.

## Installazione Docker Engine

Installa `docker-ce`, `docker-ce-cli`, `containerd.io`, `docker-buildx-plugin` e
`docker-compose-plugin` dal repository APT ufficiale di Docker (niente snap, niente
script `get.docker.com`). Configura chiave GPG, repo, abilita il servizio systemd e
aggiunge l'utente al gruppo `docker`. Rieseguibile senza toccare container e immagini.
Rimuove gli eventuali pacchetti in conflitto (`docker.io`, `containerd`, `runc`, ...).

Parametri:

- `--user NOME` — utente da aggiungere al gruppo `docker` (default: chi ha lanciato `sudo`)
- `--no-group` — non modificare l'appartenenza al gruppo `docker`
- `-h`, `--help` — aiuto

Uso rapido:

```sh
curl -fsSL https://raw.githubusercontent.com/FVilli/my-scripts/main/ubuntu/install-docker.sh | sudo sh
```

## Node.js + NVM + pi

Installa NVM (`~/.nvm`), l'ultima Node.js LTS e il coding agent `pi`
(`@earendil-works/pi-coding-agent`) globalmente via npm. Da eseguire come utente
normale, **non** con sudo. Dopo l'esecuzione serve un nuovo login (o `source ~/.bashrc`)
per avere `nvm` e `pi` nel PATH.

Parametri: nessuno (variabili opzionali: `NVM_VERSION`, `NVM_DIR`, `PI_PACKAGE`).

Uso rapido:

```sh
curl -fsSL https://raw.githubusercontent.com/FVilli/my-scripts/main/ubuntu/install-nodejs-nvm-pi.sh | sh
```

## Disabilita pulsante di alimentazione

Imposta a `ignore` le azioni di systemd-logind per i tasti fisici di alimentazione,
sospensione, ibernazione e coperchio (`HandlePowerKey`, `HandleSuspendKey`,
`HandleHibernateKey`, `HandleLidSwitch`), tramite drop-in permanente in
`/etc/systemd/logind.conf.d/`. Spegnimento solo esplicito con `sudo poweroff`.

Parametri: nessuno. Richiede root. **Attenzione:** il restart di `systemd-logind`
chiude le sessioni SSH attive — ricollegati dopo.

Uso rapido:

```sh
curl -fsSL https://raw.githubusercontent.com/FVilli/my-scripts/main/ubuntu/disable-power-button.sh | sudo sh
```

## Regole

- Ogni script deve avere un **header ASCII descrittivo** in cima (perché, quando, come)
- L'**INDEX.md** tiene l'indice leggero — la documentazione estesa resta nello script

## Note

- Script autonomi, nessuna dipendenza esterna non di base
- Documentazione principale negli header ASCII di ogni script
- Nessun test, CI o build system — sono script da lanciare e dimenticare
