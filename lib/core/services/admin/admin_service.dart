import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/usuario_model.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- SETORES ---
  Future<void> adicionarSetor(String nome) async {
    await _firestore.collection('setores').doc(nome.toLowerCase()).set({
      'nome': nome,
      'criado_em': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Map<String, dynamic>>> getSetores() {
    return _firestore.collection('setores').orderBy('nome').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => {'id': doc.id, 'nome': doc['nome']}).toList();
    });
  }

  Future<void> excluirSetor(String id) async {
    await _firestore.collection('setores').doc(id).delete();
  }

  // --- LOGS ---
  Future<void> registrarLog({required String acao, required String detalhes, String origem = "APP"}) async {
    // Busca o nome do técnico atual para o log
    final userDoc = await _firestore.collection('tecnicos').doc(_auth.currentUser?.uid).get();
    final nome = userDoc.exists ? userDoc.get('nome') : "Desconhecido";

    await _firestore.collection('logs').add({
      'tecnico_nome': nome,
      'tecnico_id': _auth.currentUser?.uid,
      'tecnico_nivel': userDoc.exists ? (userDoc.get('nivel_acesso') ?? 'normal') : 'normal',
      'acao': acao,
      'detalhes': detalhes,
      'origem': origem,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Map<String, dynamic>>> getLogs() {
    return _firestore.collection('logs').orderBy('timestamp', descending: true).limit(100).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  // --- GESTÃO DE EQUIPE ---
  Stream<List<UsuarioModel>> getAllTecnicos() {
    return _firestore.collection('tecnicos').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => UsuarioModel.fromMap(doc.data(), doc.id)).toList();
    });
  }

  Future<void> excluirUsuarioComMotivo({required String uid, required String motivo}) async {
    await _firestore.collection('tecnicos').doc(uid).update({
      'ativo': false, 
      'motivo_desativacao': motivo, 
      'excluido_em': FieldValue.serverTimestamp()
    });
  }

  Future<void> excluirUsuarioDefinitivo(String uid) async {
    await _firestore.collection('tecnicos').doc(uid).delete();
  }

  Stream<int> getNovosPerfisCount() {
    final limite = DateTime.now().subtract(const Duration(hours: 48));
    return _firestore.collection('tecnicos')
        .where('criado_em', isGreaterThan: limite)
        .where('nivel_acesso', isEqualTo: 'normal')
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  // --- LOCADORAS ---
  Future<void> adicionarLocadora(String nome) async {
    await _firestore.collection('locadoras').doc(nome.toLowerCase()).set({
      'nome': nome, 
      'criado_em': FieldValue.serverTimestamp()
    });
  }

  Stream<List<String>> getLocadoras() {
    return _firestore.collection('locadoras').orderBy('nome').snapshots().map((snap) => 
      snap.docs.map((doc) => doc['nome'] as String).toList()
    );
  }

  Future<void> excluirLocadora(String id) async {
    await _firestore.collection('locadoras').doc(id).delete();
  }

  // --- CONFIGURAÇÃO EMPRESA ---
  Future<void> salvarConfigEmpresa(Map<String, dynamic> config) async {
    await _firestore.collection('config').doc('empresa').set(config, SetOptions(merge: true));
  }

  Stream<DocumentSnapshot> getConfigEmpresa() {
    return _firestore.collection('config').doc('empresa').snapshots();
  }
}
