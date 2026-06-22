import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ronda_ti/main.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  // Inicializa o banco de dados para testes
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  testWidgets('Teste de carregamento da Home e adição de setor', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const RondaTIApp());

    // Verifica se o título aparece
    expect(find.text('Ronda TI'), findsOneWidget);

    // Tenta encontrar o campo de texto de novo setor
    final textField = find.byType(TextField);
    expect(textField, findsOneWidget);

    // Digita um novo setor
    await tester.enterText(textField, 'Setor Teste');
    
    // Clica no botão de adicionar (ícone add no suffixIcon)
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
  });
}
