import 'package:colombianet_app/controller/authController.dart';
import 'package:flutter/material.dart';
import 'package:colombianet_app/views/homeAdmin.dart';
import 'dart:math' as math;

class login extends StatefulWidget {
  const login({super.key});

  @override
  State<login> createState() => _loginState();
}

class _loginState extends State<login> with TickerProviderStateMixin {
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService authService = AuthService();

  // Controladores de animación
  late AnimationController _successAnimationController;
  late AnimationController _astronautController;
  late AnimationController _particlesController;
  late AnimationController _floatingController;

  // Animaciones
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _astronautFloat;
  late Animation<double> _astronautRotation;
  late Animation<double> _particlesAnimation;

  bool _showSuccessAnimation = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // Inicializar controladores de animación
    _successAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _astronautController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _particlesController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    _floatingController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    // Configurar animaciones
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _successAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _successAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _astronautFloat = Tween<double>(begin: 0.0, end: -20.0).animate(
      CurvedAnimation(parent: _astronautController, curve: Curves.easeInOut),
    );

    _astronautRotation = Tween<double>(begin: 0.0, end: 0.1).animate(
      CurvedAnimation(parent: _astronautController, curve: Curves.easeInOut),
    );

    _particlesAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _particlesController, curve: Curves.easeOut),
    );

    // Animación de flotación continua
    _floatingController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _successAnimationController.dispose();
    _astronautController.dispose();
    _particlesController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  // En tu archivo login.dart, modifica la función iniciarSesion:

  void iniciarSesion() async {
    final username = _userNameController.text;
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingresa el nombre de usuario y contraseña'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await authService.login(username, password);

      if (result['success'] && result.containsKey('perfil')) {
        final usuarioId = result['perfil']?['id'];
        final nombreUsuario = result['perfil']?['nombre'];

        print('Usuario ID: $usuarioId');
        print('Nombre: $nombreUsuario');

        // Mostrar animación de éxito
        setState(() {
          _showSuccessAnimation = true;
          _isLoading = false;
        });

        // Iniciar todas las animaciones
        _successAnimationController.forward();
        _astronautController.forward();
        _particlesController.forward();

        // Navegar después de la animación PASANDO EL ID
        Future.delayed(const Duration(milliseconds: 3000), () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomeAdmin(
                personalId: usuarioId,
                nombreUsuario: nombreUsuario, 
              ),
            ),
          );
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['mensaje'] ?? 'Credenciales incorrectas'),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error en inicio de sesión: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al conectar con el servidor')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020618),
      body: Stack(
        children: [
          // Contenido principal del login
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 100.0),
                  Image.asset(
                    "assets/images/logo1.png",
                    height: 150,
                    width: 150,
                  ),
                  const SizedBox(height: 40.0),
                  const Text(
                    "Bienvenido",
                    style: TextStyle(
                      color: Color(0xFFf0b100),
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    "Inicia sesión para continuar",
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                  const SizedBox(height: 24.0),
                  TextField(
                    controller: _userNameController,
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                    decoration: InputDecoration(
                      labelText: 'Nombre de usuario',
                      labelStyle: const TextStyle(
                        color: Color(0xFFf0b100),
                        fontWeight: FontWeight.bold,
                      ),
                      hintText: 'Ingresa tu nombre de usuario',
                      hintStyle: const TextStyle(color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: const BorderSide(
                          color: Color(0xFFf0b100),
                          width: 2.0,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: const BorderSide(
                          color: Color(0xFFf0b100),
                          width: 2.5,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: const BorderSide(
                          color: Colors.grey,
                          width: 2.0,
                        ),
                      ),
                      filled: true,
                      fillColor: Color(0xFF020618),
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      labelStyle: const TextStyle(
                        color: Color(0xFFf0b100),
                        fontWeight: FontWeight.bold,
                      ),
                      hintText: 'Ingresa tu contraseña',
                      hintStyle: const TextStyle(color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: const BorderSide(
                          color: Color(0xFFf0b100),
                          width: 2.0,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: const BorderSide(
                          color: Color(0xFFf0b100),
                          width: 2.5,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: const BorderSide(
                          color: Colors.grey,
                          width: 2.0,
                        ),
                      ),
                      filled: true,
                      fillColor: Color(0xFF020618),
                    ),
                  ),
                  const SizedBox(height: 24.0),
                  ElevatedButton(
                    onPressed: _isLoading ? null : iniciarSesion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFf0b100),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 30,
                            width: 30,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                        : const Text(
                            "Iniciar sesión",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  const SizedBox(height: 20),
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "¿Olvidaste tu contraseña?",
                            style: TextStyle(color: Colors.white),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: () {},
                            child: (const Text(
                              "Recuperar",
                              style: TextStyle(
                                color: Color(0xFFf0b100),
                                fontWeight: FontWeight.bold,
                              ),
                            )),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Animación de éxito con astronauta
          if (_showSuccessAnimation)
            AnimatedBuilder(
              animation: Listenable.merge([
                _successAnimationController,
                _astronautController,
                _particlesController,
                _floatingController,
              ]),
              builder: (context, child) {
                return Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.black.withOpacity(0.8 * _fadeAnimation.value),
                  child: Stack(
                    children: [
                      // Partículas de fondo
                      ...List.generate(20, (index) {
                        final random = math.Random(index);
                        return Positioned(
                          left:
                              random.nextDouble() *
                              MediaQuery.of(context).size.width,
                          top:
                              random.nextDouble() *
                              MediaQuery.of(context).size.height,
                          child: Transform.scale(
                            scale: _particlesAnimation.value,
                            child: Container(
                              width: 4 + random.nextDouble() * 6,
                              height: 4 + random.nextDouble() * 6,
                              decoration: BoxDecoration(
                                color:
                                    [
                                      Colors.white,
                                      Color(0xFFf0b100),
                                      Colors.blue,
                                      Colors.cyan,
                                    ][random.nextInt(4)].withOpacity(
                                      _fadeAnimation.value,
                                    ),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        );
                      }),

                      // Astronauta principal
                      Center(
                        child: Transform.translate(
                          offset: Offset(
                            0,
                            _astronautFloat.value +
                                (math.sin(
                                      _floatingController.value * 2 * math.pi,
                                    ) *
                                    10),
                          ),
                          child: Transform.rotate(
                            angle:
                                _astronautRotation.value +
                                (math.sin(
                                      _floatingController.value * 2 * math.pi,
                                    ) *
                                    0.05),
                            child: Transform.scale(
                              scale: _scaleAnimation.value,
                              child: Container(
                                width: 200,
                                height: 200,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      Color(0xFFf0b100).withOpacity(0.3),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                                child: Center(
                                  child: Container(
                                    width: 150,
                                    height: 150,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white.withOpacity(0.1),
                                      border: Border.all(
                                        color: Color(
                                          0xFFf0b100,
                                        ).withOpacity(0.6),
                                        width: 2,
                                      ),
                                    ),
                                    // child: Icon(
                                    //   Icons.rocket_launch,
                                    //   size: 80,
                                    //   color: Color(0xFFf0b100),
                                    // ),
                                    // Si tienes una imagen de astronauta, reemplaza el Icon con:
                                    child: Image.asset(
                                      'assets/images/astro.png',
                                      width: 120,
                                      height: 120,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Texto de éxito
                      Positioned(
                        bottom: 200,
                        left: 0,
                        right: 0,
                        child: Opacity(
                          opacity: _fadeAnimation.value,
                          child: Column(
                            children: [
                              Text(
                                "¡Bienvenido a bordo!",
                                style: TextStyle(
                                  color: Color(0xFFf0b100),
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 10),
                            ],
                          ),
                        ),
                      ),

                      // Indicador de carga
                      Positioned(
                        bottom: 100,
                        left: 0,
                        right: 0,
                        child: Opacity(
                          opacity: _fadeAnimation.value,
                          child: Center(
                            child: Container(
                              width: 200,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: _particlesAnimation.value,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Color(0xFFf0b100),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
