# `patches/drivers/`

Drivers próprios, um por periférico.

## Regra de ouro

**Um driver por vez, com log e teste isolado.** Nunca dois periféricos novos no
mesmo ciclo de teste — se falhar, não se sabe qual foi.

## Ordem

| # | Driver | Pré-requisito | Estado |
| - | ------ | ------------- | ------ |
| 1 | Console (UART ou buffer) | Fase 1 | pendente |
| 2 | Timer + GIC | Fase 2 | pendente |
| 3 | Framebuffer (reuso do bootloader) | Fase 2 | pendente |
| 4 | eMMC (leitura) | Fase 2 | pendente |
| 5 | Touch (polling) | Fase 2 | pendente |
| 6 | USB | Fase 3+ | pendente |

## Documentação por driver

Cada driver deve ter `docs/drivers/<nome>.md` contendo:

- endereço(s) de registrador e IRQ, com fonte;
- sequência de inicialização (passo a passo);
- como testar sem o resto do sistema;
- o que ainda não funciona;
- riscos (ex.: reprogramar DSI sem timings corretos).

## Licença

Código novo deste projeto: ver `LICENSES.md`. Nenhum código GPL do kernel Linux
é copiado para dentro de XNU; apenas comportamento/registradores são observados
e reimplementados.
