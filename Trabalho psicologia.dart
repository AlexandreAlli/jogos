import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(const MeuApp());
}

class MeuApp extends StatelessWidget {
  const MeuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Psicologia App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const PaginaInicial(),
    );
  }
}

class PaginaInicial extends StatefulWidget {
  const PaginaInicial({super.key});

  @override
  State<PaginaInicial> createState() => _EstadoPaginaInicial();
}

class _EstadoPaginaInicial extends State<PaginaInicial> {
  int _indiceSeleccionado = 0;
  List<Paciente> pacientes = [];
  List<Consulta> consultas = [];

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    final prefs = await SharedPreferences.getInstance();

    // Carregar pacientes
    final pacientesJson = prefs.getStringList('pacientes') ?? [];
    setState(() {
      pacientes =
          pacientesJson
              .map((json) => Paciente.fromJson(jsonDecode(json)))
              .toList();
    });

    // Carregar consultas
    final consultasJson = prefs.getStringList('consultas') ?? [];
    setState(() {
      consultas =
          consultasJson
              .map((json) => Consulta.fromJson(jsonDecode(json)))
              .toList();
    });
  }

  Future<void> _salvarDados() async {
    final prefs = await SharedPreferences.getInstance();

    // Salvar pacientes
    final pacientesJson =
        pacientes.map((paciente) => jsonEncode(paciente.toJson())).toList();
    await prefs.setStringList('pacientes', pacientesJson);

    // Salvar consultas
    final consultasJson =
        consultas
            .map((consulta) => jsonEncode(consulta.toJson()))
            .toList();
    await prefs.setStringList('consultas', consultasJson);
  }

  void _adicionarPaciente(String nome) {
    if (nome.trim().isEmpty) return;

    setState(() {
      pacientes.add(
        Paciente(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          nome: nome,
        ),
      );
    });
    _salvarDados();
  }

  void _adicionarConsulta(String idPaciente, DateTime dataHora) {
    setState(() {
      consultas.add(
        Consulta(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          idPaciente: idPaciente,
          dataHora: dataHora,
        ),
      );
    });
    _salvarDados();
  }

  // Obter consultas dos próximos 7 dias
  List<Consulta> _obterConsultasProximas() {
    final agora = DateTime.now();
    final hoje = DateTime(agora.year, agora.month, agora.day);
    final proximaSemana = hoje.add(const Duration(days: 7));

    return consultas.where((consulta) {
        final dataConsulta = DateTime(
          consulta.dataHora.year,
          consulta.dataHora.month,
          consulta.dataHora.day,
        );
        return dataConsulta.isAtSameMomentAs(hoje) ||
            (dataConsulta.isAfter(hoje) &&
                dataConsulta.isBefore(proximaSemana));
      }).toList()
      ..sort((a, b) => a.dataHora.compareTo(b.dataHora)); // Ordenar por data
  }

  // Contar consultas da semana atual (segunda a domingo)
  Map<String, int> _obterContadorSemanal() {
    final agora = DateTime.now();

    // Encontrar a segunda-feira da semana atual
    final diasDesdeSegunda = (agora.weekday - 1) % 7;
    final segundaAtual = DateTime(
      agora.year,
      agora.month,
      agora.day,
    ).subtract(Duration(days: diasDesdeSegunda));

    // Encontrar o domingo da semana atual
    final domingoProximo = segundaAtual.add(const Duration(days: 6));

    final consultasSemanais =
        consultas.where((consulta) {
          return consulta.dataHora.isAfter(
                segundaAtual.subtract(const Duration(seconds: 1)),
              ) &&
              consulta.dataHora.isBefore(
                domingoProximo.add(const Duration(days: 1)),
              );
        }).toList();

    final Map<String, int> contadorPacientes = {};

    for (var consulta in consultasSemanais) {
      final paciente = pacientes.firstWhere(
        (p) => p.id == consulta.idPaciente,
        orElse: () => Paciente(id: '', nome: 'Desconhecido'),
      );

      contadorPacientes[paciente.nome] = (contadorPacientes[paciente.nome] ?? 0) + 1;
    }

    return contadorPacientes;
  }

  // Tela de consultas dos próximos 7 dias
  Widget _construirTelaConsultasProximas() {
    final consultasProximas = _obterConsultasProximas();

    return consultasProximas.isEmpty
        ? const Center(child: Text('Não há consultas para os próximos 7 dias'))
        : ListView.builder(
          itemCount: consultasProximas.length,
          itemBuilder: (context, index) {
            final consulta = consultasProximas[index];
            final paciente = pacientes.firstWhere(
              (p) => p.id == consulta.idPaciente,
              orElse: () => Paciente(id: '', nome: 'Desconhecido'),
            );

            // Formatar a data para exibição
            final dataConsulta = consulta.dataHora;
            final eHoje = DateTime(
              dataConsulta.year,
              dataConsulta.month,
              dataConsulta.day,
            ).isAtSameMomentAs(
              DateTime(
                DateTime.now().year,
                DateTime.now().month,
                DateTime.now().day,
              ),
            );

            final textoData =
                eHoje
                    ? 'Consultas'
                    : '${dataConsulta.day}/${dataConsulta.month}/${dataConsulta.year}';

            return Card(
              margin: const EdgeInsets.all(8.0),
              child: ListTile(
                title: Text(paciente.nome),
                subtitle: Text(
                  '$textoData - ${dataConsulta.hour}:${dataConsulta.minute.toString().padLeft(2, '0')}',
                ),
                leading: const CircleAvatar(child: Icon(Icons.person)),
              ),
            );
          },
        );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> telas = [
      // Tela de Consultas dos próximos 7 dias
      Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Consultas dos Próximos 7 Dias',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Expanded(child: _construirTelaConsultasProximas()),
        ],
      ),

      // Tela de Pacientes
      _construirTelaPacientes(),

      // Tela de Estatísticas Semanais
      Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Consultas da Semana Atual (Segunda a Domingo)',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Expanded(child: _construirTelaEstatisticas()),
        ],
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Psicologia App'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: telas[_indiceSeleccionado],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indiceSeleccionado,
        onTap: (indice) {
          setState(() {
            _indiceSeleccionado = indice;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Hoje',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Pacientes'),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Estatísticas',
          ),
        ],
      ),
      floatingActionButton:
          _indiceSeleccionado == 1
              ? FloatingActionButton(
                onPressed: () => _mostrarDialogoAdicionarPaciente(context),
                child: const Icon(Icons.add),
              )
              : null,
    );
  }

  Widget _construirTelaPacientes() {
    return pacientes.isEmpty
        ? const Center(child: Text('Nenhum paciente cadastrado'))
        : ListView.builder(
          itemCount: pacientes.length,
          itemBuilder: (context, index) {
            final paciente = pacientes[index];

            return Card(
              margin: const EdgeInsets.all(8.0),
              child: ListTile(
                title: Text(paciente.nome),
                leading: const CircleAvatar(child: Icon(Icons.person)),
                onTap: () => _navegarParaDetalhesPaciente(paciente),
              ),
            );
          },
        );
  }

  Widget _construirTelaEstatisticas() {
    final estatisticas = _obterContadorSemanal();

    return estatisticas.isEmpty
        ? const Center(child: Text('Nenhuma consulta esta semana'))
        : ListView.builder(
          itemCount: estatisticas.length,
          itemBuilder: (context, index) {
            final nomePaciente = estatisticas.keys.elementAt(index);
            final contador = estatisticas[nomePaciente]!;

            return Card(
              margin: const EdgeInsets.all(8.0),
              child: ListTile(
                title: Text(nomePaciente),
                trailing: Text(
                  '$contador ${contador == 1 ? 'consulta' : 'consultas'}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            );
          },
        );
  }

  void _mostrarDialogoAdicionarPaciente(BuildContext context) {
    final controladorNome = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Novo Paciente'),
            content: TextField(
              controller: controladorNome,
              decoration: const InputDecoration(labelText: 'Nome do Paciente'),
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () {
                  _adicionarPaciente(controladorNome.text);
                  Navigator.pop(context);
                },
                child: const Text('Adicionar'),
              ),
            ],
          ),
    );
  }

  void _navegarParaDetalhesPaciente(Paciente paciente) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => TeladetalhesPaciente(
              paciente: paciente,
              consultas:
                  consultas.where((a) => a.idPaciente == paciente.id).toList(),
              aoAdicionarConsulta: (dataHora) {
                _adicionarConsulta(paciente.id, dataHora);
              },
            ),
      ),
    );
  }
}

