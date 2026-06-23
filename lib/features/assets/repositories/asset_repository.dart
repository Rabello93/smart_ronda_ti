import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/asset_model.dart';

class AssetRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<AssetModel?> getAssetByPatrimonyOrSerial(String value) async {
    String search = value.trim().toLowerCase();
    if (search.isEmpty) return null;

    // Busca direta pelo ID (Patrimônio)
    DocumentSnapshot doc = await _firestore.collection('inventario_mestre').doc(search).get();
    if (doc.exists) {
      return AssetModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
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

  Stream<List<AssetModel>> getAssetsByMaintenance() {
    return _firestore.collection('inventario_mestre')
        .where('status_operacional', isEqualTo: 'Em manutenção')
        .snapshots()
        .map((snap) => snap.docs.map((doc) => AssetModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList());
  }

  Stream<List<AssetModel>> getAssetsBySector(String sector) {
    return _firestore.collection('inventario_mestre')
        .where('setor', isEqualTo: sector)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => AssetModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList());
  }

  Stream<List<AssetModel>> getAssetsWithDivergence() {
    return _firestore.collection('inventario_mestre')
        .where('setor_divergente', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => AssetModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList());
  }

  Stream<List<AssetModel>> getAssetsWithDefects() {
    return _firestore.collection('inventario_mestre')
        .where('tem_defeito', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => AssetModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList());
  }

  Stream<List<AssetModel>> getObsoleteAssets() {
    final limitYear = DateTime.now().year - 5;
    return _firestore.collection('inventario_mestre')
        .where('ano_fabricacao', isLessThanOrEqualTo: limitYear)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => AssetModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList());
  }
}
