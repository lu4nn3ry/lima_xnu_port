# 09 — Segurança e backups

Este documento é **bloqueante**. Nenhuma fase que escreva no aparelho começa
sem que os itens aqui estejam concluídos e registrados.

---

## 1. Partições e dados irreversíveis

| Dado | Onde | Consequência da perda |
| ---- | ---- | --------------------- |
| IMEI / calibração de RF | `nvram`, `nvdata`, `nvcfg`, `persist` | sem rede celular; não recuperável por firmware genérico |
| Calibração de sensores, MAC Wi-Fi/BT | `persist` | sensores/Wi-Fi degradados ou mortos |
| Chaves e estado de desbloqueio | `seccfg`, `protect1/2` | bootloader pode ficar em estado indefinido |
| Preloader / LK | `preloader`, `lk` | brick; recuperação só via BROM (se possível) |
| Tabela de partições | `pgpt`, `sgpt` | aparelho não reconhece layout |
| Firmware de modem/DSP | `md1img`, `md1dsp` | modem/DSP inoperante |

Regra: **se não sabemos o que a partição contém, ela é intocável.**

## 2. Proibições explícitas (válidas até a Fase 1 ser aberta formalmente)

```
NÃO executar:
  fastboot flash ...
  fastboot erase ...
  fastboot format ...
  fastboot flashing unlock / lock / unlock_critical
  fastboot set_active ...
  mtkclient write / w / e / erase / format
  qualquer "spflashtool download"
```

Permitido (somente leitura):

```
  adb shell <comandos de leitura>
  adb pull <arquivo de log/config>
  fastboot getvar ...
  fastboot devices
  mtkclient read (com verificação explícita de que é read-only)
  unpack/extração local de imagens já obtidas
```

## 3. Checklist antes de qualquer escrita

- [ ] Modelo e build exatos registrados (`01-device-identity.md`)
- [ ] Bootloader state e slot ativo registrados
- [ ] Backup completo das partições críticas feito
- [ ] Hash SHA-256 de cada imagem de backup calculado e salvo
- [ ] Backup **verificado por releitura** (não só copiado)
- [ ] Duas cópias em mídias diferentes
- [ ] Caminho de recuperação testado (ex.: BROM responde? fastboot responde?)
- [ ] Plano de rollback escrito, com comandos exatos
- [ ] Janela de tempo e bateria suficiente (> 50%)
- [ ] Cabo USB e porta estáveis; sem hub
- [ ] Registro do que será escrito, com justificativa

Se qualquer item estiver vazio, **não escrever**.

## 4. Verificação de backup

```sh
# após o dump
sha256sum dumps/*.img            > dumps/SHA256SUMS
# releitura de controle de uma amostra
sha256sum /caminho/da/segunda/copia/*.img
diff dumps/SHA256SUMS dumps/SHA256SUMS.segunda-copia
```

Um backup que nunca foi restaurado/testado é uma hipótese, não um backup. Para
partições não críticas, vale testar a restauração de propósito, para validar o
procedimento antes de precisar dele.

## 5. Riscos específicos de MediaTek

- **Anti-rollback**: gravar firmware mais antigo que o contador pode brickar de
  forma permanente. Verificar antes.
- **BROM exploit**: dá acesso poderoso, inclusive a comandos de escrita. Erro de
  digitação aqui é irreversível.
- **Preloader como parte da cadeia confiável**: alterá-lo quebra a recuperação.
- **Modo de download**: algumas ferramentas escrevem por padrão ao conectar.
  Nunca rodar ferramenta desconhecida com o aparelho conectado.

## 6. Dados pessoais

Dumps podem conter dados pessoais (contas, mensagens, IMEI). Manter em `dumps/`
(git-ignored), nunca anexar em issues, nunca publicar. Se precisar compartilhar
um trecho, redigir/anonimizar.

> Incidente registrado em 2026-11-10: um `fastboot getvar all` com IMEI e serial
> foi commitado em `research/bootloader/`. O arquivo foi redigido depois, mas o
> histórico do git ainda contém os valores. Antes de publicar este repositório,
> reescrever o histórico (ou recriar o repo a partir de uma árvore limpa).

## 6.1 O que cada modo permite copiar (verificado no `lima_32`)

| Modo | Consegue copiar `userdata`/`/sdcard`? | Observação |
| ---- | ------------------------------------ | ---------- |
| `fastboot` | **Não** | O bootloader respondeu `Device does not support fetch command`. `fastboot` só oferece `getvar` (variáveis), não leitura de partições. |
| `adb` (Android iniciado) | **Sim**, `/sdcard` | `adb pull /sdcard` — não precisa de root. Não inclui dados privados de apps. |
| `adb backup` | Parcial | Depreciado; só apps com `allowBackup=true`. Não confiável como backup completo no Android 10. |
| BROM / preloader via `mtkclient` (read) | Sim, imagem crua | Gera imagem **criptografada** (FBE) de ~dezenas de GB; sem as chaves do TEE o conteúdo não é legível. Útil para o port, não para "recuperar fotos". |
| root (`dd` em `userdata`) | Sim | Exige instalar Magisk = escrita em partição. Proibido pelas regras deste projeto. |

Conclusão prática:

- **Dados pessoais** → iniciar o Android e `adb pull /sdcard`
  (`tools/backup-sdcard.ps1`).
- **Firmware/partições para o port** → dump read-only via BROM
  (`boot`, `dtbo`, `vbmeta`, `lk`, `preloader`, `nvram`, `persist`), com hashes.
- `fastboot` serve para **diagnóstico** (`getvar`), não para backup.


## 7. Responsabilidade

Desbloquear bootloader normalmente anula a garantia e pode impedir atualizações
ou serviços. Este projeto não fornece garantia de reversibilidade.
