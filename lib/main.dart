import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:pedometer/pedometer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

// ════════════════════════════════════════════════════════════════
//  MODELO NOTIFICACION
// ════════════════════════════════════════════════════════════════

class AppNotificacion {
  final String id, titulo, cuerpo;
  final DateTime fecha;
  bool leida;
  final String tipo; // 'cita' | 'vacuna'

  AppNotificacion({
    required this.id,
    required this.titulo,
    required this.cuerpo,
    required this.fecha,
    required this.tipo,
    this.leida = false,
  });
}

class Veterinario {
  final String id, nombre;
  final String? especialidad, foto;

  Veterinario({
    required this.id,
    required this.nombre,
    this.especialidad,
    this.foto,
  });

  factory Veterinario.fromJson(Map<String, dynamic> j) => Veterinario(
    id:           j['id'],
    nombre:       j['nombre'],
    especialidad: j['especialidad'],
    foto:         j['foto_url'],
  );
}
// ════════════════════════════════════════════════════════════════
final supabase = Supabase.instance.client;

// ════════════════════════════════════════════════════════════════
//  COLORES GLOBALES
// ════════════════════════════════════════════════════════════════
const kPrimary = Color(0xFF1565C0);
const kLight   = Color(0xFF42A5F5);
const kAccent  = Color(0xFF00B0FF);
const kBg      = Color(0xFFF4F6FB);

// ════════════════════════════════════════════════════════════════
//  MODELOS
// ════════════════════════════════════════════════════════════════

class Usuario {
  final String id;
  String nombre, email, rol;
  String? foto, password, fechaNacimiento, genero, telefono, direccion;

  Usuario({
    required this.id,
    required this.nombre,
    required this.email,
    this.rol = 'cliente',
    this.foto,
    this.password,
    this.fechaNacimiento,
    this.genero,
    this.telefono,
    this.direccion,
  });

  factory Usuario.fromJson(Map<String, dynamic> j, String email) => Usuario(
    id: j['id'] as String,
    nombre: j['nombre'] ?? 'Usuario',
    email: email,
    telefono: j['telefono'],
    direccion: j['direccion'],
    fechaNacimiento: j['fecha_nacimiento'],
    genero: j['genero'],
    foto: j['foto_url'],
  );
}

class Mascota {
  final String id;
  String nombre, especie, raza, edad, peso, sexo, color;
  String? foto, microchip;

  Mascota({
    required this.id,
    required this.nombre,
    required this.especie,
    required this.raza,
    required this.edad,
    required this.peso,
    required this.sexo,
    required this.color,
    this.foto,
    this.microchip,
  });

  factory Mascota.fromJson(Map<String, dynamic> j) => Mascota(
    id:        j['id'],
    nombre:    j['nombre'],
    especie:   j['especie']  ?? 'Perro',
    raza:      j['raza']     ?? '',
    edad:      j['edad']     ?? '',
    peso:      j['peso']     ?? '',
    sexo:      j['sexo']     ?? 'Macho',
    color:     j['color']    ?? '',
    foto:      j['foto_url'],
    microchip: j['microchip'],
  );

  Map<String, dynamic> toJson(String userId) => {
    'user_id':  userId,
    'nombre':   nombre,
    'especie':  especie,
    'raza':     raza,
    'edad':     edad,
    'peso':     peso,
    'sexo':     sexo,
    'color':    color,
    'foto_url': foto,
    'microchip':microchip,
  };
}

class Cita {
  final String id, clienteId;
  String mascotaId, veterinario, servicio, estado;
  DateTime fecha;

  Cita({
    required this.id,
    required this.clienteId,
    required this.mascotaId,
    required this.fecha,
    required this.veterinario,
    required this.servicio,
    this.estado = 'Pendiente',
  });

  factory Cita.fromJson(Map<String, dynamic> j) => Cita(
    id:          j['id'],
    clienteId:   j['user_id'],
    mascotaId:   j['mascota_id'] ?? '',
    fecha:       DateTime.parse(j['fecha']).toLocal(),
    veterinario: j['veterinario'],
    servicio:    j['servicio'],
    estado:      j['estado'] ?? 'Pendiente',
  );

  Map<String, dynamic> toJson(String userId) => {
    'user_id':    userId,
    'mascota_id': mascotaId.isEmpty ? null : mascotaId,
    'fecha':      fecha.toUtc().toIso8601String(),
    'veterinario':veterinario,
    'servicio':   servicio,
    'estado':     estado,
  };
}

class VisitaMedica {
  final String id, mascotaId, diagnostico, tratamiento, veterinario;
  final DateTime fecha;

  VisitaMedica({
    required this.id,
    required this.mascotaId,
    required this.fecha,
    required this.diagnostico,
    required this.tratamiento,
    required this.veterinario,
  });

  factory VisitaMedica.fromJson(Map<String, dynamic> j) => VisitaMedica(
    id:          j['id'],
    mascotaId:   j['mascota_id'],
    fecha:       DateTime.parse(j['fecha']).toLocal(),
    diagnostico: j['diagnostico'],
    tratamiento: j['tratamiento'] ?? '',
    veterinario: j['veterinario'],
  );
}

class Vacuna {
  final String id, mascotaId, nombre;
  final DateTime fecha;
  final DateTime? proxima;

  Vacuna({
    required this.id,
    required this.mascotaId,
    required this.nombre,
    required this.fecha,
    this.proxima,
  });

  factory Vacuna.fromJson(Map<String, dynamic> j) => Vacuna(
    id:        j['id'],
    mascotaId: j['mascota_id'],
    nombre:    j['nombre'],
    fecha:     DateTime.parse(j['fecha']),
    proxima:   j['proxima'] != null ? DateTime.parse(j['proxima']) : null,
  );
}

// ════════════════════════════════════════════════════════════════
//  PROVIDER  (con Supabase)
// ════════════════════════════════════════════════════════════════

class AppProvider with ChangeNotifier {
  List<Mascota>          mascotas      = [];
  List<Cita>             citas         = [];
  List<VisitaMedica>     visitas       = [];
  List<Vacuna>           vacunas       = [];
  List<Veterinario>      veterinarios  = [];
  List<AppNotificacion>  notificaciones = [];
  Usuario?               usuarioActual;
  bool                   cargando = false;

  String? get uid => supabase.auth.currentUser?.id;

  int get notificacionesNoLeidas =>
      notificaciones.where((n) => !n.leida).length;

  // ── Notificaciones ──────────────────────────────

  void generarNotificaciones() {
    final ahora = DateTime.now();
    final nuevas = <AppNotificacion>[];

    // Notificaciones de citas próximas (hoy, mañana, en 2 días, en 3 días)
    for (final cita in citas) {
      if (cita.estado == 'Cancelada') continue;
      final diff = cita.fecha.difference(ahora);
      final dias = diff.inDays;
      final horas = diff.inHours;

      String? titulo;
      String? cuerpo;

      if (horas >= 0 && horas <= 2) {
        titulo = '⏰ ¡Cita en menos de 2 horas!';
        cuerpo = '${cita.servicio} con ${cita.veterinario.split(' ').take(2).join(' ')} a las '
            '${cita.fecha.hour.toString().padLeft(2, '0')}:${cita.fecha.minute.toString().padLeft(2, '0')}';
      } else if (dias == 0) {
        titulo = '🐾 Tienes una cita hoy';
        cuerpo = '${cita.servicio} a las ${cita.fecha.hour.toString().padLeft(2, '0')}:${cita.fecha.minute.toString().padLeft(2, '0')} con ${cita.veterinario.split(' ').first}';
      } else if (dias == 1) {
        titulo = '📅 Cita mañana';
        cuerpo = '${cita.servicio} con ${cita.veterinario.split(' ').first} a las ${cita.fecha.hour.toString().padLeft(2, '0')}:${cita.fecha.minute.toString().padLeft(2, '0')}';
      } else if (dias <= 3) {
        titulo = '📆 Cita en $dias días';
        cuerpo = '${cita.servicio} el ${cita.fecha.day}/${cita.fecha.month} con ${cita.veterinario.split(' ').first}';
      }

      if (titulo != null) {
        final id = 'cita_${cita.id}';
        if (!notificaciones.any((n) => n.id == id)) {
          nuevas.add(AppNotificacion(
            id: id, titulo: titulo, cuerpo: cuerpo!, fecha: ahora, tipo: 'cita',
          ));
        }
      }
    }

    // Notificaciones de vacunas próximas
    for (final vac in vacunas) {
      if (vac.proxima == null) continue;
      final dias = vac.proxima!.difference(ahora).inDays;
      if (dias >= 0 && dias <= 7) {
        final id = 'vac_${vac.id}';
        if (!notificaciones.any((n) => n.id == id)) {
          final mascNom = mascotas.where((m) => m.id == vac.mascotaId)
              .map((m) => m.nombre).firstOrNull ?? '';
          nuevas.add(AppNotificacion(
            id: id,
            titulo: '💉 Vacuna próxima: ${vac.nombre}',
            cuerpo: '$mascNom necesita su vacuna en $dias día${dias == 1 ? '' : 's'}',
            fecha: ahora,
            tipo: 'vacuna',
          ));
        }
      }
    }

    if (nuevas.isNotEmpty) {
      notificaciones.insertAll(0, nuevas);
      notifyListeners();
    }
  }

  void marcarTodasLeidas() {
    for (final n in notificaciones) { n.leida = true; }
    notifyListeners();
  }

  void marcarLeida(String id) {
    final idx = notificaciones.indexWhere((n) => n.id == id);
    if (idx != -1) { notificaciones[idx].leida = true; notifyListeners(); }
  }

  // ── Auth ────────────────────────────────────────

