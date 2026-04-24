import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:pharmacie_mobile/services/api_service.dart';

class AjouterFournisseur extends StatefulWidget {
  const AjouterFournisseur({super.key});

  @override
  State<AjouterFournisseur> createState() => _AjouterFournisseurState();
}

class _AjouterFournisseurState extends State<AjouterFournisseur> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  int? _pharmacieId; // Variable pour stocker pharmacie_id

  final _nomCategorieController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _adresseController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final userInfo = await ApiService.getUserInfo();
    setState(() {
      // Stocker pharmacie_id dans la variable
      _pharmacieId = userInfo?['pharmacie_id'];
    });

    // Récupérer pharmacie_id spécifiquement
    if (_pharmacieId == null) {
      // Rediriger ou afficher un message si pharmacie_id est null
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucune pharmacie associée à votre compte'),
          backgroundColor: Colors.red,
        ),
      );
      // Optionnel: revenir en arrière
      Navigator.pop(context);
    }
  }

  Future<void> _insertFournisseur() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Vérifier que pharmacie_id est disponible
    if (_pharmacieId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucune pharmacie associée à votre compte'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final fournisseurData = {
        'nom': _nomCategorieController.text,
        'telephone': _telephoneController.text,
        'adresse': _adresseController.text,
        'email': _emailController.text,
        'pharmacie_id': _pharmacieId, // Utilisation de la variable
      };

      print('Valeur ID: $_pharmacieId');
      final response = await ApiService.addFournisseur(fournisseurData);

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Catégorie ajoutée avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        // Gérer les erreurs HTTP
        String errorMessage = 'Erreur lors de l\'ajout de la catégorie';
        try {
          final responseData = jsonDecode(response.body);
          if (responseData['message'] != null) {
            errorMessage = responseData['message'];
          }
        } catch (e) {
          // Si le parsing JSON échoue, utiliser le message par défaut
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nomCategorieController.dispose();
    _telephoneController.dispose();
    _adresseController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Nouveau Fournisseur',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
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
                      'Nom du fournisseur *',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _nomCategorieController,
                      decoration: const InputDecoration(
                        hintText: 'Entrez le nom du fournisseur',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Le nom du fournisseur est requis';
                        }
                        if (value.trim().length < 2) {
                          return 'Le nom du fournisseur doit contenir au moins 2 caractères';
                        }
                        if (value.trim().length > 255) {
                          return 'Le nom du fournisseur ne peut pas dépasser 255 caractères';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Téléphone du fournisseur',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _telephoneController,
                      decoration: const InputDecoration(
                        hintText: 'Entrez le numéro du fournisseur',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value != null && value.trim().length < 10) {
                          return 'Le numéro de téléphone doit contenir au moins 10 caratères';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Adresse du fournisseur',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _adresseController,
                      decoration: const InputDecoration(
                        hintText: 'Entrez l\'adresse du fournisseur',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'L\'adresse du fournisseur est requise';
                        }
                        if (value.trim().length < 2) {
                          return 'Le nom du fournisseur doit contenir au moins 2 caractères';
                        }
                        if (value.trim().length > 255) {
                          return 'Le nom du fournisseur ne peut pas dépasser 255 caractères';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'E-mail du fournisseur',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        hintText: 'Entrez l\'email du fournisseur',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value != null && value.trim().length > 10) {
                          return 'L\'adresse e-mail doit respecter la norme';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _insertFournisseur,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text('Enregistrement...'),
                                ],
                              )
                            : const Text(
                                'Enregistrer le fournisseur',
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
            ],
          ),
        ),
      ),
    );
  }
}
