import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'database/db_helper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// ---------------- MODELOS ----------------
class Usuario {
  final String id;
  String nombre;
  String email;
  String rol;
  String? foto;

  Usuario({required this.id, required this.nombre, required this.email, this.rol = 'cliente', this.foto,});
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

  Future registrarUsuario(Usuario usuario, String password) async {
    // 1. Crear cuenta en Supabase Auth
    final response = await supabase.auth.signUp(
      email: usuario.email,
      password: password,
    );

    if (response.user == null) throw Exception('Error al registrar');

    // 2. Guardar perfil en tu tabla 'usuarios'
    await supabase.from('usuarios').insert({
      'id': response.user!.id, // Usar el ID de Supabase
      'nombre': usuario.nombre,
      'email': usuario.email,
      'rol': usuario.rol,
    });

    usuario = Usuario(
      id: response.user!.id,
      nombre: usuario.nombre,
      email: usuario.email,
    );

    usuarioActual = usuario;
    notifyListeners();
  }

Future<bool> login(String email, String password) async {
    final response = await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.user == null) return false;

    final data = await supabase
        .from('usuarios')
        .select()
        .eq('id', response.user!.id)
        .single();

    usuarioActual = Usuario(
      id: data['id'],
      nombre: data['nombre'],
      email: data['email'],
      rol: data['rol'] ?? 'cliente',
      foto: data['foto'],
    );

    // Cargar mascotas
    final mascotasData = await supabase
        .from('mascotas')
        .select()
        .eq('usuarioId', response.user!.id);

    mascotas = (mascotasData as List).map((m) => Mascota(
      id: m['id'],
      nombre: m['nombre'],
      especie: m['especie'],
      raza: m['raza'],
      edad: m['edad'],
      peso: m['peso'],
      sexo: m['sexo'],
      color: m['color'],
    )).toList();

    // Cargar citas
    final citasData = await supabase
        .from('citas')
        .select()
        .eq('clienteId', response.user!.id);

    citas = (citasData as List).map((c) => Cita(
      id: c['id'],
      clienteId: c['clienteId'],
      mascotaId: c['mascotaId'],
      fecha: DateTime.parse(c['fecha']),
      veterinario: c['veterinario'],
      servicio: c['servicio'],
      estado: c['estado'],
    )).toList();

    notifyListeners();
    return true;
  }

  void logout() async {
    await supabase.auth.signOut();
    usuarioActual = null;
    mascotas = [];
    citas = [];
    notifyListeners();
  }

  Future agregarMascota(Mascota mascota) async {
    if (usuarioActual == null) throw Exception('No hay sesión activa');

    await supabase.from('mascotas').insert({
      'id': mascota.id,
      'nombre': mascota.nombre,
      'especie': mascota.especie,
      'raza': mascota.raza,
      'edad': mascota.edad,
      'peso': mascota.peso,
      'sexo': mascota.sexo,
      'color': mascota.color,
      'usuarioId': usuarioActual!.id,
    });

    mascotas.add(mascota);
    notifyListeners();
  }

  Future agregarCita(Cita cita) async {
    if (usuarioActual == null) throw Exception('No hay sesión activa');

    await supabase.from('citas').insert({
      'id': cita.id,
      'clienteId': cita.clienteId,
      'mascotaId': cita.mascotaId,
      'fecha': cita.fecha.toIso8601String(),
      'veterinario': cita.veterinario,
      'servicio': cita.servicio,
      'estado': cita.estado,
    });

    citas.add(cita);
    notifyListeners();
  }

  List<Cita> obtenerCitasUsuario(String clienteId) {
    return citas.where((c) => c.clienteId == clienteId).toList();
  }


void actualizarPerfil(String nombre, String email, String? foto) {
  if (usuarioActual != null) {
    usuarioActual!.nombre = nombre;
    usuarioActual!.email = email;
    usuarioActual!.foto = foto ?? usuarioActual!.foto;
    notifyListeners();
  }
}
}

