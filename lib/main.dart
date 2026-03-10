import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'datos.dart'; 
import 'package:flutter/foundation.dart'; 
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:ui';
import 'dart:io';
import 'dart:convert';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (!kIsWeb) {
    // 1. Configuramos los parámetros de solicitud de consentimiento (GDPR/UMP)
    final params = ConsentRequestParameters();
    
    // 2. Solicitamos la actualización del estado del consentimiento
    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      () async {
        // 3. Verificamos si hay un formulario de consentimiento disponible y es necesario
        if (await ConsentInformation.instance.isConsentFormAvailable()) {
          ConsentForm.loadConsentForm((form) {
            form.show((formError) async {
              if (formError == null) {
                // 4. Una vez gestionado el consentimiento, inicializamos AdMob
                await MobileAds.instance.initialize();
              }
            });
          }, (loadError) {
            // Error al cargar el formulario, inicializamos de todos modos
            debugPrint("Error al cargar formulario UMP: ${loadError.message}");
            MobileAds.instance.initialize();
          });
        } else {
          // Si no hay formulario (por ejemplo fuera de la UE), inicializamos directamente
          await MobileAds.instance.initialize();
        }
      },
      (FormError error) {
        // En caso de error en la actualización, intentamos inicializar de todos modos
        debugPrint("Error UMP: ${error.message}");
        MobileAds.instance.initialize();
      },
    );
  }

  runApp(MaterialApp(
    title: 'Juego del Impostor',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      brightness: Brightness.dark,
      primaryColor: const Color(0xFF7B61FF), // Electric Violet
      hintColor: const Color(0xFF00E5FF), // Neon Cyan
      scaffoldBackgroundColor: const Color(0xFF050B18), // Deep Night Navy
      cardColor: Colors.white.withOpacity(0.05),
      fontFamily: 'Outfit', // Assume Outfit is available via GoogleFonts
    ),
    home: JuegoImpostor(),
  ));
}

// --- MODELO DE JUGADOR ---
class PlayerModel {
  String id;
  String name;
  String? imagePath;
  Color color;
  bool isCustomPhoto;

  PlayerModel({
    required this.id,
    required this.name,
    this.imagePath,
    this.color = Colors.amber,
    this.isCustomPhoto = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'imagePath': imagePath,
    'color': color.value,
    'isCustomPhoto': isCustomPhoto,
  };

  factory PlayerModel.fromJson(Map<String, dynamic> json) => PlayerModel(
    id: json['id'],
    name: json['name'],
    imagePath: json['imagePath'],
    color: Color(json['color']),
    isCustomPhoto: json['isCustomPhoto'],
  );
}

class JuegoImpostor extends StatefulWidget {
  @override
  _JuegoImpostorState createState() => _JuegoImpostorState();
}
Future<void> abrirDonacion() async {
  // SUSTITUYE 'TuUsuario' por el que hayas creado en PayPal.Me
  final Uri url = Uri.parse('https://paypal.me/DavidCass97');
  
  try {
    // El modo LaunchMode.externalApplication es vital para que abra
    // el navegador o la app de PayPal en el móvil.
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('No se pudo abrir el enlace');
    }
  } catch (e) {
    debugPrint("Error: $e");
  }
}

void abrirOpcionesPrivacidad(BuildContext context) {
  if (kIsWeb) {
    // Si estamos en el navegador, no llamamos al SDK de móvil
    debugPrint("Opciones de privacidad solicitadas en Web.");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("En la web, puedes gestionar tu privacidad en el menú de cookies."),
      ),
    );
    return; // Salimos de la función aquí
  }

  // SI NO ES WEB (Es Android/iOS), ejecutamos lo de antes:
  debugPrint("Abriendo opciones de Privacidad..");
  ConsentForm.showPrivacyOptionsForm((formError) {
    if (formError != null) {
      debugPrint("Error: ${formError.message}");
    }
  });
}

// --- WIDGET DEL MANUAL ---
class ManualWidget extends StatelessWidget {
  final String idioma;
  const ManualWidget({super.key, required this.idioma});

  @override
  Widget build(BuildContext context) {
    // Usamos el mapa de textos según el idioma seleccionado
    var t = textos[idioma]!; 
    
    return Container(
      width: double.maxFinite,
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1.5),
        boxShadow: [
          BoxShadow(color: const Color(0xFF7B61FF).withOpacity(0.1), blurRadius: 20, spreadRadius: 5)
        ]
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- CABECERA ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(t['manual_title']!, style: GoogleFonts.staatliches(fontSize: 28, color: Colors.amber)),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white70),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          Divider(color: Colors.amber.withOpacity(0.3)),

          // --- CONTENIDO DESLIZABLE ---
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSeccionTitulo("⚙️ " + t['ajustes']!),
                  _buildParrafo(idioma == 'ES' 
                    ? "Puedes cambiar tus preferencias de anuncios y privacidad en cualquier momento." 
                    : "You can change your ad and privacy preferences at any time."),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () => abrirOpcionesPrivacidad(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.amber,
                      side: BorderSide(color: Colors.amber.withOpacity(0.5)),
                    ),
                    icon: const Icon(Icons.privacy_tip_outlined, size: 18),
                    label: Text(idioma == 'ES' ? "GESTIONAR PRIVACIDAD" : "MANAGE PRIVACY"),
                  ),

                  _buildSeccionTitulo(t['normas_titulo']!),
                  _buildParrafo(t['normas_desc']!),

                  _buildSeccionTitulo(t['mimica_titulo']!),
                  _buildParrafo(t['mimica_desc']!),

                  _buildSeccionTitulo(t['debate_titulo']!),
                  _buildParrafo(t['debate_desc']!),

                  _buildSeccionTitulo(t['pistas_titulo']!),
                  _buildParrafo(t['pistas_desc']!),

                  _buildSeccionTitulo(t['ruleta_titulo']!),
                  _buildParrafo(t['ruleta_desc']!),
                  
                  // --- SECCIÓN DE APOYO ---
                 const SizedBox(height: 30),
Divider(color: Colors.amber.withOpacity(0.1)),
Center(
  child: Column(
    children: [
      // Usamos ?? "" para evitar el crash si la clave no existe
      Text(t['apoyo_titulo'] ?? "¿TE GUSTA EL JUEGO?", 
        style: const TextStyle(color: Colors.white30, fontSize: 10)),
      const SizedBox(height: 8),
      TextButton.icon(
        onPressed: abrirDonacion,
        icon: const Icon(Icons.coffee_rounded, color: Colors.amber, size: 20),
        label: Text(t['apoyo_btn'] ?? "Apóyame aquí", 
          style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
        style: TextButton.styleFrom(
          backgroundColor: Colors.amber.withOpacity(0.05),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
        ),
      ),
    ],
  ),
),
const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // --- BOTÓN CERRAR ---
          const SizedBox(height: 10),
          Center(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber, 
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 45)
              ),
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.check_rounded),
              label: Text(t['confirmar']!),
            ),
          )
        ],
      ),
    );
  }

  // --- HELPERS DE DISEÑO ---
  Widget _buildSeccionTitulo(String texto) {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0, bottom: 8.0),
      child: Text(texto, style: const TextStyle(color: Colors.amberAccent, fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildParrafo(String texto) {
    return Text(texto, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 15, height: 1.4));
  }
}

void mostrarAjustes(
  BuildContext context, 
  String idiomaActual, 
  bool vibracionActual, 
  Function(String) alCambiarIdioma, 
  Function(bool) alCambiarVibracion
) {
  showDialog(
    context: context,
    builder: (context) => AjustesWidget(
      idiomaInicial: idiomaActual,
      vibracionInicial: vibracionActual,
      onIdiomaChanged: alCambiarIdioma,
      onVibracionChanged: alCambiarVibracion,
    ),
  );
}

class AjustesWidget extends StatefulWidget {
  final String idiomaInicial;
  final bool vibracionInicial;
  final Function(String) onIdiomaChanged;
  final Function(bool) onVibracionChanged;

  const AjustesWidget({
    super.key,
    required this.idiomaInicial,
    required this.vibracionInicial,
    required this.onIdiomaChanged,
    required this.onVibracionChanged,
  });

  @override
  _AjustesWidgetState createState() => _AjustesWidgetState();
}

class _AjustesWidgetState extends State<AjustesWidget> {
  late String tempIdioma;
  late bool tempVibracion;

  @override
  void initState() {
    super.initState();
    tempIdioma = widget.idiomaInicial;
    tempVibracion = widget.vibracionInicial;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0F172A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(25), 
        side: BorderSide(color: Colors.white.withOpacity(0.1), width: 1.5)
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(textos[tempIdioma]!['ajustes']!, 
                style: GoogleFonts.staatliches(fontSize: 28, color: Colors.amber)),
            const Divider(color: Colors.amber),
            
            // Selector de Idioma
            ListTile(
              title: Text(textos[tempIdioma]!['idioma']!, 
                  style: const TextStyle(color: Colors.white)),
              trailing: DropdownButton<String>(
                value: tempIdioma,
                dropdownColor: const Color(0xFF1A2A30),
                underline: Container(),
                items: ['ES', 'EN'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value == 'ES' ? "🇪🇸 Español" : "🇺🇸 English", 
                        style: const TextStyle(color: Colors.amber)),
                  );
                }).toList(),
                onChanged: (nuevo) {
                  setState(() => tempIdioma = nuevo!);
                  widget.onIdiomaChanged(nuevo!); // Avisa al juego del cambio
                },
              ),
            ),

            // Switch de Vibración
            SwitchListTile(
              title: Text(textos[tempIdioma]!['vibracion']!, 
                  style: const TextStyle(color: Colors.white)),
              value: tempVibracion,
              activeColor: Colors.amber,
              onChanged: (valor) {
                setState(() => tempVibracion = valor);
                widget.onVibracionChanged(valor); // Avisa al juego del cambio
              },
            ),

            // Botón de Privacidad (Punto de entrada UMP)
            FutureBuilder<PrivacyOptionsRequirementStatus>(
              future: ConsentInformation.instance.getPrivacyOptionsRequirementStatus(),
              builder: (context, snapshot) {
                if (snapshot.data == PrivacyOptionsRequirementStatus.required) {
                  return ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined, color: Colors.amber),
                    title: Text(tempIdioma == 'ES' ? "Privacidad de anuncios" : "Ad Privacy", 
                        style: const TextStyle(color: Colors.white, fontSize: 14)),
                    onTap: () => abrirOpcionesPrivacidad(context),
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber, 
                foregroundColor: Colors.black
              ),
              onPressed: () => Navigator.pop(context),
              child: Text(textos[tempIdioma]!['confirmar']!),
            )
          ],
        ),
      ),
    );
  }
}

