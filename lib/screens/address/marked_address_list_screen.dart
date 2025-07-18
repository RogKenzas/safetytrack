import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safetytrack/screens/institution/add_institution_screen.dart';
import '../../components/forms/primary_button.dart';

class MarkedAddressListScreen extends StatefulWidget {
  const MarkedAddressListScreen({super.key});

  @override
  State<MarkedAddressListScreen> createState() =>
      _MarkedAddressListScreenState();
}

class _MarkedAddressListScreenState extends State<MarkedAddressListScreen> {
  List<Map<String, String>> addresses = [
    {'type': 'Maison', 'address': '14 rue de Paris, Lyon'},
    {'type': 'École', 'address': '456 avenue Victor Hugo, Villeurbanne'},
  ];
  bool loading = false;

  void _onSave() async {
    setState(() => loading = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => loading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Adresses enregistrées (simulation)')),
    );
    // TODO: Naviguer vers l'écran suivant (dashboard ou institution)
  }

  void _onAddAddress() {
    // Simulation d'ajout
    setState(() {
      addresses.add({'type': 'Autre', 'address': 'Nouvelle adresse'});
    });
  }

  void _onEdit(int index) {
    // Simulation d'édition
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Éditer ${addresses[index]['type']} (simulation)'),
      ),
    );
  }

  void _onDelete(int index) {
    setState(() {
      addresses.removeAt(index);
    });
  }

  void _showAddressModal({Map<String, String>? initial, int? index}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        String type = initial?['type'] ?? 'Maison';
        String nom = initial?['type'] ?? '';
        String adresse = initial?['address'] ?? '';
        final types = ['Maison', 'École', 'Autre'];
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 24,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 18),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        Text(
                          index == null
                              ? 'Ajouter une adresse'
                              : 'Modifier l’adresse',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children:
                              types
                                  .map(
                                    (t) => Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                      ),
                                      child: ChoiceChip(
                                        label: Row(
                                          children: [
                                            if (t == 'Maison')
                                              const Icon(
                                                Icons.home,
                                                size: 18,
                                                color: Color(0xFF179D5B),
                                              ),
                                            if (t == 'École')
                                              const Icon(
                                                Icons.school,
                                                size: 18,
                                                color: Color(0xFF179D5B),
                                              ),
                                            if (t == 'Autre')
                                              const Icon(
                                                Icons.add,
                                                size: 18,
                                                color: Color(0xFF179D5B),
                                              ),
                                            const SizedBox(width: 4),
                                            Text(
                                              t,
                                              style: GoogleFonts.poppins(
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                        selected: type == t,
                                        selectedColor: const Color(0xFF179D5B),
                                        backgroundColor: Colors.white,
                                        labelStyle: TextStyle(
                                          color:
                                              type == t
                                                  ? Colors.white
                                                  : Colors.black87,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          side: BorderSide(
                                            color:
                                                type == t
                                                    ? const Color(0xFF179D5B)
                                                    : Colors.grey.shade300,
                                          ),
                                        ),
                                        onSelected: (val) {
                                          setModalState(() => type = t);
                                        },
                                      ),
                                    ),
                                  )
                                  .toList(),
                        ),
                        const SizedBox(height: 18),
                        TextField(
                          decoration: InputDecoration(
                            labelText: 'Nom',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          controller: TextEditingController(text: nom),
                          onChanged: (v) => nom = v,
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          decoration: InputDecoration(
                            labelText: 'Adresse',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          controller: TextEditingController(text: adresse),
                          onChanged: (v) => adresse = v,
                        ),
                        const SizedBox(height: 22),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  side: const BorderSide(
                                    color: Color(0xFF179D5B),
                                  ),
                                ),
                                child: Text(
                                  'Annuler',
                                  style: GoogleFonts.poppins(
                                    color: const Color(0xFF179D5B),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  if (nom.isEmpty || adresse.isEmpty) return;
                                  setState(() {
                                    if (index == null) {
                                      addresses.add({
                                        'type': type,
                                        'address': adresse,
                                      });
                                    } else {
                                      addresses[index] = {
                                        'type': type,
                                        'address': adresse,
                                      };
                                    }
                                  });
                                  Navigator.pop(context);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF179D5B),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'Enregistrer',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
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
        backgroundColor: const Color(0xFF179D5B),
        elevation: 0,
        title: Text(
          'Adresses marquées',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _showAddressModal,
                  icon: const Icon(Icons.add, color: Color(0xFF179D5B)),
                  label: Text(
                    'Ajouter une adresse',
                    style: GoogleFonts.poppins(color: const Color(0xFF179D5B)),
                  ),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: const BorderSide(color: Color(0xFF179D5B)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: ListView.separated(
                  itemCount: addresses.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, i) {
                    final addr = addresses[i];
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Stack(
                              children: [
                                Image.asset(
                                  'assets/img/map_placeholder.png',
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                ),
                                Positioned(
                                  top: 8,
                                  left: 8,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.08),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                    padding: const EdgeInsets.all(4),
                                    child: Icon(
                                      addr['type'] == 'Maison'
                                          ? Icons.home
                                          : addr['type'] == 'École'
                                          ? Icons.school
                                          : Icons.place,
                                      color: const Color(0xFF179D5B),
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      addr['type'] == 'Maison'
                                          ? 'Maison'
                                          : addr['type'] == 'École'
                                          ? 'École'
                                          : 'Autre',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                        color: const Color(0xFF179D5B),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  addr['address'] ?? '',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed:
                                          () => _showAddressModal(
                                            initial: addr,
                                            index: i,
                                          ),
                                      icon: const Icon(
                                        Icons.edit,
                                        size: 18,
                                        color: Color(0xFF179D5B),
                                      ),
                                      label: Text(
                                        'Edit',
                                        style: GoogleFonts.poppins(
                                          color: const Color(0xFF179D5B),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(
                                          color: Color(0xFF179D5B),
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 0,
                                        ),
                                        minimumSize: const Size(0, 32),
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    OutlinedButton.icon(
                                      onPressed: () => _onDelete(i),
                                      icon: const Icon(
                                        Icons.delete,
                                        size: 18,
                                        color: Color(0xFF179D5B),
                                      ),
                                      label: Text(
                                        'Delete',
                                        style: GoogleFonts.poppins(
                                          color: const Color(0xFF179D5B),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(
                                          color: Color(0xFF179D5B),
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 0,
                                        ),
                                        minimumSize: const Size(0, 32),
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),
              PrimaryButton(
                label: 'Enregistrer les adresses',
                loading: loading,
                onPressed:
                    loading
                        ? null
                        : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddInstitutionScreen(),
                            ),
                          );
                        },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
