import 'package:colombianet_app/controller/entregasController.dart';
import 'package:colombianet_app/views/EntregaDetalleScreen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';


class UnidadSeriada {
  final int id;
  final String serial;

  UnidadSeriada({required this.id, required this.serial});

  factory UnidadSeriada.fromJson(Map<String, dynamic> json) {
    return UnidadSeriada(id: json['id'] ?? 0, serial: json['serial'] ?? '');
  }
}




class EntregasResponse {
  final bool success;
  final int count;
  final Personal personal;
  final List<Entrega> entregas;

  EntregasResponse({
    required this.success,
    required this.count,
    required this.personal,
    required this.entregas,
  });

  factory EntregasResponse.fromJson(Map<String, dynamic> json) {
    return EntregasResponse(
      success: json['success'] ?? false,
      count: json['count'] ?? 0,
      // CORRECCIÓN CRÍTICA: Verificación de estructura anidada
      personal: json['data'] != null && json['data']['personal'] != null
          ? Personal.fromJson(json['data']['personal'] as Map<String, dynamic>)
          : Personal(
              id: 0,
              nombre: '',
              apellido: '',
              cedula: '',
              cargo: '',
              departamento: '',
              telefono: '',
              correo: '',
            ),
      entregas: json['data'] != null && json['data']['entregas'] != null
          ? (json['data']['entregas'] as List)
                .map((x) => Entrega.fromJson(x as Map<String, dynamic>))
                .toList()
          : [],
    );
  }
}

// Servicio para las API calls con mejor manejo de errores
class ApiService {
  static const String baseUrl = 'http://172.16.110.74:3004/api';

  static Future<EntregasResponse> getEntregasPersonal(int personalId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/personal/entregas/$personalId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        // CORRECCIÓN: Verificar que el body no esté vacío
        if (response.body.isEmpty) {
          throw Exception('Respuesta vacía del servidor');
        }

        final decodedData = json.decode(response.body);
        if (decodedData == null) {
          throw Exception('Datos nulos recibidos del servidor');
        }

        return EntregasResponse.fromJson(decodedData as Map<String, dynamic>);
      } else {
        throw Exception(
          'Error del servidor: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Error al cargar entregas: $e');
    }
  }

  static Future<Entrega> getEntregaDetalle(int entregaId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/entrega/$entregaId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          throw Exception('Respuesta vacía del servidor');
        }

        final decodedData = json.decode(response.body);
        if (decodedData == null || decodedData['data'] == null) {
          throw Exception('Datos nulos recibidos del servidor');
        }

        return Entrega.fromJson(decodedData['data'] as Map<String, dynamic>);
      } else {
        throw Exception(
          'Error del servidor: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Error al cargar detalle de entrega: $e');
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

      if (response.body.isEmpty) {
        return {'success': false, 'error': 'Respuesta vacía del servidor'};
      }

      return json.decode(response.body) as Map<String, dynamic>;
    } catch (e) {
      return {'success': false, 'error': 'Error al crear legalización: $e'};
    }
  }
}

// Vista principal - Lista de entregas
class EntregasTecnicoScreen extends StatefulWidget {
  final int personalId;

  const EntregasTecnicoScreen({Key? key, required this.personalId})
    : super(key: key);

  @override
  _EntregasTecnicoScreenState createState() => _EntregasTecnicoScreenState();
}

class _EntregasTecnicoScreenState extends State<EntregasTecnicoScreen> {
  late Future<EntregasResponse> _entregasFuture;

  static const Color _slate950 = Color(0xFF020617);
  static const Color _slate900 = Color(0xFF0F172A);
  static const Color _slate800 = Color(0xFF1E293B);
  static const Color _gray200 = Color(0xFFE5E7EB);
  static const Color _gray300 = Color(0xFFD1D5DB);
  static const Color _gray400 = Color(0xFF9CA3AF);
  static const Color _gray600 = Color(0xFF4B5563);
  static const Color _yellow500 = Color(0xFFf0b100);

