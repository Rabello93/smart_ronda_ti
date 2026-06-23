import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';

class AuthController {
  final AuthRepository _repository = AuthRepository();

  Stream<User?> get authStateChanges => _repository.authStateChanges;
  User? get currentUser => _repository.currentUser;

  Future<void> login(String email, String password) async {
    final res = await _repository.signIn(email, password);
    final userDoc = await _repository.getUserDoc(res.user!.uid);
    
    if (userDoc.exists) {
      final ativo = userDoc.get('ativo') ?? true;
      if (!ativo) {
        await _repository.signOut();
        throw Exception("Sua conta está desativada. Contate o administrador.");
      }
    }
  }

  Future<void> registerSimple({required String email, required String password}) {
    return _repository.signUp(email, password);
  }

  Future<void> registerFull(UserModel user, String password) async {
    final res = await _repository.signUp(user.email, password);
    await _repository.saveUser(user.copyWith(uid: res.user!.uid, ativo: false));
  }

  Future<void> updateProfile(UserModel user) => _repository.saveUser(user);

  Stream<UserModel?> get profileStream {
    final user = _repository.currentUser;
    if (user == null) return Stream.value(null);
    return _repository.getUserStream(user.uid);
  }

  Future<void> recoverPassword(String email) => _repository.sendPasswordReset(email);

  Future<void> logout() => _repository.signOut();
}

extension UserModelExtension on UserModel {
  UserModel copyWith({
    String? uid,
    String? nome,
    String? email,
    String? dataNascimento,
    String? funcao,
    String? localTrabalho,
    String? matricula,
    String? nivelAcesso,
    bool? ativo,
    DateTime? criadoEm,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      nome: nome ?? this.nome,
      email: email ?? this.email,
      dataNascimento: dataNascimento ?? this.dataNascimento,
      funcao: funcao ?? this.funcao,
      localTrabalho: localTrabalho ?? this.localTrabalho,
      matricula: matricula ?? this.matricula,
      nivelAcesso: nivelAcesso ?? this.nivelAcesso,
      ativo: ativo ?? this.ativo,
      criadoEm: criadoEm ?? this.criadoEm,
    );
  }
}
