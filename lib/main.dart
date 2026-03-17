import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// sensor de pasos
import 'package:pedometer/pedometer.dart';
import 'dart:async';

/// ---------------- MODELOS ----------------
class Usuario {
  final String id;
  String nombre;
  String email;
  String rol;
  String? foto;
  String? password;
  String? fechaNacimiento;
  String? genero;

  Usuario({
    required this.id,
    required this.nombre,
    required this.email,
    this.rol = 'cliente',
    this.foto,
    this.password,
    this.fechaNacimiento,
    this.genero,
  });
}

class Mascota {
  final String id;
  String nombre;
  String especie;
  String raza;
  String edad;
  String peso;
  String sexo;
  String color;

  Mascota({
    required this.id,
    required this.nombre,
    required this.especie,
    required this.raza,
    required this.edad,
    required this.peso,
    required this.sexo,
    required this.color,
  });
}

class Cita {
  final String id;
  final String clienteId;
  final String mascotaId;
  DateTime fecha;
  String veterinario;
  String servicio;
  String estado;

  Cita({
    required this.id,
    required this.clienteId,
    required this.mascotaId,
    required this.fecha,
    required this.veterinario,
    required this.servicio,
    this.estado = 'Pendiente',
  });
}

/// ---------------- PROVIDER ----------------
class AppProvider with ChangeNotifier {
  List<Usuario> usuarios = [];
  List<Mascota> mascotas = [];
  List<Cita> citas = [];
  Usuario? usuarioActual;

  void registrarUsuario(Usuario usuario) {
    usuarios.add(usuario);
    notifyListeners();
  }

  bool login(String email, String password) {
    final encontrado = usuarios
        .where((u) => u.email == email && u.password == password)
        .toList();

    if (encontrado.isEmpty) return false;

    usuarioActual = encontrado.first;
    notifyListeners();
    return true;
  }

  void logout() {
    usuarioActual = null;
    notifyListeners();
  }

  void agregarMascota(Mascota mascota) {
    mascotas.add(mascota);
    notifyListeners();
  }

  void agregarCita(Cita cita) {
    citas.add(cita);
    notifyListeners();
  }

  List<Cita> obtenerCitasUsuario(String clienteId) {
    return citas.where((c) => c.clienteId == clienteId).toList();
  }

  void actualizarPerfil(String nombre, String email, String? foto) {
    if (usuarioActual == null) return;

    usuarioActual!.nombre = nombre;
    usuarioActual!.email = email;
    usuarioActual!.foto = foto;

    notifyListeners();
  }

  void cancelarCita(String id) {
    citas.removeWhere((c) => c.id == id);
    notifyListeners();
  }
}

/// ---------------- LOGIN ----------------
class LoginScreen extends StatelessWidget {
  LoginScreen({Key? key}) : super(key: key);

  final TextEditingController emailController = TextEditingController();
  final TextEditingController conController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final app = Provider.of<AppProvider>(context);
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade400, Colors.blue.shade100],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Card(
            margin: EdgeInsets.symmetric(horizontal: width * 0.1),
            elevation: 12,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset('assets/logo.png', width: 300, height: 200),
                    const SizedBox(height: 12),
                    const Text(
                      'Bienvenido',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 0, 50, 92),
                      ),
                    ),
                    TextField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: conController,
                      decoration: const InputDecoration(
                        labelText: 'Contraseña',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock),
                      ),
                    ),
                    const SizedBox(height: 10),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.blue,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: const Text('Registrar'),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => RegisterScreen()),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: const Text('Iniciar Sesión'),
                      onPressed: () {
                        bool success = app.login(
                          emailController.text,
                          conController.text,
                        );
                        if (!context.mounted) return;
                        if (success) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => HomeScreen()),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Usuario o contraseña incorrectos'),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// ---------------- REGISTER ----------------
class RegisterScreen extends StatelessWidget {
  RegisterScreen({Key? key}) : super(key: key);

