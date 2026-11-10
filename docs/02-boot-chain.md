# 02 — Cadeia de boot

Objetivo: entender exatamente o caminho do reset até o Android, para descobrir
**se** e **como** é possível inserir código próprio.

Tudo abaixo é o modelo genérico MediaTek. Cada afirmação precisa ser confirmada
para o `lima_32`; o que não for confirmado fica marcado como hipótese.

---

## 1. Modelo genérico (MediaTek)

```
Power-on / reset
   │
   ├─ BootROM (BROM)  — mascarada em hardware, imutável
   │     valida o preloader (assinatura / política de download mode)
   │
   ├─ Preloader       — init de DRAM, clock, PMIC; carrega o LK
   │
   ├─ LK ("little kernel")  — bootloader de fato; fastboot, seleção de slot,
   │                          verificação de boot.img
   │
   ├─ boot.img        — kernel + ramdisk (+ DTB, dependendo do esquema)
   │
   └─ Android
```

Detalhes que mudam por geração e por OEM e que **precisam** ser verificados:

- onde o **DTB** vive (`boot.img`? `dtbo`? partição dedicada?);
- se há **A/B** com `boot_a`/`boot_b` e retry counters em `misc`;
- se há **AVB** (vbmeta com hash tree) e qual modo (`enforcing` vs.
  `permissive`);
- se `dm-verity` está ativo no `system`/`vendor`;
- se o bootloader aceita **imagem não assinada** em `fastboot boot`.

## 2. O que precisamos saber antes da Fase 1

| Pergunta | Por que importa | Como descobrir |
| -------- | --------------- | -------------- |
| O bootloader está desbloqueado? | Sem isso, nenhuma imagem própria executa | `fastboot getvar unlocked`, `ro.boot.verifiedbootstate` |
| Existe slot A/B? | Muda partições, offsets e estratégia de recuperação | `fastboot getvar slot-count` |
| `fastboot boot` funciona com imagem própria? | Permite testar **sem gravar** nada | teste controlado, só depois de backup |
| AVB está ativo? | Imagem sem assinatura correta é rejeitada | `fastboot getvar avb*`, `vbmeta` dump (leitura) |
| Existe download mode (BROM/Preloader)? | Caminho de recuperação de último recurso | `mtkclient` em modo leitura; nunca escrever |
| Há anti-rollback? | Gravar firmware antigo pode brickar de vez | `fastboot getvar` (`anti-rollback`, `rollback-index`) |

## 3. Observações específicas de MediaTek

- O **preloader** é parte da cadeia confiável e é atualizado por OTA/OEM. Não é
  um alvo razoável para experimentos. Tratar como intocável.
- O **BROM** tem um modo de download usado por ferramentas de service. Alguns
  chips permitem contornar a checagem de assinatura em modo BROM (exploits
  públicos). Isso é útil para **backup** e para carregar código em RAM, mas é
  também o caminho mais fácil de brickar o aparelho.
- "Carregar em RAM" (sem gravar) é a propriedade mais valiosa para a Fase 1:
  se existir um caminho BROM → payload em DRAM → execução, os testes ficam
  reversíveis por um simples reset.

> **Regra deste projeto:** qualquer uso de BROM/preloader é **read-only** até a
> Fase 1 estar formalmente aberta e com backup verificado.

## 4. Estratégias candidatas para a Fase 1

**Estado conhecido:** bootloader desbloqueado (**verificado via `fastboot getvar securestate` → `flashing_unlocked`**).
Isso torna a opção 2 viável em princípio — mas "desbloqueado" não implica automaticamente "aceita imagem não assinada"; AVB e a política de verificação do LK ainda serão validados.

Ordenadas da menos para a mais invasiva:

1. **Payload em RAM via BROM** (se o chip permitir) — nada gravado; reset
   recupera. Melhor cenário.
2. **`fastboot boot <img>`** com imagem própria — nada gravado de forma
   permanente; falha = volta ao normal.
3. **Substituir `boot` em slot inativo (`boot_b`)** — reversível via `fastboot set_active a`, mas já é escrita.
4. **Substituir `boot` no slot ativo (`boot_a`)** — só com backup verificado e caminho de
   recuperação testado.

Nenhuma das opções 3 e 4 será considerada sem que `09-safety-and-backups.md`
esteja completo e os hashes conferidos.

## 5. Respostas obtidas e perguntas em aberto

- [x] **O Android deste aparelho é A/B?** Sim, verificado (`slot-count: 2`, `current-slot: a`, partições `_a` e `_b` em `/dev/block/by-name`).
- [x] **O `boot.img` carrega DTB embutido ou há `dtbo` separado?** Existem partições dedicadas: `boot_a/b`, `dtbo_a/b` e `dtb_a/b`.
- [x] **O bootloader está desbloqueado?** Sim, verificado (`flashing_unlocked`).
- [ ] O bootloader valida `boot` com AVB em modo enforcing?
- [ ] `fastboot boot` é aceito com imagem não assinada?
- [ ] Qual a versão de preloader/LK e se há histórico de compatibilidade?
- [ ] Existe porta UART acessível no PCB? (impacta diretamente a Fase 1)
