# Correção Definitiva Build APK v3.2.6

Este plano visa resolver os conflitos de compilação (JVM Target) e permissões de Android para garantir o lançamento estável da versão 3.2.6 com todas as funcionalidades de hoje.

## User Review Required

> [!IMPORTANT]
> Vou atualizar o **Gradle** e o **Android Gradle Plugin** para as versões mais recentes. Isso é necessário para que plugins antigos e novos convivam sem erros de compilação. Além disso, adicionarei permissões de armazenamento para garantir que o botão "Salvar na Galeria" funcione em todas as versões do Android.

## Proposed Changes

### [Android - Build System]

#### [MODIFY] [gradle-wrapper.properties](file:///C:/Users/fabio/ronda_equipamentos/smart_ronda_ti/android/gradle/wrapper/gradle-wrapper.properties)
- Atualizar `distributionUrl` para Gradle **8.14.0**.

#### [MODIFY] [settings.gradle.kts](file:///C:/Users/fabio/ronda_equipamentos/smart_ronda_ti/android/settings.gradle.kts)
- Atualizar `com.android.application` para **8.11.1**.
- Atualizar `org.jetbrains.kotlin.android` para **2.2.20**.

#### [MODIFY] [build.gradle.kts](file:///C:/Users/fabio/ronda_equipamentos/smart_ronda_ti/android/build.gradle.kts)
- Refinar a regra de `jvmTarget` para incluir tanto Kotlin quanto Java em todos os subprojetos, forçando o uso da **versão 17**.

### [Android - Permissões]

#### [MODIFY] [AndroidManifest.xml](file:///C:/Users/fabio/ronda_equipamentos/smart_ronda_ti/android/app/src/main/AndroidManifest.xml)
- Adicionar permissão `WRITE_EXTERNAL_STORAGE`.
- Adicionar `android:requestLegacyExternalStorage="true"` na tag `<application>`.

### [Documentação]

#### [MODIFY] [README.md](file:///C:/Users/fabio/ronda_equipamentos/smart_ronda_ti/README.md)
- Organizar a seção "Histórico" colocando a v3.2.6 no topo e removendo duplicidades de "v3.2.5 (Atual)".

## Supercombo Corrigido

A sequência recomendada para o terminal será:
```powershell
flutter clean; flutter pub get; flutter build web --release; firebase deploy --only hosting; git add .; git commit --amend --no-edit; git push --force; flutter build apk --release --android-skip-build-dependency-validation
```

## Verification Plan

### Manual Verification
1. Rodar o supercombo e validar o sucesso do build do APK.
2. Abrir o APK no celular e testar o botão "Salvar na Galeria".