  final TextEditingController emailController = TextEditingController();
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController contraController = TextEditingController();
  final TextEditingController nacController = TextEditingController();
  final TextEditingController genContorller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final app = Provider.of<AppProvider>(context);
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade400, Colors.blue.shade100],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Card(
            margin: EdgeInsets.symmetric(horizontal: width * 0.1),
            elevation: 12,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset('assets/logo.png', width: 300, height: 200),
                    const SizedBox(height: 12),
                    const Text(
                      'Bienvenido',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 0, 50, 92),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: nombreController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                    ),
                    const SizedBox(height: 10),

                    TextField(
                      controller: contraController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Contraseña',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock),
                      ),
                    ),

                    const SizedBox(height: 10),

                    TextField(
                      controller: nacController,
                      decoration: const InputDecoration(
                        labelText: 'Fecha de nacimiento',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.cake),
                      ),
                    ),

                    const SizedBox(height: 10),

                    TextField(
                      controller: genContorller,
                      decoration: const InputDecoration(
                        labelText: 'Género',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),

                    const SizedBox(height: 20),
                    const SizedBox(height: 20),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: Colors.blue,
                      ),
                      child: const Text(
                        'Registrar',
                        style: TextStyle(color: Colors.white),
                      ),
                      onPressed: () {
                        if (nombreController.text.isEmpty ||
                            emailController.text.isEmpty ||
                            contraController.text.isEmpty ||
                            nacController.text.isEmpty ||
                            genContorller.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Completa todos los campos'),
                            ),
                          );
                          return;
                        }

                        final nuevoUsuario = Usuario(
                          id: DateTime.now().toString(),
                          nombre: nombreController.text,
                          email: emailController.text,
                          password: contraController.text,
                          fechaNacimiento: nacController.text,
                          genero: genContorller.text,
                        );

                        app.registrarUsuario(nuevoUsuario);
                        app.usuarioActual = nuevoUsuario;
                        if (!context.mounted) return;
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => HomeScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// ---------------- DASHBOARD ----------------
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final app = Provider.of<AppProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Hola ${app.usuarioActual?.nombre ?? ''}'),
        backgroundColor: Colors.blue.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              app.logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade400, Colors.blue.shade100],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _menuButton(
                context,
                'Mis Citas',
                Icons.calendar_today,
                HomeScreen(),
              ),
              const SizedBox(height: 20),
              _menuButton(
                context,
                'Registrar Mascota',
                Icons.pets,
                HomeScreen(),
              ),
              const SizedBox(height: 20),
              _menuButton(
                context,
                'Registrar Cita',
                Icons.medical_services,
                HomeScreen(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuButton(
    BuildContext context,
    String text,
    IconData icon,
    Widget screen,
  ) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 28),
      label: Padding(
        padding: const EdgeInsets.symmetric(vertical: 15),
        child: Text(text, style: const TextStyle(fontSize: 18)),
      ),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 60),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 8,
      ),
      onPressed: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
      },
    );
  }
}

