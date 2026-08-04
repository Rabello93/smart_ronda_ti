# Notas de Lançamento - v3.3.6 🚀🎯🛡️

**Data:** 04 de Agosto de 2026
**Versão:** 3.3.6 Stable

## 🚀 O que foi corrigido?

Esta versão foca na correção crítica de persistência de dados e estabilidade do repositório.

### 🏢 Gestão de Locação
*   **Correção de Persistência**: Corrigimos o erro onde itens marcados como locados perdiam a informação da empresa locadora ao salvar a ronda. Agora, os dados de locação são persistidos corretamente no banco de dados.
*   **Ciclo de Vida**: O campo de "Ano de Fabricação" agora é mantido e atualizado corretamente após cada auditoria.

### 🛠️ Estabilidade e Código
*   **Salvamento Inteligente**: Refinamos a lógica de atualização no "Castelo" para garantir que apenas os campos alterados ou necessários sejam enviados, protegendo os dados técnicos originais (Marca, Modelo, Processador).
*   **Otimização de Build**: Removidos avisos de redundância e inconsistências de tipo que poderiam causar falhas em dispositivos específicos.

---
> "Garantindo a integridade dos dados para uma governança impecável." 🏛️💎⚡🚀
