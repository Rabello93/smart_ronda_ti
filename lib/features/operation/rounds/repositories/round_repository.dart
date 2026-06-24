import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/round_model.dart';
import '../../assets/models/asset_model.dart';

class RoundRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> saveCompleteRound({
    String? existingRoundId,
    required RoundModel round,
    required List<AssetModel> assets,
    Map<String, dynamic>? exchangeData,
  }) async {
    WriteBatch batch = _firestore.batch();
    
    DocumentReference roundRef = existingRoundId != null 
      ? _firestore.collection('rondas').doc(existingRoundId)
      : _firestore.collection('rondas').doc();
    
    batch.set(roundRef, round.toMap(), SetOptions(merge: true));

    if (existingRoundId != null) {
      QuerySnapshot oldAssets = await roundRef.collection('equipamentos').get();
      for (var doc in oldAssets.docs) {
        batch.delete(doc.reference);
      }
    }

    for (var asset in assets) {
      DocumentReference assetRef = roundRef.collection('equipamentos').doc();
      batch.set(assetRef, asset.toMap());
      
      // Validação/Atualização no Castelo (Única fonte da verdade)
      String inventoryId = _generateInventoryId(asset, round.setor);
      DocumentReference invRef = _firestore.collection('inventario_mestre').doc(inventoryId);
      
      Map<String, dynamic> invData = asset.toMap();
      invData['ultima_ronda_id'] = roundRef.id;
      invData['ultimo_tecnico'] = _auth.currentUser?.uid;
      
      batch.set(invRef, invData, SetOptions(merge: true));
    }

    if (exchangeData != null) {
      DocumentReference exchangeRef = roundRef.collection('equipamentos').doc();
      exchangeData['is_troca'] = true;
      batch.set(exchangeRef, exchangeData);
    }
    
    await batch.commit();
  }

  String _generateInventoryId(AssetModel asset, String sector) {
    if (asset.semPatrimonio) {
      if (asset.serie.isNotEmpty) return "SP_${asset.serie}";
      return "SP_${asset.tipo}_$sector".toUpperCase();
    }
    return asset.patrimonio;
  }

  Stream<List<RoundModel>> getRoundsStream() {
    return _firestore.collection('rondas')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => RoundModel.fromMap(doc.data(), doc.id)).toList());
  }

  Future<List<AssetModel>> getAssetsOfRound(String roundId) async {
    final snapshot = await _firestore
        .collection('rondas')
        .doc(roundId)
        .collection('equipamentos')
        .get();
    
    return snapshot.docs
        .where((doc) => doc.data()['is_troca'] != true)
        .map((doc) => AssetModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<void> deleteRound(String roundId) async {
    WriteBatch batch = _firestore.batch();
    QuerySnapshot equips = await _firestore.collection('rondas').doc(roundId).collection('equipamentos').get();
    for (var doc in equips.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_firestore.collection('rondas').doc(roundId));
    await batch.commit();
  }
}
