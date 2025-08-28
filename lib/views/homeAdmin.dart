import 'package:another_flushbar/flushbar.dart';
import 'package:colombianet_app/views/gestionEntregas.dart';
import 'package:colombianet_app/views/login.dart';
import 'dart:ui';
import 'package:colombianet_app/views/searchMaterials.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:colombianet_app/controller/authController.dart';

class HomeAdmin extends StatefulWidget {
  final int personalId; // Agregar este parámetro
  final String? nombreUsuario; // Opcional
  
  const HomeAdmin({
    Key? key,
    required this.personalId, // Hacerlo requerido
    this.nombreUsuario,
  }) : super(key: key);

  @override
  _HomeAdminState createState() => _HomeAdminState();
}

class _HomeAdminState extends State<HomeAdmin> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final AuthService _authService = AuthService(); // Instancia del AuthService

  static const Color _slate950 = Color(0xFF020617);
  static const Color _slate900 = Color(0xFF0F172A);
  static const Color _slate800 = Color(0xFF1E293B);
  static const Color _gray200 = Color(0xFFE5E7EB);
  static const Color _gray300 = Color(0xFFD1D5DB);
  static const Color _gray400 = Color(0xFF9CA3AF);
  static const Color _gray600 = Color(0xFF4B5563);

  // Método para obtener los elementos del menú con el personalId
  List<Map<String, dynamic>> get menuItems {
    return [
      {
        'title': 'Productos',
        'icon': Icons.route,
        'route': const ProductSearchView(),
        'color': Color(0xFF2196F3), // Blue
      },
      {
        'title': 'Entregas',
        'icon': Icons.assignment,
        'route': EntregasTecnicoScreen(personalId: widget.personalId), // Usar el personalId recibido
        'color': Color(0xFFFF9800), // Orange
      },
      {
        'title': 'Mis documentos',
        'icon': Icons.image,
        'route': '',
        'color': Color(0xFF9C27B0), // Purple
      },
      {
        'title': 'Incidencias',
        'icon': Icons.warning,
        'route': '',
        'color': Color(0xFFF44336), // Red
      },
    ];
  }

  // Datos del carrusel
  final List<Map<String, dynamic>> carouselItems = [
    {
      'title': 'Productos',
      'subtitle':
          'Realiza una busqueda rapida de productos disponibles en almacen',
      'image': 'assets/images/ruta_banner.jpg',
      'gradient': [Color(0xFF42A5F5), Color(0xFF1976D2)],
    },
    {
      'title': 'Entregas',
      'subtitle': 'Administra y gestiona tus entregas',
      'image': 'assets/images/task_banner.jpg',
      'gradient': [Color(0xFF66BB6A), Color(0xFF388E3C)],
    },
    {
      'title': 'Mis documentos',
      'subtitle': 'Gestiona tus documentos',
      'image': 'assets/images/gallery_banner.jpg',
      'gradient': [Color(0xFFAB47BC), Color(0xFF7B1FA2)],
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mostrarAlerta();
      _startAutoSlide();
    });
    
    // Debug: imprimir el personalId recibido
    print('HomeAdmin inicializado con personalId: ${widget.personalId}');
    if (widget.nombreUsuario != null) {
      print('Nombre de usuario: ${widget.nombreUsuario}');
    }
  }

  void _startAutoSlide() {
    Future.delayed(Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _currentPage = (_currentPage + 1) % carouselItems.length;
        });
        _pageController.animateToPage(
          _currentPage,
          duration: Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
        _startAutoSlide();
      }
    });
  }

  void _mostrarAlerta() {
    Flushbar(
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      borderColor: _gray300,
      titleText: const Text(
        "Inicio",
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.amber
        ),
      ),
      messageText: Text(
        widget.nombreUsuario != null 
            ? "Bienvenido, ${widget.nombreUsuario}"
            : "Bienvenido",
        style: TextStyle(
          fontSize: 16,
          fontFamily: 'RobotoMono',
          fontWeight: FontWeight.w600,
          color: Colors.amber,
        ),
      ),
      duration: Duration(seconds: 2),
      backgroundColor: _slate800,
      borderRadius: BorderRadius.circular(16),
      margin: EdgeInsets.all(16),
      flushbarPosition: FlushbarPosition.TOP,
    )..show(context);
  }

  // Función para mostrar el perfil
  void _mostrarPerfil() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _slate800,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.amber.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header del perfil
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.amber.withOpacity(0.2), Colors.amber.withOpacity(0.1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.amber,
                        child: Icon(
                          Icons.person,
                          size: 40,
                          color: _slate800,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        widget.nombreUsuario ?? 'Usuario',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'ID: ${widget.personalId}',
                        style: TextStyle(
                          color: Colors.amber.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 20),
                
                // Opciones del perfil
                ListTile(
                  leading: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.settings, color: Colors.blue),
                  ),
                  title: Text(
                    'Configuración',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    // Agregar navegación a configuración
                  },
                ),
                
                ListTile(
                  leading: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.help, color: Colors.green),
                  ),
                  title: Text(
                    'Ayuda',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    // Agregar navegación a ayuda
                  },
                ),
                
                Divider(color: Colors.grey.withOpacity(0.3)),
                
                // Botón de cerrar sesión
                ListTile(
                  leading: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.logout, color: Colors.red),
                  ),
                  title: Text(
                    'Cerrar Sesión',
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmarCerrarSesion();
                  },
                ),
                
                SizedBox(height: 10),
                
                // Botón cerrar
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cerrar',
                    style: TextStyle(color: Colors.amber),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Función para confirmar el cierre de sesión
  void _confirmarCerrarSesion() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: _slate800,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.amber.withOpacity(0.3)),
          ),
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              SizedBox(width: 10),
              Text(
                'Confirmar',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          content: Text(
            '¿Estás seguro de que quieres cerrar sesión?',
            style: TextStyle(color: Colors.white.withOpacity(0.8)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancelar',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _cerrarSesion();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Cerrar Sesión',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  // Función para cerrar sesión
  void _cerrarSesion() async {
    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _slate800,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Colors.amber),
                SizedBox(height: 16),
                Text(
                  'Cerrando sesión...',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        );
      },
    );

    try {
      final result = await _authService.logout();
      
      Navigator.pop(context); // Cerrar dialog de loading
      
      if (result['success']) {
        // Mostrar mensaje de éxito
        Flushbar(
          title: "Sesión cerrada",
          message: result['mensaje'],
          duration: Duration(seconds: 2),
          backgroundColor: Colors.green,
          borderRadius: BorderRadius.circular(16),
          margin: EdgeInsets.all(16),
          flushbarPosition: FlushbarPosition.TOP,
        ).show(context);

        // Navegar al login después de un breve retraso
        Future.delayed(Duration(seconds: 1), () {
          // Navigator.pushReplacementNamed(context, '/login');
          // O si usas MaterialPageRoute:
           Navigator.pushReplacement(
             context,
             MaterialPageRoute(builder: (context) => login()),
           );
        });
      } else {
        // Mostrar error
        Flushbar(
          title: "Error",
          message: result['mensaje'],
          duration: Duration(seconds: 3),
          backgroundColor: Colors.red,
          borderRadius: BorderRadius.circular(16),
          margin: EdgeInsets.all(16),
          flushbarPosition: FlushbarPosition.TOP,
        ).show(context);
      }
    } catch (e) {
      Navigator.pop(context); // Cerrar dialog de loading
      print('Error al cerrar sesión: $e');
      
      Flushbar(
        title: "Error",
        message: "Error inesperado al cerrar sesión",
        duration: Duration(seconds: 3),
        backgroundColor: Colors.red,
        borderRadius: BorderRadius.circular(16),
        margin: EdgeInsets.all(16),
        flushbarPosition: FlushbarPosition.TOP,
      ).show(context);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF020618),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Color(0xFF020618),
        leading: Container(
          margin: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Color.fromARGB(255, 240, 177, 0).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.settings,
              color: Color.fromARGB(255, 240, 177, 0),
            ),
            onPressed: () {
              // Configuración
            },
          ),
        ),
        title: const Text(
          'Panel de Control',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Stack(
                children: [
                  Icon(
                    Icons.notifications_outlined,
                    color: Colors.amber,
                    size: 28,
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      constraints: BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        '3',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
              onPressed: () {
                // Notificaciones
              },
            ),
          ),
          Container(
            margin: EdgeInsets.only(right: 16),
            child: IconButton(
              icon: CircleAvatar(
                radius: 16,
                backgroundColor: Colors.amber,
                child: Icon(Icons.person, color: Color(0xFF020618), size: 20),
              ),
              onPressed: _mostrarPerfil, // Mostrar vista de perfil
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),

            // CARRUSEL MEJORADO (Aquí está el carrusel que solicitaste)
            Container(
              height: 180,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: carouselItems.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: carouselItems[index]['gradient'],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 15,
                          spreadRadius: 2,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Patrón de fondo
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: Colors.white.withOpacity(0.1),
                            ),
                            child: CustomPaint(painter: PatternPainter()),
                          ),
                        ),
                        // Contenido
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                carouselItems[index]['title'],
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 4,
                                      color: Colors.black.withOpacity(0.3),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                carouselItems[index]['subtitle'],
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white.withOpacity(0.9),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Spacer(),
                              Align(
                                alignment: Alignment.bottomRight,
                                child: Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.arrow_forward,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Indicadores del carrusel
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(carouselItems.length, (index) {
                return AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  margin: EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? Color(0xFFFFC107)
                        : Color(0xFF9E9E9E).withOpacity(0.4),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),

            const SizedBox(height: 30),

            // Título del menú
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF66BB6A).withOpacity(0.2),
                      Color(0xFF66BB6A).withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: Color(0xFF66BB6A).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Color(0xFF66BB6A).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.dashboard,
                        color: Color(0xFF2E7D32),
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 12),
                    const Text(
                      'Menú Principal',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Grid del menú mejorado (exactamente 4 elementos)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: 4, // Exactamente 4 elementos
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.2,
                ),
                itemBuilder: (context, index) {
                  final item = menuItems[index]; // Ahora usa el getter que incluye el personalId
                  return AnimatedContainer(
                    duration: Duration(milliseconds: 200),
                    child: InkWell(
                      onTap: () {
                        if (item['route'] is Widget) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => item['route'],
                            ),
                          );
                        } else {
                          print('No hay ruta definida para ${item['title']}');
                        }
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Colors.white, Color(0xFFFAFAFA)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: item['color'].withOpacity(0.2),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: item['color'].withOpacity(0.1),
                              blurRadius: 12,
                              spreadRadius: 2,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: item['color'].withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                item['icon'],
                                color: item['color'],
                                size: 32,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              item['title'],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF424242),
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: 40,
                              height: 3,
                              decoration: BoxDecoration(
                                color: item['color'].withOpacity(0.6),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

// Clase para crear un patrón decorativo en el carrusel
class PatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final path = Path();

    // Crear un patrón geométrico simple
    for (int i = 0; i < 10; i++) {
      for (int j = 0; j < 10; j++) {
        final x = (i * size.width / 10);
        final y = (j * size.height / 10);

        canvas.drawCircle(Offset(x, y), 2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}