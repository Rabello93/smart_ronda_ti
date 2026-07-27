import '../models/round_model.dart';
import '../repositories/round_repository.dart';
import '../../assets/models/asset_model.dart';

class RoundController {
  final RoundRepository _repository = RoundRepository();

  Future<void> finalizeRound({
    String? existingRoundId,
    required RoundModel round,
    required List<AssetModel> assets,
    List<Map<String, dynamic>>? exchanges,
  }) {
    return _repository.saveCompleteRound(
      existingRoundId: existingRoundId,
      round: round,
      assets: assets,
      exchanges: exchanges,
    );
  }

  Stream<List<RoundModel>> getHistoryStream() => _repository.getRoundsStream();

  Future<List<AssetModel>> getRoundAssets(String roundId) => _repository.getAssetsOfRound(roundId);

  Future<void> removeRound(String roundId) => _repository.deleteRound(roundId);
}
