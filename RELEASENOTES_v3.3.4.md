# Notas de Lançamento - v3.3.4 🚀🛡️💎

**Data:** 01 de Agosto de 2026
**Versão:** 3.3.4 Stable

## 🚀 O que mudou?

Esta versão foca na estabilidade operacional e na correção de permissões críticas, garantindo que a operação de campo não seja interrompida por restrições do banco de dados.

### 🛡️ Estabilidade de Salvamento (Fim do Permission Denied)
*   **Transferências Destravadas**: Corrigido o erro que impedia técnicos de transferir itens da TI para outros departamentos.
*   **Edição sem Conflitos**: A lógica de edição de rondas foi refatorada para não exigir permissões de exclusão, permitindo que todos os níveis de acesso salvem alterações normalmente.

### 📊 Dashboard e Gestão de TI
*   **Rastreio de Reparo**: Ao substituir um item, ele agora entra automaticamente como "Em manutenção" na TI, mantendo o cronômetro de dias parado ativo para controle de SLA.
*   **Card de Backup**: Criado indicador exclusivo para itens "Reservados" no Dashboard, separando o estoque estratégico do que está em conserto.

### 📑 Relatórios Inteligentes
*   **Filtros Universais**: O relatório de Incidências Críticas foi normalizado. Agora ele funciona sem depender de índices complexos do Firebase, eliminando o erro de "FAILED_PRECONDITION".

---
> "Tecnologia resiliente para uma operação ininterrupta." 🏛️📊🛡️💎⚡🚀