  Future<String?> registrar({
    required String email, required String password,
    required String nombre, String? tel, String? dir,
    String? nac, String? gen,
  }) async {
    try {
      final res = await supabase.auth.signUp(
        email: email, password: password,
        data: {'nombre': nombre},
      );
      if (res.user == null) return 'Error al registrar';
      await supabase.from('profiles').upsert({
        'id': res.user!.id, 'nombre': nombre,
        'telefono': tel, 'direccion': dir,
        'fecha_nacimiento': nac, 'genero': gen,
      });
      await _cargarPerfil(email);
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> login(String email, String password) async {
    try {
      final res = await supabase.auth.signInWithPassword(
          email: email, password: password);
      if (res.user == null) return 'Credenciales incorrectas';
      await _cargarPerfil(email);
      await cargarTodo();
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> logout() async {
    await supabase.auth.signOut();
    usuarioActual = null;
    mascotas = []; citas = []; visitas = []; vacunas = [];
    notificaciones = [];
    notifyListeners();
  }

  Future<void> _cargarPerfil(String email) async {
    final p = await supabase.from('profiles')
        .select().eq('id', uid!).maybeSingle();
    usuarioActual = p != null
        ? Usuario.fromJson(p, email)
        : Usuario(id: uid!, nombre: 'Usuario', email: email);
    notifyListeners();
  }

  // ── Carga inicial ────────────────────────────────

  Future<void> cargarVeterinarios() async {
    try {
      final rows = await supabase
          .from('veterinarios')
          .select()
          .eq('activo', true)
          .order('nombre');
      veterinarios = (rows as List)
          .map((r) => Veterinario.fromJson(r))
          .toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error cargando veterinarios: $e');
    }
  }

  Future<void> cargarTodo() async {
    if (uid == null) return;
    cargando = true; notifyListeners();
    try {
      await cargarVeterinarios();

      final mRows = await supabase.from('mascotas')
          .select().eq('user_id', uid!);
      mascotas = (mRows as List).map((r) => Mascota.fromJson(r)).toList();

      final cRows = await supabase.from('citas')
          .select().eq('user_id', uid!).order('fecha');
      citas = (cRows as List).map((r) => Cita.fromJson(r)).toList();

      if (mascotas.isNotEmpty) {
        final mIds = mascotas.map((m) => m.id).toList();
        final vRows = await supabase.from('visitas_medicas')
            .select().inFilter('mascota_id', mIds);
        visitas = (vRows as List)
            .map((r) => VisitaMedica.fromJson(r)).toList();

        final vacRows = await supabase.from('vacunas')
            .select().inFilter('mascota_id', mIds);
        vacunas = (vacRows as List).map((r) => Vacuna.fromJson(r)).toList();
      }

      // Generar notificaciones después de cargar todo
      generarNotificaciones();
    } catch (e) {
      debugPrint('Error en cargarTodo: $e');
    }
    cargando = false; notifyListeners();
  }

  // ── Perfil ───────────────────────────────────────

  Future<void> actualizarPerfil({
    required String nombre, required String email,
    String? foto, String? tel, String? dir, String? nac, String? gen,
  }) async {
    if (uid == null) return;
    String? fotoUrl = foto;
    if (foto != null && !foto.startsWith('http')) {
      fotoUrl = await _subirFoto(foto, 'perfiles');
    }
    await supabase.from('profiles').upsert({
      'id': uid, 'nombre': nombre,
      'telefono': tel, 'direccion': dir,
      'fecha_nacimiento': nac, 'genero': gen,
      if (fotoUrl != null) 'foto_url': fotoUrl,
    });
    usuarioActual?.nombre = nombre;
    usuarioActual?.email  = email;
    if (tel     != null) usuarioActual?.telefono        = tel;
    if (dir     != null) usuarioActual?.direccion       = dir;
    if (nac     != null) usuarioActual?.fechaNacimiento = nac;
    if (gen     != null) usuarioActual?.genero          = gen;
    if (fotoUrl != null) usuarioActual?.foto            = fotoUrl;
    notifyListeners();
  }

  // ── Subir foto a Supabase Storage ───────────────

  Future<String?> _subirFoto(String rutaLocal, String bucket) async {
    try {
      final file      = File(rutaLocal);
      final extension = rutaLocal.split('.').last.toLowerCase();
      final nombre    = '${uid}_${DateTime.now().millisecondsSinceEpoch}.$extension';
      await supabase.storage.from(bucket).upload(nombre, file,
          fileOptions: FileOptions(contentType: 'image/$extension', upsert: true));
      final url = supabase.storage.from(bucket).getPublicUrl(nombre);
      return url;
    } catch (_) {
      return null;
    }
  }

  // ── Mascotas ─────────────────────────────────────

  Future<void> agregarMascota(Mascota m) async {
    if (uid == null) return;
    String? fotoUrl;
    if (m.foto != null && !m.foto!.startsWith('http')) {
      fotoUrl = await _subirFoto(m.foto!, 'mascotas');
    }
    final data = m.toJson(uid!);
    if (fotoUrl != null) data['foto_url'] = fotoUrl;
    final row = await supabase.from('mascotas').insert(data).select().single();
    mascotas.add(Mascota.fromJson(row));
    notifyListeners();
  }

  Future<void> editarMascota(String id, String nombre, String especie,
      String raza, String edad, String peso, String sexo, String color,
      String? microchip, String? foto) async {
    String? fotoUrl = foto;
    if (foto != null && !foto.startsWith('http')) {
      fotoUrl = await _subirFoto(foto, 'mascotas');
    }
    await supabase.from('mascotas').update({
      'nombre': nombre, 'especie': especie, 'raza': raza,
      'edad': edad, 'peso': peso, 'sexo': sexo, 'color': color,
      'microchip': microchip,
      if (fotoUrl != null) 'foto_url': fotoUrl,
    }).eq('id', id);
    final i = mascotas.indexWhere((m) => m.id == id);
    if (i != -1) {
      mascotas[i]
        ..nombre = nombre ..especie = especie ..raza = raza
        ..edad = edad ..peso = peso ..sexo = sexo ..color = color
        ..microchip = microchip
        ..foto = fotoUrl ?? mascotas[i].foto;
    }
    notifyListeners();
  }

  Future<void> eliminarMascota(String id) async {
    await supabase.from('mascotas').delete().eq('id', id);
    mascotas.removeWhere((m) => m.id == id);
    notifyListeners();
  }

  // ── Citas ────────────────────────────────────────

  Future<void> agregarCita(Cita c) async {
    if (uid == null) return;
    final data = c.toJson(uid!);
    final vet = veterinarios.where((v) => v.nombre == c.veterinario).firstOrNull;
    if (vet != null) data['veterinario_id'] = vet.id;
    final row = await supabase.from('citas').insert(data).select().single();
    citas.add(Cita.fromJson(row));
    // Generar notificaciones al agregar cita
    generarNotificaciones();
    notifyListeners();
  }

  Future<void> cancelarCita(String id) async {
    await supabase.from('citas').delete().eq('id', id);
    citas.removeWhere((c) => c.id == id);
    // Limpiar notificaciones de esa cita
    notificaciones.removeWhere((n) => n.id == 'cita_$id');
    notifyListeners();
  }

  List<Cita> citasDeUsuario(String _) => citas;

  bool horarioOcupado(DateTime fecha, String vetNombre) {
    return citas.any((c) =>
        c.fecha == fecha &&
        c.veterinario == vetNombre &&
        c.estado != 'Cancelada');
  }

  bool vetDisponible(String vetNombre, DateTime fecha) {
    final vet = veterinarios.where((v) => v.nombre == vetNombre).firstOrNull;
    if (vet == null) return true;
    final diaSemana = fecha.weekday;
    if (diaSemana == 7) return false;
    return true;
  }

  // ── Historial medico ─────────────────────────────

  Future<void> agregarVisita(VisitaMedica v) async {
    final row = await supabase.from('visitas_medicas').insert({
      'mascota_id': v.mascotaId, 'fecha': v.fecha.toIso8601String(),
      'diagnostico': v.diagnostico, 'tratamiento': v.tratamiento,
      'veterinario': v.veterinario,
    }).select().single();
    visitas.add(VisitaMedica.fromJson(row));
    notifyListeners();
  }

  List<VisitaMedica> visitasDe(String mid) =>
      visitas.where((v) => v.mascotaId == mid).toList();

  // ── Vacunas ──────────────────────────────────────

  Future<void> agregarVacuna(Vacuna v) async {
    final row = await supabase.from('vacunas').insert({
      'mascota_id': v.mascotaId, 'nombre': v.nombre,
      'fecha': v.fecha.toIso8601String().split('T')[0],
      'proxima': v.proxima?.toIso8601String().split('T')[0],
    }).select().single();
    vacunas.add(Vacuna.fromJson(row));
    generarNotificaciones();
    notifyListeners();
  }

  List<Vacuna> vacunasDe(String mid) =>
      vacunas.where((v) => v.mascotaId == mid).toList();
}

// ════════════════════════════════════════════════════════════════
//  SPLASH
// ════════════════════════════════════════════════════════════════

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);
  @override State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    final app = Provider.of<AppProvider>(context, listen: false);
    await app.cargarVeterinarios();
    final session = supabase.auth.currentSession;
    if (session != null) {
      await app._cargarPerfil(session.user.email ?? '');
      await app.cargarTodo();
      if (!mounted) return;
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const HomeScreen()));
    } else {
      if (!mounted) return;
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) => const Scaffold(
        backgroundColor: kPrimary,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
}

// ════════════════════════════════════════════════════════════════
//  LOGIN
// ════════════════════════════════════════════════════════════════

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);
  @override State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _eCtrl = TextEditingController();
  final _pCtrl = TextEditingController();
  bool _obs     = true;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [kPrimary, kLight],
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              elevation: 16,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Image.asset('assets/logo.png', height: 130),
                  const SizedBox(height: 12),
                  const Text('Bienvenido',
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: kPrimary)),
                  const SizedBox(height: 4),
                  const Text('Inicia sesion para continuar',
                      style: TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 24),
                  _tf(_eCtrl, 'Correo electronico', Icons.email_outlined),
                  const SizedBox(height: 14),
                  _tfObs(_pCtrl, 'Contrasena', _obs, () => setState(() => _obs = !_obs)),
                  const SizedBox(height: 22),
                  _loading
                      ? const CircularProgressIndicator(color: kPrimary)
                      : _priBtn('Iniciar sesion', () async {
                          if (_eCtrl.text.isEmpty || _pCtrl.text.isEmpty) {
                            _snack(context, 'Completa todos los campos');
                            return;
                          }
                          setState(() => _loading = true);
                          final app = Provider.of<AppProvider>(context, listen: false);
                          final err = await app.login(
                              _eCtrl.text.trim(), _pCtrl.text.trim());
                          if (!context.mounted) return;
                          setState(() => _loading = false);
                          if (err == null) {
                            Navigator.pushReplacement(context,
                                MaterialPageRoute(builder: (_) => const HomeScreen()));
                          } else {
                            _snack(context, err);
                          }
                        }),
                  const SizedBox(height: 10),
                  _outBtn('Crear cuenta', () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const RegisterScreen()))),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  REGISTER
// ════════════════════════════════════════════════════════════════

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);
  @override State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nCtrl = TextEditingController();
  final _eCtrl = TextEditingController();
  final _pCtrl = TextEditingController();
  final _fCtrl = TextEditingController();
  final _gCtrl = TextEditingController();
  final _tCtrl = TextEditingController();
  final _dCtrl = TextEditingController();
  bool _obs     = true;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [kPrimary, kLight],
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              elevation: 16,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Image.asset('assets/logo.png', height: 100),
                  const SizedBox(height: 10),
                  const Text('Crear cuenta',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kPrimary)),
                  const SizedBox(height: 20),
                  _tf(_nCtrl, 'Nombre completo *',     Icons.person_outline),   const SizedBox(height: 10),
                  _tf(_eCtrl, 'Correo electronico *',  Icons.email_outlined),   const SizedBox(height: 10),
                  _tfObs(_pCtrl, 'Contrasena *', _obs, () => setState(() => _obs = !_obs)),
                  const SizedBox(height: 10),
                  _tf(_tCtrl, 'Telefono',              Icons.phone_outlined),   const SizedBox(height: 10),
                  _tf(_dCtrl, 'Direccion',             Icons.home_outlined),    const SizedBox(height: 10),
                  _tf(_fCtrl, 'Fecha de nacimiento',   Icons.cake_outlined),    const SizedBox(height: 10),
                  _tf(_gCtrl, 'Genero',                Icons.person_outline),   const SizedBox(height: 22),
                  _loading
                      ? const CircularProgressIndicator(color: kPrimary)
                      : _priBtn('Registrarme', () async {
                          if ([_nCtrl, _eCtrl, _pCtrl].any((c) => c.text.isEmpty)) {
                            _snack(context, 'Nombre, correo y contrasena son obligatorios');
                            return;
                          }
                          setState(() => _loading = true);
                          final app = Provider.of<AppProvider>(context, listen: false);
                          final err = await app.registrar(
                            email: _eCtrl.text.trim(),
                            password: _pCtrl.text.trim(),
                            nombre: _nCtrl.text.trim(),
                            tel: _tCtrl.text, dir: _dCtrl.text,
                            nac: _fCtrl.text, gen: _gCtrl.text,
                          );
                          if (!context.mounted) return;
                          setState(() => _loading = false);
                          if (err == null) {
                            Navigator.pushReplacement(context,
                                MaterialPageRoute(builder: (_) => const HomeScreen()));
                          } else {
                            _snack(context, err);
                          }
                        }),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Ya tengo cuenta, iniciar sesion',
                        style: TextStyle(color: kPrimary)),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  PANTALLA DE NOTIFICACIONES
// ════════════════════════════════════════════════════════════════

class NotificacionesScreen extends StatelessWidget {
  const NotificacionesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final app = Provider.of<AppProvider>(context);
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        title: const Text('Notificaciones'),
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        actions: [
          if (app.notificaciones.isNotEmpty)
            TextButton(
              onPressed: app.marcarTodasLeidas,
              child: const Text('Marcar todas',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
            ),
        ],
      ),
      body: app.notificaciones.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                        color: kPrimary.withOpacity(0.08),
                        shape: BoxShape.circle),
                    child: const Icon(Icons.notifications_none,
                        color: kPrimary, size: 48),
                  ),
                  const SizedBox(height: 16),
                  const Text('Sin notificaciones',
                      style: TextStyle(fontSize: 16,
                          fontWeight: FontWeight.bold, color: Colors.black54)),
                  const SizedBox(height: 6),
                  Text('Aquí aparecerán recordatorios de citas y vacunas',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                      textAlign: TextAlign.center),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: app.notificaciones.length,
              itemBuilder: (_, i) {
                final n = app.notificaciones[i];
                final esCita = n.tipo == 'cita';
                return GestureDetector(
                  onTap: () => app.marcarLeida(n.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: n.leida ? Colors.white : const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: n.leida
                            ? Colors.grey.shade200
                            : kPrimary.withOpacity(0.3),
                      ),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8, offset: const Offset(0, 3))
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: esCita
                                ? kPrimary.withOpacity(0.12)
                                : const Color(0xFFEDE7F6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            esCita ? Icons.event : Icons.vaccines,
                            color: esCita ? kPrimary : const Color(0xFF7B1FA2),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Row(children: [
                              Expanded(
                                child: Text(n.titulo,
                                    style: TextStyle(
                                        fontWeight: n.leida
                                            ? FontWeight.w500
                                            : FontWeight.bold,
                                        fontSize: 13,
                                        color: Colors.black87)),
                              ),
                              if (!n.leida)
                                Container(
                                  width: 8, height: 8,
                                  decoration: const BoxDecoration(
                                      color: kPrimary, shape: BoxShape.circle),
                                ),
                            ]),
                            const SizedBox(height: 3),
                            Text(n.cuerpo,
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey.shade600)),
                            const SizedBox(height: 4),
                            Text(
                              '${n.fecha.day}/${n.fecha.month}/${n.fecha.year}  '
                              '${n.fecha.hour.toString().padLeft(2, '0')}:'
                              '${n.fecha.minute.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                  fontSize: 10, color: Colors.grey.shade400),
                            ),
                          ]),
                        ),
                      ]),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  HOME  (navegacion principal)
