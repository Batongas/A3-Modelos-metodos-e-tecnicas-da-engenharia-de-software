// --------------------------------------------------------------
//  Jardim Digital — UI MODERNA + FUNCIONALIDADES
// --------------------------------------------------------------

import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

// --------------------------------------------------------------
//  CHAVES DE API
// --------------------------------------------------------------
const String PLANT_ID_SECRET = 'EOaxG11bycA8jXpbtc8yajFSA06mYTdspVIQPdF7j8Opxa3qd8';
const String API_URL_PLANT_ID = 'https://plant.id/api/v3/identification';

const String PERENUAL_KEY = 'sk-Z2Xg69128e76c44b113423';
const String PERENUAL_URL = 'https://perenual.com/api/species-care-guide-list';

// --------------------------------------------------------------
//  MODELO DE DADOS (PLANTA)
// --------------------------------------------------------------
class Planta {
  final String id;
  String nome;
  String especie;
  int frequenciaRega;
  DateTime proximaRega;
  int horasSol;
  DateTime proximaAdubacao;
  DateTime proximaTrocaTerra;

  Planta({
    String? id,
    required this.nome,
    required this.especie,
    required this.frequenciaRega,
    required this.horasSol,
    required this.proximaAdubacao,
    required this.proximaTrocaTerra,
    DateTime? proximaRega,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        proximaRega = proximaRega ?? DateTime(1970);

  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
        'especie': especie,
        'frequenciaRega': frequenciaRega,
        'horasSol': horasSol,
        'proximaRega': proximaRega.toIso8601String(),
        'proximaAdubacao': proximaAdubacao.toIso8601String(),
        'proximaTrocaTerra': proximaTrocaTerra.toIso8601String(),
      };

  factory Planta.fromJson(Map<String, dynamic> json) {
    DateTime _parseDate(dynamic v) {
      if (v == null) return DateTime(1970);
      try {
        return DateTime.parse(v.toString());
      } catch (_) {
        return DateTime(1970);
      }
    }

    int _parseInt(dynamic v) {
      if (v is int) return v;
      return int.tryParse(v.toString()) ?? 0;
    }

    return Planta(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      nome: json['nome'] ?? '',
      especie: json['especie'] ?? '',
      frequenciaRega: _parseInt(json['frequenciaRega']),
      horasSol: _parseInt(json['horasSol']),
      proximaRega: _parseDate(json['proximaRega']),
      proximaAdubacao: _parseDate(json['proximaAdubacao']),
      proximaTrocaTerra: _parseDate(json['proximaTrocaTerra']),
    );
  }
}

// --------------------------------------------------------------
// SERVIÇO DE NOTIFICAÇÃO
// --------------------------------------------------------------
class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('America/Sao_Paulo'));

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _plugin.initialize(initSettings);
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      await androidImpl.requestNotificationsPermission();
    }
  }

  static Future<void> schedule(
      int id, String title, String body, DateTime date) async {
    if (date.isBefore(DateTime.now())) return;

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(date, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'plant_channel',
          'Lembretes do Jardim',
          channelDescription: 'Notificações automáticas das plantas',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  static Future<void> cancel(int id) async => _plugin.cancel(id);
}

// --------------------------------------------------------------
//  MAIN
// --------------------------------------------------------------
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa os serviços em paralelo com a UI
  runZonedGuarded(() {
    // Inicia o serviço de notificação (que já inicializa o timezone)
    NotificationService.init();

    runApp(const MeuApp());
  }, (error, stack) {
    // TODO: adicione um serviço de log de erros (Firebase, Sentry, etc)
    print('Erro não tratado: $error\n$stack');
  });
}

// --------------------------------------------------------------
//  APP PRINCIPAL + TEMA
// --------------------------------------------------------------
class MeuApp extends StatelessWidget {
  const MeuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jardim Digital',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00C676),
          secondary: Color(0xFF1DE9B6),
          surface: Color(0xFF1C1C1E),
          onPrimary: Colors.white,
          onSurface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1C1C1E),
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(fontSize: 16, color: Color(0xFFDDE6D9)),
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      home: const HomePage(),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}

// --------------------------------------------------------------
//  HOMEPAGE — PLANTAS + MENU INFERIOR
// --------------------------------------------------------------
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

