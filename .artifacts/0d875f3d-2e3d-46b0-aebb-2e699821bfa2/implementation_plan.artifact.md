# Finalização da Versão 3.2.6

Este plano visa consolidar todas as alterações de hoje sob a nova versão **3.2.6**, alinhando todos os rodapés, metadados e documentação, seguido pelo fluxo de deploy e build.

## User Review Required

> [!IMPORTANT]
> Vou atualizar o `versionCode` para **42** e o `versionName` para **3.2.6**.
> O commit será realizado com a mensagem: `"feat: finalize v3.2.6 - total version alignment and strategic goals report"`.

## Proposed Changes

### [Configuração & Documentação]

#### [MODIFY] [pubspec.yaml](file:///C:/Users/fabio/ronda_equipamentos/smart_ronda_ti/pubspec.yaml)
- Atualizar para `version: 3.2.6+10`.

#### [MODIFY] [build.gradle.kts](file:///C:/Users/fabio/ronda_equipamentos/smart_ronda_ti/android/app/build.gradle.kts)
- Atualizar `versionCode: 42` e `versionName: "3.2.6"`.

#### [MODIFY] [README.md](file:///C:/Users/fabio/ronda_equipamentos/smart_ronda_ti/README.md)
- Adicionar notas da versão 3.2.6: Revisão Home Office (Switch + Persistência) e Exportação QR Code em JPG.

### [UI & Relatórios]

#### [MODIFY] [dashboard_page.dart](file:///C:/Users/fabio/ronda_equipamentos/smart_ronda_ti/lib/features/management/dashboard/pages/dashboard_page.dart)
- Atualizar rodapé para "Versão 3.2.6".

#### [MODIFY] [report_repository.dart](file:///C:/Users/fabio/ronda_equipamentos/smart_ronda_ti/lib/features/management/reports/repositories/report_repository.dart)
- Atualizar todas as menções de `v3.2.5` para `v3.2.6` nos rodapés de PDF.

#### [MODIFY] [home_page.dart](file:///C:/Users/fabio/ronda_equipamentos/smart_ronda_ti/lib/features/operation/rounds/pages/home_page.dart)
- Atualizar versão no rodapé da página inicial.

## Sequence of Commands

1. `flutter clean`
2. `flutter pub get`
3. `flutter build web`
4. `firebase deploy --only hosting`
5. `git add .`
6. `git commit -m "feat: finalize v3.2.6 - total version alignment and strategic goals report"`
7. `git push`
8. `flutter build apk --release`

## Verification Plan

### Manual Verification
- Abrir o dashboard web após deploy e checar rodapé.
- Gerar um PDF de relatório e checar rodapé.
- Instalar o APK gerado e checar a versão na Home.
