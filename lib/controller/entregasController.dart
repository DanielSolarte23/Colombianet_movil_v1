import 'package:http/http.dart' as http;
import 'dart:convert';

class Personal {
  final int id;
  final String nombre;
  final String apellido;
  final String cedula;
  final String cargo;
  final String departamento;
  final String telefono;
  final String correo;

  Personal({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.cedula,
    required this.cargo,
    required this.departamento,
    required this.telefono,
    required this.correo,
  });

  factory Personal.fromJson(Map<String, dynamic> json) {
    return Personal(
      id: json['id'] ?? 0,
      nombre: json['nombre'] ?? '',
      apellido: json['apellido'] ?? '',
      cedula: json['cedula'] ?? '',
      cargo: json['cargo'] ?? '',
      departamento: json['departamento'] ?? '',
      telefono: json['telefono'] ?? '',
      correo: json['correo'] ?? '',
    );
  }
}

class Producto {
  final int id;
  final String codigo;
  final String descripcion;
  final String marca;
  final String modelo;
  final String color;
  final String unidadMedida;

  Producto({
    required this.id,
    required this.codigo,
    required this.descripcion,
    required this.marca,
    required this.modelo,
    required this.color,
    required this.unidadMedida,
  });

  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      id: json['id'] ?? 0,
      codigo: json['codigo'] ?? '',
      descripcion: json['descripcion'] ?? '',
      marca: json['marca'] ?? '',
      modelo: json['modelo'] ?? '',
      color: json['color'] ?? '',
      unidadMedida: json['unidadMedida'] ?? '',
    );
  }
}

class UnidadSeriada {
  final int id;
  final String serial;

  UnidadSeriada({required this.id, required this.serial});

  factory UnidadSeriada.fromJson(Map<String, dynamic> json) {
    return UnidadSeriada(id: json['id'] ?? 0, serial: json['serial'] ?? '');
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UnidadSeriada && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class EntregaProducto {
  final int id;
  final int cantidad;
  final String descripcion;
  final String? serial;
  final String marca;
  final String color;
  final int devuelto;
  final int legalizado;
  final String estado;
  final List<int>? unidadesSeriadas;
  final Producto producto;
  final List<UnidadSeriada>? unidadesSeriadasDetalle;

  EntregaProducto({
    required this.id,
    required this.cantidad,
    required this.descripcion,
    this.serial,
    required this.marca,
    required this.color,
    required this.devuelto,
    required this.legalizado,
    required this.estado,
    this.unidadesSeriadas,
    required this.producto,
    this.unidadesSeriadasDetalle,
  });

  factory EntregaProducto.fromJson(Map<String, dynamic> json) {
    return EntregaProducto(
      id: json['id'] ?? 0,
      cantidad: json['cantidad'] ?? 0,
      descripcion: json['descripcion'] ?? '',
      serial: json['serial'],
      marca: json['marca'] ?? '',
      color: json['color'] ?? '',
      devuelto: json['devuelto'] ?? 0,
      legalizado: json['legalizado'] ?? 0,
      estado: json['estado'] ?? '',
      unidadesSeriadas: json['unidadesSeriadas']?.cast<int>(),
      // CORRECCIÓN CRÍTICA: Verificar que el JSON no sea null antes de parsearlo
      producto: json['Producto'] != null
          ? Producto.fromJson(json['Producto'] as Map<String, dynamic>)
          : Producto(
              id: 0,
              codigo: '',
              descripcion: '',
              marca: '',
              modelo: '',
              color: '',
              unidadMedida: '',
            ),
      unidadesSeriadasDetalle: json['unidadesSeriadasDetalle'] != null
          ? (json['unidadesSeriadasDetalle'] as List)
                .map((x) => UnidadSeriada.fromJson(x as Map<String, dynamic>))
                .toList()
          : null,
    );
  }
}

class Almacenista {
  final int id;
  final String nombre;
  final String? username;

  Almacenista({required this.id, required this.nombre, this.username});

  factory Almacenista.fromJson(Map<String, dynamic> json) {
    return Almacenista(
      id: json['id'],
      nombre: json['nombre'],
      // username: json['username'],
    );
  }
}

class TecnicoData {
  final int id;
  final String nombre;
  final String cedula;
  final String cargo;

  TecnicoData({
    required this.id,
    required this.nombre,
    required this.cedula,
    required this.cargo,
  });

  factory TecnicoData.fromJson(Map<String, dynamic> json) {
    return TecnicoData(
      id: json['id'],
      nombre: json['nombre'],
      cedula: json['cedula'],
      cargo: json['cargo'],
    );
  }
}

class Entrega {
  final int id;
  final DateTime fecha;
  final String proyecto;
  final String observaciones;
  final String estado;
  final bool wasConfirmed;
  final DateTime fechaEstimadaDevolucion;
  final DateTime? fechaCierre;
  final List<EntregaProducto> entregaProductos;
  final Almacenista almacenistaData;
  final TecnicoData? tecnicoData;

  Entrega({
    required this.id,
    required this.fecha,
    required this.proyecto,
    required this.observaciones,
    required this.estado,
    required this.wasConfirmed,
    required this.fechaEstimadaDevolucion,
    this.fechaCierre,
    required this.entregaProductos,
    required this.almacenistaData,
    this.tecnicoData,
  });

  factory Entrega.fromJson(Map<String, dynamic> json) {
    return Entrega(
      id: json['id'],
      fecha: DateTime.parse(json['fecha']),
      proyecto: json['proyecto'],
      observaciones: json['observaciones'] ?? '',
      estado: json['estado'],
      wasConfirmed: json['wasConfirmed'] ?? false,
      fechaEstimadaDevolucion: DateTime.parse(json['fechaEstimadaDevolucion']),
      fechaCierre: json['fechaCierre'] != null
          ? DateTime.parse(json['fechaCierre'])
          : null,
      entregaProductos: (json['EntregaProductos'] as List)
          .map((x) => EntregaProducto.fromJson(x))
          .toList(),
      almacenistaData: Almacenista.fromJson(json['almacenistaData']),
      tecnicoData: json['tecnicoData'] != null
          ? TecnicoData.fromJson(json['tecnicoData'])
          : null,
    );
  }
}

// Servicio para las API calls
class ApiService {
  static const String baseUrl = 'http://172.16.110.74:3004/api';

  static Future<Entrega> getEntregaDetalle(int entregaId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/entrega/$entregaId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return Entrega.fromJson(data['data']);
        } else {
          throw Exception(data['message'] ?? 'Error al obtener la entrega');
        }
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  static Future<Map<String, dynamic>> crearLegalizacion(
    Map<String, dynamic> legalizacionData,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/legalizacion'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(legalizacionData),
      );

      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }
}
