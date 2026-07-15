# Implementation Plan - APK Build Stabilization

Stabilize the Android build environment by resolving environment variable conflicts, aligning Gradle/AGP versions, and fixing JVM/Kotlin compatibility issues.

## User Review Required

> [!IMPORTANT]
> A falha no build do APK é causada por um conflito de variáveis de ambiente (`ANDROID_PREFS_ROOT` e `ANDROID_USER_HOME`). Vou tentar desativar uma delas temporariamente durante o comando de build. Recomendo remover `ANDROID_PREFS_ROOT` das configurações do seu Windows permanentemente.

## Proposed Changes

### [Android]

#### [MODIFY] [settings.gradle.kts](file:///C:/Users/fabio/ronda_equipamentos/smart_ronda_ti/android/settings.gradle.kts)
- Atualizar a versão do Android Gradle Plugin para `8.9.1`.
- Atualizar a versão do Kotlin para `1.9.24` para compatibilidade com plugins legados.

#### [MODIFY] [gradle-wrapper.properties](file:///C:/Users/fabio/ronda_equipamentos/smart_ronda_ti/android/gradle/wrapper/gradle-wrapper.properties)
- Atualizar a URL de distribuição do Gradle para `8.11.1`.

#### [MODIFY] [build.gradle.kts](file:///C:/Users/fabio/ronda_equipamentos/smart_ronda_ti/android/build.gradle.kts)
- Ajustar a configuração de `subprojects` para forçar o Java 17 de forma consistente em todos os módulos e plugins.

## Verification Plan

### Manual Verification
- Executar o build do APK garantindo que o conflito de variáveis de ambiente não ocorra:
  `$env:ANDROID_PREFS_ROOT = $null; flutter build apk --release --android-skip-build-dependency-validation`
