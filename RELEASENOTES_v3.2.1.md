# 📑 Relatório de Entrega e Notas de Lançamento

**Versão:** 3.2.1 Stable
**Data:** 25 de Junho de 2024
**Responsável:** Smart Ronda TI - Development Team

---

## 🚀 O que há de novo na v3.2.1?

Esta versão foca em correções de integridade de dados nos relatórios e refinamento da experiência do usuário no dashboard administrativo.

### 📊 Relatórios e BI
*   **Correção de Patrimônio**: Resolvido o problema onde a coluna "Patrimônio" exibia "S/P" em relatórios técnicos de rondas. Agora o número da placa é extraído corretamente dos metadados do ativo.
*   **Subtítulos Dinâmicos**: Os cabeçalhos dos relatórios agora descrevem automaticamente os filtros aplicados (ex: "Relatório de Inventário: MANUTENÇÃO - OBSOLETOS"). Caso nenhum filtro seja usado, o título assume "Relatório de Inventário Geral".
*   **Mapeamento de Dados**: O campo `patrimonio` agora é salvo explicitamente dentro do mapa de cada equipamento na ronda, garantindo auditabilidade histórica mesmo se o ID do documento principal for alterado.

### 🎨 UI/UX (Interface)
*   **Otimização Dark Mode**: Os botões de filtro (`FilterChips`) na Central de Relatórios foram redesenhados com bordas dinâmicas e cores de fundo adaptativas, garantindo excelente leitura tanto no tema claro quanto no escuro.

### 🛠️ Detalhes Técnicos
*   **Versão do App**: `3.2.1`
*   **Version Code**: `37`
*   **Persistência**: Atualização do `AssetModel.toMap()` para inclusão de campos chave.

---

## 📋 Como atualizar?
1. Execute `flutter pub get`.
2. Gere o build normalmente.

---
**Smart Ronda TI** - *Governança de Ativos com Inteligência Estratégica.*
