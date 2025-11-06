// Importa o pacote principal do Flutter para construir a interface
import 'package:flutter/material.dart';
// Importa os pacotes para salvar (SharedPreferences) e para converter texto (JSON)
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
// Importa o pacote para formatar datas (ex: dd/MM/yyyy)
import 'package:intl/intl.dart';
// Importa os pacotes para o DatePicker funcionar em Português
import 'package:flutter_localizations/flutter_localizations.dart';

class Planta {
  String nome;
  String especie;
  int frequenciaRega;
  int horasSol;
  DateTime proximaAdubacao;
  DateTime proximaTrocaTerra;

  Planta({
    required this.nome,
    required this.especie,
    required this.frequenciaRega,
    required this.horasSol,
    required this.proximaAdubacao,
    required this.proximaTrocaTerra,
  });

  //  Converter planta para JSON
  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'especie': especie,
      'frequenciaRega': frequenciaRega,
      'horasSol': horasSol,
      // DateTime não pode ser salvo direto, converter para String
      'proximaAdubacao': proximaAdubacao.toIso8601String(),
      'proximaTrocaTerra': proximaTrocaTerra.toIso8601String(),
    };
  }

  // Criar planta a partir do JSON
  factory Planta.fromJson(Map<String, dynamic> json) {
    return Planta(
      nome: json['nome'],
      especie: json['especie'],
      frequenciaRega: json['frequenciaRega'],
      horasSol: json['horasSol'],
      // Converte a String (padrão ISO) de volta para DateTime
      // Se não existir, usa uma data padrão antiga (1970)
      proximaAdubacao: json['proximaAdubacao'] != null
          ? DateTime.parse(json['proximaAdubacao'])
          : DateTime(1970),
      proximaTrocaTerra: json['proximaTrocaTerra'] != null
          ? DateTime.parse(json['proximaTrocaTerra'])
          : DateTime(1970),
    );
  }
}

//  Ponto de Entrada do App
void main() {
  runApp(const MeuApp());
}

// O widget principal que configura o app
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

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Planta> minhasPlantas = [];

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

  void _processarResultadoNavegacao(Map? resultado) {
    if (resultado == null) return;

    final planta = resultado['planta'] as Planta;
    final index = resultado['index'] as int?;

    setState(() {
      if (index != null) {
        minhasPlantas[index] = planta;
      } else {
        minhasPlantas.add(planta);
      }
    });
    _salvarPlantas();
  }

  void _navegarParaCadastro() async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CadastroPlantaPage()),
    );
    if (!mounted) return;
    _processarResultadoNavegacao(resultado);
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
          return Dismissible(
            key: Key(planta.nome + index.toString()),
            direction: DismissDirection.startToEnd,
            onDismissed: (direction) {
              setState(() {
                minhasPlantas.removeAt(index);
              });
              _salvarPlantas();

              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${planta.nome} excluída')),
              );
            },
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            child: ListTile(
              title: Text(planta.nome),
              subtitle: Text(planta.especie),
              leading: Icon(Icons.local_florist, color: Colors.green[600]),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
              onTap: () async {
                final resultado = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        DetalhePlantaPage(planta: planta, index: index),
                  ),
                );
                 if (!mounted) return;
                _processarResultadoNavegacao(resultado);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navegarParaCadastro,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class CadastroPlantaPage extends StatefulWidget {
  final Planta? plantaParaEditar;
  final int? indexParaEditar;

  const CadastroPlantaPage(
      {super.key, this.plantaParaEditar, this.indexParaEditar});

  @override
  State<CadastroPlantaPage> createState() => _CadastroPlantaPageState();
}

class _CadastroPlantaPageState extends State<CadastroPlantaPage> {
  final _nomeController = TextEditingController();
  final _especieController = TextEditingController();
  final _regaController = TextEditingController();
  final _solController = TextEditingController();

  DateTime? _dataAdubacao;
  DateTime? _dataTrocaTerra;
  final DateFormat _formatadorData = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    if (widget.plantaParaEditar != null) {
      final planta = widget.plantaParaEditar!;
      _nomeController.text = planta.nome;
      _especieController.text = planta.especie;
      _regaController.text = planta.frequenciaRega.toString();
      _solController.text = planta.horasSol.toString();

      if (planta.proximaAdubacao.isAfter(DateTime(1970))) {
        _dataAdubacao = planta.proximaAdubacao;
      }
      if (planta.proximaTrocaTerra.isAfter(DateTime(1970))) {
        _dataTrocaTerra = planta.proximaTrocaTerra;
      }
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _especieController.dispose();
    _regaController.dispose();
    _solController.dispose();
    super.dispose();
  }

