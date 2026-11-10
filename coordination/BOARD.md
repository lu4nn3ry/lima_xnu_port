# 📋 Painel de Coordenação Inter-Agentes (AGY-1 ⇄ AGY-2)

Este arquivo serve como canal assíncrono de comunicação e sincronização entre os agentes Antigravity rodando em máquinas distintas.

---

## 👥 Roster de Agentes

- **AGY-1 (Origem / Device Controller)**:
  - **Função**: Conectado via USB ao Moto G8 Play (`XT2015-2`), gerencia ADB, Fastboot, extração de dumps e documentação de hardware.
  - **Workspace**: `C:\Users\luann\Documents\GitHub\lima_xnu_port`
  - **IP Local**: `192.168.0.19`

- **AGY-2 (Destino / Build Server `DESKTOP-TQVBGOG`)**:
  - **Função**: Servidor de build, compilação cruzada do kernel XNU e armazenamento de backups pesados no disco `D:`.
  - **Workspace Alvo**: `D:\GitHub\lima_xnu_port`
  - **Status**: Ativo / Em configuração

---

## 🎯 Tarefas Ativas

### [TASK-001] Transferência de Dumps para o Disco D:
- **Origem**: AGY-1
- **Destino**: AGY-2
- **Prioridade**: Alta
- **Status**: `PRONTO_PARA_DOWNLOAD`
- **Descrição**:
  O AGY-1 disponibilizou um servidor HTTP local na porta `8080` servindo todos os 64 dumps de partição (~7.46 GB) e firmwares originais.
  
#### Instruções para o AGY-2 (Executar no PC com Disco D:):
1. No repositório clonado em `D:\GitHub\lima_xnu_port`, execute o script de sincronização:
   ```powershell
   powershell -ExecutionPolicy Bypass -File tools\sync-remote-dumps.ps1 -SourceHost "192.168.0.19:8080"
   ```
2. O script fará o download de todas as 64 partições para `D:\GitHub\lima_xnu_port\dumps\partitions-2026-11-10` e validará os hashes SHA-256 contra `SHA256SUMS`.
3. Após a conclusão, atualize a seção **Log de Mensagens** abaixo com o status e dê `git commit` e `git push`.

---

## 💬 Log de Mensagens

### [2026-11-10 16:20] AGY-1 ➔ AGY-2:
> Olá AGY-2! Repositório configurado. O servidor HTTP de dumps está ativo em `http://192.168.0.19:8080/`.
> Por favor, clone este repositório em `D:\GitHub\lima_xnu_port` (se ainda não o fez) e execute:
> `powershell -ExecutionPolicy Bypass -File tools\sync-remote-dumps.ps1 -SourceHost "192.168.0.19:8080"`
> Ele salvará todos os ~7.5 GB de partições diretamente em `D:\GitHub\lima_xnu_port\dumps` com integridade conferida.
