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
          if (apenasHomeOffice && i['home_office_autorizado'] == true) condicaoMatch = true;
          
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
        } else if (formato == 'CSV') {
          await ReportRepository.exportarInventarioParaCSV(itens, titulo);
        } else if (formato == 'XLSX') {
          await ReportRepository.exportarInventarioParaXLSX(itens, titulo);
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
    } else if (formato == 'XLSX') {
      await ReportRepository.exportarRelatorioMetasXLSX(context, periodo: periodo);
    } else {
      await ReportRepository.exportarRelatorioMetasXML(context, periodo: periodo);
    }
  }

  Future<void> gerarRelatorioIncidencias(BuildContext context, {
    required DateTimeRange periodo, 
    String? setor, 
    String? locadora,
    String formato = 'PDF',
  }) async {
    try {
      Query queryRondas = _firestore.collection('rondas')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(periodo.start))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(periodo.end));
      
      if (setor != null) queryRondas = queryRondas.where('setor', isEqualTo: setor);

      final QuerySnapshot rondasSnap = await queryRondas.orderBy('timestamp', descending: false).get();

      Map<String, Map<String, dynamic>> agregador = {};

      for (var doc in rondasSnap.docs) {
        final rondaData = doc.data() as Map<String, dynamic>;
        final DateTime roundTimestamp = (rondaData['timestamp'] as Timestamp).toDate();
        final QuerySnapshot equipsSnap = await doc.reference.collection('equipamentos').get();
        
        for (var eDoc in equipsSnap.docs) {
          final data = eDoc.data() as Map<String, dynamic>;
          
          if (locadora != null && data['locadora'] != locadora) continue;

          final String patRaw = (data['patrimonio'] ?? '').toString();
          final String serieRaw = (data['serie'] ?? '').toString();
          final String macRaw = (data['mac_address'] ?? '').toString();
          
          String normalizedPat = patRaw;
          if (patRaw == "SEM PATRIMÔNIO" || patRaw.isEmpty || patRaw == "null") {
            normalizedPat = serieRaw.isNotEmpty ? "SP_$serieRaw" : "S/P_${eDoc.id.substring(0, 5)}";
          }

          String key = normalizedPat.toUpperCase();
          final currentStatus = data['status_operacional'] ?? 'Em uso';

          String activeKey = key;
          int iHist = 0;
          while (agregador.containsKey(activeKey) && 
                 agregador[activeKey]!['teve_manutencao_concluida'] == true && 
                 currentStatus == 'Em manutenção') {
            iHist++;
            activeKey = "${key}_H$iHist";
          }

          if (!agregador.containsKey(activeKey)) {
            final base = agregador[key] ?? {};
            agregador[activeKey] = {
              'patrimonio': normalizedPat,
              'tipo': data['tipo'] ?? base['tipo'] ?? '---',
              'marca': data['marca'] ?? base['marca'] ?? '---',
              'modelo': data['modelo'] ?? base['modelo'] ?? '---',
              'serie': serieRaw.isNotEmpty ? serieRaw : (base['serie'] ?? '---'),
              'mac_address': macRaw.isNotEmpty ? macRaw : (base['mac_address'] ?? '---'),
              'locadora': data['locadora'] ?? base['locadora'] ?? 'PRÓPRIO',
              'tem_defeito': false,
              'descricao_defeito': '---',
              'em_manutencao': false,
              'teve_manutencao_concluida': false,
              'count_manutencao': base['count_manutencao'] ?? 0,
              'count_divergencia': base['count_divergencia'] ?? 0,
              'count_home_office': base['count_home_office'] ?? 0,
              'ultimo_status': currentStatus,
              'ultimo_setor': data['setor'] ?? '---',
              'data_entrada_manutencao': data['data_entrada_manutencao'],
              'data_saida_manutencao': null,
              'foi_descartado': false,
            };
          }

          final item = agregador[activeKey]!;

          if (data['marca'] != null && data['marca'].toString().isNotEmpty && data['marca'] != '---') item['marca'] = data['marca'];
          if (data['modelo'] != null && data['modelo'].toString().isNotEmpty && data['modelo'] != '---') item['modelo'] = data['modelo'];
          if (data['serie'] != null && data['serie'].toString().isNotEmpty && data['serie'] != '---') item['serie'] = data['serie'];
          if (data['mac_address'] != null && data['mac_address'].toString().isNotEmpty && data['mac_address'] != '---') item['mac_address'] = data['mac_address'];
          if (data['locadora'] != null && data['locadora'].toString().isNotEmpty) item['locadora'] = data['locadora'];

          if (data['tem_defeito'] == true || data['status'] == 'Defeito' || data['status_operacional'] == 'Defeito') {
            item['tem_defeito'] = true;
            item['descricao_defeito'] = data['descricao_defeito'] ?? 'Defeito sinalizado em ronda';
          }

          if (currentStatus == 'Em manutenção') {
            if (item['em_manutencao'] == false) item['count_manutencao']++;
            item['em_manutencao'] = true;
            if (item['data_entrada_manutencao'] == null) item['data_entrada_manutencao'] = roundTimestamp;
            item['data_saida_manutencao'] = null;
          } 
          else if (currentStatus == 'Descartado' && (item['em_manutencao'] == true || item['data_entrada_manutencao'] != null)) {
            item['data_saida_manutencao'] = roundTimestamp;
            item['teve_manutencao_concluida'] = true;
            item['foi_descartado'] = true;
            item['em_manutencao'] = false;
          }
          else if (currentStatus == 'Em uso' && (item['em_manutencao'] == true || item['data_entrada_manutencao'] != null)) {
            item['data_saida_manutencao'] = roundTimestamp;
            item['teve_manutencao_concluida'] = true;
            item['em_manutencao'] = false;
          }

          if (data['setor_divergente'] == true) item['count_divergencia']++;
          if (data['is_home_office'] == true) item['count_home_office']++;
          
          item['ultimo_status'] = currentStatus;
          item['ultimo_setor'] = currentStatus == 'Descartado' ? 'BAIXA PATRIMONIAL' : (data['setor'] ?? '---');
        }
      }

      Query queryMestreCriticos = _firestore.collection('inventario_mestre').where('tem_defeito', isEqualTo: true);
      Query queryMestreManutencao = _firestore.collection('inventario_mestre').where('status_operacional', isEqualTo: 'Em manutenção');

      if (setor != null) {
        queryMestreCriticos = queryMestreCriticos.where('setor', isEqualTo: setor);
        queryMestreManutencao = queryMestreManutencao.where('setor', isEqualTo: setor);
      }
      if (locadora != null) {
        queryMestreCriticos = queryMestreCriticos.where('locadora', isEqualTo: locadora);
        queryMestreManutencao = queryMestreManutencao.where('locadora', isEqualTo: locadora);
      }

      final mestreCriticos = await queryMestreCriticos.get();
      final mestreManutencao = await queryMestreManutencao.get();

      for (var snap in [mestreCriticos, mestreManutencao]) {
        for (var doc in snap.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final String key = doc.id.toUpperCase();
          
          if (!agregador.containsKey(key)) {
            agregador[key] = {
              'patrimonio': doc.id,
              'tipo': data['tipo'] ?? '---',
              'marca': data['marca'] ?? '---',
              'modelo': data['modelo'] ?? '---',
              'serie': data['serie'] ?? '---',
              'mac_address': data['mac_address'] ?? '---',
              'locadora': data['locadora'] ?? 'PRÓPRIO',
              'tem_defeito': data['tem_defeito'] == true,
              'descricao_defeito': data['descricao_defeito'] ?? (data['tem_defeito'] == true ? 'Defeito sinalizado' : '---'),
              'em_manutencao': data['status_operacional'] == 'Em manutenção',
              'teve_manutencao_concluida': false,
              'count_manutencao': data['status_operacional'] == 'Em manutenção' ? 1 : 0,
              'count_divergencia': 0,
              'count_home_office': 0,
              'ultimo_status': data['status_operacional'] ?? 'OK',
              'ultimo_setor': data['setor'] ?? '---',
              'data_entrada_manutencao': data['data_entrada_manutencao'],
              'data_saida_manutencao': null,
              'foi_descartado': data['status_operacional'] == 'Descartado',
            };
          } else {
            final item = agregador[key]!;
            if (data['tem_defeito'] == true) {
              item['tem_defeito'] = true;
              if (item['descricao_defeito'] == '---') item['descricao_defeito'] = data['descricao_defeito'] ?? 'Defeito (Mestre)';
            }
            if (data['status_operacional'] == 'Em manutenção') {
              item['em_manutencao'] = true;
              if (item['data_entrada_manutencao'] == null) item['data_entrada_manutencao'] = data['data_entrada_manutencao'];
            }
          }
        }
      }

      final listaFinal = agregador.values.where((item) => 
        item['tem_defeito'] == true ||
        item['em_manutencao'] == true ||
        item['teve_manutencao_concluida'] == true ||
        item['ultimo_status'] == 'Descartado' ||
        item['count_divergencia'] > 0 || 
        item['count_home_office'] > 0
      ).toList();

      listaFinal.sort((a, b) => b['count_manutencao'].compareTo(a['count_manutencao']));

      if (context.mounted) {
        if (listaFinal.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nenhuma incidência crítica encontrada.")));
          return;
        }
        
        if (formato == 'XLSX') {
          await ReportRepository.exportarRelatorioIncidenciasXLSX(context: context, dados: listaFinal, periodo: periodo);
        } else {
          await ReportRepository.exportarRelatorioIncidencias(context: context, dados: listaFinal, periodo: periodo);
        }
      }
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro: $e"), backgroundColor: Colors.red));
    }
  }
}
