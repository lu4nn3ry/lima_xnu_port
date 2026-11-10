# 06 — Display e logging

## Por que estes dois juntos

No bring-up, **log vale mais que imagem**. Um kernel que desenha um logo e não
imprime nada é inútil para depuração; um kernel que imprime "cheguei na linha X"
via UART ou pstore é ouro. Display é o *primeiro periférico de saída para o
usuário*, mas **não** o primeiro canal de diagnóstico.

Ordem correta:

1. Um canal de log que sobreviva a um reset (pstore/ramoops, UART, ou memória
   reservada lida por um segundo estágio).
2. Só depois, framebuffer.

## 1. Canais de log candidatos

| Canal | Prós | Contras | Status |
| ----- | ---- | ------- | ------ |
| UART física | Síncrono, funciona antes de tudo | Exige acesso ao PCB/pontos de teste | a verificar |
| `pstore` / `ramoops` | Persiste após reset; já existe no Android | Precisa saber a região física e o formato | a verificar |
| `log_store` / `minirdump` (MTK) | Logs de preloader/LK | Formato proprietário; só leitura | a verificar |
| Tela (framebuffer pré-existente) | Visível sem hardware extra | Precisa de um framebuffer já configurado pelo LK | a verificar |
| USB (fastboot/serial) | Sem desmontar | Só em modos específicos | a verificar |
| LED / vibração | Simples | Baixíssima largura de banda | a verificar |

Regra prática: **descobrir o canal de log antes de escrever qualquer driver.**
Se não houver canal nenhum, a Fase 1 precisa resolver isso primeiro.

## 2. Display

### O que descobrir

- Controlador DSI (MediaTek `mtk_drm`/`mtk_dsi` no Linux) e sua base.
- Painel: modelo, timing (`porch`, `clock`), número de lanes.
- Backlight: via PMIC (`mt6358`?) ou controlador dedicado (`lm3697`?).
- Se o LK já deixa um framebuffer configurado com splash screen — se sim, é a
  forma mais barata de "imprimir" algo na Fase 1.

### Estratégia mínima (Fase 2)

1. Reutilizar o framebuffer deixado pelo bootloader, **sem reprogramar o DSI**.
2. Escrever pixels em modo texto simples (fonte 8×8 desenhada à mão).
3. Só depois tentar inicializar o DSI do zero.

Reprogramar o DSI sem saber os timings do painel pode deixar a tela preta de
forma permanente até o próximo boot — o que é aceitável, mas cega o diagnóstico.
Por isso o passo 1 vem antes.

### Pendências

- [ ] Resolução nativa real (1520 vs. 1600 — ver `01-device-identity.md`)
- [ ] Endereço e formato do framebuffer do bootloader
- [ ] Modelo do painel e timings (DTB)
- [ ] Controlador de backlight e GPIO de enable

## 3. Logging do nosso código

Requisitos:

- [ ] Saída **síncrona** (sem fila, sem IRQ) para funcionar em qualquer ponto.
- [ ] Buffer circular em memória reservada + despejo no próximo boot.
- [ ] Timestamp desde o reset (via `CNTPCT_EL0`), não wall clock.
- [ ] Níveis: `panic`, `error`, `warn`, `info`, `trace`.
- [ ] Prefixo de fase (`[f1]`, `[f2]`) para separar origem.

Formato sugerido:

```
[f1 0000.012345] loader: dram ok, base=0x........ size=...
[f1 0000.012401] loader: gic v? base=0x........
[f1 0000.012445] loader: console=fb0 720x???? stride=????
```

## 4. Pendências

- [ ] Escolher o canal primário de log da Fase 1 (decisão bloqueante)
- [ ] Documentar como recuperar o log após um reset
- [ ] Testar o canal com um "hello" antes de qualquer outra coisa
