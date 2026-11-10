# 10 — Compatibilidade com projetos existentes

Este documento existe para impedir o erro mais comum em ports: **herdar
configuração de um aparelho diferente porque "é o mesmo fabricante"**.

---

## 1. HakiOS — port MT6768

O HakiOS mantém uma experiência separada para **MediaTek MT6768** além do port
principal (Qualcomm). É uma referência metodológica valiosa:

- como estruturar loader → hardware → kernel;
- como documentar o bring-up;
- que tipo de armadilha aparece em plataformas MediaTek.

O que **não** pode ser herdado:

| Item | Por quê |
| ---- | ------- |
| Endereços de registradores | MT6768 tem outro mapa de periféricos |
| Configuração de GIC/IRQ | versão e roteamento diferem |
| Mapa de memória/reservas | depende de DRAM, firmware e co-processadores do SoC |
| Timer e clocks | PLLs e árvore de clock diferentes |
| Drivers de display/touch | controladores e painéis diferentes |
| Defconfig | CPUs, caches, SMP e features podem não existir |

Conclusão: MT6768 ≠ MT6771 (e ≠ MT6765). Nada é copiado; no máximo, a *forma* da
solução é reaproveitada.

## 2. Mu-Silicium / Project Mu (UEFI)

Mu-Silicium é uma implementação UEFI voltada a plataformas **Qualcomm**
Snapdragon. É excelente para entender:

- como um bootloader UEFI é estruturado em ARM64;
- como se faz um "pacote" de plataforma e um "pacote" de dispositivo;
- como obter framebuffer, timer e console cedo no boot;
- como carregar um kernel EFI.

Limitações para o nosso caso:

- a camada de plataforma é específica de Qualcomm (SMMU, QUP, RPMh, etc.);
- MediaTek não tem o mesmo conjunto de protocolos;
- o caminho de boot (BROM → preloader → LK) não é UEFI.

Portanto: **UEFI é um caminho possível, não um caminho herdado.** A decisão de
usar UEFI no `lima_32` depende de a Fase 1 conseguir carregar código próprio.
Se o único caminho for BROM → payload em RAM, um loader minimalista
(`-ffreestanding`, sem UEFI) pode ser mais direto.

## 3. XNU (Apple)

Base oficial: `apple-oss-distributions/xnu`. Licença APSL 2.0.

O que já existe e ajuda:

- `pexpert/arm64`: camada de plataforma (console, timer, boot args);
- `osfmk/arm64`: boot, MMU, exceções, SMP;
- `iokit`: modelo de drivers.

O que não existe:

- suporte a plataformas não-Apple. O XNU assume contratos do bootloader Apple
  (device tree no formato da Apple, `boot_args`, memory regions, PE state).
- drivers para hardware MediaTek.

Consequência: o trabalho real é escrever a **camada de plataforma** que satisfaz
esses contratos usando o hardware do MT6771/MT6765, e um bootloader que passe as
informações no formato esperado.

## 4. Matriz de decisão (a preencher na Fase 1)

| Caminho | Requisito | Risco | Veredito |
| ------- | --------- | ----- | -------- |
| Payload em RAM via BROM | exploit disponível no chip | brick se errar | a avaliar |
| `fastboot boot` com imagem própria | bootloader desbloqueado e sem AVB estrito | baixo | a avaliar |
| UEFI (estilo Mu-Silicium) | port de plataforma MediaTek | alto esforço | a avaliar |
| Loader minimalista próprio | canal de carga + console | médio | a avaliar |

## 5. Regra final

> Compatibilidade não se declara; se mede. Toda afirmação de compatibilidade
> precisa de um teste no `lima_32` ou fica marcada como hipótese.
