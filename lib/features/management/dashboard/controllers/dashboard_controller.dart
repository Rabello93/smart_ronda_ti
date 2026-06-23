import '../../rounds/models/round_model.dart';

class DashboardController {
  /// Filtra a lista de rondas baseada no período selecionado.
  List<RoundModel> filterRoundsByDateRange(List<RoundModel> rounds, DateTimeRange? range) {
    if (range == null) return rounds;
    return rounds.where((r) {
      return r.dataInicio.isAfter(range.start) && 
             r.dataInicio.isBefore(range.end.add(const Duration(days: 1)));
    }).toList();
  }

  /// Calcula o ranking de rondas por setor.
  List<MapEntry<String, int>> getRankingPorSetor(List<RoundModel> rounds) {
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

  /// Calcula o total de defeitos encontrados.
  int getTotalDefeitos(List<RoundModel> rounds) {
    return rounds.fold(0, (sum, r) => sum + r.defeitosTotal);
  }
}

// Mock DateTimeRange for the controller if not using flutter material here
// In a real scenario, you'd import 'package:flutter/material.dart'
import 'package:flutter/material.dart' show DateTimeRange;