/// ---------------- HOME SCREEN ----------------
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // contador de pasos (ahora usa el sensor)
  int _stepCount = 0;
  bool _isCounting = false;

  StreamSubscription<StepCount>? _stepCountSubscription;

  void _onStepCount(StepCount event) {
    setState(() {
      _stepCount = event.steps;
    });
  }

  void _onStepCountError(error) {
    // normalmente se dispara si el dispositivo no soporta el sensor
    debugPrint('Step count error: $error');
  }

  void _startCounting() {
    // solicita permiso de actividad si se desea (Android 10+)
    // la librería `permission_handler` puede ayudar, por ejemplo:
    // await Permission.activityRecognition.request();

    _stepCountSubscription = Pedometer.stepCountStream.listen(
      _onStepCount,
      onError: _onStepCountError,
    );
    setState(() {
      _isCounting = true;
      _stepCount = 0;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Contador iniciado')));
  }

  void _stopCounting() {
    _stepCountSubscription?.cancel();

    historialPasos.add(_stepCount);

    setState(() {
      _isCounting = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Contador detenido. Total pasos: $_stepCount')),
    );
  }

  // historial de caminatas
  List<int> historialPasos = [];

  // estado para agendar citas
  DateTime _fechaSeleccionada = DateTime.now();
  String _horaSeleccionada = '';
  String? _motivoSeleccionado;
  String? _veterinarioSeleccionado;

  final List<String> _horarios = [
    "09:00 AM",
    "09:30 AM",
    "10:00 AM",
    "10:30 AM",
    "11:00 AM",
    "11:30 AM",
    "03:00 PM",
    "03:30 PM",
    "04:00 PM",
    "04:30 PM",
  ];

  final List<String> _motivos = [
    "Consulta General",
    "Vacunación",
    "Desparasitación",
    "Cirugía",
    "Emergencia",
    "Baño y Grooming",
  ];

  final List<String> _veterinarios = [
    "Dr. Carlos Ramírez",
    "Dra. Sofía Mendoza",
    "Dr. Andrés López",
    "Dra. Valeria Torres",
  ];

  final TextEditingController mascotaController = TextEditingController();
  final TextEditingController razaController = TextEditingController();
  final TextEditingController edadController = TextEditingController();
  final TextEditingController pesoController = TextEditingController();
  final TextEditingController colorController = TextEditingController();
  File? imagenMascota;
  final ImagePicker picker = ImagePicker();
  final TextEditingController nombrePerfilController = TextEditingController();
  final TextEditingController emailPerfilController = TextEditingController();
  File? imagenPerfil;

  Future seleccionarImagen() async {
    final XFile? imagen = await picker.pickImage(source: ImageSource.gallery);

    if (imagen != null) {
      setState(() {
        imagenMascota = File(imagen.path);
      });
    }
  }

  Future seleccionarImagenPerfil() async {
    final XFile? imagen = await picker.pickImage(source: ImageSource.gallery);

    if (imagen != null) {
      setState(() {
        imagenPerfil = File(imagen.path);
      });
    }
  }

  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final app = Provider.of<AppProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Hola ${app.usuarioActual?.nombre ?? ''}'),
        backgroundColor: Colors.blue.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              app.logout();
              Navigator.pop(context);
            },
          ),
        ],
      ),

      body: _selectedIndex == 0
          ? _inicio(app)
          : _selectedIndex == 1
          ? _citas(app)
          : _selectedIndex == 2
          ? _mascotas(app)
          : _perfil(app),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue.shade700,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => PasosScreen(app: app)),
          );
        },
        tooltip: 'Ir a caminata',
        child: const FaIcon(FontAwesomeIcons.dog, color: Colors.white),
      ),

      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: Icon(
                  Icons.home,
                  color: _selectedIndex == 0 ? Colors.blue : Colors.grey,
                ),
                onPressed: () => setState(() => _selectedIndex = 0),
              ),
              IconButton(
                icon: Icon(
                  Icons.calendar_today,
                  color: _selectedIndex == 1 ? Colors.blue : Colors.grey,
                ),
                onPressed: () => setState(() => _selectedIndex = 1),
              ),
              const SizedBox(width: 40),
              IconButton(
                icon: Icon(
                  Icons.pets,
                  color: _selectedIndex == 2 ? Colors.blue : Colors.grey,
                ),
                onPressed: () => setState(() => _selectedIndex = 2),
              ),
              IconButton(
                icon: Icon(
                  Icons.person,
                  color: _selectedIndex == 3 ? Colors.blue : Colors.grey,
                ),
                onPressed: () => setState(() => _selectedIndex = 3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future seleccionarFotoPerfil() async {
    final XFile? imagen = await picker.pickImage(source: ImageSource.gallery);

    if (imagen != null) {
      setState(() {
        imagenPerfil = File(imagen.path);
      });
    }
  }

  // ---------------- PANTALLA INICIO ----------------
  Widget _inicio(AppProvider app) {
    if (app.usuarioActual == null) {
      return const Center(child: Text("Usuario no disponible"));
    }

    final citas = app.obtenerCitasUsuario(app.usuarioActual!.id);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // contador de pasos
          
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              "assets/cd.png",
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),

          const SizedBox(height: 20),
        
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Citas Pendientes",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              //Text("Ver todo", style: TextStyle(color: Colors.blue)),
            ],
          ),

          const SizedBox(height: 10),

          citas.isEmpty
              ? const Text("No tienes citas registradas")
              : SizedBox(
                  height: 160,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: citas.length,
                    itemBuilder: (context, index) {
                      final cita = citas[index];

                      return Container(
                        width: 200,
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(15),
                        ),

                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Align(
                              alignment: Alignment.topRight,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.cancel,
                                  color: Colors.red,
                                ),
                                onPressed: () {
                                  app.cancelarCita(cita.id);
                                },
                              ),
                            ),

                            Text(
                              cita.servicio,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 5),
                            Text("Vet: ${cita.veterinario}"),
                            const SizedBox(height: 5),
                            Text(
                              cita.fecha.toLocal().toString().split(' ')[0],
                              style: const TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              cita.estado,
                              style: TextStyle(
                                color: cita.estado == 'Cancelada'
                                    ? Colors.red
                                    : Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

          const SizedBox(height: 25),

          // Mascotas
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Mascotas",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              //Text("Ver todo", style: TextStyle(color: Colors.blue)),
            ],
          ),

          const SizedBox(height: 10),

          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: app.mascotas.length,
              itemBuilder: (context, index) {
                final mascota = app.mascotas[index];

                return Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(right: 12),
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.pets, color: Colors.blue),
                    ),
                    const SizedBox(height: 5),
                    Text(mascota.nombre),
                  ],
                );
              },
            ),
          ),

          const SizedBox(height: 20),

          

          const SizedBox(height: 25),

          // Imagen veterinarios
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              "assets/vet.jpg",
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- PANTALLA CITAS ----------------
  Widget _citas(AppProvider app) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Agendar Cita",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            initialValue: _motivoSeleccionado,
            decoration: InputDecoration(
              labelText: "Motivo de la cita",
              prefixIcon: const Icon(Icons.pets),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            items: _motivos
                .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                .toList(),
            onChanged: (value) {
              setState(() {
                _motivoSeleccionado = value;
              });
            },
          ),
          const SizedBox(height: 15),
          DropdownButtonFormField<String>(
            value: _veterinarioSeleccionado,
            decoration: InputDecoration(
              labelText: "Seleccionar Veterinario",
              prefixIcon: const Icon(Icons.medical_services),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            items: _veterinarios
                .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                .toList(),
            onChanged: (value) {
              setState(() {
                _veterinarioSeleccionado = value;
              });
            },
          ),
          const SizedBox(height: 20),
          const Text(
            "Seleccionar Fecha",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(10),
            child: CalendarDatePicker(
              initialDate: _fechaSeleccionada,
              firstDate: DateTime.now(),
              lastDate: DateTime(2030),
              onDateChanged: (date) {
                setState(() {
                  _fechaSeleccionada = date;
                });
              },
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "Seleccionar Horario",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _horarios.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.5,
            ),
            itemBuilder: (context, index) {
              final hora = _horarios[index];
              final seleccionada = hora == _horaSeleccionada;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _horaSeleccionada = hora;
                  });
                },
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                  
                    color: seleccionada
                        ? const Color(0xFF00B2FB)
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    hora,
                    style: TextStyle(
                      color: seleccionada ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 25),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00B2FB),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed:
                  (_motivoSeleccionado == null ||
                      _veterinarioSeleccionado == null ||
                      _horaSeleccionada.isEmpty)
                  ? null
                  : () {
                      final horaPartes = _horaSeleccionada.split(':');
                      final hora = int.tryParse(horaPartes[0]) ?? 0;
                      final minuto =
                          int.tryParse(horaPartes[1].split(' ')[0]) ?? 0;
                      final fechaCompleta = DateTime(
                        _fechaSeleccionada.year,
                        _fechaSeleccionada.month,
                        _fechaSeleccionada.day,
                        hora,
                        minuto,
                      );

                      bool ocupado = app.citas.any(
                        (c) =>
                            c.fecha == fechaCompleta &&
                            c.veterinario == _veterinarioSeleccionado &&
                            c.estado != 'Cancelada',
                      );

                      if (ocupado) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Ese horario ya está ocupado'),
                          ),
                        );
                        return;
                      }

                      app.agregarCita(
                        Cita(
                          id: DateTime.now().toString(),
                          clienteId: app.usuarioActual!.id,
                          mascotaId: app.mascotas.isNotEmpty
                              ? app.mascotas.last.id
                              : '',
                          fecha: fechaCompleta,
                          veterinario: _veterinarioSeleccionado!,
                          servicio: _motivoSeleccionado!,
                        ),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Cita agendada correctamente'),
                        ),
                      );
                    },
              child: const Text(
                "Confirmar Cita",
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- PANTALLA MASCOTAS ----------------
  Widget _mascotas(AppProvider app) {
  return SingleChildScrollView(
    padding: EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Center(
          child: GestureDetector(
            onTap: seleccionarImagen,
            child: CircleAvatar(
              radius: 55,
              backgroundColor: Colors.grey.shade300,
              backgroundImage:
                  imagenMascota != null ? FileImage(imagenMascota!) : null,
              child: imagenMascota == null
                  ? Icon(Icons.camera_alt, size: 30, color: Colors.grey)
                  : null,
            ),
          ),
        ),

        SizedBox(height: 10),

        Center(
          child: Text(
            "Agregar foto de la mascota",
            style: TextStyle(color: Colors.grey),
          ),
        ),

        SizedBox(height: 25),

        Text(
          "Registrar Mascota",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        SizedBox(height: 15),

        TextField(
          controller: mascotaController,
          decoration: InputDecoration(
            labelText: 'Nombre de la mascota',
            prefixIcon: Icon(Icons.pets),
            border: OutlineInputBorder(),
          ),
        ),

        SizedBox(height: 10),

        TextField(
          controller: razaController,
          decoration: InputDecoration(
            labelText: 'Raza',
            border: OutlineInputBorder(),
          ),
        ),

        SizedBox(height: 10),

        TextField(
          controller: edadController,
          decoration: InputDecoration(
            labelText: 'Edad',
            border: OutlineInputBorder(),
          ),
        ),

        SizedBox(height: 10),

        TextField(
          controller: pesoController,
          decoration: InputDecoration(
            labelText: 'Peso',
            border: OutlineInputBorder(),
          ),
        ),

        SizedBox(height: 10),

        TextField(
          controller: colorController,
          decoration: InputDecoration(
            labelText: 'Color',
            border: OutlineInputBorder(),
          ),
        ),

        SizedBox(height: 20),

        ElevatedButton(
          child: Text("Registrar Mascota"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            minimumSize: Size(double.infinity, 50),
            foregroundColor: Colors.white,
          ),
          onPressed: () {

            if (mascotaController.text.isEmpty) return;

            app.agregarMascota(
              Mascota(
                id: DateTime.now().toString(),
                nombre: mascotaController.text,
                especie: "Perro",
                raza: razaController.text,
                edad: edadController.text,
                peso: pesoController.text,
                sexo: "Macho",
                color: colorController.text,
              ),
            );

            mascotaController.clear();
            razaController.clear();
            edadController.clear();
            pesoController.clear();
            colorController.clear();

            setState(() {
              imagenMascota = null;
            });
          },
        ),

        SizedBox(height: 30),

        Text(
          "Mascotas registradas",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        SizedBox(height: 10),

        ...app.mascotas.map((m) => Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Icon(Icons.pets, color: Colors.white),
                ),
                title: Text(m.nombre),
                subtitle: Text(
                  "Raza: ${m.raza} | Edad: ${m.edad} | Peso: ${m.peso} kg",
                ),
              ),
            )),
      ],
    ),
  );
}
  // ---------------- PANTALLA PERFIL ----------------
  Widget _perfil(AppProvider app) {
    final usuario = app.usuarioActual;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // FOTO DE PERFIL
          GestureDetector(
            onTap: seleccionarFotoPerfil,
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey.shade300,
              backgroundImage: imagenPerfil != null
                  ? FileImage(imagenPerfil!)
                  : (usuario?.foto != null
                        ? FileImage(File(usuario!.foto!))
                        : null),
              child: (imagenPerfil == null && usuario?.foto == null)
                  ? const Icon(Icons.camera_alt, size: 40)
                  : null,
            ),
          ),

          const SizedBox(height: 10),

          // NOMBRE
          Text(
            usuario?.nombre ?? "Usuario",
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 5),

          // EMAIL
          Text(
            usuario?.email ?? "",
            style: const TextStyle(color: Colors.grey),
          ),

          const SizedBox(height: 30),

          // EDITAR NOMBRE
          TextField(
            controller: nombrePerfilController,
            decoration: const InputDecoration(
              labelText: "Editar nombre",
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 10),

          // EDITAR EMAIL
          TextField(
            controller: emailPerfilController,
            decoration: const InputDecoration(
              labelText: "Editar email",
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 20),

          // GUARDAR CAMBIOS
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              minimumSize: const Size(double.infinity, 50),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              app.actualizarPerfil(
                nombrePerfilController.text,
                emailPerfilController.text,
                imagenPerfil?.path,
              );

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Perfil actualizado")),
              );
            },
            child: const Text("Guardar cambios"),
          ),

          const SizedBox(height: 20),

          // CERRAR SESIÓN
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              minimumSize: const Size(double.infinity, 50),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              app.logout();

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => LoginScreen()),
                (route) => false,
              );
            },
            child: const Text("Cerrar sesión"),
          ),
        ],
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final app = Provider.of<AppProvider>(context);
    if (app.usuarioActual != null) {
      nombrePerfilController.text = app.usuarioActual!.nombre;
      emailPerfilController.text = app.usuarioActual!.email;
    }
  }

  @override
  void dispose() {
    mascotaController.dispose();
    razaController.dispose();
    edadController.dispose();
    pesoController.dispose();
    colorController.dispose();
    nombrePerfilController.dispose();
    emailPerfilController.dispose();
    super.dispose();
  }
}

