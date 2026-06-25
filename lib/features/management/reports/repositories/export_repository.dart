import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'report_repository.dart';

class ExportRepository {
  static Future<void> exportarPDFGenerico(BuildContext context, List<Map<String, dynamic>> itens, String titulo) async {
    await ReportRepository.exportarLocacaoParaPDF(context, itens, titulo);
  }

  static Future<void> exportarXMLGenerico(BuildContext context, List<Map<String, dynamic>> itens, String setor) async {
    await ReportRepository.exportarMapaAtivosSetorXML(setor: setor, itens: itens, context: context);
  }

  static Future<void> exportarRondasParaCSV({
    String? tecnicoId, 
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
      final firestore = FirebaseFirestore.instance;
      Query query = firestore.collection('rondas').orderBy('timestamp', descending: true);
      QuerySnapshot rondasSnapshot = await query.get();

      List<List<dynamic>> rows = [];
      rows.add(["Data", "Setor", "Responsável", "Tipo", "Patrimônio", "Marca", "Modelo", "Nº Série", "CPU", "MAC", "Obsoleto", "Status", "Locado", "Locadora", "Observação"]);

      int currentYear = DateTime.now().year;

      for (var doc in rondasSnapshot.docs) {
        Map<String, dynamic> ronda = doc.data() as Map<String, dynamic>;
        if (tecnicoId != null && ronda['tecnico_id'] != tecnicoId) continue;
        if (setor != null && ronda['setor'] != setor) continue;
        QuerySnapshot equipSnapshot = await firestore.collection('rondas').doc(doc.id).collection('equipamentos').get();

        for (var equipDoc in equipSnapshot.docs) {
          Map<String, dynamic> equip = equipDoc.data() as Map<String, dynamic>;
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

          rows.add([
            ronda['data_inicio']?.toString().substring(0, 10) ?? '',
            ronda['setor'] ?? '',
            ronda['tecnico'] ?? '',
            equip['tipo'] ?? '',
            equip['patrimonio'] ?? '',
            equip['marca'] ?? '',
            equip['modelo'] ?? '',
            equip['serie'] ?? '',
            equip['processador'] ?? '',
            equip['mac_address'] ?? '',
            isObsoleto ? "SIM ($idade anos)" : 'NÃO',
            equip['status'] ?? '',
            (equip['is_locado'] ?? false) ? 'Sim' : 'Não',
            equip['locadora'] ?? '-',
            equip['observacao'] ?? ''
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
            bool jaExiste = rows.any((row) => row[4] == doc.id);
            if (!jaExiste) {
              rows.add([
                'INV. MESTRE',
                equip['setor'] ?? '---',
                'SISTEMA',
                equip['tipo'] ?? '',
                doc.id,
                equip['marca'] ?? '',
                equip['modelo'] ?? '',
                equip['serie'] ?? '',
                equip['processador'] ?? '---',
                equip['mac_address'] ?? '---',
                "SIM ($idade anos)",
                equip['status_operacional'] ?? 'OK',
                (equip['is_locado'] ?? false) ? 'Sim' : 'Não',
                equip['locadora'] ?? '-',
                'Exportado via Auditoria de Ciclo de Vida'
              ]);
            }
          }
        }
      }

      if (rows.length == 1) {
        messenger?.showSnackBar(const SnackBar(content: Text("Nenhum item corresponde aos filtros."), backgroundColor: Colors.orange));
        return;
      }

      String csvData = const ListToCsvConverter(fieldDelimiter: ';').convert(rows);
      final directory = await getTemporaryDirectory();
      final file = File("${directory.path}/Relatorio_${DateTime.now().millisecondsSinceEpoch}.csv");
      await file.writeAsBytes([0xEF, 0xBB, 0xBF]); // UTF-8 BOM
      await file.writeAsString(csvData);
      await Share.shareXFiles([XFile(file.path)], text: 'Exportação CSV');
    } catch (e) { messenger?.showSnackBar(SnackBar(content: Text("Erro CSV: $e"), backgroundColor: Colors.red)); }
  }
}
