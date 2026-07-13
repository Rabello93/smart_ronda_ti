import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart' as ex;

class ReportRepository {
  // --- HELPERS ---
  static Future<pw.MemoryImage?> _fetchLogo(Map<String, dynamic> config) async {
    if (config['logo_url'] != null && config['logo_url'].isNotEmpty) {
      try {
        String url = config['logo_url'];
        if (url.contains("drive.google.com")) {
          final fileId = RegExp(r"d/([^/]+)").firstMatch(url)?.group(1) ?? RegExp(r"id=([^&]+)").firstMatch(url)?.group(1);
          if (fileId != null) url = "https://docs.google.com/uc?export=download&id=$fileId";
        }
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) return pw.MemoryImage(response.bodyBytes);
      } catch (e) {
        debugPrint("Erro logo PDF: $e");
      }
    }
    return null;
  }

  static pw.Widget _buildHeader(Map<String, dynamic> config, String title, pw.MemoryImage? logoImage) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(bottom: 5.0 * PdfPageFormat.mm),
      padding: const pw.EdgeInsets.only(bottom: 2.0 * PdfPageFormat.mm),
      decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(width: 0.5, color: PdfColors.grey))),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(config['nome'] ?? "RONDA TI", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
              pw.Text(title.toUpperCase(), style: const pw.TextStyle(fontSize: 10, color: PdfColors.blue900)),
            ]
          ),
          if (logoImage != null) pw.Image(logoImage, height: 80),
        ]
      )
    );
  }

  static pw.Widget _buildFooter(Map<String, dynamic> config) {
    final now = DateTime.now();
    final dateStr = "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 5.0 * PdfPageFormat.mm),
      padding: const pw.EdgeInsets.only(top: 2.0 * PdfPageFormat.mm),
      decoration: const pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(width: 0.5, color: PdfColors.grey))),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(config['nome'] ?? "SMART RONDA TI", style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
              if (config['cnpj'] != null && config['cnpj'].isNotEmpty)
                pw.Text("CNPJ: ${config['cnpj']}", style: const pw.TextStyle(fontSize: 7)),
              if (config['contato'] != null && config['contato'].isNotEmpty)
                pw.Text("Contato: ${config['contato']}", style: const pw.TextStyle(fontSize: 7)),
            ]
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text("Gerado em: $dateStr", style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
              pw.Text("Smart Ronda TI - Governança de Ativos", style: const pw.TextStyle(fontSize: 6, color: PdfColors.grey500)),
            ]
          ),
        ]
      )
    );
  }

  // --- PDF EXPORTS ---

  static Future<void> exportarLocacaoParaPDF(BuildContext context, List<Map<String, dynamic>> itens, String titulo) async {
    final messenger = (context.mounted) ? ScaffoldMessenger.of(context) : null;
    try {
      final pdf = pw.Document();
      final firestore = FirebaseFirestore.instance;

      DocumentSnapshot configDoc = await firestore.collection('config').doc('empresa').get();
      Map<String, dynamic> config = configDoc.exists ? (configDoc.data() as Map<String, dynamic>) : {};
      
      pw.MemoryImage? logoImage = await _fetchLogo(config);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          header: (pw.Context context) => _buildHeader(config, titulo, logoImage),
          footer: (pw.Context context) => _buildFooter(config),
          build: (pw.Context context) => [
            pw.SizedBox(height: 10),
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo900),
              headers: const ['TIPO', 'PATRIMÔNIO', 'LOCADORA', 'SETOR ATUAL', 'DESCRIÇÃO DEFEITO'],
              data: itens.map((i) => [
                i['tipo'] ?? '',
                i['patrimonio'] ?? (i['serie'] ?? 'S/P'),
                i['locadora'] ?? 'Não inf.',
                i['setor'] ?? '---',
                i['descricao_defeito'] ?? '---',
              ]).toList(),
            ),
            pw.SizedBox(height: 20),
            pw.Container(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                "TOTAL DE ITENS NO RELATÓRIO: ${itens.length}",
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
              ),
            ),
          ],
        ),
      );

      final output = await getTemporaryDirectory();
      final file = File("${output.path}/relatorio_${DateTime.now().millisecondsSinceEpoch}.pdf");
      await file.writeAsBytes(await pdf.save());
      await Share.shareXFiles([XFile(file.path)], text: titulo);
    } catch (e) {
      messenger?.showSnackBar(SnackBar(content: Text("Erro PDF: $e"), backgroundColor: Colors.red));
    }
  }

  static Future<void> exportarRondasParaPDF({
    String? tecnicoId, 
    String? tecnicoNome, 
    String? setor,
    String? locadora,
    String? tipoEquipamento,
    bool? apenasDefeitos,
    bool? apenasSemPatrimonio,
    bool? apenasObsoletos,
    BuildContext? context
  }) async {
    final messenger = (context != null && context.mounted) ? ScaffoldMessenger.of(context) : null;
    try {
      if (context != null && !context.mounted) return;
      final pdf = pw.Document();
      final firestore = FirebaseFirestore.instance;

      DocumentSnapshot configDoc = await firestore.collection('config').doc('empresa').get();
      Map<String, dynamic> config = configDoc.exists ? (configDoc.data() as Map<String, dynamic>) : {};
      
      pw.MemoryImage? logoImage = await _fetchLogo(config);

      Query query = firestore.collection('rondas').orderBy('timestamp', descending: true);
      QuerySnapshot rondasSnapshot = await query.get();

      List<List<String>> tableData = [];
      int currentYear = DateTime.now().year;

      for (var doc in rondasSnapshot.docs) {
        final ronda = doc.data() as Map<String, dynamic>;
        if (tecnicoId != null && ronda['tecnico_id'] != tecnicoId) continue;
        if (setor != null && ronda['setor'] != setor) continue;
        
        QuerySnapshot equipSnapshot = await firestore.collection('rondas').doc(doc.id).collection('equipamentos').get();
        for (var equipDoc in equipSnapshot.docs) {
          final equip = equipDoc.data() as Map<String, dynamic>;
          
          if (locadora != null && equip['locadora'] != locadora) continue;
          if (tipoEquipamento != null && equip['tipo'] != tipoEquipamento) continue;
          if (apenasDefeitos == true && equip['status'] != 'Defeito') continue;
          
          bool semPlaca = equip['sem_patrimonio'] == true || equip['patrimonio']?.toString().toLowerCase().contains("sem patrimônio") == true;
          
          if (apenasSemPatrimonio == true && !semPlaca) continue;

          int? anoFab = equip['ano_fabricacao'];
          int idade = anoFab != null ? (currentYear - anoFab) : 0;
          bool isObsoleto = anoFab != null && (idade >= 5);
          if (apenasObsoletos == true && !isObsoleto) continue;

          tableData.add([
            ronda['data_inicio']?.toString().substring(0, 10) ?? '',
            ronda['setor']?.toString().toUpperCase() ?? '',
            equip['tipo'] ?? '',
            equip['patrimonio'] ?? (equipDoc.id.length > 15 ? 'S/P' : equipDoc.id),
            equip['modelo'] ?? '---',
            equip['locadora'] ?? 'PRÓPRIO',
            isObsoleto ? "SIM ($idade anos)" : 'NÃO',
            (equip['tem_defeito'] == true || equip['status_operacional'] == 'Em manutenção') ? 'SIM' : 'NÃO',
            equip['status_operacional'] ?? (equip['status'] ?? 'OK'),
          ]);
        }
      }

      if (apenasObsoletos == true) {
        QuerySnapshot mestreSnap = await firestore.collection('inventario_mestre').get();
        for (var doc in mestreSnap.docs) {
          final equip = doc.data() as Map<String, dynamic>;
          int? anoFab = equip['ano_fabricacao'];
          int idade = anoFab != null ? (currentYear - anoFab) : 0;
          if (anoFab != null && (idade >= 5)) {
            bool jaExiste = tableData.any((row) => row[3] == doc.id);
            if (!jaExiste) {
              tableData.add([
                'INV. MESTRE',
                equip['setor']?.toString().toUpperCase() ?? '---',
                equip['tipo'] ?? '',
                doc.id,
                equip['processador'] ?? '---',
                equip['mac_address'] ?? '---',
                "SIM ($idade anos)",
                "NÃO", // Defeito
                equip['status_operacional'] ?? 'OK',
              ]);
            }
          }
        }
      }

      if (tableData.isEmpty) {
        messenger?.showSnackBar(const SnackBar(content: Text("Nenhum item encontrado."), backgroundColor: Colors.orange));
        return;
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          header: (pw.Context context) => _buildHeader(config, "RELATÓRIO TÉCNICO", logoImage),
          footer: (pw.Context context) => _buildFooter(config),
          build: (pw.Context context) => [
            pw.SizedBox(height: 10),
            pw.Center(child: pw.Text(apenasObsoletos == true ? "RELATÓRIO DE OBSOLESCÊNCIA (+5 ANOS)" : "AUDITORIA DE RONDAS", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16))),
            pw.SizedBox(height: 20),
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 8),
              cellStyle: const pw.TextStyle(fontSize: 7),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey900),
              headers: const ['DATA', 'SETOR', 'TIPO', 'PATRIMÔNIO', 'MODELO', 'LOCADORA', 'OBSOLETO', 'DEFEITO', 'STATUS'],
              data: tableData,
            ),
            pw.SizedBox(height: 20),
            pw.Container(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                "TOTAL DE REGISTROS NA AUDITORIA: ${tableData.length}",
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
              ),
            ),
          ],
        ),
      );

      final output = await getTemporaryDirectory();
      final file = File("${output.path}/relatorio_${DateTime.now().millisecondsSinceEpoch}.pdf");
      await file.writeAsBytes(await pdf.save());
      await Share.shareXFiles([XFile(file.path)], text: 'Relatório PDF');
    } catch (e) {
      messenger?.showSnackBar(SnackBar(content: Text("Erro PDF: $e"), backgroundColor: Colors.red));
    }
  }

  static Future<void> exportarInventarioParaCSV(List<Map<String, dynamic>> itens, String titulo) async {
    try {
      List<List<dynamic>> rows = [];
      rows.add(["TIPO", "PATRIMONIO", "MARCA", "MODELO", "SERIE", "DEPARTAMENTO", "STATUS", "LOCADO", "LOCADORA", "DEFEITO", "HOME OFFICE", "RESPONSAVEL EXTERNO"]);

      for (var i in itens) {
        rows.add([
          i['tipo'] ?? '',
          i['patrimonio'] ?? '',
          i['marca'] ?? '',
          i['modelo'] ?? '',
          i['serie'] ?? '',
          i['setor'] ?? '',
          i['status_operacional'] ?? '',
          (i['is_locado'] ?? false) ? 'SIM' : 'NAO',
          i['locadora'] ?? 'PROPRIO',
          (i['tem_defeito'] ?? false) ? 'SIM' : 'NAO',
          (i['is_home_office'] ?? false) ? 'SIM' : 'NAO',
          i['responsavel_externo'] ?? '',
        ]);
      }

      String csvData = const ListToCsvConverter(fieldDelimiter: ';').convert(rows);
      final directory = await getTemporaryDirectory();
      final file = File("${directory.path}/relatorio_${DateTime.now().millisecondsSinceEpoch}.csv");
      await file.writeAsBytes([0xEF, 0xBB, 0xBF]); 
      await file.writeAsString(csvData);
      await Share.shareXFiles([XFile(file.path)], text: titulo);
    } catch (e) {
      debugPrint("Erro CSV: $e");
    }
  }

  static Future<void> exportarInventarioParaXLSX(List<Map<String, dynamic>> itens, String titulo) async {
    try {
      var excel = ex.Excel.createExcel();
      ex.Sheet sheet = excel['Inventario'];
      excel.delete('Sheet1');

      ex.CellStyle headerStyle = ex.CellStyle(
        backgroundColorHex: ex.ExcelColor.fromHexString('#1A237E'),
        fontColorHex: ex.ExcelColor.fromHexString('#FFFFFF'),
        bold: true,
        horizontalAlign: ex.HorizontalAlign.Center,
      );

      List<String> headers = ["TIPO", "PATRIMÔNIO", "MARCA", "MODELO", "SÉRIE", "DEPARTAMENTO", "STATUS", "LOCADORA", "DEFEITO", "HOME OFFICE", "RESPONSÁVEL"];
      
      for (int i = 0; i < headers.length; i++) {
        var cell = sheet.cell(ex.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = ex.TextCellValue(headers[i]);
        cell.cellStyle = headerStyle;
      }

      for (int r = 0; r < itens.length; r++) {
        var item = itens[r];
        sheet.cell(ex.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: r + 1)).value = ex.TextCellValue(item['tipo']?.toString() ?? '');
        sheet.cell(ex.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: r + 1)).value = ex.TextCellValue(item['patrimonio']?.toString() ?? '');
        sheet.cell(ex.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: r + 1)).value = ex.TextCellValue(item['marca']?.toString() ?? '');
        sheet.cell(ex.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: r + 1)).value = ex.TextCellValue(item['modelo']?.toString() ?? '');
        sheet.cell(ex.CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: r + 1)).value = ex.TextCellValue(item['serie']?.toString() ?? '');
        sheet.cell(ex.CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: r + 1)).value = ex.TextCellValue(item['setor']?.toString() ?? '');
        sheet.cell(ex.CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: r + 1)).value = ex.TextCellValue(item['status_operacional']?.toString() ?? '');
        sheet.cell(ex.CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: r + 1)).value = ex.TextCellValue(item['locadora']?.toString() ?? 'PRÓPRIO');
        sheet.cell(ex.CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: r + 1)).value = ex.TextCellValue((item['tem_defeito'] == true) ? 'SIM' : 'NÃO');
        sheet.cell(ex.CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: r + 1)).value = ex.TextCellValue((item['is_home_office'] == true) ? 'SIM' : 'NÃO');
        sheet.cell(ex.CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: r + 1)).value = ex.TextCellValue(item['responsavel_externo']?.toString() ?? '');
      }

      final directory = await getTemporaryDirectory();
      var fileBytes = excel.save();
      final file = File("${directory.path}/relatorio_${DateTime.now().millisecondsSinceEpoch}.xlsx")
        ..createSync(recursive: true)
        ..writeAsBytesSync(fileBytes!);

      await Share.shareXFiles([XFile(file.path)], text: titulo);
    } catch (e) {
      debugPrint("Erro XLSX: $e");
    }
  }

  static Future<void> exportarMapaAtivosSetor({required String setor, required List<Map<String, dynamic>> itens, required BuildContext context}) async {
    final messenger = (context.mounted) ? ScaffoldMessenger.of(context) : null;
    try {
      final pdf = pw.Document();
      final firestore = FirebaseFirestore.instance;
      DocumentSnapshot configDoc = await firestore.collection('config').doc('empresa').get();
      Map<String, dynamic> config = configDoc.exists ? (configDoc.data() as Map<String, dynamic>) : {};
      pw.MemoryImage? logoImage = await _fetchLogo(config);

      pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (pw.Context context) => _buildHeader(config, "MAPA DE ATIVOS", logoImage),
        footer: (pw.Context context) => _buildFooter(config),
        build: (pw.Context context) => [
          pw.SizedBox(height: 10),
          pw.Header(level: 0, child: pw.Text("SETOR ${setor.toUpperCase()}")),
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo900),
            headers: const ['TIPO', 'PATRIMÔNIO', 'STATUS OP.', 'LOCADO'],
            data: itens.map((i) => [i['tipo'] ?? '', i['patrimonio'] ?? 'S/P', i['status_operacional'] ?? 'Em uso', (i['is_locado'] ?? false) ? 'Sim' : 'Não']).toList(),
          ),
          pw.SizedBox(height: 20),
          pw.Container(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              "TOTAL DE ATIVOS NO SETOR: ${itens.length}",
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
            ),
          ),
        ]
      ));
      final output = await getTemporaryDirectory();
      final file = File("${output.path}/relatorio_${DateTime.now().millisecondsSinceEpoch}.pdf");
      await file.writeAsBytes(await pdf.save());
      await Share.shareXFiles([XFile(file.path)], text: 'Mapa de Ativos');
    } catch (e) { messenger?.showSnackBar(SnackBar(content: Text("Erro: $e"), backgroundColor: Colors.red)); }
  }

  static Future<void> exportarRelatorioIncidencias({
    required BuildContext context,
    required List<Map<String, dynamic>> dados,
    required DateTimeRange periodo,
  }) async {
    final messenger = (context.mounted) ? ScaffoldMessenger.of(context) : null;
    try {
      final pdf = pw.Document();
      final firestore = FirebaseFirestore.instance;
      DocumentSnapshot configDoc = await firestore.collection('config').doc('empresa').get();
      Map<String, dynamic> config = configDoc.exists ? (configDoc.data() as Map<String, dynamic>) : {};
      pw.MemoryImage? logoImage = await _fetchLogo(config);

      final dateStr = "${DateFormat('dd/MM/yy').format(periodo.start)} - ${DateFormat('dd/MM/yy').format(periodo.end)}";

      pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        header: (pw.Context context) => _buildHeader(config, "ANÁLISE DE INCIDÊNCIAS CRÍTICAS", logoImage),
        footer: (pw.Context context) => _buildFooter(config),
        build: (pw.Context context) => [
          pw.Text("Período de Análise: $dateStr", style: const pw.TextStyle(fontSize: 12)),
          pw.SizedBox(height: 15),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 8),
            cellStyle: const pw.TextStyle(fontSize: 7),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.red900),
            headers: const ['PATRIMÔNIO', 'MODELO', 'DEF.', 'MAN.', 'TEMPO MAN.', 'DIV.', 'H.O.', 'SETOR ATUAL'],
            data: dados.map((d) {
              String tempoMan = '---';
              if (d['data_entrada_manutencao'] != null) {
                final DateTime dt = (d['data_entrada_manutencao'] is Timestamp) 
                    ? (d['data_entrada_manutencao'] as Timestamp).toDate() 
                    : d['data_entrada_manutencao'];
                final diff = DateTime.now().difference(dt);
                tempoMan = "${diff.inDays}d ${diff.inHours % 24}h";
              }

              return [
                d['patrimonio']?.toString() ?? '---',
                d['modelo']?.toString() ?? '---',
                d['count_defeito'].toString(),
                d['count_manutencao'].toString(),
                tempoMan,
                d['count_divergencia'].toString(),
                d['count_home_office'].toString(),
                d['ultimo_setor']?.toString().toUpperCase() ?? '---',
              ];
            }).toList(),
          ),
          pw.SizedBox(height: 20),
          pw.Container(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              "TOTAL DE ATIVOS COM INCIDÊNCIAS: ${dados.length}",
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
            ),
          ),
        ]
      ));

      final output = await getTemporaryDirectory();
      final file = File("${output.path}/relatorio_incidencias_${DateTime.now().millisecondsSinceEpoch}.pdf");
      await file.writeAsBytes(await pdf.save());
      await Share.shareXFiles([XFile(file.path)], text: 'Relatório de Incidências');
    } catch (e) { messenger?.showSnackBar(SnackBar(content: Text("Erro: $e"), backgroundColor: Colors.red)); }
  }

  // --- XML EXPORTS ---

  static Future<void> exportarRondasParaXML({
    String? tecnicoId, 
    String? setor,
    BuildContext? context
  }) async {
    final messenger = (context != null && context.mounted) ? ScaffoldMessenger.of(context) : null;
    try {
      final firestore = FirebaseFirestore.instance;
      QuerySnapshot rondasSnapshot = await firestore.collection('rondas').orderBy('timestamp', descending: true).get();

      StringBuffer xml = StringBuffer();
      xml.writeln('<?xml version="1.0" encoding="UTF-8"?>');
      xml.writeln('<RelatorioRondas>');

      for (var doc in rondasSnapshot.docs) {
        final ronda = doc.data() as Map<String, dynamic>;
        if (tecnicoId != null && ronda['tecnico_id'] != tecnicoId) continue;
        if (setor != null && ronda['setor'] != setor) continue;

        xml.writeln('  <Ronda id="${doc.id}">');
        xml.writeln('    <Data>${ronda['data_inicio']}</Data>');
        xml.writeln('    <Setor>${ronda['setor']}</Setor>');
        xml.writeln('    <Tecnico>${ronda['tecnico']}</Tecnico>');
        xml.writeln('    <Equipamentos>');

        QuerySnapshot equipSnapshot = await firestore.collection('rondas').doc(doc.id).collection('equipamentos').get();
        for (var equipDoc in equipSnapshot.docs) {
          final equip = equipDoc.data() as Map<String, dynamic>;
          xml.writeln('      <Equipamento>');
          xml.writeln('        <Tipo>${equip['tipo']}</Tipo>');
          xml.writeln('        <Patrimonio>${equip['patrimonio'] ?? 'S/P'}</Patrimonio>');
          xml.writeln('        <Status>${equip['status']}</Status>');
          xml.writeln('        <Serie>${equip['serie'] ?? ''}</Serie>');
          xml.writeln('      </Equipamento>');
        }

        xml.writeln('    </Equipamentos>');
        xml.writeln('  </Ronda>');
      }

      xml.writeln('</RelatorioRondas>');

      final output = await getTemporaryDirectory();
      final file = File("${output.path}/relatorio_${DateTime.now().millisecondsSinceEpoch}.xml");
      await file.writeAsString(xml.toString());
      await Share.shareXFiles([XFile(file.path)], text: 'Relatório XML');
    } catch (e) {
      messenger?.showSnackBar(SnackBar(content: Text("Erro XML: $e"), backgroundColor: Colors.red));
    }
  }

  static Future<void> exportarMapaAtivosSetorXML({required String setor, required List<Map<String, dynamic>> itens, required BuildContext context}) async {
    final messenger = (context.mounted) ? ScaffoldMessenger.of(context) : null;
    try {
      StringBuffer xml = StringBuffer();
      xml.writeln('<?xml version="1.0" encoding="UTF-8"?>');
      xml.writeln('<MapaAtivos setor="${setor.toUpperCase()}">');
      for (var i in itens) {
        xml.writeln('  <Ativo>');
        xml.writeln('    <Tipo>${i['tipo'] ?? ''}</Tipo>');
        xml.writeln('    <Patrimonio>${i['patrimonio'] ?? 'S/P'}</Patrimonio>');
        xml.writeln('    <Status>${i['status_operacional'] ?? ''}</Status>');
        xml.writeln('    <Locado>${(i['is_locado'] ?? false) ? 'Sim' : 'Não'}</Locado>');
        xml.writeln('  </Ativo>');
      }
      xml.writeln('</MapaAtivos>');

      final output = await getTemporaryDirectory();
      final file = File("${output.path}/relatorio_${DateTime.now().millisecondsSinceEpoch}.xml");
      await file.writeAsString(xml.toString());
      await Share.shareXFiles([XFile(file.path)], text: 'Mapa de Ativos XML');
    } catch (e) { messenger?.showSnackBar(SnackBar(content: Text("Erro: $e"), backgroundColor: Colors.red)); }
  }

  static Future<void> exportarLogsParaPDF(BuildContext context) async {
    final messenger = context.mounted ? ScaffoldMessenger.of(context) : null;
    try {
      final pdf = pw.Document();
      final firestore = FirebaseFirestore.instance;
      
      DocumentSnapshot configDoc = await firestore.collection('config').doc('empresa').get();
      Map<String, dynamic> config = configDoc.exists ? (configDoc.data() as Map<String, dynamic>) : {};
      pw.MemoryImage? logoImage = await _fetchLogo(config);

      QuerySnapshot logSnapshot = await firestore.collection('logs').orderBy('timestamp', descending: true).get();
      pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (pw.Context context) => _buildHeader(config, "LOGS DO SISTEMA", logoImage),
        footer: (pw.Context context) => _buildFooter(config),
        build: (pw.Context context) => [
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo900),
            headers: const ['Data/Hora', 'Tecnico', 'Acao', 'Detalhes'],
            data: logSnapshot.docs.map((doc) {
              final log = doc.data() as Map<String, dynamic>;
              final date = (log['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
              return ["${date.day}/${date.month}/${date.year}", log['tecnico_nome'] ?? '---', log['acao'] ?? '---', log['detalhes'] ?? '---'];
            }).toList(),
          ),
        ]
      ));
      final output = await getTemporaryDirectory();
      final file = File("${output.path}/relatorio_${DateTime.now().millisecondsSinceEpoch}.pdf");
      await file.writeAsBytes(await pdf.save());
      await Share.shareXFiles([XFile(file.path)], text: 'Logs de Auditoria');
    } catch (e) { messenger?.showSnackBar(SnackBar(content: Text("Erro: $e"), backgroundColor: Colors.red)); }
  }

  static Future<void> exportarRelatorioMetas(BuildContext context, {DateTimeRange? periodo, DateTimeRange? periodoComparativo}) async {
    final messenger = (context.mounted) ? ScaffoldMessenger.of(context) : null;
    try {
      final pdf = pw.Document();
      final firestore = FirebaseFirestore.instance;

      DocumentSnapshot configDoc = await firestore.collection('config').doc('empresa').get();
      Map<String, dynamic> config = configDoc.exists ? (configDoc.data() as Map<String, dynamic>) : {};
      pw.MemoryImage? logoImage = await _fetchLogo(config);

      DocumentSnapshot goalsDoc = await firestore.collection('config').doc('metas').get();
      Map<String, dynamic> goals = goalsDoc.exists ? (goalsDoc.data() as Map<String, dynamic>) : {'rondas_mensal': 100, 'itens_mensal': 500};

      final now = DateTime.now();
      final start = periodo?.start ?? DateTime(now.year, now.month, 1);
      final end = periodo?.end ?? DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      Future<Map<String, int>> fetchPerformance(DateTime start, DateTime end) async {
        QuerySnapshot roundsSnap = await firestore.collection('rondas')
            .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
            .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(end))
            .get();

        int rondas = roundsSnap.docs.length;
        int itens = 0;
        for (var doc in roundsSnap.docs) {
          final data = doc.data() as Map<String, dynamic>;
          itens += (data['itens_total'] as int? ?? 0);
        }
        return {'rondas': rondas, 'itens': itens};
      }

      final perfPrincipal = await fetchPerformance(start, end);
      Map<String, int>? perfComparativoDados;
      if (periodoComparativo != null) {
        perfComparativoDados = await fetchPerformance(periodoComparativo.start, periodoComparativo.end);
      }

      pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (pw.Context context) => _buildHeader(config, "RELATÓRIO DE PERFORMANCE E METAS", logoImage),
        footer: (pw.Context context) => _buildFooter(config),
        build: (pw.Context context) => [
          pw.SizedBox(height: 10),
          pw.Text("Período Principal: ${start.day}/${start.month}/${start.year} - ${end.day}/${end.month}/${end.year}", style: const pw.TextStyle(fontSize: 12)),
          if (periodoComparativo != null)
            pw.Text("Período Comparativo: ${periodoComparativo.start.day}/${periodoComparativo.start.month}/${periodoComparativo.start.year} - ${periodoComparativo.end.day}/${periodoComparativo.end.month}/${periodoComparativo.end.year}", style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey)),
          
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo900),
            headers: perfComparativoDados == null 
              ? const ['INDICADOR', 'META', 'REALIZADO', 'ATINGIMENTO']
              : const ['INDICADOR', 'META', 'PERÍODO 1', 'PERÍODO 2', 'EVOLUÇÃO'],
            data: perfComparativoDados == null 
              ? [
                  [
                    'RONDAS', 
                    '${goals['rondas_mensal']}', 
                    '${perfPrincipal['rondas']}', 
                    '${((perfPrincipal['rondas'] ?? 0) / ((goals['rondas_mensal'] as int?) ?? 1) * 100).toStringAsFixed(1)}%'
                  ],
                  [
                    'ITENS AUDITADOS', 
                    '${goals['itens_mensal']}', 
                    '${perfPrincipal['itens']}', 
                    '${((perfPrincipal['itens'] ?? 0) / ((goals['itens_mensal'] as int?) ?? 1) * 100).toStringAsFixed(1)}%'
                  ],
                ]
              : [
                  [
                    'RONDAS', 
                    '${goals['rondas_mensal']}', 
                    '${perfComparativoDados['rondas']}', 
                    '${perfPrincipal['rondas']}',
                    "${((perfComparativoDados['rondas'] ?? 0) > 0) ? ((((perfPrincipal['rondas']) ?? 0) - (perfComparativoDados['rondas'] ?? 0)) / (perfComparativoDados['rondas'] ?? 1) * 100).toStringAsFixed(1) : '---'}%"
                  ],
                  [
                    'ITENS AUDITADOS', 
                    '${goals['itens_mensal']}', 
                    '${perfComparativoDados['itens']}', 
                    '${perfPrincipal['itens']}',
                    "${((perfComparativoDados['itens'] ?? 0) > 0) ? ((((perfPrincipal['itens']) ?? 0) - (perfComparativoDados['itens'] ?? 0)) / (perfComparativoDados['itens'] ?? 1) * 100).toStringAsFixed(1) : '---'}%"
                  ],
                ],
          ),
        ],
      ));

      final output = await getTemporaryDirectory();
      final file = File("${output.path}/relatorio_${DateTime.now().millisecondsSinceEpoch}.pdf");
      await file.writeAsBytes(await pdf.save());
      await Share.shareXFiles([XFile(file.path)], text: 'Relatório de Metas');
    } catch (e) { messenger?.showSnackBar(SnackBar(content: Text("Erro: $e"), backgroundColor: Colors.red)); }
  }

  static Future<void> exportarRelatorioMetasXML(BuildContext context, {DateTimeRange? periodo}) async {
    final messenger = (context.mounted) ? ScaffoldMessenger.of(context) : null;
    try {
      final firestore = FirebaseFirestore.instance;
      DocumentSnapshot goalsDoc = await firestore.collection('config').doc('metas').get();
      Map<String, dynamic> goals = goalsDoc.exists ? (goalsDoc.data() as Map<String, dynamic>) : {'rondas_mensal': 100, 'itens_mensal': 500};

      final now = DateTime.now();
      final start = periodo?.start ?? DateTime(now.year, now.month, 1);
      final end = periodo?.end ?? DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      QuerySnapshot roundsSnap = await firestore.collection('rondas')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .get();

      int rondasRealizadas = roundsSnap.docs.length;
      int itensVistos = 0;
      
      StringBuffer xml = StringBuffer();
      xml.writeln('<?xml version="1.0" encoding="UTF-8"?>');
      xml.writeln('<PerformanceMetas>');
      xml.writeln('  <Periodo>');
      xml.writeln('    <Inicio>${start.toIso8601String()}</Inicio>');
      xml.writeln('    <Fim>${end.toIso8601String()}</Fim>');
      xml.writeln('  </Periodo>');
      xml.writeln('  <MetasConfiguradas>');
      xml.writeln('    <MetaRondas>${goals['rondas_mensal']}</MetaRondas>');
      xml.writeln('    <MetaItens>${goals['itens_mensal']}</MetaItens>');
      xml.writeln('  </MetasConfiguradas>');
      xml.writeln('  <Realizado>');
      
      for (var doc in roundsSnap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        itensVistos += (data['itens_total'] as int? ?? 0);
        xml.writeln('    <Ronda id="${doc.id}">');
        xml.writeln('      <Data>${data['data_inicio']}</Data>');
        xml.writeln('      <Setor>${data['setor']}</Setor>');
        xml.writeln('      <Itens>${data['itens_total']}</Itens>');
        xml.writeln('    </Ronda>');
      }

      xml.writeln('  </Realizado>');
      xml.writeln('  <Sumario>');
      xml.writeln('    <TotalRondas>$rondasRealizadas</TotalRondas>');
      xml.writeln('    <TotalItens>$itensVistos</TotalItens>');
      xml.writeln('    <AtingimentoRondas>${(rondasRealizadas / (goals['rondas_mensal'] as int) * 100).toStringAsFixed(2)}%</AtingimentoRondas>');
      xml.writeln('    <AtingimentoItens>${(itensVistos / (goals['itens_mensal'] as int) * 100).toStringAsFixed(2)}%</AtingimentoItens>');
      xml.writeln('  </Sumario>');
      xml.writeln('</PerformanceMetas>');

      final output = await getTemporaryDirectory();
      final file = File("${output.path}/relatorio_${DateTime.now().millisecondsSinceEpoch}.xml");
      await file.writeAsString(xml.toString());
      await Share.shareXFiles([XFile(file.path)], text: 'Dados de Metas para Excel');
    } catch (e) { messenger?.showSnackBar(SnackBar(content: Text("Erro: $e"), backgroundColor: Colors.red)); }
  }

  static pw.Widget _bulletPoint(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 5,
            height: 5,
            margin: const pw.EdgeInsets.only(top: 4, right: 8),
            decoration: const pw.BoxDecoration(color: PdfColors.blue900, shape: pw.BoxShape.circle),
          ),
          pw.Expanded(child: pw.Text(text, style: const pw.TextStyle(fontSize: 10))),
        ],
      ),
    );
  }

  static Future<void> exportarPropostaComercial(BuildContext context) async {
    try {
      final pdf = pw.Document();
      final ByteData bytes = await rootBundle.load('assets/logo.png');
      final Uint8List byteList = bytes.buffer.asUint8List();
      final logoImage = pw.MemoryImage(byteList);
      final now = DateTime.now();
      final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(now);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) => [
            // CAPA / CABEÇALHO
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Image(logoImage, height: 100),
                  pw.SizedBox(height: 20),
                  pw.Text("Smart Ronda TI", style: pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                  pw.Text("SOLUÇÃO INTELIGENTE EM GOVERNANÇA DE ATIVOS", style: const pw.TextStyle(fontSize: 11, color: PdfColors.blueGrey700)),
                  pw.SizedBox(height: 30),
                  pw.Divider(thickness: 1, color: PdfColors.grey300),
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            // INTUITO E UTILIDADE
            pw.Text("1. O CONCEITO", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
            pw.SizedBox(height: 10),
            pw.Text(
              "O Smart Ronda TI nasceu da necessidade crítica de transformar a gestão de ativos tecnológicos de um processo passivo e manual em uma operação digital proativa. O intuito é fornecer uma 'fotografia' fiel e em tempo real de todo o parque computacional da instituição.",
              textAlign: pw.TextAlign.justify,
              style: const pw.TextStyle(fontSize: 11, lineSpacing: 1.5),
            ),
            pw.SizedBox(height: 15),
            pw.Text(
              "Como ele pode ser útil?",
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800),
            ),
            pw.SizedBox(height: 8),
            _bulletPoint("Redução de perdas através da rastreabilidade rigorosa de movimentações."),
            _bulletPoint("Identificação automática de equipamentos obsoletos (+5 anos) para planejamento de trocas."),
            _bulletPoint("Monitoramento de 'Equipamentos Críticos' com histórico de manutenções recorrentes."),
            _bulletPoint("Saneamento de inventário físico com tecnologia de busca contextual e QR Code."),

            pw.SizedBox(height: 25),

            // PRINCIPAIS FUNÇÕES
            pw.Text("2. FUNCIONALIDADES CHAVE", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
            pw.SizedBox(height: 10),
            _bulletPoint("Inventário Mestre (O Castelo): Base de dados centralizada e editável para todo o hardware."),
            _bulletPoint("Rondas de Auditoria: Conferência setorizada com status operacional em tempo real."),
            _bulletPoint("Gestão de Ativos Próprios e Locados: Visão unificada de toda a propriedade tecnológica."),
            _bulletPoint("Mapa de Incidências: Relatório preditivo que aponta gargalos técnicos e falhas recorrentes."),
            _bulletPoint("Exportação Avançada: Geração nativa de documentos em PDF, Excel (XLSX), CSV e XML."),
            _bulletPoint("Rastreio de Home Office: Controle jurídico de ativos fora das dependências físicas."),

            pw.SizedBox(height: 25),

            // NÍVEIS DE ACESSO
            pw.Text("3. GOVERNANÇA E SEGURANÇA (NÍVEIS DE ACESSO)", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
            pw.SizedBox(height: 10),
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blue900),
              cellStyle: const pw.TextStyle(fontSize: 9),
              headers: ['PERFIL', 'DESCRIÇÃO DAS ATRIBUIÇÕES'],
              data: [
                ['MASTER', 'Controle total do ecossistema, gestão de usuários, branding da empresa e reset de banco de dados.'],
                ['GERENTE', 'Acesso completo ao Dashboard de BI, relatórios estratégicos e aprovação de novos técnicos.'],
                ['NORMAL', 'Execução de rondas operacionais em campo, registro de defeitos e consulta de histórico.'],
                ['ESPECTADOR', 'Acesso exclusivo para visualização de indicadores e KPIs (Ideal para conselhos e diretoria).'],
              ],
            ),

            pw.Spacer(),

            // RODAPÉ PROFISSIONAL
            pw.Divider(thickness: 0.5, color: PdfColors.grey300),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text("Desenvolvido por Fabio Rabelo", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                    pw.Text("Especialista em Governança de TI", style: const pw.TextStyle(fontSize: 8)),
                    pw.Text("Contato: fabiorabelosilva93@outlook.com", style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text("Gerado em: $dateStr", style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                    pw.Text("Smart Ronda TI v3.2.5", style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                  ],
                ),
              ],
            ),
          ],
        ),
      );

      final output = await getTemporaryDirectory();
      final file = File("${output.path}/proposta_comercial_smart_ronda.pdf");
      await file.writeAsBytes(await pdf.save());
      await Share.shareXFiles([XFile(file.path)], text: 'Proposta Comercial Smart Ronda TI');
    } catch (e) {
      debugPrint("Erro ao gerar proposta: $e");
    }
  }
}
