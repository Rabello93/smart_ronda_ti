import 'package:flutter/material.dart' show DateTimeRange;
import '../../../operation/rounds/models/round_model.dart';
import '../../../operation/assets/models/asset_model.dart';
import 'package:intl/intl.dart';

class DashboardController {
  /// Filtra a lista de rondas baseada no período selecionado.
  List<RoundModel> filterRoundsByDateRange(List<RoundModel> rounds, DateTimeRange? range) {
    if (range == null) return rounds;
    return rounds.where((r) {
      return r.dataInicio.isAfter(range.start.subtract(const Duration(seconds: 1))) && 
             r.dataInicio.isBefore(range.end.add(const Duration(days: 1)));
    }).toList();
  }

  /// Calcula o ranking de rondas por departamento.
  List<MapEntry<String, int>> getRankingPorDepartamento(List<RoundModel> rounds) {
    Map<String, int> counts = {};
    for (var r in rounds) {
      counts[r.setor] = (counts[r.setor] ?? 0) + 1;
    }
    return counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  }

  /// Calcula o ranking de rondas por técnico.
  List<MapEntry<String, int>> getRankingPorTecnico(List<RoundModel> rounds) {
    Map<String, int> counts = {};
    for (var r in rounds) {
      counts[r.tecnico] = (counts[r.tecnico] ?? 0) + 1;
    }
    return counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  }

  /// Calcula o total de itens verificados.
  int getTotalItens(List<RoundModel> rounds) {
    return rounds.fold(0, (sum, r) => sum + r.itensTotal);
  }

  /// Calcula o total de defeitos encontrados no período.
  int getTotalDefeitos(List<RoundModel> rounds) {
    return rounds.fold(0, (sum, r) => sum + r.defeitosTotal);
  }

  /// Gera dados para o gráfico de tendência (últimos 7 dias)
  Map<String, int> getRoundsTrend(List<RoundModel> allRounds) {
    Map<String, int> trend = {};
    final now = DateTime.now();
    
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateKey = DateFormat('dd/MM').format(date);
      trend[dateKey] = 0;
    }

