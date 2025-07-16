import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

//ROTAS
import '../../db/database.dart';
import 'pop/valor_tag.dart';

class RelatorioMensal extends StatefulWidget {
  const RelatorioMensal({super.key});

  @override
  State<RelatorioMensal> createState() => _RelatorioMensalState();
}

class _RelatorioMensalState extends State<RelatorioMensal> {
  List<Expense> _expenses = [];
  final DatabaseHelper dbHelper = DatabaseHelper.instance;
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _refreshExpenses();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Map<String, double> _getExpensesByTag() {
    final now = DateTime.now();
    final Map<String, double> tagData = {};

    for (var expense in _expenses) {
      if (expense.data.year == now.year && expense.data.month == now.month) {
        for (var tag in expense.tags) {
          tagData[tag] = (tagData[tag] ?? 0) + expense.amount;
        }
      }
    }

    return tagData;
  }

  // Dados simulados para os gráficos

  Future<void> _refreshExpenses() async {
    final expenseList = await dbHelper.getExpenses();
    setState(() {
      _expenses = expenseList;
    });
  }

  Future<void> mostrarPopupValorNativo(
    BuildContext context, {
    required String tag,
    required double amount,
    required Color color,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (_) => PopupConfirmacaoAnimada(
        tag: tag,
        amount: amount,
        color: color,
        totalExpenses: _getExpensesByTag().values.fold(0.0, (a, b) => a + b),
      ),
    );
  }

