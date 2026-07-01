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
              pw.Text(config['nome'] ?? "RONDA TI", style: const pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
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
              pw.Text(config['nome'] ?? "SMART RONDA TI", style: const pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
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
              headerStyle: const pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo900),
              headers: const ['TIPO', 'PATRIMÔNIO', 'LOCADORA', 'SETOR ATUAL'],
              data: itens.map((i) => [
                i['tipo'] ?? '',
                i['patrimonio'] ?? (i['serie'] ?? 'S/P'),
                i['locadora'] ?? 'Não inf.',
                i['setor'] ?? '---',
              ]).toList(),
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
          if (apenasSemPatrimonio == false && semPlaca) continue;

          int? anoFab = equip['ano_fabricacao'];
          int idade = anoFab != null ? (currentYear - anoFab) : 0;
          bool isObsoleto = anoFab != null && (idade >= 5);
          if (apenasObsoletos == true && !isObsoleto) continue;

          tableData.add([
            ronda['data_inicio']?.toString().substring(0, 10) ?? '',
            ronda['setor']?.toString().toUpperCase() ?? '',
            equip['tipo'] ?? '',
            equip['patrimonio'] ?? 'S/P',
            equip['processador'] ?? '---',
            equip['mac_address'] ?? '---',
            isObsoleto ? "SIM ($idade anos)" : 'NÃO',
            equip['status'] ?? '',
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
            pw.Center(child: pw.Text(apenasObsoletos == true ? "RELATÓRIO DE OBSOLESCÊNCIA (+5 ANOS)" : "AUDITORIA DE RONDAS", style: const pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16))),
            pw.SizedBox(height: 20),
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 8),
              cellStyle: const pw.TextStyle(fontSize: 7),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey900),
              headers: const ['DATA', 'SETOR', 'TIPO', 'PATRIMÔNIO', 'CPU', 'MAC', 'OBSOLETO', 'STATUS'],
              data: tableData,
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
          pw.Header(level: 0, child: pw.Text("SETOR ${setor.toUpperCase()}")),
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo900),
            headers: const ['TIPO', 'PATRIMÔNIO', 'STATUS OP.', 'LOCADO'],
            data: itens.map((i) => [i['tipo'] ?? '', i['patrimonio'] ?? 'S/P', i['status_operacional'] ?? 'Em uso', (i['is_locado'] ?? false) ? 'Sim' : 'Não']).toList(),
          ),
        ]
      ));
      final output = await getTemporaryDirectory();
      final file = File("${output.path}/relatorio_${DateTime.now().millisecondsSinceEpoch}.pdf");
      await file.writeAsBytes(await pdf.save());
      await Share.shareXFiles([XFile(file.path)], text: 'Mapa de Ativos');
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

  // --- OTHERS ---

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

  static Future<void> exportarPropostaComercial(BuildContext context) async {
    try {
      final pdf = pw.Document();
      
      // Carrega a logo do assets
      final ByteData bytes = await rootBundle.load('assets/logo.png');
      final Uint8List byteList = bytes.buffer.asUint8List();
      final logoImage = pw.MemoryImage(byteList);

      final now = DateTime.now();
      final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(now);

      pdf.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => pw.Column(
          children: [
            pw.Expanded(
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Image(logoImage, height: 120),
                  pw.SizedBox(height: 30),
                  pw.Text("Smart Ronda TI", style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                  pw.Text("SOLUÇÃO EM GOVERNANÇA E AUDITORIA DE ATIVOS", style: const pw.TextStyle(fontSize: 12, color: PdfColors.blueGrey700)),
                  pw.SizedBox(height: 50),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(20),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey100,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                    ),
                    child: pw.Text(
                      "O Smart Ronda TI é uma solução definitiva para instituições que buscam excelência na governança de seus ativos tecnológicos. O sistema foi projetado para transformar o processo manual de conferência em uma operação digital inteligente, garantindo transparência, redução de perdas e suporte estratégico para novos investimentos em infraestrutura.",
                      textAlign: pw.TextAlign.center,
                      style: const pw.TextStyle(fontSize: 11, lineSpacing: 1.5),
                    ),
                  ),
                  pw.SizedBox(height: 40),
                  pw.Align(
                    alignment: pw.Alignment.centerLeft,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text("PRINCIPAIS FUNCIONALIDADES:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13, color: PdfColors.blue900)),
                        pw.SizedBox(height: 15),
                        _bulletPoint("Gestão completa de ativos de TI com Inventário Mestre."),
                        _bulletPoint("Auditoria de rondas técnicas em campo com sincronização real-time."),
                        _bulletPoint("Controle rigoroso de equipamentos próprios e locados."),
                        _bulletPoint("Análise inteligente de obsolescência (+5 anos) e saúde do parque."),
                        _bulletPoint("Relatórios executivos e operacionais (PDF, CSV, XML)."),
                        _bulletPoint("Segurança avançada com autenticação biométrica."),
                        _bulletPoint("Níveis de Acesso: Master, Gerente e Espectador (Acesso exclusivo ao Dashboard)."),
                      ]
                    )
                  ),
                ]
              )
            ),
            // Rodapé customizado do desenvolvedor
            pw.Container(
              padding: const pw.EdgeInsets.only(top: 10),
              decoration: const pw.BoxDecoration(
                border: pw.Border(top: pw.BorderSide(width: 0.5, color: PdfColors.grey300)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text("Desenvolvedor: Fabio Rabelo", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      pw.Text("Contato: fabiorabelosilva93@outlook.com", style: const pw.TextStyle(fontSize: 8)),
                    ]
                  ),
                  pw.Text("Gerado em: $dateStr", style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                ]
              )
            ),
          ]
        )
      ));

      final output = await getTemporaryDirectory();
      final file = File("${output.path}/relatorio_${DateTime.now().millisecondsSinceEpoch}.pdf");
      await file.writeAsBytes(await pdf.save());
      await Share.shareXFiles([XFile(file.path)], text: 'Apresentação Comercial Smart Ronda TI');
    } catch (e) { debugPrint("Erro ao gerar proposta: $e"); }
  }

  static pw.Widget _bulletPoint(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text("  • ", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Expanded(child: pw.Text(text, style: const pw.TextStyle(fontSize: 10))),
        ]
      )
    );
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
      Map<String, int>? perfComparativo;
      if (periodoComparativo != null) {
        perfComparativo = await fetchPerformance(periodoComparativo.start, periodoComparativo.end);
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
            headers: periodoComparativo == null 
              ? const ['INDICADOR', 'META', 'REALIZADO', 'ATINGIMENTO']
              : const ['INDICADOR', 'META', 'PERÍODO 1', 'PERÍODO 2', 'EVOLUÇÃO'],
            data: periodoComparativo == null 
              ? [
                  [
                    'RONDAS', 
                    '${goals['rondas_mensal']}', 
                    '${perfPrincipal['rondas']}', 
                    '${((perfPrincipal['rondas'] ?? 0) / (goals['rondas_mensal'] ?? 1) * 100).toStringAsFixed(1)}%'
                  ],
                  [
                    'ITENS AUDITADOS', 
                    '${goals['itens_mensal']}', 
                    '${perfPrincipal['itens']}', 
                    '${((perfPrincipal['itens'] ?? 0) / (goals['itens_mensal'] ?? 1) * 100).toStringAsFixed(1)}%'
                  ],
                ]
              : [
                  [
                    'RONDAS', 
                    '${goals['rondas_mensal']}', 
                    '${perfComparativo!['rondas']}', 
                    '${perfPrincipal['rondas']}',
                    "${(perfComparativo!['rondas'] ?? 0) > 0 ? (((perfPrincipal['rondas'] ?? 0) - (perfComparativo!['rondas'] ?? 0)) / (perfComparativo!['rondas'] ?? 1) * 100).toStringAsFixed(1) : '---'}%"
                  ],
                  [
                    'ITENS AUDITADOS', 
                    '${goals['itens_mensal']}', 
                    '${perfComparativo!['itens']}', 
                    '${perfPrincipal['itens']}',
                    "${(perfComparativo!['itens'] ?? 0) > 0 ? (((perfPrincipal['itens'] ?? 0) - (perfComparativo!['itens'] ?? 0)) / (perfComparativo!['itens'] ?? 1) * 100).toStringAsFixed(1) : '---'}%"
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
      xml.writeln('    <AtingimentoRondas>${(rondasRealizadas / goals['rondas_mensal'] * 100).toStringAsFixed(2)}%</AtingimentoRondas>');
      xml.writeln('    <AtingimentoItens>${(itensVistos / goals['itens_mensal'] * 100).toStringAsFixed(2)}%</AtingimentoItens>');
      xml.writeln('  </Sumario>');
      xml.writeln('</PerformanceMetas>');

      final output = await getTemporaryDirectory();
      final file = File("${output.path}/relatorio_${DateTime.now().millisecondsSinceEpoch}.xml");
      await file.writeAsString(xml.toString());
      await Share.shareXFiles([XFile(file.path)], text: 'Dados de Metas para Excel');
    } catch (e) { messenger?.showSnackBar(SnackBar(content: Text("Erro: $e"), backgroundColor: Colors.red)); }
  }
}
