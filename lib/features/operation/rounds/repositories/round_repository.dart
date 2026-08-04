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
    List<Map<String, dynamic>>? exchanges,
  }) async {
    WriteBatch batch = _firestore.batch();
    
    DocumentReference roundRef = existingRoundId != null 
      ? _firestore.collection('rondas').doc(existingRoundId)
      : _firestore.collection('rondas').doc();
    
    // Só atualiza o documento da ronda se for nova ou se o usuário for Admin (Conforme Regras do Firebase)
    final bool isNew = existingRoundId == null;
    final bool isUserAdmin = await _checkIfAdmin();
    
    if (isNew || isUserAdmin) {
      batch.set(roundRef, round.toMap(), SetOptions(merge: true));
    }

    // Na edição, marcamos os itens antigos como substituídos em vez de deletar (Evita PERMISSION_DENIED)
    if (existingRoundId != null) {
      QuerySnapshot oldAssets = await roundRef.collection('equipamentos').get();
      for (var doc in oldAssets.docs) {
        batch.update(doc.reference, {'substituido_por_edicao': true});
      }
    }

    for (var asset in assets) {
      String inventoryId = _generateInventoryId(asset, round.setor);
      Map<String, dynamic> assetData = asset.toMap();
      assetData['patrimonio'] = inventoryId;

      // Grava o item na ronda atual
      DocumentReference assetRef = roundRef.collection('equipamentos').doc();
      batch.set(assetRef, assetData);
      
      // ATUALIZAÇÃO NO CASTELO: Liberdade total para transferir setor e mudar status
      DocumentReference invRef = _firestore.collection('inventario_mestre').doc(inventoryId);

      // Criamos um mapa de atualização seletivo completo para não perder dados de locação ou técnicos
      Map<String, dynamic> invUpdate = {
        'setor': round.setor,
        'tipo': asset.tipo,
        'marca': asset.marca,
        'modelo': asset.modelo,
        'serie': asset.serie,
        'is_locado': asset.isLocado, // Restaurado
        'locadora': asset.locadora,   // Restaurado
        'processador': asset.processador,
        'mac_address': asset.macAddress,
        'ano_fabricacao': asset.anoFabricacao, // Restaurado
        'status_operacional': asset.statusOperacional,
        'tem_defeito': asset.temDefeito,
        'descricao_defeito': asset.descricaoDefeito,
        'ultima_ronda_id': roundRef.id,
        'ultimo_tecnico': _auth.currentUser?.uid,
        'ultima_atualizacao': FieldValue.serverTimestamp(),
        'data_ultima_auditoria': FieldValue.serverTimestamp(),
        'acessorios': asset.acessorios,
        'home_office_autorizado': asset.homeOfficeAutorizado,
        'responsavel_externo': asset.responsavelExterno,
      };
      
      batch.set(invRef, invUpdate, SetOptions(merge: true));

      // Conversão de Sem Placa -> Com Placa
      if (asset.idAnterior != null && asset.idAnterior!.startsWith("SP_") && asset.idAnterior != inventoryId) {
        batch.update(_firestore.collection('inventario_mestre').doc(asset.idAnterior!), {
          'status': 'Inativo',
          'motivo_baixa': 'Convertido para patrimônio real: $inventoryId',
        });
      }
    }

    // Lógica de Trocas (Substituições)
    if (exchanges != null && exchanges.isNotEmpty) {
      for (var exchangeData in exchanges) {
        DocumentReference exchangeRef = roundRef.collection('equipamentos').doc();
        exchangeData['is_troca'] = true;
        batch.set(exchangeRef, exchangeData);

        String? patAntigo = exchangeData['patrimonio_antigo']?.toString().trim();
        if (patAntigo != null && patAntigo.isNotEmpty && patAntigo != "SEM PATRIMÔNIO") {
          DocumentReference oldAssetRef = _firestore.collection('inventario_mestre').doc(patAntigo);
          
          DateTime? dataTroca = exchangeData['hora_retirada'] != null 
              ? DateTime.tryParse(exchangeData['hora_retirada'].toString()) 
              : null;

          batch.update(oldAssetRef, {
            'setor': 'TI',
            'status_operacional': 'Em manutenção',
            'data_entrada_manutencao': dataTroca != null ? Timestamp.fromDate(dataTroca) : FieldValue.serverTimestamp(),
          });
        }
      }
    }
    
    await batch.commit();
  }

  String _generateInventoryId(AssetModel asset, String sector) {
    if (asset.patrimonio.startsWith("SP_")) return asset.patrimonio;
    if (asset.semPatrimonio) {
      if (asset.serie.isNotEmpty) return "SP_${asset.serie}";
      return "SP_${asset.tipo}_${sector}_${DateTime.now().millisecondsSinceEpoch}".toUpperCase();
    }
    return asset.patrimonio;
  }

  Stream<List<RoundModel>> getRoundsStream() {
    return _firestore.collection('rondas')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => RoundModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList());
  }

  Future<List<AssetModel>> getAssetsOfRound(String roundId) async {
    final snapshot = await _firestore.collection('rondas').doc(roundId).collection('equipamentos').get();
    return snapshot.docs
        .where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['is_troca'] != true && data['substituido_por_edicao'] != true;
        })
        .map((doc) => AssetModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
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

  Future<bool> _checkIfAdmin() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return false;
      final doc = await _firestore.collection('tecnicos').doc(uid).get();
      return doc.data()?['nivel_acesso'] == 'master' || doc.data()?['nivel_acesso'] == 'gerente';
    } catch (e) { return false; }
  }
}
