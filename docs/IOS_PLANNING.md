# 🍏 Planejamento para Versão iOS - Smart Ronda TI

Este documento serve como guia estratégico para a futura expansão do ecossistema Smart Ronda para dispositivos Apple.

## ☁️ Opções de Build na Nuvem (Sem Mac Físico)

Para compilar o projeto para iOS sem possuir um hardware Apple, utilizaremos serviços de CI/CD que fornecem máquinas macOS remotas:

### 1. GitHub Actions (Recomendado para Automação)
- **Custo**: Grátis (2.000 minutos/mês para repositórios privados).
- **Fluxo**: Automatizado via script `.yml` no push do Git.
- **Uso**: Ideal para gerar builds contínuos de teste.

### 2. Codemagic (Recomendado para Facilidade)
- **Custo**: 500 minutos gratuitos por mês.
- **Fluxo**: Interface visual simplificada e integração direta com o GitHub.
- **Uso**: Melhor opção para quem nunca gerou um IPA (instalador iOS) antes.

### 3. Xcode Cloud (Oficial)
- **Custo**: 25 horas gratuitas/mês para quem já é Apple Developer.
- **Uso**: Integração total com a App Store Connect.

---

## 🛠️ Pré-requisitos Obrigatórios

Independente da ferramenta de nuvem escolhida, a Apple exige:

1. **Apple Developer Program**: Uma conta de desenvolvedor ativa (Custo atual: U$ 99/ano). Sem isso, não é possível instalar o app em iPhones físicos ou publicar na App Store.
2. **Certificados e Provisioning Profiles**: Arquivos de segurança (`.p12` e `.mobileprovision`) que vinculam o código do app à sua identidade de desenvolvedor.
3. **App ID**: Identificador único (ex: `com.smartronda.ti.ios`) configurado no portal da Apple.

---

## 🚀 Próximos Passos Sugeridos

Quando decidirmos iniciar esta etapa:

1. **Configuração do Xcode**: Precisaremos de um Mac (pode ser via Xcode Cloud ou máquina virtual local) apenas para a configuração inicial do projeto iOS (ícones, permissões e nomes de pacotes).
2. **Setup do CI/CD**: Criar o script de automação para que toda atualização no GitHub gere automaticamente um arquivo `.ipa`.
3. **Testes via TestFlight**: Usar a ferramenta oficial da Apple para distribuir a versão beta para técnicos que possuam iPhone.

---
**Data da Nota:** 25 de Junho de 2024
**Versão Atual do Sistema:** 3.2.0