// ════════════════════════════════════════════════════════════════

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);
  @override State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  // -- cita --
  DateTime _fechaCita  = DateTime.now();
  String   _horaCita   = '';
  String?  _motivo, _veterinario, _mascotaCitaId;

  // -- mascota --
  final _mNom = TextEditingController();
  final _mRaz = TextEditingController();
  final _mEda = TextEditingController();
  final _mPes = TextEditingController();
  final _mCol = TextEditingController();
  final _mMic = TextEditingController();
  String _mEsp = 'Perro';
  String _mSex = 'Macho';
  File?  _mFoto;

  // -- tips --
  int _tipIdx = 0;
  final _picker = ImagePicker();

  static const _horarios = [
    '09:00','09:30','10:00','10:30','11:00','11:30',
    '15:00','15:30','16:00','16:30',
  ];
  static const _motivos = [
    'Consulta General','Vacunacion','Desparasitacion',
    'Cirugia','Emergencia','Bano y Grooming',
  ];
  static const _especies = ['Perro','Gato','Conejo','Ave','Reptil','Otro'];
  static const _sexos    = ['Macho','Hembra'];
  static const _tips = [
    {'icon': Icons.water_drop,      'color': kAccent,
     'texto': 'Asegurate de que tu mascota tenga agua fresca disponible todo el dia.'},
    {'icon': Icons.directions_walk, 'color': Color(0xFF66BB6A),
     'texto': 'Los perros necesitan al menos 30 minutos de ejercicio diario.'},
    {'icon': Icons.vaccines,        'color': Color(0xFFAB47BC),
     'texto': 'Mantener las vacunas al dia es la mejor forma de proteger a tu mascota.'},
    {'icon': Icons.brush,           'color': Color(0xFFFFA726),
     'texto': 'Cepilla a tu mascota regularmente para revisar su piel y pelaje.'},
    {'icon': Icons.favorite,        'color': Color(0xFFEF5350),
     'texto': 'El tiempo de calidad con tu mascota fortalece el vinculo entre ustedes.'},
    {'icon': Icons.restaurant,      'color': Color(0xFF26A69A),
     'texto': 'Evita darle comida humana a tu mascota. Algunos alimentos son toxicos.'},
  ];

  @override
  void dispose() {
    for (final c in [_mNom,_mRaz,_mEda,_mPes,_mCol,_mMic]) { c.dispose(); }
    super.dispose();
  }

  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final app = Provider.of<AppProvider>(context);
    final u = app.usuarioActual;
    final h = DateTime.now().hour;
    final saludo = h < 12 ? 'Buenos días' : h < 18 ? 'Buenas tardes' : 'Buenas noches';
    final noLeidas = app.notificacionesNoLeidas;

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kPrimary,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            // Avatar / foto de perfil — abre el perfil
            GestureDetector(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => PerfilScreen(app: app))),
              child: Row(children: [
                // Avatar
                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    color: Colors.white.withOpacity(0.2),
                    image: u?.foto != null
                        ? DecorationImage(
                            image: u!.foto!.startsWith('http')
                                ? NetworkImage(u.foto!) as ImageProvider
                                : FileImage(File(u.foto!)),
                            fit: BoxFit.cover)
                        : null,
                  ),
                  child: u?.foto == null
                      ? const Icon(Icons.person, color: Colors.white, size: 20)
                      : null,
                ),
                const SizedBox(width: 10),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(saludo,
                      style: const TextStyle(
                          fontSize: 10, color: Colors.white70,
                          fontWeight: FontWeight.normal)),
                  Text(
                    u?.nombre.split(' ').first ?? 'Usuario',
                    style: const TextStyle(
                        fontSize: 14, color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                ]),
              ]),
            ),
          ],
        ),
        actions: [
          // Botón notificaciones con badge
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 26),
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const NotificacionesScreen())),
              ),
              if (noLeidas > 0)
                Positioned(
                  right: 8, top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                        color: Colors.red, shape: BoxShape.circle),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      noLeidas > 9 ? '9+' : '$noLeidas',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 9,
                          fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: IndexedStack(index: _tab, children: [
        _tabInicio(app),
        _tabCitas(app),
        _tabMascotas(app),
      ]),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        backgroundColor: kPrimary,
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => PasosScreen(app: app))),
        child: const Icon(Icons.directions_walk, color: Colors.white, size: 26),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8, color: Colors.white, elevation: 12,
        child: SizedBox(
          height: 60,
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _nav(Icons.home_rounded,   'Inicio',   0),
            _nav(Icons.calendar_month, 'Citas',    1),
            const SizedBox(width: 48),
            _nav(Icons.pets_rounded,   'Mascotas', 2),
            // Tab expediente
            GestureDetector(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => ExpedienteScreen(app: app))),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.folder_shared_outlined, color: Colors.grey.shade400, size: 24),
                const SizedBox(height: 2),
                Text('Expediente',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _nav(IconData icon, String label, int idx) {
    final sel = _tab == idx;
    return GestureDetector(
      onTap: () => setState(() => _tab = idx),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: sel ? kPrimary : Colors.grey.shade400, size: 24),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(
            fontSize: 10, color: sel ? kPrimary : Colors.grey.shade400,
            fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
      ]),
    );
  }

  // ════════════════ TAB INICIO ════════════════════

  Widget _tabInicio(AppProvider app) {
    final todas   = app.citasDeUsuario(app.usuarioActual!.id);
    final ahora   = DateTime.now();
    final futuras = todas.where((c) => c.fecha.isAfter(ahora)).toList()
      ..sort((a, b) => a.fecha.compareTo(b.fecha));
    final proxima = futuras.isNotEmpty ? futuras.first : null;
    final vacProx = app.vacunas.where((v) {
      if (v.proxima == null) return false;
      final d = v.proxima!.difference(ahora).inDays;
      return d >= 0 && d <= 30;
    }).toList();
    final tip = _tips[_tipIdx % _tips.length];

    return SingleChildScrollView(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // HEADER stats
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          decoration: const BoxDecoration(
            color: kPrimary,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Clínica Veterinaria',
                style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 14),
            Row(children: [
              _stat(Icons.calendar_today, '${todas.length}',       'Citas'),
              const SizedBox(width: 10),
              _stat(Icons.pets,           '${app.mascotas.length}','Mascotas'),
              const SizedBox(width: 10),
              _stat(Icons.vaccines,       '${app.vacunas.length}', 'Vacunas'),
            ]),
          ]),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            _secTitle('Próxima Cita'),
            const SizedBox(height: 10),
            proxima == null
                ? _emptyBox(Icons.event_available, 'Sin citas próximas',
                    'Agenda una cita desde la pestaña Citas')
                : _proxCard(app, proxima),

            if (todas.length > 1) ...[
              const SizedBox(height: 24),
              _secTitle('Todas mis citas'),
              const SizedBox(height: 10),
              SizedBox(
                height: 148,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: todas.length,
                  itemBuilder: (_, i) => _citaMiniCard(app, todas[i]),
                ),
              ),
            ],

            const SizedBox(height: 24),
            _secTitle('Mis Mascotas'),
            const SizedBox(height: 10),
            app.mascotas.isEmpty
                ? _emptyBox(Icons.pets, 'Sin mascotas',
                    'Agrega tu primera mascota en la pestaña Mascotas')
                : SizedBox(
                    height: 92,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: app.mascotas.length,
                      itemBuilder: (_, i) {
                        final m = app.mascotas[i];
                        final cols = [
                          const Color(0xFFBBDEFB), const Color(0xFFFFE0B2),
                          const Color(0xFFE1BEE7), const Color(0xFFB2EBF2),
                        ];
                        return Container(
                          margin: const EdgeInsets.only(right: 14),
                          child: Column(children: [
                            Container(
                              width: 60, height: 60,
                              decoration: BoxDecoration(
                                color: cols[i % cols.length],
                                shape: BoxShape.circle,
                                image: m.foto != null
                                    ? DecorationImage(
                                        image: m.foto!.startsWith('http')
                                            ? NetworkImage(m.foto!) as ImageProvider
                                            : FileImage(File(m.foto!)),
                                        fit: BoxFit.cover)
                                    : null,
                              ),
                              child: m.foto == null
                                  ? const Icon(Icons.pets, color: kPrimary, size: 26)
                                  : null,
                            ),
                            const SizedBox(height: 6),
                            Text(m.nombre,
                                style: const TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.w600)),
                          ]),
                        );
                      },
                    ),
                  ),

            if (vacProx.isNotEmpty) ...[
              const SizedBox(height: 24),
              _secTitle('Recordatorio de Vacunas'),
              const SizedBox(height: 10),
              ...vacProx.map((v) {
                final mNom = app.mascotas
                    .where((m) => m.id == v.mascotaId)
                    .map((m) => m.nombre)
                    .firstOrNull ?? '';
                final dias = v.proxima!.difference(ahora).inDays;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: _cardDeco(),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: const Color(0xFFEDE7F6),
                          borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.vaccines,
                          color: Color(0xFF7B1FA2), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(v.nombre,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(mNom,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600)),
                    ])),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: dias <= 7
                            ? Colors.red.shade400
                            : Colors.orange.shade400,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(dias == 0 ? 'Hoy' : 'en $dias dias',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 11,
                              fontWeight: FontWeight.bold)),
                    ),
                  ]),
                );
              }),
            ],

            const SizedBox(height: 24),
            _secTitle('Consejo del día'),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => setState(() => _tipIdx++),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: _cardDeco(),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (tip['color'] as Color).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(tip['icon'] as IconData,
                        color: tip['color'] as Color, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(tip['texto'] as String,
                        style: const TextStyle(
                            fontSize: 13, height: 1.45, color: Colors.black87)),
                    const SizedBox(height: 6),
                    Text('Toca para ver otro consejo',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade400)),
                  ])),
                ]),
              ),
            ),

            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => VacunasScreen(app: app))),
              child: Container(
                width: double.infinity, padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6A1B9A), Color(0xFFAB47BC)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [BoxShadow(color: const Color(0xFF6A1B9A).withOpacity(0.3),
                      blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.vaccines, color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Registro de Vacunas',
                        style: TextStyle(color: Colors.white,
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    SizedBox(height: 2),
                    Text('Ver y registrar vacunas de todas tus mascotas',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ])),
                  const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
                ]),
              ),
            ),

            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => ExpedienteScreen(app: app))),
              child: Container(
                width: double.infinity, padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1B5E20), Color(0xFF43A047)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [BoxShadow(
                      color: const Color(0xFF1B5E20).withOpacity(0.3),
                      blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.folder_shared, color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Expediente Clínico',
                        style: TextStyle(color: Colors.white,
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    SizedBox(height: 2),
                    Text('Ver y descargar historial completo en PDF',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ])),
                  const Icon(Icons.arrow_forward_ios,
                      color: Colors.white70, size: 16),
                ]),
              ),
            ),
            const SizedBox(height: 10),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              crossAxisSpacing: 10, mainAxisSpacing: 10,
              childAspectRatio: 1.0,
              children: const [
                _ServTile(Icons.medical_services,'Consulta',   Color(0xFF42A5F5)),
                _ServTile(Icons.vaccines,         'Vacunacion', Color(0xFF66BB6A)),
                _ServTile(Icons.cut,              'Grooming',   Color(0xFFFFA726)),
                _ServTile(Icons.science,          'Laboratorio',Color(0xFFAB47BC)),
                _ServTile(Icons.emergency,        'Emergencias',Color(0xFFEF5350)),
                _ServTile(Icons.local_pharmacy,   'Farmacia',   Color(0xFF26A69A)),
              ],
            ),

            const SizedBox(height: 24),
            _secTitle('Contactar Clínica'),
            const SizedBox(height: 10),
            _contactCard(),
            const SizedBox(height: 30),
          ]),
        ),
      ]),
    );
  }

  Widget _stat(IconData icon, String val, String lbl) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14)),
          child: Column(children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(height: 4),
            Text(val, style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            Text(lbl, style: TextStyle(
                color: Colors.white.withOpacity(0.8), fontSize: 10)),
          ]),
        ),
      );

  Widget _proxCard(AppProvider app, Cita cita) {
    final mNom = app.mascotas.where((m) => m.id == cita.mascotaId)
        .map((m) => m.nombre).firstOrNull ?? 'Mascota';
    final diff  = cita.fecha.difference(DateTime.now());
    final dias  = diff.inDays;
    final horas = diff.inHours % 24;
    final cuenta = dias > 0 ? 'en $dias dia${dias == 1 ? '' : 's'}'
        : horas > 0 ? 'en $horas hora${horas == 1 ? '' : 's'}' : 'Hoy';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [kPrimary, kAccent]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(
            color: kPrimary.withOpacity(0.3), blurRadius: 12,
            offset: const Offset(0, 5))],
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16)),
          child: const Icon(Icons.event, color: Colors.white, size: 28),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(cita.servicio, style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 3),
          Text('$mNom  -  ${cita.veterinario.split(' ').take(2).join(' ')}',
              style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12)),
          const SizedBox(height: 3),
          Text('${cita.fecha.day}/${cita.fecha.month}/${cita.fecha.year}  '
              '${cita.fecha.hour.toString().padLeft(2, '0')}:'
              '${cita.fecha.minute.toString().padLeft(2, '0')}',
              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
        ])),
        Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(20)),
            child: Text(cuenta, style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _generarPDF(cita, app),
            child: const Text('Ver PDF', style: TextStyle(
                color: Colors.white70, fontSize: 11,
                decoration: TextDecoration.underline)),
          ),
        ]),
      ]),
    );
  }

  Widget _citaMiniCard(AppProvider app, Cita cita) {
    final mNom = app.mascotas.where((m) => m.id == cita.mascotaId)
        .map((m) => m.nombre).firstOrNull ?? 'Mascota';
    return Container(
      width: 200, margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(14),
      decoration: _cardDeco(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(child: Text(cita.servicio,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              overflow: TextOverflow.ellipsis)),
          GestureDetector(
            onTap: () async {
              final confirmar = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  title: const Text('Cancelar cita'),
                  content: const Text('¿Seguro que deseas cancelar esta cita?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('No')),
                    TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Sí, cancelar',
                            style: TextStyle(color: Colors.red))),
                  ],
                ),
              );
              if (confirmar == true) await app.cancelarCita(cita.id);
            },
            child: const Icon(Icons.close, color: Colors.red, size: 18),
          ),
        ]),
        const SizedBox(height: 5),
        _rowInfo(Icons.pets,           mNom),
        _rowInfo(Icons.person_outline, cita.veterinario.split(' ').take(2).join(' ')),
        _rowInfo(Icons.calendar_today,
            '${cita.fecha.day}/${cita.fecha.month}/${cita.fecha.year}'),
        const Spacer(),
        GestureDetector(
          onTap: () => _generarPDF(cita, app),
          child: Row(children: [
            const Icon(Icons.picture_as_pdf, size: 13, color: kAccent),
            const SizedBox(width: 4),
            const Text('Comprobante', style: TextStyle(
                fontSize: 11, color: kAccent,
                decoration: TextDecoration.underline)),
          ]),
        ),
      ]),
    );
  }

  Widget _rowInfo(IconData icon, String txt) => Padding(
        padding: const EdgeInsets.only(bottom: 3),
        child: Row(children: [
          Icon(icon, size: 12, color: Colors.grey),
          const SizedBox(width: 4),
          Expanded(child: Text(txt,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              overflow: TextOverflow.ellipsis)),
        ]),
      );

  Widget _emptyBox(IconData icon, String title, String sub) =>
      Container(
        width: double.infinity, padding: const EdgeInsets.all(18),
        decoration: _cardDeco(),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: kPrimary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: kPrimary, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 3),
            Text(sub, style: TextStyle(
                fontSize: 12, color: Colors.grey.shade500)),
          ])),
        ]),
      );

  // ════════════════ TAB CITAS ══════════════════════

  Widget _tabCitas(AppProvider app) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _secTitle('Agendar Cita'),
        const SizedBox(height: 16),

        _drop<String>(
          value: _mascotaCitaId, label: 'Mascota',
          icon: Icons.pets,
          items: app.mascotas.map((m) =>
              DropdownMenuItem(value: m.id, child: Text(m.nombre))).toList(),
          onChanged: (v) => setState(() => _mascotaCitaId = v),
        ),
        const SizedBox(height: 12),
        _drop<String>(
          value: _motivo, label: 'Motivo de la cita',
          icon: Icons.medical_services_outlined,
          items: _motivos.map((m) =>
              DropdownMenuItem(value: m, child: Text(m))).toList(),
          onChanged: (v) => setState(() => _motivo = v),
        ),
        const SizedBox(height: 12),
        app.veterinarios.isEmpty
            ? Container(
                padding: const EdgeInsets.all(14),
                decoration: _cardDeco(),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(children: [
                      SizedBox(width: 16, height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: kPrimary)),
                      SizedBox(width: 10),
                      Text('Cargando veterinarios...',
                          style: TextStyle(color: Colors.grey, fontSize: 13)),
                    ]),
                    TextButton(
                      onPressed: () => app.cargarVeterinarios(),
                      child: const Text('Reintentar',
                          style: TextStyle(color: kPrimary, fontSize: 12)),
                    ),
                  ],
                ),
              )
            : _drop<String>(
                value: _veterinario,
                label: 'Veterinario',
                icon: Icons.person_outline,
                items: app.veterinarios.map((v) => DropdownMenuItem(
                  value: v.nombre,
                  child: Text(
                    v.especialidad != null
                        ? '${v.nombre} · ${v.especialidad}'
                        : v.nombre,
                    style: const TextStyle(fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                )).toList(),
                onChanged: (v) => setState(() {
                  _veterinario = v;
                  _horaCita = '';
                }),
              ),
        const SizedBox(height: 20),
        _secTitle('Fecha'),
        const SizedBox(height: 8),
        Container(
          decoration: _cardDeco(),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: CalendarDatePicker(
              initialDate: _fechaCita, firstDate: DateTime.now(),
              lastDate: DateTime(2030),
              onDateChanged: (d) => setState(() {
                _fechaCita = d; _horaCita = '';
              }),
            ),
          ),
        ),
        const SizedBox(height: 20),

        _secTitle('Horario disponible'),
        const SizedBox(height: 10),
        if (_veterinario == null)
          Container(
            padding: const EdgeInsets.all(14), decoration: _cardDeco(),
            child: const Row(children: [
              Icon(Icons.info_outline, color: Colors.grey, size: 18),
              SizedBox(width: 8),
              Text('Selecciona un veterinario para ver horarios',
                  style: TextStyle(color: Colors.grey, fontSize: 13)),
            ]),
          )
        else
          GridView.builder(
            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            itemCount: _horarios.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4, crossAxisSpacing: 8,
                mainAxisSpacing: 8, childAspectRatio: 2.2),
            itemBuilder: (_, i) {
              final hora   = _horarios[i];
              final partes = hora.split(':');
              final hh = int.tryParse(partes[0]) ?? 0;
              final mm = int.tryParse(partes[1]) ?? 0;
              final fh = DateTime(_fechaCita.year, _fechaCita.month,
                  _fechaCita.day, hh, mm);
              final ocupado = app.horarioOcupado(fh, _veterinario!);
              final sel = hora == _horaCita;

              return GestureDetector(
                onTap: ocupado ? null : () => setState(() => _horaCita = hora),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: ocupado ? Colors.red.shade50
                        : sel ? kPrimary : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: ocupado ? Colors.red.shade200
                          : sel ? kPrimary : Colors.grey.shade200,
                    ),
                    boxShadow: sel
                        ? [BoxShadow(color: kPrimary.withOpacity(0.3),
                            blurRadius: 6, offset: const Offset(0, 2))]
                        : null,
                  ),
                  child: Text(hora, style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600,
                      color: ocupado ? Colors.red.shade300
                          : sel ? Colors.white : Colors.black87)),
                ),
              );
            },
          ),
        const SizedBox(height: 8),
        Row(children: [
          _dot(Colors.red.shade50,   Colors.red.shade200, 'Ocupado'),
          const SizedBox(width: 14),
          _dot(kPrimary, kPrimary, 'Seleccionado'),
        ]),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity, height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: (_mascotaCitaId != null && _motivo != null &&
                  _veterinario != null && _horaCita.isNotEmpty)
                  ? kPrimary : Colors.grey.shade300,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            onPressed: (_mascotaCitaId == null || _motivo == null ||
                _veterinario == null || _horaCita.isEmpty)
                ? null
                : () async {
                    final pp = _horaCita.split(':');
                    final hh = int.tryParse(pp[0]) ?? 0;
                    final mm = int.tryParse(pp[1]) ?? 0;
                    final fc = DateTime(_fechaCita.year, _fechaCita.month,
                        _fechaCita.day, hh, mm);
                    if (app.horarioOcupado(fc, _veterinario!)) {
                      _snack(context, 'Ese horario ya está ocupado');
                      return;
                    }
                    await app.agregarCita(Cita(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      clienteId: app.usuarioActual!.id,
                      mascotaId: _mascotaCitaId!,
                      fecha: fc,
                      veterinario: _veterinario!,
                      servicio: _motivo!,
                    ));
                    if (!context.mounted) return;
                    _snack(context, 'Cita agendada correctamente');
                    setState(() {
                      _horaCita = ''; _motivo = null;
                      _mascotaCitaId = null; _veterinario = null;
                    });
                  },
            child: Text('Confirmar Cita',
                style: TextStyle(
                    fontSize: 16,
                    color: (_mascotaCitaId != null && _motivo != null &&
                        _veterinario != null && _horaCita.isNotEmpty)
                        ? Colors.white : Colors.grey.shade500,
                    fontWeight: FontWeight.bold)),
          ),
        ),

        const SizedBox(height: 32),
        _secTitle('Mis Citas'),
        const SizedBox(height: 10),
        app.citas.isEmpty
            ? _emptyBox(Icons.calendar_today, 'Sin citas registradas',
                'Agenda tu primera cita con el formulario de arriba')
            : Column(
                children: app.citas.map((cita) {
                  final mNom = app.mascotas
                      .where((m) => m.id == cita.mascotaId)
                      .map((m) => m.nombre)
                      .firstOrNull ?? 'Mascota';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: _cardDeco(),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: kPrimary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.event, color: kPrimary, size: 22),
                      ),
                      title: Text(cita.servicio,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        const SizedBox(height: 3),
                        Text(mNom,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600)),
                        Text(cita.veterinario.split(' ').take(2).join(' '),
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600)),
                        Text(
                          '${cita.fecha.day}/${cita.fecha.month}/${cita.fecha.year}'
                          '  ${cita.fecha.hour.toString().padLeft(2, '0')}:'
                          '${cita.fecha.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade500),
                        ),
                      ]),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        IconButton(
                          icon: const Icon(Icons.picture_as_pdf,
                              color: kAccent, size: 22),
                          onPressed: () => _generarPDF(cita, app),
                          tooltip: 'Comprobante',
                        ),
                        IconButton(
                          icon: const Icon(Icons.cancel_outlined,
                              color: Colors.red, size: 22),
                          tooltip: 'Cancelar cita',
                          onPressed: () async {
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20)),
                                title: const Text('Cancelar cita'),
                                content: Text(
                                    '¿Seguro que deseas cancelar la cita de ${cita.servicio}?'),
                                actions: [
                                  TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('No')),
                                  TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text('Sí, cancelar',
                                          style: TextStyle(
                                              color: Colors.red))),
                                ],
                              ),
                            );
                            if (ok == true) await app.cancelarCita(cita.id);
                          },
                        ),
                      ]),
                    ),
                  );
                }).toList(),
              ),
        const SizedBox(height: 24),
      ]),
    );
  }

  // ════════════════ TAB MASCOTAS ════════════════════

  Widget _tabMascotas(AppProvider app) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(18), decoration: _cardDeco(),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _secTitle('Registrar Mascota'),
            const SizedBox(height: 16),

            Center(
              child: GestureDetector(
                onTap: () async {
                  final f = await _picker.pickImage(source: ImageSource.gallery);
                  if (f != null) setState(() => _mFoto = File(f.path));
                },
                child: Stack(children: [
                  CircleAvatar(
                    radius: 48, backgroundColor: Colors.grey.shade200,
                    backgroundImage: _mFoto != null ? FileImage(_mFoto!) : null,
                    child: _mFoto == null
                        ? const Icon(Icons.camera_alt, size: 32, color: Colors.grey)
                        : null,
                  ),
                  Positioned(bottom: 0, right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                          color: kPrimary, shape: BoxShape.circle),
                      child: const Icon(Icons.edit, size: 14, color: Colors.white),
                    ),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 4),
            const Center(child: Text('Foto de la mascota',
                style: TextStyle(color: Colors.grey, fontSize: 12))),
            const SizedBox(height: 16),

            _tf(_mNom, 'Nombre *',  Icons.pets),
            const SizedBox(height: 10),

            Row(children: [
              Expanded(child: _dropInline<String>(
                value: _mEsp, label: 'Especie',
                items: _especies.map((e) =>
                    DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => _mEsp = v ?? 'Perro'),
              )),
              const SizedBox(width: 10),
              Expanded(child: _dropInline<String>(
                value: _mSex, label: 'Sexo',
                items: _sexos.map((s) =>
                    DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) => setState(() => _mSex = v ?? 'Macho'),
              )),
            ]),
            const SizedBox(height: 10),
            _tf(_mRaz, 'Raza',          Icons.info_outline),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _tf(_mEda, 'Edad',     Icons.cake_outlined)),
              const SizedBox(width: 10),
              Expanded(child: _tf(_mPes, 'Peso (kg)', Icons.monitor_weight_outlined)),
            ]),
            const SizedBox(height: 10),
            _tf(_mCol, 'Color',          Icons.palette_outlined),
            const SizedBox(height: 10),
            _tf(_mMic, 'Microchip (opcional)', Icons.qr_code_outlined),
            const SizedBox(height: 18),

            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14))),
                onPressed: () {
                  if (_mNom.text.isEmpty) {
                    _snack(context, 'El nombre es obligatorio');
                    return;
                  }
                  app.agregarMascota(Mascota(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    nombre: _mNom.text, especie: _mEsp, raza: _mRaz.text,
                    edad: _mEda.text, peso: _mPes.text, sexo: _mSex,
                    color: _mCol.text, microchip: _mMic.text.isEmpty ? null : _mMic.text,
                    foto: _mFoto?.path,
                  ));
                  for (final c in [_mNom,_mRaz,_mEda,_mPes,_mCol,_mMic]) { c.clear(); }
                  setState(() { _mFoto = null; _mEsp = 'Perro'; _mSex = 'Macho'; });
                  _snack(context, 'Mascota registrada');
                },
                child: const Text('Guardar Mascota',
                    style: TextStyle(fontSize: 15, color: Colors.white,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ]),
        ),

        const SizedBox(height: 24),
        _secTitle('Mis Mascotas'),
        const SizedBox(height: 10),
        app.mascotas.isEmpty
            ? _emptyBox(Icons.pets, 'Sin mascotas registradas',
                'Completa el formulario de arriba')
            : Column(children: app.mascotas.map((m) => _mascotaCard(app, m)).toList()),
      ]),
    );
  }

  Widget _mascotaCard(AppProvider app, Mascota m) => Card(
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 10),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200)),
        color: Colors.white,
        child: ExpansionTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          leading: CircleAvatar(
            backgroundColor: const Color(0xFFE3F2FD),
            backgroundImage: m.foto != null
                ? (m.foto!.startsWith('http')
                    ? NetworkImage(m.foto!) as ImageProvider
                    : FileImage(File(m.foto!)))
                : null,
            child: m.foto == null
                ? const Icon(Icons.pets, color: kPrimary, size: 22) : null,
          ),
          title: Text(m.nombre,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('${m.especie}  -  ${m.raza}  -  ${m.sexo}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: kPrimary, size: 20),
              onPressed: () => _dlgEditarMascota(app, m),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
              onPressed: () => _dlgEliminar(app, m),
            ),
          ]),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Divider(),
                Wrap(spacing: 10, runSpacing: 6, children: [
                  _chipInfo('Edad: ${m.edad}'),
                  _chipInfo('Peso: ${m.peso} kg'),
                  _chipInfo('Color: ${m.color}'),
                  if (m.microchip != null && m.microchip!.isNotEmpty)
                    _chipInfo('Chip: ${m.microchip}'),
                ]),
                const SizedBox(height: 12),
                const Divider(),

                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Historial Médico',
                      style: TextStyle(fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700, fontSize: 13)),
                  TextButton(
                    onPressed: () => _dlgVisita(app, m.id),
                    child: const Text('+ Agregar'),
                  ),
                ]),
                ...app.visitasDe(m.id).map((v) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: const Color(0xFFE3F2FD),
                          borderRadius: BorderRadius.circular(12)),
                      child: Row(children: [
                        const Icon(Icons.local_hospital, color: kPrimary, size: 18),
                        const SizedBox(width: 10),
                        Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(v.diagnostico,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13)),
                          Text('${v.tratamiento}  -  '
                              '${v.fecha.day}/${v.fecha.month}/${v.fecha.year}  '
                              '-  ${v.veterinario.split(' ').take(2).join(' ')}',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey.shade600)),
                        ])),
                      ]),
                    )),
                if (app.visitasDe(m.id).isEmpty)
                  Text('Sin visitas registradas',
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),

                const SizedBox(height: 10),
                const Divider(),

                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Vacunas',
                      style: TextStyle(fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700, fontSize: 13)),
                  TextButton(
                    onPressed: () => _dlgVacuna(app, m.id),
                    child: const Text('+ Agregar'),
                  ),
                ]),
                ...app.vacunasDe(m.id).map((v) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: const Color(0xFFEDE7F6),
                          borderRadius: BorderRadius.circular(12)),
                      child: Row(children: [
                        const Icon(Icons.vaccines,
                            color: Color(0xFF7B1FA2), size: 18),
                        const SizedBox(width: 10),
                        Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(v.nombre,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13)),
                          Text(
                            'Aplicada: ${v.fecha.day}/${v.fecha.month}/${v.fecha.year}'
                            '${v.proxima != null ? '   Próxima: ${v.proxima!.day}/${v.proxima!.month}/${v.proxima!.year}' : ''}',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade600),
                          ),
                        ])),
                      ]),
                    )),
                if (app.vacunasDe(m.id).isEmpty)
                  Text('Sin vacunas registradas',
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
              ]),
            ),
          ],
        ),
      );

  Widget _chipInfo(String txt) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
            color: kPrimary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20)),
        child: Text(txt, style: const TextStyle(fontSize: 11, color: kPrimary)),
      );

  // ═════ Diálogos mascotas ═════════════════════════

  void _dlgEditarMascota(AppProvider app, Mascota m) {
    final nc = TextEditingController(text: m.nombre);
    final rc = TextEditingController(text: m.raza);
    final ec = TextEditingController(text: m.edad);
    final pc = TextEditingController(text: m.peso);
    final cc = TextEditingController(text: m.color);
    final mc = TextEditingController(text: m.microchip ?? '');
    String esp = m.especie, sex = m.sexo;
    File? foto;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Editar ${m.nombre}'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              GestureDetector(
                onTap: () async {
                  final f = await _picker.pickImage(source: ImageSource.gallery);
                  if (f != null) setSt(() => foto = File(f.path));
                },
                child: CircleAvatar(
                  radius: 40, backgroundColor: Colors.grey.shade200,
                  backgroundImage: foto != null ? FileImage(foto!)
                      : m.foto != null ? FileImage(File(m.foto!)) : null,
                  child: (foto == null && m.foto == null)
                      ? const Icon(Icons.camera_alt, color: Colors.grey) : null,
                ),
              ),
              const SizedBox(height: 12),
              _tf(nc, 'Nombre', Icons.pets),              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: _dropInline<String>(
                  value: esp, label: 'Especie',
                  items: _especies.map((e) =>
                      DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) => setSt(() => esp = v ?? esp),
                )),
                const SizedBox(width: 8),
                Expanded(child: _dropInline<String>(
                  value: sex, label: 'Sexo',
                  items: _sexos.map((s) =>
                      DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) => setSt(() => sex = v ?? sex),
                )),
              ]),
              const SizedBox(height: 8),
              _tf(rc, 'Raza',   Icons.info_outline),      const SizedBox(height: 8),
              Row(children: [
                Expanded(child: _tf(ec, 'Edad', Icons.cake_outlined)),
                const SizedBox(width: 8),
                Expanded(child: _tf(pc, 'Peso', Icons.monitor_weight_outlined)),
              ]),
              const SizedBox(height: 8),
              _tf(cc, 'Color',  Icons.palette_outlined),  const SizedBox(height: 8),
              _tf(mc, 'Microchip', Icons.qr_code_outlined),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: kPrimary),
              onPressed: () {
                if (nc.text.isEmpty) return;
                app.editarMascota(m.id, nc.text, esp, rc.text, ec.text,
                    pc.text, sex, cc.text,
                    mc.text.isEmpty ? null : mc.text, foto?.path);
                Navigator.pop(ctx);
                _snack(context, 'Mascota actualizada');
              },
              child: const Text('Guardar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _dlgEliminar(AppProvider app, Mascota m) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Eliminar mascota'),
        content: Text('¿Seguro que deseas eliminar a ${m.nombre}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () { app.eliminarMascota(m.id); Navigator.pop(context); },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _dlgVisita(AppProvider app, String mid) {
    final d = TextEditingController();
    final t = TextEditingController();
    String? v;
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, ss) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Nueva Visita Médica'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              _tf(d, 'Diagnóstico', Icons.medical_information_outlined),
              const SizedBox(height: 10),
              _tf(t, 'Tratamiento', Icons.medication_outlined),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: v,
                decoration: const InputDecoration(
                    labelText: 'Veterinario',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder()),
                items: app.veterinarios.map((x) =>
                    DropdownMenuItem(value: x.nombre, child: Text(x.nombre))).toList(),
                onChanged: (x) => ss(() => v = x),
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: kPrimary),
              onPressed: () async {
                if (d.text.isEmpty || v == null) return;
                await app.agregarVisita(VisitaMedica(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  mascotaId: mid, fecha: DateTime.now(),
                  diagnostico: d.text, tratamiento: t.text, veterinario: v!,
                ));
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                _snack(context, 'Visita registrada');
              },
              child: const Text('Guardar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _dlgVacuna(AppProvider app, String mid) {
    final n = TextEditingController();
    DateTime fApl = DateTime.now();
    DateTime? fPrx;
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, ss) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Nueva Vacuna'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              _tf(n, 'Nombre de la vacuna', Icons.vaccines_outlined),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today, color: kPrimary),
                title: Text(
                  'Fecha de aplicación: ${fApl.day}/${fApl.month}/${fApl.year}',
                  style: const TextStyle(fontSize: 13),
                ),
                onTap: () async {
                  final d = await showDatePicker(context: ctx,
                      initialDate: fApl, firstDate: DateTime(2020),
                      lastDate: DateTime.now());
                  if (d != null) ss(() => fApl = d);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event_repeat, color: Colors.teal),
                title: Text(
                  fPrx == null ? 'Próxima dosis (opcional)'
                      : 'Próxima: ${fPrx!.day}/${fPrx!.month}/${fPrx!.year}',
                  style: const TextStyle(fontSize: 13),
                ),
                onTap: () async {
                  final d = await showDatePicker(context: ctx,
                      initialDate: DateTime.now().add(const Duration(days: 365)),
                      firstDate: DateTime.now(), lastDate: DateTime(2030));
                  if (d != null) ss(() => fPrx = d);
                },
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              onPressed: () async {
                if (n.text.isEmpty) return;
                await app.agregarVacuna(Vacuna(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  mascotaId: mid, nombre: n.text,
                  fecha: fApl, proxima: fPrx,
                ));
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                _snack(context, 'Vacuna registrada');
              },
              child: const Text('Guardar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════ CONTACTO ══════════════════

  Widget _contactCard() => Container(
        decoration: _cardDeco(),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: kPrimary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.local_hospital, color: kPrimary, size: 26),
              ),
              const SizedBox(width: 14),
              const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Clínica Veterinaria',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text('Lunes a Sábado  9:00 - 17:00',
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
              ]),
            ]),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              _cBtn(Icons.phone_outlined,    'Llamar',    Colors.green,
                  () => _launch('tel:6648094202')),
              _cBtn(Icons.chat_outlined,     'WhatsApp',  Colors.teal,
                  () => _launch('https://wa.me/6648094202')),
              _cBtn(Icons.email_outlined,    'Email',     kPrimary,
                  () => _launch('mailto:0324108105@gmail.com')),
              _cBtn(Icons.location_on,       'Mapa',      Colors.orange,
                  () => _launch('https://maps.google.com/?q=Clinica+Veterinaria+Tijuana')),
            ]),
          ]),
        ),
      );

  Widget _cBtn(IconData icon, String label, Color color, VoidCallback fn) =>
      GestureDetector(
        onTap: fn,
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 5),
          Text(label, style: TextStyle(
              fontSize: 10, color: color, fontWeight: FontWeight.w600)),
        ]),
      );

  Future<void> _launch(String url) async {
    final u = Uri.parse(url);
    if (await canLaunchUrl(u)) {
      await launchUrl(u, mode: LaunchMode.externalApplication);
    }
  }

  // ════════════════ PDF ════════════════════════

  Future<void> _generarPDF(Cita cita, AppProvider app) async {
    try {
      final u  = app.usuarioActual;
      final mNom = app.mascotas.where((m) => m.id == cita.mascotaId)
          .map((m) => m.nombre).firstOrNull ?? 'Sin mascota';
      final mascota = app.mascotas.where((m) => m.id == cita.mascotaId)
          .firstOrNull;

      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(36),
          build: (_) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: const PdfColor.fromInt(0xFF1565C0),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                pw.Text('COMPROBANTE DE CITA',
                    style: pw.TextStyle(fontSize: 20,
                        fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                pw.SizedBox(height: 4),
                pw.Text('Verify Booking.co  |  Tel: 664-809-4202',
                    style: pw.TextStyle(fontSize: 11, color: PdfColors.grey300)),
              ]),
            ),
            pw.SizedBox(height: 24),
            _pdfSec('Datos de la Cita'),
            _pdfFila('Servicio',    cita.servicio),
            _pdfFila('Veterinario', cita.veterinario),
            _pdfFila('Fecha',
                '${cita.fecha.day}/${cita.fecha.month}/${cita.fecha.year}'),
            _pdfFila('Hora',
                '${cita.fecha.hour.toString().padLeft(2, '0')}:'
                '${cita.fecha.minute.toString().padLeft(2, '0')}'),
            _pdfFila('Estado', cita.estado),
            pw.SizedBox(height: 16),
            _pdfSec('Datos de la Mascota'),
            _pdfFila('Nombre', mNom),
            if (mascota != null) ...[
              _pdfFila('Especie', mascota.especie),
              _pdfFila('Raza',    mascota.raza),
              _pdfFila('Edad',    mascota.edad),
              _pdfFila('Peso',    '${mascota.peso} kg'),
              if (mascota.microchip != null)
                _pdfFila('Microchip', mascota.microchip!),
            ],
            pw.SizedBox(height: 16),
            if (u != null) ...[
              _pdfSec('Datos del Dueño'),
              _pdfFila('Nombre',   u.nombre),
              _pdfFila('Correo',   u.email),
              if (u.telefono != null && u.telefono!.isNotEmpty)
                _pdfFila('Teléfono', u.telefono!),
              if (u.direccion != null && u.direccion!.isNotEmpty)
                _pdfFila('Dirección', u.direccion!),
            ],
            pw.SizedBox(height: 24),
            pw.Divider(),
            pw.SizedBox(height: 8),
            pw.Text('Este documento es un comprobante oficial de la cita agendada.',
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
          ]),
        ),
      );

      final dir  = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/comprobante_cita_${cita.id.substring(0, 10)}.pdf';
      final file = File(path);
      await file.writeAsBytes(await pdf.save());

      if (!mounted) return;
      _snack(context, 'Comprobante generado');
      await Share.shareXFiles([XFile(path)],
          text: 'Comprobante de cita - Clínica Veterinaria');
    } catch (e) {
      if (!mounted) return;
      _snack(context, 'Error al generar comprobante: $e');
    }
  }

  pw.Widget _pdfSec(String t) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 6),
        child: pw.Text(t,
            style: pw.TextStyle(fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: const PdfColor.fromInt(0xFF1565C0))),
      );

  pw.Widget _pdfFila(String lbl, String val) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 3),
        child: pw.Row(children: [
          pw.SizedBox(width: 110,
              child: pw.Text(lbl,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold,
                      fontSize: 12, color: PdfColors.grey700))),
          pw.Text(val, style: pw.TextStyle(fontSize: 12)),
        ]),
      );

  // ════════════════ WIDGETS HELPERS ════════════════

  Widget _secTitle(String t) => Text(t,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
          color: Colors.black87));

  Widget _drop<T>({
    required T? value, required String label, required IconData icon,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) =>
      Container(
        decoration: _cardDeco(),
        child: DropdownButtonFormField<T>(
          value: value,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon, color: kPrimary),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none),
            filled: true, fillColor: Colors.white,
          ),
          items: items, onChanged: onChanged,
          borderRadius: BorderRadius.circular(14),
        ),
      );

  Widget _dropInline<T>({
    required T value, required String label,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) =>
      DropdownButtonFormField<T>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        items: items, onChanged: onChanged,
        borderRadius: BorderRadius.circular(12),
      );

  Widget _dot(Color bg, Color border, String label) => Row(children: [
        Container(width: 12, height: 12,
            decoration: BoxDecoration(color: bg,
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: border, width: 1.5))),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ]);
}

