import 'package:colombianet_app/controller/entregasController.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class EntregaDetalleScreen extends StatefulWidget {
  final int entregaId;
  final int personalId;
  final bool esDetalle;

  const EntregaDetalleScreen({
    Key? key,
    required this.entregaId,
    required this.personalId,
    required this.esDetalle,
  }) : super(key: key);

  @override
  _EntregaDetalleScreenState createState() => _EntregaDetalleScreenState();
}

class _EntregaDetalleScreenState extends State<EntregaDetalleScreen> {
  late Future<Entrega> _entregaFuture;
  final _formKey = GlobalKey<FormState>();

  static const Color _slate950 = Color(0xFF020617);
  static const Color _slate900 = Color(0xFF0F172A);
  static const Color _slate800 = Color(0xFF1E293B);
  static const Color _gray200 = Color(0xFFE5E7EB);
  static const Color _gray300 = Color(0xFFD1D5DB);
  static const Color _gray400 = Color(0xFF9CA3AF);
  static const Color _gray600 = Color(0xFF4B5563);
  static const Color _yellow500 = Color(0xFFf0b100);

  // Controladores para el formulario de legalización
  final _tipoController = TextEditingController();
  final _justificacionController = TextEditingController();
  final _observacionesController = TextEditingController();
  final _ubicacionController = TextEditingController();

  // Lista de productos seleccionados para legalización
  Map<int, ProductoLegalizacion> productosLegalizacion = {};

  // Tipos de legalización disponibles
  final List<String> tiposLegalizacion = [
    "instalado",
    "consumido",
    "perdido",
    "dañado",
    "donado",
    "otro",
  ];

  @override
  void initState() {
    super.initState();
    _entregaFuture = ApiService.getEntregaDetalle(widget.entregaId);
    _tipoController.text = 'instalado';
  }

  @override
  void dispose() {
    _tipoController.dispose();
    _justificacionController.dispose();
    _observacionesController.dispose();
    _ubicacionController.dispose();
    super.dispose();
  }

  void _inicializarProductosLegalizacion(List<EntregaProducto> productos) {
    productosLegalizacion.clear();
    for (var producto in productos) {
      if (producto.estado.toLowerCase() == 'pendiente' ||
          producto.estado.toLowerCase() == 'devuelto_parcial') {
        int cantidadPendiente =
            producto.cantidad - producto.devuelto - producto.legalizado;
        if (cantidadPendiente > 0) {
          productosLegalizacion[producto.id] = ProductoLegalizacion(
            productoId: producto.producto.id,
            entregaProductoId: producto.id,
            cantidad: 0,
            cantidadMaxima: cantidadPendiente,
            tieneSeriales:
                producto.unidadesSeriadas != null &&
                producto.unidadesSeriadas!.isNotEmpty,
            unidadesSeriadasDisponibles: producto.unidadesSeriadasDetalle ?? [],
            unidadesSeleccionadas: [],
            producto: producto,
          );
        }
      }
    }
  }

   void _onProductoLegalizacionChanged(
    int entregaProductoId,
    int cantidad,
    List<UnidadSeriada>? unidades,
  ) {
    print('DEBUG: Callback ejecutado para producto $entregaProductoId con cantidad $cantidad');
    setState(() {
      if (productosLegalizacion.containsKey(entregaProductoId)) {
        final productoAnterior = productosLegalizacion[entregaProductoId]!;
        
        productosLegalizacion[entregaProductoId] = productoAnterior.copyWith(
          cantidad: cantidad,
          unidadesSeleccionadas: unidades,
        );
        
        print('DEBUG: Producto actualizado. Nueva cantidad: ${productosLegalizacion[entregaProductoId]!.cantidad}');
        print('DEBUG: Total productos con cantidad > 0: ${productosLegalizacion.values.where((p) => p.cantidad > 0).length}');
      }
    });
  }

  Future<void> _enviarLegalizacion() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validar que al menos un producto esté seleccionado
    final productosALegalizar = productosLegalizacion.values
        .where((p) => p.cantidad > 0)
        .toList();

    if (productosALegalizar.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Debes seleccionar al menos un producto para legalizar',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validar productos con seriales
    for (var producto in productosALegalizar) {
      if (producto.tieneSeriales) {
        if (producto.unidadesSeleccionadas.length != producto.cantidad) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Para ${producto.producto.descripcion}: debes seleccionar ${producto.cantidad} unidades seriadas',
              ),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }
    }

