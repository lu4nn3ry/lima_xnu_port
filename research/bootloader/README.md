# `research/bootloader/`

Material sobre preloader, LK e o caminho de carga do `lima_32`.

## Prioridade: entender antes de tocar

O objetivo desta pasta é responder, com evidência:

1. Qual versão de preloader/LK o aparelho usa?
2. O bootloader está desbloqueado?
3. Existe caminho de carga **sem gravação** (BROM em RAM, `fastboot boot`)?
4. Quais imagens o bootloader aceita (assinatura? AVB? hash?)?
5. Como se recupera o aparelho se algo der errado?

## Coleta (somente leitura)

```sh
fastboot getvar all            # em modo bootloader; apenas leitura
fastboot devices
adb shell getprop | grep -E 'ro.boot|verifiedboot'
adb shell cat /proc/cmdline
```

Com `mtkclient` (se usado): apenas comandos de leitura, e conferir a saída antes
de qualquer coisa. Nenhum subcomando de escrita.

## O que registrar

| Item | Onde salvar |
| ---- | ----------- |
| `fastboot getvar all` completo | `fastboot-getvar.txt` |
| Versão de LK/preloader | `versions.md` |
| Mensagens do modo fastboot | `fastboot-notes.md` |
| Hashes das imagens de boot | `hashes.txt` |

## Avisos

- Não publicar `getvar` sem revisar: pode conter serial, IMEI e dados únicos.
- Não atualizar preloader/LK por conta própria.
- Anti-rollback é um risco real em MediaTek; verificar antes de qualquer OTA
  manual.