// ════════════════════════════════════════════════════════════════
//  PANTALLA DE PERFIL  (ahora pantalla separada)
// ════════════════════════════════════════════════════════════════

class PerfilScreen extends StatefulWidget {
  final AppProvider app;
  const PerfilScreen({Key? key, required this.app}) : super(key: key);
  @override State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  late final TextEditingController _pNom;
  late final TextEditingController _pEma;
  late final TextEditingController _pTel;
  late final TextEditingController _pDir;
  late final TextEditingController _pNac;
  late final TextEditingController _pGen;
  File? _pFoto;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final u = widget.app.usuarioActual;
    _pNom = TextEditingController(text: u?.nombre ?? '');
    _pEma = TextEditingController(text: u?.email ?? '');
    _pTel = TextEditingController(text: u?.telefono ?? '');
    _pDir = TextEditingController(text: u?.direccion ?? '');
    _pNac = TextEditingController(text: u?.fechaNacimiento ?? '');
    _pGen = TextEditingController(text: u?.genero ?? '');
  }

  @override
  void dispose() {
    for (final c in [_pNom, _pEma, _pTel, _pDir, _pNac, _pGen]) { c.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.app;
    final u = app.usuarioActual;

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        actions: [
          // Botón cerrar sesión en AppBar del perfil
          TextButton.icon(
            onPressed: () async {
              await app.logout();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (_) => false);
            },
            icon: const Icon(Icons.logout, color: Colors.white70, size: 18),
            label: const Text('Salir',
                style: TextStyle(color: Colors.white70, fontSize: 13)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [

          // ── Foto + nombre ──────────────────────
          Container(
            width: double.infinity, padding: const EdgeInsets.all(24),
            decoration: _cardDeco(),
            child: Column(children: [
              GestureDetector(
                onTap: () async {
                  final f = await _picker.pickImage(source: ImageSource.gallery);
                  if (f != null) setState(() => _pFoto = File(f.path));
                },
                child: Stack(alignment: Alignment.bottomRight, children: [
                  CircleAvatar(
                    radius: 52, backgroundColor: Colors.grey.shade200,
                    backgroundImage: _pFoto != null
                        ? FileImage(_pFoto!) as ImageProvider
                        : u?.foto != null
                            ? (u!.foto!.startsWith('http')
                                ? NetworkImage(u.foto!) as ImageProvider
                                : FileImage(File(u.foto!)))
                            : null,
                    child: (_pFoto == null && u?.foto == null)
                        ? const Icon(Icons.person, size: 50, color: Colors.grey) : null,
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(color: kPrimary, shape: BoxShape.circle),
                    child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                  ),
                ]),
              ),
              const SizedBox(height: 12),
              Text(u?.nombre ?? 'Usuario',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(u?.email ?? '',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              const SizedBox(height: 8),
              // Estadísticas rápidas del usuario
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _statChip(Icons.pets, '${app.mascotas.length}', 'mascotas'),
                const SizedBox(width: 12),
                _statChip(Icons.calendar_today, '${app.citas.length}', 'citas'),
                const SizedBox(width: 12),
                _statChip(Icons.vaccines, '${app.vacunas.length}', 'vacunas'),
              ]),
            ]),
          ),

          const SizedBox(height: 20),

          // ── Formulario ──────────────────────────
          Container(
            padding: const EdgeInsets.all(20), decoration: _cardDeco(),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: kPrimary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.person_outline, color: kPrimary, size: 20),
                ),
                const SizedBox(width: 10),
                const Text('Información Personal',
                    style: TextStyle(fontWeight: FontWeight.bold,
                        fontSize: 15, color: kPrimary)),
              ]),
              const SizedBox(height: 16),
              _tf(_pNom, 'Nombre completo',        Icons.person_outline),
              const SizedBox(height: 10),
              _tf(_pEma, 'Correo electrónico',     Icons.email_outlined),
              const SizedBox(height: 10),
              _tf(_pTel, 'Teléfono',               Icons.phone_outlined),
              const SizedBox(height: 10),
              _tf(_pDir, 'Dirección',              Icons.home_outlined),
              const SizedBox(height: 10),
              _tf(_pNac, 'Fecha de nacimiento',    Icons.cake_outlined),
              const SizedBox(height: 10),
              _tf(_pGen, 'Género',                 Icons.person_outline),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14))),
                  onPressed: () {
                    if (_pNom.text.isEmpty || _pEma.text.isEmpty) {
                      _snack(context, 'Nombre y correo son obligatorios');
                      return;
                    }
                    app.actualizarPerfil(
                      nombre: _pNom.text, email: _pEma.text,
                      foto: _pFoto?.path, tel: _pTel.text, dir: _pDir.text,
                      nac: _pNac.text, gen: _pGen.text,
                    );
                    _snack(context, 'Perfil actualizado');
                    setState(() {}); // actualiza la vista
                  },
                  child: const Text('Guardar cambios',
                      style: TextStyle(fontSize: 15, color: Colors.white,
                          fontWeight: FontWeight.bold)),
                ),
              ),
            ]),
          ),

          const SizedBox(height: 16),

          // ── Expediente directo desde perfil ─────
          GestureDetector(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => ExpedienteScreen(app: app))),
            child: Container(
              width: double.infinity, padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1B5E20), Color(0xFF43A047)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.folder_shared, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Expediente Clínico',
                      style: TextStyle(color: Colors.white,
                          fontWeight: FontWeight.bold, fontSize: 14)),
                  SizedBox(height: 2),
                  Text('Ver historial completo y descargar PDF',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                ])),
                const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 14),
              ]),
            ),
          ),

          const SizedBox(height: 16),

          // ── Sección mascotas (vista rápida) ─────
          Container(
            padding: const EdgeInsets.all(20), decoration: _cardDeco(),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: Colors.teal.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.pets, color: Colors.teal, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Text('Mis Mascotas',
                      style: TextStyle(fontWeight: FontWeight.bold,
                          fontSize: 15, color: Colors.teal)),
                ]),
              ]),
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 12),
              app.mascotas.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text('Sin mascotas registradas',
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
                    )
                  : Column(
                      children: app.mascotas.map((m) {
                        final vacunas = app.vacunasDe(m.id);
                        final visitas = app.visitasDe(m.id);
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: kBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(children: [
                            Container(
                              width: 48, height: 48,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE3F2FD),
                                shape: BoxShape.circle,
                                image: m.foto != null
                                    ? DecorationImage(
                                        image: m.foto!.startsWith('http')
                                            ? NetworkImage(m.foto!) as ImageProvider
                                            : FileImage(File(m.foto!)),
                                        fit: BoxFit.cover)
                                    : null,
                              ),
                              child: m.foto == null
                                  ? const Icon(Icons.pets, color: kPrimary, size: 22)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text(m.nombre,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold, fontSize: 14)),
                                Text('${m.especie} · ${m.raza}',
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey.shade600)),
                              ]),
                            ),
                            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                              _miniChip('${vacunas.length} vacunas', const Color(0xFFEDE7F6), const Color(0xFF7B1FA2)),
                              const SizedBox(height: 4),
                              _miniChip('${visitas.length} visitas', const Color(0xFFE3F2FD), kPrimary),
                            ]),
                          ]),
                        );
                      }).toList(),
                    ),
            ]),
          ),

          const SizedBox(height: 16),

          // ── Botón cerrar sesión ──────────────────
          SizedBox(
            width: double.infinity, height: 50,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text('Cerrar sesión',
                  style: TextStyle(fontSize: 15, color: Colors.red,
                      fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () async {
                await app.logout();
                if (!context.mounted) return;
                Navigator.pushAndRemoveUntil(context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (_) => false);
              },
            ),
          ),
          const SizedBox(height: 30),
        ]),
      ),
    );
  }

  Widget _statChip(IconData icon, String val, String lbl) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
            color: kPrimary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20)),
        child: Row(children: [
          Icon(icon, size: 14, color: kPrimary),
          const SizedBox(width: 4),
          Text('$val $lbl',
              style: const TextStyle(fontSize: 11, color: kPrimary,
                  fontWeight: FontWeight.w600)),
        ]),
      );

  Widget _miniChip(String txt, Color bg, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
            color: bg, borderRadius: BorderRadius.circular(10)),
        child: Text(txt, style: TextStyle(fontSize: 10, color: color,
            fontWeight: FontWeight.w600)),
      );
}