// Função de nível superior para o isolate
List<Planta> _parsePlantas(String json) {
  return (jsonDecode(json) as List)
      .map((data) => Planta.fromJson(data))
      .toList();
}

class _HomePageState extends State<HomePage> {
  List<Planta> minhasPlantas = [];
  final DateFormat _fmt = DateFormat('dd/MM/yyyy HH:mm');
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _carregarPlantas();
  }

  Future<void> _carregarPlantas() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('minhas_plantas_key') ?? '[]';

    // Usa o compute para fazer o parsing em um isolate separado
    final plantas = await compute(_parsePlantas, data);

    if (mounted) {
      setState(() {
        minhasPlantas = plantas;
      });
    }
  }

  Future<void> _salvarPlantas() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'minhas_plantas_key',
      jsonEncode(minhasPlantas.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> _adicionarOuEditarPlanta(
      {Planta? plantaParaEditar, int? indexParaEditar}) async {
    final resultado = await Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, __, ___) => CadastroPlantaPage(
          plantaParaEditar: plantaParaEditar,
          indexParaEditar: indexParaEditar,
        ),
        transitionsBuilder: (_, animation, __, child) {
          final offset = Tween<Offset>(
            begin: const Offset(0.1, 0.05),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ));
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(position: offset, child: child),
          );
        },
      ),
    );

    if (resultado != null && resultado is Map && resultado['planta'] is Planta) {
      final Planta plantaSalva = resultado['planta'] as Planta;
      final int idHash = plantaSalva.id.hashCode;

      // agenda notificações
      await NotificationService.schedule(
        idHash + 1,
        'Hora de regar! 💧',
        'Sua planta "${plantaSalva.nome}" precisa de água.',
        plantaSalva.proximaRega,
      );
      await NotificationService.schedule(
        idHash + 2,
        'Hora de adubar! 🪴',
        'Sua planta "${plantaSalva.nome}" precisa de adubo.',
        plantaSalva.proximaAdubacao,
      );
      await NotificationService.schedule(
        idHash + 3,
        'Hora da terra! 🌑',
        'Sua planta "${plantaSalva.nome}" precisa de terra nova.',
        plantaSalva.proximaTrocaTerra,
      );

      setState(() {
        if (indexParaEditar != null) {
          minhasPlantas[indexParaEditar] = plantaSalva;
        } else {
          minhasPlantas.add(plantaSalva);
        }
      });
      _salvarPlantas();
    }
  }

  Future<void> _removerPlanta(int index) async {
    final planta = minhasPlantas[index];
    final idBase = planta.id.hashCode;

    await NotificationService.cancel(idBase + 1);
    await NotificationService.cancel(idBase + 2);
    await NotificationService.cancel(idBase + 3);

    setState(() => minhasPlantas.removeAt(index));
    _salvarPlantas();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${planta.nome} removida!')),
    );
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Jardim Digital')),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildListaPlantas(),
          const PerfilPage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.local_florist_outlined),
            label: 'Plantas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Perfil',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF00C676),
        onPressed: () =>
            _adicionarOuEditarPlanta(plantaParaEditar: null, indexParaEditar: null),
        child: const Icon(Icons.add_rounded, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  // ------------------------------------------------------------
  //  HOME VISUAL (header + cards + lista)
  // ------------------------------------------------------------
  Widget _buildListaPlantas() {
    final temPlantas = minhasPlantas.isNotEmpty;
    final agora = DateTime.now();
    final dataFormatada = DateFormat('d.M.y').format(agora);
    final horaFormatada = DateFormat('HH:mm').format(agora);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                horaFormatada,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.cloud, color: Colors.white70, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    dataFormatada,
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ícones de status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              Icon(Icons.cut_rounded, color: Colors.redAccent, size: 20),
              Icon(Icons.water_drop_outlined,
                  color: Colors.tealAccent, size: 20),
              Icon(Icons.bug_report_outlined, color: Colors.red, size: 20),
              Icon(Icons.grass_rounded,
                  color: Colors.greenAccent, size: 20),
              Icon(Icons.spa_rounded, color: Colors.green, size: 20),
            ],
          ),
          const SizedBox(height: 10),

          
          const SizedBox(height: 16),

          // CARD STATUS GERAL
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Em geral',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  temPlantas
                      ? '${minhasPlantas.length} planta(s) cadastrada(s)'
                      : '0 planta (0 precisa de cuidados)',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C676),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  onPressed: () => _adicionarOuEditarPlanta(
                    plantaParaEditar: null,
                    indexParaEditar: null,
                  ),
                  child: const Text(
                    'Adicionar planta',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // BOTÃO CRIAR ESPAÇO
          ElevatedButton.icon(
            onPressed: () {},
            icon:
                const Icon(Icons.add_rounded, color: Color(0xFF00C676)),
            label: const Text(
              'Criar espaço',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF00C676),
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF101010),
              elevation: 0,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50),
                side: const BorderSide(
                    color: Color(0xFF00C676), width: 1.2),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // LISTA DE PLANTAS
          if (temPlantas)
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: minhasPlantas.length,
              itemBuilder: (context, index) {
                final planta = minhasPlantas[index];
                return Dismissible(
                  key: Key(planta.id),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) => _removerPlanta(index),
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.red[400],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child:
                        const Icon(Icons.delete, color: Colors.white),
                  ),
                  child: Card(
                    color: const Color(0xFF1C1C1E),
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFF00C676),
                        child: Icon(Icons.eco, color: Colors.white),
                      ),
                      title: Text(
                        planta.nome,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                      subtitle: Text(
                        'Espécie: ${planta.especie}\nAdubar em: ${planta.proximaAdubacao.isAfter(DateTime(1971)) ? _fmt.format(planta.proximaAdubacao) : 'Não definido'}',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 14),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios,
                          color: Colors.white54),
                      onTap: () => _adicionarOuEditarPlanta(
                        plantaParaEditar: planta,
                        indexParaEditar: index,
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

// --------------------------------------------------------------
//  PERFIL
// --------------------------------------------------------------
class PerfilPage extends StatelessWidget {
  const PerfilPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Meu Perfil 🌿',
            style: TextStyle(fontSize: 18, color: Colors.white70),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              await NotificationService.schedule(
                999, // ID de teste
                'Notificação de Teste 🔔',
                'Se você recebeu isso, as notificações estão funcionando!',
                DateTime.now().add(const Duration(seconds: 5)),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Notificação de teste agendada para 5 segundos.'),
                ),
              );
            },
            child: const Text('Testar Notificação'),
          ),
        ],
      ),
    );
  }
}

