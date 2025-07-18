import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../components/forms/primary_button.dart';

class MarkAddressScreen extends StatefulWidget {
  const MarkAddressScreen({super.key});

  @override
  State<MarkAddressScreen> createState() => _MarkAddressScreenState();
}

class _MarkAddressScreenState extends State<MarkAddressScreen> {
  String selectedType = 'Maison';
  final List<String> types = ['Maison', 'École', 'Autre'];
  String address = '14 rue de Paris, Lyon';
  String name = 'Maison';
  bool loading = false;

  void _onSave() async {
    setState(() => loading = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => loading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Adresse marquée enregistrée (simulation)')),
    );
    // TODO: Naviguer vers la liste des adresses
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Color(0xFF179D5B),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 12),
                          const Icon(
                            Icons.search,
                            color: Colors.grey,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Rechercher une adresse',
                              style: GoogleFonts.poppins(
                                color: Colors.grey.shade600,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5EF),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Center(
                  child: Icon(
                    Icons.location_on,
                    size: 80,
                    color: Color(0xFF179D5B),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children:
                    types
                        .map(
                          (type) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: ChoiceChip(
                              label: Text(type, style: GoogleFonts.poppins()),
                              selected: selectedType == type,
                              selectedColor: const Color(0xFF179D5B),
                              labelStyle: TextStyle(
                                color:
                                    selectedType == type
                                        ? Colors.white
                                        : Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                              onSelected: (val) {
                                setState(() {
                                  selectedType = type;
                                  name = type;
                                });
                              },
                            ),
                          ),
                        )
                        .toList(),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nom',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Text(name, style: GoogleFonts.poppins(fontSize: 15)),
                    const SizedBox(height: 12),
                    Text(
                      'Adresse',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Text(address, style: GoogleFonts.poppins(fontSize: 15)),
                  ],
                ),
              ),
              const Spacer(),
              PrimaryButton(
                label: 'Enregistrer l’adresse marquée',
                loading: loading,
                onPressed: loading ? null : _onSave,
              ),
              const SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }
}
