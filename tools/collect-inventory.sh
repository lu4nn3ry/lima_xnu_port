#!/usr/bin/env bash
# collect-inventory.sh
#
# Coleta READ-ONLY de informações do aparelho via adb (opcionalmente fastboot).
#
# Garantias:
#   - nunca executa flash, erase, format, set_active, unlock ou write;
#   - não modifica nada no aparelho;
#   - grava tudo em research/hardware/AAAA-MM-DD-inventory.txt.
#
# Uso:
#   sh tools/collect-inventory.sh
#   sh tools/collect-inventory.sh --fastboot
#
# Requisitos: adb no PATH; depuração USB habilitada e autorizada.

set -u

OUT_DIR="research/hardware"
DATE="$(date +%Y-%m-%d 2>/dev/null || echo desconhecido)"
OUT="${OUT_DIR}/${DATE}-inventory.txt"
WITH_FASTBOOT=0

for arg in "$@"; do
  case "$arg" in
    --fastboot) WITH_FASTBOOT=1 ;;
    -h|--help)
      sed -n '2,20p' "$0"
      exit 0
      ;;
    *)
      echo "argumento desconhecido: $arg" >&2
      exit 2
      ;;
  esac
done

if ! command -v adb >/dev/null 2>&1; then
  echo "erro: adb nao encontrado no PATH" >&2
  exit 1
fi

# Guarda de seguranca: bloqueia qualquer comando com verbo de escrita.
guard() {
  case "$1" in
    *flash*|*erase*|*format*|*set_active*|*unlock*|*write*|*delete*|*wipe*)
      echo "BLOQUEADO (verbo de escrita): $1" >&2
      return 1
      ;;
  esac
  return 0
}

mkdir -p "$OUT_DIR"
: > "$OUT"

sect() {
  printf '\n\n===== %s =====\n' "$1" >> "$OUT"
}

# adb shell com uma unica string (permite pipes)
sh_() {
  guard "$1" || return 1
  printf '\n$ adb shell %s\n' "$1" >> "$OUT"
  adb shell "$1" >> "$OUT" 2>&1 || printf '[falhou ou sem permissao]\n' >> "$OUT"
}

# comando no host
host_() {
  guard "$1" || return 1
  printf '\n$ %s\n' "$1" >> "$OUT"
  eval "$1" >> "$OUT" 2>&1 || printf '[falhou]\n' >> "$OUT"
}

# --------------------------------------------------------------------------
sect "cabecalho"
{
  echo "# coletado em: $(date 2>/dev/null)"
  echo "# metodo: adb/fastboot, somente leitura"
  echo "# versao do script: 1"
  echo "# maquina: $(uname -a 2>/dev/null)"
} >> "$OUT"

sect "dispositivos"
host_ "adb devices -l"

sect "identidade"
sh_ "getprop | grep -i -E 'ro.product|ro.build|ro.board|ro.hardware|ro.carrier|ro.boot'"

sect "campos-chave"
for p in \
  ro.product.model \
  ro.product.device \
  ro.build.product \
  ro.board.platform \
  ro.hardware \
  ro.boot.hardware \
  ro.build.fingerprint \
  ro.build.version.release \
  ro.build.version.security_patch \
  ro.boot.verifiedbootstate \
  ro.boot.slot_suffix \
  ro.boot.bootloader \
  ro.carrier
do
  sh_ "getprop $p"
done

sect "cpu"
sh_ "cat /proc/cpuinfo"
sh_ "cat /proc/version"
sh_ "ls /sys/devices/system/cpu/"
sh_ "for c in /sys/devices/system/cpu/cpu[0-9]*; do echo \"\$c \$(cat \$c/regs/identification/midr_el1 2>/dev/null)\"; done"
sh_ "ls /sys/devices/system/cpu/cpufreq/ 2>/dev/null"
sh_ "cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq 2>/dev/null"

sect "memoria"
sh_ "cat /proc/meminfo"
sh_ "cat /proc/iomem"
sh_ "cat /proc/cmdline"

sect "device tree"
sh_ "ls /proc/device-tree 2>/dev/null"
sh_ "cat /proc/device-tree/model 2>/dev/null; echo"
sh_ "cat /proc/device-tree/compatible 2>/dev/null | tr '\\0' '\\n'"

sect "interrupcoes"
sh_ "cat /proc/interrupts"
sh_ "cat /proc/softirqs 2>/dev/null"

sect "armazenamento"
sh_ "ls -l /sys/block/"
sh_ "cat /sys/block/mmcblk0/size 2>/dev/null"
sh_ "ls /sys/block/mmcblk0/device/ 2>/dev/null"
sh_ "cat /proc/partitions"
sh_ "mount | head -40"
sh_ "cat /proc/mounts | head -40"

sect "display"
sh_ "wm size"
sh_ "wm density"
sh_ "dmesg | grep -i -E 'dsi|panel|lcm|drm|backlight' | head -60"

sect "entrada"
sh_ "cat /proc/bus/input/devices"
sh_ "cat /sys/class/input/input0/name 2>/dev/null"
sh_ "dmesg | grep -i -E 'touch|input|keypad|gpio-keys' | head -60"

sect "usb e energia"
sh_ "dmesg | grep -i -E 'usb|dwc|charger|pmic' | head -60"
sh_ "cat /sys/class/power_supply/*/uevent 2>/dev/null"

sect "logs do boot"
sh_ "dmesg | head -120"
sh_ "dmesg | tail -120"
sh_ "ls -l /sys/fs/pstore 2>/dev/null"
sh_ "ls -l /proc/last_kmsg 2>/dev/null"
sh_ "ls -l /sys/fs/pstore/console-ramoops* 2>/dev/null"

sect "chaves de boot (ro.boot)"
sh_ "getprop | grep '\\[ro.boot'"

if [ "$WITH_FASTBOOT" = "1" ]; then
  sect "fastboot (somente leitura)"
  if command -v fastboot >/dev/null 2>&1; then
    host_ "fastboot devices"
    host_ "fastboot getvar all"
  else
    echo "fastboot nao encontrado no PATH" >> "$OUT"
  fi
fi

sect "fim"
echo "coleta concluida: $OUT"
echo
echo "AVISO: este arquivo contem serial, IMEI e outros dados unicos do aparelho."
echo "Nao publique sem revisar e anonimizar."