// --- TEXTOS ---
final Map<String, Map<String, String>> textos = {
  'ES': {
    'titulo': 'THE IMPOSTOR',
    'subtitulo': '¿QUIÉN ES EL IMPOSTOR?',
    'nueva_partida': 'NUEVA PARTIDA',
    'ajustes': 'AJUSTES',
    'idioma': 'IDIOMA',
    'vibracion': 'VIBRACIÓN',
    'vibracion_on': 'ACTIVADA',
    'vibracion_off': 'DESACTIVADA',
    'confirmar': 'ENTENDIDO',
    'manual_title': 'MANUAL DE JUEGO',
    // Configuración
    'config_jugadores': 'JUGADORES',
    'config_impostores': 'IMPOSTORES',
    'config_pistas': 'Mostrar Pistas al Impostor',
    'config_mimica': 'Modo Mímica',
    'config_prob': 'PROBABILIDAD %',
    'config_tiempo': 'Tiempo de Debate',
    'config_segundos': 'SEGUNDOS',
    'config_ruleta': 'Ruleta de Castigos',
    'config_inocentes': 'Castigar Inocentes',
    'config_lista_castigos': 'LISTA DE CASTIGOS',
    'config_add_castigo': 'Ej: Hacer 10 flexiones',
    'btn_siguiente': 'SIGUIENTE',
    'btn_empezar': 'EMPEZAR',
    // Juego
    'quien_juega': '¿QUIÉN JUEGA?',
    'categoria_title': 'CATEGORÍA',
    'mantener_pulsado': 'MANTÉN PULSADO',
    'confidencial': 'CONFIDENCIAL',
    'confirmar_pasar': 'CONFIRMAR Y PASAR',
    'tu_rol': 'TU ROL',
    'tu_palabra': 'TU PALABRA',
    'rol_impostor': 'IMPOSTOR',
    'debatir': '¡A DEBATIR!',
    'empieza': 'EMPIEZA',
    'votar_impostor': 'VOTAR AL IMPOSTOR',
    'repetir_partida': 'REPETIR PARTIDA',
    'finalizar': 'FINALIZAR',
    // Votación
    'pasa_movil': 'PASA EL MÓVIL A:',
    'lo_tengo': 'LO TENGO',
    'quien_es_imp': '¿QUIÉN ES EL IMPOSTOR?',
    'eliminado': 'ELIMINADO',
    'era_inocente': 'ERA INOCENTE',
    'cazado': '¡CAZADO!',
    'victoria': '¡IMPOSTOR CAZADO!',
    'duelo': 'DUELO FINAL',
    // Manual
    'config_desc': 'Puedes gestionar tus preferencias de anuncios y configuración de privacidad en cualquier momento para adaptar la experiencia a tu gusto.',
    'normas_titulo': '🎯 Normas Básicas',
    'normas_desc': 'El objetivo es descubrir quién es el Impostor. Todos los jugadores reciben una palabra secreta, excepto el Impostor. Por turnos, cada jugador dice una palabra o frase corta relacionada con la palabra secreta. ¡Cuidado! Si eres demasiado obvio, el Impostor adivinará la palabra y ganará. Si eres demasiado críptico, los demás pensarán que tú eres el Impostor.',
    'mimica_titulo': '🎭 Modo Mímica',
    'mimica_desc': '¡Está prohibido hablar! En este modo, los jugadores deben describir su palabra secreta únicamente mediante gestos. El Impostor debe estar muy atento para imitar los movimientos de los demás e intentar deducir de qué se trata sin que le pillen.',
    'debate_titulo': '⏱️ Tiempo de Debate',
    'debate_desc': 'Cuando el temporizador llega a cero o todos han dado su pista, comienza el debate. Discutid abiertamente quién creéis que miente o quién ha dado una pista sospechosa. Al finalizar el tiempo de discusión, se procederá a la votación.',
    'pistas_titulo': '💡 Pistas del Impostor',
    'pistas_desc': 'Si esta opción está activa, el Impostor recibirá una ayuda visual sobre la categoría de la palabra (ej: "Es una comida" o "Es un lugar"). Esto le servirá para mimetizarse mejor y tener una oportunidad de sobrevivir las primeras rondas.',
    'ruleta_titulo': '☠️ Ruleta de Castigos',
    'ruleta_desc': 'Si los jugadores expulsan a un inocente, o si el impostor es finalmente cazado, el expulsado deberá girar la ruleta y cumplir el castigo físico o social que aparezca en pantalla. ¡Asegúrate de haber añadido castigos divertidos en la configuración!',
  },
  'EN': {
    'titulo': 'THE IMPOSTOR',
    'subtitulo': 'WHO IS THE IMPOSTOR?',
    'nueva_partida': 'NEW GAME',
    'ajustes': 'SETTINGS',
    'idioma': 'LANGUAGE',
    'vibracion': 'VIBRATION',
    'vibracion_on': 'ON',
    'vibracion_off': 'OFF',
    'confirmar': 'GOT IT',
    'manual_title': 'GAME MANUAL',
    // Config
    'config_jugadores': 'PLAYERS',
    'config_impostores': 'IMPOSTORS',
    'config_pistas': 'Show Tips to Impostor',
    'config_mimica': 'Mimic Mode',
    'config_prob': 'PROBABILITY %',
    'config_tiempo': 'Debate Time',
    'config_segundos': 'SECONDS',
    'config_ruleta': 'Punishment Wheel',
    'config_inocentes': 'Punish Innocents',
    'config_lista_castigos': 'PUNISHMENT LIST',
    'config_add_castigo': 'Ex: Do 10 pushups',
    'btn_siguiente': 'NEXT',
    'btn_empezar': 'START',
    // Game
    'quien_juega': 'WHO IS PLAYING?',
    'categoria_title': 'CATEGORY',
    'mantener_pulsado': 'HOLD TO REVEAL',
    'confidencial': 'CONFIDENTIAL',
    'confirmar_pasar': 'CONFIRM & PASS',
    'tu_rol': 'YOUR ROLE',
    'tu_palabra': 'YOUR WORD',
    'rol_impostor': 'IMPOSTOR',
    'debatir': 'DEBATE TIME!',
    'empieza': 'STARTS',
    'votar_impostor': 'VOTE THE IMPOSTOR',
    'repetir_partida': 'PLAY AGAIN',
    'finalizar': 'FINISH',
    // Voting
    'pasa_movil': 'PASS THE PHONE TO:',
    'lo_tengo': 'I HAVE IT',
    'quien_es_imp': 'WHO IS THE IMPOSTOR?',
    'eliminado': 'ELIMINATED',
    'era_inocente': 'WAS INNOCENT',
    'cazado': 'CAUGHT!',
    'victoria': 'IMPOSTOR CAUGHT!',
    'duelo': 'FINAL DUEL',
    // Manual
    'config_desc': 'You can manage your ad preferences and privacy settings at any time to tailor the experience to your liking.',
    'normas_titulo': '🎯 Basic Rules',
    'normas_desc': 'The goal is to find the Impostor. All players get a secret word except the Impostor. In turns, each player says a word or short phrase related to the secret word. Be careful! If you are too obvious, the Impostor will guess the word and win. If you are too cryptic, others will think you are the Impostor.',
    'mimica_titulo': '🎭 Mimic Mode',
    'mimica_desc': 'Talking is strictly forbidden! In this mode, players must describe their secret word using only gestures. The Impostor must pay close attention to imitate others\' movements and try to deduce the word without getting caught.',
    'debate_titulo': '⏱️ Debate Time',
    'debate_desc': 'When the timer reaches zero or everyone has given their clue, the debate begins. Discuss openly who you think is lying or who gave a suspicious clue. Once the discussion ends, the voting stage will begin.',
    'pistas_titulo': '💡 Impostor Tips',
    'pistas_desc': 'If this option is enabled, the Impostor will receive a visual hint about the category of the word (e.g., "It\'s a food" or "It\'s a place"). This helps them blend in better and gives them a chance to survive the early rounds.',
    'ruleta_titulo': '☠️ Punishment Wheel',
    'ruleta_desc': 'If the players kick out an innocent person, or if the Impostor is finally caught, the eliminated player must spin the wheel and perform the physical or social punishment shown on screen. Make sure you added fun punishments in the settings!',
  }
};

class _JuegoImpostorState extends State<JuegoImpostor> with TickerProviderStateMixin {
  // --- VARIABLES DE ESTADO ---
  String pantallaActual = 'HOME';
  int numJugadores = 3;
  int numImpostores = 1;
  bool mostrarPistas = true;
  bool permitirMimica = false;
  int probabilidadMimica = 50; 
  bool esRondaMimica = false;
  bool activarCastigos = false;
  bool castigarInocentes = false;
  bool activarTiempo = false;
  int tiempoConfigurado = 60; 
  int tiempoRestante = 60;
  Timer? _timerDebate;
  String idioma = 'ES'; // Por defecto Español
bool vibracionActiva = true; // Parámetro extra

  List<PlayerModel> jugadoresPartida = [];
  List<PlayerModel> jugadoresGuardados = [];
  List<bool> eliminados = []; 
  String categoriaSeleccionada = 'Aleatorio';
  String palabraSecreta = "";
  String pistaSecreta = "";
  List<int> indicesImpostores = [];
  int jugadorActualIndice = 0;
  bool viendoPalabra = false; 
  bool tarjetaEstrenada = false; 
  bool palabraVista = false; 
  String empiezaJugador = "";

  List<int> conteoVotos = [];
  int jugadorVotandoIndex = 0;
  List<String> listaCastigos = []; 
  TextEditingController castigoController = TextEditingController();
  String castigoFinal = "";
  bool girandoRuleta = false;
  bool fueImpostorCazado = false;
  bool superCastigosDesbloqueados = false;

  // --- DATOS DINÁMICOS DIARIOS ---
  String categoriaDelDia = "";
  Map<String, String>? palabraDelDia;

  // --- ANIMACION RULETA ---
  late AnimationController _controllerRuleta;
  late Animation<double> _animacionRuleta;
  double _anguloActual = 0.0;
  List<String> _castigosVisibles = [];
  int _ultimaDivision = -1;

  // --- AUDIO ---
  final AudioPlayer _audioPlayer = AudioPlayer();

  void _reproducirSonido(String nombre) async {
    try {
      await _audioPlayer.play(AssetSource('assets/audio/$nombre.mp3'));
    } catch (e) {
      debugPrint("Error de audio: $e");
    }
  }

