import 'package:flutter/material.dart';
import 'package:pharmacie_mobile/services/api_service.dart';
import 'dart:convert';

class AjoutMultipleProduits extends StatefulWidget {
  const AjoutMultipleProduits({super.key});

  @override
  State<AjoutMultipleProduits> createState() => _AjoutMultipleProduitsState();
}

class _AjoutMultipleProduitsState extends State<AjoutMultipleProduits> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _fournisseurs = [];
  List<ProduitItem> _produits = [ProduitItem()];

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadFournisseurs();
  }

  Future<void> _loadCategories() async {
    try {
      final response = await ApiService.getCategories();
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _categories = List<Map<String, dynamic>>.from(
            data['categories'] ?? [],
          );
        });
      }
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

  void _addProduit() {
    setState(() {
      _produits.add(ProduitItem());
    });
  }

  void _removeProduit(int index) {
    if (_produits.length > 1) {
      setState(() {
        _produits.removeAt(index);
      });
    }
  }

  Future<void> _submitProduits() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Vérifier qu'au moins un produit est valide
    bool hasValidProduct = false;
    for (var produit in _produits) {
      if (produit.nomController.text.isNotEmpty &&
          produit.prixVenteController.text.isNotEmpty &&
          produit.stockController.text.isNotEmpty &&
          produit.selectedCategorie != null) {
        hasValidProduct = true;
        break;
      }
    }

    if (!hasValidProduct) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir au moins un produit complètement'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      List<Map<String, dynamic>> produitsData = [];

      for (var produit in _produits) {
        if (produit.nomController.text.isNotEmpty &&
            produit.prixVenteController.text.isNotEmpty &&
            produit.stockController.text.isNotEmpty &&
            produit.selectedCategorie != null) {
          produitsData.add({
            'nom': produit.nomController.text.trim(),
            'description': produit.descriptionController.text.trim(),
            'prix_achat':
                double.tryParse(produit.prixAchatController.text) ?? 0,
            'prix_vente':
                double.tryParse(produit.prixVenteController.text) ?? 0,
            'quantite': int.tryParse(produit.stockController.text) ?? 0,
            'seuil_alerte':
                int.tryParse(produit.seuilAlerteController.text) ?? 10,
            'categorie_id': produit.selectedCategorie,
            'fournisseur_id': produit.selectedFournisseur,
            'code_barre': produit.codeBarreController.text.trim(),
            'date_expiration': produit.dateExpirationController.text.trim(),
          });
        }
      }

      // Envoyer les produits un par un (car l'API n'a peut-être pas d'endpoint批量)
      int successCount = 0;
      List<String> errors = [];

      for (var produitData in produitsData) {
        try {
          final response = await ApiService.addProduit(produitData);
          if (response.statusCode == 201) {
            successCount++;
          } else {
            final errorData = jsonDecode(response.body);
            errors.add(
              '${produitData['nom']}: ${errorData['message'] ?? 'Erreur'}',
            );
          }
        } catch (e) {
          errors.add('${produitData['nom']}: Erreur réseau');
        }
      }

      if (mounted) {
        if (successCount > 0) {
          String message = '$successCount produit(s) ajouté(s) avec succès';
          if (errors.isNotEmpty) {
            message += '\n${errors.length} erreur(s)';
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: successCount == produitsData.length
                  ? Colors.green
                  : Colors.orange,
              duration: const Duration(seconds: 4),
            ),
          );

          if (errors.isNotEmpty) {
            _showErrorsDialog(errors);
          } else {
            Navigator.pop(context, true);
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Aucun produit n\'a pu être ajouté'),
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

  void _showErrorsDialog(List<String> errors) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Erreurs lors de l\'ajout'),
        content: SizedBox(
          width: double.maxFinite,
          height: 200,
          child: ListView.builder(
            itemCount: errors.length,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text('• ${errors[index]}'),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, true);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Ajout Multiple de Produits',
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
        actions: [
          IconButton(
            onPressed: _addProduit,
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Ajouter une ligne',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Header avec information
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFF2E7D32).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Color(0xFF2E7D32)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFF2E7D32)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Remplissez les informations pour chaque produit. Les champs avec * sont obligatoires.',
                      style: TextStyle(color: Color(0xFF2E7D32), fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),

            // Liste des produits
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _produits.length,
                itemBuilder: (context, index) => _buildProduitCard(index),
              ),
            ),

            // Bouton de soumission
            Container(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitProduits,
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
                      : Text(
                          'Enregistrer ${_produits.length} produit(s)',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProduitCard(int index) {
    final produit = _produits[index];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header de la carte
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Produit ${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                if (_produits.length > 1)
                  IconButton(
                    onPressed: () => _removeProduit(index),
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    tooltip: 'Supprimer ce produit',
                  ),
              ],
            ),
          ),

          // Champs du produit
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Nom et Description
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: produit.nomController,
                        decoration: const InputDecoration(
                          labelText: 'Nom du produit *',
                          prefixIcon: Icon(Icons.medication),
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Nom requis';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: produit.descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    prefixIcon: Icon(Icons.description),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),

                // Prix
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: produit.prixAchatController,
                        decoration: const InputDecoration(
                          labelText: 'Prix d\'achat (FC)',
                          prefixIcon: Icon(Icons.shopping_cart),
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: produit.prixVenteController,
                        decoration: const InputDecoration(
                          labelText: 'Prix de vente (FC) *',
                          prefixIcon: Icon(Icons.attach_money),
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Prix requis';
                          }
                          final prix = double.tryParse(value);
                          if (prix == null || prix <= 0) {
                            return 'Prix invalide';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: produit.selectedCategorie,
                        decoration: const InputDecoration(
                          labelText: 'Catégorie *',
                          prefixIcon: Icon(Icons.category),
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: _categories.map((categorie) {
                          return DropdownMenuItem<String>(
                            value: categorie['id'].toString(),
                            child: Text(
                              categorie['nom'] ?? 'Catégorie inconnue',
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            produit.selectedCategorie = value;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Catégorie requise';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                // Catégorie et Fournisseur
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: produit.selectedFournisseur,
                        decoration: const InputDecoration(
                          labelText: 'Fournisseur',
                          prefixIcon: Icon(Icons.business),
                          border: OutlineInputBorder(),
                          isDense: true,
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
                            produit.selectedFournisseur = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Stock et Date d'expiration
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: produit.stockController,
                        decoration: const InputDecoration(
                          labelText: 'Quantité *',
                          prefixIcon: Icon(Icons.inventory),
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Quantité requise';
                          }
                          final quantite = int.tryParse(value);
                          if (quantite == null || quantite < 0) {
                            return 'Quantité invalide';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: produit.seuilAlerteController,
                        decoration: const InputDecoration(
                          labelText: 'Seuil alerte',
                          prefixIcon: Icon(Icons.warning),
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                        controller: produit.codeBarreController,
                        decoration: const InputDecoration(
                          labelText: 'Code barre',
                          prefixIcon: Icon(Icons.qr_code),
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: produit.dateExpirationController,
                        decoration: const InputDecoration(
                          labelText: 'Date expiration',
                          prefixIcon: Icon(Icons.calendar_today),
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        keyboardType: TextInputType.datetime,
                        onTap: () async {
                          DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2100),
                          );
                          if (pickedDate != null) {
                            produit.dateExpirationController.text = pickedDate
                                .toString()
                                .split(' ')[0];
                          }
                        },
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
  }
}

class ProduitItem {
  final TextEditingController nomController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController prixAchatController = TextEditingController();
  final TextEditingController prixVenteController = TextEditingController();
  final TextEditingController stockController = TextEditingController();
  final TextEditingController codeBarreController = TextEditingController();
  final TextEditingController dateExpirationController =
      TextEditingController();
  final TextEditingController seuilAlerteController = TextEditingController(
    text: '10',
  );

  String? selectedCategorie;
  String? selectedFournisseur;

  void dispose() {
    nomController.dispose();
    descriptionController.dispose();
    prixAchatController.dispose();
    prixVenteController.dispose();
    stockController.dispose();
    codeBarreController.dispose();
    dateExpirationController.dispose();
    seuilAlerteController.dispose();
  }
}
