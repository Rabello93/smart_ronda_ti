import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/usuario_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream que monitora o estado da autenticação (logado ou não)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Retorna o usuário atual do Firebase Auth
  User? get currentUser => _auth.currentUser;

  // Faz o login e já verifica se o usuário está ativo no Firestore
  Future<void> login(String email, String password) async {
    UserCredential res = await _auth.signInWithEmailAndPassword(email: email, password: password);
    
    DocumentSnapshot userDoc = await _firestore.collection('tecnicos').doc(res.user!.uid).get();
    
    if (userDoc.exists) {
      bool ativo = userDoc.get('ativo') ?? true;
      if (!ativo) {
        await _auth.signOut();
        throw Exception("Sua conta está desativada. Contate o administrador.");
      }
    }
  }

  // Cadastro inicial (apenas e-mail e senha)
  Future<void> cadastrarApenasAuth({required String email, required String password}) async {
    await _auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  // Cadastro completo do técnico salvando no Firestore usando o Modelo
  Future<void> cadastrarTecnico(UsuarioModel usuario, String password) async {
    UserCredential res = await _auth.createUserWithEmailAndPassword(
      email: usuario.email, 
      password: password
    );
    
    // Salva os dados no Firestore usando o toMap() do modelo
    await _firestore.collection('tecnicos').doc(res.user!.uid).set(
      usuario.copyWith(uid: res.user!.uid, ativo: false).toMap()
    );
  }

  // Atualiza o perfil do usuário
  Future<void> atualizarPerfil(UsuarioModel usuario) async {
    await _firestore.collection('tecnicos').doc(usuario.uid).set(
      usuario.toMap(), 
      SetOptions(merge: true)
    );
  }

  // Stream do perfil do usuário logado (usando o Modelo)
  Stream<UsuarioModel?> getPerfilStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(null);
    
    return _firestore.collection('tecnicos').doc(user.uid).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return UsuarioModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    });
  }

  // Recuperação de senha
  Future<void> recuperarSenha(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
  }
}

// Extensão para facilitar a criação de cópias do modelo com dados alterados
extension UsuarioModelExtension on UsuarioModel {
  UsuarioModel copyWith({
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
    return UsuarioModel(
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