  Future<void> _selecionarData(BuildContext context,
      {required bool isAdubacao}) async {
    final DateTime? dataSelecionada = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      locale: const Locale('pt', 'BR'),
    );

    if (dataSelecionada != null) {
      setState(() {
        if (isAdubacao) {
          _dataAdubacao = dataSelecionada;
        } else {
          _dataTrocaTerra = dataSelecionada;
        }
      });
    }
  }

  void _salvarPlanta() {
    final nome = _nomeController.text;
    final especie = _especieController.text;
    final rega = int.tryParse(_regaController.text) ?? 0;
    final sol = int.tryParse(_solController.text) ?? 0;
    final adubacao = _dataAdubacao ?? DateTime(1970);
    final trocaTerra = _dataTrocaTerra ?? DateTime(1970);

    if (nome.isEmpty || especie.isEmpty) {
      return;
    }

    final plantaAtualizada = Planta(
      nome: nome,
      especie: especie,
      frequenciaRega: rega,
      horasSol: sol,
      proximaAdubacao: adubacao,
      proximaTrocaTerra: trocaTerra,
    );

    Navigator.pop(context, {
      'planta': plantaAtualizada,
      'index': widget.indexParaEditar,
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.plantaParaEditar != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Planta' : 'Cadastrar Nova Planta'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _nomeController,
                decoration:
                    const InputDecoration(labelText: 'Nome da Planta (Apelido)'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _especieController,
                decoration:
                    const InputDecoration(labelText: 'Espécie (Ex: Samambaia)'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _regaController,
                decoration:
                    const InputDecoration(labelText: 'Frequência de Rega (dias)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _solController,
                decoration:
                    const InputDecoration(labelText: 'Horas de Sol (por dia)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              const Text('Próximos Cuidados:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
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
                    child: const Text('Selecionar Data'),
                  ),
                ],
              ),
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
                    onPressed: () =>
                        _selecionarData(context, isAdubacao: false),
                    child: const Text('Selecionar Data'),
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

class DetalhePlantaPage extends StatefulWidget {
  final Planta planta;
  final int index;

  const DetalhePlantaPage(
      {super.key, required this.planta, required this.index});

  @override
  State<DetalhePlantaPage> createState() => _DetalhePlantaPageState();
}

class _DetalhePlantaPageState extends State<DetalhePlantaPage> {
  void _navegarParaEdicao() async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CadastroPlantaPage(
          plantaParaEditar: widget.planta,
          indexParaEditar: widget.index,
        ),
      ),
    );

    if (!mounted) return;

    if (resultado != null) {
      Navigator.pop(context, resultado);
    }
  }

  @override
  Widget build(BuildContext context) {
    final DateFormat formatadorData = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.planta.nome),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _navegarParaEdicao,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Espécie: ${widget.planta.especie}',
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
              widget.planta.frequenciaRega > 0
                  ? '${widget.planta.frequenciaRega} dias'
                  : 'Rega não especificada',
              style: TextStyle(
                  fontSize: 20,
                  color: widget.planta.frequenciaRega > 0
                      ? Colors.blue[700]
                      : Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            const Text(
              'Necessidade de sol:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              widget.planta.horasSol > 0
                  ? '${widget.planta.horasSol} horas por dia'
                  : 'Sol não especificado',
              style: TextStyle(
                  fontSize: 20,
                  color: widget.planta.horasSol > 0
                      ? Colors.orange[700]
                      : Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            const Text(
              'Próxima Adubação:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              widget.planta.proximaAdubacao.isAfter(DateTime(1971))
                  ? formatadorData.format(widget.planta.proximaAdubacao)
                  : 'Não especificado',
              style: TextStyle(
                  fontSize: 20,
                  color: widget.planta.proximaAdubacao.isAfter(DateTime(1971))
                      ? Colors.brown[700]
                      : Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            const Text(
              'Próxima Troca de Terra:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              widget.planta.proximaTrocaTerra.isAfter(DateTime(1971))
                  ? formatadorData.format(widget.planta.proximaTrocaTerra)
                  : 'Não especificado',
              style: TextStyle(
                  fontSize: 20,
                  color: widget.planta.proximaTrocaTerra.isAfter(DateTime(1971))
                      ? Colors.black87
                      : Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
