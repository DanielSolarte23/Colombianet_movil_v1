import 'package:flutter/foundation.dart';

class UserProvider extends ChangeNotifier {
  int _userId = 0;
  int _perfilId = 0;
  String _username = '';
  String _nombre = '';
  String _token = '';
  Map<String, dynamic> _userData = {};

  bool _isLoading = true; // 👈 bandera de carga

  // Getters
  int get userId => _userId;
  int get perfilId => _perfilId;
  String get username => _username;
  String get nombre => _nombre;
  String get token => _token;
  Map<String, dynamic> get userData => _userData;
  bool get isLoggedIn => _userId > 0 && _token.isNotEmpty;
  bool get isLoading => _isLoading; // 👈 getter para usar en main.dart

  // Setters
  void setUserData(Map<String, dynamic> data) {
    _userId = data['cuenta']?['id'] ?? 0;
    _perfilId = data['perfil']?['id'] ?? 0;
    _username = data['cuenta']?['username'] ?? '';
    _nombre = data['perfil']?['nombre'] ?? '';
    _token = data['token'] ?? '';
    _userData = data;
    _isLoading = false; // 👈 ya no está cargando
    notifyListeners();
  }

  void clearUserData() {
    _userId = 0;
    _perfilId = 0;
    _username = '';
    _nombre = '';
    _token = '';
    _userData = {};
    _isLoading = false; // 👈 asegura que no quede cargando
    notifyListeners();
  }

  Future<void> loadUserData() async {
    // Simulación de carga inicial (ej: SharedPreferences, API, etc.)
    await Future.delayed(Duration(seconds: 1));

    // 👇 Aquí podrías intentar recuperar token o sesión guardada
    // Si no hay nada, simplemente marca que terminó de cargar
    _isLoading = false;
    notifyListeners();
  }
}
