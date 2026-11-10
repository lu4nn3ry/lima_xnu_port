# 05 — Interrupções e timers

Sem GIC e timer funcionando não há kernel. Este documento define o que
descobrir e por quê.

---

## 1. GIC (Generic Interrupt Controller)

O que importa:

| Item | Por quê |
| ---- | ------- |
| Versão (v2, v3, v4) | modelo de programação e registradores completamente diferentes |
| Base do distribuidor | `GICD` |
| Base do CPU interface | `GICC` (v2) ou redefinida em `GICR`/system registers (v3) |
| Número de linhas (SPIs) | tamanho da tabela de IRQ |
| Estrutura de afinidade (v3) | um `GICR` por CPU, endereço derivado |
| Quem inicializa antes de nós | LK/preloader pode deixar o GIC já configurado — ou não |

Coleta indireta:

```sh
adb shell 'cat /proc/interrupts | head -40'
adb shell 'dmesg | grep -i -E "gic|irqchip|interrupt"' | head -40
# DTB:
#   /interrupt-controller@...  (compatible: arm,gic-400 / arm,gic-v3)
```

No DTB, o `compatible` do nó do controlador resolve a versão. Para MT6771 a
suspeita é GIC-400 (v2) ou GICv3 — **não assumir**; os dois aparecem em
plataformas ARM64 dessa geração.

Ponto de atenção MediaTek: além do GIC, existe um **`mtk,sysirq`** (tradução de
IRQ do SoC para linhas do GIC). Se os drivers de periférico usarem números de
IRQ "do SoC", o mapa precisa dessa tradução.

## 2. Timers

| Timer | Papel |
| ----- | ----- |
| `CNTPCT_EL0` / `CNTVCT_EL0` | contador arquitetural, sempre presente em ARMv8 |
| `CNTP_*` / `CNTV_*` | comparadores; base do tick do kernel |
| `mtk,timer` (SoC) | timer proprietário, usado por algumas funções MediaTek |
| Watchdog | reset por timeout — perigoso durante bring-up |

Requisitos mínimos para a Fase 2:

- [ ] Frequência do contador (`CNTFRQ_EL0`) lida corretamente
- [ ] Tick periódico via `CNTP` funcionando
- [ ] Watchdog desarmado/renovado (ou identificado e evitado)
- [ ] Origem de tempo consistente com a UART (para medir delays)

## 3. Interrupções de periféricos que interessam

| Periférico | IRQ | Status |
| ---------- | --- | ------ |
| UART (se acessível) | — | pendente |
| Display / DSI | — | pendente |
| eMMC / SDHCI | — | pendente |
| Touch (GPIO) | — | pendente |
| USB | — | pendente |

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