/// ---------------- LOGIN ----------------
class LoginScreen extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController conController = TextEditingController();

  LoginScreen({super.key});

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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/logo.png',
                      width: 300,
                      height: 200,
                    ),
                    SizedBox(height: 12),
                    Text('Bienvenido',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color:const Color.fromARGB(255, 0, 50, 92))),
                         TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        enableSuggestions: false,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email),
                        )),
                    SizedBox(height: 20),
                    TextField(
                        controller: conController,
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.lock),
                        )),
                    SizedBox(height: 10),
                   
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.blue, 
                        minimumSize: Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: Text('Registrar'),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => RegisterScreen()),
                        );
                      },
                    ),
                    SizedBox(height: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 50),
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: Text('Iniciar Sesión'),
                      onPressed: () async {
                        try {
                          final ok = await app.login(
                            emailController.text.trim(),
                            conController.text.trim(),
                          );

                          if (ok) {
                            Navigator.pushReplacement(context,
                                MaterialPageRoute(builder: (_) => HomeScreen()));
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Credenciales incorrectas')),
                            );
                          }
                        } catch (e) {
                          print('ERROR LOGIN: $e');
                          String mensaje = 'Error al iniciar sesión';

                          if (e.toString().contains('Email not confirmed')) {
                            mensaje = 'Debes confirmar tu email antes de entrar';
                          } else if (e.toString().contains('Invalid login credentials')) {
                            mensaje = 'Email o contraseña incorrectos';
                          } else if (e.toString().contains('rate limit')) {
                            mensaje = 'Demasiados intentos, espera unos minutos';
                          }

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(mensaje),
                              backgroundColor: Colors.red,
                              duration: Duration(seconds: 6),
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
  final TextEditingController emailController = TextEditingController();
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController contraController = TextEditingController();
  final TextEditingController nacController = TextEditingController();
  final TextEditingController genContorller = TextEditingController();
  final TextEditingController confirmarContraController = TextEditingController();

  RegisterScreen({super.key});

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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/logo.png',
                      width: 300,
                      height: 200,
                    ),
                    SizedBox(height: 12),
                    Text('Bienvenido',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color:const Color.fromARGB(255, 0, 50, 92))),
                    SizedBox(height: 20),
                    TextField(
                        controller: nombreController,
                        decoration: InputDecoration(
                          labelText: 'Nombre',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        )),
                    SizedBox(height: 10),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      enableSuggestions: false,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                    ),

                    TextField(
                      controller: contraController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock),
                      ),
                    ),

                    SizedBox(height: 10),

                    TextField(
                      controller: confirmarContraController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Confirmar contraseña',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                    ),

                    SizedBox(height: 10),

                    TextField(
                      controller: nacController,
                      decoration: InputDecoration(
                        labelText: 'Fecha de nacimiento',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.cake),
                      ),
                    ),

                    SizedBox(height: 10),

                    TextField(
                      controller: genContorller,
                      decoration: InputDecoration(
                        labelText: 'Género',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),

                    SizedBox(height: 20),
                    SizedBox(height: 20),
                    SizedBox(height: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 50),
                        backgroundColor: Colors.blue,
                      ),
                      child: Text(
                        'Registrar',
                        style: TextStyle(color: Colors.white),
                      ),
                      onPressed: () async {
                        // Validación básica de campos vacíos
                        if (nombreController.text.isEmpty ||
                            emailController.text.isEmpty ||
                            contraController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Por favor llena todos los campos')),
                          );
                          return;
                        }

                        if (contraController.text.length < 6) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('La contraseña debe tener al menos 6 caracteres'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        // Validación de coincidencia
                        if (contraController.text != confirmarContraController.text) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Las contraseñas no coinciden'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        try {
                          final nuevoUsuario = Usuario(
                            id: '',
                            nombre: nombreController.text.trim(),
                            email: emailController.text.trim(),
                          );

                          await app.registrarUsuario(nuevoUsuario, contraController.text.trim());

                          Navigator.pushReplacement(context,
                              MaterialPageRoute(builder: (_) => HomeScreen()));

                        } catch (e) {
                          print('ERROR REGISTRO: $e');
                          String mensaje = 'Error al registrar';

                          if (e.toString().contains('already registered')) {
                            mensaje = 'Este email ya está registrado';
                          } else if (e.toString().contains('Password should be')) {
                            mensaje = 'La contraseña debe tener al menos 6 caracteres';
                          } else if (e.toString().contains('Invalid email')) {
                            mensaje = 'El email no es válido';
                          }

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(mensaje),
                              backgroundColor: Colors.red,
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
/// ---------------- DASHBOARD ----------------
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = Provider.of<AppProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Hola ${app.usuarioActual?.nombre ?? ''}'),
        backgroundColor: Colors.blue.shade700,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              app.logout();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => LoginScreen()),
              );
            },
          )
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
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _menuButton(
                context,
                'Mis Citas',
                Icons.calendar_today,
                HomeScreen(), 
              ),
              SizedBox(height: 20),
              _menuButton(
                context,
                'Registrar Mascota',
                Icons.pets,
                HomeScreen(),
              ),
              SizedBox(height: 20),
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
      BuildContext context, String text, IconData icon, Widget screen) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 28),
      label: Padding(
        padding: EdgeInsets.symmetric(vertical: 15),
        child: Text(text, style: TextStyle(fontSize: 18)),
      ),
      style: ElevatedButton.styleFrom(
        minimumSize: Size(double.infinity, 60),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 8,
      ),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => screen),
        );
      },
    );
  }
}