    for (var r in allRounds) {
      final dateKey = DateFormat('dd/MM').format(r.dataInicio);
      if (trend.containsKey(dateKey)) {
        trend[dateKey] = trend[dateKey]! + 1;
      }
    }
    return trend;
  }

  /// Calcula o Health Score do Patrimônio (Média de Saúde do Parque)
  Map<String, double> getInventoryCoverage(List<AssetModel> allAssets, List<RoundModel> roundsInPeriod) {
    if (allAssets.isEmpty) return {'auditado': 0, 'pendente': 0};
    
    // Nova Lógica 3.3.0: Média do Health Score Real
    // auditado = Média das notas de saúde de todos os ativos
    // pendente = O "Gap" para chegar em 100%
    
    double totalScore = allAssets.fold(0.0, (sum, a) => sum + a.healthScore);
    double averageScore = totalScore / allAssets.length;

    return {
      'auditado': averageScore,
      'pendente': 100.0 - averageScore,
    };
  }

  /// Resumo por categoria de ativos
  List<MapEntry<String, int>> getAssetCategorySummary(List<AssetModel> allAssets) {
    Map<String, int> categories = {};
    for (var a in allAssets) {
      categories[a.tipo] = (categories[a.tipo] ?? 0) + 1;
    }
    return categories.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  }

  /// Gera dados para comparativo mensal (últimos 6 meses)
  Map<String, Map<String, int>> getMonthlyComparison(List<RoundModel> allRounds) {
    Map<String, Map<String, int>> data = {};
    final now = DateTime.now();
    
    for (int i = 5; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      final key = DateFormat('MMM/yy').format(date);
      data[key] = {'rondas': 0, 'itens': 0, 'defeitos': 0};
    }

    for (var r in allRounds) {
      final key = DateFormat('MMM/yy').format(r.dataInicio);
      if (data.containsKey(key)) {
        data[key]!['rondas'] = data[key]!['rondas']! + 1;
        data[key]!['itens'] = data[key]!['itens']! + r.itensTotal;
        data[key]!['defeitos'] = data[key]!['defeitos']! + r.defeitosTotal;
      }
    }
    return data;
  }

  /// Identifica alertas críticos (Ex: Muitos defeitos hoje)
  List<String> getCriticalAlerts(List<RoundModel> allRounds, [List<AssetModel>? allAssets]) {
    List<String> alerts = [];
    final today = DateTime.now();
    final todayRounds = allRounds.where((r) => 
      r.dataInicio.day == today.day && 
      r.dataInicio.month == today.month && 
      r.dataInicio.year == today.year
    ).toList();

    int defectsToday = todayRounds.fold(0, (sum, r) => sum + r.defeitosTotal);
    if (defectsToday > 0) {
      alerts.add("$defectsToday novos defeitos relatados hoje!");
    }

    if (allAssets != null) {
      final emManutencao = allAssets.where((a) => a.statusOperacional == 'Em manutenção').toList();
      if (emManutencao.length > 5) {
        alerts.add("Atenção: ${emManutencao.length} itens aguardando manutenção!");
      }
    }

    return alerts;
  }

  /// Identifica departamentos sem rondas há mais de 15 dias.
  List<String> getInactiveDepartmentAlerts(List<RoundModel> allRounds, List<Map<String, dynamic>> departamentos) {
    List<String> alerts = [];
    final now = DateTime.now();
    
    for (var dep in departamentos) {
      final nome = dep['nome'] as String;
      final rondasDoDep = allRounds.where((r) => r.setor == nome).toList()
        ..sort((a, b) => b.dataInicio.compareTo(a.dataInicio));
      
      if (rondasDoDep.isEmpty) {
        alerts.add("Departamento $nome nunca recebeu uma ronda!");
      } else {
        final lastRound = rondasDoDep.first.dataInicio;
        final difference = now.difference(lastRound).inDays;
        if (difference > 15) {
          alerts.add("Atenção: $nome sem rondas há $difference dias!");
        }
      }
    }
    return alerts;
  }

  /// Calcula o Ranking de Divergências por Departamento
  List<Map<String, dynamic>> getDivergenceRanking(List<AssetModel> allAssets) {
    Map<String, int> divergenceCount = {};
    Map<String, int> totalCount = {};

    for (var a in allAssets) {
      totalCount[a.setor] = (totalCount[a.setor] ?? 0) + 1;
      if (a.setorDivergente) {
        divergenceCount[a.setor] = (divergenceCount[a.setor] ?? 0) + 1;
      }
    }

    final ranking = divergenceCount.entries.map((e) {
      final total = totalCount[e.key] ?? 1;
      final percent = (e.value / total * 100);
      return {
        'setor': e.key,
        'count': e.value,
        'percent': percent,
      };
    }).toList();

    // Ordena pelo maior número de divergências
    ranking.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
    return ranking;
  }

  /// Calcula o Mapa de Calor de Auditoria (Semáforo de Risco)
  Map<String, List<String>> getAuditHeatMap(List<RoundModel> allRondas, List<Map<String, dynamic>> departamentos) {
    Map<String, List<String>> heatMap = {'verde': [], 'amarelo': [], 'vermelho': []};
    final now = DateTime.now();

    for (var dep in departamentos) {
      final nome = dep['nome'] as String;
      final rondasDoDep = allRondas.where((r) => r.setor == nome).toList()
        ..sort((a, b) => b.dataInicio.compareTo(a.dataInicio));

      if (rondasDoDep.isEmpty) {
        heatMap['vermelho']!.add(nome);
      } else {
        final lastRound = rondasDoDep.first.dataInicio;
        final diff = now.difference(lastRound).inDays;
        if (diff <= 15) heatMap['verde']!.add(nome);
        else if (diff <= 30) heatMap['amarelo']!.add(nome);
        else heatMap['vermelho']!.add(nome);
      }
    }
    return heatMap;
  }

  /// Simula a capacidade contratada baseada em novos usuários
  Map<String, dynamic> simulateCapacity(List<AssetModel> allAssets, Map<String, int> contractedMap, int extraUsers) {
    Map<String, int> currentUsage = {};
    for (var a in allAssets.where((a) => a.isLocado)) {
      currentUsage[a.tipo] = (currentUsage[a.tipo] ?? 0) + 1;
    }

    Map<String, int> needed = {};
    Map<String, int> deficit = {};

    // Assume 1 Notebook, 1 Monitor por usuário extra como padrão
    needed['Notebook'] = extraUsers;
    needed['Monitor'] = extraUsers;

    for (var entry in needed.entries) {
      final tipo = entry.key;
      final extra = entry.value;
      final contratado = contractedMap[tipo] ?? 0;
      final emUso = currentUsage[tipo] ?? 0;
      
      final totalFinal = emUso + extra;
      if (totalFinal > contratado) {
        deficit[tipo] = totalFinal - contratado;
      }
    }

    return {
      'current_usage': currentUsage,
      'needed_extra': needed,
      'deficit': deficit,
    };
  }
}
