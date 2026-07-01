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

      // Aplica filtro de setor na query se selecionado
      if (setor != null) {
        query = query.where('setor', isEqualTo: setor);
      }

      final snapshot = await query.get();
      var itens = snapshot.docs.map((d) {
        final data = d.data() as Map<String, dynamic>;
        return {...data, 'patrimonio': d.id};
      }).toList();

      // Filtra em memória para permitir combinações complexas sem necessidade de múltiplos índices compostos
      if (apenasDefeitos) {
        itens = itens.where((i) => i['tem_defeito'] == true).toList();
      }
      
      // Se selecionou Manutenção OU Reservados, ele quer ambos (Lógica OR para status)
      if (emManutencao || reservados) {
        itens = itens.where((i) {
          final status = i['status_operacional'];
          bool match = false;
          if (emManutencao && status == 'Em manutenção') match = true;
          if (reservados && status == 'Reservado') match = true;
          return match;
        }).toList();
      }

      if (emDivergencia) {
        itens = itens.where((i) => i['setor_divergente'] == true).toList();
      }

      if (apenasHomeOffice) {
        itens = itens.where((i) => i['is_home_office'] == true).toList();
      }

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

      // Construção do Título Dinâmico (Executivo)
      String titulo = "Relatório de Inventário";
      List<String> tags = [];
      if (setor != null) tags.add(setor.toUpperCase());
      if (apenasObsoletos) tags.add("OBSOLETOS");
      if (apenasDefeitos) tags.add("COM DEFEITO");
      if (emManutencao) tags.add("MANUTENÇÃO");
      if (emDivergencia) tags.add("DIVERGENTES");
      if (reservados) tags.add("RESERVADOS");
      if (apenasHomeOffice) tags.add("HOME OFFICE");

      if (tags.isEmpty) {
        titulo += " Geral";
      } else {
        titulo += ": ${tags.join(' - ')}";
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
