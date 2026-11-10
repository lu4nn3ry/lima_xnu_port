# Licenças

Este repositório mistura material de origens diferentes. Cada parte mantém a
licença da sua origem; nada aqui relicencia código de terceiros.

## Material próprio deste repositório

| Parte | Licença pretendida | Observação |
| ----- | ------------------ | ---------- |
| `docs/`, `devices/*/README.md`, `research/*/README.md`, `upstream/` | CC BY 4.0 | Documentação original do projeto. |
| `tools/` (scripts originais) | MIT | A confirmar/formalizar quando houver código relevante. |
| `patches/` (patches originais) | Licença do upstream alvo | Um patch sobre XNU não pode ser relicenciado de forma incompatível com a APSL. |

> Enquanto o projeto não tiver um arquivo `LICENSE` definitivo, trate o material
> próprio como "todos os direitos reservados" até a decisão ser registrada aqui.

## Código de terceiros (não incluído neste repositório)

| Projeto | Licença | Uso neste projeto |
| ------- | ------- | ----------------- |
| Apple XNU (`apple-oss-distributions/xnu`) | Apple Public Source License 2.0 | Base para estudo/patches. Patches derivados ficam sob APSL 2.0. |
| HakiOS XNU kernel (`oosexgang/hakios-xnu-kernel`) | Verificar no repositório antes de reutilizar | Referência e possível origem de patches. **Conferir a licença no commit usado.** |
| Mu-Silicium / Project Mu | Verificar (BSD/MIT no ecossistema Mu) | Referência de infraestrutura UEFI. Não copiar sem checar `LICENSE` e avisos. |
| EDK2 / Project Mu | BSD-2-Clause-Patent (predominante) | Idem. |
| Linux / kernel MediaTek | GPL-2.0 | Apenas leitura para entender o hardware. **Não** pode ser copiado para dentro de XNU. |
| mtkclient | Verificar (GPL-3.0) | Ferramenta externa. Usada como executável, não embutida. |

## O que nunca será distribuído aqui

- Imagens de firmware da Motorola/MediaTek (`boot.img`, `preloader`, `lk`,
  `md1img`, `nvram`, `persist`, `super`, etc.).
- Blobs proprietários, assinaturas, chaves ou certificados.
- Dumps que possam conter IMEI, calibração de RF ou dados pessoais.
- Qualquer componente do iOS.

Backups existem apenas localmente, fora do controle de versão
(`.gitignore` já cobre `dumps/`, `backups/` e `firmware/`).

## Aviso legal

Este é um projeto de pesquisa de engenharia reversa e portabilidade. Executar
código não assinado, desbloquear bootloader ou modificar o aparelho pode anular
a garantia, impedir atualizações, inutilizar o dispositivo ou violar termos de
uso. A responsabilidade é de quem executa.
