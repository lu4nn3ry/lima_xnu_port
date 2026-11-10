# `lima_32` — Motorola Moto G8 Play (XT2015-2)

Alvo atual do projeto. Documentação de referência:
`docs/01-device-identity.md` (identidade), `docs/02-boot-chain.md` (boot),
`docs/03`–`08` (hardware).

## Status

**Fase 0 — pesquisa e inventário concluídos.** Nenhuma alteração de escrita foi feita no aparelho. Todos os dados abaixo foram verificados diretamente no hardware via Fastboot e ADB.

## Resumo (verificado em hardware)

| Campo | Valor | Confiança | Fonte |
| ----- | ----- | --------- | ----- |
| Modelo | XT2015-2 | **verificado** | `fastboot getvar sku` |
| Codinome | `lima_32` (userspace 32-bit sobre kernel arm64) | **verificado** | `fastboot getvar product` / `getprop` |
| SoC | **MediaTek MT6771V/WL** (Helio P70) | **verificado** | `fastboot getvar cpu` & `/proc/cpuinfo` |
| CPU | 4× Cortex-A53 (`0xd03`) + 4× Cortex-A73 (`0xd09`) | **verificado** | `adb shell cat /proc/cpuinfo` |
| Frequência CPU | 793 MHz – 1.989 GHz | **verificado** | `cpufreq/scaling_available_frequencies` |
| RAM | 2 GB LPDDR4x (~1.8 GB visível ao kernel) | **verificado** | `fastboot getvar ram` & `/proc/meminfo` |
| Storage | eMMC 32 GB (`msdc@11230000`) | **verificado** | `fastboot getvar partition-size:userdata` & IRQs |
| Tela | **720×1520** (DSI `0x14014000`) | **verificado** | `getevent -p` (`mtk-tpd` digitizer) |
| PMIC | **MT6358** | **verificado** | `/proc/interrupts` (`mt6358-irq` no `mt-eint 182`) |
| GIC | **GICv3** | **verificado** | `/proc/interrupts` (`GICv3 29 Level arch_timer`) |
| Console Serial | UART0 (`0x11002000`, `ttyS0`) | **verificado** | devicetree & `/proc/interrupts` |
| Firmware atual | Android 10 (`QMDS30.47-33-5`, RETBR) | **verificado** | `fastboot getvar ro.build.fingerprint` |
| Bootloader | Desbloqueado (`flashing_unlocked`) | **verificado** | `fastboot getvar securestate` |

## Arquivos

| Arquivo | Papel |
| ------- | ----- |
| `device.yaml` | descrição legível por máquina, com `status` por campo |
| `defconfig` | configuração de build do alvo (template; nada ativo) |
| `notes/` | notas datadas de sessões de coleta |

## Como usar

1. Leia `docs/09-safety-and-backups.md` antes de qualquer coisa.
2. Rode `tools/collect-inventory.sh` (read-only) com o aparelho conectado.
3. Salve a saída em `research/hardware/`.
4. Atualize `device.yaml`, `docs/01` e `docs/03` com valores verificados e a
   fonte de cada um.
5. Registre a sessão em `notes/AAAA-MM-DD-*.md`.

## O que não fazer

- Não copiar `defconfig`/mapas de memória de MT6768, Snapdragon ou de qualquer
  outro aparelho.
- Não usar scatter file de outro modelo.
- Não gravar partições.
