import 'package:flutter/material.dart';
import 'package:pharmacie_mobile/services/api_service.dart';
import 'dart:convert';

class AjouterProduit extends StatefulWidget {
  const AjouterProduit({super.key});

  @override
  State<AjouterProduit> createState() => _AjouterProduitState();
}

class _AjouterProduitState extends State<AjouterProduit> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Contrôleurs pour les champs
  final _nomController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _prixAchatController = TextEditingController();
  final _prixVenteController = TextEditingController();
  final _stockController = TextEditingController();
  final _codeBarreController = TextEditingController();
  final _dateExpirationController = TextEditingController();
  final _seuilAlerteController = TextEditingController(text: '10');

  String? _selectedCategorie;
  List<Map<String, dynamic>> _categories = [];
  String? _selectedFournisseur;
  List<Map<String, dynamic>> _fournisseurs = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadFournisseurs();
  }

  Future<void> _loadCategories() async {
    try {
      // Pour l'instant, utilisons des catégories par défaut
      setState(() {
        _categories = [
          {'id': '1', 'nom': 'Médicaments'},
          {'id': '2', 'nom': 'Parapharmacie'},
          {'id': '3', 'nom': 'Produits d\'hygiène'},
          {'id': '4', 'nom': 'Équipements médicaux'},
        ];
      });
    } catch (e) {
      print('Erreur chargement catégories: $e');
    }
  }

  Future<void> _loadFournisseurs() async {
    try {
      final response = await ApiService.getFournisseurs();
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _fournisseurs = List<Map<String, dynamic>>.from(
            data['fournisseurs'] ?? [],
          );
        });
      }
    } catch (e) {
      print('Erreur chargement fournisseurs: $e');
    }
  }

  Future<void> _submitProduit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategorie == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner une catégorie'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final produitData = {
        'nom': _nomController.text,
        'description': _descriptionController.text,
        'prix_achat': double.tryParse(_prixAchatController.text) ?? 0,
        'prix_vente': double.tryParse(_prixVenteController.text) ?? 0,
        'quantite': int.tryParse(_stockController.text) ?? 0,
        'seuil_alerte': int.tryParse(_seuilAlerteController.text) ?? 10,
        'categorie_id': _selectedCategorie,
        'fournisseur_id': _selectedFournisseur,
        'code_barre': _codeBarreController.text,
        'date_expiration': _dateExpirationController.text,
      };

      final response = await ApiService.addProduit(produitData);

      if (response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Produit ajouté avec succès'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          final errorData = jsonDecode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorData['message'] ?? 'Erreur lors de l\'ajout'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _descriptionController.dispose();
    _prixAchatController.dispose();
    _prixVenteController.dispose();
    _stockController.dispose();
    _codeBarreController.dispose();
    _dateExpirationController.dispose();
    _seuilAlerteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Nouveau Produit',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section Informations générales
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Informations générales',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _nomController,
                      decoration: const InputDecoration(
                        labelText: 'Nom du produit *',
                        prefixIcon: Icon(Icons.medication),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer le nom du produit';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        prefixIcon: Icon(Icons.description),
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _prixController,
                      decoration: const InputDecoration(
                        labelText: 'Prix de vente (FC) *',
                        prefixIcon: Icon(Icons.attach_money),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer le prix';
                        }
                        final prix = double.tryParse(value);
                        if (prix == null || prix <= 0) {
                          return 'Prix invalide';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Section Catégorie et Fournisseur
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Classification',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      value: _selectedCategorie,
                      decoration: const InputDecoration(
                        labelText: 'Catégorie *',
                        prefixIcon: Icon(Icons.category),
                        border: OutlineInputBorder(),
                      ),
                      items: _categories.map((categorie) {
                        return DropdownMenuItem<String>(
                          value: categorie['id'].toString(),
                          child: Text(categorie['nom'] ?? 'Catégorie inconnue'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategorie = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez sélectionner une catégorie';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedFournisseur,
                      decoration: const InputDecoration(
                        labelText: 'Fournisseur',
                        prefixIcon: Icon(Icons.business),
                        border: OutlineInputBorder(),
                      ),
                      items: _fournisseurs.map((fournisseur) {
                        return DropdownMenuItem<String>(
                          value: fournisseur['id'].toString(),
                          child: Text(
                            fournisseur['nom'] ?? 'Fournisseur inconnu',
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedFournisseur = value;
                        });
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Section Stock
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Gestion du stock',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _stockController,
                            decoration: const InputDecoration(
                              labelText: 'Quantité initiale *',
                              prefixIcon: Icon(Icons.inventory),
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez entrer la quantité';
                              }
                              final quantite = int.tryParse(value);
                              if (quantite == null || quantite < 0) {
                                return 'Quantité invalide';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _seuilAlerteController,
                            decoration: const InputDecoration(
                              labelText: 'Seuil d\'alerte',
                              prefixIcon: Icon(Icons.warning),
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez entrer le seuil';
                              }
                              final seuil = int.tryParse(value);
                              if (seuil == null || seuil < 0) {
                                return 'Seuil invalide';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Bouton de soumission
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitProduit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Enregistrer le produit',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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
