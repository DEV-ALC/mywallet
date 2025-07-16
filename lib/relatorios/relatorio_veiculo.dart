import 'package:flutter/material.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';

//ROTAS
import '../../db/database.dart';
import '../../cadastros/cad_veiculo.dart';
import '../animations/confirmacao.dart';

class Vehicle extends StatefulWidget {
  const Vehicle({super.key});

  @override
  State<Vehicle> createState() => _VehicleState();
}

class _VehicleState extends State<Vehicle> {
  List<String> etiquetas = [];
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
  final Set<String> selecionadas = {};
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _refreshEtiquetas();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _refreshEtiquetas() async {
    final etiquetaList = await dbHelper.getEtiquetas();
    print(etiquetaList); // Para debug
    setState(() {
      etiquetas = etiquetaList.map((e) => e.title).toList();
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.purple,
        title: const Text(
          'Gastos Veiculos',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (context) => VehicleForm())),
            icon: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, size: 15, color: Colors.white),
                Icon(Icons.directions_car, color: Colors.white),
              ],
            ),
          )
        ],
      ),
      body: Container(),
      floatingActionButton: SizedBox(
        height: 65,
        width: 65,
        child: FloatingActionButton(
          onPressed: () async {
            _showAdicionardialog();
          },
          backgroundColor: Colors.purple,
          elevation: 6,
          child: const Icon(
            Icons.add,
            color: Colors.white,
            size: 32,
          ),
        ),
      ),
    );
  }
}
