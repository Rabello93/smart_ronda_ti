import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/ronda_model.dart';
import '../../models/ativo_model.dart';

class RondaService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- SALVAR RONDA ---
  Future<void> salvarRondaCompleta({
    String? rondaExistenteId,
    required RondaModel ronda,
    required List<AtivoModel> equipamentos,
    Map<String, dynamic>? dadosTroca,
  }) async {
    WriteBatch batch = _firestore.batch();
    
    DocumentReference rondaRef = rondaExistenteId != null 
      ? _firestore.collection('rondas').doc(rondaExistenteId)
      : _firestore.collection('rondas').doc();
    
    // Salva os dados principais da ronda
    batch.set(rondaRef, ronda.toMap(), SetOptions(merge: true));

    // Se estiver editando, remove os equipamentos antigos da subcoleção para evitar duplicados
    if (rondaExistenteId != null) {
      QuerySnapshot equipsAntigos = await rondaRef.collection('equipamentos').get();
      for (var doc in equipsAntigos.docs) {
        batch.delete(doc.reference);
      }
    }

    // Salva os equipamentos na subcoleção e atualiza o "Castelo"
    for (var equip in equipamentos) {
      DocumentReference equipRef = rondaRef.collection('equipamentos').doc();
      batch.set(equipRef, equip.toMap());
      
      // Atualiza o Inventário Mestre (O Castelo)
      String idDocumento = _gerarIdInventario(equip, ronda.setor);
      DocumentReference invRef = _firestore.collection('inventario_mestre').doc(idDocumento);
      
      Map<String, dynamic> invData = equip.toMap();
      invData['ultima_ronda_id'] = rondaRef.id;
      invData['ultimo_tecnico'] = _auth.currentUser?.uid;
      
      batch.set(invRef, invData, SetOptions(merge: true));
    }

    // Se houve troca, salva o registro especial
    if (dadosTroca != null) {
      DocumentReference trocaRef = rondaRef.collection('equipamentos').doc();
      dadosTroca['is_troca'] = true;
      batch.set(trocaRef, dadosTroca);
    }
    
    await batch.commit();
  }

  // Auxiliar para gerar ID do inventário (lógica movida do FirebaseService)
  String _gerarIdInventario(AtivoModel equip, String setorRonda) {
    if (equip.semPatrimonio) {
      if (equip.serie.isNotEmpty) return "SP_${equip.serie}";
      return "SP_${equip.tipo}_$setorRonda".toUpperCase();
    }
    return equip.patrimonio;
  }

  // --- HISTÓRICO ---
  Stream<List<RondaModel>> getHistoricoRondas() {
    return _firestore.collection('rondas').orderBy('timestamp', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => RondaModel.fromMap(doc.data(), doc.id)).toList();
    });
  }

  // --- DETALHES ---
  Future<List<Map<String, dynamic>>> getEquipamentosDaRonda(String rondaId) async {
    final snapshot = await _firestore.collection('rondas').doc(rondaId).collection('equipamentos').get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  // --- EXCLUSÃO ---
  Future<void> excluirRonda(String docId) async {
    await _firestore.collection('rondas').doc(docId).delete();
  }
}