  void _vibrar({int duration = 50}) async {
    if (vibracionActiva && !kIsWeb) {
      bool? hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        Vibration.vibrate(duration: duration);
      }
    }
  }

  // --- PUBLICIDAD ---
  BannerAd? _bannerAd;
  bool _bannerListo = false;
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  bool _rewardedCargando = false;

  List<String> categoriasBloqueadas = [
    'Adultos', 'Terror', 'Cultura Friki', 'Marcas Famosas', 
    'Países del Mundo', 'Súper Lujo', 'Música y Leyendas', 
    'Superhéroes', 'Años 80 y 90'
  ];

  @override
  void initState() {
    super.initState();
    _cargarDatosLocales();
    _obtenerDatosDiarios();
    
    // Inicializar Animación Ruleta
    _controllerRuleta = AnimationController(vsync: this, duration: const Duration(seconds: 4));
    _animacionRuleta = CurvedAnimation(parent: _controllerRuleta, curve: Curves.decelerate);
    
    _controllerRuleta.addListener(() {
      setState(() {
        _anguloActual = _animacionRuleta.value * (12 * pi + Random().nextDouble() * pi); // Vueltas aleatorias
        if (_castigosVisibles.isNotEmpty) {
          double segment = (2 * pi) / _castigosVisibles.length;
          int currentSegment = (_anguloActual / segment).floor();
          if (currentSegment != _ultimaDivision) {
            _reproducirSonido('click');
            _vibrar(duration: 10);
            _ultimaDivision = currentSegment;
          }
        }
      });
    });

    _controllerRuleta.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          girandoRuleta = false;
          // Calcular el castigo final basándonos en el ángulo final
          if (_castigosVisibles.isNotEmpty) {
            double anguloNormalizado = _anguloActual % (2 * pi);
            double segment = (2 * pi) / _castigosVisibles.length;
            int index = ((2 * pi - anguloNormalizado) / segment).floor() % _castigosVisibles.length;
            castigoFinal = _castigosVisibles[index];
          }
        });
        _reproducirSonido('success');
        _vibrar(duration: 300);
      }
    });

    // Solo cargamos anuncios si ya se ha inicializado el SDK después del consentimiento
    Future.delayed(Duration(seconds: 3), () {
      if (!kIsWeb) {
        _cargarBanner();
        _cargarInterstitial();
        _cargarRewarded();
      }
    });
  }

  @override
  void dispose() {
    _timerDebate?.cancel();
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    _controllerRuleta.dispose();
    super.dispose();
  }

  // --- LÓGICA DE ANUNCIOS ---
  void _cargarBanner() {
  if (kIsWeb) return; // Detiene la función si detecta que es Web

  _bannerAd = BannerAd(
    adUnitId: kReleaseMode 
      ? 'ca-app-pub-3207283705047602/5913524774' 
      : 'ca-app-pub-3940256099942544/6300978111',
    size: AdSize.banner,
    request: AdRequest(),
    listener: BannerAdListener(
      onAdLoaded: (_) => setState(() => _bannerListo = true),
      onAdFailedToLoad: (ad, err) { ad.dispose(); },
    ),
  )..load();
}

  void _cargarInterstitial() {
  if (kIsWeb) return; // Detiene la función si es Web

  InterstitialAd.load(
    adUnitId: kReleaseMode 
      ? 'ca-app-pub-3207283705047602/1170859205' 
      : 'ca-app-pub-3940256099942544/1033173712',
    request: AdRequest(),
    adLoadCallback: InterstitialAdLoadCallback(
      onAdLoaded: (ad) {
        _interstitialAd = ad;
        _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
          onAdDismissedFullScreenContent: (ad) { ad.dispose(); _cargarInterstitial(); },
          onAdFailedToShowFullScreenContent: (ad, err) { ad.dispose(); _cargarInterstitial(); },
        );
      },
      onAdFailedToLoad: (err) => _interstitialAd = null,
    ),
  );
}

  void _mostrarInterstitial(String destino) {
    if (_interstitialAd != null) {
      _interstitialAd!.show();
      _interstitialAd = null; 
    }
    setState(() => pantallaActual = destino);
  }

  void _cargarRewarded() {
  if (kIsWeb) return; // Detiene la función si es Web

  if (_rewardedCargando) return;
  setState(() => _rewardedCargando = true);
  RewardedAd.load(
    adUnitId: kReleaseMode 
      ? 'ca-app-pub-3207283705047602/9843556142' 
      : 'ca-app-pub-3940256099942544/5224354917',
    request: AdRequest(),
    rewardedAdLoadCallback: RewardedAdLoadCallback(
      onAdLoaded: (ad) {
        setState(() { _rewardedAd = ad; _rewardedCargando = false; });
      },
      onAdFailedToLoad: (err) {
        setState(() { _rewardedAd = null; _rewardedCargando = false; });
        Future.delayed(Duration(seconds: 5), () => _cargarRewarded());
      },
      ),
    );
  }

  void _confirmarDesbloqueo(String cat) {
  int tiempoWeb = 15; // Segundos de espera en web
  Timer? timerWeb;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => StatefulBuilder(
      builder: (context, setStateDialog) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1B282D),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          title: const Text("Contenido Premium", 
            style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(kIsWeb 
                ? "Para desbloquear '$cat', espera unos segundos mientras cargamos el contenido." 
                : "Mira un video para desbloquear '$cat'."),
              const SizedBox(height: 20),
              if (_rewardedCargando || (kIsWeb && timerWeb != null))
                const CircularProgressIndicator(color: Colors.amber),
              if (kIsWeb && timerWeb != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text("Cargando: $tiempoWeb s", style: const TextStyle(color: Colors.amber)),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                timerWeb?.cancel();
                Navigator.pop(context);
              }, 
              child: const Text("CANCELAR")
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber, 
                shape: const StadiumBorder()
              ),
              onPressed: (kIsWeb && timerWeb != null) ? null : () {
                if (kIsWeb) {
                  // --- LÓGICA PARA WEB ---
                  timerWeb = Timer.periodic(const Duration(seconds: 1), (t) {
                    setStateDialog(() {
                      if (tiempoWeb > 0) {
                        tiempoWeb--;
                      } else {
                        t.cancel();
                        Navigator.pop(context);
                        setState(() {
                          categoriasBloqueadas.remove(cat);
                          categoriaSeleccionada = cat;
                        });
                      }
                    });
                  });
                } else {
                  // --- LÓGICA PARA MÓVIL (Lo que ya tenías) ---
                  if (_rewardedAd != null) {
                    Navigator.pop(context);
                    _rewardedAd!.show(onUserEarnedReward: (ad, reward) {
                      setState(() {
                        categoriasBloqueadas.remove(cat);
                        categoriaSeleccionada = cat;
                      });
                      _cargarRewarded();
                    });
                  } else {
                    _cargarRewarded();
                    setStateDialog(() {});
                  }
                }
              },
              child: Text(kIsWeb ? "DESBLOQUEAR" : "VER VIDEO", 
                style: const TextStyle(color: Colors.black)),
            ),
          ],
        );
      },
    ),
  );
}

void _confirmarDesbloqueoSuperCastigos() {
  int tiempoWeb = 15;
  Timer? timerWeb;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => StatefulBuilder(
      builder: (context, setStateDialog) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1B282D),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          title: const Text("PACK SUPER CASTIGOS", 
            style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(kIsWeb 
                ? "Para desbloquear el pack premium, espera unos segundos." 
                : "Mira un video para desbloquear 8 castigos extremos."),
              const SizedBox(height: 20),
              if (_rewardedCargando || (kIsWeb && timerWeb != null))
                const CircularProgressIndicator(color: Colors.redAccent),
              if (kIsWeb && timerWeb != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text("Cargando: $tiempoWeb s", style: const TextStyle(color: Colors.redAccent)),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                timerWeb?.cancel();
                Navigator.pop(context);
              }, 
              child: const Text("CANCELAR")
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent, 
                shape: const StadiumBorder()
              ),
              onPressed: (kIsWeb && timerWeb != null) ? null : () {
                if (kIsWeb) {
                  timerWeb = Timer.periodic(const Duration(seconds: 1), (t) {
                    setStateDialog(() {
                      if (tiempoWeb > 0) {
                        tiempoWeb--;
                      } else {
                        t.cancel();
                        Navigator.pop(context);
                        _aplicarSuperCastigos();
                      }
                    });
                  });
                } else {
                  if (_rewardedAd != null) {
                    Navigator.pop(context);
                    _rewardedAd!.show(onUserEarnedReward: (ad, reward) {
                      _aplicarSuperCastigos();
                      _cargarRewarded();
                    });
                  } else {
                    _cargarRewarded();
                    setStateDialog(() {});
                  }
                }
              },
              child: Text(kIsWeb ? "DESBLOQUEAR" : "VER VIDEO", 
                style: const TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    ),
  );
}

void _aplicarSuperCastigos() {
  setState(() {
    superCastigosDesbloqueados = true;
    for (var sc in superCastigos) {
      String castigo = idioma == 'ES' ? sc['es']! : sc['en']!;
      if (!listaCastigos.contains(castigo)) {
        listaCastigos.add(castigo);
      }
    }
  });
  _reproducirSonido('success');
  _vibrar(duration: 500);
}

// --- PERSISTENCIA ---
Future<void> _cargarDatosLocales() async {
  final prefs = await SharedPreferences.getInstance();
  
  // Cargar Vibración e Idioma
  setState(() {
    vibracionActiva = prefs.getBool('vibracion') ?? true;
    idioma = prefs.getString('idioma') ?? 'ES';
  });

  // Cargar Jugadores Guardados
  String? playersJson = prefs.getString('jugadores_guardados');
  if (playersJson != null) {
    List<dynamic> decoded = jsonDecode(playersJson);
    setState(() {
      jugadoresGuardados = decoded.map((item) => PlayerModel.fromJson(item)).toList();
    });
  }

  // Inicializar partida por defecto
  _resetearPartidaConNombres();
}

void _resetearPartidaConNombres() {
  setState(() {
    jugadoresPartida = [];
    for (int i = 0; i < numJugadores; i++) {
        // Si tenemos jugadores guardados, los usamos por defecto
        if (i < jugadoresGuardados.length) {
          jugadoresPartida.add(jugadoresGuardados[i]);
        } else {
          jugadoresPartida.add(PlayerModel(
            id: DateTime.now().millisecondsSinceEpoch.toString() + i.toString(),
            name: "${idioma == 'ES' ? 'Jugador' : 'Player'} ${i + 1}",
            color: Colors.primaries[i % Colors.primaries.length],
          ));
        }
    }
  });
}

Future<void> _guardarJugador(PlayerModel player) async {
  final prefs = await SharedPreferences.getInstance();
  
  int index = jugadoresGuardados.indexWhere((p) => p.id == player.id);
  if (index >= 0) {
    jugadoresGuardados[index] = player;
  } else {
    jugadoresGuardados.add(player);
  }

  // Sincronizar con la partida actual si el jugador está en ella
  for (int i = 0; i < jugadoresPartida.length; i++) {
    if (jugadoresPartida[i].id == player.id) {
      jugadoresPartida[i] = player;
    }
  }

  String encoded = jsonEncode(jugadoresGuardados.map((p) => p.toJson()).toList());
  await prefs.setString('jugadores_guardados', encoded);
  setState(() {});
}

