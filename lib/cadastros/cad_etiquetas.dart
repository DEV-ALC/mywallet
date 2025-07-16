import 'package:flutter/material.dart';

//ROTAS
import '../db/database.dart';

class EtiquetaScreen extends StatefulWidget {
  const EtiquetaScreen({super.key});

  @override
  State<EtiquetaScreen> createState() => _EtiquetaScreenState();
}

class _EtiquetaScreenState extends State<EtiquetaScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _etiquetaController = TextEditingController();
  final DatabaseHelper dbHelper = DatabaseHelper.instance;
  List<Etiqueta> _etiquetas = [];

  @override
  void initState() {
    super.initState();
    _refreshEtiquetas();
  }

  Future<void> _refreshEtiquetas() async {
    final etiquetaList = await dbHelper.getEtiquetas();
    setState(() {
      _etiquetas = etiquetaList;
    });
  }

  Future<void> _adicionarEtiqueta(context) async {
    if (_formKey.currentState!.validate()) {
      final novaEtiqueta = _etiquetaController.text.trim();
      final exists = _etiquetas.any((e) => e.title == novaEtiqueta);

      if (!exists) {
        final etiqueta = Etiqueta(title: novaEtiqueta);
        await dbHelper.insertEtiqueta(etiqueta);
        _etiquetaController.clear();
        _refreshEtiquetas();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Etiqueta já existe!')),
        );
      }
    }
  }

  Future<void> _removerEtiqueta(int id) async {
    await dbHelper.deleteEtiqueta(id);
    _refreshEtiquetas();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        title: const Text('Cadastro de Etiquetas'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _etiquetaController,
                      decoration: const InputDecoration(
                        labelText: 'Nova etiqueta',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Digite uma etiqueta';
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) => _adicionarEtiqueta(context),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      _adicionarEtiqueta(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                    child: const Text('Adicionar'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _etiquetas.isEmpty
                  ? const Center(child: Text('Nenhuma etiqueta cadastrada.'))
                  : ListView.separated(
                      itemCount: _etiquetas.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final etiqueta = _etiquetas[index];
                        return ListTile(
                          title: Text(etiqueta.title),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _removerEtiqueta(etiqueta.id!),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
