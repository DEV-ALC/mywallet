import 'package:flutter/material.dart';

class VehicleForm extends StatefulWidget {
  const VehicleForm({super.key});

  @override
  _VehicleFormState createState() => _VehicleFormState();
}

class _VehicleFormState extends State<VehicleForm>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _modeloController = TextEditingController();
  final _marcaController = TextEditingController();
  final _anoController = TextEditingController();
  final _apelidoController = TextEditingController();
  String? _tipoVeiculo;
  late AnimationController _animationController;
  late Animation<double> _buttonScaleAnimation;

  final List<String> _combustiveis = ['Carro', 'Moto'];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _buttonScaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final vehicle = Vehicle(
        modelo: _modeloController.text,
        marca: _marcaController.text,
        ano: _anoController.text,
        placa: _apelidoController.text,
        combustivel: _tipoVeiculo!,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veículo cadastrado!'),
          backgroundColor: Colors.purple,
          duration: Duration(seconds: 2),
        ),
      );
      _modeloController.clear();
      _marcaController.clear();
      _anoController.clear();
      _apelidoController.clear();
      setState(() => _tipoVeiculo = null);
    }
  }

  @override
  void dispose() {
    _modeloController.dispose();
    _marcaController.dispose();
    _anoController.dispose();
    _apelidoController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastrar Veículo'),
        backgroundColor: Colors.purple,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _apelidoController,
                decoration: InputDecoration(
                  labelText: 'Apelido',
                  prefixIcon: const Icon(Icons.edit_note, color: Colors.purple),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Colors.purple, width: 2),
                  ),
                ),
                validator: (value) => value!.isEmpty ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _modeloController,
                decoration: InputDecoration(
                  labelText: 'Modelo',
                  prefixIcon:
                      const Icon(Icons.directions_car, color: Colors.purple),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Colors.purple, width: 2),
                  ),
                ),
                validator: (value) => value!.isEmpty ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _anoController,
                decoration: InputDecoration(
                  labelText: 'Ano',
                  prefixIcon:
                      const Icon(Icons.calendar_today, color: Colors.purple),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Colors.purple, width: 2),
                  ),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value!.isEmpty) return 'Obrigatório';
                  final year = int.tryParse(value);
                  if (year == null ||
                      year < 1900 ||
                      year > DateTime.now().year) {
                    return 'Ano inválido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _tipoVeiculo,
                decoration: InputDecoration(
                  labelText: 'Tipo',
                  // prefixIcon: Icon(Icons.local_gas_statin,
                  //     color: Colors.purple),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Colors.purple, width: 2),
                  ),
                ),
                items: _combustiveis.map((String combustivel) {
                  return DropdownMenuItem<String>(
                    value: combustivel,
                    child: Text(combustivel),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _tipoVeiculo = value),
                validator: (value) => value == null ? 'Selecione' : null,
              ),
              const SizedBox(height: 24),
              Center(
                child: MouseRegion(
                  onEnter: (_) => _animationController.forward(),
                  onExit: (_) => _animationController.reverse(),
                  child: ScaleTransition(
                    scale: _buttonScaleAnimation,
                    child: ElevatedButton(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor:
                            Theme.of(context).colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 5,
                      ),
                      child: const Text(
                        'Salvar Veículo',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Vehicle {
  final int? id;
  final String modelo;
  final String marca;
  final String ano;
  final String placa;
  final String combustivel;

  Vehicle({
    this.id,
    required this.modelo,
    required this.marca,
    required this.ano,
    required this.placa,
    required this.combustivel,
  });
}
