import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/asset_model.dart';

class AssetRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<AssetModel?> getAssetByPatrimonyOrSerial(String value) async {
    String search = value.trim(); // Removido .toLowerCase() para suportar IDs SP_...
    if (search.isEmpty) return null;

    // Busca direta pelo ID (Patrimônio)
    DocumentSnapshot doc = await _firestore.collection('inventario_mestre').doc(search).get();
    if (doc.exists) {
      return AssetModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }

    // Se não achou pelo ID exato, tenta a busca case-insensitive apenas para o ID
    // (Útil se o técnico digitar um patrimônio comum em minúsculo)
    if (!search.startsWith("SP_")) {
      DocumentSnapshot docLower = await _firestore.collection('inventario_mestre').doc(search.toLowerCase()).get();
      if (docLower.exists) {
        return AssetModel.fromMap(docLower.data() as Map<String, dynamic>, docLower.id);
      }
    }

    // Busca pelo campo Série
    QuerySnapshot querySerial = await _firestore
        .collection('inventario_mestre')
        .where('serie', isEqualTo: value.trim())
        .limit(1)
        .get();
    
    if (querySerial.docs.isNotEmpty) {
      return AssetModel.fromMap(
        querySerial.docs.first.data() as Map<String, dynamic>, 
        querySerial.docs.first.id
      );
    }
    return null;
  }

  Future<void> deleteAsset(String patrimony) async {
    await _firestore.collection('inventario_mestre').doc(patrimony).delete();
  }

  Future<void> updateAsset(String patrimony, Map<String, dynamic> data) async {
    await _firestore.collection('inventario_mestre').doc(patrimony).update({
      ...data,
      'ultima_atualizacao': FieldValue.serverTimestamp(),
    });
  }

  Future<void> renameAsset(String oldPatrimony, String newPatrimony) async {
    final docRef = _firestore.collection('inventario_mestre').doc(oldPatrimony);
    final newRef = _firestore.collection('inventario_mestre').doc(newPatrimony);

    final snapshot = await docRef.get();
    if (snapshot.exists) {
      final data = snapshot.data() as Map<String, dynamic>;
      data['patrimonio'] = newPatrimony;
      data['ultima_atualizacao'] = FieldValue.serverTimestamp();

      final batch = _firestore.batch();
      batch.set(newRef, data);
      batch.delete(docRef);
      await batch.commit();
    }
  }

  Future<void> resetInventory() async {
    final QuerySnapshot snapshot = await _firestore.collection('inventario_mestre').get();
    final WriteBatch batch = _firestore.batch();
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Stream<List<AssetModel>> getAssetsByMaintenance() {
    return _firestore.collection('inventario_mestre')
        .where('status_operacional', isEqualTo: 'Em manutenção')
        .snapshots()
        .map((snap) => snap.docs.map((doc) => AssetModel.fromMap(doc.data(), doc.id)).toList());
  }

  Stream<List<AssetModel>> getAssetsBySector(String sector) {
    return _firestore.collection('inventario_mestre')
        .where('setor', isEqualTo: sector)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => AssetModel.fromMap(doc.data(), doc.id)).toList());
  }

  Stream<List<AssetModel>> getAssetsWithDivergence() {
    return _firestore.collection('inventario_mestre')
        .where('setor_divergente', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => AssetModel.fromMap(doc.data(), doc.id)).toList());
  }

  Stream<List<AssetModel>> getAssetsWithDefects() {
    return _firestore.collection('inventario_mestre')
        .where('tem_defeito', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => AssetModel.fromMap(doc.data(), doc.id)).toList());
  }

  Stream<List<AssetModel>> getObsoleteAssets() {
    final limitYear = DateTime.now().year - 5;
    return _firestore.collection('inventario_mestre')
        .where('ano_fabricacao', isLessThanOrEqualTo: limitYear)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => AssetModel.fromMap(doc.data(), doc.id)).toList());
  }

  Stream<List<AssetModel>> getAssetsByHomeOffice() {
    return _firestore.collection('inventario_mestre')
        .where('home_office_autorizado', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => AssetModel.fromMap(doc.data(), doc.id)).toList());
  }

  Stream<List<AssetModel>> getAllAssetsStream() {
    return _firestore.collection('inventario_mestre')
        .snapshots()
        .map((snap) => snap.docs.map((doc) => AssetModel.fromMap(doc.data(), doc.id)).toList());
  }
}
