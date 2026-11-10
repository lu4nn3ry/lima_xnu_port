# Upstream

Repositórios e projetos acompanhados. **Acompanhar não é copiar.**

| Projeto | URL | Licença (verificar) | Papel neste projeto |
| ------- | --- | ------------------- | ------------------- |
| Apple XNU | https://github.com/apple-oss-distributions/xnu | APSL 2.0 | Base oficial do kernel Darwin. Fonte dos patches em `patches/xnu/`. |
| HakiOS XNU kernel | https://github.com/oosexgang/hakios-xnu-kernel | verificar no repo | Referência de estrutura, loader, drivers e ferramentas de port. |
| HakiOS — experiência MT6768 | (dentro do projeto HakiOS) | verificar | Referência **metodológica** para MediaTek. Não é compatível com MT6771. |
| Mu-Silicium | https://github.com/DragonOS-Community/Mu-Silicium | verificar (ecossistema Mu) | Infraestrutura UEFI para ARM64 móvel (foco Qualcomm). |
| Project Mu | https://microsoft.github.io/mu/ | BSD-2-Clause-Patent (predominante) | Base de firmware UEFI. |
| EDK2 | https://github.com/tianocore/edk2 | BSD-2-Clause-Patent | Implementação de referência UEFI. |
| mtkclient | https://github.com/bkerler/mtkclient | GPL-3.0 (verificar) | Ferramenta externa de leitura BROM/preloader. Nunca embutida no repo. |

## Como usar este material

1. **Ler** para entender abordagem e arquitetura.
2. **Registrar** em `docs/` o que foi aprendido, com link e commit/tag.
3. **Só então** decidir se algo é aplicável ao `lima_32`.

## Regras

- Fixar a versão: anotar `tag` ou `commit` ao citar qualquer upstream. "A branch
  main do projeto X" não é referência.
- Conferir a licença **no commit usado**, não no README.
- Não misturar código GPL (kernel Linux) com código APSL (XNU).
- Não copiar configuração de plataforma entre SoCs diferentes (ver
  `docs/10-compatibility.md`).

## Pendências

- [ ] Fixar a tag/commit do XNU usada como base
- [ ] Verificar licença do HakiOS no commit de referência
- [ ] Verificar licença do Mu-Silicium e dos pacotes Mu usados
- [ ] Registrar, para cada upstream, o que exatamente estamos observando
