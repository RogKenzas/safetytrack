import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OtpInput extends StatefulWidget {
  final void Function(String) onCompleted;
  const OtpInput({super.key, required this.onCompleted});

  @override
  State<OtpInput> createState() => _OtpInputState();
}

class _OtpInputState extends State<OtpInput> {
  final List<TextEditingController> _controllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _onChanged(int i, String value) {
    if (value.length == 1 && i < 3) {
      _focusNodes[i + 1].requestFocus();
    }
    if (value.isEmpty && i > 0) {
      _focusNodes[i - 1].requestFocus();
    }
    final code = _controllers.map((c) => c.text).join();
    if (code.length == 4) {
      widget.onCompleted(code);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (i) {
        return Container(
          width: 56,
          height: 64,
          margin: EdgeInsets.only(right: i < 3 ? 16 : 0),
          child: TextField(
            controller: _controllers[i],
            focusNode: _focusNodes[i],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 1,
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF179D5B),
                  width: 2,
                ),
              ),
            ),
            onChanged: (v) => _onChanged(i, v),
          ),
        );
      }),
    );
  }
}
