# 07 — Armazenamento

Armazenamento é a **última** coisa a ser tocada. É onde estão os dados
irreversíveis do aparelho.

---

## 1. O que descobrir

| Item | Como | Status | Fonte |
| ---- | ---- | ------ | ----- |
| Tipo (eMMC vs. UFS) | `ls /sys/block`, `dmesg \| grep -i -E 'mmc\|ufs'` | **verificado** | eMMC 5.1 (`mmcblk0`) em `dumps/dmesg-stock.txt` |
| Controlador | DTB (`mmc@...`, `sdhci@...`) | **verificado** | MediaTek MSDC em `msdc@11230000` (eMMC) e `msdc@11240000` (SD) |
| Versão / Modelo | `cat /sys/block/mmcblk0/device/...` | **verificado** | 32GB SAMSUNG 4X6KMB (`fastboot getvar emmc`) |
| Tamanho | `cat /sys/block/mmcblk0/size` (setores de 512 B) | **verificado** | 34.359.738.368 bytes (32 GiB / 67.108.864 setores) |
| Tabela de partições | GPT (`sgpt`/`pgpt`), scatter file | **verificado** | GPT com 64 partições mapeadas em `research/partitions-by-name.txt` |
| Slots A/B | ver `02-boot-chain.md` | **verificado** | A/B Dual-Slot (`slot-count: 2`, `current-slot: a`) |

## 2. Mapa real verificado (2026-11-10)

Fonte: `adb shell ls -l /dev/block/by-name` (leitura, sem root). O conteúdo das
partições **não** é legível sem root/BROM, e os tamanhos via sysfs estão
bloqueados por SELinux — a tabela por nome/nó é o que temos hoje.

```
p1  boot_para   p2  para        p3  expdb       p4  frp
p5  cid         p6  logs        p7  utags       p8  utagsBackup
p9  carrier     p10 pad1        p11 nvcfg       p12 nvdata
p13 metadata    p14 protect1    p15 protect2    p16 seccfg
p17 persist     p18 prodpersist p19 sec1        p20 proinfo
p21 nvram       p22 efuse       p23 pad2        p24 hw
p25 sp          p26 kpan        p27 vbmeta_a    p28 md1img_a
p29 spmfw_a     p30 scp_a       p31 sspm_a      p32 cam_vpu1_a
p33 cam_vpu2_a  p34 cam_vpu3_a  p35 logo_a      p36 lk_a
p37 boot_a      p38 dtb_a       p39 dtbo_a      p40 tee_a
p41 oem_a       p42 (não exposta)               p43 system_a
p44 vbmeta_b    p45 md1img_b    p46 spmfw_b     p47 scp_b
p48 sspm_b      p49 cam_vpu1_b  p50 cam_vpu2_b  p51 cam_vpu3_b
p52 logo_b      p53 lk_b        p54 boot_b      p55 dtb_b
p56 dtbo_b      p57 tee_b       p58 oem_b       p59 (não exposta)
p60 system_b    p61 userdata    p62 otp         p63 flashinfo
```

Observações relevantes:

- **Não existe partição `preloader` nem `recovery`** no `by-name`. O preloader
  do MT6771 vive fora da GPT (área dedicada do eMMC), e não há recovery
  separado (A/B + `boot` fazem esse papel).
- **A/B completo**: `boot`, `dtb`, `dtbo`, `lk`, `logo`, `md1img`, `scp`,
  `sspm`, `spmfw`, `cam_vpu*`, `tee`, `oem`, `vbmeta`, `system` têm `_a`/`_b`.
- `dtb_a`/`dtb_b` existem → há DTB **separado** do `boot.img` neste aparelho.
- `p42` e `p59` não aparecem em `by-name` (provável espaço de tabela/lacuna).
- Montagens verificadas:

```
/dev/block/dm-0  → /system   ext4 ro   (2,5 GB)
/dev/block/dm-1  → /vendor   ext4 ro   (384 MB)
/dev/block/dm-2  → /oem      ext4 ro   (273 MB)
/dev/block/mmcblk0p61 → /data  f2fs rw  (22 GB)
/dev/block/mmcblk0p18 → /mnt/product/persist (3,7 MB)
```

- `dm-0/1/2` são **dm-verity**, mapeados em `/dev/block/mapper` como
  `system-verity`, `vendor-verity`, `oem-verity`. Ou seja: `/system`, `/vendor`
  e `/oem` são verificados por hash em tempo de execução.
- `userdata` é **f2fs** (não ext4) — importante para qualquer tentativa futura de
  leitura.

## 2.1 Template (substituído pelo mapa acima)


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
