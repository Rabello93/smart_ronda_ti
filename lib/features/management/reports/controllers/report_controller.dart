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

      // Lógica de Filtros Combinados (União de Condições)
      final bool temFiltroCondicao = apenasDefeitos || apenasObsoletos || emManutencao || emDivergencia || reservados || apenasHomeOffice;

      if (temFiltroCondicao) {
        itens = itens.where((i) {
          bool condicaoMatch = false;
          
          if (apenasDefeitos && i['tem_defeito'] == true) condicaoMatch = true;
          
          if (apenasObsoletos) {
            int? ano = i['ano_fabricacao'];
            if (ano != null && (DateTime.now().year - ano >= 5)) condicaoMatch = true;
          }
          
          final status = i['status_operacional'];
          if (emManutencao && status == 'Em manutenção') condicaoMatch = true;
          if (reservados && status == 'Reservado') condicaoMatch = true;
          if (emDivergencia && i['setor_divergente'] == true) condicaoMatch = true;
          if (apenasHomeOffice && i['is_home_office'] == true) condicaoMatch = true;
          
          return condicaoMatch;
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
