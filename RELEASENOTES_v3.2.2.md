# 📑 Relatório de Entrega e Notas de Lançamento

**Versão:** 3.2.2 Stable
**Data:** 01 de Julho de 2024
**Responsável:** Smart Ronda TI - Development Team

---

## 🚀 O que há de novo na v3.2.2?

Esta versão consolida a integridade do banco de dados e traz ferramentas poderosas para o saneamento do inventário mestre.

### 🏛️ Gestão do Castelo e Dashboard
*   **Vassourinha Laranja Reativada**: O botão de Reset Total do Inventário Mestre está novamente operacional e seguro.
*   **Edição de Patrimônio**: Agora é possível atualizar o número da placa de um equipamento diretamente no menu "O Castelo". O sistema cuida da migração de dados e renomeação do registro automaticamente.
*   **Gestão Unificada de Ativos**: A aba de Locação no Dashboard evoluiu para **"Ativos"**, oferecendo uma visão 360º de todo o parque tecnológico, agrupando itens em "Patrimônio Próprio" ou por suas respectivas locadoras.
*   **Conversão Inteligente de Ativos**: Sistema agora rastreia e deleta registros temporários (SP_...) quando um item recebe uma placa de patrimônio definitiva durante a ronda.

### 📊 Relatórios de Auditoria e BI
*   **Mapa de Incidências Críticas**: Nova ferramenta de BI que gera um ranking de ativos com maior recorrência de manutenções, divergências de setor e uso de Home Office, permitindo uma gestão preditiva de substituição de equipamentos.
*   **Lógica de Filtros Combinados**: Implementada a lógica de UNIÃO para filtros de inventário. Agora, ao selecionar múltiplos problemas (ex: Defeitos + Obsoletos), o relatório traz todos os itens que se encaixam em QUALQUER uma das categorias críticas.
*   **Correção de Exibição**: Solucionado definitivamente o problema de exibição de patrimônio nos relatórios técnicos.
*   **Status Operacional Real**: Relatórios agora exibem o estado real do item (Home Office, Manutenção, Reservado) em vez de um status genérico.
*   **Novo Filtro de Saneamento**: Adicionado o botão "🚫 SEM PATRIMÔNIO" na central de relatórios para identificação rápida de itens que precisam de placa.

---

## 🛠️ Detalhes Técnicos
*   [x] **Versão do App**: `3.2.2`
*   [x] **Version Code**: `38`
*   [x] **Persistência**: Implementação de `idAnterior` no `AssetModel` para transições seguras.

---

## 📋 Como atualizar?
1. Execute `flutter pub get`.
2. Gere o build normalmente.

---
**Smart Ronda TI** - *Governança de Ativos com Inteligência Estratégica.*
