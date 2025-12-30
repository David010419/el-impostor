import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'datos.dart'; 
import 'package:flutter/foundation.dart'; 
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    unawaited(MobileAds.instance.initialize());
  }
  runApp(MaterialApp(
    title: 'Juego del Impostor',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      brightness: Brightness.dark,
      primaryColor: Colors.amber,
      hintColor: Colors.amberAccent,
      fontFamily: 'Segoe UI',
      scaffoldBackgroundColor: const Color(0xFF0F2027),
    ),
    home: JuegoImpostor(),
  ));
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
        color: const Color(0xFF1A2A30),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber, width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 15, offset: Offset(0, 5))
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
      backgroundColor: const Color(0xFF1A2A30),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20), 
        side: const BorderSide(color: Colors.amber)
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

class _JuegoImpostorState extends State<JuegoImpostor> {
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

  List<String> nombresJugadores = [];
  List<bool> eliminados = []; 
  String categoriaSeleccionada = 'Aleatorio';
  String palabraSecreta = "";
  String pistaSecreta = "";
  List<int> indicesImpostores = [];
  int jugadorActualIndice = 0;
  bool viendoPalabra = false; 
  bool tarjetaEstrenada = false; 
  String empiezaJugador = "";

  List<int> conteoVotos = [];
  int jugadorVotandoIndex = 0;
  List<String> listaCastigos = []; 
  TextEditingController castigoController = TextEditingController();
  String castigoFinal = "";
  bool girandoRuleta = false;
  bool fueImpostorCazado = false;

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
    nombresJugadores = List.generate(numJugadores, (i) => "Jugador ${i+1}");
    Future.delayed(Duration(seconds: 2), () {
      _cargarBanner();
      _cargarInterstitial();
      _cargarRewarded();
    });
  }

  @override
  void dispose() {
    _timerDebate?.cancel();
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
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
    // 1. SIEMPRE elegimos nuevos impostores
    indicesImpostores = [];
    while (indicesImpostores.length < numImpostores) {
      int r = Random().nextInt(numJugadores);
      if (!indicesImpostores.contains(r)) indicesImpostores.add(r);
    }

    // 2. SIEMPRE reseteamos los eliminados para que todos vuelvan a jugar
    eliminados = List.generate(numJugadores, (_) => false);

    // 3. Selección de la categoría y palabra secreta
    String cat = categoriaSeleccionada;
    if (cat == 'Aleatorio') {
      List<String> keys = categorias.keys
          .where((k) => !categoriasBloqueadas.contains(k))
          .toList();
      cat = keys[Random().nextInt(keys.length)];
    }
    
    final listaPalabras = categorias[cat]!;
    final item = listaPalabras[Random().nextInt(listaPalabras.length)];

    // --- CAMBIO PARA TRADUCCIÓN ---
    if (idioma == 'ES') {
      palabraSecreta = item['palabra']!;
      pistaSecreta = item['pista']!;
    } else {
      // Si el idioma es inglés, buscamos las claves '_en'
      // Usamos ?? como seguridad por si alguna palabra no tuviera traducción
      palabraSecreta = item['palabra_en'] ?? item['palabra']!;
      pistaSecreta = item['pista_en'] ?? item['pista']!;
    }
    // ------------------------------

    // 4. Quién empieza
    List<int> vivos = [];
    for (int i = 0; i < numJugadores; i++) if (!eliminados[i]) vivos.add(i);
    empiezaJugador = nombresJugadores[vivos[Random().nextInt(vivos.length)]];

    // 5. Resetear estado de la interfaz
    esRondaMimica = permitirMimica && (Random().nextInt(100) < probabilidadMimica);
    jugadorActualIndice = 0;
    tarjetaEstrenada = false;
    pantallaActual = 'REVELAR';
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
      if (activarCastigos && listaCastigos.isNotEmpty) _lanzarRuleta();
      else setState(() => pantallaActual = 'VICTORIA');
    } else {
      if (activarCastigos && castigarInocentes && listaCastigos.isNotEmpty) _lanzarRuleta();
      else {
        setState(() { eliminados[masVotado] = true; pantallaActual = 'RESULTADOS_VOTO'; });
      }
    }
  }

  void _lanzarRuleta() {
    setState(() { girandoRuleta = true; pantallaActual = 'RULETA'; });
    int saltos = 0;
    Timer.periodic(Duration(milliseconds: 100), (t) {
      setState(() => castigoFinal = listaCastigos[Random().nextInt(listaCastigos.length)]);
      saltos++;
      if (saltos > 15) { t.cancel(); setState(() => girandoRuleta = false); }
    });
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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
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

  Widget buildButton(String text, VoidCallback onPressed, {Color color = Colors.amber}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: color == Colors.amber ? Colors.black : Colors.white, minimumSize: Size(double.infinity, 55), shape: StadiumBorder(), elevation: 10),
        onPressed: onPressed, child: Text(text, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

Widget vistaHome() {
  return Stack(
    children: [
      // --- CAPA 1: Contenido Principal Centrado ---
      Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 300,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 25),
            Text(
              "THE IMPOSTOR",
              textAlign: TextAlign.center,
              style: GoogleFonts.staatliches(
                fontSize: 60,
                color: Colors.amber,
                letterSpacing: 4.0,
                fontWeight: FontWeight.normal,
              ),
            ),
            const SizedBox(height: 60),
            buildButton(
                idioma == 'ES' ? "NUEVA PARTIDA" : "NEW GAME", 
                () => setState(() => pantallaActual = 'CONFIG')),
            const SizedBox(height: 20),
            Text(
              idioma == 'ES' ? "¿QUIÉN ES EL IMPOSTOR?" : "WHO IS THE IMPOSTOR?",
              style: TextStyle(
                  color: Colors.amber.withOpacity(0.3),
                  fontSize: 12,
                  letterSpacing: 3,
                  fontWeight: FontWeight.w300),
            ),
          ],
        ),
      ),

      // --- CAPA 2: Botonera Superior Derecha ---
      Positioned(
        top: 40,
        right: 20,
        child: Row(
          children: [
            // Botón del Manual (Ayuda)
            _botonCircularHome(
              Icons.question_mark_rounded,
              idioma == 'ES' ? 'Reglas' : 'Rules',
              () => mostrarManualDeJuego(context, idioma),
            ),
            
            const SizedBox(width: 15), // Espacio entre botones
            
            // Botón de Configuración (Ajustes)
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
    ], // Cierre de la lista de hijos del Stack
  ); // Cierre del return Stack
} // Cierre de la función vistaHome

// Helper para mantener los botones circulares con el mismo estilo
Widget _botonCircularHome(IconData icono, String tooltip, VoidCallback accion) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.black.withOpacity(0.5),
      shape: BoxShape.circle,
      border: Border.all(color: Colors.amber.withOpacity(0.5), width: 2)
    ),
    child: IconButton(
      icon: Icon(icono, color: Colors.amber, size: 25),
      tooltip: tooltip,
      onPressed: accion,
    ),
  );
}
  Widget vistaConfig() {
  // Creamos el acceso directo a los textos según el idioma actual
  var t = textos[idioma]!;

  return SingleChildScrollView(
    padding: const EdgeInsets.symmetric(vertical: 60),
    child: Column(
      children: [
        // Título: AJUSTES / SETTINGS
        Text(t['ajustes']!, 
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.amber)),
        
        // Selectores traducidos
        _selector(t['config_jugadores']!, numJugadores, 3, 15, (v) {
          setState(() {
            numJugadores = v;
            if (nombresJugadores.length < v) {
              int faltan = v - nombresJugadores.length;
              nombresJugadores.addAll(List.generate(faltan, (i) => "Jugador ${nombresJugadores.length + i + 1}"));
            } else if (nombresJugadores.length > v) {
              nombresJugadores = nombresJugadores.sublist(0, v);
            }
            if (numImpostores >= v) numImpostores = v - 1;
          });
        }),

        _selector(t['config_impostores']!, numImpostores, 1, numJugadores - 1, (v) => setState(() => numImpostores = v)),

        // Switches traducidos
        _switch(t['config_pistas']!, mostrarPistas, (v) => setState(() => mostrarPistas = v)),
        
        _switch(t['config_mimica']!, permitirMimica, (v) => setState(() => permitirMimica = v)),
        
        if (permitirMimica) 
          _selector(t['config_prob']!, probabilidadMimica, 0, 100, (v) => setState(() => probabilidadMimica = v), step: 10),
        
        _switch(t['config_tiempo']!, activarTiempo, (v) => setState(() => activarTiempo = v)),
        
        if (activarTiempo) 
          _selector(t['config_segundos']!, tiempoConfigurado, 15, 300, (v) => setState(() => tiempoConfigurado = v), step: 15),
        
        _switch(t['config_ruleta']!, activarCastigos, (v) => setState(() => activarCastigos = v)),
        
        if (activarCastigos) ...[
          _switch(t['config_inocentes']!, castigarInocentes, (v) => setState(() => castigarInocentes = v)),
          _editorCastigos(t), // Pasamos 't' para traducir el interior del editor
        ],

        const SizedBox(height: 30),
        
        // Botón: SIGUIENTE / NEXT
        buildButton(t['btn_siguiente']!, () => setState(() => pantallaActual = 'NOMBRES')),
      ],
    ),
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
      ],
    ),
  );
}

  

  Widget vistaNombres() {
  var t = textos[idioma]!; // Acceso a las traducciones

  return Column(children: [
    const SizedBox(height: 100),
    // Título: ¿QUIÉN JUEGA? / WHO IS PLAYING?
    Text(t['quien_juega']!, 
      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.amber)),
    
    Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.all(30), 
        itemCount: numJugadores, 
        itemBuilder: (context, i) => Container(
          margin: const EdgeInsets.only(bottom: 15), 
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08), 
            borderRadius: BorderRadius.circular(20), 
            border: Border.all(color: Colors.white10)
          ),
          child: TextField(
            style: const TextStyle(color: Colors.white, fontSize: 18), 
            textAlign: TextAlign.center, 
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.person, color: Colors.amber), 
              // Hint: Jugador X / Player X
              hintText: "${idioma == 'ES' ? 'Jugador' : 'Player'} ${i + 1}", 
              border: InputBorder.none, 
              contentPadding: const EdgeInsets.symmetric(vertical: 15)
            ), 
            onChanged: (v) => nombresJugadores[i] = v
          ),
        )
      )
    ),
    
    // Botón: CATEGORÍAS / CATEGORIES
    buildButton(idioma == 'ES' ? "CATEGORÍAS" : "CATEGORIES", 
      () => setState(() => pantallaActual = 'CATEGORIA')),
    
    const SizedBox(height: 30),
  ]);
}

  Widget vistaCategoria() {
  var t = textos[idioma]!;

  // Mapa para traducir los nombres de las categorías en la interfaz
  final Map<String, String> nombresCat = {
    'Aleatorio': idioma == 'ES' ? 'Aleatorio' : 'Random',
    'Animales': idioma == 'ES' ? 'Animales' : 'Animals',
    'Comidas': idioma == 'ES' ? 'Comidas' : 'Food',
    'Objetos': idioma == 'ES' ? 'Objetos' : 'Objects',
    'Lugares': idioma == 'ES' ? 'Lugares' : 'Places',
    'Cine y TV': idioma == 'ES' ? 'Cine y TV' : 'Movies & TV',
    'Deportes': idioma == 'ES' ? 'Deportes' : 'Sports',
    'Profesiones': idioma == 'ES' ? 'Profesiones' : 'Jobs',
    'Videojuegos': idioma == 'ES' ? 'Videojuegos' : 'Video Games',
    'Personajes Famosos': idioma == 'ES' ? 'Personajes Famosos' : 'Famous People',
    'Cosas de Casa': idioma == 'ES' ? 'Cosas de Casa' : 'Household items',
    'Adultos': idioma == 'ES' ? 'Adultos' : 'Adults (18+)',
    'Terror': idioma == 'ES' ? 'Terror' : 'Horror',
    'Cultura Friki': idioma == 'ES' ? 'Cultura Friki' : 'Geek Culture',
    'Marcas Famosas': idioma == 'ES' ? 'Marcas Famosas' : 'Famous Brands',
    'Países del Mundo': idioma == 'ES' ? 'Países del Mundo' : 'Countries',
    'Súper Lujo': idioma == 'ES' ? 'Súper Lujo' : 'Super Luxury',
    'Música y Leyendas': idioma == 'ES' ? 'Música y Leyendas' : 'Music Legends',
    'Superhéroes': idioma == 'ES' ? 'Superhéroes' : 'Superheroes',
    'Años 80 y 90': idioma == 'ES' ? 'Años 80 y 90' : '80s & 90s',
  };

  List<String> todas = ['Aleatorio'] + categorias.keys.toList();

  return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    // Título: CATEGORÍA / CATEGORY
    Text(t['categoria_title']!, 
      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.amber)),
    
    const SizedBox(height: 30),
    
    Wrap(spacing: 12, runSpacing: 12, alignment: WrapAlignment.center, children: todas.map((cat) {
      bool lock = categoriasBloqueadas.contains(cat);
      bool sel = categoriaSeleccionada == cat;
      return GestureDetector(
        onTap: () { if (lock) _confirmarDesbloqueo(cat); else setState(() => categoriaSeleccionada = cat); },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: sel ? Colors.amber : Colors.white10, 
            borderRadius: BorderRadius.circular(15), 
            border: Border.all(color: lock ? Colors.redAccent.withOpacity(0.5) : Colors.transparent)
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (lock) const Icon(Icons.play_circle_fill, size: 16, color: Colors.redAccent),
            if (lock) const SizedBox(width: 8),
            // Mostramos el nombre traducido
            Text(nombresCat[cat] ?? cat, 
              style: TextStyle(color: sel ? Colors.black : Colors.white)),
          ]),
        ),
      );
    }).toList()),
    
    const SizedBox(height: 60),
    
    // Botón: EMPEZAR / START
    buildButton(t['btn_empezar']!, () => prepararPartida()),
  ]);
}
  Widget vistaRevelar() {
  var t = textos[idioma]!;
  bool imp = indicesImpostores.contains(jugadorActualIndice);

  return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Text(nombresJugadores[jugadorActualIndice].toUpperCase(), 
        style: const TextStyle(fontSize: 26, color: Colors.white, letterSpacing: 5)),
    const SizedBox(height: 30),
    Container(
        width: 300,
        height: 400,
        child: Stack(children: [
          Positioned.fill(
              child: GestureDetector(
                  onLongPressStart: (_) { if (tarjetaEstrenada) setState(() => viendoPalabra = true); },
                  onLongPressEnd: (_) => setState(() => viendoPalabra = false),
                  child: AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      decoration: BoxDecoration(
                          color: viendoPalabra ? (imp ? const Color(0xFF2D0A0A) : const Color(0xFF0A192D)) : Colors.white.withOpacity(0.02),
                          borderRadius: BorderRadius.circular(35),
                          border: Border.all(color: viendoPalabra ? (imp ? Colors.redAccent : Colors.amber) : Colors.white10, width: 2)),
                      child: Center(
                          child: viendoPalabra 
                              ? _infoSecreta(imp) 
                              : Text(tarjetaEstrenada ? t['mantener_pulsado']! : "", // TRADUCIDO
                                  style: const TextStyle(color: Colors.white24, fontWeight: FontWeight.bold)))))),
          
          // El "Sobre" Confidencial
          AnimatedPositioned(
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeInOutBack,
              top: tarjetaEstrenada ? 500 : 0,
              left: 0, right: 0, bottom: tarjetaEstrenada ? -500 : 0,
              child: GestureDetector(
                  onTap: () => setState(() => tarjetaEstrenada = true),
                  child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 400),
                      opacity: tarjetaEstrenada ? 0 : 1,
                      child: Container(
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(35),
                              gradient: const LinearGradient(colors: [Color(0xFF333333), Color(0xFF111111)]),
                              border: Border.all(color: Colors.amber.withOpacity(0.5))),
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.mail_lock_rounded, size: 60, color: Colors.amber),
                                const SizedBox(height: 25),
                                Text(t['confidencial']!, // TRADUCIDO
                                    style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, letterSpacing: 2))
                              ]))))),
        ])),
    const SizedBox(height: 40),
    Opacity(
        opacity: (!viendoPalabra && tarjetaEstrenada) ? 1.0 : 0.0,
        child: buildButton(t['confirmar_pasar']!, () { // TRADUCIDO
          if (!viendoPalabra && tarjetaEstrenada) {
            if (jugadorActualIndice < numJugadores - 1) {
              setState(() {
                jugadorActualIndice++;
                tarjetaEstrenada = false;
              });
            } else {
              setState(() => pantallaActual = 'JUEGO');
              iniciarTemporizador();
            }
          }
        }, color: Colors.white.withOpacity(0.05))),
  ]);
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
          style: const TextStyle(fontSize: 16, color: Colors.white70)),
  ]);
}

  Widget vistaJuego() {
  var t = textos[idioma]!;
  return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    if (activarTiempo) ...[
      Stack(alignment: Alignment.center, children: [
        SizedBox(width: 80, height: 80, 
          child: CircularProgressIndicator(value: tiempoRestante / tiempoConfigurado, strokeWidth: 8, color: tiempoRestante < 10 ? Colors.redAccent : Colors.amber)),
        Text("$tiempoRestante", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: tiempoRestante < 10 ? Colors.redAccent : Colors.white))
      ]), 
      const SizedBox(height: 20)
    ],
    if (esRondaMimica) 
      Text(idioma == 'ES' ? "¡RONDA MÍMICA!" : "MIMIC ROUND!", 
        style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 24)),
    
    Text(t['debatir']!, style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
    const SizedBox(height: 20),
    Text("${t['empieza']!}: ${empiezaJugador.toUpperCase()}", 
      style: const TextStyle(color: Colors.amber, fontSize: 22)),
    const SizedBox(height: 60),
    
    buildButton(t['votar_impostor']!, iniciarVotacion, color: Colors.redAccent),
    buildButton(t['repetir_partida']!, () { prepararPartida(); iniciarTemporizador(); }, color: Colors.white10),
    buildButton(t['finalizar']!, () => _mostrarInterstitial('HOME'), color: Colors.white.withOpacity(0.05)),
  ]);
}
 Widget vistaVotacionTurno() {
  var t = textos[idioma]!;
  return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    const Icon(Icons.touch_app_rounded, size: 80, color: Colors.amber),
    const SizedBox(height: 20),
    Text(t['pasa_movil']!),
    Text(nombresJugadores[jugadorVotandoIndex].toUpperCase(), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.amber)),
    const SizedBox(height: 50),
    buildButton(t['lo_tengo']!, () => setState(() => pantallaActual = 'VOTACION_ACCION')),
  ]);
}

 Widget vistaVotacionAccion() {
  var t = textos[idioma]!;
  return Column(children: [
    const SizedBox(height: 80),
    Text(t['quien_es_imp']!, style: const TextStyle(fontSize: 20, color: Colors.amber)),
    Expanded(child: ListView.builder(itemCount: numJugadores, itemBuilder: (context, i) {
      if(i == jugadorVotandoIndex || eliminados[i]) return const SizedBox.shrink();
      return buildButton(nombresJugadores[i], () => registrarVoto(i), color: Colors.white10);
    })),
  ]);
}

