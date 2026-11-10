# 04 — Mapa de memória

Objetivo: saber, com precisão, **quais faixas de DRAM podemos usar** e quais são
propriedade de firmware/co-processadores. Um kernel que escreve em região
reservada falha de forma silenciosa e difícil de diagnosticar.

> Status: documento de método. Nenhum valor numérico ainda é confiável para o
> `lima_32` até ser obtido do DTB do próprio aparelho.

---

## 1. De onde vêm os dados (em ordem de confiança)

1. **DTB do aparelho** — nós `/memory` e `/reserved-memory`. Fonte primária.
2. **`/proc/iomem` e `/proc/meminfo`** no Android — visão do kernel Linux
   rodando; útil para conferência.
3. **Saída do BROM/preloader** (se disponível em modo leitura) — base real da
   DRAM, tamanho por canal.
4. **Especificações do SoC** — apenas para comparação, nunca como verdade.

Coleta:

```sh
adb shell 'cat /proc/iomem'
adb shell 'cat /proc/meminfo | head -5'
adb shell 'ls /sys/firmware/fdt 2>/dev/null || ls /proc/device-tree'
```

Extração do DTB (offline, a partir de `boot.img`/`dtbo` já obtido em leitura):

```sh
# separar dtb do boot.img (ferramentas tipo extract-ikconfig/mkbootimg/unpack_bootimg)
unpack_bootimg --boot_img boot.img --out out/
dtc -I dtb -O dts -o board.dts out/dtb
```

## 2. Template de tabela

Preencher com valores reais. `fonte` = nó do DTB ou linha do `iomem`.

| Região | Base | Tamanho | Uso | Fonte | Intocável? |
| ------ | ---- | ------- | --- | ----- | ---------- |
| DRAM (total) | — | — | memória física | — | n/a |
| Kernel/utilizável | — | — | nosso alvo | — | não |
| `reserve-memory-*` (SCP/SSPM) | — | — | co-processador | — | **sim** |
| `atf` / `tee` / `gz` | — | — | secure monitor / TrustZone | — | **sim** |
| `md1*` (modem) | — | — | modem | — | **sim** |
| framebuffer / `cont-splash` | — | — | splash do bootloader | — | depende |
| `minirdump` / `log_store` | — | — | logs do preloader/LK | — | **sim** (fonte de diagnóstico) |
| `ramoops` / `pstore` | — | — | log persistente entre resets | — | depende |
| `misc`/`dtbo` (se mapeadas no DTB) | — | — | — | — | sim |

## 3. Regiões que nunca devem ser tocadas

- Qualquer coisa com nome contendo `md1`, `modem`, `nvram`, `nvdata`,
  `persist`, `protect`, `seccfg`, `sec`, `tee`, `gz`, `atf`, `scp`, `sspm`,
  `dsp`, `minirdump`.
- Faixas marcadas `no-map` no DTB.
- Faixas marcadas `reusable` **não** são automaticamente nossas: "reusable" no
  Linux significa "reaproveitável pelo Linux depois que o dono liberar".

## 4. O que o XNU precisa saber

| Requisito | Por quê |
| --------- | ------- |
| Base e tamanho da DRAM física | construir o mapa de phys memory |
| Quais páginas são usáveis | `pmap` / bootstrap allocator |
| Alinhamento e granularidade | tamanho de página (4K? 16K?) |
| Lacunas de endereço | não mapear buracos como RAM |
| Atributos (normal vs. device) | MMU; região de registradores é `Device-nGnRnE` |

## 5. Pendências

- [ ] Extrair e decompilar o DTB do `lima_32`
- [ ] Listar todos os nós de `reserved-memory` com base/tamanho
- [ ] Descobrir a base física da DRAM (provável `0x40000000`, **confirmar**)
- [ ] Identificar a região reservada para o logo/splash — candidata a framebuffer
      inicial na Fase 2
- [ ] Verificar se existe `ramoops` utilizável como canal de log na Fase 1
