import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'cadastros/cad_etiquetas.dart';
import 'db/database.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'relatorios/relatorio_mensal.dart';
import 'animations/confirmacao.dart';

class PersonalWalletApp extends StatelessWidget {
  const PersonalWalletApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Carteira Pessoal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.purple,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Expense> _expenses = [];
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = MoneyMaskedTextController(
    initialValue: 0.0,
    leftSymbol: 'R\$ ',
    decimalSeparator: ',',
    thousandSeparator: '.',
  );
  final DatabaseHelper dbHelper = DatabaseHelper.instance;
  List<String> etiquetas = [];
  final Set<String> selecionadas = {};
  DateTime _selectedDate = DateTime.now();

  Future<void> _refreshExpenses() async {
    final expenseList = await dbHelper.getExpenses();
    // print(expenseList); // Para debug
    setState(() {
      _expenses = expenseList;
    });
  }

  Future<void> _refreshEtiquetas() async {
    final etiquetaList = await dbHelper.getEtiquetas();
    print(etiquetaList); // Para debug
    setState(() {
      etiquetas = etiquetaList.map((e) => e.title).toList();
    });
  }

  Future<void> _deleteExpense(int id) async {
    await dbHelper.deleteExpense(id);
    await _refreshExpenses();
  }

  Future<void> _selecionarData(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('pt', 'BR'), // para calendário em português
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _addExpense() async {
    if (_formKey.currentState!.validate()) {
      double valor = _amountController.numberValue;

      final expense = Expense(
        title: _titleController.text,
        amount: valor,
        data: _selectedDate,
        tags: selecionadas.toList(),
      );
      await dbHelper.insertExpense(expense);
      await _refreshExpenses();
      _titleController.clear();
      _amountController.updateValue(0.0);
      setState(() {
        selecionadas.clear();
      });
    }
  }

  Future<void> _showAdicionardialog() async {
    return showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Adicionar Gasto'),
              content: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(labelText: 'Título'),
                        validator: (value) =>
                            value!.isEmpty ? 'Insira um título' : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                          controller: _amountController,
                          decoration:
                              const InputDecoration(labelText: 'Valor (R\$)'),
                          keyboardType: TextInputType.number,
                          validator: (_) {
                            final valor = _amountController.numberValue;
                            if (valor <= 0) return 'Insira um valor válido';
                            return null;
                          }),
                      const SizedBox(height: 10),

                      // Campo de Data
                      GestureDetector(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                            locale: const Locale('pt', 'BR'),
                          );
                          if (picked != null) {
                            setState(() {
                              _selectedDate = picked;
                            });
                            setStateDialog(() {}); // Atualiza o diálogo
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Data',
                            border: OutlineInputBorder(),
                          ),
                          child: Text(
                            '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        children: etiquetas.map(
                          (etiqueta) {
                            final selecionado = selecionadas.contains(etiqueta);
                            return ChoiceChip(
                              label: Text(etiqueta),
                              selected: selecionado,
                              selectedColor: Colors.purple,
                              onSelected: (bool selected) {
                                setStateDialog(() {
                                  if (selected) {
                                    if (selecionadas.length > 0) return;
                                    selecionadas.add(etiqueta);
                                  } else {
                                    selecionadas.remove(etiqueta);
                                  }
                                });
                              },
                              labelStyle: TextStyle(
                                  color: selecionado
                                      ? Colors.white
                                      : Colors.black),
                            );
                          },
                        ).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                SizedBox(
                  width: MediaQuery.of(context).size.width,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple),
                    onPressed: () async {
                      if (!_formKey.currentState!.validate()) return;
                      _addExpense();
                      Navigator.pop(context);
                      await mostrarPopupConfirmacaoNativo(context);
                    },
                    child: const Text(
                      'Adicionar',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  List<FlSpot> _getWeeklyExpenses() {
    final Map<int, double> weeklyData = {};
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    for (var expense in _expenses) {
      if (expense.data.isAfter(startOfWeek)) {
        final day = expense.data.weekday - 1;
        weeklyData[day] = (weeklyData[day] ?? 0) + expense.amount;
      }
    }

    return List.generate(7, (index) {
      return FlSpot(index.toDouble(), weeklyData[index] ?? 0);
    });
  }

  void _showMonthlyReport() {
    showDialog(
      context: context,
      builder: (context) {
        final monthlyExpenses = _expenses
            .where((e) => e.data.month == DateTime.now().month)
            .toList();
        return AlertDialog(
          title: const Text('Relatório Mensal'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: monthlyExpenses.isEmpty
                  ? [const Text('Nenhum gasto registrado este mês.')]
                  : monthlyExpenses.map((e) {
                      return ListTile(
                          title: Text(e.title),
                          subtitle: Text(
                              'R\$ ${e.amount.toStringAsFixed(2)} - ${e.tags.join(', ')}'),
                          trailing: Text(DateFormat('dd/MM').format(e.data)));
                    }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.purple,
        title: const Text(
          'Carteira Pessoal',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month, color: Colors.white),
            onPressed: _showMonthlyReport,
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.purple,
              ),
              child: Text('Menu',
                  style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ListTile(
              leading: const Icon(Icons.label),
              title: const Text('Etiquetas'),
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const EtiquetaScreen()));
                // Navegar ou fazer algo
              },
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart),
              title: const Text('Relatorio Mensal'),
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const RelatorioMensal()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Configurações'),
              onTap: () {},
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Gastos Semanais',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: AspectRatio(
                aspectRatio: 1.6,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: _getWeeklyExpenses().map((e) => e.y).isNotEmpty
                        ? (_getWeeklyExpenses()
                                .map((e) => e.y)
                                .reduce((a, b) => a > b ? a : b) *
                            1.2)
                        : 100, // Valor padrão se não houver dados
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          getTitlesWidget: (value, meta) {
                            const days = [
                              'Seg',
                              'Ter',
                              'Qua',
                              'Qui',
                              'Sex',
                              'Sáb',
                              'Dom'
                            ];
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              space: 4,
                              child: Text(
                                days[value.toInt()],
                                style: const TextStyle(
                                  color: Colors.blueGrey,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (_) => Colors.transparent,
                        tooltipPadding: EdgeInsets.zero,
                        tooltipMargin: 8,
                        getTooltipItem: (
                          BarChartGroupData group,
                          int groupIndex,
                          BarChartRodData rod,
                          int rodIndex,
                        ) {
                          return BarTooltipItem(
                            'R\$ ${rod.toY.toStringAsFixed(2)}',
                            const TextStyle(
                              // color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                    ),
                    barGroups:
                        _getWeeklyExpenses().asMap().entries.map((entry) {
                      final index = entry.key;
                      final spot = entry.value;
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: spot.y,
                            gradient: const LinearGradient(
                              colors: [Colors.purple, Colors.purpleAccent],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                            width: 10,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                          ),
                        ],
                        showingTooltipIndicators: spot.y > 0 ? [0] : [],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const SizedBox(height: 24),
            const Text(
              'Gastos Recentes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _expenses.length,
              itemBuilder: (context, index) {
                final expense = _expenses[index];
                return ListTile(
                  title: Text(expense.title),
                  subtitle: Text(
                    'R\$ ${expense.amount.toStringAsFixed(2)} - ${expense.tags.join(', ')}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      if (expense.id != null) {
                        _deleteExpense(expense.id!);
                      }
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: SizedBox(
        height: 65,
        width: 65,
        child: FloatingActionButton(
          onPressed: () async {
            await _refreshEtiquetas();
            _showAdicionardialog();
          },
          child: const Icon(
            Icons.add,
            color: Colors.purple,
            size: 50,
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    _refreshExpenses();
    super.initState();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }
}
