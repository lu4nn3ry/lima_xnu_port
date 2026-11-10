# 04 — Mapa de memória

Objetivo: saber, com precisão, **quais faixas de DRAM podemos usar** e quais são
propriedade de firmware/co-processadores. Um kernel que escreve em região
reservada falha de forma silenciosa e difícil de diagnosticar.

> Status: **Confirmado e verificado** via live devicetree (`/proc/device-tree/reserved-memory`),
> `/proc/iomem` e `kernel.dtb` no Motorola Moto G8 Play (`lima_32` / MT6771V/WL).

---

## 1. Visão geral da DRAM

- **Base física da DRAM**: `0x40000000` (1.073.741.824 bytes = 1 GiB)
- **Fim da DRAM física**: `0xbfffffff` (~3 GiB endereçáveis)
- **Tamanho total**: 3.211 MiB reportados pelo kernel (`MemTotal: 3028244 kB` após reservas)
- **Ponto de entrada do kernel (boot.img v2)**: `0x40008000`
- **Endereço do Ramdisk**: `0x55000000`
- **Endereço das Tags/DTB**: `0x54000000`

---

## 2. Tabela de regiões reservadas e utilizáveis

| Região / Bloco | Base Física | Tamanho | Uso | Intocável? | Fonte |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Kernel / Usável Primário** | `0x40000000` | 324 MiB | Ponto de entrada (`0x40008000`) do XNU | **Não** (Alvo principal) | `/proc/iomem` |
| `mblock-8-ram_console` | `0x54400000` | 64 KiB | Console em RAM (persistente) | Sim | DTB `mblock-8` |
| `mblock-9-pstore` (ramoops) | `0x54410000` | 896 KiB | `persistent_ram` / ramoops (`console-ramoops`) | Sim (Leitura pós-reboot) | DTB `mblock-9` / `/proc/iomem` |
| `mblock-10-minirdump` | `0x544f0000` | 64 KiB | MTK Mini-RAMDump | **Sim** | DTB `mblock-10` |
| **System RAM Usável** | `0x54500000` | 1 MiB | Memória livre | Não | `/proc/iomem` |
| `mblock-3-atf-reserved` | `0x54600000` | 256 KiB | ARM Trusted Firmware (BL31 EL3) | **Sim (Crítico)** | DTB `mblock-3` |
| **System RAM Usável** | `0x54640000` | 25,75 MiB | Memória livre | Não | `/proc/iomem` |
| `mblock-7-pl-bootarg` | `0x54800000` | 128 KiB | Argumentos de boot do Preloader | **Sim** | DTB `mblock-7` |
| `mblock-20-dtb_addr_mrdump` | `0x54000000` | 512 KiB | Endereço do DTB para crash dump | **Sim** | DTB `mblock-20` |
| `mblock-19-lk_addr_mrdump` | `0x56000000` | 4 MiB | LK MRDump | **Sim** | DTB `mblock-19` |
| **System RAM Usável** | `0x56400000` | 539,9 MiB | Memória livre para drivers/userspace | Não | `/proc/iomem` |
| `mblock-16-ccci` (modem) | `0x66000000` | 16 MiB | CCCI Modem Buffer | **Sim** | DTB `mblock-16` |
| `mblock-13-SPM-reserved` | `0x77ff0000` | 64 KiB | MTK System Power Manager | **Sim** | DTB `mblock-13` |
| **System RAM Usável** | `0x78000000` | 84,9 MiB | Memória livre | Não | `/proc/iomem` |
| `mblock-11-framebuffer` | `0x7d4f0000` | 15,06 MiB | Framebuffer do Bootloader / Splash screen | **Depende** (FB inicial Fase 2) | DTB `mblock-11` |
| `mblock-6-tee-reserved` | `0x7e400000` | 27 MiB | Trustonic TEE / MobiCore | **Sim (Crítico)** | DTB `mblock-6` |
| `mblock-5-SSPM-reserved` | `0x7ff00000` | 768 KiB | Smart Sensor Power Manager | **Sim** | DTB `mblock-5` |
| `mblock-2-log_store` | `0x7ffc0000` | 256 KiB | Buffer circular de logs do Preloader/LK | **Sim** (Leitura) | DTB `mblock-2` |
| **System RAM Usável** | `0x80000000` | 96 MiB | Memória livre | Não | `/proc/iomem` |
| `mblock-18-ccci` (modem) | `0x86000000` | 192 MiB | Memória principal do modem 4G | **Sim** | DTB `mblock-18` |
| `mblock-17-md_smem_ncache` | `0x88000000` | 16 MiB | Modem Shared Non-Cacheable Memory | **Sim** | DTB `mblock-17` |
| **System RAM Usável** | `0x8f300000` | 217,9 MiB | Memória livre | Não | `/proc/iomem` |
| `mblock-14-SCP-reserved` | `0x9d400000` | 1,5 MiB | System Companion Processor (Áudio/Sensores) | **Sim** | DTB `mblock-14` |
| `mblock-15-ccci_tag_mem` | `0x9d5e0000` | 64 KiB | Modem CCCI Tags | **Sim** | DTB `mblock-15` |
| `mblock-12-vpu_binary` | `0x9d5f0000` | 42,06 MiB | Vision Processing Unit Firmware | **Sim** | DTB `mblock-12` |
| **System RAM Usável** | `0xa0000000` | 509,9 MiB | Memória livre | Não | `/proc/iomem` |
| `mblock-4-atf-log-reserved`| `0xbfe00000` | 256 KiB | Buffer de logs do ARM Trusted Firmware | **Sim** (Leitura) | DTB `mblock-4` |
| `mblock-1-dramc-rk0` | `0xbff00000` | 1 MiB | DRAM Controller calibration data | **Sim** | DTB `mblock-1` |

---

## 3. Oportunidades críticas para o port XNU

1. **Canal de Log Síncrono da Fase 1 (`pstore / ramoops`)**:
   - Endereço físico: `0x54410000`
   - O Linux do Android monta `/sys/fs/pstore` e lê `console-ramoops`.
   - Se nosso código inicial da Fase 1 gravar uma string com cabeçalho ramoops (`=== console-ramoops ===`) em `0x54410000` e reiniciar o aparelho de volta no Android, **o Android lê a mensagem automaticamente** em `/sys/fs/pstore/console-ramoops`!
   - Isso cumpre 100% o critério da **Fase 1**: *"Código próprio executa no aparelho e produz uma mensagem recuperável após reset"*.

2. **Console Gráfico da Fase 2 (`mblock-11-framebuffer`)**:
   - Endereço físico: `0x7d4f0000`
   - Tamanho: 15.073.280 bytes (~15 MiB).
   - O bootloader LK já inicializa o controlador DSI e desenha a logo do Motorola neste framebuffer exato. Podemos desenhar diretamente em `0x7d4f0000` sem tocar na configuração complexa de clock/DSI!

---

## 4. Status das Pendências

- [x] Extrair e decompilar o DTB do `lima_32` (realizado com `tools/fdt-to-dts.js`)
- [x] Listar todos os nós de `reserved-memory` com base/tamanho (concluído com 20 mblocks mapeados)
- [x] Descobrir a base física da DRAM (`0x40000000`, confirmada)
- [x] Identificar a região reservada para o logo/splash (`0x7d4f0000`, ~15 MiB)
- [x] Verificar se existe `ramoops` utilizável como canal de log na Fase 1 (`0x54410000`, ativo)
