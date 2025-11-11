// Importa o pacote principal do Flutter para construir a interface
import 'package:flutter/material.dart';
// Importa os pacotes para salvar (SharedPreferences) e para converter texto (JSON)
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
// Importa o pacote para formatar datas (ex: dd/MM/yyyy)
import 'package:intl/intl.dart';
// Importa os pacotes para o DatePicker funcionar em Português
import 'package:flutter_localizations/flutter_localizations.dart';

// Imports necessários para Notificações, Timezone, Câmera e API
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:http/http.dart' as http; // Para API
import 'package:image_picker/image_picker.dart'; // Para Câmera


// ⚠️ SUBSTITUA PELA SUA CHAVE SECRETA REAL DA PLANT.ID
const String PLANT_ID_SECRET = 'EOaxG11bycA8jXpbtc8yajFSA06mYTdspVIQPdF7j8Opxa3qd8'; 
const String API_URL_PLANT_ID = 'https://plant.id/api/v3/identification';


// CLASSE MODELO (PLANTAS) - FINAL
// -------------------------------------------------------------------
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
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
       proximaRega = proximaRega ?? DateTime(1970);


  //  Converter planta para JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'especie': especie,
      'frequenciaRega': frequenciaRega,
      'horasSol': horasSol,
      'proximaRega': proximaRega.toIso8601String(),
      'proximaAdubacao': proximaAdubacao.toIso8601String(),
      'proximaTrocaTerra': proximaTrocaTerra.toIso8601String(),
    };
  }

  // Criar planta a partir do JSON
  factory Planta.fromJson(Map<String, dynamic> json) {
    return Planta(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      nome: json['nome'],
      especie: json['especie'],
      frequenciaRega: (json['frequenciaRega'] is int) ? json['frequenciaRega'] : int.tryParse(json['frequenciaRega'].toString()) ?? 0,
      horasSol: (json['horasSol'] is int) ? json['horasSol'] : int.tryParse(json['horasSol'].toString()) ?? 0,
      
      proximaRega: json['proximaRega'] != null 
          ? DateTime.parse(json['proximaRega'])
          : null,
      proximaAdubacao: json['proximaAdubacao'] != null
          ? DateTime.parse(json['proximaAdubacao'])
          : DateTime(1970),
      proximaTrocaTerra: json['proximaTrocaTerra'] != null
          ? DateTime.parse(json['proximaTrocaTerra'])
          : DateTime(1970),
    );
  }
}

// -------------------------------------------------------------------
// SERVIÇO DE NOTIFICAÇÃO (COMPLETO)
// -------------------------------------------------------------------

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('America/Sao_Paulo')); 

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS, 
    );

    await _notificationsPlugin.initialize(initializationSettings);
    
    // CORREÇÃO CRUCIAL: Solicita permissão de notificação em tempo de execução para Android 13+
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();
    }
  }

  static Future<void> scheduleNotification(
      int id, String title, String body, DateTime scheduledDate) async {
    
    if (scheduledDate.isBefore(DateTime.now())) return; 

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local), 
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'plant_channel_id', 
          'Lembretes do Jardim', 
          channelDescription: 'Canal para lembretes de plantas.',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }
}


// -------------------------------------------------------------------
// PONTO DE ENTRADA E WIDGET PRINCIPAL
// -------------------------------------------------------------------

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init(); 
  runApp(const MeuApp());
}

class MeuApp extends StatelessWidget {
  const MeuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Digital Garden',
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', 'BR'),
        Locale('en', 'US'),
      ],
      locale: const Locale('pt', 'BR'),
      home: const HomePage(),
    );
  }
}

