import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'datos.dart'; 
import 'package:flutter/foundation.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    unawaited(MobileAds.instance.initialize());
  }
  runApp(MaterialApp(
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

class _JuegoImpostorState extends State<JuegoImpostor> {
  // --- VARIABLES DE ESTADO ---
  String pantallaActual = 'HOME';
  int numJugadores = 4;
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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          backgroundColor: Color(0xFF1B282D),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          title: Text("Contenido Premium", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Mira un video para desbloquear '$cat'."),
              if (_rewardedCargando) Padding(
                padding: const EdgeInsets.only(top: 20),
                child: CircularProgressIndicator(color: Colors.amber),
              )
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text("CERRAR")),
            if (!_rewardedCargando) ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _rewardedAd != null ? Colors.amber : Colors.white12, shape: StadiumBorder()),
              onPressed: () {
                if (_rewardedAd != null) {
                  Navigator.pop(context);
                  _rewardedAd!.show(onUserEarnedReward: (ad, reward) {
                    setState(() { categoriasBloqueadas.remove(cat); categoriaSeleccionada = cat; });
                    _cargarRewarded();
                  });
                } else { _cargarRewarded(); setStateDialog(() {}); }
              },
              child: Text(_rewardedAd != null ? "VER VIDEO" : "REINTENTAR", style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
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

  // --- LÓGICA DE JUEGO ---
  void prepararPartida({bool reiniciarTotal = true}) {
    if (reiniciarTotal) {
      indicesImpostores = [];
      while (indicesImpostores.length < numImpostores) {
        int r = Random().nextInt(numJugadores);
        if (!indicesImpostores.contains(r)) indicesImpostores.add(r);
      }
      eliminados = List.generate(numJugadores, (_) => false);
    }
    String cat = categoriaSeleccionada;
    if (cat == 'Aleatorio') {
      List<String> keys = categorias.keys.where((k) => !categoriasBloqueadas.contains(k)).toList();
      cat = keys[Random().nextInt(keys.length)];
    }
    final item = categorias[cat]![Random().nextInt(categorias[cat]!.length)];
    palabraSecreta = item['palabra']!;
    pistaSecreta = item['pista']!;
    List<int> vivos = [];
    for(int i=0; i<numJugadores; i++) if(!eliminados[i]) vivos.add(i);
    empiezaJugador = nombresJugadores[vivos[Random().nextInt(vivos.length)]];
    esRondaMimica = permitirMimica && (Random().nextInt(100) < probabilidadMimica);
    setState(() { jugadorActualIndice = 0; tarjetaEstrenada = false; pantallaActual = 'REVELAR'; });
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

  // --- VISTAS ---
  Widget vistaHome() {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.theater_comedy_rounded, size: 120, color: Colors.amber),
      SizedBox(height: 20),
      Text("IMPOSTOR", style: TextStyle(fontSize: 45, fontWeight: FontWeight.w900, letterSpacing: 5)),
      SizedBox(height: 60),
      buildButton("NUEVA PARTIDA", () => setState(() => pantallaActual = 'CONFIG')),
    ]);
  }

  Widget vistaConfig() {
    return SingleChildScrollView(padding: EdgeInsets.symmetric(vertical: 60), child: Column(children: [
      Text("AJUSTES", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.amber)),
      _selector("JUGADORES", numJugadores, 4, 15, (v) => setState(() => numJugadores = v)),
      _selector("IMPOSTORES", numImpostores, 1, 3, (v) => setState(() => numImpostores = v)),
      _switch("Mostrar Pistas al Impostor", mostrarPistas, (v) => setState(() => mostrarPistas = v)),
      _switch("Modo Mímica", permitirMimica, (v) => setState(() => permitirMimica = v)),
      if (permitirMimica) _selector("PROBABILIDAD %", probabilidadMimica, 0, 100, (v) => setState(() => probabilidadMimica = v), step: 10),
      _switch("Tiempo de Debate", activarTiempo, (v) => setState(() => activarTiempo = v)),
      if (activarTiempo) _selector("SEGUNDOS", tiempoConfigurado, 15, 300, (v) => setState(() => tiempoConfigurado = v), step: 15),
      _switch("Ruleta de Castigos", activarCastigos, (v) => setState(() => activarCastigos = v)),
      if (activarCastigos) ...[
        _switch("Castigar Inocentes", castigarInocentes, (v) => setState(() => castigarInocentes = v)),
        _editorCastigos(),
      ],
      SizedBox(height: 30),
      buildButton("SIGUIENTE", () => setState(() => pantallaActual = 'NOMBRES')),
    ]));
  }

  Widget _editorCastigos() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 25, vertical: 10),
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(25), border: Border.all(color: Colors.redAccent.withOpacity(0.3))),
      child: Column(children: [
        Row(children: [Icon(Icons.auto_awesome, color: Colors.redAccent, size: 20), SizedBox(width: 10), Text("LISTA DE CASTIGOS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14))]),
        SizedBox(height: 15),
        ...listaCastigos.map((c) => Container(
          margin: EdgeInsets.only(bottom: 8), padding: EdgeInsets.only(left: 15), decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(15)),
          child: Row(children: [Expanded(child: Text(c, style: TextStyle(fontSize: 13, color: Colors.white70))), IconButton(icon: Icon(Icons.close, size: 18, color: Colors.redAccent), onPressed: () => setState(() => listaCastigos.remove(c)))]),
        )).toList(),
        SizedBox(height: 10),
        TextField(
          controller: castigoController, style: TextStyle(fontSize: 14),
          decoration: InputDecoration(filled: true, fillColor: Colors.white.withOpacity(0.05), hintText: "Ej: Hacer 10 flexiones", border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none), suffixIcon: IconButton(icon: Icon(Icons.add_circle, color: Colors.redAccent), onPressed: () {
            if (castigoController.text.isNotEmpty) setState(() { listaCastigos.add(castigoController.text.toUpperCase()); castigoController.clear(); });
          })),
        ),
      ]),
    );
  }

  Widget vistaNombres() {
    return Column(children: [
      SizedBox(height: 100),
      Text("¿QUIÉN JUEGA?", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.amber)),
      Expanded(child: ListView.builder(padding: EdgeInsets.all(30), itemCount: numJugadores, itemBuilder: (context, i) => Container(
        margin: EdgeInsets.only(bottom: 15), decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
        child: TextField(style: TextStyle(color: Colors.white, fontSize: 18), textAlign: TextAlign.center, decoration: InputDecoration(prefixIcon: Icon(Icons.person, color: Colors.amber), hintText: "Jugador ${i+1}", border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 15)), onChanged: (v) => nombresJugadores[i] = v),
      ))),
      buildButton("CATEGORÍAS", () => setState(() => pantallaActual = 'CATEGORIA')),
      SizedBox(height: 30),
    ]);
  }

  Widget vistaCategoria() {
    List<String> todas = ['Aleatorio'] + categorias.keys.toList();
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text("CATEGORÍA", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.amber)),
      SizedBox(height: 30),
      Wrap(spacing: 12, runSpacing: 12, alignment: WrapAlignment.center, children: todas.map((cat) {
        bool lock = categoriasBloqueadas.contains(cat);
        bool sel = categoriaSeleccionada == cat;
        return GestureDetector(
          onTap: () { if (lock) _confirmarDesbloqueo(cat); else setState(() => categoriaSeleccionada = cat); },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(color: sel ? Colors.amber : Colors.white10, borderRadius: BorderRadius.circular(15), border: Border.all(color: lock ? Colors.redAccent.withOpacity(0.5) : Colors.transparent)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (lock) Icon(Icons.play_circle_fill, size: 16, color: Colors.redAccent),
              if (lock) SizedBox(width: 8),
              Text(cat, style: TextStyle(color: sel ? Colors.black : Colors.white)),
            ]),
          ),
        );
      }).toList()),
      SizedBox(height: 60),
      buildButton("EMPEZAR", () => prepararPartida()),
    ]);
  }

  Widget vistaRevelar() {
    bool imp = indicesImpostores.contains(jugadorActualIndice);
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text(nombresJugadores[jugadorActualIndice].toUpperCase(), style: TextStyle(fontSize: 26, color: Colors.white, letterSpacing: 5)),
      SizedBox(height: 30),
      Container(width: 300, height: 400, child: Stack(children: [
        Positioned.fill(child: GestureDetector(onLongPressStart: (_) { if (tarjetaEstrenada) setState(() => viendoPalabra = true); }, onLongPressEnd: (_) => setState(() => viendoPalabra = false), child: AnimatedContainer(duration: Duration(milliseconds: 400), decoration: BoxDecoration(color: viendoPalabra ? (imp ? Color(0xFF2D0A0A) : Color(0xFF0A192D)) : Colors.white.withOpacity(0.02), borderRadius: BorderRadius.circular(35), border: Border.all(color: viendoPalabra ? (imp ? Colors.redAccent : Colors.amber) : Colors.white10, width: 2)), child: Center(child: viendoPalabra ? _infoSecreta(imp) : Text(tarjetaEstrenada ? "MANTÉN PULSADO" : "", style: TextStyle(color: Colors.white24, fontWeight: FontWeight.bold)))))),
        AnimatedPositioned(duration: Duration(milliseconds: 800), curve: Curves.easeInOutBack, top: tarjetaEstrenada ? 500 : 0, left: 0, right: 0, bottom: tarjetaEstrenada ? -500 : 0, child: GestureDetector(onTap: () => setState(() => tarjetaEstrenada = true), child: AnimatedOpacity(duration: Duration(milliseconds: 400), opacity: tarjetaEstrenada ? 0 : 1, child: Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(35), gradient: LinearGradient(colors: [Color(0xFF333333), Color(0xFF111111)]), border: Border.all(color: Colors.amber.withOpacity(0.5))), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.mail_lock_rounded, size: 60, color: Colors.amber), SizedBox(height: 25), Text("CONFIDENCIAL", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, letterSpacing: 2))]))))),
      ])),
      SizedBox(height: 40),
      Opacity(opacity: (!viendoPalabra && tarjetaEstrenada) ? 1.0 : 0.0, child: buildButton("CONFIRMAR Y PASAR", () { if (!viendoPalabra && tarjetaEstrenada) { if (jugadorActualIndice < numJugadores - 1) setState(() { jugadorActualIndice++; tarjetaEstrenada = false; }); else { setState(() => pantallaActual = 'JUEGO'); iniciarTemporizador(); } } }, color: Colors.white.withOpacity(0.05))),
    ]);
  }

  Widget _infoSecreta(bool imp) {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(imp ? Icons.security_rounded : Icons.wb_incandescent_rounded, size: 60, color: imp ? Colors.redAccent : Colors.amber),
      SizedBox(height: 20),
      Text(imp ? "TU ROL" : "TU PALABRA", style: TextStyle(color: Colors.white38, fontSize: 12)),
      Text(imp ? "IMPOSTOR" : palabraSecreta.toUpperCase(), textAlign: TextAlign.center, style: TextStyle(color: imp ? Colors.redAccent : Colors.amber, fontSize: 32, fontWeight: FontWeight.w900)),
      if (mostrarPistas && imp) Text(pistaSecreta.toUpperCase(), style: TextStyle(fontSize: 16, color: Colors.white70)),
    ]);
  }

  Widget vistaJuego() {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      if (activarTiempo) ...[Stack(alignment: Alignment.center, children: [SizedBox(width: 80, height: 80, child: CircularProgressIndicator(value: tiempoRestante / tiempoConfigurado, strokeWidth: 8, color: tiempoRestante < 10 ? Colors.redAccent : Colors.amber)), Text("$tiempoRestante", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: tiempoRestante < 10 ? Colors.redAccent : Colors.white))]), SizedBox(height: 20)],
      if (esRondaMimica) Text("¡RONDA MÍMICA!", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 24)),
      Text("¡A DEBATIR!", style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
      SizedBox(height: 20),
      Text("EMPIEZA: ${empiezaJugador.toUpperCase()}", style: TextStyle(color: Colors.amber, fontSize: 22)),
      SizedBox(height: 60),
      buildButton("VOTAR AL IMPOSTOR", iniciarVotacion, color: Colors.redAccent),
      buildButton("REPETIR PARTIDA", () { prepararPartida(reiniciarTotal: false); iniciarTemporizador(); }, color: Colors.white10),
      buildButton("FINALIZAR", () => _mostrarInterstitial('HOME'), color: Colors.white.withOpacity(0.05)),
    ]);
  }

  Widget vistaVotacionTurno() {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.touch_app_rounded, size: 80, color: Colors.amber),
      SizedBox(height: 20),
      Text("PASA EL MÓVIL A:"),
      Text(nombresJugadores[jugadorVotandoIndex].toUpperCase(), style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.amber)),
      SizedBox(height: 50),
      buildButton("LO TENGO", () => setState(() => pantallaActual = 'VOTACION_ACCION')),
    ]);
  }

  Widget vistaVotacionAccion() {
    return Column(children: [
      SizedBox(height: 80),
      Text("¿QUIÉN ES EL IMPOSTOR?", style: TextStyle(fontSize: 20, color: Colors.amber)),
      Expanded(child: ListView.builder(itemCount: numJugadores, itemBuilder: (context, i) {
        if(i == jugadorVotandoIndex || eliminados[i]) return SizedBox.shrink();
        return buildButton(nombresJugadores[i], () => registrarVoto(i), color: Colors.white10);
      })),
    ]);
  }

  Widget vistaResultadosVoto() {
    int masVotado = conteoVotos.indexOf(conteoVotos.reduce(max));
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.person_off_rounded, size: 80, color: Colors.redAccent),
      Text("${nombresJugadores[masVotado]} ELIMINADO", style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
      Text("ERA INOCENTE", style: TextStyle(color: Colors.white54)),
      SizedBox(height: 40),
      buildButton("CONTINUAR", () { setState(() => pantallaActual = 'JUEGO'); iniciarTemporizador(); }),
    ]);
  }

  Widget vistaVictoria() {
    int masVotado = conteoVotos.indexOf(conteoVotos.reduce(max));
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.emoji_events_rounded, size: 100, color: Colors.amber),
      Text("¡IMPOSTOR CAZADO!", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.amber)),
      Text("Era ${nombresJugadores[masVotado]}", style: TextStyle(fontSize: 18, color: Colors.white70)),
      SizedBox(height: 50),
      buildButton("VOLVER A JUGAR", () => prepararPartida(reiniciarTotal: true)),
      buildButton("INICIO", () => _mostrarInterstitial('HOME'), color: Colors.white.withOpacity(0.05)),
    ]);
  }

  Widget vistaRuleta() {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.gavel_rounded, size: 80, color: Colors.redAccent),
      Text(fueImpostorCazado ? "¡CAZADO!" : "¡INOCENTE!", style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.redAccent)),
      SizedBox(height: 30),
      Container(padding: EdgeInsets.all(30), decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.redAccent)), child: Text(castigoFinal, textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
      SizedBox(height: 50),
      if(!girandoRuleta) buildButton("CONTINUAR", () { if(fueImpostorCazado) setState(() => pantallaActual = 'VICTORIA'); else { int mas = conteoVotos.indexOf(conteoVotos.reduce(max)); setState(() { eliminados[mas] = true; pantallaActual = 'RESULTADOS_VOTO'; }); } }),
    ]);
  }

  Widget vistaDuelo() {
    List<String> imps = [];
    for(int i in indicesImpostores) imps.add(nombresJugadores[i]);
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.flash_on_rounded, size: 80, color: Colors.amber),
      Text("DUELO FINAL", style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
      SizedBox(height: 40),
      Text("EL IMPOSTOR ERA:", style: TextStyle(color: Colors.white38)),
      Text(imps.join(", ").toUpperCase(), style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.redAccent)),
      SizedBox(height: 60),
      buildButton("NUEVA PARTIDA", () => _mostrarInterstitial('HOME')),
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