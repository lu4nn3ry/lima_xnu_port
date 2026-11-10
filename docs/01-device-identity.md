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
| Modelo | XT2015-2 | **relato do usuário** (2026-11-10) | confirmar com `adb shell getprop ro.product.model` |
| Codinome Motorola | `lima` (variante `lima_32`?) | a verificar | `ro.product.device`, `ro.build.product` |
| Região / canal | — | a verificar | `ro.carrier`, `ro.build.region` |
| Android de fábrica | 9 (Pie), relatado | público | — |
| Firmware atual | **Android 10** | **relato do usuário** (2026-11-10) | `ro.build.fingerprint`, `ro.build.version.release` |
| Origem do Android 10 | oficial (OTA)? | a verificar | comparar fingerprint com firmware oficial |
| Build atual | — | a verificar | `ro.build.fingerprint` |
| Patch de segurança | — | a verificar | `ro.build.version.security_patch` |

> Nota: um aparelho de fábrica com Android 9 que hoje roda Android 10 pode ter
> recebido OTA de **bootloader/LK/preloader** junto com o sistema. Isso muda a
> cadeia de boot e possivelmente o índice de anti-rollback. Registrar a versão
> do bootloader antes de qualquer conclusão.

## 2. SoC — ponto crítico

Fontes públicas divergem. É **obrigatório** confirmar no aparelho.

| Hipótese | Situação |
| -------- | -------- |
| MediaTek **MT6771** / Helio P70 (4×A73 + 4×A53, Mali-G72 MP3) | Relatado em fontes de especificação. É a hipótese de trabalho. |
| MediaTek **MT6765** / Helio P35 (4×A53 + 4×A53, PowerVR GE8320) | Também aparece associado a modelos da mesma família. Não descartar. |

Consequência prática: MT6771 e MT6765 têm **clusters de CPU diferentes**
(A73+A53 vs. A53+A53) e **GPUs de fabricantes diferentes**. Um port escrito para
um não inicializa o outro. Além disso, o port MT6768 do HakiOS **não** é
MT6771 nem MT6765.

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

| Campo | Valor esperado | Status | Fonte |
| ----- | -------------- | ------ | ----- |
| RAM | 2 GB | público / a confirmar variante | `adb shell cat /proc/meminfo`, `dumpsys meminfo` |
| Armazenamento | 32 GB eMMC 5.1 | público / a verificar | `adb shell 'cat /sys/block/mmcblk0/size'` |
| Tipo de storage | eMMC (vs. UFS) | a verificar | `ls /sys/block`, `dmesg | grep -i mmc` |

Nota: `eMMC 5.1` é plausível para a plataforma, mas o que importa para o port é
o controlador realmente usado (`mmcblk0` vs. `sdhci` vs. UFS). Confirmar antes de
escrever qualquer driver.

## 4. Tela

| Campo | Valor | Status | Fonte |
| ----- | ----- | ------ | ----- |
| Resolução | 720×1520 **ou** 720×1600 | **conflitante** | ver abaixo |
| Painel / controlador | desconhecido | a verificar | `dmesg | grep -i -E 'dsi|panel|lcm'` |
| Densidade | — | a verificar | `wm size`, `wm density` |

`wm size` devolve o tamanho lógico configurado, não necessariamente o nativo.
Para o nativo, o melhor é o DTB (`panel`/`dsi` node) ou o log do kernel Linux.
A diferença 1520 vs. 1600 muda o cálculo de framebuffer e _stride_ — não
improvisar.

## 5. Conectividade e periféricos de interesse

| Componente | Situação | Onde confirmar |
| ---------- | -------- | -------------- |
| Touchscreen | desconhecido | `dmesg`, `getevent -pl`, `/sys/class/input/*/name` |
| USB | desconhecido (PHY/controlador) | `dmesg | grep -i -E 'dwc|musb|usb'` |
| PMIC | desconhecido (MediaTek típico: MT6358/MT6359) | DTB, `dmesg` |
| Modem | presente, **fora de escopo e intocável** | — |
| Wi-Fi/BT | fora de escopo inicial | — |

## 6. Estado do bootloader e slot

| Campo | Valor | Fonte |
| ----- | ----- | ----- |
| Bootloader desbloqueado | **sim — relato do usuário** (2026-11-10) | confirmar com `fastboot getvar unlocked` |
| `ro.boot.verifiedbootstate` | — (esperado `orange` se desbloqueado) | `adb shell getprop` |
| Como foi desbloqueado | — (site oficial Motorola?) | perguntar; afeta `ro.boot.flash.locked` |
| Slots (A/B) | — | `fastboot getvar slot-count`, `ro.boot.slot_suffix` |
| `current-slot` | — | `fastboot getvar current-slot` |
| Aviso de boot do bootloader | — | tela de aviso exibida ao ligar? |

## 7. Pendências deste documento

- [ ] Resolver conflito MT6771 vs. MT6765 com evidência do aparelho
- [ ] Resolver conflito 720×1520 vs. 720×1600
- [ ] Confirmar codinome exato (`lima` vs. `lima_32`) e o que o sufixo significa
- [ ] Preencher todos os campos "a verificar"