/// ---------------- HOME SCREEN ----------------
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  final TextEditingController mascotaController = TextEditingController();
  final TextEditingController veterinarioController = TextEditingController();
  final TextEditingController servicioController = TextEditingController();
  final TextEditingController fechaController = TextEditingController();
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


String especieSeleccionada = 'Perro';
String sexoSeleccionado = 'Macho';

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
            icon: Icon(Icons.logout),
            onPressed: () {
              app.logout();
              Navigator.pop(context);
            },
          )
        ],
      ),

      body: _selectedIndex == 0
          ? _inicio(app)
          : _selectedIndex == 1
              ? _citas(app)
              : _selectedIndex == 2
                  ? _mascotas(app)
                  : _perfil(app),


      bottomNavigationBar: BottomAppBar(
        shape: CircularNotchedRectangle(),
        notchMargin: 8,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: Icon(Icons.home,
                    color: _selectedIndex == 0 ? Colors.blue : Colors.grey),
                onPressed: () => setState(() => _selectedIndex = 0),
              ),
              IconButton(
                icon: Icon(Icons.calendar_today,
                    color: _selectedIndex == 1 ? Colors.blue : Colors.grey),
                onPressed: () => setState(() => _selectedIndex = 1),
              ),
              SizedBox(width: 40),
              IconButton(
                icon: Icon(Icons.pets,
                    color: _selectedIndex == 2 ? Colors.blue : Colors.grey),
                onPressed: () => setState(() => _selectedIndex = 2),
              ),
              IconButton(
                icon: Icon(Icons.person,
                    color: _selectedIndex == 3 ? Colors.blue : Colors.grey),
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
  if (imagen == null) return;

  final app = Provider.of<AppProvider>(context, listen: false);
  final userId = app.usuarioActual?.id;
  if (userId == null) return;

  try {
    final file = File(imagen.path);
    final extension = imagen.path.split('.').last;
    final path = 'perfil/$userId.$extension';

    // Subir a Supabase Storage
    await supabase.storage.from('avatars').upload(
      path,
      file,
      fileOptions: FileOptions(upsert: true),
    );

    // Obtener URL pública
    final url = supabase.storage.from('avatars').getPublicUrl(path);

    // Guardar URL en la tabla usuarios
    await supabase.from('usuarios').update({'foto': url}).eq('id', userId);

    // Actualizar estado local
    setState(() {
      imagenPerfil = file;
    });

    app.actualizarPerfil(
      app.usuarioActual!.nombre,
      app.usuarioActual!.email,
      url,
    );

  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error al subir la foto'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

  // ---------------- PANTALLA INICIO ----------------
  Widget _inicio(AppProvider app) {
  if (app.usuarioActual == null) return Center(child: Text('Sesión no iniciada'));
  final citas = app.obtenerCitasUsuario(app.usuarioActual!.id);

  return SingleChildScrollView(
    padding: EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // 🐶 Imagen principal
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.asset("assets/cd.png",
            height: 180,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),

        SizedBox(height: 20),

        // Citas pendientes 
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Citas Pendientes",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              "Ver todo",
              style: TextStyle(color: Colors.blue),
            )
          ],
        ),

        SizedBox(height: 10),

        citas.isEmpty
            ? Text("No tienes citas registradas")
            : SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: citas.length,
                  itemBuilder: (context, index) {
                    final cita = citas[index];
                    return Container(
                      width: 200,
                      margin: EdgeInsets.only(right: 12),
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cita.servicio,
                            style: TextStyle(
                                fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 5),
                          Text("Vet: ${cita.veterinario}"),
                          SizedBox(height: 5),
                          Text(
                            "${cita.fecha.toLocal()}".split(' ')[0],
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

        SizedBox(height: 25),

        // 🐾 Mascotas
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Mascotas",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              "Ver todo",
              style: TextStyle(color: Colors.blue),
            )
          ],
        ),

        SizedBox(height: 10),

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
                    margin: EdgeInsets.only(right: 12),
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.pets, color: Colors.blue),
                  ),
                  SizedBox(height: 5),
                  Text(mascota.nombre),
                ],
              );
            },
          ),
        ),

        SizedBox(height: 25),

        // 👩‍⚕️ Veterinarios

        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.asset("assets/vet.jpg",
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
  DateTime fechaSeleccionada = DateTime.now();
  String horaSeleccionada = "";
  String? motivoSeleccionado;
  String? veterinarioSeleccionado;

  final List<String> horarios = [
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

  final List<String> motivos = [
    "Consulta General",
    "Vacunación",
    "Desparasitación",
    "Cirugía",
    "Emergencia",
    "Baño y Grooming",
  ];

  final List<String> veterinarios = [
    "Dr. Carlos Ramírez",
    "Dra. Sofía Mendoza",
    "Dr. Andrés López",
    "Dra. Valeria Torres",
  ];

  return StatefulBuilder(
    builder: (context, setState) {
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

            /// 🔹 MOTIVO
            DropdownButtonFormField<String>(
              initialValue: motivoSeleccionado,
              decoration: InputDecoration(
                labelText: "Motivo de la cita",
                prefixIcon: const Icon(Icons.pets),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              items: motivos
                  .map((m) => DropdownMenuItem(
                        value: m,
                        child: Text(m),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  motivoSeleccionado = value;
                });
              },
            ),

            const SizedBox(height: 15),

            /// 🔹 VETERINARIO
            DropdownButtonFormField<String>(
              initialValue: veterinarioSeleccionado,
              decoration: InputDecoration(
                labelText: "Seleccionar Veterinario",
                prefixIcon: const Icon(Icons.medical_services),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              items: veterinarios
                  .map((v) => DropdownMenuItem(
                        value: v,
                        child: Text(v),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  veterinarioSeleccionado = value;
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
                initialDate: fechaSeleccionada,
                firstDate: DateTime.now(),
                lastDate: DateTime(2030),
                onDateChanged: (date) {
                  setState(() {
                    fechaSeleccionada = date;
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
              itemCount: horarios.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 2.5,
              ),
              itemBuilder: (context, index) {
                final hora = horarios[index];
                final seleccionada = hora == horaSeleccionada;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      horaSeleccionada = hora;
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
                        color:
                            seleccionada ? Colors.white : Colors.black87,
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
                onPressed: (motivoSeleccionado == null ||
                        veterinarioSeleccionado == null ||
                        horaSeleccionada.isEmpty)
                    ? null
                    : () {
                        app.agregarCita(Cita(
                          id: DateTime.now().toString(),
                          clienteId: app.usuarioActual!.id,
                          mascotaId: app.mascotas.isNotEmpty
                              ? app.mascotas.last.id
                              : '',
                          fecha: fechaSeleccionada,
                          veterinario: veterinarioSeleccionado!,
                          servicio: motivoSeleccionado!,
                        ));

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Cita agendada correctamente"),
                          ),
                        );
                      },
                child: const Text(
                  "Confirmar Cita",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      );
    },
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
          child: Text("Registrar Mascota"),
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

  nombrePerfilController.text = usuario?.nombre ?? "";
  emailPerfilController.text = usuario?.email ?? "";

  return SingleChildScrollView(
    padding: EdgeInsets.all(20),
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
                    ? NetworkImage(usuario!.foto!) as ImageProvider
                    : null),
            child: (imagenPerfil == null && usuario?.foto == null)
                ? Icon(Icons.camera_alt, size: 40)
                : null,
          ),
        ),

        SizedBox(height: 10),

        // NOMBRE
        Text(
          usuario?.nombre ?? "Usuario",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),

        SizedBox(height: 5),

        // EMAIL
        Text(
          usuario?.email ?? "",
          style: TextStyle(
            color: Colors.grey,
          ),
        ),

        SizedBox(height: 30),

        // EDITAR NOMBRE
        TextField(
          controller: nombrePerfilController,
          decoration: InputDecoration(
            labelText: "Editar nombre",
            border: OutlineInputBorder(),
          ),
        ),

        SizedBox(height: 10),

        // EDITAR EMAIL
        TextField(
          controller: emailPerfilController,
          decoration: InputDecoration(
            labelText: "Editar email",
            border: OutlineInputBorder(),
          ),
        ),

        SizedBox(height: 20),

        // GUARDAR CAMBIOS
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            minimumSize: Size(double.infinity, 50),
            foregroundColor: Colors.white,
          ),
          onPressed: () {

            app.actualizarPerfil(
              nombrePerfilController.text,
              emailPerfilController.text,
              imagenPerfil?.path,
            );

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Perfil actualizado")),
            );
          },
          child: Text("Guardar cambios"),
        ),

        SizedBox(height: 20),

        // CERRAR SESIÓN
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            minimumSize: Size(double.infinity, 50),
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
          child: Text("Cerrar sesión"),
        ),
      ],
    ),
  );
}

}
/// ---------------- APP PRINCIPAL ----------------
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://vgebmmsazwirthdoffuc.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZnZWJtbXNhendpcnRoZG9mZnVjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM1MzE4MzIsImV4cCI6MjA4OTEwNzgzMn0.MX4Lcj4lFhpTITucYYXnLm6BI3nj4L4WK1xmpg8Mvug',
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Clínica Veterinaria',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: supabase.auth.currentSession != null
            ? HomeScreen()
            : LoginScreen(),
      ),
    ),
  );
}

// Helper global para acceder al cliente
final supabase = Supabase.instance.client;