/// ---------------- APP PRINCIPAL ----------------
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Clínica Veterinaria',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: LoginScreen(),
      ),
    ),
  );
}

class PasosScreen extends StatefulWidget {
  final AppProvider app;

  const PasosScreen({super.key, required this.app});

  @override
  State<PasosScreen> createState() => _PasosScreenState();
}

class _PasosScreenState extends State<PasosScreen>
    with SingleTickerProviderStateMixin {

  int pasos = 0;
  bool contando = false;
  String? mascotaSeleccionada;
  List<String> historial = [];

  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: -10, end: 10).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    Future.delayed(const Duration(seconds: 1), _sumarPasos);
  }

  void _sumarPasos() async {
    while (true) {
      await Future.delayed(const Duration(seconds: 1));
      if (contando) {
        setState(() {
          pasos += 2;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.app;

return Scaffold(
  appBar: AppBar(
    title: const Text("Caminata"),
    backgroundColor: Colors.blue,
  ),



  body: Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Color.fromARGB(255, 241, 235, 243),
          Color.fromARGB(255, 255, 255, 255),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),

    child: SafeArea(
      child: Stack(
        children: [

          // 🐾 PATITAS (AHORA SÍ BIEN)
          Positioned(
            top: 80,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _animation.value),
                  child: const Icon(
                    Icons.pets,
                    size: 90,
                    color: Color.fromARGB(255, 51, 150, 249),
                  ),
                );
              },
            ),
          ),

          // 📦 CONTENIDO
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [

                const SizedBox(height: 120),

                // 🔢 PASOS
                const SizedBox(height: 30),
                Text(
                  "$pasos",
                  style: const TextStyle(
                    fontSize: 60,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 51, 150, 249),
                  ),
                ),

                const Text(
                  "pasos",
                  style: TextStyle(color: Color.fromARGB(255, 51, 150, 249)),
                ),

                const SizedBox(height: 30),
                const SizedBox(height: 30),

                //  SELECTOR
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: DropdownButtonFormField<String>(
                    dropdownColor: const Color.fromARGB(255, 255, 255, 255),
                    value: mascotaSeleccionada,
                    hint: const Text(
                      'Seleccionar mascota',
                      style: TextStyle(color: Color.fromARGB(255, 51, 150, 249),),
                    ),
                    style: const TextStyle(color: Color.fromARGB(255, 51, 150, 249),),
                    items: app.mascotas
                        .map((m) => DropdownMenuItem(
                              value: m.id,
                              child: Text(m.nombre),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        mascotaSeleccionada = value;
                      });
                    },
                  ),
                ),

                const SizedBox(height: 30),

                //  BOTONES
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          padding: const EdgeInsets.all(15),
                        ),
                        onPressed: () {
                          setState(() {
                            contando = true;
                          });
                        },
                        child: const Text("Iniciar"),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          padding: const EdgeInsets.all(15),
                        ),
                        onPressed: () {
                          if (mascotaSeleccionada == null) return;

                          historial.add(
                            'Mascota: ${app.mascotas.firstWhere((m) => m.id == mascotaSeleccionada).nombre} - Pasos: $pasos - ${DateTime.now().toString().split(' ')[0]}',
                          );

                          setState(() {
                            contando = false;
                            pasos = 0;
                          });
                        },
                        child: const Text("Detener"),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // HISTORIAL
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Historial",
                    style: TextStyle(
                      color: Color.fromARGB(255, 51, 150, 249),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                Expanded(
                  child: ListView(
                    children: historial.map((h) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 51, 150, 249),

                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          h,
                          style: const TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  ),
);
  }
    }


class SubirFotoWidget extends StatefulWidget {
  const SubirFotoWidget({Key? key}) : super(key: key);

  @override
  _SubirFotoWidgetState createState() => _SubirFotoWidgetState();
}

class _SubirFotoWidgetState extends State<SubirFotoWidget> {
  File? _imagen;
  final ImagePicker _picker = ImagePicker();

  Future<void> _tomarFoto() async {
    final XFile? foto = await _picker.pickImage(source: ImageSource.camera);
    if (foto != null) {
      setState(() {
        _imagen = File(foto.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(onPressed: _tomarFoto, child: const Text("Subir Foto")),
        if (_imagen != null) Image.file(_imagen!, height: 200),
      ],
    );
  }
}
