import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ReportRepository {
  // --- PDF EXPORTS ---

  static Future<void> exportarLocacaoParaPDF(BuildContext context, List<Map<String, dynamic>> itens, String titulo) async {
    final messenger = (context.mounted) ? ScaffoldMessenger.of(context) : null;
    try {
      final pdf = pw.Document();
      final firestore = FirebaseFirestore.instance;

      DocumentSnapshot configDoc = await firestore.collection('config').doc('empresa').get();
      Map<String, dynamic> config = configDoc.exists ? (configDoc.data() as Map<String, dynamic>) : {};
      
      pw.MemoryImage? logoImage;
      if (config['logo_url'] != null && config['logo_url'].isNotEmpty) {
        try {
          String url = config['logo_url'];
          if (url.contains("drive.google.com")) {
            final fileId = RegExp(r"d/([^/]+)").firstMatch(url)?.group(1) ?? RegExp(r"id=([^&]+)").firstMatch(url)?.group(1);
            if (fileId != null) url = "https://docs.google.com/uc?export=download&id=$fileId";
          }
          final response = await http.get(Uri.parse(url));
          if (response.statusCode == 200) logoImage = pw.MemoryImage(response.bodyBytes);
        } catch (e) {
          debugPrint("Erro logo PDF: $e");
        }
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          header: (pw.Context context) => pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(bottom: 5.0 * PdfPageFormat.mm),
            decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(width: 0.5, color: PdfColors.grey))),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(config['nome'] ?? "RONDA TI", style: const pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                    pw.Text(titulo.toUpperCase(), style: const pw.TextStyle(fontSize: 10, color: PdfColors.blue900)),
                  ]
                ),
                if (logoImage != null) pw.Image(logoImage, height: 35),
              ]
            )
          ),
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
      final file = File("${output.path}/Relatorio_Locacao_${DateTime.now().millisecondsSinceEpoch}.pdf");
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
      
      pw.MemoryImage? logoImage;
      if (config['logo_url'] != null && config['logo_url'].isNotEmpty) {
        try {
          String url = config['logo_url'];
          if (url.contains("drive.google.com")) {
            final fileId = RegExp(r"d/([^/]+)").firstMatch(url)?.group(1) ?? RegExp(r"id=([^&]+)").firstMatch(url)?.group(1);
            if (fileId != null) url = "https://docs.google.com/uc?export=download&id=$fileId";
          }
          final response = await http.get(Uri.parse(url));
          if (response.statusCode == 200) logoImage = pw.MemoryImage(response.bodyBytes);
        } catch (e) {
          debugPrint("Erro logo PDF: $e");
        }
      }

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
          header: (pw.Context context) => pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(bottom: 3.0 * PdfPageFormat.mm),
            decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(width: 0.5, color: PdfColors.grey))),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(config['nome'] ?? "RONDA TI", style: const pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                    pw.Text("RELATÓRIO TÉCNICO", style: const pw.TextStyle(fontSize: 10, color: PdfColors.blue900)),
                  ]
                ),
                if (logoImage != null) pw.Image(logoImage, height: 35),
              ]
            )
          ),
          build: (pw.Context context) => [
            pw.SizedBox(height: 10),
            pw.Center(child: pw.Text(apenasObsoletos == true ? "RELATÓRIO DE OBSOLESCÊNCIA (+5 ANOS)" : "AUDITORIA DE RONDAS", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16))),
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
      final file = File("${output.path}/Relatorio_${DateTime.now().millisecondsSinceEpoch}.pdf");
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
      pdf.addPage(pw.MultiPage(pageFormat: PdfPageFormat.a4, build: (pw.Context context) => [
        pw.Header(level: 0, child: pw.Text("MAPA DE ATIVOS - SETOR ${setor.toUpperCase()}")),
        pw.TableHelper.fromTextArray(
          headers: const ['TIPO', 'PATRIMÔNIO', 'STATUS OP.', 'LOCADO'],
          data: itens.map((i) => [i['tipo'] ?? '', i['patrimonio'] ?? 'S/P', i['status_operacional'] ?? 'Em uso', (i['is_locado'] ?? false) ? 'Sim' : 'Não']).toList(),
        ),
      ]));
      final output = await getTemporaryDirectory();
      final file = File("${output.path}/Mapa_$setor.pdf");
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
          xml.writeln('        <Série>${equip['serie'] ?? ''}</Série>');
          xml.writeln('      </Equipamento>');
        }

        xml.writeln('    </Equipamentos>');
        xml.writeln('  </Ronda>');
      }

      xml.writeln('</RelatorioRondas>');

      final output = await getTemporaryDirectory();
      final file = File("${output.path}/Relatorio_${DateTime.now().millisecondsSinceEpoch}.xml");
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
      final file = File("${output.path}/Mapa_$setor.xml");
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
      QuerySnapshot logSnapshot = await firestore.collection('logs').orderBy('timestamp', descending: true).get();
      pdf.addPage(pw.MultiPage(pageFormat: PdfPageFormat.a4, build: (pw.Context context) => [
        pw.Header(level: 0, child: pw.Text("Auditoria - Logs do Sistema")),
        pw.SizedBox(height: 20),
        pw.TableHelper.fromTextArray(
          headers: const ['Data/Hora', 'Tecnico', 'Acao', 'Detalhes'],
          data: logSnapshot.docs.map((doc) {
            final log = doc.data() as Map<String, dynamic>;
            final date = (log['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
            return ["${date.day}/${date.month}/${date.year}", log['tecnico_nome'] ?? '---', log['acao'] ?? '---', log['detalhes'] ?? '---'];
          }).toList(),
        ),
      ]));
      final output = await getTemporaryDirectory();
      final file = File("${output.path}/Logs_${DateTime.now().millisecondsSinceEpoch}.pdf");
      await file.writeAsBytes(await pdf.save());
      await Share.shareXFiles([XFile(file.path)], text: 'Logs de Auditoria');
    } catch (e) { messenger?.showSnackBar(SnackBar(content: Text("Erro: $e"), backgroundColor: Colors.red)); }
  }

  static Future<void> exportarPropostaComercial(BuildContext context) async {
    try {
      final pdf = pw.Document();
      pdf.addPage(pw.Page(build: (pw.Context context) => pw.Center(child: pw.Text("APRESENTAÇÃO COMERCIAL RONDA TI"))));
      final output = await getTemporaryDirectory();
      final file = File("${output.path}/Proposta_RondaTI.pdf");
      await file.writeAsBytes(await pdf.save());
      await Share.shareXFiles([XFile(file.path)]);
    } catch (e) { debugPrint("Erro: $e"); }
  }
}
