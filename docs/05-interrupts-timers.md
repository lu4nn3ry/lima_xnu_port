# 05 — Interrupções e timers

Sem GIC e timer funcionando não há kernel. Este documento define o que
descobrir e por quê.

---

## 1. GIC (Generic Interrupt Controller)

| Item | Valor Verificado | Fonte |
| ---- | ---------------- | ----- |
| Versão | **GICv3** | `adb shell cat /proc/interrupts` (`GICv3 29 Level arch_timer`) |
| Nó no Devicetree | `gic@1023a000` / `interrupt-controller@0c000000` | `/sys/firmware/devicetree/base` |
| Polarizador de IRQ | `intpol-controller@0c530620` | `/sys/firmware/devicetree/base` |
| Tradução MediaTek | `MT_SYSIRQ` (linhas do SoC mapeadas para GIC SPIs) | `/proc/interrupts` |

## 2. Timers e Watchdog

| Timer | Papel / Configuração | IRQ | Fonte |
| ----- | -------------------- | --- | ----- |
| ARM Arch Timer | `CNTPCT_EL0` / `CNTVCT_EL0` (PPIs) | IRQ 29, 30 (`GICv3 Level`) | `/proc/interrupts` |
| MediaTek APXGPT | `apxgpt@10008000` (`mt-gpt`) | `MT_SYSIRQ 176 Level` | `/proc/interrupts` & DT |
| System Timer | `sys_timer@10017000` | devicetree | `/sys/firmware/devicetree/base` |
| Watchdog | `toprgu@10007000` (`mt_wdt`) | `MT_SYSIRQ 142 Edge` | `/proc/interrupts` & DT |

## 3. Interrupções de periféricos (Mapeamento Real)

| Periférico | Linha de IRQ | Controlador Pai | Status |
| ---------- | ------------ | ---------------- | ------ |
| UART0 (`ttyS0`) | `MT_SYSIRQ 91` | `MT_SYSIRQ` -> GICv3 | **verificado** |
| Display Mutex | `MT_SYSIRQ 217` | `MT_SYSIRQ` | **verificado** |
| Display OVL0 / OVL0_2L | `MT_SYSIRQ 225, 226` | `MT_SYSIRQ` | **verificado** |
| Display RDMA0 | `MT_SYSIRQ 228` | `MT_SYSIRQ` | **verificado** |
| Display CCORR0 | `MT_SYSIRQ 232` | `MT_SYSIRQ` | **verificado** |
| Display DSI0 | `MT_SYSIRQ 236` | `MT_SYSIRQ` | **verificado** |
| eMMC (`msdc@11230000`) | `MT_SYSIRQ 77` | `MT_SYSIRQ` | **verificado** |
| SD Card (`msdc@11240000`) | `MT_SYSIRQ 78` | `MT_SYSIRQ` | **verificado** |
| Touchscreen (`ilitek`) | `mt-eint 6 Edge` | `mt-eint` (GPIO EINT) | **verificado** |
| Fingerprint (`goodix`) | `mt-eint 11 Edge` | `mt-eint` | **verificado** |
| PMIC MT6358 | `mt-eint 182 Level` | `mt-eint` | **verificado** |
| Tecla Power (`pwrkey`) | `mt6358-irq 48, 50` | `mt6358-irq` | **verificado** |
| Teclado Físico (`mtk-kpd`) | `MT_SYSIRQ 186 Edge` | `MT_SYSIRQ` | **verificado** |
| USB (`musb-hdrc`) | `MT_SYSIRQ 72, 73` | `MT_SYSIRQ` | **verificado** |
| GPU Mali-G72 | `MT_SYSIRQ 278, 279, 280` | `MT_SYSIRQ` | **verificado** |

## 4. Ordem de habilitação recomendada

1. Timer arquitetural (não depende de nada além do CPU).
2. GIC: distribuidor + interface da CPU de boot.
3. UART/console: habilita log síncrono, não depende de IRQ.
4. Só então IRQs de periféricos, uma por vez.

## 5. Pendências

- [ ] Determinar versão e bases do GIC a partir do DTB
- [ ] Verificar se existe `mtk,sysirq` e qual o mapa de tradução
- [ ] Confirmar `CNTFRQ_EL0` e se o firmware já o programou
- [ ] Identificar o watchdog e como o kernel Linux o mantém alimentado
