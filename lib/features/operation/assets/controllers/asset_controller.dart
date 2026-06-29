import '../models/asset_model.dart';
import '../repositories/asset_repository.dart';

class AssetController {
  final AssetRepository _repository = AssetRepository();

  Future<AssetModel?> searchAsset(String value) {
    return _repository.getAssetByPatrimonyOrSerial(value);
  }

  Future<void> removeAsset(String patrimony) {
    return _repository.deleteAsset(patrimony);
  }

  Future<void> updateAssetTechnicalData({
    required String patrimony,
    String? processor,
    String? macAddress,
    int? year,
  }) {
    return _repository.updateAsset(patrimony, {
      if (processor != null) 'processador': processor,
      if (macAddress != null) 'mac_address': macAddress,
      if (year != null) 'ano_fabricacao': year,
    });
  }

  Stream<List<AssetModel>> getMaintenanceStream() => _repository.getAssetsByMaintenance();
  Stream<List<AssetModel>> getSectorStream(String sector) => _repository.getAssetsBySector(sector);
  Stream<List<AssetModel>> getDivergenceStream() => _repository.getAssetsWithDivergence();
  Stream<List<AssetModel>> getDefectsStream() => _repository.getAssetsWithDefects();
  Stream<List<AssetModel>> getObsoleteStream() => _repository.getObsoleteAssets();
  Stream<List<AssetModel>> getAllAssetsStream() => _repository.getAllAssetsStream();
}
