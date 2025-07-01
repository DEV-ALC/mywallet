import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PopupConfirmacaoAnimada extends StatefulWidget {
  final String tag;
  final double amount;
  final Color color;
  final double totalExpenses;

  const PopupConfirmacaoAnimada({
    super.key,
    required this.tag,
    required this.amount,
    required this.color,
    required this.totalExpenses,
  });

  @override
  State<PopupConfirmacaoAnimada> createState() =>
      _PopupConfirmacaoAnimadaState();
}

class _PopupConfirmacaoAnimadaState extends State<PopupConfirmacaoAnimada>
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

    Future.delayed(const Duration(seconds: 3), () async {
      if (mounted) {
        await _slideController.forward();
        if (mounted) Navigator.of(context).pop();
      }
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
    final percentage = widget.totalExpenses > 0
        ? (widget.amount / widget.totalExpenses) * 100
        : 0.0;
    final formatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Center(
      child: SlideTransition(
        position: _slideAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Dialog(
            backgroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.color,
                          border: Border.all(color: Colors.black26, width: 2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.tag,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color.fromRGBO(19, 58, 99, 1),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    formatter.format(widget.amount),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Stack(
                    children: [
                      Container(
                        width: 200,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      Container(
                        width: 200 * (percentage / 100),
                        height: 20,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              widget.color.withOpacity(0.6),
                              widget.color
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${percentage.toStringAsFixed(1)}% do total',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      _slideController.forward().then((_) {
                        if (mounted) Navigator.of(context).pop();
                      });
                    },
                    child: const Text(
                      'Fechar',
                      style: TextStyle(color: Color.fromRGBO(19, 58, 99, 1)),
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
