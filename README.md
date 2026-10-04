# my-scripts

Libreria personale di script per automazioni sysadmin. Piattaforma corrente: Ubuntu (AMD Ryzen 7 5700U bare-metal), ma non limitato — spazio per PowerShell su Windows e altro.

## Struttura

```
ubuntu/            ← script Ubuntu
└── disable-power-button.sh
```

Pianificato: `windows/` con PowerShell.

## Regole

- Ogni script deve avere un **header ASCII descrittivo** in cima (perché, quando, come)
- L'**INDEX.md** tiene l'indice leggero — la documentazione estesa resta nello script

## Note

- Script autonomi, nessuna dipendenza esterna non di base
- Documentazione principale negli header ASCII di ogni script
- Nessun test, CI o build system — sono script da lanciare e dimenticare
