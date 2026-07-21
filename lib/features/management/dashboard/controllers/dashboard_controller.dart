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

  /// Calcula o ranking de rondas por setor. (Legado)
  List<MapEntry<String, int>> getRankingPorSetor(List<RoundModel> rounds) => getRankingPorDepartamento(rounds);

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

  /// Calcula o Health Score do Patrimônio (Itens Saudáveis vs Total)
  Map<String, double> getInventoryCoverage(List<AssetModel> allAssets, List<RoundModel> roundsInPeriod) {
    if (allAssets.isEmpty) return {'auditado': 0, 'pendente': 0};
    
    // Nova Lógica 3.2.9: Saúde Física do Parque
    // Um item deixa de ser "saudável" se:
    // 1. Tem defeito relatado
    // 2. Está em manutenção
    // 3. É obsoleto (+5 anos)
    
    int total = allAssets.length;
    int problematicos = allAssets.where((a) => 
      a.temDefeito || 
      a.statusOperacional == 'Em manutenção' || 
      a.isObsoleto
    ).length;

    int saudaveis = total - problematicos;
    if (saudaveis < 0) saudaveis = 0;

    return {
      'auditado': saudaveis.toDouble(),
      'pendente': problematicos.toDouble(),
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
      // Encontra a última ronda desse departamento
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
}
