# 01 — Identidade do aparelho

Este é o documento mais importante da Fase 0. Ele deve conter **apenas** dados
verificados ou explicitamente rotulados como não verificados.

Regra: todo item tem um campo **Fonte**. Valores aceitáveis:

- `verificado: <comando> → <saída resumida>` (o melhor caso)
- `público: <URL> (acessado em AAAA-MM-DD)`
- `hipótese`
- `conflitante: ver nota N`

---

## 1. Identificação

| Campo | Valor | Status | Fonte |
| ----- | ----- | ------ | ----- |
| Marca / modelo comercial | Motorola Moto G8 Play | público | — |
| Modelo | XT2015-2 | **verificado** | `fastboot getvar sku / carrier_sku` → `XT2015-2` |
| Codinome Motorola | `lima_32` (`lima`) | **verificado** | `fastboot getvar product / version-bootloader` → `lima` / `lima_32_retail` |
| Região / canal | `retbr` (Retail Brasil) | **verificado** | `fastboot getvar ro.carrier` → `retbr` |
| Android de fábrica | 9 (Pie), relatado | público | — |
| Firmware atual | **Android 10** | **verificado** | `fastboot getvar ro.build.fingerprint` → `motorola/lima_32/lima:10/QMDS30.47-33-5/7e278:user/release-keys` |
| Origem do Android 10 | oficial (OTA Motorola) | **verificado** | assinatura `release-keys`, canal `retbr` |
| Build atual | `QMDS30.47-33-5` | **verificado** | `fastboot getvar ro.build.fingerprint` |
| Bootloader MBM | `MBM-2.1-lima_32_retail-b64a50bf6-211028` | **verificado** | `fastboot getvar version-bootloader` |
| Kernel Linux base | `4.14.141+ (Thu Oct 28 10:57:32 CDT 2021)` | **verificado** | `fastboot getvar kernel.version` |

---

## 2. SoC — ponto crítico (Resolvido)

O conflito de SoC foi definitivamente resolvido via consulta de hardware ao bootloader:

| Campo | Valor | Status | Fonte |
| ----- | ----- | ------ | ----- |
| SoC Real | **MediaTek MT6771V/WL** | **verificado** | `fastboot getvar cpu` → `MT6771V/WL` |
| Família | Helio P70M / P60 | verificado | especificação MT6771 |
| Topologia de CPU | 4× Cortex-A73 @ 2.0 GHz + 4× Cortex-A53 @ 2.0 GHz | arquitetural | MT6771 |
| GPU | ARM Mali-G72 MP3 | arquitetural | MT6771 |
| Baseband | `MT6771_V70.02.01.113R` | verificado | `fastboot getvar version-baseband` |

> Conclusão: O aparelho utiliza o MediaTek **MT6771** (A73+A53, Mali). O MT6765 está descartado.
> O port de referência MT6768 (Helio G80/G85 do HakiOS) compartilha a mesma arquitetura de barramento MediaTek e GIC, servindo como forte base comparativa.

Verificação (em ordem de confiabilidade):

```sh
# 1. Plataforma declarada pelo Android
adb shell getprop ro.board.platform      # ex.: mt6771 / mt6765
adb shell getprop ro.hardware
adb shell getprop ro.product.board

# 2. Compatibilidade de kernel declarada
adb shell cat /proc/version

# 3. Device tree — a fonte mais forte
adb shell 'ls /proc/device-tree'
adb shell 'cat /proc/device-tree/model; echo'
adb shell 'cat /proc/device-tree/compatible | tr "\0" "\n"'

# 4. Topologia de CPU (distingue A73+A53 de A53+A53)
adb shell 'for c in /sys/devices/system/cpu/cpu[0-9]*; do \
  echo "$c: $(cat $c/regs/identification/midr_el1 2>/dev/null)"; done'
adb shell 'cat /proc/cpuinfo'
adb shell 'ls /sys/devices/system/cpu/cpufreq/'

# 5. GPU
adb shell 'cat /sys/class/kgsl/kgsl-3d0/gpu_model 2>/dev/null'   # Qualcomm
adb shell 'ls /sys/class/misc/mali0 2>/dev/null'                 # Mali
adb shell 'dumpsys SurfaceFlinger | grep -i -m5 gpu'

# 6. Confirmação cruzada offline (somente leitura)
#    mtkclient em modo leitura pode mostrar HW code / HW subcode / HW version
#    do preloader/BootROM. NÃO usar comandos de escrita.
```

