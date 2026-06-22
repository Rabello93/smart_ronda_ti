import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/ativo_model.dart';

class InventoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- BUSCA ---
  Future<AtivoModel?> buscarNoInventario(String valor) async {
    String busca = valor.trim().toLowerCase();
    if (busca.isEmpty) return null;

    // Busca direta pelo ID (Patrimônio)
    DocumentSnapshot doc = await _firestore.collection('inventario_mestre').doc(busca).get();
    if (doc.exists) {
      return AtivoModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }

    // Busca pelo campo Série
    QuerySnapshot querySerie = await _firestore
        .collection('inventario_mestre')
        .where('serie', isEqualTo: valor.trim())
        .limit(1)
        .get();
    
    if (querySerie.docs.isNotEmpty) {
      return AtivoModel.fromMap(
        querySerie.docs.first.data() as Map<String, dynamic>, 
        querySerie.docs.first.id
      );
    }
    return null;
  }

  // --- GESTÃO DO CASTELO ---
  Future<void> excluirItemMestre(String patrimonio) async {
    await _firestore.collection('inventario_mestre').doc(patrimonio).delete();
  }

  Future<void> resetarInventarioMestre() async {
    final QuerySnapshot mestreDocs = await _firestore.collection('inventario_mestre').get();
    WriteBatch batch = _firestore.batch();
    for (var doc in mestreDocs.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // --- FILTROS E INDICADORES (STREAMS) ---
  Stream<List<AtivoModel>> getItensEmManutencao() {
    return _firestore.collection('inventario_mestre')
        .where('status_operacional', isEqualTo: 'Em manutenção')
        .snapshots()
        .map((snap) => snap.docs.map((doc) => AtivoModel.fromMap(doc.data(), doc.id)).toList());
  }

  Stream<List<AtivoModel>> getItensPorSetor(String setor) {
    return _firestore.collection('inventario_mestre')
        .where('setor', isEqualTo: setor)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => AtivoModel.fromMap(doc.data(), doc.id)).toList());
  }

  Stream<List<AtivoModel>> getItensDivergentes() {
    return _firestore.collection('inventario_mestre')
        .where('setor_divergente', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => AtivoModel.fromMap(doc.data(), doc.id)).toList());
  }

  Stream<List<AtivoModel>> getItensComDefeito() {
    return _firestore.collection('inventario_mestre')
        .where('tem_defeito', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => AtivoModel.fromMap(doc.data(), doc.id)).toList());
  }

  Stream<List<AtivoModel>> getItensObsoletos() {
    final anoLimite = DateTime.now().year - 5;
    return _firestore.collection('inventario_mestre')
        .where('ano_fabricacao', isLessThanOrEqualTo: anoLimite)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => AtivoModel.fromMap(doc.data(), doc.id)).toList());
  }

  // --- ATUALIZAÇÕES ---
  Future<void> atualizarDadosCastelo({
    required String patrimonio,
    int? ano,
    double? valor,
    String? processador,
    String? macAddress,
  }) async {
    await _firestore.collection('inventario_mestre').doc(patrimonio).update({
      if (ano != null) 'ano_fabricacao': ano,
      if (valor != null) 'valor_compra': valor,
      if (processador != null) 'processador': processador,
      if (macAddress != null) 'mac_address': macAddress,
      'ultima_atualizacao': FieldValue.serverTimestamp(),
    });
  }
}
