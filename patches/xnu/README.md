# `patches/xnu/`

Patches contra o XNU oficial (`apple-oss-distributions/xnu`).

## Convenções

- Um patch = uma mudança conceitual, com mensagem explicando **por quê**.
- Nome: `NNNN-<subsistema>-<resumo>.patch` (ex.: `0001-pexpert-arm64-add-mtk-console.patch`).
- Cabeçalho obrigatório no patch:

```
# base: apple-oss-distributions/xnu @ <tag ou commit>
# alvo: lima_32 / Fase <n>
# licença: APSL-2.0 (derivado do upstream)
# estado: experimental | testado-em-qemu | testado-no-aparelho
```

- Nada de "patch monolítico" que junta console + MMU + timer. Bring-up precisa
  de bissecção.

## Organização prevista

| Área | Conteúdo |
| ---- | -------- |
| `pexpert/arm64` | console, timer, boot args, plataforma |
| `osfmk/arm64` | boot, pmap, exceções |
| `bsd/dev/arm` | drivers novos |
| `SETUP` / build | adaptações de build fora do ecossistema Apple |

## Pré-requisito

Nada aqui começa antes de a Fase 2 estar concluída: um loader próprio capaz de
imprimir o mapa de hardware.
