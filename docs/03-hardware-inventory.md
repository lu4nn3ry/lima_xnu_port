# 03 — Inventário de hardware

Template de inventário. Cada linha precisa de **fonte** (comando + saída, ou
referência). Nada aqui é considerado definitivo sem verificação.

Preenchimento parcial é normal. O documento serve para mostrar o que ainda falta.

---

## 1. CPUs

| Cluster | Núcleos | Microarquitetura | Frequência | Status |
| ------- | ------- | ---------------- | ---------- | ------ |
| 0 | 4 | a verificar (A53?) | — | pendente |
| 1 | 4 | a verificar (A73? A53?) | — | pendente |

Coleta:

```sh
adb shell 'cat /proc/cpuinfo'
adb shell 'for c in /sys/devices/system/cpu/cpu[0-9]*; do \
  echo "$c $(cat $c/regs/identification/midr_el1 2>/dev/null)"; done'
adb shell 'cat /sys/devices/system/cpu/cpu0/regs/identification/midr_el1'
adb shell 'ls /sys/devices/system/cpu/cpufreq'
```

Interpretação do MIDR (ARM64): `Implementer`, `Variant`, `Architecture`,
`PartNum`, `Revision`. `0x41` = ARM. PartNum `0xD03` = Cortex-A53,
`0xD09` = Cortex-A73. É a forma mais direta de decidir MT6771 vs. MT6765.

## 2. Memória

| Campo | Valor | Status |
| ----- | ----- | ------ |
| RAM total | — | pendente |
| Regiões reservadas | ver `04-memory-map.md` | pendente |
| Base física da DRAM | — | pendente (DTB / BROM) |

## 3. Interrupções e timers

Ver `05-interrupts-timers.md`.

## 4. Display

| Campo | Valor | Status |
| ----- | ----- | ------ |
| Controlador DSI | — | pendente |
| Painel (modelo) | — | pendente |
| Resolução nativa | conflitante (1520 vs. 1600) | pendente |
| Número de lanes DSI | — | pendente |
| Backlight | — | pendente |

## 5. Armazenamento

| Campo | Valor | Status |
| ----- | ----- | ------ |
| Controlador | — (eMMC? UFS?) | pendente |
| Partição de rootfs | — | pendente |
| Tamanho | — | pendente |

## 6. Entrada

| Campo | Valor | Status |
| ----- | ----- | ------ |
| Touch controller | — | pendente |
| Barramento (I2C/SPI) | — | pendente |
| Endereço | — | pendente |
| GPIO de IRQ | — | pendente |
| Botões | — | pendente |

## 7. Energia

| Campo | Valor | Status |
| ----- | ----- | ------ |
| PMIC | — (MT6358? MT6359?) | pendente |
| Reguladores relevantes | — | pendente |
| Charger | — | pendente |

## 8. Log e debug

| Recurso | Disponível? | Observação |
| ------- | ----------- | ---------- |
| UART exposta | — | precisa de acesso físico |
| `pstore` / `ramoops` | — | verificar `/sys/fs/pstore` |
| `/proc/last_kmsg` | — | kernels antigos; MTK costuma ter algo equivalente |
| Console de boot do LK | — | visível em fastboot? |

## 9. Como preencher de forma reproduzível

1. Rodar `tools/collect-inventory.sh` com o aparelho conectado (read-only).
2. Guardar a saída em `research/hardware/<data>-inventory.txt`.
3. Extrair os valores para as tabelas acima, citando `id` da coleta.
4. Se dois valores conflitarem, registrar **os dois** e abrir uma pendência.
