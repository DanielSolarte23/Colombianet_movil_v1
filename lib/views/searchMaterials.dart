import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class ProductSearchView extends StatefulWidget {
  const ProductSearchView({Key? key}) : super(key: key);

  @override
  State<ProductSearchView> createState() => _ProductSearchViewState();
}

class _ProductSearchViewState extends State<ProductSearchView> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounceTimer;

  List<dynamic> _searchResults = [];
  bool _isLoading = false;
  bool _showResults = false;
  Map<String, dynamic>? _statistics;
  dynamic _selectedProduct;

  static const Color _slate950 = Color(0xFF020617);
  static const Color _slate900 = Color(0xFF0F172A);
  static const Color _slate800 = Color(0xFF1E293B);
  static const Color _gray200 = Color(0xFFE5E7EB);
  static const Color _gray300 = Color(0xFFD1D5DB);
  static const Color _gray400 = Color(0xFF9CA3AF);
  static const Color _gray600 = Color(0xFF4B5563);

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text;

    if (query.isEmpty) {
      setState(() {
        _searchResults.clear();
        _showResults = false;
        _statistics = null;
      });
      return;
    }

    // Cancelar timer anterior si existe
    _debounceTimer?.cancel();
    
    // Solo hacer búsqueda automática si hay al menos 3 caracteres
    if (query.length >= 3) {
      _debounceTimer = Timer(const Duration(milliseconds: 500), () {
        _performSearch(query);
      });
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _showResults = false;
    });

    try {
      final uri = Uri.parse(
        'http://172.16.110.74:3004/api/productos/busqueda-rapida',
      ).replace(
        queryParameters: {
          'q': query.trim(),
          'limite': '10',
          'incluirUnidades': 'true',
        },
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            _searchResults = data['data'] ?? [];
            _statistics = data['estadisticas'];
            _showResults = true;
          });
        } else {
          setState(() {
            _searchResults = [];
            _statistics = null;
            _showResults = true;
          });
        }
      } else {
        setState(() {
          _searchResults = [];
          _statistics = null;
          _showResults = true;
        });
      }
    } catch (e) {
      debugPrint('Error realizando búsqueda: $e');
      setState(() {
        _searchResults = [];
        _statistics = null;
        _showResults = true;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _selectProduct(dynamic product) {
    setState(() {
      _selectedProduct = product;
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchResults.clear();
      _showResults = false;
      _statistics = null;
    });
    _focusNode.requestFocus();
  }

  Widget _buildSearchField() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _focusNode,
        onSubmitted: (query) {
          if (query.isNotEmpty) {
            _performSearch(query);
          }
        },
        decoration: InputDecoration(
          hintText: 'Buscar por código, descripción, marca, modelo o serial...',
          hintStyle: const TextStyle(color: _gray400),
          prefixIcon: const Icon(Icons.search, color: _gray400),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  onPressed: _clearSearch,
                  icon: const Icon(Icons.close, color: _gray400),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _slate900,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10),
        ],
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          ),
          SizedBox(width: 12),
          Text('Buscando...', style: TextStyle(color: _gray600)),
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _slate900,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 48, color: _gray400),
          const SizedBox(height: 16),
          const Text(
            'No se encontraron resultados',
            style: TextStyle(
              color: _gray200,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Intenta con otros términos de búsqueda o revisa la ortografía',
            style: const TextStyle(color: _gray400, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: _clearSearch,
            icon: const Icon(Icons.refresh, color: Colors.blue),
            label: const Text(
              'Limpiar búsqueda',
              style: TextStyle(color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (!_showResults || _isLoading) {
      return const SizedBox.shrink();
    }

    if (_searchResults.isEmpty && _searchController.text.isNotEmpty) {
      return _buildNoResults();
    }

    if (_searchResults.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      decoration: BoxDecoration(
        color: _slate900,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_statistics != null) _buildStatistics(),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _searchResults.length,
              itemBuilder: (context, index) =>
                  _buildResultItem(_searchResults[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Información de búsqueda
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _slate900,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue.shade300,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Cómo usar la búsqueda',
                      style: TextStyle(
                        color: _gray200,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSearchTip(
                  Icons.edit,
                  'Escribe al menos 3 caracteres',
                  'Para iniciar la búsqueda automática',
                  Colors.blue,
                ),
                _buildSearchTip(
                  Icons.search,
                  'Presiona Enter para buscar inmediatamente',
                  'O espera medio segundo para búsqueda automática',
                  Colors.green,
                ),
                _buildSearchTip(
                  Icons.filter_alt,
                  'Busca por múltiples campos',
                  'Código, descripción, marca, modelo o serial',
                  Colors.purple,
                ),
                _buildSearchTip(
                  Icons.inventory_2,
                  'Stock en tiempo real',
                  'Disponibilidad actualizada al instante',
                  Colors.orange,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Parámetros de búsqueda
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _slate900,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.tune, color: Colors.green.shade300, size: 24),
                    const SizedBox(width: 12),
                    const Text(
                      'Parámetros de Búsqueda',
                      style: TextStyle(
                        color: _gray200,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildSearchParameter(
                        'Código',
                        'Ej: PRD001',
                        Icons.qr_code_2,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSearchParameter(
                        'Descripción',
                        'Ej: Fibra, Herrajes',
                        Icons.description,
                        Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildSearchParameter(
                        'Marca',
                        'Ej: V-KOM, Tp-link',
                        Icons.business,
                        Colors.purple,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSearchParameter(
                        'Modelo',
                        'Ej: 12 hilos, SC/APC',
                        Icons.settings,
                        Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildSearchParameter(
                  'Serial',
                  'Ej: SN123456789, ABC-DEF-GHI',
                  Icons.fingerprint,
                  Colors.red,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Características
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _slate900,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.star_outline,
                      color: Colors.amber.shade300,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Características',
                      style: TextStyle(
                        color: _gray200,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildFeatureCard(
                        Icons.flash_on,
                        'Búsqueda Rápida',
                        'Encuentra productos en múltiples campos simultáneamente',
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildFeatureCard(
                        Icons.update,
                        'Stock en Tiempo Real',
                        'Información actualizada de disponibilidad',
                        Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildFeatureCard(
                        Icons.timer,
                        'Búsqueda Automática',
                        'Resultados mientras escribes (3+ caracteres)',
                        Colors.purple,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildFeatureCard(
                        Icons.visibility,
                        'Detalles Completos',
                        'Información detallada de cada producto',
                        Colors.orange,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchTip(
    IconData icon,
    String title,
    String description,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _gray200,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(color: _gray400, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchParameter(
    String title,
    String example,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _slate800,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(example, style: const TextStyle(color: _gray300, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
    IconData icon,
    String title,
    String description,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _slate800,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: _gray200,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(color: _gray400, fontSize: 10),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStatistics() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _gray300, width: 1)),
      ),
      child: Row(
        children: [
          Text(
            '${_statistics!['totalEncontrados']} resultado${_statistics!['totalEncontrados'] != 1 ? 's' : ''}',
            style: const TextStyle(color: _gray200, fontSize: 14),
          ),
          if (_statistics!['productos'] > 0) ...[
            const Text(' • ', style: TextStyle(color: _gray200)),
            Text(
              '${_statistics!['productos']} producto${_statistics!['productos'] != 1 ? 's' : ''}',
              style: const TextStyle(color: _gray200, fontSize: 14),
            ),
          ],
          if (_statistics!['unidadesPorSerial'] > 0) ...[
            const Text(' • ', style: TextStyle(color: _gray200)),
            Text(
              '${_statistics!['unidadesPorSerial']} por serial',
              style: const TextStyle(color: _gray200, fontSize: 14),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResultItem(dynamic item) {
    final isProduct = item['tipoResultado'] == 'producto';

    return InkWell(
      onTap: () => _selectProduct(item),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: _gray300, width: 0.5)),
        ),
        child: isProduct ? _buildProductItem(item) : _buildSerialItem(item),
      ),
    );
  }

  Widget _buildProductItem(dynamic item) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.inventory_2, color: Colors.amber, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item['codigo'] ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: item['stockDisponible'] > 0
                          ? Colors.green.withOpacity(0.2)
                          : Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      item['stockDisponible'] > 0 ? 'Disponible' : 'Agotado',
                      style: TextStyle(
                        color: item['stockDisponible'] > 0
                            ? Colors.green
                            : Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                item['descripcion'] ?? '',
                style: const TextStyle(color: _gray200, fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (item['marca'] != null) ...[
                      Text(
                        'Marca: ${item['marca']}',
                        style: const TextStyle(color: _gray300, fontSize: 12),
                      ),
                      const SizedBox(width: 16),
                    ],
                    if (item['modelo'] != null) ...[
                      Text(
                        'Modelo: ${item['modelo']}',
                        style: const TextStyle(color: _gray300, fontSize: 12),
                      ),
                      const SizedBox(width: 16),
                    ],
                    if (item['Stant'] != null) ...[
                      Text(
                        'Estante: ${item['Stant']['nombre']}',
                        style: const TextStyle(color: _gray300, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
              if (item['Subcategorium'] != null) ...[
                const SizedBox(height: 2),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      if (item['Subcategorium']['Categorium'] != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.purple.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            item['Subcategorium']['Categorium']['nombre'],
                            style: TextStyle(
                              color: Colors.purple.shade300,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward,
                        color: _gray400,
                        size: 10,
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item['Subcategorium']['nombre'],
                          style: TextStyle(
                            color: Colors.blue.shade300,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${item['stockDisponible']} disponible${item['stockDisponible'] != 1 ? 's' : ''}',
              style: const TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
            if (item['stockTotal'] > item['stockDisponible'])
              Text(
                '${item['stockTotal']} total',
                style: const TextStyle(color: _gray400, fontSize: 10),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildSerialItem(dynamic item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.qr_code, color: Colors.green, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Serial: ${item['serial'] ?? ''}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: ['nuevo', 'usado'].contains(item['estado'])
                    ? Colors.green.withOpacity(0.2)
                    : Colors.amber.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                item['estado']?.toString()?.toUpperCase() ?? 'N/A',
                style: TextStyle(
                  color: ['nuevo', 'usado'].contains(item['estado'])
                      ? Colors.green
                      : Colors.amber,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (item['Producto'] != null) ...[
          Text(
            item['Producto']['descripcion'] ?? '',
            style: const TextStyle(color: _gray200, fontSize: 14),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            'Código: ${item['Producto']['codigo'] ?? ''}',
            style: const TextStyle(color: _gray300, fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  Widget _buildProductDetails() {
    if (_selectedProduct == null) return const SizedBox.shrink();

    return Dialog(
      backgroundColor: _slate950,
      
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600, maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.amber)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Detalles del Producto',
                    style: TextStyle(
                      color: _gray200,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _selectedProduct = null),
                    icon: const Icon(Icons.close, color: _gray400),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Información básica
                    _buildDetailSection(
                      'Información Básica',
                      Icons.inventory_2,
                      Colors.amber,
                      [
                        _buildDetailRow('Código', _selectedProduct['codigo']),
                        _buildDetailRow(
                          'Descripción',
                          _selectedProduct['descripcion'],
                        ),
                        if (_selectedProduct['marca'] != null)
                          _buildDetailRow('Marca', _selectedProduct['marca']),
                        if (_selectedProduct['modelo'] != null)
                          _buildDetailRow('Modelo', _selectedProduct['modelo']),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Stock
                    _buildDetailSection('Stock', Icons.storage, Colors.green, [
                      _buildDetailRow(
                        'Disponible',
                        _selectedProduct['stockDisponible'].toString(),
                      ),
                      if (_selectedProduct['stockTotal'] !=
                          _selectedProduct['stockDisponible'])
                        _buildDetailRow(
                          'Total',
                          _selectedProduct['stockTotal'].toString(),
                        ),
                    ]),
                    const SizedBox(height: 20),
                    // Botón cerrar
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () =>
                            setState(() => _selectedProduct = null),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _gray600,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Cerrar',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection(
    String title,
    IconData icon,
    Color iconColor,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                color: _gray200,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: _gray300,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: _gray200)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Búsqueda rápida'),
        backgroundColor: _slate950,
        foregroundColor: Colors.white,
      ),
      backgroundColor: _slate950,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  child: const Text(
                    'Búsqueda de Productos',
                    style: TextStyle(
                      color: _gray200,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Search Field
                _buildSearchField(),
                // Loading Indicator
                if (_isLoading) _buildLoadingIndicator(),
                // Content Area
                Expanded(child: _buildMainContent()),
              ],
            ),
            // Product Details Modal
            if (_selectedProduct != null) _buildProductDetails(),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    // Si está cargando, no mostrar nada aquí (ya se muestra el indicador arriba)
    if (_isLoading) {
      return const SizedBox.shrink();
    }

    // Si hay resultados de búsqueda, mostrarlos
    if (_showResults) {
      return _buildSearchResults();
    }

    // Si no hay búsqueda activa, mostrar la vista de bienvenida
    return _buildWelcomeView();
  }
}