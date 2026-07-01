import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../repositories/report_repository.dart';

class ReportController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> gerarRelatorioInventario({
    required BuildContext context,
    String? setor,
    bool apenasDefeitos = false,
    bool apenasObsoletos = false,
    bool emManutencao = false,
    bool emDivergencia = false,
    bool reservados = false,
    bool apenasHomeOffice = false,
    required String formato,
  }) async {
    try {
      Query query = _firestore.collection('inventario_mestre');

      if (setor != null) query = query.where('setor', isEqualTo: setor);
      if (apenasDefeitos) query = query.where('tem_defeito', isEqualTo: true);
      if (emManutencao) query = query.where('status_operacional', isEqualTo: 'Em manutenção');
      if (reservados) query = query.where('status_operacional', isEqualTo: 'Reservado');
      if (emDivergencia) query = query.where('setor_divergente', isEqualTo: true);
      if (apenasHomeOffice) query = query.where('is_home_office', isEqualTo: true);

      final snapshot = await query.get();
      var itens = snapshot.docs.map((d) {
        final data = d.data() as Map<String, dynamic>;
        return {...data, 'patrimonio': d.id};
      }).toList();

      if (apenasObsoletos) {
        final int currentYear = DateTime.now().year;
        itens = itens.where((i) {
          int? ano = i['ano_fabricacao'];
          return ano != null && (currentYear - ano >= 5);
        }).toList();
      }

      if (itens.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Nenhum item encontrado com estes filtros."))
          );
        }
        return;
      }

      // Construção do Título Dinâmico
      String titulo = "Relatório de Inventário";
      List<String> filtros = [];
      if (setor != null) filtros.add(setor.toUpperCase());
      if (apenasObsoletos) filtros.add("OBSOLETOS");
      if (apenasDefeitos) filtros.add("COM DEFEITO");
      if (emManutencao) filtros.add("EM MANUTENÇÃO");
      if (emDivergencia) filtros.add("DIVERGENTES");
      if (reservados) filtros.add("RESERVADOS");
      if (apenasHomeOffice) filtros.add("HOME OFFICE");

      if (filtros.isEmpty) {
        titulo += " Geral";
      } else {
        titulo += ": ${filtros.join(' - ')}";
      }

      if (context.mounted) {
        if (formato == 'PDF') {
          await ReportRepository.exportarLocacaoParaPDF(
            context, 
            itens, 
            titulo
          );
        } else {
          await ReportRepository.exportarMapaAtivosSetorXML(
            setor: setor ?? "GERAL", 
            itens: itens, 
            context: context
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao gerar: $e"), backgroundColor: Colors.red)
        );
      }
    }
  }

  Future<void> gerarRelatorioMetas(BuildContext context, {DateTimeRange? periodo, DateTimeRange? periodoComparativo, required String formato}) async {
    if (formato == 'PDF') {
      await ReportRepository.exportarRelatorioMetas(context, periodo: periodo, periodoComparativo: periodoComparativo);
    } else {
      await ReportRepository.exportarRelatorioMetasXML(context, periodo: periodo);
    }
  }
}
