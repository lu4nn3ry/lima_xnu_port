# 03 — Inventário de hardware

Template de inventário. Cada linha precisa de **fonte** (comando + saída, ou
referência). Nada aqui é considerado definitivo sem verificação.

Preenchimento parcial é normal. O documento serve para mostrar o que ainda falta.

---

## 1. CPUs

| Cluster | Núcleos | Microarquitetura | PartNum | Frequência | Status | Fonte |
| ------- | ------- | ---------------- | ------- | ---------- | ------ | ----- |
| 0 (LITTLE) | 4 (CPU0-3) | ARM Cortex-A53 (r0p4) | `0xd03` | 793 MHz – 1.989 GHz | **verificado** | `adb shell cat /proc/cpuinfo` & `cpufreq` |
| 1 (big)    | 4 (CPU4-7) | ARM Cortex-A73 (r0p2) | `0xd09` | 793 MHz – 1.989 GHz | **verificado** | `adb shell cat /proc/cpuinfo` & `cpufreq` |

Verificação via ADB (`/proc/cpuinfo`):
```text
processor 0..3: CPU implementer 0x41, CPU part 0xd03 (Cortex-A53), revision 4
processor 4..7: CPU implementer 0x41, CPU part 0xd09 (Cortex-A73), revision 2
Hardware      : MT6771V/WL
```
Frequências disponíveis (`scaling_available_frequencies`):
`1989000 1924000 1846000 1781000 1716000 1677000 1625000 1586000 1508000 1417000 1326000 1248000 1131000 1014000 910000 793000` (kHz)

## 2. Memória

| Campo | Valor | Status | Fonte |
| ----- | ----- | ------ | ----- |
| RAM total visível ao kernel | ~1.8 GB (`1846936 kB`) | **verificado** | `/proc/meminfo` |
| RAM física instalada | 2.0 GB (LPDDR4x) | catálogo/bootloader | — |
| Regiões reservadas | ver `04-memory-map.md` | pendente | — |
| Base física da DRAM | `0x40000000` (padrão MT6771) | pendente confirmação DTB | DTB stock |

## 3. Interrupções e timers

Ver `05-interrupts-timers.md`.

## 4. Display

| Campo | Valor | Status | Fonte |
| ----- | ----- | ------ | ----- |
| Controlador DSI | `dsi0@14014000` | **verificado** | `/sys/firmware/devicetree/base` |
| OVL / RDMA / Mutex | `ovl0@14008000`, `rdma0@1400b000`, `mutex@14016000` | **verificado** | `/proc/interrupts` & devicetree |
| Resolução nativa | **720 × 1520** | **verificado** | `getevent -p` (`mtk-tpd` ABS X=720, Y=1520) |
| Backlight | `disp_pwm0@1100e000` / PMIC | **verificado** | devicetree & `/proc/interrupts` |

## 5. Armazenamento

| Campo | Valor | Status | Fonte |
| ----- | ----- | ------ | ----- |
| Controlador | MediaTek MSDC eMMC (`mtk-msdc`) | **verificado** | `/proc/interrupts` IRQs 77, 78 (`MT_SYSIRQ`) |
| Nós de barramento | `msdc@11230000` (eMMC), `msdc@11240000` (SD) | **verificado** | devicetree & `/proc/interrupts` |
| Layout de partições | 63 partições em `/dev/block/by-name` | **verificado** | `adb shell ls -l /dev/block/by-name` |

## 6. Entrada

| Campo | Valor | Status | Fonte |
| ----- | ----- | ------ | ----- |
| Touch controller | Ilitek (`ilitek`) | **verificado** | `/proc/interrupts` (`mt-eint 6 Edge`) |
| Touch digitizer | `mtk-tpd` (720x1520) | **verificado** | `getevent -p` (Direct Touch, ABS 0..720, 0..1520) |
| Botões físicos | Teclado `mtk-kpd` | **verificado** | `/proc/interrupts` (`MT_SYSIRQ 186`) & `getevent` |
| Botão Power | `pwrkey` / `pwrkey_r` no PMIC | **verificado** | `/proc/interrupts` (`mt6358-irq 48, 50`) |
| Sensor Biométrico | Goodix (`goodix_fp_irq`) | **verificado** | `/proc/interrupts` (`mt-eint 11 Edge`) |

## 7. Energia

| Campo | Valor | Status | Fonte |
| ----- | ----- | ------ | ----- |
| PMIC principal | **MediaTek MT6358** | **verificado** | `/proc/interrupts` (`mt6358-irq` no `mt-eint 182`) |
| Barramento PMIC | PMIC-PWRAP (`pwrap@1000d000`) | **verificado** | `/proc/interrupts` (`MT_SYSIRQ 185`) |
| RTC | MT6358 RTC interno | **verificado** | `/proc/interrupts` (`mt6358-irq 64`) |
| Sub-PMIC / Charger | Richtek `rt5081` / `rt9465` / `mt6370` | verificado | devicetree & interrupts |

## 8. Log e debug

| Recurso | Disponível? | Endereço / IRQ | Observação |
| ------- | ----------- | -------------- | ---------- |
| UART0 (`ttyS0`) | Sim | `0x11002000`, IRQ 91 | Console serial principal do SoC MT6771 |
| UART1 | Sim | `0x11003000` | Segundo canal UART |
| UART2 | Sim | `0x11004000` | Terceiro canal UART |
| Watchdog | Sim | `toprgu@10007000`, IRQ 142 | MediaTek RGU Watchdog (`mt_wdt`) |

## 9. Como preencher de forma reproduzível

1. Rodar `tools/collect-inventory.sh` com o aparelho conectado (read-only).
2. Guardar a saída em `research/hardware/<data>-inventory.txt`.
3. Extrair os valores para as tabelas acima, citando `id` da coleta.
4. Se dois valores conflitarem, registrar **os dois** e abrir uma pendência.
