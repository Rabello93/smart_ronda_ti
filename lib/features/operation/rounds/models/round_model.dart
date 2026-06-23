import 'package:cloud_firestore/cloud_firestore.dart';

class RoundModel {
  final String? id;
  final DateTime dataInicio;
  final String setor;
  final String tecnico;
  final String tecnicoId;
  final int itensTotal;
  final int trocasTotal;
  final int defeitosTotal;
  final int alugadosTotal;
  final bool validada;

  RoundModel({
    this.id,
    required this.dataInicio,
    required this.setor,
    required this.tecnico,
    required this.tecnicoId,
    this.itensTotal = 0,
    this.trocasTotal = 0,
    this.defeitosTotal = 0,
    this.alugadosTotal = 0,
    this.validada = false,
  });

  factory RoundModel.fromMap(Map<String, dynamic> map, String id) {
    return RoundModel(
      id: id,
      dataInicio: map['data_inicio'] != null 
          ? DateTime.parse(map['data_inicio']) 
          : (map['timestamp'] as Timestamp).toDate(),
      setor: map['setor'] ?? '',
      tecnico: map['tecnico'] ?? '',
      tecnicoId: map['tecnico_id'] ?? '',
      itensTotal: map['itens_total'] ?? 0,
      trocasTotal: map['trocas_total'] ?? 0,
      defeitosTotal: map['defeitos_total'] ?? 0,
      alugadosTotal: map['alugados_total'] ?? 0,
      validada: map['validada'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'data_inicio': dataInicio.toIso8601String(),
      'setor': setor,
      'tecnico': tecnico,
      'tecnico_id': tecnicoId,
      'itens_total': itensTotal,
      'trocas_total': trocasTotal,
      'defeitos_total': defeitosTotal,
      'alugados_total': alugadosTotal,
      'validada': validada,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
}
