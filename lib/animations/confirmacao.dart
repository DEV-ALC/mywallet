import 'package:flutter/material.dart';

Future<void> mostrarPopupConfirmacaoNativo(BuildContext context,
    {String mensagem = 'Cadastro realizado com sucesso!'}) async {
  return showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withOpacity(0.3),
    builder: (_) => const _PopupConfirmacaoAnimada(),
  );
}

class _PopupConfirmacaoAnimada extends StatefulWidget {
  const _PopupConfirmacaoAnimada();

  @override
  State<_PopupConfirmacaoAnimada> createState() =>
      _PopupConfirmacaoAnimadaState();
}

class _PopupConfirmacaoAnimadaState extends State<_PopupConfirmacaoAnimada>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _slideController;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _scaleAnimation =
        CurvedAnimation(parent: _scaleController, curve: Curves.easeOutBack);
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -2),
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeIn));

    _scaleController.forward();

    Future.delayed(const Duration(seconds: 1), () async {
      await _slideController.forward(); // anima para cima
      if (mounted) Navigator.of(context).pop(); // fecha o dialog
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SlideTransition(
        position: _slideAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Dialog(
            backgroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: const Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, size: 80, color: Colors.green),
                  SizedBox(height: 16),
                  Text(
                    'Cadastro realizado com sucesso!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color.fromRGBO(19, 58, 99, 1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
