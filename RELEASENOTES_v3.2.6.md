# 📑 Relatório de Entrega e Notas de Lançamento

**Versão:** 3.2.6 Stable
**Data:** 15 de Julho de 2026
**Responsável:** Smart Ronda TI - Development Team

---

## 🚀 O que há de novo na v3.2.6?

Esta versão consolida a governança de ativos em Home Office e otimiza a operação de campo com foco em redução de custos de suprimentos.

### 🏠 Gestão de Home Office 2.0
*   **Autorização Permanente**: Substituímos o botão temporário por uma chave de autorização permanente (`Switch`).
*   **Persistência Inteligente**: O sistema agora "lembra" se um equipamento está autorizado para Home Office entre as rondas. Ao escanear um item, a chave liga automaticamente se ele já possuir a permissão.
*   **Identificação do Responsável**: O nome do responsável pelo equipamento externo agora é preservado e exibido com destaque nos relatórios e dashboard.

### 🖨️ Otimização para Impressoras Térmicas
*   **Novo Formato JPG Nativo**: Alteramos a exportação de QR Codes de PNG para JPG em todo o sistema (Ronda e Histórico).
*   **Economia de Fita (Ribbon)**: A remoção do canal de transparência e o uso de fundo branco sólido eliminam o processamento ineficiente das impressoras portáteis, resultando em grande economia de insumos.
*   **Salvar na Galeria**: Adicionado botão direto para salvar a imagem do QR Code na galeria do dispositivo, facilitando o uso por aplicativos de terceiros ou impressão posterior.

### 📊 Dashboard e Relatórios
*   **Sincronização de Filtros**: Dashboard e Relatórios agora utilizam o campo de autorização permanente para contabilizar ativos em Home Office com precisão.
*   **Relatórios Corporativos**: Exportações para PDF, Excel e CSV agora incluem o nome do Responsável quando o filtro de Home Office está ativo.

### 🛠️ Detalhes Técnicos
*   [x] **Versão do App**: `3.2.6`
*   [x] **Version Code**: `42`
*   [x] **Dependência**: Adicionada a biblioteca `image` para conversão segura de formatos.

---

## 📋 Como atualizar?
1. Execute `flutter clean` e `flutter pub get` para sincronizar a nova dependência.
2. Realize o build do APK e o deploy do Hosting para alinhar todo o ecossistema.

---
**Smart Ronda TI** - *Governança de Ativos com Inteligência Estratégica.*