Future<void> _eliminarJugador(String id) async {
  final prefs = await SharedPreferences.getInstance();
  jugadoresGuardados.removeWhere((p) => p.id == id);
  String encoded = jsonEncode(jugadoresGuardados.map((p) => p.toJson()).toList());
  await prefs.setString('jugadores_guardados', encoded);
  setState(() {});
}

Widget _buildAvatar(PlayerModel player, {double size = 40}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: player.color.withOpacity(0.8), 
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: player.color.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipOval(
        child: player.imagePath != null && player.isCustomPhoto
            ? Image.file(File(player.imagePath!), fit: BoxFit.cover)
            : _buildInitialAvatar(player, size),
      ),
    );
  }

Widget _buildInitialAvatar(PlayerModel player, double size) {
  return Center(
    child: Text(
      player.name.isNotEmpty ? player.name[0].toUpperCase() : "?",
      style: TextStyle(color: player.color, fontWeight: FontWeight.bold, fontSize: size * 0.5),
    ),
  );
}

Future<String?> _tomarFoto() async {
  final ImagePicker picker = ImagePicker();
  try {
    final XFile? photo = await picker.pickImage(source: ImageSource.camera, maxWidth: 400, maxHeight: 400);
    if (photo == null) return null;

    final directory = await getApplicationDocumentsDirectory();
    final String fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final String path = '${directory.path}/$fileName';
    
    await photo.saveTo(path);
    return path;
  } catch (e) {
    debugPrint("Error tomando foto: $e");
    return null;
  }
}

void _obtenerDatosDiarios() {
  DateTime now = DateTime.now();
  int seed = now.year * 10000 + now.month * 100 + now.day;
  Random r = Random(seed);

  List<String> keys = categorias.keys.toList();
  // No queremos que la categoría del día sea de las bloqueadas si es posible
  List<String> validas = keys.where((k) => !categoriasBloqueadas.contains(k)).toList();
  if (validas.isEmpty) validas = keys;

  categoriaDelDia = validas[r.nextInt(validas.length)];
  List<Map<String, String>> lista = categorias[categoriaDelDia]!;
  palabraDelDia = lista[r.nextInt(lista.length)];
}

  // --- NAVEGACIÓN ---
  void volverAtras() {
    _timerDebate?.cancel();
    setState(() {
      switch (pantallaActual) {
        case 'CONFIG': pantallaActual = 'HOME'; break;
        case 'NOMBRES': pantallaActual = 'CONFIG'; break;
        case 'CATEGORIA': pantallaActual = 'NOMBRES'; break;
        case 'REVELAR': pantallaActual = 'CATEGORIA'; break;
        default: pantallaActual = 'HOME';
      }
    });
  }

  void mostrarManualDeJuego(BuildContext context, String idiomaActual) {
  showDialog(
    context: context,
    barrierDismissible: false, // Obliga a usar el botón de cerrar
    builder: (BuildContext context) {
      return Dialog(
        backgroundColor: Colors.transparent, // Fondo transparente para usar el nuestro
        insetPadding: const EdgeInsets.all(15), // Márgenes externos
        child: ManualWidget(idioma: idiomaActual), // <--- PASAMOS EL IDIOMA AQUÍ
      );
    },
  );
}

  // --- LÓGICA DE JUEGO ---
 void prepararPartida({bool reiniciarTotal = true}) {
  setState(() {
    // 1. SIEMPRE elegimos    // Asignar impostores
    indicesImpostores = [];
    while (indicesImpostores.length < numImpostores) {
      int r = Random().nextInt(numJugadores);
      if (!indicesImpostores.contains(r)) indicesImpostores.add(r);
    }
    
    empiezaJugador = jugadoresPartida[Random().nextInt(numJugadores)].name;
    
    // 2. SIEMPRE reseteamos los eliminados para que todos vuelvan a jugar
    eliminados = List.generate(numJugadores, (_) => false);

    Random r = Random();
    String cat = categoriaSeleccionada;
    if (cat == 'Aleatorio') {
      // 30% de probabilidad para la categoría del día si está disponible
      if (categoriaDelDia.isNotEmpty && r.nextInt(100) < 30) {
        cat = categoriaDelDia;
      } else {
        // Aleatorio solo escoge entre las categorías básicas desbloqueadas
        List<String> basicas = categorias.keys.where((k) => !categoriasBloqueadas.contains(k)).toList();
        if (basicas.isEmpty) basicas = categorias.keys.toList(); // Fallback por si acaso
        cat = basicas[r.nextInt(basicas.length)];
      }
    }
    
    // Buscar la palabra en el mapa correspondiente
    List<Map<String, String>> lista = (categorias[cat] ?? categoriasDificiles[cat])!;
    
    Map<String, String> item;
    // Si la categoría coincide con el día, hay un 40% de que salga la palabra del día
    if (cat == categoriaDelDia && palabraDelDia != null && r.nextInt(100) < 40) {
      item = palabraDelDia!;
    } else {
      item = lista[r.nextInt(lista.length)];
    }
    
    // Asignar palabra y pista (¡HABÍAN DESAPARECIDO EN LA ÚLTIMA EDICIÓN!)
    palabraSecreta = (idioma == 'ES' ? item['palabra'] : item['palabra_en'])!;
    pistaSecreta = (idioma == 'ES' ? item['pista'] : item['pista_en'])!;
    
    // ------------------------------

    // 4. Quién empieza
    List<int> vivos = [];
    for (int i = 0; i < numJugadores; i++) if (!eliminados[i]) vivos.add(i);
    empiezaJugador = jugadoresPartida[vivos[Random().nextInt(vivos.length)]].name;

    // 5. Resetear estado de la interfaz
    esRondaMimica = permitirMimica && (Random().nextInt(100) < probabilidadMimica);
    jugadorActualIndice = 0;
    tarjetaEstrenada = false;
    palabraVista = false;
    pantallaActual = 'REVELAR';
    _reproducirSonido('click');
    _vibrar();
  });
}
  void iniciarTemporizador() {
    _timerDebate?.cancel();
    if (!activarTiempo) return;
    setState(() => tiempoRestante = tiempoConfigurado);
    _timerDebate = Timer.periodic(Duration(seconds: 1), (t) {
      if (tiempoRestante > 0) setState(() => tiempoRestante--);
      else { t.cancel(); iniciarVotacion(); }
    });
  }

  void iniciarVotacion() {
    _timerDebate?.cancel();
    int vivosCount = eliminados.where((e) => !e).length;
    if (vivosCount <= 2) setState(() => pantallaActual = 'DUELO');
    else {
      setState(() {
        conteoVotos = List.generate(numJugadores, (_) => 0);
        jugadorVotandoIndex = 0;
        while (eliminados[jugadorVotandoIndex]) { jugadorVotandoIndex++; }
        pantallaActual = 'VOTACION_TURNO';
      });
    }
  }

  void registrarVoto(int index) {
    conteoVotos[index]++;
    int sig = jugadorVotandoIndex + 1;
    while (sig < numJugadores && eliminados[sig]) { sig++; }
    if (sig < numJugadores) setState(() { jugadorVotandoIndex = sig; pantallaActual = 'VOTACION_TURNO'; });
    else _finalizarVotacion();
  }

  void _finalizarVotacion() {
    int masVotado = conteoVotos.indexOf(conteoVotos.reduce(max));
    bool esImp = indicesImpostores.contains(masVotado);
    fueImpostorCazado = esImp;
    if (esImp) {
      _reproducirSonido('success');
      _vibrar(duration: 500);
      if (activarCastigos && listaCastigos.isNotEmpty) _lanzarRuleta();
      else setState(() => pantallaActual = 'VICTORIA');
    } else {
      _reproducirSonido('fail');
      _vibrar(duration: 300);
      if (activarCastigos && castigarInocentes && listaCastigos.isNotEmpty) _lanzarRuleta();
      else {
        setState(() { eliminados[masVotado] = true; pantallaActual = 'RESULTADOS_VOTO'; });
      }
    }
  }

  void _lanzarRuleta() {
  if (listaCastigos.isEmpty) return;
  
  // Seleccionar castigos aleatorios para la ruleta (máximo 12 para que quepan)
  List<String> temp = List.from(listaCastigos)..shuffle();
  _castigosVisibles = temp.take(12).toList();
  _ultimaDivision = -1;

  setState(() { 
    girandoRuleta = true; 
    pantallaActual = 'RULETA'; 
    castigoFinal = "";
  });
  
  _controllerRuleta.reset();
  _controllerRuleta.forward();
}

  // --- UI BASE ---
  Widget buildScreen(Widget child) {
    // Definimos qué pantallas NO permiten volver atrás para evitar trampas o errores
    bool bloquearAtras = pantallaActual == 'HOME' || 
                         pantallaActual == 'JUEGO' || 
                         pantallaActual == 'VOTACION_TURNO' || 
                         pantallaActual == 'VOTACION_ACCION' || 
                         pantallaActual == 'VICTORIA' ||
                         pantallaActual == 'DUELO' ||
                         girandoRuleta;

    return Scaffold(
      body: Container(
        width: double.infinity, height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.8, -0.8),
            radius: 1.5,
            colors: [Color(0xFF0F172A), Color(0xFF050B18)],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Center(child: AnimatedSwitcher(duration: Duration(milliseconds: 500), child: child)),
                  if (!bloquearAtras)
                    Positioned(top: 50, left: 20, child: IconButton(icon: Icon(Icons.arrow_back_ios_new, color: Colors.amber, size: 30), onPressed: volverAtras)),
                ],
              ),
            ),
            if (_bannerListo) Container(alignment: Alignment.center, width: _bannerAd!.size.width.toDouble(), height: _bannerAd!.size.height.toDouble(), child: AdWidget(ad: _bannerAd!)),
          ],
        ),
      ),
    );
  }

  Widget buildButton(String text, VoidCallback onPressed, {Color? color}) {
    final primary = color ?? const Color(0xFF7B61FF);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [primary, primary.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: primary.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          onPressed: () {
            _reproducirSonido('click');
            _vibrar();
            onPressed();
          },
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget vistaHome() {
    final primary = const Color(0xFF7B61FF);
    final cyan = const Color(0xFF00E5FF);

    return Container(
      // Ya no necesitamos el fondo aquí porque lo hereda de buildScreen. Solo dejamos el contenido.
      child: Stack(
        children: [
          // --- Contenido Principal ---
          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 60),
                  // Logo con sutil resplandor
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: primary.withOpacity(0.1),
                          blurRadius: 40,
                          spreadRadius: 10,
                        )
                      ],
                    ),
                    child: Image.asset(
                      'assets/images/logo.png',
                      height: 220,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "THE IMPOSTOR",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 48,
                      color: Colors.white,
                      letterSpacing: 8.0,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 40),
                  buildButton(
                    idioma == 'ES' ? "NUEVA PARTIDA" : "NEW GAME", 
                    () => setState(() => pantallaActual = 'CONFIG')
                  ),
                  const SizedBox(height: 15),
                  _buildDailyInfo(),
                  const SizedBox(height: 40),
                  Text(
                    idioma == 'ES' ? "¿QUIÉN ES EL IMPOSTOR?" : "WHO IS THE IMPOSTOR?",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.2),
                      fontSize: 10,
                      letterSpacing: 4,
                      fontWeight: FontWeight.w400
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Footer de Privacidad
                  GestureDetector(
                    onTap: () => _lanzarUrl('https://theimpostor.es/privacidad.html'), 
                    child: Text(
                      idioma == 'ES' ? "Política de Privacidad" : "Privacy Policy",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.15), 
                        fontSize: 10, 
                        decoration: TextDecoration.underline
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),

          // --- CAPA 2: Botonera Superior Derecha ---
          Positioned(
            top: 40,
            right: 20,
            child: Row(
              children: [
                _botonCircularHome(
                  Icons.question_mark_rounded,
                  idioma == 'ES' ? 'Reglas' : 'Rules',
                  () => mostrarManualDeJuego(context, idioma),
                ),
                const SizedBox(width: 15),
                _botonCircularHome(
                  Icons.group_add_rounded, 
                  idioma == 'ES' ? "JUGADORES" : "PLAYERS", 
                  () => setState(() => pantallaActual = 'GESTION_JUGADORES')
                ),
                const SizedBox(width: 15),
                _botonCircularHome(
                  Icons.settings_rounded,
                  idioma == 'ES' ? 'Ajustes' : 'Settings',
                  () => mostrarAjustes(
                    context,
                    idioma,
                    vibracionActiva,
                    (nuevo) => setState(() => idioma = nuevo),
                    (valor) => setState(() => vibracionActiva = valor),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyInfo() {
    if (palabraDelDia == null) return const SizedBox.shrink();
    final cyan = const Color(0xFF00E5FF);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // Glassmorphism effect
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: cyan.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.auto_awesome, color: cyan, size: 20),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        idioma == 'ES' ? "DESTACADO DEL DÍA" : "DAILY FEATURED",
                        style: TextStyle(
                          color: cyan.withOpacity(0.6),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _nombreCategoriaTraducida(categoriaDelDia).toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.white24),
              ],
            ),
          ),
        ),
      ),
    );
  }