// ════════════════════════════════════════════════════════════════
//  SERVICIO TILE
// ════════════════════════════════════════════════════════════════

class _ServTile extends StatelessWidget {
  final IconData icon;
  final String   label;
  final Color    color;
  const _ServTile(this.icon, this.label, this.color, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
                blurRadius: 6, offset: const Offset(0, 3))]),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: color.withOpacity(0.15), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 6),
          Text(label, textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                  color: color)),
        ]),
      );
}

// ════════════════════════════════════════════════════════════════
//  PANTALLA CAMINATA
// ════════════════════════════════════════════════════════════════

class PasosScreen extends StatefulWidget {
  final AppProvider app;
  const PasosScreen({super.key, required this.app});
  @override State<PasosScreen> createState() => _PasosScreenState();
}

class _PasosScreenState extends State<PasosScreen>
    with SingleTickerProviderStateMixin {
  StreamSubscription<StepCount>? _sub;
  int  _base = 0, _sesion = 0;
  bool _on = false, _err = false;
  String? _mid;
  final List<String> _hist = [];

  late AnimationController _ac;
  late Animation<double>   _an;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(vsync: this,
        duration: const Duration(seconds: 2))..repeat(reverse: true);
    _an = Tween<double>(begin: -8, end: 8).animate(
        CurvedAnimation(parent: _ac, curve: Curves.easeInOut));
  }

  void _iniciar() {
    setState(() { _on = true; _sesion = 0; _base = 0; });
    _sub = Pedometer.stepCountStream.listen(
      (e) => setState(() {
        if (_base == 0) _base = e.steps;
        _sesion = (e.steps - _base).clamp(0, 999999);
      }),
      onError: (_) { setState(() => _err = true); _simular(); },
      cancelOnError: true,
    );
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Caminata iniciada')));
  }

  void _simular() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 850));
      if (!_on || !mounted) return false;
      setState(() => _sesion++);
      return true;
    });
  }

  void _detener() {
    _sub?.cancel(); _sub = null;
    if (_mid == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Selecciona una mascota')));
      return;
    }
    final nom = widget.app.mascotas.firstWhere((m) => m.id == _mid).nombre;
    final hoy = DateTime.now();
    setState(() {
      _hist.insert(0,
          '$nom  -  $_sesion pasos  -  ${hoy.day}/${hoy.month}/${hoy.year}');
      _on = false; _base = 0; _sesion = 0;
    });
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Caminata guardada')));
  }

  @override
  void dispose() { _sub?.cancel(); _ac.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final app = widget.app;
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        title: const Text('Registro de Caminata'),
        backgroundColor: kPrimary, foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          AnimatedBuilder(
            animation: _an,
            builder: (_, __) => Transform.translate(
              offset: Offset(0, _an.value),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: kPrimary.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.pets, size: 60, color: kPrimary),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('$_sesion',
              style: const TextStyle(fontSize: 72,
                  fontWeight: FontWeight.bold, color: kPrimary)),
          const Text('pasos',
              style: TextStyle(color: Colors.grey, fontSize: 16)),
          if (_err)
            const Text('Modo simulación activo',
                style: TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 20),
          _dropLocal<String>(
            value: _mid, label: 'Seleccionar mascota', icon: Icons.pets,
            items: app.mascotas.map((m) =>
                DropdownMenuItem(value: m.id, child: Text(m.nombre))).toList(),
            onChanged: (v) => setState(() => _mid = v),
          ),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: ElevatedButton.icon(
              icon: const Icon(Icons.play_arrow, color: Colors.white),
              label: const Text('Iniciar', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green,
                  padding: const EdgeInsets.all(14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              onPressed: _on ? null : _iniciar,
            )),
            const SizedBox(width: 12),
            Expanded(child: ElevatedButton.icon(
              icon: const Icon(Icons.stop, color: Colors.white),
              label: const Text('Detener', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red,
                  padding: const EdgeInsets.all(14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              onPressed: _on ? _detener : null,
            )),
          ]),
          const SizedBox(height: 20),
          Align(alignment: Alignment.centerLeft,
              child: const Text('Historial de caminatas',
                  style: TextStyle(fontWeight: FontWeight.bold,
                      fontSize: 15, color: Colors.black87))),
          const SizedBox(height: 10),
          Expanded(
            child: _hist.isEmpty
                ? Center(child: Text('Sin caminatas registradas',
                    style: TextStyle(color: Colors.grey.shade400)))
                : ListView.builder(
                    itemCount: _hist.length,
                    itemBuilder: (_, i) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: _cardDeco(),
                      child: Row(children: [
                        const Icon(Icons.directions_walk, color: kPrimary, size: 20),
                        const SizedBox(width: 10),
                        Expanded(child: Text(_hist[i],
                            style: const TextStyle(fontSize: 13))),
                      ]),
                    ),
                  ),
          ),
        ]),
      ),
    );
  }

  Widget _dropLocal<T>({
    required T? value, required String label, required IconData icon,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) =>
      Container(
        decoration: _cardDeco(),
        child: DropdownButtonFormField<T>(
          value: value,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon, color: kPrimary),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none),
            filled: true, fillColor: Colors.white,
          ),
          items: items, onChanged: onChanged,
          borderRadius: BorderRadius.circular(14),
        ),
      );
}

