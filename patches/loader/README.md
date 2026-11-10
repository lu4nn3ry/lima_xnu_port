# `patches/loader/`

Patches e código do loader próprio (Fase 1).

## Decisão pendente

O loader pode ser:

- **minimalista** (`-ffreestanding`, sem dependências): mais simples de auditar,
  menor superfície de erro;
- **baseado em UEFI / Mu-Silicium**: reuso de infraestrutura, mas com camada de
  plataforma a escrever do zero para MediaTek.

A escolha depende de `docs/10-compatibility.md` e do caminho de carga que a
Fase 0 descobrir.

## Convenções

- Um commit por funcionalidade observável.
- Cada funcionalidade precisa de um teste em QEMU antes do aparelho.
- Saída de debug é requisito, não luxo: nenhuma funcionalidade entra sem log.
- Código deve ser compilável com toolchain documentada (versão exata no README).

## Estrutura prevista

```
loader/
├── boot/        entry point, stack, early init
├── platform/    inicialização do SoC (clock, DRAM já pronta)
├── console/     UART / framebuffer / buffer em memória
├── dt/          leitura do DTB
└── tests/       runner em QEMU
```