class TeladetalhesPaciente extends StatelessWidget {
  final Paciente paciente;
  final List<Consulta> consultas;
  final Function(DateTime) aoAdicionarConsulta;

  const TeladetalhesPaciente({
    super.key,
    required this.paciente,
    required this.consultas,
    required this.aoAdicionarConsulta,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(paciente.nome)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Próximas Consultas',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Expanded(
            child:
                consultas.isEmpty
                    ? const Center(child: Text('Nenhuma consulta agendada'))
                    : ListView.builder(
                      itemCount: consultas.length,
                      itemBuilder: (context, index) {
                        final consulta = consultas[index];
                        return Card(
                          margin: const EdgeInsets.all(8.0),
                          child: ListTile(
                            title: Text(
                              '${consulta.dataHora.day}/${consulta.dataHora.month}/${consulta.dataHora.year}',
                            ),
                            subtitle: Text(
                              '${consulta.dataHora.hour}:${consulta.dataHora.minute.toString().padLeft(2, '0')}',
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarSeletorDataHora(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _mostrarSeletorDataHora(BuildContext context) async {
    final data = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (data != null) {
      if (!context.mounted) return;

      final hora = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (hora != null) {
        final dataHora = DateTime(
          data.year,
          data.month,
          data.day,
          hora.hour,
          hora.minute,
        );

        aoAdicionarConsulta(dataHora);
      }
    }
  }
}

class Paciente {
  final String id;
  final String nome;

  Paciente({required this.id, required this.nome});

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': nome};
  }

  factory Paciente.fromJson(Map<String, dynamic> json) {
    return Paciente(id: json['id'], nome: json['name']);
  }
}

class Consulta {
  final String id;
  final String idPaciente;
  final DateTime dataHora;

  Consulta({
    required this.id,
    required this.idPaciente,
    required this.dataHora,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': idPaciente,
      'dateTime': dataHora.millisecondsSinceEpoch,
    };
  }

  factory Consulta.fromJson(Map<String, dynamic> json) {
    return Consulta(
      id: json['id'],
      idPaciente: json['patientId'],
      dataHora: DateTime.fromMillisecondsSinceEpoch(json['dateTime']),
    );
  }
}