// ════════════════════════════════════════════════════════════════
//  PANTALLA DE VACUNAS
// ════════════════════════════════════════════════════════════════

class VacunasScreen extends StatefulWidget {
  final AppProvider app;
  const VacunasScreen({super.key, required this.app});
  @override State<VacunasScreen> createState() => _VacunasScreenState();
}

class _VacunasScreenState extends State<VacunasScreen> {
  String? _filtroMascota;

  void _dlgAgregarVacuna(BuildContext context) {
    final app    = widget.app;
    final nomCtrl = TextEditingController();
    String? mid;
    DateTime fApl = DateTime.now();
    DateTime? fPrx;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, ss) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Registrar Vacuna'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              DropdownButtonFormField<String>(
                value: mid,
                decoration: InputDecoration(
                  labelText: 'Mascota *',
                  prefixIcon: const Icon(Icons.pets, color: kPrimary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: app.mascotas.map((m) =>
                    DropdownMenuItem(value: m.id, child: Text(m.nombre))).toList(),
                onChanged: (v) => ss(() => mid = v),
                borderRadius: BorderRadius.circular(12),
              ),
              const SizedBox(height: 10),
              _tf(nomCtrl, 'Nombre de la vacuna *', Icons.vaccines_outlined),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today, color: kPrimary),
                title: Text(
                  'Aplicada: ${fApl.day}/${fApl.month}/${fApl.year}',
                  style: const TextStyle(fontSize: 13),
                ),
                onTap: () async {
                  final d = await showDatePicker(
                      context: ctx, initialDate: fApl,
                      firstDate: DateTime(2020), lastDate: DateTime.now());
                  if (d != null) ss(() => fApl = d);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event_repeat, color: Colors.teal),
                title: Text(
                  fPrx == null ? 'Próxima dosis (opcional)'
                      : 'Próxima: ${fPrx!.day}/${fPrx!.month}/${fPrx!.year}',
                  style: const TextStyle(fontSize: 13),
                ),
                onTap: () async {
                  final d = await showDatePicker(
                      context: ctx,
                      initialDate: DateTime.now().add(const Duration(days: 365)),
                      firstDate: DateTime.now(), lastDate: DateTime(2030));
                  if (d != null) ss(() => fPrx = d);
                },
              ),
            ]),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              onPressed: () {
                if (nomCtrl.text.isEmpty || mid == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Selecciona una mascota y escribe el nombre')));
                  return;
                }
                app.agregarVacuna(Vacuna(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  mascotaId: mid!, nombre: nomCtrl.text,
                  fecha: fApl, proxima: fPrx,
                ));
                setState(() {});
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vacuna registrada')));
              },
              child: const Text('Guardar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app     = widget.app;
    final ahora   = DateTime.now();

    final todasVac = app.vacunas.where((v) =>
        _filtroMascota == null || v.mascotaId == _filtroMascota).toList()
      ..sort((a, b) => b.fecha.compareTo(a.fecha));

    final proximas = app.vacunas.where((v) {
      if (v.proxima == null) return false;
      final d = v.proxima!.difference(ahora).inDays;
      return d >= 0 && d <= 30;
    }).toList();

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        title: const Text('Vacunas'),
        backgroundColor: kPrimary, foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Registrar vacuna',
            onPressed: app.mascotas.isEmpty
                ? () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Primero registra una mascota')))
                : () => _dlgAgregarVacuna(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.teal,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nueva vacuna',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: app.mascotas.isEmpty
            ? () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Primero registra una mascota')))
            : () => _dlgAgregarVacuna(context),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          if (proximas.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Text('${proximas.length} vacuna${proximas.length > 1 ? 's' : ''} próxima${proximas.length > 1 ? 's' : ''} a vencer',
                      style: const TextStyle(fontWeight: FontWeight.bold,
                          color: Colors.orange, fontSize: 14)),
                ]),
                const SizedBox(height: 8),
                ...proximas.map((v) {
                  final mNom = app.mascotas.where((m) => m.id == v.mascotaId)
                      .map((m) => m.nombre).firstOrNull ?? '';
                  final dias = v.proxima!.difference(ahora).inDays;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(children: [
                      const Icon(Icons.circle, size: 6, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(child: Text('$mNom — ${v.nombre}',
                          style: const TextStyle(fontSize: 13))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: dias <= 7 ? Colors.red.shade400 : Colors.orange.shade400,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(dias == 0 ? 'Hoy' : 'en $dias dias',
                            style: const TextStyle(color: Colors.white,
                                fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ]),
                  );
                }),
              ]),
            ),
            const SizedBox(height: 20),
          ],

          if (app.mascotas.isNotEmpty) ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                _filtroChip('Todas', null),
                ...app.mascotas.map((m) => _filtroChip(m.nombre, m.id)),
              ]),
            ),
            const SizedBox(height: 16),
          ],

          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('${todasVac.length} vacuna${todasVac.length == 1 ? '' : 's'} registrada${todasVac.length == 1 ? '' : 's'}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          ]),
          const SizedBox(height: 10),

          if (todasVac.isEmpty)
            Container(
              width: double.infinity, padding: const EdgeInsets.all(24),
              decoration: _cardDeco(),
              child: Column(children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: Colors.teal.withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.vaccines, color: Colors.teal, size: 36),
                ),
                const SizedBox(height: 12),
                const Text('Sin vacunas registradas',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Text('Toca el botón + para registrar la primera vacuna',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                    textAlign: TextAlign.center),
              ]),
            )
          else
            ...todasVac.map((v) {
              final mascota = app.mascotas.where((m) => m.id == v.mascotaId)
                  .firstOrNull;
              final mNom = mascota?.nombre ?? 'Mascota';
              final vence = v.proxima != null
                  ? v.proxima!.difference(ahora).inDays
                  : null;
              final venceProx = vence != null && vence <= 30;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: venceProx
                      ? Border.all(color: Colors.orange.shade300, width: 1.5)
                      : Border.all(color: Colors.grey.shade100),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
                      blurRadius: 8, offset: const Offset(0, 3))],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: venceProx
                            ? Colors.orange.withOpacity(0.12)
                            : const Color(0xFFEDE7F6),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(Icons.vaccines,
                          color: venceProx
                              ? Colors.orange.shade700
                              : const Color(0xFF7B1FA2),
                          size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(v.nombre,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 3),
                        Row(children: [
                          if (mascota?.foto != null)
                            CircleAvatar(
                              radius: 10,
                              backgroundImage: FileImage(File(mascota!.foto!)),
                            )
                          else
                            const CircleAvatar(
                              radius: 10, backgroundColor: Color(0xFFE3F2FD),
                              child: Icon(Icons.pets, size: 10, color: kPrimary),
                            ),
                          const SizedBox(width: 6),
                          Text(mNom,
                              style: TextStyle(fontSize: 12,
                                  color: Colors.grey.shade600)),
                        ]),
                        const SizedBox(height: 4),
                        Text('Aplicada: ${v.fecha.day}/${v.fecha.month}/${v.fecha.year}',
                            style: TextStyle(fontSize: 11,
                                color: Colors.grey.shade500)),
                        if (v.proxima != null)
                          Text('Próxima: ${v.proxima!.day}/${v.proxima!.month}/${v.proxima!.year}',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: venceProx
                                      ? Colors.orange.shade700
                                      : Colors.grey.shade500,
                                  fontWeight: venceProx
                                      ? FontWeight.bold : FontWeight.normal)),
                      ]),
                    ),
                    if (vence != null)
                      Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: venceProx
                                ? (vence <= 7
                                    ? Colors.red.shade400
                                    : Colors.orange.shade400)
                                : Colors.green.shade400,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            vence < 0 ? 'Vencida'
                                : vence == 0 ? 'Hoy'
                                : venceProx ? 'en $vence dias'
                                : 'Al día',
                            style: const TextStyle(color: Colors.white,
                                fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ]),
                  ]),
                ),
              );
            }),
        ]),
      ),
    );
  }

  Widget _filtroChip(String label, String? id) {
    final sel = _filtroMascota == id;
    return GestureDetector(
      onTap: () => setState(() => _filtroMascota = id),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: sel ? Colors.teal : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: sel ? Colors.teal : Colors.grey.shade300),
          boxShadow: sel
              ? [BoxShadow(color: Colors.teal.withOpacity(0.3),
                  blurRadius: 6, offset: const Offset(0, 2))]
              : null,
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                color: sel ? Colors.white : Colors.grey.shade700,
                fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  EXPEDIENTE CLINICO
// ════════════════════════════════════════════════════════════════

class ExpedienteScreen extends StatefulWidget {
  final AppProvider app;
  const ExpedienteScreen({super.key, required this.app});
  @override State<ExpedienteScreen> createState() => _ExpedienteScreenState();
}

class _ExpedienteScreenState extends State<ExpedienteScreen> {
  bool _generando = false;

  Future<void> _generarExpedientePDF() async {
    setState(() => _generando = true);
    try {
      final app = widget.app;
      final u   = app.usuarioActual;
      final pdf = pw.Document();
      final ahora = DateTime.now();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(36),
          header: (_) => pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: pw.BoxDecoration(
              color: const PdfColor.fromInt(0xFF1565C0),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
              pw.Text('EXPEDIENTE CLINICO',
                  style: pw.TextStyle(fontSize: 16,
                      fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
              pw.Text(
                  'Generado: ${ahora.day}/${ahora.month}/${ahora.year}',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey300)),
            ]),
          ),
          footer: (_) => pw.Padding(
            padding: const pw.EdgeInsets.only(top: 8),
            child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
              pw.Text('Clínica Veterinaria  |  Tel: 664-123-4567',
                  style: pw.TextStyle(fontSize: 9, color: PdfColors.grey)),
              pw.Text('clinica@vet.com',
                  style: pw.TextStyle(fontSize: 9, color: PdfColors.grey)),
            ]),
          ),
          build: (_) => [
            pw.SizedBox(height: 16),
            _exSec('DATOS DEL CLIENTE'),
            pw.SizedBox(height: 8),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                _exFila('Nombre',    u?.nombre    ?? '-'),
                _exFila('Correo',    u?.email     ?? '-'),
                _exFila('Teléfono',  u?.telefono  ?? '-'),
                _exFila('Dirección', u?.direccion ?? '-'),
                if (u?.fechaNacimiento != null && u!.fechaNacimiento!.isNotEmpty)
                  _exFila('Fecha de nacimiento', u.fechaNacimiento!),
                if (u?.genero != null && u!.genero!.isNotEmpty)
                  _exFila('Género', u.genero!),
              ]),
            ),
            pw.SizedBox(height: 20),
            _exSec('CITAS AGENDADAS'),
            pw.SizedBox(height: 8),
            app.citas.isEmpty
                ? _exVacio('Sin citas registradas')
                : pw.Column(children: app.citas.map((c) {
                    final mNom = app.mascotas
                        .where((m) => m.id == c.mascotaId)
                        .map((m) => m.nombre)
                        .firstOrNull ?? '-';
                    return pw.Container(
                      margin: const pw.EdgeInsets.only(bottom: 6),
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey300),
                        borderRadius:
                            const pw.BorderRadius.all(pw.Radius.circular(6)),
                      ),
                      child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                        pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            children: [
                          pw.Text(c.servicio,
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 12)),
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: pw.BoxDecoration(
                              color: c.estado == 'Cancelada'
                                  ? PdfColors.red100
                                  : PdfColors.green100,
                              borderRadius: const pw.BorderRadius.all(
                                  pw.Radius.circular(10)),
                            ),
                            child: pw.Text(c.estado,
                                style: pw.TextStyle(
                                    fontSize: 9,
                                    color: c.estado == 'Cancelada'
                                        ? PdfColors.red800
                                        : PdfColors.green800)),
                          ),
                        ]),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Mascota: $mNom  |  Vet: ${c.veterinario}  |  '
                          '${c.fecha.day}/${c.fecha.month}/${c.fecha.year}  '
                          '${c.fecha.hour.toString().padLeft(2, '0')}:'
                          '${c.fecha.minute.toString().padLeft(2, '0')}',
                          style: pw.TextStyle(
                              fontSize: 10, color: PdfColors.grey700),
                        ),
                      ]),
                    );
                  }).toList()),
            pw.SizedBox(height: 20),
            ...app.mascotas.map((m) {
              final visitas = app.visitasDe(m.id);
              final vacunas = app.vacunasDe(m.id);
              return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                _exSec('MASCOTA: ${m.nombre.toUpperCase()}'),
                pw.SizedBox(height: 8),
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blue50,
                    borderRadius:
                        const pw.BorderRadius.all(pw.Radius.circular(8)),
                  ),
                  child: pw.Wrap(spacing: 20, runSpacing: 4, children: [
                    _exChip('Especie: ${m.especie}'),
                    _exChip('Raza: ${m.raza}'),
                    _exChip('Edad: ${m.edad}'),
                    _exChip('Peso: ${m.peso} kg'),
                    _exChip('Sexo: ${m.sexo}'),
                    _exChip('Color: ${m.color}'),
                    if (m.microchip != null && m.microchip!.isNotEmpty)
                      _exChip('Microchip: ${m.microchip}'),
                  ]),
                ),
                pw.SizedBox(height: 10),
                pw.Text('Historial Médico',
                    style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: const PdfColor.fromInt(0xFF1565C0))),
                pw.SizedBox(height: 4),
                visitas.isEmpty
                    ? _exVacio('Sin visitas registradas')
                    : pw.Column(children: visitas.map((v) => pw.Container(
                          margin: const pw.EdgeInsets.only(bottom: 5),
                          padding: const pw.EdgeInsets.all(8),
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(color: PdfColors.blue200),
                            borderRadius: const pw.BorderRadius.all(
                                pw.Radius.circular(6)),
                          ),
                          child: pw.Column(
                              crossAxisAlignment:
                                  pw.CrossAxisAlignment.start,
                              children: [
                            pw.Row(
                                mainAxisAlignment:
                                    pw.MainAxisAlignment.spaceBetween,
                                children: [
                              pw.Text(v.diagnostico,
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold,
                                      fontSize: 11)),
                              pw.Text(
                                  '${v.fecha.day}/${v.fecha.month}/${v.fecha.year}',
                                  style: pw.TextStyle(
                                      fontSize: 9, color: PdfColors.grey)),
                            ]),
                            if (v.tratamiento.isNotEmpty)
                              pw.Text('Tratamiento: ${v.tratamiento}',
                                  style: pw.TextStyle(
                                      fontSize: 10,
                                      color: PdfColors.grey700)),
                            pw.Text('Veterinario: ${v.veterinario}',
                                style: pw.TextStyle(
                                    fontSize: 10, color: PdfColors.grey600)),
                          ]),
                        )).toList()),
                pw.SizedBox(height: 10),
                pw.Text('Vacunas',
                    style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: const PdfColor.fromInt(0xFF4A148C))),
                pw.SizedBox(height: 4),
                vacunas.isEmpty
                    ? _exVacio('Sin vacunas registradas')
                    : pw.Column(children: vacunas.map((v) => pw.Container(
                          margin: const pw.EdgeInsets.only(bottom: 5),
                          padding: const pw.EdgeInsets.all(8),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.purple50,
                            borderRadius: const pw.BorderRadius.all(
                                pw.Radius.circular(6)),
                          ),
                          child: pw.Row(
                              mainAxisAlignment:
                                  pw.MainAxisAlignment.spaceBetween,
                              children: [
                            pw.Text(v.nombre,
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold,
                                    fontSize: 11)),
                            pw.Column(
                                crossAxisAlignment:
                                    pw.CrossAxisAlignment.end,
                                children: [
                              pw.Text(
                                  'Aplicada: ${v.fecha.day}/${v.fecha.month}/${v.fecha.year}',
                                  style: pw.TextStyle(
                                      fontSize: 9,
                                      color: PdfColors.grey700)),
                              if (v.proxima != null)
                                pw.Text(
                                    'Próxima: ${v.proxima!.day}/${v.proxima!.month}/${v.proxima!.year}',
                                    style: pw.TextStyle(
                                        fontSize: 9,
                                        color: PdfColors.orange800)),
                            ]),
                          ]),
                        )).toList()),
                pw.SizedBox(height: 20),
              ]);
            }),
          ],
        ),
      );

      final dir  = await getApplicationDocumentsDirectory();
      final path =
          '${dir.path}/expediente_${u?.nombre.replaceAll(' ', '_') ?? 'cliente'}_${ahora.millisecondsSinceEpoch}.pdf';
      final file = File(path);
      await file.writeAsBytes(await pdf.save());

      if (!mounted) return;
      setState(() => _generando = false);
      await Share.shareXFiles(
        [XFile(path)],
        text: 'Expediente Clínico - ${u?.nombre ?? 'Cliente'}',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _generando = false);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al generar expediente: $e')));
    }
  }

  pw.Widget _exSec(String t) => pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: pw.BoxDecoration(
          color: const PdfColor.fromInt(0xFF1565C0),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        ),
        child: pw.Text(t,
            style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white)),
      );

  pw.Widget _exFila(String lbl, String val) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 2),
        child: pw.Row(children: [
          pw.SizedBox(
            width: 130,
            child: pw.Text(lbl,
                style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 11,
                    color: PdfColors.grey700)),
          ),
          pw.Text(val, style: pw.TextStyle(fontSize: 11)),
        ]),
      );

  pw.Widget _exChip(String txt) => pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: pw.BoxDecoration(
          color: PdfColors.white,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
          border: pw.Border.all(color: PdfColors.blue200),
        ),
        child: pw.Text(txt,
            style: pw.TextStyle(fontSize: 9, color: PdfColors.blue900)),
      );

  pw.Widget _exVacio(String msg) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 4),
        child: pw.Text(msg,
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey400)),
      );

  @override
  Widget build(BuildContext context) {
    final app = widget.app;
    final u   = app.usuarioActual;

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        title: const Text('Expediente Clínico'),
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        actions: [
          if (_generando)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2)),
            )
          else
            IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              tooltip: 'Descargar expediente',
              onPressed: _generarExpedientePDF,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.download, color: Colors.white),
              label: Text(
                _generando ? 'Generando PDF...' : 'Descargar Expediente Completo',
                style: const TextStyle(color: Colors.white,
                    fontWeight: FontWeight.bold, fontSize: 15),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B5E20),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _generando ? null : _generarExpedientePDF,
            ),
          ),

          const SizedBox(height: 6),
          Center(
            child: Text(
              'El PDF incluye datos del cliente, citas, historial médico y vacunas',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 24),

          _secCard(
            title: 'Datos del Cliente',
            icon: Icons.person_outline,
            color: kPrimary,
            child: Column(children: [
              _infoRow(Icons.person,     u?.nombre     ?? '-'),
              _infoRow(Icons.email,      u?.email      ?? '-'),
              _infoRow(Icons.phone,      u?.telefono   ?? '-'),
              _infoRow(Icons.home,       u?.direccion  ?? '-'),
              if (u?.fechaNacimiento != null && u!.fechaNacimiento!.isNotEmpty)
                _infoRow(Icons.cake, u.fechaNacimiento!),
              if (u?.genero != null && u!.genero!.isNotEmpty)
                _infoRow(Icons.person_outline, u.genero!),
            ]),
          ),

          const SizedBox(height: 16),

          _secCard(
            title: 'Citas Agendadas (${app.citas.length})',
            icon: Icons.calendar_today,
            color: Colors.indigo,
            child: app.citas.isEmpty
                ? _empty('Sin citas registradas')
                : Column(
                    children: app.citas.map((c) {
                      final mNom = app.mascotas
                          .where((m) => m.id == c.mascotaId)
                          .map((m) => m.nombre)
                          .firstOrNull ?? '-';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: kBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.indigo.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.event,
                                color: Colors.indigo, size: 18),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(c.servicio,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13)),
                              Text('$mNom  -  ${c.veterinario.split(' ').take(2).join(' ')}',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600)),
                              Text(
                                '${c.fecha.day}/${c.fecha.month}/${c.fecha.year}  '
                                '${c.fecha.hour.toString().padLeft(2, '0')}:'
                                '${c.fecha.minute.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey.shade500),
                              ),
                            ]),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: c.estado == 'Cancelada'
                                  ? Colors.red.shade50
                                  : Colors.green.shade50,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(c.estado,
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: c.estado == 'Cancelada'
                                        ? Colors.red.shade700
                                        : Colors.green.shade700)),
                          ),
                        ]),
                      );
                    }).toList(),
                  ),
          ),

          const SizedBox(height: 16),

          ...app.mascotas.map((m) {
            final visitas = app.visitasDe(m.id);
            final vacunas = app.vacunasDe(m.id);
            return Column(children: [
              _secCard(
                title: m.nombre,
                icon: Icons.pets,
                color: Colors.teal,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Wrap(spacing: 8, runSpacing: 6, children: [
                    _chip('${m.especie}'),
                    _chip('${m.raza}'),
                    _chip('${m.edad}'),
                    _chip('${m.peso} kg'),
                    _chip(m.sexo),
                    if (m.microchip != null && m.microchip!.isNotEmpty)
                      _chip('Chip: ${m.microchip}'),
                  ]),
                  const SizedBox(height: 14),
                  const Divider(),
                  Row(children: [
                    const Icon(Icons.local_hospital, color: kPrimary, size: 16),
                    const SizedBox(width: 6),
                    Text('Historial Médico (${visitas.length})',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13)),
                  ]),
                  const SizedBox(height: 8),
                  visitas.isEmpty
                      ? _empty('Sin visitas registradas')
                      : Column(
                          children: visitas.map((v) => Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE3F2FD),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(children: [
                              Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Text(v.diagnostico,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13)),
                                  if (v.tratamiento.isNotEmpty)
                                    Text('Trat: ${v.tratamiento}',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade600)),
                                  Text(v.veterinario,
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade500)),
                                ]),
                              ),
                              Text(
                                  '${v.fecha.day}/${v.fecha.month}/${v.fecha.year}',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade500)),
                            ]),
                          )).toList(),
                        ),
                  const SizedBox(height: 14),
                  const Divider(),
                  Row(children: [
                    const Icon(Icons.vaccines,
                        color: Color(0xFF7B1FA2), size: 16),
                    const SizedBox(width: 6),
                    Text('Vacunas (${vacunas.length})',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13)),
                  ]),
                  const SizedBox(height: 8),
                  vacunas.isEmpty
                      ? _empty('Sin vacunas registradas')
                      : Column(
                          children: vacunas.map((v) => Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEDE7F6),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                              Text(v.nombre,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13)),
                              Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                Text(
                                    'Aplicada: ${v.fecha.day}/${v.fecha.month}/${v.fecha.year}',
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey.shade600)),
                                if (v.proxima != null)
                                  Text(
                                      'Próxima: ${v.proxima!.day}/${v.proxima!.month}/${v.proxima!.year}',
                                      style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.orange,
                                          fontWeight: FontWeight.bold)),
                              ]),
                            ]),
                          )).toList(),
                        ),
                ]),
              ),
              const SizedBox(height: 16),
            ]);
          }),

          const SizedBox(height: 30),
        ]),
      ),
    );
  }

  Widget _secCard({
    required String title, required IconData icon,
    required Color color, required Widget child,
  }) =>
      Container(
        decoration: _cardDeco(),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Text(title,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15, color: color)),
            ]),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 12),
            child,
          ]),
        ),
      );

  Widget _infoRow(IconData icon, String txt) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(children: [
          Icon(icon, size: 16, color: Colors.grey.shade500),
          const SizedBox(width: 8),
          Expanded(child: Text(txt,
              style: const TextStyle(fontSize: 13))),
        ]),
      );

  Widget _chip(String txt) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.teal.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.teal.withOpacity(0.3)),
        ),
        child: Text(txt,
            style: const TextStyle(fontSize: 11, color: Colors.teal)),
      );

  Widget _empty(String msg) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(msg,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
      );
}

