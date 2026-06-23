import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String nome;
  final String email;
  final String dataNascimento;
  final String funcao;
  final String localTrabalho;
  final String matricula;
  final String nivelAcesso;
  final bool ativo;
  final DateTime? criadoEm;

  UserModel({
    required this.uid,
    required this.nome,
    required this.email,
    required this.dataNascimento,
    required this.funcao,
    required this.localTrabalho,
    this.matricula = '',
    this.nivelAcesso = 'normal',
    this.ativo = false,
    this.criadoEm,
  });

  // Converte o Documento do Firebase para o Modelo
  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      uid: id,
      nome: map['nome'] ?? '',
      email: map['email'] ?? '',
      dataNascimento: map['data_nascimento'] ?? '',
      funcao: map['funcao'] ?? '',
      localTrabalho: map['local_trabalho'] ?? '',
      matricula: map['matricula'] ?? '',
      nivelAcesso: map['nivel_acesso'] ?? 'normal',
      ativo: map['ativo'] ?? false,
      criadoEm: map['criado_em'] != null ? (map['criado_em'] as Timestamp).toDate() : null,
    );
  }

  // Converte o Modelo para Map (para salvar no Firebase)
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'nome': nome,
      'email': email,
      'data_nascimento': dataNascimento,
      'funcao': funcao,
      'local_trabalho': localTrabalho,
      'matricula': matricula,
      'nivel_acesso': nivelAcesso,
      'ativo': ativo,
      'criado_em': criadoEm != null ? Timestamp.fromDate(criadoEm!) : FieldValue.serverTimestamp(),
    };
  }

  // Atalho para saber se é administrador
  bool get isAdmin => nivelAcesso == 'master' || nivelAcesso == 'gerente';
}
