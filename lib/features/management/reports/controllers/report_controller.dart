import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../repositories/report_repository.dart';

class ReportController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> gerarRelatorioInventario({
    required BuildContext context,
    String? setor,
    String? locadora,
    String? tipo,
    bool apenasDefeitos = false,
    bool apenasObsoletos = false,
    bool emManutencao = false,
    bool emDivergencia = false,
    bool reservados = false,
    bool apenasHomeOffice = false,
    bool apenasLocados = false,
    bool apenasSemPatrimonio = false,
    required String formato,
  }) async {
    try {
      Query query = _firestore.collection('inventario_mestre');

      if (setor != null) query = query.where('setor', isEqualTo: setor);
      
      final snapshot = await query.get();
      var itens = snapshot.docs.map((d) {
        final data = d.data() as Map<String, dynamic>;
        return {...data, 'patrimonio': d.id};
      }).toList();

      if (apenasLocados) {
        itens = itens.where((i) => i['is_locado'] == true).toList();
        if (locadora != null) {
          itens = itens.where((i) => i['locadora'] == locadora).toList();
        }
      }

      if (apenasSemPatrimonio) {
        itens = itens.where((i) => i['sem_patrimonio'] == true || i['patrimonio'].toString().startsWith("SP_")).toList();
      }

      if (tipo != null) {
        itens = itens.where((i) => i['tipo'] == tipo).toList();
      }

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
      if (apenasSemPatrimonio) tags.add("SEM PATRIMÔNIO");

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

  Future<void> gerarRelatorioIncidencias(BuildContext context, {required DateTimeRange periodo}) async {
    try {
      final QuerySnapshot rondasSnap = await _firestore.collection('rondas')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(periodo.start))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(periodo.end))
          .get();

      Map<String, Map<String, dynamic>> agregador = {};

      for (var doc in rondasSnap.docs) {
        final QuerySnapshot equipsSnap = await doc.reference.collection('equipamentos').get();
        
        for (var eDoc in equipsSnap.docs) {
          final data = eDoc.data() as Map<String, dynamic>;
          if (data['is_troca'] == true) continue;

          final String pat = data['patrimonio'] ?? eDoc.id;
          
          if (!agregador.containsKey(pat)) {
            agregador[pat] = {
              'patrimonio': pat,
              'tipo': data['tipo'] ?? '---',
              'modelo': data['modelo'] ?? '---',
              'count_defeito': 0,
              'count_manutencao': 0,
              'count_divergencia': 0,
              'count_home_office': 0,
              'ultimo_status': data['status_operacional'] ?? 'OK',
              'ultimo_setor': data['setor'] ?? '---',
            };
          }

          if (data['tem_defeito'] == true) {
            agregador[pat]!['count_defeito']++;
          }
          if (data['status_operacional'] == 'Em manutenção') {
            agregador[pat]!['count_manutencao']++;
          }
          if (data['setor_divergente'] == true) {
            agregador[pat]!['count_divergencia']++;
          }
          if (data['is_home_office'] == true) {
            agregador[pat]!['count_home_office']++;
          }
          
          // Atualiza com o dado mais recente da ronda (como as rondas vêm ordenadas por tempo, o loop pega o rastro)
          agregador[pat]!['ultimo_status'] = data['status_operacional'] ?? 'OK';
          agregador[pat]!['ultimo_setor'] = data['setor'] ?? '---';
        }
      }

      // Filtra apenas itens que tiveram pelo menos uma incidência
      final listaFinal = agregador.values.where((item) => 
        item['count_manutencao'] > 0 || 
        item['count_divergencia'] > 0 || 
        item['count_home_office'] > 0
      ).toList();

      // Ordena por maior número de manutenções
      listaFinal.sort((a, b) => b['count_manutencao'].compareTo(a['count_manutencao']));

      if (context.mounted) {
        if (listaFinal.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nenhuma incidência crítica encontrada no período.")));
          return;
        }
        await ReportRepository.exportarRelatorioIncidencias(
          context: context, 
          dados: listaFinal, 
          periodo: periodo
        );
      }
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro: $e"), backgroundColor: Colors.red));
    }
  }
}
