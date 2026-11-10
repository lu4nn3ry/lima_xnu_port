# TODO

Legenda: `[ ]` pendente · `[~]` em andamento · `[x]` concluído · `[!]` bloqueado

---

## Fase 0 — Pesquisa (atual)

Objetivo: saber exatamente o que é o aparelho e como ele inicializa, **sem
alterar nada**.

### 0.1 Identidade do aparelho
- [x] Modelo: XT2015-2 (confirmado: `fastboot getvar sku` → XT2015-2)
- [x] Firmware atual: Android 10 (confirmado: build `QMDS30.47-33-5`)
- [x] Bootloader desbloqueado (confirmado: `securestate: flashing_unlocked` via Unique Key oficial)
- [x] Confirmar strings do build (`motorola/lima_32/lima:10/QMDS30.47-33-5/7e278:user/release-keys`)
- [x] Confirmar se o Android 10 veio por OTA oficial (canal `retbr`, release-keys, bootloader `MBM-2.1-lima_32_retail`)
- [x] Confirmar SoC real (MT6771V/WL confirmado via `fastboot getvar cpu` - Helio P70M)
- [x] Confirmar variante de RAM/armazenamento (2GB Samsung LP4x + 32GB Samsung eMMC)
- [x] Confirmar resolução de tela real (confirmado: 720×1520 @ 280 dpi via `adb shell wm size`)
- [x] Registrar patch de segurança e slot ativo (Slot `_a` ativo de 2 slots)
- [x] Confirmar `fastboot getvar unlocked` (`securestate: flashing_unlocked`)

### 0.2 Cadeia de boot
- [x] Mapear: BootROM → preloader → LK → boot.img → Android (documentado em `docs/02-boot-chain.md`)
- [x] Verificar se o aparelho é A/B (slots) ou A-only (A/B verificado: `slot-count: 2`)
- [x] Verificar presença e política de AVB/vbmeta (verity, verification)
- [x] Documentar o que o bootloader aceita (confirmado: `fastboot boot` não é implementado pelo LK da MTK; estratégia definida para isolamento via Slot B)
- [x] Documentar o modo de emergência/download (BROM/Preloader) — apenas leitura

### 0.3 Firmware e partições
- [x] Obter tabela de partições (GPT) e mapeamento (confirmado: `research/partitions-by-name.txt`)
- [x] Identificar partições sensíveis e marcá-las como intocáveis (`boot_a`, `protect1/2`, `nvram`, `nvdata`, `proinfo`)
- [x] Verificar backups existentes e hashes (confirmado: 64 partições transferidas para `dumps/` com SHA-256 verificado)
- [x] Registrar versão de firmware e anti-rollback, se houver

### 0.4 Kernel / DTB
- [x] Extrair DTB do `boot.img` (ou do `dtbo`) e decompilar (confirmado: `dumps/boot_extracted/kernel.dts`)
- [x] Inventariar `reserved-memory`, `memory`, `cpus`, `timer`, `interrupt-controller`
- [x] Inventariar periféricos de interesse: display, eMMC, touch, USB, PMIC
- [x] Salvar material bruto em `research/` (`iomem-stock.txt`, `cmdline-stock.txt`, `dmesg-stock.txt`)

### 0.5 Hardware
- [x] Preencher `docs/03-hardware-inventory.md` com fonte para cada item
- [x] Preencher `docs/04-memory-map.md` (concluído com faixas de DRAM utilizáveis e reservadas)
- [x] Preencher `docs/05-interrupts-timers.md`
- [x] Verificar existência de UART acessível e/ou caminho de log (confirmado: UART `ttyS0` @ 921600 e `pstore/ramoops` com console persistente em `0x54410000`)

### 0.6 Saída da fase
- [x] `docs/01` a `docs/09` revisados e sem "a verificar" nos itens críticos
- [x] Decisão registrada: existe caminho viável para a Fase 1? qual? (Isolamento via Slot B com Stage 1 bare-metal ARMv7-A)

---

## Fase 1 — Loader próprio

- [x] Definir estratégia de carga segura (Isolamento via Slot B - `boot_b`)
- [x] Fazer um "hello world" que produza saída observável (Stage 1 compilado em ARMv7-A com saída em UART0 `0x11002000`, Ramoops `0x54410000` e FB `0x7d4f0000`)
- [x] Implementar log persistente e recuperável após reset (`0x54410000` ramoops)
- [~] Testar execução no hardware real via Slot B (`tools/test-stage1-slotb.ps1`)

## Fase 2 — Hardware

- [ ] Mapa de RAM utilizável vs. reservada
- [ ] GIC: versão, base, linhas, afinidade
- [ ] Timer: arquitetural vs. timer do SoC
- [ ] CPU: MPIDR, clusters, PSCI/estados de energia
- [ ] Framebuffer: configurar e desenhar algo sem driver completo
- [ ] MMU: mapeamento inicial, atributos de memória

## Fase 3 — XNU mínimo

- [ ] Estrutura de build ARM64 do XNU fora do ecossistema Apple
- [ ] Boot args, machine-dependent code (`pexpert/arm64`)
- [ ] Console de debug e `kprintf` funcionando
- [ ] Primeiro "kernel roda e imprime" reproduzível

## Fase 4 — Drivers

- [ ] Display
- [ ] Armazenamento (eMMC)
- [ ] Touch
- [ ] USB
- [ ] Demais periféricos, um por vez, cada um com doc própria

## Fase 5 — Darwin userspace

- [ ] Definir o que é viável (launchd? userland próprio? apenas libSystem?)
- [ ] Documentar limites legais e técnicos

---

## Dívidas técnicas / decisões pendentes

- [ ] Definir licença definitiva do código próprio (`LICENSES.md`)
- [ ] Definir política de commits (um commit por fato verificado?)
- [ ] Decidir se `research/` aceita binários grandes via Git LFS ou fica fora do repo
