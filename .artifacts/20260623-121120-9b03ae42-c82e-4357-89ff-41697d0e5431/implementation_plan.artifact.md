# Phase 7: Final Cleanup & Import Refactoring

This plan covers the final stage of the modular migration for Smart Ronda TI. The goal is to fix all broken imports, rename classes for consistency with the new architecture, and ensure all pages are fully functional under the new "SmartRonda TI Constitution".

## Proposed Changes

### [Asset Module]

Fixing inconsistencies in models.

#### [asset_model.dart](file:///C:/Users/fabio/ronda_equipamentos/smart_ronda_ti/lib/features/assets/models/asset_model.dart)
- Fix typo: rename `ultima_ronda_id` to `ultimaRondaId` in `fromMap`.

---

### [Reports Module]

Renaming classes for consistency with the "Repository" naming convention.

#### [export_repository.dart](file:///C:/Users/fabio/ronda_equipamentos/smart_ronda_ti/lib/features/reports/repositories/export_repository.dart)
- Rename `ExportService` class to `ExportRepository`.
- Fix import: `pdf_service.dart` -> `pdf_repository.dart`.
- Update internal calls to `PdfService` to `PdfRepository`.

#### [pdf_repository.dart](file:///C:/Users/fabio/ronda_equipamentos/smart_ronda_ti/lib/features/reports/repositories/pdf_repository.dart)
- Rename `PdfService` class to `PdfRepository`.

---

### [Refactoring Pages]

Updating all pages to use the new modular controllers and models.

#### [main.dart](file:///C:/Users/fabio/ronda_equipamentos/smart_ronda_ti/lib/main.dart)
- Ensure all imports point to the correct locations.
- Verify `AuthWrapper` logic with new controllers.

#### [home_page.dart](file:///C:/Users/fabio/ronda_equipamentos/smart_ronda_ti/lib/features/rounds/pages/home_page.dart)
- Update imports (remove `core/services/` and `core/models/`).
- Replace `AuthService` with `AuthController`.
- Replace `AdminService` with `AdminController`.
- Replace `UsuarioModel` with `UserModel`.
- Replace `PdfService`/`ExportService` with `PdfRepository`/`ExportRepository`.
- Update method calls to match new controller/repository APIs.

#### [ronda_page.dart](file:///C:/Users/fabio/ronda_equipamentos/smart_ronda_ti/lib/features/rounds/pages/ronda_page.dart)
- Update imports.
- Replace `AtivoModel` with `AssetModel`.
- Replace `RondaModel` with `RoundModel`.
- Replace `InventoryService` with `AssetController`.
- Replace `RondaService` with `RoundController`.
- Replace `AdminService` with `AdminController`.
- Update method calls.

#### [dashboard_page.dart](file:///C:/Users/fabio/ronda_equipamentos/smart_ronda_ti/lib/features/dashboard/pages/dashboard_page.dart)
- Final check on imports and field names (e.g., `itensTotal`, `defeitosTotal`).

#### [Other Pages]
- Update `admin_page.dart`, `history_page.dart`, `ronda_details_page.dart`, `login_page.dart`, `about_page.dart`, `log_page.dart` with similar refactorings.

## Verification Plan

### Automated Tests
- Run `flutter analyze` to ensure no errors remain.
- I will use `analyze_file` on each refactored file.

### Manual Verification
- Verify that the app starts and `AuthWrapper` works.
- Check that the `DashboardPage` and `HomePage` load correctly.
- Verify that a round can still be started and finished (logic check).
