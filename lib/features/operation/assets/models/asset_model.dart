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
  final String? motivoBaixa;
  final String status;
  final int? anoFabricacao;
  final int? anoEntradaUnidade;
  final bool isHomeOffice;
  final bool homeOfficeAutorizado; // Novo: Autorização permanente
  final DateTime? dataEntradaManutencao; // Novo: Para cálculo de tempo em reparo
  final String? responsavelExterno;
  final bool isEmprestimo; // Novo: Item emprestado (Fora da unidade)
  final DateTime? dataEmprestimo; // Novo: Data do empréstimo
  final String? motivoEmprestimo; // Novo: Motivo do empréstimo
  final String? destinoEmprestimo; // Novo: Para onde/Quem (Fora da unidade)
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
    this.motivoBaixa,
    this.status = 'Ativo',
    this.anoFabricacao,
    this.anoEntradaUnidade,
    this.isHomeOffice = false,
    this.homeOfficeAutorizado = false,
    this.dataEntradaManutencao,
    this.responsavelExterno,
    this.isEmprestimo = false,
    this.dataEmprestimo,
    this.motivoEmprestimo,
    this.destinoEmprestimo,
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
      motivoBaixa: map['motivo_baixa'],
      status: map['status'] ?? 'Ativo',
      anoFabricacao: map['ano_fabricacao'],
      anoEntradaUnidade: map['ano_entrada_unidade'],
      isHomeOffice: map['is_home_office'] ?? false,
      homeOfficeAutorizado: map['home_office_autorizado'] ?? false,
      dataEntradaManutencao: map['data_entrada_manutencao'] != null 
          ? (map['data_entrada_manutencao'] as Timestamp).toDate() 
          : null,
      responsavelExterno: map['responsavel_externo'],
      isEmprestimo: map['is_emprestimo'] ?? false,
      dataEmprestimo: map['data_emprestimo'] != null 
          ? (map['data_emprestimo'] as Timestamp).toDate() 
          : null,
      motivoEmprestimo: map['motivo_emprestimo'],
      destinoEmprestimo: map['destino_emprestimo'],
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
      'motivo_baixa': motivoBaixa,
      'status': status,
      'ano_fabricacao': anoFabricacao,
      'ano_entrada_unidade': anoEntradaUnidade,
      'is_home_office': isHomeOffice,
      'home_office_autorizado': homeOfficeAutorizado,
      'data_entrada_manutencao': dataEntradaManutencao != null 
          ? Timestamp.fromDate(dataEntradaManutencao!) 
          : null,
      'responsavel_externo': responsavelExterno,
      'is_emprestimo': isEmprestimo,
      'data_emprestimo': dataEmprestimo != null 
          ? Timestamp.fromDate(dataEmprestimo!) 
          : null,
      'motivo_emprestimo': motivoEmprestimo,
      'destino_emprestimo': destinoEmprestimo,
      'id_anterior': idAnterior,
      'acessorios': acessorios,
    };
  }

  bool get isObsoleto {
    if (anoFabricacao == null) return false;
    return (DateTime.now().year - anoFabricacao!) >= 5;
  }

  double get healthScore {
    double score = 100.0;

    // Fator 1: Idade (Obsolescência)
    if (isObsoleto) score -= 30.0;

    // Fator 2: Defeitos
    if (temDefeito) score -= 30.0;

    // Fator 3: Manutenção
    if (statusOperacional == 'Em manutenção') score -= 20.0;

    // Fator 4: Divergência de Setor / Empréstimo
    if (setorDivergente || isEmprestimo) score -= 10.0;

    // Fator 5: Baixa Patrimonial (Estado crítico/final)
    if (statusOperacional == 'Baixa Patrimonial') score = 0.0;

    return score.clamp(0.0, 100.0);
  }

  String get actionRecommendation {
    final score = healthScore;
    if (score == 0) return "Ativo Desativado / Baixa";
    if (score < 50) return "Prioridade de Substituição (CAPEX)";
    if (isObsoleto) return "Fim de Vida Útil - Planejar Troca";
    if (temDefeito || statusOperacional == 'Em manutenção') return "Monitorar SLA de Reparo";
    if (isEmprestimo) return "Rastrear Retorno de Empréstimo";
    if (score < 80) return "Avaliar Manutenção Preventiva";
    return "Operação Nominal - Saudável";
  }
}