// Helper para mantener los botones circulares con el mismo estilo
Widget _botonCircularHome(IconData icono, String tooltip, VoidCallback accion) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Material(
            color: Colors.white.withOpacity(0.05),
            child: IconButton(
              icon: Icon(icono, color: Colors.white70, size: 24),
              tooltip: tooltip,
              onPressed: accion,
            ),
          ),
        ),
      ),
    );
  }
  Widget vistaConfig() {
  var t = textos[idioma]!;
  final primary = const Color(0xFF7B61FF);

  return SafeArea(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      child: Column(
        children: [
          Text(
            t['ajustes']!.toUpperCase(), 
            style: GoogleFonts.outfit(
              fontSize: 26, 
              fontWeight: FontWeight.w900, 
              color: primary,
              letterSpacing: 2
            )
          ),
          const SizedBox(height: 10),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Column(
                children: [
                  _modernContainer(
                    child: Column(
                      children: [
                        _selector(t['config_jugadores']!, numJugadores, 3, 15, (v) {
                          setState(() {
                            numJugadores = v;
                            if (jugadoresPartida.length < v) {
                              int faltan = v - jugadoresPartida.length;
                              for (int i = 0; i < faltan; i++) {
                                jugadoresPartida.add(PlayerModel(
                                  id: DateTime.now().millisecondsSinceEpoch.toString() + (jugadoresPartida.length + i).toString(),
                                  name: "${idioma == 'ES' ? 'Jugador' : 'Player'} ${jugadoresPartida.length + i + 1}",
                                  color: Colors.primaries[(jugadoresPartida.length + i) % Colors.primaries.length],
                                ));
                              }
                            } else if (jugadoresPartida.length > v) {
                              jugadoresPartida = jugadoresPartida.sublist(0, v);
                            }
                            if (numImpostores >= v) numImpostores = v - 1;
                          });
                        }),
                        _selector(t['config_impostores']!, numImpostores, 1, numJugadores - 1, (v) => setState(() => numImpostores = v)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 15),

                  _modernContainer(
                    child: Column(
                      children: [
                        _switch(t['config_pistas']!, mostrarPistas, (v) => setState(() => mostrarPistas = v)),
                        _switch(t['config_mimica']!, permitirMimica, (v) => setState(() => permitirMimica = v)),
                        if (permitirMimica) 
                          _selector(t['config_prob']!, probabilidadMimica, 0, 100, (v) => setState(() => probabilidadMimica = v), step: 10),
                        _switch(t['config_tiempo']!, activarTiempo, (v) => setState(() => activarTiempo = v)),
                        if (activarTiempo) 
                          _selector(t['config_segundos']!, tiempoConfigurado, 15, 300, (v) => setState(() => tiempoConfigurado = v), step: 15),
                      ],
                    ),
                  ),

                  const SizedBox(height: 15),

                  _modernContainer(
                    borderColor: activarCastigos ? Colors.pinkAccent.withOpacity(0.3) : null,
                    child: Column(
                      children: [
                        _switch(t['config_ruleta']!, activarCastigos, (v) => setState(() => activarCastigos = v)),
                        if (activarCastigos) ...[
                          _switch(t['config_inocentes']!, castigarInocentes, (v) => setState(() => castigarInocentes = v)),
                          _editorCastigos(t),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          buildButton(t['btn_siguiente']!, () => setState(() => pantallaActual = 'NOMBRES')),
          const SizedBox(height: 5),
        ],
      ),
    ),
  );
}

  Widget _modernContainer({required Widget child, Color? borderColor}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: borderColor ?? Colors.white.withOpacity(0.08)),
      ),
      child: child,
    );
  }
  Widget _editorCastigos(Map<String, String> t) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.black26, 
      borderRadius: BorderRadius.circular(25), 
      border: Border.all(color: Colors.redAccent.withOpacity(0.3))
    ),
    child: Column(
      children: [
        Row(
          children: [
            const Icon(Icons.auto_awesome, color: Colors.redAccent, size: 20), 
            const SizedBox(width: 10), 
            // Título: LISTA DE CASTIGOS / PUNISHMENT LIST
            Text(t['config_lista_castigos']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))
          ]
        ),
        const SizedBox(height: 15),
        ...listaCastigos.map((c) => Container(
          margin: const EdgeInsets.only(bottom: 8), 
          padding: const EdgeInsets.only(left: 15), 
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(15)),
          child: Row(
            children: [
              Expanded(child: Text(c, style: const TextStyle(fontSize: 13, color: Colors.white70))), 
              IconButton(icon: const Icon(Icons.close, size: 18, color: Colors.redAccent), onPressed: () => setState(() => listaCastigos.remove(c)))
            ]
          ),
        )).toList(),
        const SizedBox(height: 10),
        TextField(
          controller: castigoController, 
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            filled: true, 
            fillColor: Colors.white.withOpacity(0.05), 
            // Hint: Ej: Hacer 10 flexiones / Ex: Do 10 pushups
            hintText: t['config_add_castigo']!, 
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none), 
            suffixIcon: IconButton(
              icon: const Icon(Icons.add_circle, color: Colors.redAccent), 
              onPressed: () {
                if (castigoController.text.isNotEmpty) {
                  setState(() { 
                    listaCastigos.add(castigoController.text.toUpperCase()); 
                    castigoController.clear(); 
                  });
                }
              }
            )
          ),
        ),
        if (!superCastigosDesbloqueados) ...[
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _confirmarDesbloqueoSuperCastigos,
            icon: const Icon(Icons.lock_open_rounded, color: Colors.white),
            label: Text(idioma == 'ES' ? "DESBLOQUEAR PACK PREMIUM" : "UNLOCK PREMIUM PACK"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
            ),
          ),
        ] else ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: Colors.greenAccent, size: 16),
              const SizedBox(width: 5),
              Text(idioma == 'ES' ? "PACK PREMIUM ACTIVADO" : "PREMIUM PACK ACTIVE", 
                style: const TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ],
    ),
  );
}

  // --- GESTIÓN DE JUGADORES (UI) ---

  void _mostrarEditorJugador(PlayerModel? player, {int? indexPartida, bool soloSesion = false}) {
    showDialog(
      context: context,
      builder: (context) => PlayerEditorDialog(
        player: player,
        idioma: idioma,
        onSave: (p) {
          if (indexPartida != null) {
            setState(() {
              jugadoresPartida[indexPartida] = p;
            });
          }
          if (!soloSesion) {
            _guardarJugador(p);
          }
        },
        tomarFoto: _tomarFoto,
      ),
    );
  }

  void _mostrarSeleccionFavoritos(int indexPartida) {
    final pActual = jugadoresPartida[indexPartida];
    bool esAmigo = jugadoresGuardados.any((amigo) => amigo.id == pActual.id);

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1B282D),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => Column(
        children: [
          const SizedBox(height: 20),
          Text(idioma == 'ES' ? "MIS AMIGOS" : "MY FRIENDS", style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 18)),
          const Divider(color: Colors.white10),
          
          if (!esAmigo) ...[
            ListTile(
              leading: const CircleAvatar(backgroundColor: Colors.amber, child: Icon(Icons.star, color: Colors.black)),
              title: Text(idioma == 'ES' ? "GUARDAR COMO AMIGO" : "SAVE AS FRIEND", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: Text(idioma == 'ES' ? "Aparecerá siempre en Gestión de Jugadores" : "Will always appear in Player Management", style: const TextStyle(color: Colors.white24, fontSize: 11)),
              onTap: () {
                Navigator.pop(context);
                _guardarJugador(pActual);
              },
            ),
            const Divider(color: Colors.white10),
          ],

          Expanded(
            child: jugadoresGuardados.isEmpty 
              ? Center(child: Text(idioma == 'ES' ? "No tienes amigos guardados todavía" : "No saved friends yet", style: const TextStyle(color: Colors.white38)))
              : ListView.builder(
                  itemCount: jugadoresGuardados.length,
                  itemBuilder: (context, i) {
                    final p = jugadoresGuardados[i];
                    bool yaEnPartida = jugadoresPartida.any((pj) => pj.id == p.id);
                    return ListTile(
                      leading: _buildAvatar(p, size: 45),
                      title: Text(p.name, style: TextStyle(color: yaEnPartida ? Colors.white24 : Colors.white, fontWeight: FontWeight.bold)),
                      trailing: yaEnPartida 
                          ? const Icon(Icons.check_circle, color: Colors.white10)
                          : const Icon(Icons.add_circle_outline, color: Colors.amber),
                      onTap: yaEnPartida ? null : () {
                        setState(() => jugadoresPartida[indexPartida] = p);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }

  Widget vistaNombres() {
    var t = textos[idioma]!;
    final primary = const Color(0xFF7B61FF);

    return Column(children: [
      const SizedBox(height: 80),
      Text(
        t['quien_juega']!.toUpperCase(), 
        style: GoogleFonts.outfit(
          fontSize: 32, 
          fontWeight: FontWeight.w900, 
          color: primary,
          letterSpacing: 2
        )
      ),
      const SizedBox(height: 10),
      Text(idioma == 'ES' ? "Toca un jugador para editarlo" : "Tap a player to edit", 
        style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.3), letterSpacing: 1.2)),
      
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20), 
          itemCount: numJugadores, 
          itemBuilder: (context, i) {
            final p = jugadoresPartida[i];
            bool esAmigo = jugadoresGuardados.any((amigo) => amigo.id == p.id);
            return Container(
              margin: const EdgeInsets.only(bottom: 15),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: esAmigo ? primary.withOpacity(0.4) : Colors.white.withOpacity(0.08),
                  width: esAmigo ? 1.5 : 1,
                ),
                boxShadow: esAmigo ? [
                  BoxShadow(color: primary.withOpacity(0.05), blurRadius: 10, spreadRadius: 1)
                ] : null,
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                leading: _buildAvatar(p, size: 55),
                title: Text(p.name.toUpperCase(), 
                  style: const TextStyle(
                    color: Colors.white, 
                    fontWeight: FontWeight.w800, 
                    letterSpacing: 2,
                    fontSize: 16
                  )),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        esAmigo ? Icons.star_rounded : Icons.star_border_rounded, 
                        color: esAmigo ? primary : Colors.white24
                      ),
                      onPressed: () => _mostrarSeleccionFavoritos(i),
                    ),
                    Icon(Icons.edit_note_rounded, color: Colors.white.withOpacity(0.1)),
                  ],
                ),
                onTap: () => _mostrarEditorJugador(p, indexPartida: i, soloSesion: true),
              ),
            );
          }
        )
      ),
      
      buildButton(idioma == 'ES' ? "CATEGORÍAS" : "CATEGORIES", 
        () => setState(() => pantallaActual = 'CATEGORIA')),
      const SizedBox(height: 20),
    ]);
  }

  Widget vistaGestionJugadores() {
    final primary = const Color(0xFF7B61FF);
    
    return Column(
      children: [
        const SizedBox(height: 80),
        Text(
          (idioma == 'ES' ? "MIS AMIGOS" : "MY FRIENDS").toUpperCase(), 
          style: GoogleFonts.outfit(
            fontSize: 32, 
            fontWeight: FontWeight.w900, 
            color: primary,
            letterSpacing: 2
          )
        ),
        const SizedBox(height: 10),
        Text(idioma == 'ES' ? "Gestiona quién juega habitualmente" : "Manage who usually plays", 
          style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.3), letterSpacing: 1.2)),
        
        Expanded(
          child: jugadoresGuardados.isEmpty 
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_add_disabled_rounded, size: 80, color: Colors.white.withOpacity(0.05)),
                    const SizedBox(height: 20),
                    Text(idioma == 'ES' ? "No hay jugadores guardados" : "No saved players", 
                      style: TextStyle(color: Colors.white.withOpacity(0.2))),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: jugadoresGuardados.length,
                itemBuilder: (context, i) {
                  final p = jugadoresGuardados[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 15),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      leading: _buildAvatar(p, size: 55),
                      title: Text(p.name.toUpperCase(), 
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                      subtitle: Text(idioma == 'ES' ? "VER PERFIL" : "VIEW PROFILE", 
                        style: TextStyle(color: primary.withOpacity(0.6), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      trailing: IconButton(
                        icon: Icon(Icons.delete_outline_rounded, color: Colors.pinkAccent.withOpacity(0.5), size: 24),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: const Color(0xFF0F172A),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                              title: Text(idioma == 'ES' ? "ELIMINAR" : "DELETE", style: const TextStyle(fontWeight: FontWeight.bold)),
                              content: Text(idioma == 'ES' ? "¿Borrar a ${p.name}?" : "Delete ${p.name}?"),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context), child: Text(idioma == 'ES' ? "NO" : "NO", style: const TextStyle(color: Colors.white38))),
                                TextButton(onPressed: () {
                                  _eliminarJugador(p.id);
                                  Navigator.pop(context);
                                }, child: Text(idioma == 'ES' ? "SÍ, BORRAR" : "YES, DELETE", style: const TextStyle(color: Colors.pinkAccent))),
                              ],
                            ),
                          );
                        },
                      ),
                      onTap: () => _mostrarEditorJugador(p),
                    ),
                  );
                },
              ),
        ),
        
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: buildButton(idioma == 'ES' ? "AÑADIR AMIGO" : "ADD FRIEND", 
            () => _mostrarEditorJugador(null), color: Colors.white.withOpacity(0.05)),
        ),
        const SizedBox(height: 20),
      ],
    );
  }


  String _nombreCategoriaTraducida(String cat) {
    if (idioma == 'ES') return cat;
    switch (cat) {
      case 'Aleatorio': return 'Random';
      case 'Animales': return 'Animals';
      case 'Comidas': return 'Food';
      case 'Objetos': return 'Objects';
      case 'Lugares': return 'Places';
      case 'Cine y TV': return 'Movies & TV';
      case 'Deportes': return 'Sports';
      case 'Profesiones': return 'Jobs';
      case 'Videojuegos': return 'Video Games';
      case 'Personajes Famosos': return 'Famous People';
      case 'Cosas de Casa': return 'Household items';
      case 'Adultos': return 'Adults (18+)';
      case 'Terror': return 'Horror';
      case 'Cultura Friki': return 'Geek Culture';
      case 'Marcas Famosas': return 'Famous Brands';
      case 'Países del Mundo': return 'Countries';
      case 'Súper Lujo': return 'Super Luxury';
      case 'Música y Leyendas': return 'Music Legends';
      case 'Superhéroes': return 'Superheroes';
      case 'Años 80 y 90': return '80s & 90s';
      case 'Objetos de Oficina': return 'Office items';
      case 'Mitología': return 'Mythology';
      case 'Instrumentos': return 'Instruments';
      case 'Conceptos Abstractos': return 'Abstract Concepts';
      case 'Ciencia Avanzada': return 'Advanced Science';
      case 'Arte y Literatura': return 'Art & Literature';
      default: return cat;
    }
  }

  Widget vistaCategoria() {
  var t = textos[idioma]!;

  List<String> bloqueadas = categoriasBloqueadas.toList();
  List<String> basicas = categorias.keys.where((c) => !bloqueadas.contains(c)).toList();
  List<String> dificilesLibres = categoriasDificiles.keys.where((c) => !bloqueadas.contains(c)).toList();
  
  // Orden: 1. Aleatorio, 2. Básicas, 3. Difíciles, 4. Bloqueadas (Anuncios)
  List<String> todas = ['Aleatorio'] + basicas + dificilesLibres + bloqueadas;
  List<String> dificilesTotales = categoriasDificiles.keys.toList(); // Para colorearlas moradas

  return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    // Título: CATEGORÍA / CATEGORY
    Text(t['categoria_title']!, 
      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.amber)),
    
    const SizedBox(height: 30),
  
  Expanded(
    child: SingleChildScrollView(
      child: Wrap(spacing: 12, runSpacing: 12, alignment: WrapAlignment.center, children: todas.map((cat) {
      bool lock = categoriasBloqueadas.contains(cat);
      bool sel = categoriaSeleccionada == cat;
      bool esDificil = dificilesTotales.contains(cat);
      
      return GestureDetector(
        onTap: () { if (lock) _confirmarDesbloqueo(cat); else setState(() => categoriaSeleccionada = cat); },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: sel ? (esDificil ? Colors.deepPurpleAccent : Colors.amber) : (cat == categoriaDelDia ? Colors.amber.withOpacity(0.1) : Colors.white10), 
            borderRadius: BorderRadius.circular(15), 
            border: Border.all(
              color: esDificil ? Colors.deepPurpleAccent : (cat == categoriaDelDia ? Colors.amber : (lock ? Colors.redAccent.withOpacity(0.5) : Colors.transparent)), 
              width: (cat == categoriaDelDia || esDificil) ? 2 : 1
            )
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (lock) const Icon(Icons.play_circle_fill, size: 16, color: Colors.redAccent),
            if (esDificil) const Icon(Icons.psychology, size: 16, color: Colors.purpleAccent),
            if (cat == categoriaDelDia && !sel) const Icon(Icons.auto_awesome, size: 14, color: Colors.amber),
            if (lock || (cat == categoriaDelDia && !sel) || esDificil) const SizedBox(width: 8),
            // Mostramos el nombre traducido
            Text(_nombreCategoriaTraducida(cat), 
              style: TextStyle(color: sel ? Colors.white : Colors.white70, fontWeight: (cat == categoriaDelDia || esDificil) ? FontWeight.bold : FontWeight.normal)),
          ]),
        ),
      );
  }).toList()),
    ),
  ),
  
  const SizedBox(height: 20),
  
  // Botón: EMPEZAR / START
  buildButton(t['btn_empezar']!, () => prepararPartida()),
  const SizedBox(height: 20),
]);
}
  Widget vistaRevelar() {
  var t = textos[idioma]!;
  bool imp = indicesImpostores.contains(jugadorActualIndice);
  final primary = const Color(0xFF7B61FF);
  final danger = const Color(0xFFFF2D55);

  return SafeArea(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      child: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 90), // Para que el botón flotante no tape el final
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 10),
                      _buildAvatar(jugadoresPartida[jugadorActualIndice], size: 60),
                      const SizedBox(height: 10),
                      Text(
                        jugadoresPartida[jugadorActualIndice].name.toUpperCase(), 
                        style: GoogleFonts.outfit(
                          fontSize: 22, 
                          color: Colors.white, 
                          letterSpacing: 4, 
                          fontWeight: FontWeight.w900
                        )
                      ),
                      const SizedBox(height: 8),
                      if (palabraDelDia != null && palabraSecreta == (idioma == 'ES' ? palabraDelDia!['palabra'] : palabraDelDia!['palabra_en']))
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00E5FF).withOpacity(0.1), 
                            borderRadius: BorderRadius.circular(20), 
                            border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.5))
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.auto_awesome, color: Color(0xFF00E5FF), size: 16),
                              const SizedBox(width: 8),
                              Text(
                                (idioma == 'ES' ? "PALABRA DEL DÍA" : "WORD OF THE DAY").toUpperCase(), 
                                style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 20),
                      
                      // Tarjeta restringida centralmente interactuable
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 280, maxHeight: 380),
                          child: SizedBox(
                            height: 380, // Fuerza la ocupación máxima para la animación
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: GestureDetector(
                                    onTap: () {
                                      if (!tarjetaEstrenada) {
                                        setState(() => tarjetaEstrenada = true);
                                        _reproducirSonido('click');
                                      }
                                    },
                                    onLongPressStart: (_) { 
                                      if (tarjetaEstrenada) {
                                        setState(() {
                                          viendoPalabra = true;
                                          palabraVista = true;
                                        }); 
                                        _reproducirSonido('reveal');
                                        _vibrar(duration: 100);
                                      }
                                    },
                                    onLongPressEnd: (_) => setState(() => viendoPalabra = false),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 300),
                                      decoration: BoxDecoration(
                                        color: viendoPalabra 
                                            ? (imp ? danger.withOpacity(0.15) : primary.withOpacity(0.15)) 
                                            : Colors.white.withOpacity(0.02),
                                        borderRadius: BorderRadius.circular(40),
                                        border: Border.all(
                                          color: viendoPalabra 
                                              ? (imp ? danger : primary) 
                                              : Colors.white.withOpacity(0.1), 
                                          width: 2
                                        ),
                                        boxShadow: viendoPalabra ? [
                                          BoxShadow(color: (imp ? danger : primary).withOpacity(0.1), blurRadius: 20, spreadRadius: 5)
                                        ] : null,
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(40),
                                        child: BackdropFilter(
                                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                          child: Center(
                                            child: viendoPalabra 
                                                ? _infoSecreta(imp) 
                                                : Column(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Icon(
                                                        Icons.fingerprint_rounded, 
                                                        size: 80, 
                                                        color: Colors.white.withOpacity(0.05)
                                                      ),
                                                      const SizedBox(height: 20),
                                                      Text(
                                                        !tarjetaEstrenada 
                                                            ? (idioma == 'ES' ? "TOCA PARA ABRIR" : "TAP TO OPEN")
                                                            : (idioma == 'ES' ? "MANTÉN PULSADO" : "HOLD TO REVEAL"),
                                                        style: TextStyle(
                                                          color: Colors.white.withOpacity(0.6), 
                                                          fontWeight: FontWeight.w900,
                                                          letterSpacing: 2,
                                                          fontSize: 14
                                                        )
                                                      ),
                                                    ],
                                                  )
                                          ),
                                        ),
                                      ),
                                    )
                                  ),
                                ),
                                
                                // Sobre moderno animado
                                AnimatedPositioned(
                                  duration: const Duration(milliseconds: 600),
                                  curve: Curves.easeOutBack,
                                  top: tarjetaEstrenada ? -400 : 0,
                                  left: 0, 
                                  right: 0, 
                                  bottom: tarjetaEstrenada ? 400 : 0,
                                  child: IgnorePointer(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [primary, primary.withOpacity(0.8)],
                                        ),
                                        borderRadius: BorderRadius.circular(40),
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.mark_as_unread_rounded, size: 60, color: Colors.white),
                                          const SizedBox(height: 20),
                                          Text(
                                            t['confidencial']!.toUpperCase(),
                                            style: GoogleFonts.outfit(
                                              fontSize: 24,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.white,
                                              letterSpacing: 4
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          // Botón inferior - SIEMPRE visible flotando sobre el contenido
          if (tarjetaEstrenada && palabraVista)
            Positioned(
              left: 0,
              right: 0,
              bottom: 15,
              child: buildButton(
                idioma == 'ES' ? "SIGUIENTE" : "NEXT", 
                () {
                  if (jugadorActualIndice < numJugadores - 1) {
                    setState(() {
                      jugadorActualIndice++;
                      tarjetaEstrenada = false;
                      viendoPalabra = false; // Por si acaso
                      palabraVista = false;
                    });
                    _reproducirSonido('click');
                    _vibrar();
                  } else {
                    setState(() => pantallaActual = 'JUEGO');
                    iniciarTemporizador();
                  }
                }, 
              ),
            ),
        ],
      ),
    ),
  );
}

  Widget _infoSecreta(bool imp) {
  var t = textos[idioma]!;

  return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Icon(imp ? Icons.security_rounded : Icons.wb_incandescent_rounded,
        size: 60, color: imp ? Colors.redAccent : Colors.amber),
    const SizedBox(height: 20),
    // TU ROL / YOUR ROLE o TU PALABRA / YOUR WORD
    Text(imp ? t['tu_rol']! : t['tu_palabra']!, 
        style: const TextStyle(color: Colors.white38, fontSize: 12)),
    // IMPOSTOR o LA PALABRA SECRETA
    Text(imp ? t['rol_impostor']! : palabraSecreta.toUpperCase(), 
        textAlign: TextAlign.center, 
        style: TextStyle(color: imp ? Colors.redAccent : Colors.amber, fontSize: 32, fontWeight: FontWeight.w900)),
    // Pista si es impostor
    if (mostrarPistas && imp) 
      Text(pistaSecreta.toUpperCase(), 
          style: const TextStyle(color: Colors.redAccent, fontSize: 18, fontWeight: FontWeight.bold)),
    ]);
  }

  Widget vistaJuego() {
    var t = textos[idioma]!;
    final primary = const Color(0xFF7B61FF);
    final danger = const Color(0xFFFF2D55);

    return SafeArea(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (esRondaMimica) ...[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: danger.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: danger.withOpacity(0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.theater_comedy_rounded, color: danger),
              const SizedBox(width: 10),
              Text(
                (idioma == 'ES' ? "¡RONDA MÍMICA!" : "MIMIC ROUND!").toUpperCase(), 
                style: GoogleFonts.outfit(color: danger, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 2)
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
      ],
      
      Text(
        t['debatir']!.toUpperCase(), 
        style: GoogleFonts.outfit(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 4)
      ),
      const SizedBox(height: 30),
      
      _modernContainer(
        child: Column(
          children: [
            Text(
              t['empieza']!.toUpperCase(), 
              style: const TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2)
            ),
            const SizedBox(height: 10),
            Text(
              empiezaJugador.toUpperCase(), 
              style: GoogleFonts.outfit(color: const Color(0xFF00E5FF), fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 2)
            ),
          ],
        ),
      ),
    ],
  ),
)
        ),
        
        const SizedBox(height: 20),
        
        buildButton(t['votar_impostor']!, iniciarVotacion, color: danger),
        buildButton(t['repetir_partida']!, () { prepararPartida(); iniciarTemporizador(); }, color: Colors.white.withOpacity(0.05)),
        buildButton(t['finalizar']!, () => _mostrarInterstitial('HOME'), color: Colors.white.withOpacity(0.02)),
      ]),
    )
  );
}
  Widget vistaVotacionTurno() {
    var t = textos[idioma]!;
    final primary = const Color(0xFF7B61FF);
    final cyan = const Color(0xFF00E5FF);

    return SafeArea(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildAvatar(jugadoresPartida[jugadorVotandoIndex], size: 100),
                const SizedBox(height: 30),
                Icon(Icons.touch_app_rounded, size: 50, color: cyan.withOpacity(0.5)),
                const SizedBox(height: 20),
                Text(
                  t['pasa_movil']!.toUpperCase(), 
                  style: const TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2)
                ),
                const SizedBox(height: 10),
                Text(
                  jugadoresPartida[jugadorVotandoIndex].name.toUpperCase(), 
                  style: GoogleFonts.outfit(fontSize: 36, fontWeight: FontWeight.w900, color: primary, letterSpacing: 4)
                ),
              ],
            )
          )
        ),
        const SizedBox(height: 20),
        buildButton(t['lo_tengo']!, () => setState(() => pantallaActual = 'VOTACION_ACCION')),
      ]),
    )
  );
}

  Widget vistaVotacionAccion() {
    var t = textos[idioma]!;
    final cyan = const Color(0xFF00E5FF);

    return Column(children: [
      const SizedBox(height: 80),
      Text(
        t['quien_es_imp']!.toUpperCase(), 
        textAlign: TextAlign.center,
        style: GoogleFonts.outfit(
          fontSize: 32, 
          fontWeight: FontWeight.w900, 
          color: Colors.white,
          letterSpacing: 2
        )
      ),
      const SizedBox(height: 20),
      Text(idioma == 'ES' ? "Selecciona al sospechoso" : "Select the suspect", 
        style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.3), letterSpacing: 1.2)),
      
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          itemCount: numJugadores, 
          itemBuilder: (context, i) {
            if(i == jugadorVotandoIndex || eliminados[i]) return const SizedBox.shrink();
            final p = jugadoresPartida[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 15),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                leading: _buildAvatar(p, size: 50),
                title: Text(p.name.toUpperCase(), 
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                trailing: Icon(Icons.touch_app_rounded, color: cyan.withOpacity(0.4), size: 24),
                onTap: () => registrarVoto(i),
              ),
            );
          }
        )
      ),
    ]);
  }

  Widget vistaResultadosVoto() {
    var t = textos[idioma]!;
    int masVotado = conteoVotos.indexOf(conteoVotos.reduce(max));
    final danger = const Color(0xFFFF2D55);

    return SafeArea(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildAvatar(jugadoresPartida[masVotado], size: 120),
                const SizedBox(height: 30),
                Icon(Icons.person_off_rounded, size: 80, color: danger.withOpacity(0.5)),
                const SizedBox(height: 20),
                Text(
                  "${jugadoresPartida[masVotado].name} ${t['eliminado']!}".toUpperCase(), 
                  style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2)
                ),
                const SizedBox(height: 10),
                Text(t['era_inocente']!, style: const TextStyle(color: Colors.white38, fontSize: 14)),
              ],
            )
          )
        ),
        const SizedBox(height: 20),
        buildButton(t['confirmar']!, () { setState(() => pantallaActual = 'JUEGO'); iniciarTemporizador(); }),
      ]),
    )
  );
}

  Widget vistaVictoria() {
    var t = textos[idioma]!;
    int masVotado = conteoVotos.indexOf(conteoVotos.reduce(max));
    final cyan = const Color(0xFF00E5FF);
    final primary = const Color(0xFF7B61FF);

    return SafeArea(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildAvatar(jugadoresPartida[masVotado], size: 120),
                const SizedBox(height: 30),
                Icon(Icons.emoji_events_rounded, size: 100, color: cyan),
                const SizedBox(height: 20),
                Text(
                  t['victoria']!.toUpperCase(), 
                  style: GoogleFonts.outfit(fontSize: 48, fontWeight: FontWeight.w900, color: cyan, letterSpacing: 8)
                ),
                const SizedBox(height: 10),
                Text(
                  "${idioma == 'ES' ? 'ERA EL IMPOSTOR:' : 'IT WAS THE IMPOSTOR:'} ${jugadoresPartida[masVotado].name}".toUpperCase(), 
                  style: const TextStyle(fontSize: 14, color: Colors.white38, fontWeight: FontWeight.bold, letterSpacing: 2)
                ),
              ],
            )
          )
        ),
        const SizedBox(height: 20),
        buildButton(t['repetir_partida']!, () => prepararPartida(), color: primary),
        buildButton(idioma == 'ES' ? "VOLVER AL INICIO" : "BACK TO HOME", 
          () => _mostrarInterstitial('HOME'), color: Colors.white.withOpacity(0.05)),
      ]),
    )
  );
}

  Widget vistaRuleta() {
  var t = textos[idioma]!;
  final danger = const Color(0xFFFF2D55);
  final cyan = const Color(0xFF00E5FF);
  final primary = const Color(0xFF7B61FF);

    return SafeArea(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.gavel_rounded, size: 60, color: danger),
                const SizedBox(height: 10),
                Text(fueImpostorCazado 
                  ? (idioma == 'ES' ? "¡CAZADO!" : "CAUGHT!") 
                  : (idioma == 'ES' ? "¡INOCENTE!" : "INNOCENT!"), 
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.redAccent)
                ),
                
                const SizedBox(height: 20),
                
                // --- NUEVA RULETA VISUAL ---
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Transform.rotate(
                      angle: _anguloActual,
                      child: CustomPaint(
                        size: const Size(280, 280),
                        painter: RuletaPainter(castigos: _castigosVisibles),
                      ),
                    ),
                    // Puntero de la ruleta
                    Container(
                      height: 300,
                      alignment: Alignment.topCenter,
                      child: const Icon(Icons.arrow_drop_down_rounded, size: 50, color: Colors.amber),
                    ),
                    // Centro de la ruleta
                    Container(
                      width: 30, height: 30,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))]
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                
                // Cuadro de texto del castigo
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 500),
                  opacity: !girandoRuleta ? 1.0 : 0.4,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    padding: const EdgeInsets.all(20), 
                    decoration: BoxDecoration(
                      color: Colors.white10, 
                      borderRadius: BorderRadius.circular(20), 
                      border: Border.all(color: girandoRuleta ? Colors.white10 : Colors.redAccent)
                    ), 
                    child: Text(
                      girandoRuleta ? (idioma == 'ES' ? "GIRANDO..." : "SPINNING...") : castigoFinal, 
                      textAlign: TextAlign.center, 
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                    )
                  ),
                ),
              ],
            )
          )
        ),
        
        const SizedBox(height: 15),
        
        SizedBox(
          height: 70,
          child: (!girandoRuleta) 
            ? buildButton(t['confirmar']!, () { 
                if(fueImpostorCazado) setState(() => pantallaActual = 'VICTORIA'); 
                else { 
                  int mas = conteoVotos.indexOf(conteoVotos.reduce(max)); 
                  setState(() { eliminados[mas] = true; pantallaActual = 'RESULTADOS_VOTO'; }); 
                } 
              })
            : const SizedBox.shrink()
        ),
      ]),
    )
  );
}


 Widget vistaDuelo() {
  var t = textos[idioma]!;
  List<String> imps = [];
  for(int i in indicesImpostores) imps.add(jugadoresPartida[i].name);
  return SafeArea(
   child: Padding(
     padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
     child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
       Expanded(
         child: SingleChildScrollView(
           child: Column(
             mainAxisAlignment: MainAxisAlignment.center,
             children: [
               const Icon(Icons.flash_on_rounded, size: 80, color: Colors.amber),
               Text(t['duelo']!, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
               const SizedBox(height: 40),
               Text(idioma == 'ES' ? "EL IMPOSTOR ERA:" : "THE IMPOSTOR WAS:", style: const TextStyle(color: Colors.white38)),
               Text(imps.join(", ").toUpperCase(), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.redAccent)),
             ],
           )
         )
       ),
       const SizedBox(height: 20),
       buildButton(t['nueva_partida']!, () => _mostrarInterstitial('HOME')),
     ]),
   )
 );
}

  Widget _selector(String t, int v, int min, int max, Function(int) f, {int step = 1}) {
    return Column(children: [
      SizedBox(height: 15),
      Text(t, style: TextStyle(fontSize: 12, color: Colors.white54, letterSpacing: 2)),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        IconButton(icon: Icon(Icons.remove_circle_outline, color: Colors.amber), onPressed: () => v > min ? f(v - step) : null),
        Text("$v", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        IconButton(icon: Icon(Icons.add_circle_outline, color: Colors.amber), onPressed: () => v < max ? f(v + step) : null),
      ]),
    ]);
  }

  Widget _switch(String t, bool v, Function(bool) f) {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 40), child: SwitchListTile(title: Text(t, style: TextStyle(fontSize: 14)), value: v, onChanged: f, activeColor: Colors.amber));
  }

  void _lanzarUrl(String urlStr) async {
    final Uri url = Uri.parse(urlStr);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint("No se pudo abrir $urlStr");
    }
  }

  

  @override
  Widget build(BuildContext context) {
    switch (pantallaActual) {
      case 'CONFIG': return buildScreen(vistaConfig());
      case 'NOMBRES': return buildScreen(vistaNombres());
      case 'CATEGORIA': return buildScreen(vistaCategoria());
      case 'REVELAR': return buildScreen(vistaRevelar());
      case 'JUEGO': return buildScreen(vistaJuego());
      case 'VOTACION_TURNO': return buildScreen(vistaVotacionTurno());
      case 'VOTACION_ACCION': return buildScreen(vistaVotacionAccion());
      case 'RESULTADOS_VOTO': return buildScreen(vistaResultadosVoto());
      case 'RULETA': return buildScreen(vistaRuleta());
      case 'VICTORIA': return buildScreen(vistaVictoria());
      case 'DUELO': return buildScreen(vistaDuelo());
      case 'GESTION_JUGADORES': return buildScreen(vistaGestionJugadores());
      default: return buildScreen(vistaHome());
    }
  }
}