  List<FlSpot> _getMonthlyExpenses() {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final Map<int, double> monthlyData = {};

    for (int i = 1; i <= daysInMonth; i++) {
      monthlyData[i - 1] = 0.0;
    }

    for (var expense in _expenses) {
      if (expense.data.year == now.year && expense.data.month == now.month) {
        final day = expense.data.day - 1;
        monthlyData[day] = (monthlyData[day] ?? 0) + expense.amount;
      }
    }

    return monthlyData.entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final monthlyExpenses = _expenses
        .where((e) =>
            e.data.month == DateTime.now().month &&
            e.data.year == DateTime.now().year)
        .toList();

    final tagExpenses = _getExpensesByTag();
    final List<Color> colors = [
      Colors.purple,
      Colors.blue,
      Colors.orange,
      Colors.green,
      Colors.red,
      Colors.purpleAccent,
      Colors.redAccent,
      Colors.blueAccent,
      Colors.greenAccent,
      Colors.orangeAccent,
    ];

    // Lista de gráficos para o PageView
    final List<Map<String, dynamic>> _charts = [
      {
        'title': 'Gastos por Etiqueta',
        'widget': AspectRatio(
          aspectRatio: 1.0,
          child: PieChart(
            PieChartData(
              sections: tagExpenses.isEmpty
                  ? [
                      PieChartSectionData(
                        value: 1,
                        title: 'Sem dados',
                        color: Colors.grey,
                        radius: 50,
                        titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ]
                  : tagExpenses.entries.toList().asMap().entries.map((entry) {
                      final index = entry.key;
                      final tag = entry.value.key;
                      final amount = entry.value.value;
                      return PieChartSectionData(
                        value: amount,
                        title: ' $tag',
                        color: colors[index % colors.length],
                        radius: 50,
                        titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      );
                    }).toList(),
              centerSpaceRadius: 40,
              sectionsSpace: 2,
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) async {
                  if (event.isInterestedForInteractions &&
                      pieTouchResponse != null &&
                      pieTouchResponse.touchedSection != null) {
                    final touchedIndex =
                        pieTouchResponse.touchedSection!.touchedSectionIndex;
                    if (touchedIndex >= 0 &&
                        touchedIndex < tagExpenses.length) {
                      final touchedTag =
                          tagExpenses.entries.toList()[touchedIndex].key;
                      final touchedAmount =
                          tagExpenses.entries.toList()[touchedIndex].value;
                      final touchedColor = colors[touchedIndex % colors.length];
                      await mostrarPopupValorNativo(
                        context,
                        tag: touchedTag,
                        amount: touchedAmount,
                        color: touchedColor,
                      );
                    }
                  }
                  setState(() {});
                },
              ),
            ),
          ),
        ),
      },
      {
        'title': 'Gastos Mensais',
        'widget': AspectRatio(
          aspectRatio: 2.0,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: _getMonthlyExpenses().map((e) => e.y).isNotEmpty
                  ? (_getMonthlyExpenses()
                          .map((e) => e.y)
                          .reduce((a, b) => a > b ? a : b) *
                      1.2)
                  : 100,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 20,
                    getTitlesWidget: (value, meta) {
                      final day = value.toInt() + 1;
                      final daysInMonth =
                          DateTime.now().month == DateTime.now().month
                              ? DateTime(DateTime.now().year,
                                      DateTime.now().month + 1, 0)
                                  .day
                              : 31;
                      if (day % 5 != 0 && day != 1 && day != daysInMonth) {
                        return const SideTitleWidget(
                          axisSide: AxisSide.bottom,
                          child: Text(''),
                        );
                      }
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        space: 4,
                        child: Text(
                          day.toString(),
                          style: const TextStyle(
                            color: Colors.blueGrey,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
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
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ),
              barGroups: _getMonthlyExpenses().asMap().entries.map((entry) {
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
                      width: 6,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                      backDrawRodData: BackgroundBarChartRodData(
                        show: true,
                        toY: 0,
                        color: Colors.transparent,
                      ),
                    ),
                  ],
                  showingTooltipIndicators: spot.y > 0 ? [0] : [],
                );
              }).toList(),
            ),
          ),
        ),
      },
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.purple,
        title: const Text(
          'Relatório Mensal',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.arrow_left,
                    size: 40,
                    color:
                        _currentPage > 0 ? Colors.purple : Colors.transparent,
                  ),
                  onPressed: _currentPage > 0
                      ? () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      : null,
                ),
                Text(
                  _charts[_currentPage]['title'],
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: Icon(
                    Icons.arrow_right,
                    size: 40,
                    color: _currentPage < _charts.length - 1
                        ? Colors.purple
                        : Colors.transparent,
                  ),
                  onPressed: _currentPage < _charts.length - 1
                      ? () {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              width: MediaQuery.of(context).size.width,
              child: Stack(
                children: [
                  PageView.builder(
                    controller: _pageController,
                    itemCount: _charts.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      return _charts[index]['widget'];
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Todos os Gastos do Mês',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            monthlyExpenses.isEmpty
                ? const Text('Nenhum gasto registrado este mês.')
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: monthlyExpenses.length,
                    itemBuilder: (context, index) {
                      final expense = monthlyExpenses[index];
                      return ListTile(
                        title: Text(expense.title),
                        subtitle: Text(
                          'R\$ ${expense.amount.toStringAsFixed(2)} - ${expense.tags.join(', ')}',
                        ),
                        trailing: Text(
                          DateFormat('dd/MM').format(expense.data),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const DonutSliderExample(),
    );
  }
}

class DonutSliderExample extends StatefulWidget {
  const DonutSliderExample({super.key});

  @override
  State<DonutSliderExample> createState() => _DonutSliderExampleState();
}

class _DonutSliderExampleState extends State<DonutSliderExample> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Dados simulados para os gráficos
  final List<Map<String, dynamic>> _charts = [
    {
      'title': 'Gastos por Tag',
      'colors': [Colors.red, Colors.blue, Colors.green],
    },
    {
      'title': 'Gastos por Categoria',
      'colors': [Colors.purple, Colors.yellow, Colors.orange],
    },
    {
      'title': 'Gastos por Mês',
      'colors': [Colors.cyan, Colors.pink, Colors.teal],
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gráficos Deslizáveis'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  itemCount: _charts.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _charts[index]['title'],
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Simulação de um gráfico de donut
                          Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: SweepGradient(
                                colors: _charts[index]['colors'],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Container(
                                width: 80,
                                height: 80,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          // Indicador de página

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