// ════════════════════════════════════════════════════════════════
//  HELPERS GLOBALES
// ════════════════════════════════════════════════════════════════

BoxDecoration _cardDeco() => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06),
          blurRadius: 8, offset: const Offset(0, 3))],
    );

Widget _tf(TextEditingController ctrl, String label, IconData icon,
    {bool obs = false}) =>
    TextField(
      controller: ctrl, obscureText: obs,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: kPrimary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: kPrimary, width: 2),
        ),
      ),
    );

Widget _tfObs(TextEditingController ctrl, String label,
    bool obs, VoidCallback toggle) =>
    TextField(
      controller: ctrl, obscureText: obs,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline, color: kPrimary),
        suffixIcon: IconButton(
          icon: Icon(obs ? Icons.visibility_off : Icons.visibility),
          onPressed: toggle,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: kPrimary, width: 2),
        ),
      ),
    );

Widget _priBtn(String label, VoidCallback fn) =>
    SizedBox(
      width: double.infinity, height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
            backgroundColor: kPrimary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
        onPressed: fn,
        child: Text(label,
            style: const TextStyle(fontSize: 16, color: Colors.white,
                fontWeight: FontWeight.bold)),
      ),
    );

Widget _outBtn(String label, VoidCallback fn) =>
    SizedBox(
      width: double.infinity, height: 50,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
            side: const BorderSide(color: kPrimary),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
        onPressed: fn,
        child: Text(label,
            style: const TextStyle(fontSize: 16, color: kPrimary,
                fontWeight: FontWeight.bold)),
      ),
    );

void _snack(BuildContext ctx, String msg) =>
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(msg)));

// ════════════════════════════════════════════════════════════════
//  MAIN
// ════════════════════════════════════════════════════════════════

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url:     'https://knidpuslwnbrcymbirwh.supabase.co',
    anonKey: 'sb_publishable_NWbhMTEqrDCOCCS1xJEnQA_bCUr4bb2'
  );

  runApp(ChangeNotifierProvider(
    create: (_) => AppProvider(),
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Clínica Veterinaria',
      theme: ThemeData(
        primaryColor: kPrimary,
        scaffoldBackgroundColor: kBg,
        colorScheme: ColorScheme.fromSeed(seedColor: kPrimary, primary: kPrimary),
        appBarTheme: const AppBarTheme(
            backgroundColor: kPrimary, foregroundColor: Colors.white, elevation: 0),
      ),
      home: const SplashScreen(),
    ),
  ));
}