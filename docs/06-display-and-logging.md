# 06 — Display e logging

## Por que estes dois juntos

No bring-up, **log vale mais que imagem**. Um kernel que desenha um logo e não
imprime nada é inútil para depuração; um kernel que imprime "cheguei na linha X"
via UART ou pstore é ouro. Display é o *primeiro periférico de saída para o
usuário*, mas **não** o primeiro canal de diagnóstico.

Ordem comprovada e adotada:

1. **Canal primário de log**: `pstore` / `ramoops` (em `0x54410000`) persistente na DRAM entre resets, complementado por UART0 (`0x11002000`).
2. **Segundo estágio (display)**: Framebuffer linear pré-configurado pelo bootloader LK em `0x7d4f0000`.

---

## 1. Canais de log verificados

| Canal | Endereço Físico | Configuração | Prós | Contras | Status |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`pstore` / `ramoops`** | `0x54410000` | 896 KiB (`console-ramoops` ativo) | Sobrevive a resets sem desmontar hardware; Android lê direto em `/sys/fs/pstore/` | Necessita de reboot para inspeção caso não haja UART | **Confirmado (Primário Fase 1)** |
| **UART0 (AP Console)** | `0x11002000` | 921.600 baud, 8N1 (`compatible = "mediatek,mt6577-uart"`) | Síncrono, imediato | Exige solda ou pinout de testpoint no PCB | **Confirmado (DTB/cmdline)** |
| **Framebuffer LK** | `0x7d4f0000` | 15.073.280 bytes (~15 MiB), 720×1520 | Visual sem cabos; tela já ligada pelo bootloader | Exige renderizador de fonte bitmap manual | **Confirmado (Fase 2)** |
| **`log_store` (MTK)** | `0x7ffc0000` | 256 KiB | Logs internos do preloader e LK | Formato binário MTK | Confirmado |
| **ATF log store** | `0xbfe00000` | 256 KiB | Logs do ARM Trusted Firmware | Formato texto | Confirmado |

---

## 2. Display e Framebuffer

### Dados de hardware confirmados:
- **Resolução Nativa**: 720 × 1520 pixels (24-bit ou 32-bit RGBA).
- **Controlador DSI**: MediaTek DSI em `0x14014000` com LARB0 em `0x14017000`.
- **Framebuffer Linear pré-alocado pelo LK**:
  - Base: `0x7d4f0000`
  - Tamanho: `0x00f10000` (15.073.280 bytes)
  - Formato: BGRX8888 ou RGBA8888 (32 bits por pixel: $720 \times 1520 \times 4 \approx 4.377.600$ bytes por buffer). O espaço de 15 MiB suporta confortavelmente triple-buffering.

### Estratégia de exibição (Fase 2):
1. **Reaproveitamento direto**: Escrever diretamente na faixa de memória física `0x7d4f0000` sem tocar na configuração dos registradores DSI ou do PMIC backlight.
2. Como o LK já deixou o backlight e a tela ligados na logo da Motorola, o buffer é scanout ativo pelo display controller.

---

## 3. Decisão da Fase 1

O critério de aceite da Fase 1 é:
> *"Código próprio executa no aparelho e produz uma mensagem recuperável após reset."*

### O mecanismo do teste:
1. Compilar um binário ARM bare-metal (`stage1_hello.bin`) empacotado como `boot.img` com o cabeçalho v2 do `lima_32`.
2. O bootloader descompacta e salta para `0x40008000`.
3. O código escreve no endereço de ramoops (`0x54410000`):
   ```
   === console-ramoops ===
   [lima-xnu-phase1] Hello from bare-metal Stage 1 loader on MT6771!
   ```
4. Em seguida, aciona o Watchdog timer da MTK (`0x10007000`) ou chama `psci_system_reset` via SMC para reiniciar o celular de volta ao Android (ou slot de boot secundário).
5. No boot do Android, lemos `/sys/fs/pstore/console-ramoops` via ADB e comprovamos a execução de código arbitrário bare-metal!

---

## 4. Status das Pendências

- [x] Resolução nativa real (720×1520 confirmada)
- [x] Endereço e formato do framebuffer do bootloader (`0x7d4f0000`, 15 MiB)
- [x] Escolher o canal primário de log da Fase 1 (`pstore / ramoops` em `0x54410000`)
- [x] Documentar como recuperar o log após um reset (leitura via `/sys/fs/pstore`)
- [x] Especificação do teste da Fase 1
