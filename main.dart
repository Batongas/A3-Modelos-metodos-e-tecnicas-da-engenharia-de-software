// Importa o pacote principal do Flutter para construir a interface
import 'package:flutter/material.dart';

// Este é o "molde" para cada planta que você cadastrar.
class Planta {
  String nome; // Ex: "Minha Samambaia"
  String especie; // Ex: "Samambaia-americana"
  int frequenciaRega; // Ex: Regar a cada 2 dias
  int horasSol; // Ex: 3 horas de sol indireto

  // Isso é um "construtor" para criar a planta
  Planta({
    required this.nome,
    required this.especie,
    required this.frequenciaRega,
    required this.horasSol,
  });
}

// --- Ponto de Entrada do App ---
// O Flutter começa a executar o app por aqui
void main() {
  runApp(const MeuApp());
}

// O widget principal que configura o app
class MeuApp extends StatelessWidget {
  const MeuApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Digital Garden' ,
      // Define o tema (cores) do aplicativo
      theme: ThemeData(
        primarySwatch: Colors.green, // Define a cor principal como verde
        useMaterial3: true,
      ),
      // Define a 'HomePage' como a tela inicial
      home: HomePage(),

    );
  }
}

// Esta parte guarda a configuração e NUNCA MUDA.
class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  // criar classe de "Estado" (a parte que muda) abaixo.
  @override
  State<HomePage> createState() => _HomePageState();
}

// Esta é a parte que GUARDA OS DADOS e pode ser REDESENHADA.
// O '_' (underline) no nome torna a classe "privada" (só este arquivo a vê).
class _HomePageState extends State<HomePage> {
  // Esta é a lista de plantas. Ela é o "estado" da sua tela.
  // Quando esta lista mudar, queremos que a tela mude também.
  List<Planta> minhasPlantas = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Digital Garden'),
      ),

      body: ListView.builder(

        itemCount: minhasPlantas.length,
        itemBuilder: (context, index) {
          final planta = minhasPlantas[index];

          return ListTile(
            title: Text(planta.nome),
            subtitle: Text(planta.especie),
            leading: Icon(Icons.local_florist),// Ícone de flor
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
          onPressed: () {
            //navegar para a nova tela de cadastro
            _navegarParaCadastro(context);
          },
          child: Icon(Icons.add),
      ),
    );
  }

  void _navegarParaCadastro(BuildContext context) async {
    // 'async' e 'await' são usados para esperar a tela de cadastro

    final novaPlanta = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CadastroPlantaPage()),

    );
    if (novaPlanta != null) {
      setState(() {
        minhasPlantas.add(novaPlanta);
      });
    }
  }
}

class CadastroPlantaPage extends StatefulWidget {
  const CadastroPlantaPage({Key? key}) : super(key: key);

  @override
  _CadastroPlantaPageState createState() => _CadastroPlantaPageState();
}

class _CadastroPlantaPageState extends State<CadastroPlantaPage> {
  final _nomeController = TextEditingController();
  final _especieController = TextEditingController();
  final _regaController = TextEditingController();
  final _solController = TextEditingController();

  void _salvarPlanta() {
    final nome = _nomeController.text;
    final especie = _especieController.text;
    final rega = int.tryParse(_regaController.text) ?? 0;
    final sol = int.tryParse(_solController.text) ?? 0;
    final novaPlanta = Planta(
      nome: nome,
      especie: especie,
      frequenciaRega: rega,
      horasSol: sol,
    );

    Navigator.pop(context, novaPlanta);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cadastrar nova Planta'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nomeController,
              decoration: InputDecoration(labelText: 'Nome da planta (Apelido)'),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _especieController,
              decoration: InputDecoration(labelText: 'Espécie da planta (Ex: Samambaia'),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _regaController,
              decoration: InputDecoration(labelText: 'Frequência de rega (dias)'),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 10),
            TextField(
              controller: _solController,
              decoration: InputDecoration(labelText: 'Horas de Sol (por dia)'),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _salvarPlanta, // Chama o método de salvar
              child: Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }
}


