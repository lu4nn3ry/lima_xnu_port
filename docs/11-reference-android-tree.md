# 11 — `android_device_motorola_lima` (projeto irmão)

Repositório: `../android_device_motorola_lima`
(`https://github.com/lu4nn3ry/android_device_motorola_lima`)

Projeto **irmão**, não parte deste. Ele monta uma device tree Android/LineageOS
para a família Lima. Este documento registra o que dele se aproveita, o que não
se aproveita, e o que ainda precisa de validação.

> Regra: esse repositório é **referência**, nunca fonte de verdade. Ele mesmo se
> declara incompleto ("sem build verificado", "placeholders").

---

## 1. O que ele resolveu

| Pergunta | Resposta que ele dá | Confiança |
| -------- | ------------------- | --------- |
| O que é `lima` vs `lima_32`? | `lima` = Motorola One Macro; `lima_32` = Moto G8 Play | estrutura do repo |
| SoC da família | MT6771 (Helio P70) | consistente com o bootloader |
| Sistemas de arquivos | ext4 + f2fs | consistente com as montagens reais |
| Candidatos de kernel Linux | Jebaitedneko `pie-9.0.0-release-pmd29`; electimon branch `12` | lista, não validado |
| Trees TWRP de referência | mototek, ayham-1, realaltffour | lista, não validado |
| Device tree gerado | `twrpdtgen/android_device_motorola_lima` (Apache-2.0) | lista, não validado |

## 2. Onde ele **não** serve como verdade

| Ponto | Problema |
| ----- | -------- |
| `BoardConfigCommon.mk` declara `TARGET_ARCH := arm64` + `TARGET_2ND_ARCH := arm` | Isso é uma **escolha de build futuro**, não um fato do aparelho. O ROM de fábrica é 32-bit only (`abilist64` vazio). |
| Partições, `BOARD_KERNEL_CMDLINE`, `BOARD_BOOTIMG_HEADER_VERSION` | Comentados/ausentes — ainda placeholders. |
| Fingerprint/build | Placeholder explícito no README. |
| "Sem build verificado" | Declarado no próprio README/TODO. |

Conclusão: nada de hardware dele entra em `docs/` sem verificação independente.
O que já verificamos aqui (partições, display, SoC, fstab real) tem precedência.

## 3. O que realmente vale a pena puxar de lá

Não é o Makefile — são as **pistas de pesquisa**:

1. **Kernel Linux da família Lima** (GPLv2): é a documentação viva do hardware —
   DTS, drivers de display/touch/PMIC, defconfig real do `lima_32`.
   - https://github.com/Jebaitedneko/android_kernel_motorola_lima (`pie-9.0.0-release-pmd29`)
   - https://github.com/electimon/android_kernel_motorola_lima (branch `12`)
2. **Trees TWRP** (fstab, partições, boot/recovery):
   - `mototek/recovery_motorola_lima` (`lineage-18.1`)
   - `ayham-1/android_device_motorola_lima_twrp`
   - `realaltffour/android_device_motorola_lima_twrp`
3. **Tree gerada por twrpdtgen**: contém `extract-files.sh`, `setup-makefiles.sh`
   e fstab — útil como amostra do que o firmware expõe.

## 4. Por que o kernel Linux importa para um port de XNU

| O que olhar no kernel Linux | Por que |
| --------------------------- | ------- |
| `arch/arm64/boot/dts/mediatek/*lima*` | DTB real: memória, IRQs, clocks, painel, touch |
| `drivers/gpu/drm/mediatek/` | sequência de init do DSI e timings do painel |
| `drivers/mmc/host/mtk-sd.c` | controlador eMMC, modos, DMA |
| `drivers/input/touchscreen/` | modelo e barramento do touch |
| `arch/arm64/configs/*lima*_defconfig` | quais drivers o hardware realmente usa |

**Licença:** kernel Linux é GPLv2. Nada de código é copiado para `patches/xnu/`
(APSL). Só comportamento, endereços e sequências são reimplementados — o que é
permitido e é a prática normal de ports.

## 5. Divergências a resolver

- [ ] O `BoardConfigCommon.mk` assume `arm64` como ABI primária. O stock é
      32-bit. Para um port XNU isso é irrelevante (kernel é arm64), mas registre
      que o userspace atual **não** é arm64.
- [ ] `lima` e `lima_32` compartilham `TARGET_BOOTLOADER_BOARD_NAME := lima`.
      Confirmar se o One Macro usa a mesma placa base.
- [ ] Nenhum valor de partição do repo irmão foi validado; usar o mapa real em
      `07-storage.md`.

## 6. Próxima ação concreta

1. Clonar (fora deste repo) o kernel `Jebaitedneko` no commit fixo.
2. Extrair o DTS do `lima_32` e responder: GIC (v2/v3), timer, mapa de memória,
   painel, touch.
3. Registrar os achados em `research/kernel/` e `research/device-tree/`,
   citando commit exato.
