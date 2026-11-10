# `research/device-tree/`

Material bruto relacionado ao DTB (device tree) do `lima_32`.

## Como obter

```sh
# a partir de um boot.img já obtido em leitura
unpack_bootimg --boot_img boot.img --out out/
dtc -I dtb -O dts -o board.dts out/dtb

# dtbo separado (se existir)
dtc -I dtb -O dts -o dtbo.dts dtbo.img
```

Nunca editar o DTB original. Trabalhar sempre sobre cópias.

## O que extrair primeiro

- `/memory` — base e tamanho da DRAM
- `/reserved-memory` — regiões de co-processadores (intocáveis)
- `/cpus` — nós de CPU, `reg` = MPIDR, `compatible`
- `/interrupt-controller@*` — versão e bases do GIC
- `/timer` — timer do SoC
- `/soc/mmc@*`, `/soc/ufs@*` — armazenamento
- `/soc/dsi@*`, `/soc/disp@*` — display
- `/soc/i2c@*` + filhos — touch, PMIC
- `/chosen` — `bootargs`, `stdout-path` (pistas sobre console)

## Arquivos esperados

| Arquivo | Conteúdo |
| ------- | -------- |
| `board.dts` | DTS decompilado do `boot` |
| `dtbo.dts` | overlays, se houver |
| `reserved-memory.txt` | extração legível das regiões reservadas |
| `README-notes.md` | observações da extração |

## Regra

Arquivos pequenos e textuais podem ser versionados. `.dtb`/`.img` não
(`.gitignore` já os exclui). Guardar os binários localmente e citar o hash.
