# `research/kernel/`

Material sobre o kernel Android/Linux que roda no `lima_32` hoje.

## Por que estudar o kernel Linux do aparelho

Não vamos copiar código (GPL vs. APSL, e arquitetura diferente). Mas o kernel
Linux é a **melhor documentação disponível** do hardware:

- drivers mostram endereços, IRQs, sequências de inicialização e quirks;
- `dmesg` mostra a ordem real de probe e o que o bootloader deixou pronto;
- o DTB usado pelo kernel é a fonte primária do mapa de hardware.

## O que coletar

| Item | Como | Status |
| ---- | ---- | ------ |
| Versão e config do kernel | `cat /proc/version`, `zcat /proc/config.gz` (se existir) | pendente |
| `dmesg` completo do boot | `adb shell dmesg` | pendente |
| Config embutida no `boot.img` | `extract-ikconfig` | pendente |
| Fontes do kernel Motorola (se publicadas) | site de código aberto da Motorola | pendente |
| `cmdline` do kernel | `cat /proc/cmdline` | pendente |

## O que observar no `dmesg`

- ordem de inicialização dos clocks e reguladores;
- mensagens de `mtk_drm`/`mtk_dsi` (timings do painel);
- `mmc0: ...` (modo, barramento, versão do eMMC);
- `input: ...` (touch);
- regiões reservadas e `memblock`;
- mensagens de secure monitor (ATF/TEE).

## Regra

Material de kernel Linux é **referência**, nunca código a portar. Registrar
sempre de qual versão/commit veio.
