# my-scripts

Raccolta personale di script sysadmin. Ogni script è autodocumentato: l'header ASCII
in testa al file spiega *perché esiste, quando usarlo, parametri, avvertenze*.

## docker:ubuntu

Per installare Docker Engine + buildx/compose dal repo APT ufficiale.
Opzioni: `--user NOME`, `--no-group`, `-h`.

```sh
curl -fsSL https://raw.githubusercontent.com/FVilli/my-scripts/main/ubuntu/install-docker.sh | sudo sh
```

## avahi:ubuntu

Per rendere il server raggiungibile come `<hostname>.local` e scoprire i servizi mDNS in LAN.
Opzioni: `--no-firewall`, `-h`.

```sh
curl -fsSL https://raw.githubusercontent.com/FVilli/my-scripts/main/ubuntu/install-avahi.sh | sudo sh
```

## nodejs-nvm-pi:ubuntu

Per installare NVM, Node.js LTS e il coding agent `pi` globalmente. Non usare sudo.

```sh
curl -fsSL https://raw.githubusercontent.com/FVilli/my-scripts/main/ubuntu/install-nodejs-nvm-pi.sh | sh
```

## disable-power-button:ubuntu

Per rendere inattivo il pulsante fisico di alimentazione (spegni solo con `sudo poweroff`).
Chiude le sessioni SSH attive: ricollegati dopo.

```sh
curl -fsSL https://raw.githubusercontent.com/FVilli/my-scripts/main/ubuntu/disable-power-button.sh | sudo sh
```
