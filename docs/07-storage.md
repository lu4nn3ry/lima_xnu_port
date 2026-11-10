# 07 — Armazenamento

Armazenamento é a **última** coisa a ser tocada. É onde estão os dados
irreversíveis do aparelho.

---

## 1. O que descobrir

| Item | Como | Status |
| ---- | ---- | ------ |
| Tipo (eMMC vs. UFS) | `ls /sys/block`, `dmesg | grep -i -E 'mmc|ufs'` | pendente |
| Controlador | DTB (`mmc@...`, `sdhci@...`) | pendente |
| Versão (eMMC 5.1?) | `cat /sys/block/mmcblk0/device/...` | pendente |
| Tamanho | `cat /sys/block/mmcblk0/size` (setores de 512 B) | pendente |
| Tabela de partições | GPT (`sgpt`/`pgpt`), scatter file | pendente |
| Slots A/B | ver `02-boot-chain.md` | pendente |

## 2. Mapa de partições — template

Preencher a partir de leitura (nunca de um scatter de outro aparelho).

| Partição | Tamanho | Conteúdo | Intocável | Observação |
| -------- | ------- | -------- | --------- | ---------- |
| `preloader*` | — | preloader | **sim** | parte da cadeia confiável |
| `pgpt` / `sgpt` | — | tabelas GPT primária/secundária | **sim** | |
| `lk` / `bootloader` | — | LK | **sim** | |
| `boot` / `boot_a`/`boot_b` | — | kernel+ramdisk | cuidado | alvo eventual da Fase 3+ |
| `dtbo` | — | overlays de DTB | cuidado | |
| `vbmeta` | — | AVB | cuidado | |
| `misc` | — | flags de boot/slot | cuidado | |
| `md1img` / `md1dsp` | — | firmware de modem/DSP | **sim** | específico do aparelho |
| `nvram` / `nvdata` / `nvcfg` | — | dados de RF/IMEI | **sim** | perder = sem modem |
| `persist` | — | calibração, sensores, MAC | **sim** | perder = sem Wi-Fi/sensores |
| `protect1` / `protect2` / `seccfg` | — | chaves/estado de desbloqueio | **sim** | |
| `super` | — | system/vendor/product | não (mas grande) | |
| `userdata` | — | dados do usuário | não | apagar = perda de dados |

> Nomes e layout variam. Os nomes acima são típicos de MediaTek/Android 9–10 e
> **devem** ser substituídos pelos reais do `lima_32`.

## 3. Estratégia de leitura segura

1. Preferir leitura via `adb`/`fastboot` (sem BROM) quando possível.
2. Para partições que o Android não expõe, usar BROM/preloader **em modo
   leitura**, com a ferramenta travada em read-only.
3. Salvar em `dumps/` (ignorado pelo git) e calcular hash de cada arquivo.
4. Verificar o dump relendo uma amostra e comparando o hash.
5. Guardar **duas** cópias em mídias diferentes.

Detalhes e checklist em `09-safety-and-backups.md`.

## 4. O que o XNU vai precisar

- Driver de host eMMC/SDHCI: comandos básicos (CMD0/1/2/3/7/8/9/12/13/16/17/18/24/25).
- DMA: endereço físico, alinhamento, cache coherency (crítico em ARM64 sem IOMMU
  configurada).
- Interrupção do controlador no GIC (ver `05-interrupts-timers.md`).
- Formato de partição que o kernel vai entender (GPT é o mais direto).

## 5. Pendências

- [ ] Confirmar eMMC vs. UFS
- [ ] Obter GPT real e preencher a tabela
- [ ] Identificar partições que o Android monta como read-only e por quê (verity)
- [ ] Decidir: na Fase 4, o XNU lê `boot` cru ou uma partição dedicada?
