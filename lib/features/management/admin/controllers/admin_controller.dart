import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../system/auth/models/user_model.dart';
import '../repositories/admin_repository.dart';

class AdminController {
  final AdminRepository _repository = AdminRepository();

  Future<void> createSector(String name) => _repository.addSector(name);
  Stream<List<Map<String, dynamic>>> get sectorsStream => _repository.getSectorsStream();
  Future<void> removeSector(String id) => _repository.deleteSector(id);
  Future<void> transferAssets(String from, String to) => _repository.transferAssetsBetweenSectors(from, to);

  Future<void> registerLog({required String action, required String details}) => 
      _repository.logAction(action: action, details: details);
  Stream<List<Map<String, dynamic>>> get logsStream => _repository.getLogsStream();

  Stream<List<UserModel>> get usersStream => _repository.getUsersStream();
  Future<void> suspendUser(String uid, String reason) => _repository.deactivateUser(uid: uid, reason: reason);
  Future<void> removeUser(String uid) => _repository.deleteUser(uid);

  Future<void> createLeasingCompany(String name) => _repository.addLeasingCompany(name);
  Stream<List<String>> get leasingCompaniesStream => _repository.getLeasingCompaniesStream();
  Future<void> removeLeasingCompany(String id) => _repository.deleteLeasingCompany(id);

  Future<void> updateCompanyBranding(Map<String, dynamic> config) => _repository.saveCompanyConfig(config);
  Stream<DocumentSnapshot> get brandingStream => _repository.getCompanyConfigStream();

  Future<void> updateGoals(Map<String, dynamic> goals) => _repository.saveGoalsConfig(goals);
  Stream<DocumentSnapshot> get goalsStream => _repository.getGoalsConfigStream();
}
