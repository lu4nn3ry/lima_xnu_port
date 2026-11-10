# `lima_32` — Motorola Moto G8 Play (XT2015-2)

Alvo atual do projeto. Documentação de referência:
`docs/01-device-identity.md` (identidade), `docs/02-boot-chain.md` (boot),
`docs/03`–`08` (hardware).

## Status

**Fase 0 — pesquisa.** Nenhuma alteração foi feita no aparelho. Nenhum dado
abaixo está confirmado no hardware ainda.

## Resumo (com nível de confiança)

| Campo | Valor | Confiança |
| ----- | ----- | --------- |
| Modelo | XT2015-2 | relato do usuário |
| Codinome | `lima` / `lima_32` | a confirmar |
| SoC | MT6771 **ou** MT6765 | **conflitante** |
| CPU | 4+4 (A73+A53 ou A53+A53) | depende do SoC |
| RAM | 2 GB | pública |
| Storage | eMMC (versão a confirmar) | pública |
| Tela | 720×1520 ou 720×1600 | **conflitante** |
| Android de fábrica | 9 | pública |
| Firmware atual | Android 10 | relato do usuário |
| Bootloader | desbloqueado | relato do usuário (confirmar) |

> O ponto mais importante deste arquivo é o que ele **não** afirma. Resolver
> MT6771 vs. MT6765 é a primeira tarefa técnica do projeto.

## Arquivos

| Arquivo | Papel |
| ------- | ----- |
| `device.yaml` | descrição legível por máquina, com `status` por campo |
| `defconfig` | configuração de build do alvo (template; nada ativo) |
| `notes/` | notas datadas de sessões de coleta |

## Como usar

1. Leia `docs/09-safety-and-backups.md` antes de qualquer coisa.
2. Rode `tools/collect-inventory.sh` (read-only) com o aparelho conectado.
3. Salve a saída em `research/hardware/`.
4. Atualize `device.yaml`, `docs/01` e `docs/03` com valores verificados e a
   fonte de cada um.
5. Registre a sessão em `notes/AAAA-MM-DD-*.md`.

## O que não fazer

- Não copiar `defconfig`/mapas de memória de MT6768, Snapdragon ou de qualquer
  outro aparelho.
- Não usar scatter file de outro modelo.
- Não gravar partições.