class PlayerEditorDialog extends StatefulWidget {
  final PlayerModel? player;
  final String idioma;
  final Function(PlayerModel) onSave;
  final Future<String?> Function() tomarFoto;

  const PlayerEditorDialog({
    super.key,
    this.player,
    required this.idioma,
    required this.onSave,
    required this.tomarFoto,
  });

  @override
  _PlayerEditorDialogState createState() => _PlayerEditorDialogState();
}

class _PlayerEditorDialogState extends State<PlayerEditorDialog> {
  late TextEditingController _nameController;
  late Color _selectedColor;
  String? _imagePath;
  late bool _isCustomPhoto;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.player?.name ?? "");
    _selectedColor = widget.player?.color ?? Colors.amber;
    _imagePath = widget.player?.imagePath;
    _isCustomPhoto = widget.player?.isCustomPhoto ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1B282D),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      title: Text(
        widget.player == null 
            ? (widget.idioma == 'ES' ? "NUEVO JUGADOR" : "NEW PLAYER") 
            : (widget.idioma == 'ES' ? "EDITAR JUGADOR" : "EDIT PLAYER"),
        style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () async {
                String? path = await widget.tomarFoto();
                if (path != null) {
                  setState(() {
                    _imagePath = path;
                    _isCustomPhoto = true;
                  });
                }
              },
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(
                      color: _selectedColor.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: _selectedColor, width: 3),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _imagePath != null && _isCustomPhoto
                        ? Image.file(File(_imagePath!), fit: BoxFit.cover)
                        : Center(child: Icon(Icons.person, size: 60, color: _selectedColor)),
                  ),
                  const CircleAvatar(
                    backgroundColor: Colors.amber,
                    radius: 15,
                    child: Icon(Icons.camera_alt, size: 18, color: Colors.black),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              // autofocus: true, // Eliminado por seguridad en emuladores
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: widget.idioma == 'ES' ? "Nombre" : "Name",
                labelStyle: const TextStyle(color: Colors.white54),
                enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: Colors.primaries.map((color) => GestureDetector(
                onTap: () => setState(() => _selectedColor = color),
                child: Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _selectedColor == color ? Colors.white : Colors.white24,
                      width: _selectedColor == color ? 2 : 1
                    ),
                  ),
                ),
              )).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context), 
          child: Text(widget.idioma == 'ES' ? "CANCELAR" : "CANCEL", style: const TextStyle(color: Colors.white54))
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
          onPressed: () {
            if (_nameController.text.trim().isEmpty) return;
            PlayerModel p = PlayerModel(
              id: widget.player?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
              name: _nameController.text.trim(),
              imagePath: _imagePath,
              color: _selectedColor,
              isCustomPhoto: _isCustomPhoto,
            );
            widget.onSave(p);
            Navigator.pop(context);
          },
          child: Text(widget.idioma == 'ES' ? "GUARDAR" : "SAVE", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

class RuletaPainter extends CustomPainter {
  final List<String> castigos;
  RuletaPainter({required this.castigos});

  @override
  void paint(Canvas canvas, Size size) {
    if (castigos.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final sweepAngle = (2 * pi) / castigos.length;
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < castigos.length; i++) {
      paint.color = Colors.primaries[i % Colors.primaries.length].withOpacity(0.8);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        i * sweepAngle,
        sweepAngle,
        true,
        paint,
      );

      // Dibujar texto del castigo
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(i * sweepAngle + sweepAngle / 2);
      
      final textPainter = TextPainter(
        text: TextSpan(
          text: castigos[i].length > 15 ? castigos[i].substring(0, 12) + "..." : castigos[i],
          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout(maxWidth: radius - 20);

      textPainter.paint(canvas, Offset(radius / 2 - textPainter.width / 2, -textPainter.height / 2));
      canvas.restore();
    }
    
    // Borde exterior
    final borderPaint = Paint()
      ..color = Colors.white24
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(center, radius, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _PulseIcon extends StatefulWidget {
  const _PulseIcon();
  @override
  State<_PulseIcon> createState() => _PulseIconState();
}

class _PulseIconState extends State<_PulseIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat(reverse: true);
  }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween(begin: 0.8, end: 1.2).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut)),
      child: const Icon(Icons.auto_awesome, color: Colors.amber, size: 18),
    );
  }
}