Widget vistaResultadosVoto() {
  var t = textos[idioma]!;
  int masVotado = conteoVotos.indexOf(conteoVotos.reduce(max));
  return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    const Icon(Icons.person_off_rounded, size: 80, color: Colors.redAccent),
    Text("${nombresJugadores[masVotado]} ${t['eliminado']!}", style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
    Text(t['era_inocente']!, style: const TextStyle(color: Colors.white54)),
    const SizedBox(height: 40),
    buildButton(t['confirmar']!, () { setState(() => pantallaActual = 'JUEGO'); iniciarTemporizador(); }),
  ]);
}

Widget vistaVictoria() {
  var t = textos[idioma]!;
  int masVotado = conteoVotos.indexOf(conteoVotos.reduce(max));
  return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    const Icon(Icons.emoji_events_rounded, size: 100, color: Colors.amber),
    Text(t['victoria']!, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.amber)),
    Text("${idioma == 'ES' ? 'Era' : 'It was'} ${nombresJugadores[masVotado]}", style: const TextStyle(fontSize: 18, color: Colors.white70)),
    const SizedBox(height: 50),
    buildButton(t['repetir_partida']!, () => prepararPartida()),
    buildButton(idioma == 'ES' ? "INICIO" : "HOME", () => _mostrarInterstitial('HOME'), color: Colors.white.withOpacity(0.05)),
  ]);
}