// -------------------------------------------------------------------
// HOMEPAGE - LISTA DE PLANTAS, DELETAR E EDITAR
// -------------------------------------------------------------------

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Planta> minhasPlantas = [];
  final DateFormat _formatadorDataHora = DateFormat('dd/MM/yyyy HH:mm'); 

  @override
  void initState() {
    super.initState();
    _carregarPlantas();
  }

  void _carregarPlantas() async {
    final prefs = await SharedPreferences.getInstance();
    final String plantasString = prefs.getString('minhas_plantas_key') ?? '[]';
    final List<dynamic> plantasJson = jsonDecode(plantasString);
    setState(() {
      minhasPlantas = plantasJson.map((json) => Planta.fromJson(json)).toList();
    });
  }

  void _salvarPlantas() async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> plantasJson =
    minhasPlantas.map((planta) => planta.toJson()).toList();
    final String plantasString = jsonEncode(plantasJson);
    await prefs.setString('minhas_plantas_key', plantasString);
  }

  // Lógica unificada para Adicionar ou Editar
  void _adicionarOuEditarPlanta({Planta? plantaParaEditar, int? indexParaEditar}) async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CadastroPlantaPage(
          plantaParaEditar: plantaParaEditar,
          indexParaEditar: indexParaEditar, 
        ),
      ),
    );

    // Verifica se o resultado é válido e contém a Planta
    if (resultado != null && resultado is Map && resultado.containsKey('planta')) {
      
      final Planta plantaSalva = resultado['planta'] as Planta;
      final int? index = indexParaEditar; 

      // Recalcula a data da próxima rega (X dias à frente)
      final proximaRega = plantaSalva.frequenciaRega > 0
          ? DateTime.now().add(Duration(days: plantaSalva.frequenciaRega))
          : DateTime(1970);

      // Cria a Planta completa final, garantindo o ID e a proximaRega atualizados
      final plantaCompleta = Planta(
        id: plantaParaEditar?.id ?? plantaSalva.id,
        nome: plantaSalva.nome,
        especie: plantaSalva.especie,
        frequenciaRega: plantaSalva.frequenciaRega,
        horasSol: plantaSalva.horasSol,
        proximaAdubacao: plantaSalva.proximaAdubacao,
        proximaTrocaTerra: plantaSalva.proximaTrocaTerra,
        proximaRega: proximaRega,
      );

      // Agendamento de notificações
      final int idBase = plantaCompleta.id.hashCode;
    
      // Cancela as antigas e agenda as novas
      NotificationService.cancelNotification(idBase + 1);
      NotificationService.cancelNotification(idBase + 2);
      NotificationService.cancelNotification(idBase + 3);

      NotificationService.scheduleNotification(idBase + 1, 'Hora de regar! 💧', 'Sua planta "${plantaCompleta.nome}" precisa de água.', plantaCompleta.proximaRega);
      NotificationService.scheduleNotification(idBase + 2, 'Hora de adubar! 🪴', 'Sua planta "${plantaCompleta.nome}" precisa de adubo.', plantaCompleta.proximaAdubacao);
      NotificationService.scheduleNotification(idBase + 3, 'Hora da terra! 🌑', 'Sua planta "${plantaCompleta.nome}" precisa de terra nova.', plantaCompleta.proximaTrocaTerra);

      // Atualiza o estado
      setState(() {
        if (index != null) {
          minhasPlantas[index] = plantaCompleta;
        } else {
          minhasPlantas.add(plantaCompleta);
        }
      });
      
      _salvarPlantas();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Digital Garden'),
      ),
      body: ListView.builder(
        itemCount: minhasPlantas.length,
        itemBuilder: (context, index) {
          final planta = minhasPlantas[index];
          final String key = planta.id; 

          return Dismissible(
            key: Key(key), 
            
            onDismissed: (direction) {
              final plantaRemovida = minhasPlantas[index];
              
              // Cancela as notificações ao remover a planta
              final int idBase = plantaRemovida.id.hashCode;
              NotificationService.cancelNotification(idBase + 1); 
              NotificationService.cancelNotification(idBase + 2);
              NotificationService.cancelNotification(idBase + 3);

              setState(() {
                minhasPlantas.removeAt(index);
              });
              
              _salvarPlantas(); 

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${plantaRemovida.nome} removida!')),
              );
            },

            background: Container(
              color: Colors.red[400],
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20.0),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            
            child: ListTile(
              title: Text(planta.nome),
              subtitle: Text(
                'Espécie: ${planta.especie}\nPróxima Adubação: ${planta.proximaAdubacao.isAfter(DateTime(1971)) ? _formatadorDataHora.format(planta.proximaAdubacao) : 'Não definido'}',
                style: TextStyle(fontSize: 12),
              ),
              leading: Icon(Icons.local_florist, color: Colors.green[600]),
              trailing:
              const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
              
              onTap: () {
                _adicionarOuEditarPlanta(
                  plantaParaEditar: planta, 
                  indexParaEditar: index,
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _adicionarOuEditarPlanta(plantaParaEditar: null, indexParaEditar: null);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

// -------------------------------------------------------------------
// CADASTRO/EDIÇÃO DE PLANTAS
// -------------------------------------------------------------------

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
  final _nomeController = TextEditingController();
  final _especieController = TextEditingController();
  final _regaController = TextEditingController();
  final _solController = TextEditingController();

  // Variável para controlar o estado de carregamento da API (NOVO)
  bool _estaIdentificando = false; 

  DateTime? _dataAdubacao;
  DateTime? _dataTrocaTerra;
  final DateFormat _formatadorData = DateFormat('dd/MM/yyyy HH:mm'); 

  @override
  void initState() {
    super.initState();
    
    // Preenche os campos se estiver em modo de edição
    if (widget.plantaParaEditar != null) {
      _nomeController.text = widget.plantaParaEditar!.nome;
      _especieController.text = widget.plantaParaEditar!.especie;
      _regaController.text = widget.plantaParaEditar!.frequenciaRega.toString();
      _solController.text = widget.plantaParaEditar!.horasSol.toString();
      
      // Usa null se for a data padrão (1970)
      _dataAdubacao = widget.plantaParaEditar!.proximaAdubacao.isAfter(DateTime(1971)) 
          ? widget.plantaParaEditar!.proximaAdubacao 
          : null;
      _dataTrocaTerra = widget.plantaParaEditar!.proximaTrocaTerra.isAfter(DateTime(1971)) 
          ? widget.plantaParaEditar!.proximaTrocaTerra 
          : null;
    }
  }

  // MÉTODO DE RECONHECIMENTO DE IMAGEM (API Plant.id v3)
  // Em: class _CadastroPlantaPageState

Future<void> _identificarPlanta() async {
  // 1. Mostrar "carregando"
  setState(() {
    _estaIdentificando = true;
  });

  // 2. Tentar pegar a foto (Câmera)
  final ImagePicker picker = ImagePicker();
  final XFile? foto = await picker.pickImage(source: ImageSource.camera);

  if (foto == null) {
    setState(() { _estaIdentificando = false; });
    return; // Usuário cancelou
  }

  try {
    // --- NOVO MÉTODO: Usando Multipart/form-data ---

    // 3. Criar a requisição multipart
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(API_URL_PLANT_ID), // URL: .../identification
    );

    // 4. Adicionar a Autenticação (A CHAVE) no Header
    // (Conforme a documentação pede)
    request.headers['Api-Key'] = PLANT_ID_SECRET;

    // 5. Adicionar os "text fields" (os atributos)
    // A documentação diz: "attributes are sent in text fields"
    // (O 'organs' é enviado como uma lista de campos)
    //request.fields['organs'] = 'leaf';
    // request.fields['organs'] = 'flower'; // (Você pode adicionar mais se quiser)

    // 6. Adicionar o arquivo (a imagem)
    // A documentação diz: "images are sent as files"
    request.files.add(await http.MultipartFile.fromPath('images', foto.path));

    // 7. Enviar a requisição
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    
    // --- FIM DO NOVO MÉTODO ---

    // 8. Processar a resposta (igual a antes)
    if (response.statusCode == 200 || response.statusCode == 201 ) {
      final data = jsonDecode(response.body);
      
      if (data['suggestions'] != null && data['suggestions'].isNotEmpty) {
        final melhorSugestao = data['suggestions'][0]['plant_name'] ?? 'Desconhecida';
        
        final regaDias = 7; 
        final solHoras = 4;

        setState(() {
          _especieController.text = melhorSugestao;
          _regaController.text = regaDias.toString();
          _solController.text = solHoras.toString();
        });

      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nenhuma planta identificada pela Plant.id.')),
        );
      }
    } else {
      // O erro 404 deve sumir. Se der 401 ou 403, é a chave. Se der 400, é o formato.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro na API (${response.statusCode}): ${response.body}')),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erro de processamento: $e')),
    );
  } finally {
    // 9. Esconder o "carregando"
    setState(() {
      _estaIdentificando = false;
    });
  }
}


  // Método para mostrar o calendário e o seletor de hora
  Future<void> _selecionarData(BuildContext context,
      {required bool isAdubacao}) async {
    
    // 1. SELETOR DE DATA
    final DateTime? dataSelecionada = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(), 
      lastDate: DateTime(2101),
      locale: const Locale('pt', 'BR'),
    );

    if (dataSelecionada == null) return; 

    // 2. SELETOR DE HORA
    final TimeOfDay? horaSelecionada = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (horaSelecionada == null) return; 

    // 3. COMBINAR DATA E HORA
    final DateTime dataCompleta = DateTime(
      dataSelecionada.year,
      dataSelecionada.month,
      dataSelecionada.day,
      horaSelecionada.hour,
      horaSelecionada.minute,
    );

    // 4. Atualiza o estado
    setState(() {
      if (isAdubacao) {
        _dataAdubacao = dataCompleta;
      } else {
        _dataTrocaTerra = dataCompleta;
      }
    });
  }


  void _salvarPlanta() {
    final nome = _nomeController.text;
    final especie = _especieController.text;
    final rega = int.tryParse(_regaController.text) ?? 0;
    final sol = int.tryParse(_solController.text) ?? 0;

    // Se o usuário não selecionou uma data, usamos uma data padrão (1970)
    final adubacao = _dataAdubacao ?? DateTime(1970);
    final trocaTerra = _dataTrocaTerra ?? DateTime(1970);

    if (nome.isEmpty || especie.isEmpty) {
      return;
    }
    
    // Reutiliza o ID existente para a Planta (ou cria um novo se for adição)
    final String idExistente = widget.plantaParaEditar?.id ?? DateTime.now().millisecondsSinceEpoch.toString();

    // Nota: proximaRega é um placeholder. A HomePage fará o cálculo final.
    final novaPlanta = Planta(
      id: idExistente, 
      nome: nome,
      especie: especie,
      frequenciaRega: rega,
      horasSol: sol,
      proximaAdubacao: adubacao,
      proximaTrocaTerra: trocaTerra,
      proximaRega: DateTime.now() // Placeholder
    ); 
    
    // Retorna a planta salva e o índice para a HomePage
    Navigator.pop(context, {
      'planta': novaPlanta, 
      'index': widget.indexParaEditar, 
    });
  }

  @override
  Widget build(BuildContext context) {
    String titulo = widget.plantaParaEditar != null ? 'Editar Planta' : 'Cadastrar Nova Planta';
    
    return Scaffold(
      appBar: AppBar(
        title: Text(titulo),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // 1. BOTÃO DE RECONHECIMENTO (COM LOADING)
              ElevatedButton.icon(
                icon: _estaIdentificando 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.camera_alt_outlined),
                label: Text(_estaIdentificando ? 'Identificando...' : 'Identificar por Foto'),
                onPressed: _estaIdentificando ? null : _identificarPlanta, // <--- Chamada à função da API
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 20), // Espaçamento

              // 2. CAMPOS DO FORMULÁRIO (LISTA ÚNICA)
              TextField(
                controller: _nomeController,
                decoration: const InputDecoration(labelText: 'Nome da Planta (Apelido)'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _especieController,
                decoration: const InputDecoration(labelText: 'Espécie (Ex: Samambaia)'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _regaController,
                decoration: const InputDecoration(labelText: 'Frequência de Rega (dias)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _solController,
                decoration: const InputDecoration(labelText: 'Horas de Sol (por dia)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),

              // 3. SELETORES DE DATA/HORA
              const Text('Próximos Cuidados:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),

              // Seletor de Adubação
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _dataAdubacao == null
                        ? 'Próxima adubação:'
                        : 'Adubar em: ${_formatadorData.format(_dataAdubacao!)}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  TextButton(
                    onPressed: () => _selecionarData(context, isAdubacao: true),
                    child: const Text('Selecionar Data e Hora'),
                  ),
                ],
              ),

              // Seletor de Troca de Terra
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _dataTrocaTerra == null
                        ? 'Próxima troca de terra:'
                        : 'Trocar terra em: ${_formatadorData.format(_dataTrocaTerra!)}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  TextButton(
                    onPressed: () => _selecionarData(context, isAdubacao: false),
                    child: const Text('Selecionar Data e Hora'),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _salvarPlanta,
                child: const Text('Salvar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// -------------------------------------------------------------------
// DETALHES DA PLANTA
// -------------------------------------------------------------------

class DetalhePlantaPage extends StatelessWidget {
  final Planta planta;
  const DetalhePlantaPage({super.key, required this.planta});

  @override
  Widget build(BuildContext context) {
    final DateFormat formatadorData = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: Text(planta.nome),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Espécie: ${planta.especie}',
              style: TextStyle(
                  fontSize: 18,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[700]),
            ),

            const SizedBox(height: 20),

            const Text(
              'Regar a cada:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              planta.frequenciaRega > 0
                  ? '${planta.frequenciaRega} dias'
                  : 'Rega não especificada',
              style: TextStyle(
                  fontSize: 20,
                  color: planta.frequenciaRega > 0
                      ? Colors.blue[700]
                      : Colors.grey[600]),
            ),

            const SizedBox(height: 20),

            const Text(
              'Necessidade de sol:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              planta.horasSol > 0
                  ? '${planta.horasSol} horas por dia'
                  : 'Sol não especificado',
              style: TextStyle(
                  fontSize: 20,
                  color: planta.horasSol > 0
                      ? Colors.orange[700]
                      : Colors.grey[600]),
            ),

            const SizedBox(height: 20),

            const Text(
              'Próxima Adubação:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              planta.proximaAdubacao.isAfter(DateTime(1971))
                  ? formatadorData.format(planta.proximaAdubacao)
                  : 'Não especificado',
              style: TextStyle(
                  fontSize: 20,
                  color: planta.proximaAdubacao.isAfter(DateTime(1971))
                      ? Colors.brown[700]
                      : Colors.grey[600]),
            ),

            const SizedBox(height: 20),

            const Text(
              'Próxima Troca de Terra:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              planta.proximaTrocaTerra.isAfter(DateTime(1971))
                  ? formatadorData.format(planta.proximaTrocaTerra)
                  : 'Não especificado',
              style: TextStyle(
                  fontSize: 20,
                  color: planta.proximaTrocaTerra.isAfter(DateTime(1971))
                      ? Colors.black87
                      : Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}