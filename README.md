# lima_xnu_port

Pesquisa independente de um port experimental de **XNU/Darwin** para o
**Motorola Moto G8 Play** (`lima_32`, XT2015-2), MediaTek.

> **Status atual: Fase 0 — pesquisa.** Nenhum código de kernel, nenhum flash,
> nenhuma alteração nas partições do aparelho.

Este repositório é **separado** de qualquer ROM Android, árvore de dispositivo,
kernel Linux ou projeto de usuário final. Ele não contém firmware proprietário,
não redistribui blobs da Motorola/MediaTek e não contém código da Apple além do
que estiver publicado nos repositórios oficiais `apple-oss-distributions`.

---

## Objetivo

Adaptar o kernel Darwin (XNU) para o hardware do `lima_32` e documentar cada
etapa de forma reproduzível.

**Primeiro objetivo real** (não é "iniciar o iOS"):

1. Executar um **loader próprio** no aparelho.
2. Obter **logs** desse código.
3. Descrever corretamente o **hardware** (RAM, GIC, timer, CPU, framebuffer).

Só depois disso faz sentido falar de XNU, drivers e ambiente de usuário.

## Não-objetivos

- Não é um port de iOS. O userspace do iOS não é redistribuível e está fora de
  escopo. O escopo é o **Darwin/XNU open source**.
- Não é uma ROM Android alternativa.
- Não é um guia de desbloqueio genérico nem de "root".
- Não é compatível, por herança, com ports de outros SoCs (ver
  `docs/10-compatibility.md`).

## Estrutura

```
docs/        documentação técnica numerada (fonte da verdade do projeto)
devices/     descrição por aparelho; `lima_32` é o alvo atual
research/    material bruto coletado (DTB, dmesg, mapas de memória, firmware)
patches/     patches mantidos pelo projeto (xnu, loader, drivers)
tools/       scripts auxiliares, sempre read-only por padrão
upstream/    notas sobre repositórios externos acompanhados
```

## Roadmap resumido

| Fase | Nome | Meta |
| ---- | ---- | ---- |
| 0 | Pesquisa | Identificar firmware, bootloader, kernel, DTB, partições, hardware. Zero alterações no aparelho. |
| 1 | Loader | Estudar UEFI/Mu-Silicium e a cadeia de boot. Executar código próprio **sem gravar partições**. |
| 2 | Hardware | RAM, regiões reservadas, GIC, timer, CPU, framebuffer. |
| 3 | XNU mínimo | Adaptação ARM64, inicialização de um núcleo, logs. |
| 4 | Drivers | Display, armazenamento, touch, USB — um por vez. |
| 5 | Darwin userspace | Ambiente de usuário e compatibilidade. |

Detalhamento e tarefas: `TODO.md`.

## Regras de segurança (obrigatórias)

- Não gravar `bootloader`, `boot`, `recovery`, `vbmeta`, `dtbo` ou qualquer
  outra partição nesta fase.
- Não apagar dados do aparelho.
- Não tocar em `persist`, `nvram`, `nvdata`, `md1img`/modem ou calibração.
  Parte dessas partições contém dados **exclusivos daquele aparelho**
  (calibração de RF, IMEI). Perder isso não é reversível por firmware.
- Nenhum comando `flash`, `erase`, `format` ou `fastboot flashing ...` sem
  análise específica registrada em `docs/09-safety-and-backups.md`.
- Backups verificáveis antes de qualquer experimento que escreva algo.
- Preferir QEMU primeiro; depois inicialização temporária (`fastboot boot`),
  se e somente se o bootloader permitir.

## Estado das informações

O documento `docs/01-device-identity.md` separa explicitamente:

- **verificado no aparelho** (com o comando e a saída que provaram o dado);
- **relatado pelo usuário** (informação de quem tem o aparelho, ainda sem
  comando de confirmação);
- **relatado em fonte pública** (link, data, confiabilidade);
- **a verificar / conflitante**.

Nenhum dado de hardware deve ser considerado definitivo só porque aparece em
uma tabela de site de especificações.

## Upstream acompanhado

Ver `upstream/README.md`. Resumo: XNU oficial da Apple, HakiOS XNU kernel,
Mu-Silicium / Project Mu (UEFI), e o material de portabilidade do HakiOS para
MT6768 — este último serve como **referência metodológica**, não como
configuração reutilizável.

## Licença

Ver `LICENSES.md`.
