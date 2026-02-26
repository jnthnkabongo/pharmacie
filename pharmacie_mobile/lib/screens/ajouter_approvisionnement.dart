import 'package:flutter/material.dart';
import 'package:pharmacie_mobile/services/api_service.dart';
import 'dart:convert';

class AjouterApprovisionnement extends StatefulWidget {
  const AjouterApprovisionnement({super.key});

  @override
  State<AjouterApprovisionnement> createState() =>
      _AjouterApprovisionnementState();
}

class _AjouterApprovisionnementState extends State<AjouterApprovisionnement> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Contrôleurs pour les champs
  String? _selectedFournisseur;
  List<Map<String, dynamic>> _fournisseurs = [];
  List<Map<String, dynamic>> _produits = [];

  // Articles dans l'approvisionnement
  List<Map<String, dynamic>> _articles = [];

  @override
  void initState() {
    super.initState();
    _loadFournisseurs();
    _loadProduits();
    // Ajouter un article par défaut
    _addArticle();
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

  Future<void> _loadProduits() async {
    try {
      final response = await ApiService.getProduits();
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _produits = List<Map<String, dynamic>>.from(data['produits'] ?? []);
        });
      }
    } catch (e) {
      print('Erreur chargement produits: $e');
    }
  }

  void _addArticle() {
    setState(() {
      _articles.add({
        'produit_id': null,
        'quantite': TextEditingController(text: '1'),
        'prix_achat': TextEditingController(text: '0'),
      });
    });
  }

  void _removeArticle(int index) {
    if (_articles.length > 1) {
      setState(() {
        _articles.removeAt(index);
      });
    }
  }

  double _calculateTotal() {
    double total = 0.0;
    for (var article in _articles) {
      final quantite = double.tryParse(article['quantite'].text) ?? 0;
      final prix = double.tryParse(article['prix_achat'].text) ?? 0;
      total += quantite * prix;
    }
    return total;
  }

  Future<void> _submitApprovisionnement() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedFournisseur == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un fournisseur'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Vérifier que tous les articles sont valides
    for (var article in _articles) {
      if (article['produit_id'] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Veuillez sélectionner un produit pour chaque article',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final articlesData = _articles.map((article) {
        return {
          'produit_id': article['produit_id'],
          'quantite': int.tryParse(article['quantite'].text) ?? 0,
          'prix_achat': double.tryParse(article['prix_achat'].text) ?? 0,
        };
      }).toList();

      final approvisionnementData = {
        'fournisseur_id': _selectedFournisseur,
        'montant_total': _calculateTotal(),
        'articles': articlesData,
      };

      final response = await ApiService.addApprovisionnement(
        approvisionnementData,
      );

      if (response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Approvisionnement ajouté avec succès'),
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Nouvel Approvisionnement',
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
              // Section Fournisseur
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
                      'Fournisseur',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedFournisseur,
                      decoration: const InputDecoration(
                        labelText: 'Sélectionner un fournisseur',
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
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez sélectionner un fournisseur';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _showAddFournisseurDialog(),
                      icon: const Icon(Icons.add),
                      label: const Text('Ajouter un nouveau fournisseur'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Section Articles
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Articles',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1976D2),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _addArticle,
                          icon: const Icon(Icons.add),
                          label: const Text('Ajouter'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1976D2),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ..._articles.asMap().entries.map((entry) {
                      final index = entry.key;
                      final article = entry.value;
                      return _buildArticleCard(index, article);
                    }).toList(),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Section Total
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total:',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${_calculateTotal().toStringAsFixed(2)} FC',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Bouton de soumission
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitApprovisionnement,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1976D2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Enregistrer l\'approvisionnement',
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

  Widget _buildArticleCard(int index, Map<String, dynamic> article) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Article ${index + 1}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1976D2),
                ),
              ),
              if (_articles.length > 1)
                IconButton(
                  onPressed: () => _removeArticle(index),
                  icon: const Icon(Icons.delete, color: Colors.red),
                ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: article['produit_id'],
            decoration: const InputDecoration(
              labelText: 'Produit',
              prefixIcon: Icon(Icons.medication),
              border: OutlineInputBorder(),
            ),
            items: _produits.map((produit) {
              return DropdownMenuItem<String>(
                value: produit['id'].toString(),
                child: Text(produit['nom'] ?? 'Produit inconnu'),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                article['produit_id'] = value;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez sélectionner un produit';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: article['quantite'],
                  decoration: const InputDecoration(
                    labelText: 'Quantité',
                    prefixIcon: Icon(Icons.inventory),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer une quantité';
                    }
                    final quantite = int.tryParse(value);
                    if (quantite == null || quantite <= 0) {
                      return 'Quantité invalide';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    setState(() {}); // Recalculer le total
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: article['prix_achat'],
                  decoration: const InputDecoration(
                    labelText: 'Prix d\'achat (FC)',
                    prefixIcon: Icon(Icons.attach_money),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer un prix';
                    }
                    final prix = double.tryParse(value);
                    if (prix == null || prix < 0) {
                      return 'Prix invalide';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    setState(() {}); // Recalculer le total
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddFournisseurDialog() {
    final nomController = TextEditingController();
    final telephoneController = TextEditingController();
    final adresseController = TextEditingController();
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Ajouter un fournisseur',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1976D2),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: nomController,
                decoration: const InputDecoration(
                  labelText: 'Nom *',
                  prefixIcon: Icon(Icons.business),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer le nom';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: telephoneController,
                decoration: const InputDecoration(
                  labelText: 'Téléphone',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: adresseController,
                decoration: const InputDecoration(
                  labelText: 'Adresse',
                  prefixIcon: Icon(Icons.location_on),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Annuler'),
                    ),
                  ),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (nomController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Le nom est obligatoire'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        try {
                          final fournisseurData = {
                            'nom': nomController.text,
                            'telephone': telephoneController.text,
                            'adresse': adresseController.text,
                            'email': emailController.text,
                          };

                          final response = await ApiService.addFournisseur(
                            fournisseurData,
                          );

                          if (response.statusCode == 201) {
                            Navigator.pop(context);
                            _loadFournisseurs(); // Recharger la liste
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Fournisseur ajouté avec succès'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Erreur lors de l\'ajout'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Erreur: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1976D2),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Ajouter'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