Registrar a saída bruta em `research/hardware/soc-identification.txt`.

## 3. Memória e armazenamento

| Campo | Valor | Status | Fonte |
| ----- | ----- | ------ | ----- |
| RAM | 2 GB LPDDR4x | **verificado** | `fastboot getvar ram` → `2GB SAMSUNG LP4x DIE=16Gb` |
| Armazenamento | 32 GB | **verificado** | `fastboot getvar emmc` → `32GB SAMSUNG 4X6KMB RV=08 PV=00 FV=0000000000000003` |
| Tipo de storage | eMMC | **verificado** | `fastboot getvar storage-type` → `eMMC` |

## 4. Tela

| Campo | Valor | Status | Fonte |
| ----- | ----- | ------ | ----- |
| Resolução | 720×1520 **ou** 720×1600 | **conflitante** | a verificar via DTB/dmesg |
| Painel / controlador | desconhecido | a verificar | `dmesg | grep -i -E 'dsi|panel|lcm'` |
| Densidade | — | a verificar | `wm size`, `wm density` |

## 5. Conectividade e periféricos de interesse

| Componente | Situação | Onde confirmar |
| ---------- | -------- | -------------- |
| Touchscreen | desconhecido | `dmesg`, `getevent -pl`, `/sys/class/input/*/name` |
| USB | desconhecido (PHY/controlador) | `dmesg | grep -i -E 'dwc|musb|usb'` |
| PMIC | MediaTek (típico MT6358 com MT6771) | DTB, `dmesg` |
| Modem | presente, **fora de escopo e intocável** | — |
| Wi-Fi/BT | fora de escopo inicial | — |

## 6. Estado do bootloader e slot

| Campo | Valor | Status | Fonte |
| ----- | ----- | ------ | ----- |
| Bootloader desbloqueado | **sim (`flashing_unlocked`)** | **verificado** | `fastboot getvar securestate` → `flashing_unlocked` |
| Como foi desbloqueado | portal oficial Motorola via `fastboot oem unlock` com Unique Key | **verificado** | executado em 2026-11-10 |
| `iswarrantyvoid` | `yes` | **verificado** | `fastboot getvar iswarrantyvoid` → `yes` |
| Slots (A/B) | 2 slots (`_a`, `_b`) | **verificado** | `fastboot getvar slot-count` → `2` |
| `current-slot` | `a` (running-slot: `_a`) | **verificado** | `fastboot getvar current-slot` → `a` |
| Versão do Bootloader | `MBM-2.1-lima_32_retail-b64a50bf6-211028` | **verificado** | `fastboot getvar version-bootloader` |
| Max download size | 268435456 bytes (256 MB) | **verificado** | `fastboot getvar max-download-size` |

## 7. Pendências deste documento

- [x] Resolver conflito MT6771 vs. MT6765 com evidência do aparelho (Resolvido: MT6771V/WL)
- [x] Confirmar codinome exato (`lima` / `lima_32`) (Resolvido: `lima` com MBM `lima_32_retail`)
- [x] Confirmar desbloqueio e slots A/B (Resolvido: `flashing_unlocked`, A/B com slot A ativo)
- [ ] Resolver conflito 720×1520 vs. 720×1600 (extrair DTB)
- [ ] Extrair device tree (`/sys/firmware/fdt` ou `boot.img`/`dtbo`)
