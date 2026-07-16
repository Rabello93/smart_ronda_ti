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
      String inventoryId = _generateInventoryId(asset, round.setor);
      Map<String, dynamic> assetData = asset.toMap();
      assetData['patrimonio'] = inventoryId;

      DocumentReference assetRef = roundRef.collection('equipamentos').doc();
      batch.set(assetRef, assetData);
      
      // Validação/Atualização no Castelo (Única fonte da verdade)
      DocumentReference invRef = _firestore.collection('inventario_mestre').doc(inventoryId);
      
      Map<String, dynamic> invData = Map.from(assetData);
      invData['ultima_ronda_id'] = roundRef.id;
      invData['ultimo_tecnico'] = _auth.currentUser?.uid;
      
      batch.set(invRef, invData, SetOptions(merge: true));

      // LOGICA DE CONVERSÃO: Se o item tinha um ID provisório (SP_...) e ganhou um real, remove o antigo
      if (asset.idAnterior != null && asset.idAnterior!.startsWith("SP_") && asset.idAnterior != inventoryId) {
        batch.delete(_firestore.collection('inventario_mestre').doc(asset.idAnterior));
      }
    }

    if (exchangeData != null) {
      DocumentReference exchangeRef = roundRef.collection('equipamentos').doc();
      exchangeData['is_troca'] = true;
      batch.set(exchangeRef, exchangeData);

      // INTELIGENCIA 3.2.7: Transferência automática do item substituído para a TI
      String? patAntigo = exchangeData['patrimonio_antigo']?.toString().trim();
      if (patAntigo != null && patAntigo.isNotEmpty && patAntigo != "SEM PATRIMÔNIO") {
        DocumentReference oldAssetRef = _firestore.collection('inventario_mestre').doc(patAntigo);
        batch.set(oldAssetRef, {
          'setor': 'TI',
          'status_operacional': 'Reservado',
          'observacao_interna': 'Substituído em ronda no setor ${round.setor}. Motivo: ${exchangeData['motivo'] ?? 'Não informado'}.',
          'data_ultima_substituicao': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    }
    
    await batch.commit();
  }

  String _generateInventoryId(AssetModel asset, String sector) {
    // Se o item já tem um código SP_... vindo do formulário, mantemos ele para evitar duplicatas
    if (asset.patrimonio.startsWith("SP_")) {
      return asset.patrimonio;
    }

    if (asset.semPatrimonio) {
      if (asset.serie.isNotEmpty) return "SP_${asset.serie}";
      // Gera novo ID apenas se for um item realmente novo (não carregado da lupa)
      return "SP_${asset.tipo}_${sector}_${DateTime.now().millisecondsSinceEpoch}".toUpperCase();
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
