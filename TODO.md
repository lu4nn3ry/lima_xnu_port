# TODO

Legenda: `[ ]` pendente · `[~]` em andamento · `[x]` concluído · `[!]` bloqueado

---

## Fase 0 — Pesquisa (atual)

Objetivo: saber exatamente o que é o aparelho e como ele inicializa, **sem
alterar nada**.

### 0.1 Identidade do aparelho
- [x] Modelo: XT2015-2 (relato do usuário, 2026-11-10)
- [x] Firmware atual: Android 10 (relato do usuário, 2026-11-10)
- [x] Bootloader desbloqueado (relato do usuário, 2026-11-10)
- [ ] Confirmar strings do build (`ro.product.model`, `ro.product.device`, `ro.build.fingerprint`)
- [ ] Confirmar se o Android 10 veio por OTA oficial e se alterou bootloader/anti-rollback
- [ ] Confirmar SoC real (MT6771 vs MT6765 — ver `docs/01-device-identity.md`)
- [ ] Confirmar variante de RAM/armazenamento
- [ ] Confirmar resolução de tela real (720×1520 vs 720×1600)
- [ ] Registrar patch de segurança e slot ativo
- [ ] Confirmar `fastboot getvar unlocked` e `ro.boot.verifiedbootstate`

### 0.2 Cadeia de boot
- [ ] Mapear: BootROM → preloader → LK → boot.img → Android
- [ ] Verificar se o aparelho é A/B (slots) ou A-only
- [ ] Verificar presença e política de AVB/vbmeta (verity, verification)
- [ ] Documentar o que o bootloader aceita (`fastboot boot`? apenas imagens assinadas?)
- [ ] Documentar o modo de emergência/download (BROM/Preloader) — apenas leitura

### 0.3 Firmware e partições
- [ ] Obter tabela de partições (GPT) e tamanhos
- [ ] Identificar partições sensíveis e marcá-las como intocáveis
- [ ] Verificar backups existentes e hashes
- [ ] Registrar versão de firmware e anti-rollback, se houver

### 0.4 Kernel / DTB
- [ ] Extrair DTB do `boot.img` (ou do `dtbo`) e decompilar
- [ ] Inventariar `reserved-memory`, `memory`, `cpus`, `timer`, `interrupt-controller`
- [ ] Inventariar periféricos de interesse: display, eMMC, touch, USB, PMIC
- [ ] Salvar material bruto em `research/device-tree/`

### 0.5 Hardware
- [ ] Preencher `docs/03-hardware-inventory.md` com fonte para cada item
- [ ] Preencher `docs/04-memory-map.md`
- [ ] Preencher `docs/05-interrupts-timers.md`
- [ ] Verificar existência de UART acessível e/ou caminho de log (pstore/ramoops)

### 0.6 Saída da fase
- [ ] `docs/01` a `docs/09` revisados e sem "a verificar" nos itens críticos
- [ ] Decisão registrada: existe caminho viável para a Fase 1? qual?

---

## Fase 1 — Loader próprio

- [ ] Estudar Mu-Silicium / Project Mu e o modelo de port UEFI para ARM64 móvel
- [ ] Avaliar se o caminho UEFI é aplicável a MT6771 (ver `docs/10-compatibility.md`)
- [ ] Definir estratégia de carga sem gravação (`fastboot boot`, cadeia de boot própria)
- [ ] Fazer um "hello world" que produza saída observável (tela, UART, pstore)
- [ ] Implementar log persistente e recuperável após reset
- [ ] Validar em QEMU (`qemu-system-aarch64`) antes de qualquer teste no aparelho

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
