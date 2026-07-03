import 'package:cloud_firestore/cloud_firestore.dart';

class AssetModel {
  final String patrimonio;
  final String tipo;
  final String marca;
  final String modelo;
  final String serie;
  final bool isLocado;
  final String? locadora;
  final String? processador;
  final String? macAddress;
  final String setor;
  final String? ultimaRondaId;
  final String? ultimoTecnico;
  final DateTime? ultimaAtualizacao;
  final String statusOperacional;
  final bool setorDivergente;
  final String? motivoDivergencia;
  final bool semPatrimonio;
  final bool temDefeito;
  final String? descricaoDefeito;
  final String status;
  final int? anoFabricacao;
  final int? anoEntradaUnidade;
  final bool isHomeOffice;
  final String? responsavelExterno;
  final String? idAnterior; // Novo campo para rastrear conversões (Sem Placa -> Com Placa)
  final Map<String, bool> acessorios;

  AssetModel({
    required this.patrimonio,
    required this.tipo,
    this.marca = '',
    this.modelo = '',
    this.serie = '',
    this.isLocado = false,
    this.locadora,
    this.processador,
    this.macAddress,
    required this.setor,
    this.ultimaRondaId,
    this.ultimoTecnico,
    this.ultimaAtualizacao,
    this.statusOperacional = 'Em uso',
    this.setorDivergente = false,
    this.motivoDivergencia,
    this.semPatrimonio = false,
    this.temDefeito = false,
    this.descricaoDefeito,
    this.status = 'Ativo',
    this.anoFabricacao,
    this.anoEntradaUnidade,
    this.isHomeOffice = false,
    this.responsavelExterno,
    this.idAnterior,
    this.acessorios = const {},
  });

  factory AssetModel.fromMap(Map<String, dynamic> map, String id) {
    return AssetModel(
      patrimonio: map['patrimonio'] ?? id,
      tipo: map['tipo'] ?? 'Outro',
      marca: map['marca'] ?? '',
      modelo: map['modelo'] ?? '',
      serie: map['serie'] ?? '',
      isLocado: map['is_locado'] ?? false,
      locadora: map['locadora'],
      processador: map['processador'],
      macAddress: map['mac_address'],
      setor: map['setor'] ?? 'Não definido',
      ultimaRondaId: map['ultima_ronda_id'],
      ultimoTecnico: map['ultimo_tecnico'],
      ultimaAtualizacao: map['ultima_atualizacao'] != null 
          ? (map['ultima_atualizacao'] as Timestamp).toDate() 
          : null,
      statusOperacional: map['status_operacional'] ?? 'Em uso',
      setorDivergente: map['setor_divergente'] ?? false,
      motivoDivergencia: map['motivo_divergencia'],
      semPatrimonio: map['sem_patrimonio'] ?? false,
      temDefeito: map['tem_defeito'] ?? false,
      descricaoDefeito: map['descricao_defeito'],
      status: map['status'] ?? 'Ativo',
      anoFabricacao: map['ano_fabricacao'],
      anoEntradaUnidade: map['ano_entrada_unidade'],
      isHomeOffice: map['is_home_office'] ?? false,
      responsavelExterno: map['responsavel_externo'],
      idAnterior: map['id_anterior'],
      acessorios: Map<String, bool>.from(map['acessorios'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'patrimonio': patrimonio,
      'tipo': tipo,
      'marca': marca,
      'modelo': modelo,
      'serie': serie,
      'is_locado': isLocado,
      'locadora': locadora,
      'processador': processador,
      'mac_address': macAddress,
      'setor': setor,
      'ultima_ronda_id': ultimaRondaId,
      'ultimo_tecnico': ultimoTecnico,
      'ultima_atualizacao': ultimaAtualizacao != null 
          ? Timestamp.fromDate(ultimaAtualizacao!) 
          : FieldValue.serverTimestamp(),
      'status_operacional': statusOperacional,
      'setor_divergente': setorDivergente,
      'motivo_divergencia': motivoDivergencia,
      'sem_patrimonio': semPatrimonio,
      'tem_defeito': temDefeito,
      'descricao_defeito': descricaoDefeito,
      'status': status,
      'ano_fabricacao': anoFabricacao,
      'ano_entrada_unidade': anoEntradaUnidade,
      'is_home_office': isHomeOffice,
      'responsavel_externo': responsavelExterno,
      'id_anterior': idAnterior,
      'acessorios': acessorios,
    };
  }

  bool get isObsoleto {
    if (anoFabricacao == null) return false;
    return (DateTime.now().year - anoFabricacao!) >= 5;
  }
}