// --------------------------------------------------------------
//  PÁGINA DE CADASTRO / EDIÇÃO DE PLANTA
// --------------------------------------------------------------
class CadastroPlantaPage extends StatefulWidget {
  final Planta? plantaParaEditar;
  final int? indexParaEditar;

  const CadastroPlantaPage({
    super.key,
    this.plantaParaEditar,
    this.indexParaEditar,
  });

  @override
  State<CadastroPlantaPage> createState() => _CadastroPlantaPageState();
}

class _CadastroPlantaPageState extends State<CadastroPlantaPage> {
  final _nome = TextEditingController();
  final _especie = TextEditingController();
  final _rega = TextEditingController();
  final _sol = TextEditingController();

  DateTime? _adubacao;
  DateTime? _trocaTerra;
  bool _identificando = false;
  final DateFormat _fmt = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    if (widget.plantaParaEditar != null) {
      final p = widget.plantaParaEditar!;
      _nome.text = p.nome;
      _especie.text = p.especie;
      _rega.text = p.frequenciaRega.toString();
      _sol.text = p.horasSol.toString();
      _adubacao = p.proximaAdubacao;
      _trocaTerra = p.proximaTrocaTerra;
    }
  }

  Future<void> _identificarPlanta() async {
    setState(() => _identificando = true);

    final picker = ImagePicker();
    // Otimização: define uma qualidade e tamanho máximos para a imagem
    final XFile? foto = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80, // Qualidade de 0 a 100
    );

    if (foto == null) {
      setState(() => _identificando = false);
      return;
    }

    try {
      // 1. CHAMADA PLANT.ID (Identifica o nome)
      final request = http.MultipartRequest('POST', Uri.parse(API_URL_PLANT_ID));
      request.headers['Api-Key'] = PLANT_ID_SECRET;
      request.files.add(await http.MultipartFile.fromPath('images', foto.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        // Verifica se achou alguma planta
        if (data['result'] != null &&
            data['result']['classification'] != null &&
            data['result']['classification']['suggestions'] != null &&
            data['result']['classification']['suggestions'].isNotEmpty) {
          final sugestao = data['result']['classification']['suggestions'][0];
          final String nomeDaPlanta = sugestao['name'] ?? 'Desconhecida';

          // 2. CHAMADA PERENUAL (Busca os cuidados usando o nome)
          final perenualResponse = await http.get(
              Uri.parse('$PERENUAL_URL?key=$PERENUAL_KEY&q=$nomeDaPlanta'));

          // Valores padrão caso a Perenual não ache nada
          int regaDias = Random().nextInt(2) + 1;
          int solHoras = Random().nextInt(2) + 1;
          DateTime proxAdubacao = DateTime.now().add(const Duration(days: 60));
          DateTime proxTrocaTerra =
              DateTime.now().add(const Duration(days: 365));

          if (perenualResponse.statusCode == 200) {
            final perenualData = jsonDecode(perenualResponse.body);
            // Se a lista 'data' não for vazia, pegamos o primeiro resultado
            if (perenualData['data'] != null &&
                perenualData['data'].isNotEmpty) {
              final dadosCuidado = perenualData['data'][0];

              // Usa as funções auxiliares para traduzir os textos da API
              regaDias = _mapearRega(dadosCuidado['watering'] ?? 'Average');
              solHoras = _mapearSol(dadosCuidado['sunlight'] ?? 'Part Shade');
              proxAdubacao = _mapearAdubacao(dadosCuidado['fertilizing']);
              proxTrocaTerra = _mapearTrocaTerra(dadosCuidado['repotting']);
            }
          }

          // 3. Atualiza a tela com TUDO preenchido
          if (mounted) {
            setState(() {
              _especie.text = nomeDaPlanta;
              _rega.text = regaDias.toString();
              _sol.text = solHoras.toString();
              // Define as datas (se forem válidas)
              _adubacao =
                  proxAdubacao.isAfter(DateTime(1971)) ? proxAdubacao : null;
              _trocaTerra =
                  proxTrocaTerra.isAfter(DateTime(1971)) ? proxTrocaTerra : null;
            });
          }
        } else {
          // Não achou sugestão no JSON
          print("Nenhuma sugestão encontrada na resposta da Plant.id");
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Não foi possível identificar a planta.')),
            );
          }
        }
      }
    } catch (e) {
      print("Erro ao identificar: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao identificar: $e')), // Mostra o erro para o usuário
        );
      }
    } finally {
      if (mounted) {
        setState(() => _identificando = false);
      }
    }
  }

  // --- FUNÇÕES AUXILIARES (Ficam logo abaixo do _identificarPlanta) ---

  int _mapearRega(String regaApi) {
    switch (regaApi.toLowerCase()) {
      case 'frequent':
        return 3;
      case 'average':
        return 7;
      case 'minimum':
        return 14;
      default:
        return 7;
    }
  }

  int _mapearSol(dynamic solApi) {
    // A API pode retornar lista ou string, garantimos que seja string
    String sol = solApi.toString().toLowerCase().split(',')[0];
    if (sol.contains('full sun')) return 6;
    if (sol.contains('part shade') || sol.contains('partial')) return 4;
    if (sol.contains('shade')) return 2;
    return 4;
  }

  DateTime _mapearAdubacao(String? aduboApi) {
    if (aduboApi == null || aduboApi.toLowerCase().contains("not required"))
      return DateTime(1970);
    if (aduboApi.toLowerCase().contains("weeks"))
      return DateTime.now().add(const Duration(days: 30));
    if (aduboApi.toLowerCase().contains("monthly"))
      return DateTime.now().add(const Duration(days: 30));
    return DateTime.now().add(const Duration(days: 60));
  }

  DateTime _mapearTrocaTerra(String? trocaApi) {
    if (trocaApi == null) return DateTime.now().add(const Duration(days: 365));
    if (trocaApi.toLowerCase().contains("2-3 years"))
      return DateTime.now().add(const Duration(days: 365 * 2));
    if (trocaApi.toLowerCase().contains("year"))
      return DateTime.now().add(const Duration(days: 365));
    return DateTime.now().add(const Duration(days: 365));
  }
  // ----------------------------------------------------------------------

  Future<void> _selecionarData({required bool isAdubacao}) async {
    final now = DateTime.now();
    final data = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(2100),
      locale: const Locale('pt', 'BR'),
    );
    if (data == null) return;

    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now),
    );
    if (hora == null) return;

    final combinado = DateTime(
      data.year,
      data.month,
      data.day,
      hora.hour,
      hora.minute,
    );

    setState(() {
      if (isAdubacao) {
        _adubacao = combinado;
      } else {
        _trocaTerra = combinado;
      }
    });
  }

  void _salvar() {
    if (_nome.text.isEmpty || _especie.text.isEmpty) return;

    final freqRega = int.tryParse(_rega.text) ?? 0;
    final horasSol = int.tryParse(_sol.text) ?? 0;

    final proximaRega = freqRega > 0
        ? DateTime.now().add(Duration(days: freqRega))
        : DateTime(1970);

    final planta = Planta(
      id: widget.plantaParaEditar?.id,
      nome: _nome.text,
      especie: _especie.text,
      frequenciaRega: freqRega,
      horasSol: horasSol,
      proximaRega: proximaRega,
      proximaAdubacao: _adubacao ?? DateTime(1970),
      proximaTrocaTerra: _trocaTerra ?? DateTime(1970),
    );

    Navigator.pop(context, {'planta': planta});
  }

  @override
  Widget build(BuildContext context) {
    final titulo =
        widget.plantaParaEditar == null ? 'Nova Planta' : 'Editar Planta';

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text(titulo),
        backgroundColor: const Color(0xFF1C1C1E),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Botão identificar por foto
            ElevatedButton.icon(
              icon: _identificando
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : const Icon(Icons.camera_alt_outlined),
              label: Text(_identificando
                  ? 'Identificando...'
                  : 'Identificar por Foto'),
              onPressed: _identificando ? null : _identificarPlanta,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C676),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50)),
              ),
            ),
            const SizedBox(height: 24),

            // Cards com inputs
            _inputCard(Icons.local_florist, 'Nome da Planta', _nome),
            _inputCard(Icons.eco_outlined, 'Espécie', _especie),
            _inputCard(Icons.water_drop_outlined,
                'Frequência de Rega (dias)', _rega,
                type: TextInputType.number),
            _inputCard(Icons.wb_sunny_outlined, 'Horas de Sol (por dia)', _sol,
                type: TextInputType.number),

            const SizedBox(height: 16),

            // Próximos cuidados
            Card(
              color: const Color(0xFF1C1C1E),
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Próximos cuidados',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading:
                          const Icon(Icons.grass, color: Color(0xFF00C676)),
                      title: const Text('Próxima adubação',
                          style: TextStyle(color: Colors.white)),
                      subtitle: Text(
                        _adubacao == null
                            ? 'Não definido'
                            : _fmt.format(_adubacao!),
                        style: const TextStyle(color: Colors.white70),
                      ),
                      trailing: TextButton(
                        onPressed: () =>
                            _selecionarData(isAdubacao: true),
                        child: const Text('Escolher',
                            style:
                                TextStyle(color: Color(0xFF00C676))),
                      ),
                    ),
                    const Divider(color: Colors.white12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.landscape,
                          color: Color(0xFF00C676)),
                      title: const Text('Troca de terra',
                          style: TextStyle(color: Colors.white)),
                      subtitle: Text(
                        _trocaTerra == null
                            ? 'Não definido'
                            : _fmt.format(_trocaTerra!),
                        style:
                            const TextStyle(color: Colors.white70),
                      ),
                      trailing: TextButton(
                        onPressed: () =>
                            _selecionarData(isAdubacao: false),
                        child: const Text('Escolher',
                            style:
                                TextStyle(color: Color(0xFF00C676))),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Botão salvar
            ElevatedButton(
              onPressed: _salvar,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C676),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50)),
              ),
              child: const Text(
                'Salvar Planta',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputCard(IconData icon, String label,
      TextEditingController controller,
      {TextInputType type = TextInputType.text}) {
    return Card(
      color: const Color(0xFF1C1C1E),
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF00C676), size: 26),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: controller,
                keyboardType: type,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: label,
                  labelStyle: const TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
