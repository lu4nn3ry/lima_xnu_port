# `tools/`

Scripts auxiliares. **Todos começam read-only.**

## `collect-inventory.sh`

Coleta de inventário via `adb` (e opcionalmente `fastboot getvar`). Não escreve
nada no aparelho. Saída vai para `research/hardware/AAAA-MM-DD-inventory.txt`.

```sh
sh tools/collect-inventory.sh            # só adb
sh tools/collect-inventory.sh --fastboot # inclui fastboot getvar all
```

Requisitos: `adb` no PATH; aparelho com depuração USB habilitada e autorizada.
No Windows, rodar via **Git Bash ou WSL** (o `bash` nativo não está disponível
nesta máquina).

O script:

- só executa comandos de leitura (`getprop`, `cat`, `ls`, `dmesg`, `getevent -pl`);
- aborta se um comando contiver `flash`, `erase`, `format`, `set_active`;
- escreve um cabeçalho com data, modelo e fingerprint;
- não publica nada: o arquivo fica local.

## Ferramentas previstas

| Ferramenta | Função |
| ---------- | ------ |
| `check-dump.sh` | calcula e compara hashes de backups |
| `extract-dtb.sh` | separa DTB de `boot.img` e decompila |
| `reserved-memory.sh` | resume `/reserved-memory` do DTS |
| `qemu-run.sh` | executa o loader em `qemu-system-aarch64` |

## Regras

1. Read-only por padrão; escrita exige flag explícita **e** documentação.
2. Nunca embutir credenciais, seriais ou IMEI em código.
3. Saída sempre em arquivo, com data — nunca só no terminal.
4. Um script que não é seguro o suficiente para rodar num aparelho de produção
   não entra aqui.
