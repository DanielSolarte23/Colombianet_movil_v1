import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  final String baseUrl = "http://172.16.110.74:3004/api";
  
  Future<Map<String, dynamic>> login(String username, String password) async {
    final url = Uri.parse('$baseUrl/auth/inicio');
    
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: jsonEncode({'username': username, 'password': password}),
      );
      
      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'mensaje': responseData['message'] ?? 'Inicio de sesión exitoso',
          'token': responseData['token'],
          'cuenta': responseData['cuenta'],
          'perfil': responseData['perfil'],
        };
      } else {
        return {
          'success': false,
          'mensaje': responseData['message'] ?? 'Error: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'mensaje': 'Error de conexión al servidor: $e'};
    }
  }

  // Nueva función de logout
  Future<Map<String, dynamic>> logout() async {
    final url = Uri.parse('$baseUrl/auth/logout');
    
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        // Si necesitas enviar el token, agrégalo aquí:
        // headers: {
        //   'Content-Type': 'application/json; charset=utf-8',
        //   'Authorization': 'Bearer $token',
        // },
      );
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'mensaje': 'Sesión cerrada correctamente',
        };
      } else {
        final responseData = jsonDecode(response.body);
        return {
          'success': false,
          'mensaje': responseData['message'] ?? 'Error al cerrar sesión',
        };
      }
    } catch (e) {
      return {
        'success': false, 
        'mensaje': 'Error de conexión al servidor: $e'
      };
    }
  }
}