  @override
  void initState() {
    super.initState();
    _entregasFuture = ApiService.getEntregasPersonal(widget.personalId);
  }

  Color _getEstadoColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return Colors.orange;
      case 'cerrada':
        return Colors.green;
      case 'cancelada':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getEstadoIcon(String estado) {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return Icons.pending_actions;
      case 'cerrada':
        return Icons.check_circle;
      case 'cancelada':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _slate900,
      appBar: AppBar(
        title: const Text('Mis Entregas'),
        backgroundColor: _slate950,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<EntregasResponse>(
        future: _entregasFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Error: ${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _entregasFuture = ApiService.getEntregasPersonal(
                          widget.personalId,
                        );
                      });
                    },
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.entregas.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No tienes entregas registradas'),
                ],
              ),
            );
          }

          final data = snapshot.data!;
          return Column(
            children: [
              // Header con información del técnico
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: _yellow500,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${data.personal.nombre} ${data.personal.apellido}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${data.personal.cargo} - ${data.personal.departamento}',
                    ),
                    Text('${data.count} entregas registradas'),
                  ],
                ),
              ),
              // Lista de entregas
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    setState(() {
                      _entregasFuture = ApiService.getEntregasPersonal(
                        widget.personalId,
                      );
                    });
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: data.entregas.length,
                    itemBuilder: (context, index) {
                      final entrega = data.entregas[index];
                      return EntregaCard(
                        entrega: entrega,
                        personalId: widget.personalId,
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// Widget para cada tarjeta de entrega
class EntregaCard extends StatelessWidget {
  final Entrega entrega;
  final int personalId;

  const EntregaCard({Key? key, required this.entrega, required this.personalId})
    : super(key: key);

  Color _getEstadoColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return Colors.orange;
      case 'cerrada':
        return Colors.green;
      case 'cancelada':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getEstadoIcon(String estado) {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return Icons.pending_actions;
      case 'cerrada':
        return Icons.check_circle;
      case 'cancelada':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('dd/MM/yyyy');
    final estadoColor = _getEstadoColor(entrega.estado);
    final estadoIcon = _getEstadoIcon(entrega.estado);

    return Card(
      color: _EntregasTecnicoScreenState._slate950,
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header de la tarjeta
            Row(
              children: [
                Expanded(
                  child: Text(
                    entrega.proyecto,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: estadoColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: estadoColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(estadoIcon, size: 16, color: estadoColor),
                      const SizedBox(width: 4),
                      Text(
                        entrega.estado.toUpperCase(),
                        style: TextStyle(
                          color: estadoColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Información de fechas
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Entrega: ${formatter.format(entrega.fecha)}',
                  style: TextStyle(color: Colors.grey[400]),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Devolución estimada: ${formatter.format(entrega.fechaEstimadaDevolucion)}',
                  style: TextStyle(color: Colors.grey[400]),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Información de productos
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _EntregasTecnicoScreenState._slate900,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.inventory, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    '${entrega.entregaProductos.length} producto(s)',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                  const Spacer(),
                  Text(
                    'Almacenista: ${entrega.almacenistaData.nombre}',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                ],
              ),
            ),

            if (entrega.wasConfirmed)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(Icons.verified, size: 16, color: Colors.green[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Confirmado',
                      style: TextStyle(
                        color: Colors.green[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // Botones de acción
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EntregaDetalleScreen(
                          entregaId: entrega.id,
                          personalId: personalId,
                          esDetalle: true,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.visibility,
                    color: _EntregasTecnicoScreenState._yellow500,
                  ),
                  label: const Text(
                    'Detalles',
                    style: TextStyle(color: Colors.amber),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed:
                      entrega.estado.toLowerCase() == 'pendiente' ||
                          entrega.estado.toLowerCase() ==
                              'parcialmente_devuelta'
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EntregaDetalleScreen(
                                entregaId: entrega.id,
                                personalId: personalId,
                                esDetalle: false,
                              ),
                            ),
                          );
                        }
                      : null,
                  icon: const Icon(Icons.fact_check),
                  label: const Text('Legalizar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
