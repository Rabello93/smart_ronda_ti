# 📑 Relatório de Entrega e Notas de Lançamento

**Versão:** 3.2.3 Stable
**Data:** 02 de Julho de 2024
**Responsável:** Smart Ronda TI - Development Team

---

## 🚀 O que há de novo na v3.2.3?

Esta versão traz a tão aguardada flexibilidade na manipulação de dados, permitindo que a gestão exporte o inventário para ferramentas de análise externa.

### 📊 Relatórios e Dados
*   **Exportação XLSX Nativa**: Agora o sistema gera arquivos Excel reais (.xlsx) com cabeçalhos estilizados, negrito e cores corporativas.
*   **Exportação CSV**: Adicionado suporte para CSV separado por ponto e vírgula, com codificação UTF-8 BOM para compatibilidade imediata com o Excel brasileiro.
*   **Seletor de Formatos**: Interface da Central de Relatórios atualizada com um menu deslizante horizontal para acomodar as 4 opções de saída (PDF, CSV, XLSX, XML).

### 🛠️ Detalhes Técnicos
*   [x] **Versão do App**: `3.2.3`
*   [x] **Version Code**: `39`
*   [x] **Dependência**: Adicionado suporte à biblioteca `excel`.

---

## 📋 Como atualizar?
1. Execute `flutter pub get` para instalar a nova dependência de Excel.
2. Gere o build normalmente.

---
**Smart Ronda TI** - *Governança de Ativos com Inteligência Estratégica.*