Widget vistaRuleta() {
  var t = textos[idioma]!;
  return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    const Icon(Icons.gavel_rounded, size: 80, color: Colors.redAccent),
    Text(fueImpostorCazado 
      ? (idioma == 'ES' ? "¡CAZADO!" : "CAUGHT!") 
      : (idioma == 'ES' ? "¡INOCENTE!" : "INNOCENT!"), 
      style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.redAccent)),
    const SizedBox(height: 30),
    Container(padding: const EdgeInsets.all(30), decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.redAccent)), 
      child: Text(castigoFinal, textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
    const SizedBox(height: 50),
    if(!girandoRuleta) buildButton(t['confirmar']!, () { 
      if(fueImpostorCazado) setState(() => pantallaActual = 'VICTORIA'); 
      else { 
        int mas = conteoVotos.indexOf(conteoVotos.reduce(max)); 
        setState(() { eliminados[mas] = true; pantallaActual = 'RESULTADOS_VOTO'; }); 
      } 
    }),
  ]);
}

 Widget vistaDuelo() {
  var t = textos[idioma]!;
  List<String> imps = [];
  for(int i in indicesImpostores) imps.add(nombresJugadores[i]);
  return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    const Icon(Icons.flash_on_rounded, size: 80, color: Colors.amber),
    Text(t['duelo']!, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
    const SizedBox(height: 40),
    Text(idioma == 'ES' ? "EL IMPOSTOR ERA:" : "THE IMPOSTOR WAS:", style: const TextStyle(color: Colors.white38)),
    Text(imps.join(", ").toUpperCase(), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.redAccent)),
    const SizedBox(height: 60),
    buildButton(t['nueva_partida']!, () => _mostrarInterstitial('HOME')),
  ]);
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
      default: return buildScreen(vistaHome());
    }
  }
}