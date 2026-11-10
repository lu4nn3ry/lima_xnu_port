# 08 — Entrada

## 1. Botões

Mais importantes do que parecem no bring-up: são o canal de controle mais
simples que existe (sem driver complexo, sem IRQ sofisticada).

Botoes físicos do aparelho (a confirmar): power, volume up, volume down.

| Botão | GPIO | PMIC/Keypad | Status |
| ----- | ---- | ----------- | ------ |
| Power | — | — | pendente |
| Volume + | — | — | pendente |
| Volume − | — | — | pendente |

Coleta: DTB (`gpio-keys` / `mtk-kpd`), `dmesg | grep -i key`.

## 2. Touchscreen

| Item | Valor | Status |
| ---- | ----- | ------ |
| Fabricante/controller | — | pendente |
| Modelo | — | pendente |
| Barramento (I2C/SPI) | — | pendente |
| Endereço do escravo | — | pendente |
| GPIO de reset | — | pendente |
| GPIO de IRQ | — | pendente |
| Resolução de eixos | — | pendente |
| Protocolo | — | pendente |

Coleta:

```sh
adb shell 'cat /proc/bus/input/devices'
adb shell 'ls /sys/class/input'
adb shell 'cat /sys/class/input/input*/name'
adb shell 'getevent -pl'          # lista capabilities e eixos
adb shell 'dmesg | grep -i -E "touch|focaltech|novatek|goodix|synaptics|himax"'
```

## 3. Ordem de implementação

1. Botões via PMIC/keypad (sem IRQ, polling) — valida leitura de registrador.
2. Touch em polling (sem IRQ) — valida I2C e o controlador.
3. Touch com IRQ — valida GIC + GPIO interrupt.
4. Só então um stack de eventos de entrada.

## 4. Pendências

- [ ] Identificar o controlador de touch
- [ ] Obter endereço I2C/SPI e GPIOs do DTB
- [ ] Verificar se o controlador precisa de firmware carregado (alguns precisam)
- [ ] Mapear o keypad/PMIC usado pelos botões
