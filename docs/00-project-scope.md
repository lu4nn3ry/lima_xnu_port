# 00 — Escopo do projeto

## O que este projeto é

Um esforço de engenharia reversa e portabilidade, em fases, para levar o kernel
**Darwin/XNU** (código aberto da Apple) a rodar em um aparelho Android
específico: o Motorola Moto G8 Play, codinome `lima_32` (possivelmente `lima`).

O projeto é deliberadamente **sequencial**. Cada fase produz um artefato
verificável e uma documentação correspondente. Se uma fase não fecha, a
seguinte não começa.

## Por que não começar pelo XNU

Levar um kernel novo a um SoC desconhecido exige, antes de qualquer linha de
kernel:

1. Saber **como o aparelho inicializa** (quem carrega o quê, com que restrições).
2. Saber **se conseguimos executar código próprio** e **ver saída**.
3. Saber **onde está cada coisa** na memória e nos barramentos.

Sem esses três, qualquer port de kernel vira tentativa às cegas: o kernel
"não boota" e não há como distinguir entre erro de build, de mapeamento de
memória, de console, de MMU ou de hardware. A progressão adotada aqui é a mesma
recomendada por guias de portabilidade de XNU: código próprio → logs → hardware
→ CPU/memória → armazenamento → periféricos.

## Critérios de sucesso por fase

| Fase | Critério objetivo de saída |
| ---- | -------------------------- |
| 0 | Inventário de hardware e cadeia de boot documentados, com fonte para cada afirmação, **sem ter escrito nada no aparelho**. |
| 1 | Código próprio executa no aparelho e produz uma mensagem recuperável após reset. |
| 2 | Kernel próprio inicializa CPU, MMU, GIC e timer e imprime um relatório de hardware. |
| 3 | Núcleo XNU adaptado imprime `kprintf` na saída escolhida. |
| 4 | Pelo menos um periférico externo funcionando (display é o candidato natural). |
| 5 | Decisão documentada sobre viabilidade de userspace. |

## Fora de escopo (permanente)

- iOS, seus componentes privados, ou qualquer coisa que exija material da Apple
  não publicado.
- Distribuição de firmware, blobs ou dumps de aparelho.
- Instruções genéricas de modificação de Android, root, ou "desbloqueio".
- Suporte a outros aparelhos. Outros dispositivos podem ser adicionados em
  `devices/`, mas cada um é um projeto próprio.

## Princípios

1. **Read-only por padrão.** Toda ferramenta começa sem permissão de escrita.
2. **Fonte ou não existe.** Cada fato de hardware tem comando de verificação ou
   referência em `research/`.
3. **Separar observação de hipótese.** Hipótese é marcada como hipótese.
4. **Nada de herança de SoC.** Configuração de MT6768, Snapdragon ou qualquer
   outro chip não é transportada por analogia (ver `10-compatibility.md`).
5. **Backup antes de escrita.** E hash verificado, não só cópia.