    // Crear estructura JSON para enviar
    final legalizacionData = {
      'entregaId': widget.entregaId,
      'personalId': widget.personalId,
      'tipo': _tipoController.text,
      'justificacion': _justificacionController.text,
      'observaciones': _observacionesController.text,
      'ubicacion': _ubicacionController.text,
      'evidencia': [], // Por ahora vacío, podrías implementar subida de fotos
      'productos': productosALegalizar.map((p) {
        final map = {'productoId': p.productoId, 'cantidad': p.cantidad};

        if (p.tieneSeriales && p.unidadesSeleccionadas.isNotEmpty) {
          map['unidadesSeriadas'] = p.unidadesSeleccionadas.first.id;
        }

        return map;
      }).toList(),
    };

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Expanded(child: Text('Enviando legalización...')),
            ],
          ),
        ),
      );

      final response = await ApiService.crearLegalizacion(legalizacionData);
      Navigator.pop(context); // Cerrar loading

      if (response['success'] == true) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('¡Éxito!'),
            content: Text(
              response['message'] ?? 'Legalización enviada correctamente',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Cerrar diálogo
                  Navigator.pop(context); // Regresar a la lista
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response['error'] ?? response['message'] ?? 'Error desconocido',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Cerrar loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error de conexión: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _slate900,
      appBar: AppBar(
        title: Text(
          widget.esDetalle ? 'Detalle de Entrega' : 'Legalizar Entrega',
        ),
        backgroundColor: widget.esDetalle ? _slate950 : _slate950,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<Entrega>(
        future: _entregaFuture,
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
                  Text('Error: ${snapshot.error}'),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _entregaFuture = ApiService.getEntregaDetalle(
                          widget.entregaId,
                        );
                      });
                    },
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          final entrega = snapshot.data!;

          if (!widget.esDetalle && productosLegalizacion.isEmpty) {
            _inicializarProductosLegalizacion(entrega.entregaProductos);
          }

          return widget.esDetalle
              ? _buildDetalleView(entrega)
              : _buildLegalizacionView(entrega);
        },
      ),
    );
  }

  Widget _buildDetalleView(Entrega entrega) {
    final formatter = DateFormat('dd/MM/yyyy');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header de la entrega
          Card(
            color: _slate950,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entrega.proyecto,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Estado: ${entrega.estado.toUpperCase()}',
                    style: TextStyle(
                      color: _getEstadoColor(entrega.estado),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Fecha: ${formatter.format(entrega.fecha)}',
                        style: TextStyle(color: Colors.grey[300]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.schedule, size: 16, color: Colors.grey[300]),
                      const SizedBox(width: 8),
                      Text(
                        'Devolución: ${formatter.format(entrega.fechaEstimadaDevolucion)}',
                        style: TextStyle(color: Colors.grey[300]),
                      ),
                    ],
                  ),
                  if (entrega.observaciones.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Observaciones: ${entrega.observaciones}',
                      style: TextStyle(color: Colors.grey[300]),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Lista de productos
          const Text(
            'Productos Entregados',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),

          ...entrega.entregaProductos
              .map((producto) => ProductoDetalleCard(producto: producto))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildLegalizacionView(Entrega entrega) {
    final productosDisponibles = productosLegalizacion.values
        .where((p) => p.cantidadMaxima > 0)
        .toList();


    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header de la entrega
            Card(
              color: _slate950,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entrega.proyecto,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ID: ${entrega.id}',
                      style: TextStyle(color: Colors.grey[300]),
                    ),
                    Text(
                      'Fecha: ${DateFormat('dd/MM/yyyy').format(entrega.fecha)}',
                      style: TextStyle(color: Colors.grey[300]),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Formulario de legalización
            const Text(
              'Información de Legalización',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),

            // Tipo de legalización
            DropdownButtonFormField<String>(
              dropdownColor: _slate950, // Fondo del menú desplegable
              style: const TextStyle(color: _slate900),

              value: _tipoController.text,
              decoration: InputDecoration(
                labelText: 'Tipo de Legalización',
                labelStyle: const TextStyle(color: Colors.white),
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: _slate900, // Fondo oscuro del campo
              ),
              items: tiposLegalizacion
                  .map(
                    (tipo) => DropdownMenuItem(
                      value: tipo,
                      child: Text(
                        tipo.capitalize(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _tipoController.text = value!;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Selecciona un tipo';
                }
                return null;
              },
            ),

            const SizedBox(height: 12),

            // Justificación
            TextFormField(
              controller: _justificacionController,
              style: TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Justificación',
                labelStyle: TextStyle(color: Colors.white),
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: _yellow500),
                ),
                hintText: 'Describe la razón de la legalización...',
                hintStyle: TextStyle(color: Colors.grey),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'La justificación es requerida';
                }
                if (value.length < 10) {
                  return 'La justificación debe tener al menos 10 caracteres';
                }
                return null;
              },
            ),

            const SizedBox(height: 12),

            // Ubicación
            TextFormField(
              controller: _ubicacionController,
              style: TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Ubicación',
                labelStyle: TextStyle(color: Colors.white),
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: _yellow500),
                ),
                hintText: 'Ej: Torre Norte - Piso 3',
                hintStyle: TextStyle(color: Colors.grey),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'La ubicación es requerida';
                }
                return null;
              },
            ),

            const SizedBox(height: 12),

            // Observaciones (opcional)
            TextFormField(
              controller: _observacionesController,
              style: TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Observaciones (opcional)',
                labelStyle: TextStyle(color: Colors.white),
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: _yellow500),
                ),
              ),
              maxLines: 2,
            ),

            const SizedBox(height: 24),

            // Productos disponibles
            const Text(
              'Productos a Legalizar',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),

            ...productosDisponibles
                .map(
                  (producto) => ProductoLegalizacionCard(
                    key: ValueKey(producto.entregaProductoId),
                    productoLegalizacion: producto,
                    onChanged: (cantidad, unidades) {
                      // ✅ Callback corregido
                      _onProductoLegalizacionChanged(
                        producto.entregaProductoId,
                        cantidad,
                        unidades,
                      );
                    },
                  ),
                )
                .toList(),

            const SizedBox(height: 24),

            // Resumen de productos seleccionados
            if (productosLegalizacion.values.any((p) => p.cantidad > 0)) ...[
              Card(
                color: _slate950,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Resumen de Legalización',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...productosLegalizacion.values
                          .where((p) => p.cantidad > 0)
                          .map(
                            (p) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      p.producto.descripcion,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    'Cantidad: ${p.cantidad}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Botón para enviar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _enviarLegalizacion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Enviar Legalización',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
}

class ProductoLegalizacion {
  final int productoId;
  final int entregaProductoId;
  int cantidad;
  final int cantidadMaxima;
  final bool tieneSeriales;
  final List<UnidadSeriada> unidadesSeriadasDisponibles;
  List<UnidadSeriada> unidadesSeleccionadas;
  final EntregaProducto producto;

  ProductoLegalizacion({
    required this.productoId,
    required this.entregaProductoId,
    required this.cantidad,
    required this.cantidadMaxima,
    required this.tieneSeriales,
    required this.unidadesSeriadasDisponibles,
    required this.unidadesSeleccionadas,
    required this.producto,
  });

  // ✅ Método copyWith agregado
  ProductoLegalizacion copyWith({
    int? cantidad,
    List<UnidadSeriada>? unidadesSeleccionadas,
  }) {
    return ProductoLegalizacion(
      productoId: this.productoId,
      entregaProductoId: this.entregaProductoId,
      cantidad: cantidad ?? this.cantidad,
      cantidadMaxima: this.cantidadMaxima,
      tieneSeriales: this.tieneSeriales,
      unidadesSeriadasDisponibles: this.unidadesSeriadasDisponibles,
      unidadesSeleccionadas: unidadesSeleccionadas ?? this.unidadesSeleccionadas,
      producto: this.producto,
    );
  }
}



// Widget para mostrar detalle de un producto
class ProductoDetalleCard extends StatelessWidget {
  final EntregaProducto producto;

  const ProductoDetalleCard({Key? key, required this.producto})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: _EntregaDetalleScreenState._slate950,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    producto.descripcion,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getEstadoColor(producto.estado).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _getEstadoColor(producto.estado)),
                  ),
                  child: Text(
                    producto.estado.toUpperCase(),
                    style: TextStyle(
                      color: _getEstadoColor(producto.estado),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Text(
              'Código: ${producto.producto.codigo}',
              style: TextStyle(color: Colors.grey),
            ),
            Text(
              'Marca: ${producto.marca}',
              style: TextStyle(color: Colors.grey),
            ),

            // if (producto.color.isNotEmpty && producto.color != 'N/A')
            //   Text('Color: ${producto.color}',style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: _buildCantidadInfo(
                    'Entregado',
                    producto.cantidad,
                    Colors.blue,
                  ),
                ),
                if (producto.devuelto > 0)
                  Expanded(
                    child: _buildCantidadInfo(
                      'Devuelto',
                      producto.devuelto,
                      Colors.orange,
                    ),
                  ),
                if (producto.legalizado > 0)
                  Expanded(
                    child: _buildCantidadInfo(
                      'Legalizado',
                      producto.legalizado,
                      Colors.green,
                    ),
                  ),
              ],
            ),

            // Mostrar unidades seriadas si las tiene
            if (producto.unidadesSeriadasDetalle != null &&
                producto.unidadesSeriadasDetalle!.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Unidades Seriadas:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: producto.unidadesSeriadasDetalle!
                    .map(
                      (unidad) => Chip(
                        label: Text(unidad.serial),
                        backgroundColor: Colors.grey.shade200,
                        labelStyle: const TextStyle(fontSize: 12),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCantidadInfo(String label, int cantidad, Color color) {
    return Column(
      children: [
        Text(
          cantidad.toString(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: color)),
      ],
    );
  }

  Color _getEstadoColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return Colors.orange;
      case 'cerrado':
        return Colors.green;
      case 'cancelado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

// Widget para seleccionar productos a legalizar
class ProductoLegalizacionCard extends StatefulWidget {
  final ProductoLegalizacion productoLegalizacion;
  final Function(int cantidad, List<UnidadSeriada>? unidades) onChanged;

  const ProductoLegalizacionCard({
    Key? key,
    required this.productoLegalizacion,
    required this.onChanged,
  }) : super(key: key);

  @override
  _ProductoLegalizacionCardState createState() =>
      _ProductoLegalizacionCardState();
}

class _ProductoLegalizacionCardState extends State<ProductoLegalizacionCard> {
  late int _cantidad;
  late List<UnidadSeriada> _unidadesSeleccionadas;
  late TextEditingController _cantidadController; // Agregar el controller

  @override
  void initState() {
    super.initState();
    _cantidad = widget.productoLegalizacion.cantidad;
    _unidadesSeleccionadas = List.from(
      widget.productoLegalizacion.unidadesSeleccionadas,
    );
    // Inicializar el controller
    _cantidadController = TextEditingController(text: _cantidad.toString());
  }

  @override
  void dispose() {
    // Importante: liberar el controller
    _cantidadController.dispose();
    super.dispose();
  }

  void _updateCantidad(int nuevaCantidad) {
    setState(() {
      _cantidad = nuevaCantidad;
      // Actualizar el controller cuando cambie la cantidad programáticamente
      _cantidadController.text = _cantidad.toString();

      // Si tiene seriales, ajustar la selección
      if (widget.productoLegalizacion.tieneSeriales) {
        if (nuevaCantidad == 0) {
          _unidadesSeleccionadas.clear();
        } else if (_unidadesSeleccionadas.length != nuevaCantidad) {
          // Ajustar la cantidad de unidades seleccionadas
          if (_unidadesSeleccionadas.length > nuevaCantidad) {
            _unidadesSeleccionadas = _unidadesSeleccionadas
                .take(nuevaCantidad)
                .toList();
          }
        }
      }

      widget.onChanged(
        _cantidad,
        widget.productoLegalizacion.tieneSeriales
            ? _unidadesSeleccionadas
            : null,
      );
    });
  }

  void _toggleUnidadSeriada(UnidadSeriada unidad) {
    setState(() {
      if (_unidadesSeleccionadas.contains(unidad)) {
        _unidadesSeleccionadas.remove(unidad);
      } else {
        if (_unidadesSeleccionadas.length <
            widget.productoLegalizacion.cantidadMaxima) {
          _unidadesSeleccionadas.add(unidad);
        }
      }

      _cantidad = _unidadesSeleccionadas.length;
      // Actualizar el controller también aquí
      _cantidadController.text = _cantidad.toString();
      widget.onChanged(_cantidad, _unidadesSeleccionadas);
    });
  }

  @override
  Widget build(BuildContext context) {
    final producto = widget.productoLegalizacion.producto;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: _cantidad > 0 ? 4 : 2,
      color: _cantidad > 0 ? Colors.green.shade50 : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header del producto
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        producto.descripcion,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text('Código: ${producto.producto.codigo}'),
                      Text(
                        'Disponible: ${widget.productoLegalizacion.cantidadMaxima}',
                      ),
                      if (widget.productoLegalizacion.tieneSeriales)
                        Text(
                          'Producto seriado',
                          style: TextStyle(
                            color: Colors.blue.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
                Switch(
                  value: _cantidad > 0,
                  onChanged: (value) {
                    _updateCantidad(value ? 1 : 0);
                  },
                  activeColor: Colors.green,
                ),
              ],
            ),

            if (_cantidad > 0) ...[
              const SizedBox(height: 12),

              // Selector de cantidad (solo si no tiene seriales)
              if (!widget.productoLegalizacion.tieneSeriales) ...[
                Row(
                  children: [
                    const Text('Cantidad a legalizar: '),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: _cantidad > 1
                                ? () => _updateCantidad(_cantidad - 1)
                                : null,
                            icon: const Icon(Icons.remove),
                          ),
                          SizedBox(
                            width: 70,
                            child: TextField(
                              controller:
                                  _cantidadController, // Usar el controller persistente
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              onSubmitted: (value) {
                                final cantidad =
                                    int.tryParse(value) ?? _cantidad;
                                if (cantidad >= 1 &&
                                    cantidad <=
                                        widget
                                            .productoLegalizacion
                                            .cantidadMaxima) {
                                  _updateCantidad(cantidad);
                                } else {
                                  // Si el valor no es válido, restaurar el valor anterior
                                  _cantidadController.text = _cantidad
                                      .toString();
                                }
                              },
                              // Opcional: manejar cambios mientras escribe
                              onChanged: (value) {
                                // Solo actualizar si el valor es válido al perder el foco
                                // o presionar enter (manejado en onSubmitted)
                              },
                            ),
                          ),
                          IconButton(
                            onPressed:
                                _cantidad <
                                    widget.productoLegalizacion.cantidadMaxima
                                ? () => _updateCantidad(_cantidad + 1)
                                : null,
                            icon: const Icon(Icons.add),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],

              // Selector de unidades seriadas
              if (widget.productoLegalizacion.tieneSeriales) ...[
                const Text(
                  'Selecciona las unidades a legalizar:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (widget
                    .productoLegalizacion
                    .unidadesSeriadasDisponibles
                    .isEmpty)
                  const Text(
                    'No hay unidades seriadas disponibles',
                    style: TextStyle(
                      color: Colors.orange,
                      fontStyle: FontStyle.italic,
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget
                        .productoLegalizacion
                        .unidadesSeriadasDisponibles
                        .map((unidad) {
                          final isSelected = _unidadesSeleccionadas.contains(
                            unidad,
                          );
                          return FilterChip(
                            label: Text(unidad.serial),
                            selected: isSelected,
                            onSelected: (selected) =>
                                _toggleUnidadSeriada(unidad),
                            selectedColor: Colors.green.shade200,
                            checkmarkColor: Colors.green.shade800,
                          );
                        })
                        .toList(),
                  ),
                const SizedBox(height: 8),
                Text(
                  'Seleccionadas: ${_unidadesSeleccionadas.length}/${widget.productoLegalizacion.cantidadMaxima}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],

              // Mostrar advertencias si es necesario
              if (widget.productoLegalizacion.tieneSeriales &&
                  _cantidad != _unidadesSeleccionadas.length) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.orange.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning,
                        color: Colors.orange.shade700,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Debes seleccionar exactamente ${_cantidad} unidad(es) seriada(s)',
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

// Extension para capitalizar strings
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}

// Modelos de datos que necesitas importar del archivo anterior

// Widget de ejemplo para usar la pantalla
// class EjemploUso extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Legalización de Entregas',
//       theme: ThemeData(
//         primarySwatch: Colors.blue,
//         visualDensity: VisualDensity.adaptivePlatformDensity,
//       ),
//       home: Scaffold(
//         appBar: AppBar(
//           title: const Text('Ejemplo'),
//           backgroundColor: Colors.blue,
//         ),
//         body: Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               ElevatedButton(
//                 onPressed: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => const EntregaDetalleScreen(
//                         entregaId: 98, // ID de ejemplo
//                         personalId: 19, // ID del técnico
//                         esDetalle: true, // Modo detalle
//                       ),
//                     ),
//                   );
//                 },
//                 child: const Text('Ver Detalle de Entrega'),
//               ),
//               const SizedBox(height: 16),
//               ElevatedButton(
//                 onPressed: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => const EntregaDetalleScreen(
//                         entregaId: 98, // ID de ejemplo
//                         personalId: 19, // ID del técnico
//                         esDetalle: false, // Modo legalización
//                       ),
//                     ),
//                   );
//                 },
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.green,
//                   foregroundColor: Colors.white,
//                 ),
//                 child: const Text('Legalizar Entrega'),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
