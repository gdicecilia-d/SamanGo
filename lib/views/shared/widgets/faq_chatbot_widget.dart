import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FaqChatbotWidget extends StatefulWidget {
  const FaqChatbotWidget({Key? key}) : super(key: key);

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const FaqChatbotWidget(),
    );
  }

  @override
  State<FaqChatbotWidget> createState() => _FaqChatbotWidgetState();
}

class _FaqChatbotWidgetState extends State<FaqChatbotWidget> {
  String? _selectedQuestion;
  String? _currentAnswer;

  final Map<String, String> _faqMap = {
    '¿Cómo hago una reserva?': 'Para hacer una reserva, ve a la página principal, selecciona un destino, elige una fecha y presiona el botón de solicitar.',
    '¿Cómo cancelo mi viaje?': 'Para cancelar, ve a la sección "Mis Viajes", selecciona el viaje que deseas cancelar y presiona el botón "Cancelar". Revisa nuestras políticas de reembolso antes de hacerlo.',
    '¿Qué métodos de pago aceptan?': 'Actualmente aceptamos pagos de forma segura a través de PayPal para todas nuestras reservaciones.',
    '¿Cómo contacto con el operador?': 'Una vez que tu reserva sea confirmada, podrás acceder a los datos de contacto del operador desde los detalles de tu viaje en "Mis Viajes".'
  };

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: 24 + bottomInset,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFC6707).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.support_agent, color: Color(0xFFFC6707)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Asistente SamanGo',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF333333),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFFE0E0E0)),
          const SizedBox(height: 16),
          
          // Content
          if (_selectedQuestion == null) ...[
            Text(
              '¡Hola! ¿En qué puedo ayudarte hoy?',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF666666),
              ),
            ),
            const SizedBox(height: 16),
            ..._faqMap.keys.map((question) => _buildQuestionButton(question)).toList(),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedQuestion!,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currentAnswer!,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      color: const Color(0xFF666666),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _selectedQuestion = null;
                  _currentAnswer = null;
                });
              },
              icon: const Icon(Icons.arrow_back, color: Color(0xFFFC6707)),
              label: Text(
                'Regresar al menú',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFFC6707),
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFFC6707)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuestionButton(String question) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            _selectedQuestion = question;
            _currentAnswer = _faqMap[question];
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF333333),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          alignment: Alignment.centerLeft,
        ),
        child: Row(
          children: [
            const Icon(Icons.help_outline, color: Color(0xFFFC6707), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                question,
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Color(0xFFCCCCCC), size: 16),
          ],
        ),
      ),
    );
  }
}
