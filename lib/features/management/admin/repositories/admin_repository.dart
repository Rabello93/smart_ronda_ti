import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../auth/models/user_model.dart';

class AdminRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- SECTORS ---
  Future<void> addSector(String name) async {
    await _firestore.collection('setores').doc(name.toLowerCase()).set({
      'nome': name,
      'criado_em': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Map<String, dynamic>>> getSectorsStream() {
    return _firestore.collection('setores').orderBy('nome').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => {'id': doc.id, 'nome': doc['nome']}).toList();
    });
  }

  Future<void> deleteSector(String id) async {
    await _firestore.collection('setores').doc(id).delete();
  }

  // --- LOGS ---
  Future<void> logAction({required String action, required String details, String origin = "APP"}) async {
    final userDoc = await _firestore.collection('tecnicos').doc(_auth.currentUser?.uid).get();
    final name = userDoc.exists ? userDoc.get('nome') : "Desconhecido";

    await _firestore.collection('logs').add({
      'tecnico_nome': name,
      'tecnico_id': _auth.currentUser?.uid,
      'tecnico_nivel': userDoc.exists ? (userDoc.get('nivel_acesso') ?? 'normal') : 'normal',
      'acao': action,
      'detalhes': details,
      'origem': origin,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Map<String, dynamic>>> getLogsStream() {
    return _firestore.collection('logs').orderBy('timestamp', descending: true).limit(100).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    });
  }

  // --- TEAM MANAGEMENT ---
  Stream<List<UserModel>> getUsersStream() {
    return _firestore.collection('tecnicos').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
    });
  }

  Future<void> deactivateUser({required String uid, required String reason}) async {
    await _firestore.collection('tecnicos').doc(uid).update({
      'ativo': false, 
      'motivo_desativacao': reason, 
      'excluido_em': FieldValue.serverTimestamp()
    });
  }

  Future<void> deleteUser(String uid) async {
    await _firestore.collection('tecnicos').doc(uid).delete();
  }

  // --- LEASING COMPANIES ---
  Future<void> addLeasingCompany(String name) async {
    await _firestore.collection('locadoras').doc(name.toLowerCase()).set({
      'nome': name, 
      'criado_em': FieldValue.serverTimestamp()
    });
  }

  Stream<List<String>> getLeasingCompaniesStream() {
    return _firestore.collection('locadoras').orderBy('nome').snapshots().map((snap) => 
      snap.docs.map((doc) => doc['nome'] as String).toList()
    );
  }

  Future<void> deleteLeasingCompany(String id) async {
    await _firestore.collection('locadoras').doc(id).delete();
  }

  // --- COMPANY CONFIG ---
  Future<void> saveCompanyConfig(Map<String, dynamic> config) async {
    await _firestore.collection('config').doc('empresa').set(config, SetOptions(merge: true));
  }

  Stream<DocumentSnapshot> getCompanyConfigStream() {
    return _firestore.collection('config').doc('empresa').snapshots();
  }
}
