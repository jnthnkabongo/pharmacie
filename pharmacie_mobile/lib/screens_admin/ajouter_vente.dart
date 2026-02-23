import 'package:flutter/material.dart';
import 'package:pharmacie_mobile/services/api_service.dart';
import 'dart:convert';

class AjouterVente extends StatefulWidget {
  const AjouterVente({super.key});

  @override
  State<AjouterVente> createState() => _AjouterVenteState();
}

class _AjouterVenteState extends State<AjouterVente> {
  // == ETATS ==
  bool _isLoading = true;
  bool _isSaving = false;
  List<Map<String, dynamic>> _produits = [];
  List<Map<String, dynamic>> _filteredProduits = [];
  List<String> _categories = ['Toutes'];
  String _selectedCategory = 'Toutes';

  final List<Map<String, dynamic>> _panier = [];

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _clientController = TextEditingController();
  String _modePaiement = 'Comptant';

  @override
  void initState() {
    super.initState();
    _loadProduits();
    _searchController.addListener(_filterProduits);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _clientController.dispose();
    super.dispose();
  }

  // == DATA FETCH ==
  Future<void> _loadProduits() async {
    try {
      final response = await ApiService.getProduits();
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _produits = List<Map<String, dynamic>>.from(data['produits'] ?? []);
          // Produits avec du stock
          _produits = _produits.where((p) {
            final stockObj = p['stock'];
            int stockQty = 0;
            if (stockObj != null && stockObj['quantite'] != null) {
              stockQty = stockObj['quantite'] is num
                  ? (stockObj['quantite'] as num).toInt()
                  : int.tryParse(stockObj['quantite'].toString()) ?? 0;
            }
            return stockQty > 0;
          }).toList();

          _filteredProduits = _produits;

          // Extraire les catégories uniques
          final cats = _produits
              .map(
                (p) => p['categorie'] != null
                    ? p['categorie']['nom']?.toString()
                    : null,
              )
              .where((c) => c != null && c.isNotEmpty)
              .cast<String>()
              .toSet()
              .toList();
          _categories = ['Toutes', ...cats];

          _isLoading = false;
        });
      } else {
        _showValidationMessage(
          'Erreur de chargement des produits',
          isError: true,
        );
        setState(() => _isLoading = false);
      }
    } catch (e) {
      _showValidationMessage('Erreur de connexion serveur', isError: true);
      setState(() => _isLoading = false);
    }
  }

  // == FILTRES ==
  void _filterProduits() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredProduits = _produits.where((p) {
        final nom = p['nom']?.toString().toLowerCase() ?? '';
        final cat = p['categorie'] != null
            ? p['categorie']['nom']?.toString() ?? ''
            : '';

        final matchesQuery =
            query.isEmpty ||
            nom.contains(query) ||
            cat.toLowerCase().contains(query);
        final matchesCategory =
            _selectedCategory == 'Toutes' || cat == _selectedCategory;

        return matchesQuery && matchesCategory;
      }).toList();
    });
  }

  void _selectCategory(String cat) {
    setState(() {
      _selectedCategory = cat;
      _filterProduits();
    });
  }

  // == LOGIQUE DU PANIER ==
  void _addToCart(Map<String, dynamic> produit) {
    final stockAvailable = _getStockQty(produit);
    final existingIndex = _panier.indexWhere(
      (item) => item['produit']['id'] == produit['id'],
    );

    if (existingIndex >= 0) {
      if (_panier[existingIndex]['quantite'] < stockAvailable) {
        setState(() => _panier[existingIndex]['quantite']++);
      } else {
        _showValidationMessage(
          'Stock maximal atteint pour ce produit',
          isError: true,
        );
      }
    } else {
      setState(() {
        _panier.add({
          'produit': produit,
          'quantite': 1,
          'prix_unitaire':
              double.tryParse(produit['prix_vente']?.toString() ?? '0') ?? 0.0,
        });
      });
    }
  }

  void _updateCartQuantity(int index, int delta) {
    setState(() {
      final newQty = _panier[index]['quantite'] + delta;
      final stockAvailable = _getStockQty(_panier[index]['produit']);

      if (newQty > 0 && newQty <= stockAvailable) {
        _panier[index]['quantite'] = newQty;
      } else if (newQty <= 0) {
        _panier.removeAt(index);
      } else if (newQty > stockAvailable) {
        _showValidationMessage('Stock insuffisant !', isError: true);
      }
    });
  }

  int _getStockQty(Map<String, dynamic> produit) {
    if (produit['stock'] == null || produit['stock']['quantite'] == null) {
      return 0;
    }
    return produit['stock']['quantite'] is num
        ? (produit['stock']['quantite'] as num).toInt()
        : int.tryParse(produit['stock']['quantite'].toString()) ?? 0;
  }

  double get _totalPanier {
    return _panier.fold(
      0,
      (total, item) => total + (item['prix_unitaire'] * item['quantite']),
    );
  }

  int get _totalArticles {
    return _panier.fold(0, (total, item) => total + (item['quantite'] as int));
  }

  // == ENREGISTREMENT API ==
  Future<void> _validerVente() async {
    if (_panier.isEmpty) return;

    setState(() => _isSaving = true);

    final userIdObj = await ApiService.getUserInfo();
    final currentUserId = userIdObj?['id'] ?? 1;

    final List<Map<String, dynamic>> articles = _panier
        .map(
          (item) => {
            'produit_id': item['produit']['id'],
            'quantite': item['quantite'],
            'prix_unitaire': item['prix_unitaire'],
          },
        )
        .toList();

    final bodyData = {
      'client_id': _clientController.text.trim().isEmpty
          ? 'Client Anonyme'
          : _clientController.text.trim(),
      'vendeur_id': currentUserId,
      'type_vente': _modePaiement == 'Comptant' ? 'comptant' : 'credit',
      'montant_total': _totalPanier,
      'articles': articles,
    };

    // Afficher les données avant envoi
    print('=== DONNÉES ENVOYÉES À L\'API ===');
    print('URL: POST /api/add-vente');
    print('Body: ${jsonEncode(bodyData)}');
    print('Nombre d\'articles: ${articles.length}');
    print('Montant total: ${_totalPanier.toStringAsFixed(2)} FC');
    print('Mode paiement: $_modePaiement');
    print(
      'Client: ${_clientController.text.trim().isEmpty ? "Client Anonyme" : _clientController.text.trim()}',
    );
    print('Vendeur ID: $currentUserId');
    print('================================');

    try {
      final response = await ApiService.addVente(bodyData);

      setState(() => _isSaving = false);
      if (response.statusCode == 201 || response.statusCode == 200) {
        _showValidationMessage('Vente finalisée avec succès !');
        if (mounted) Navigator.pop(context, true);
      } else {
        final err = jsonDecode(response.body);
        _showValidationMessage(
          err['message'] ?? 'Erreur lors de la validation',
          isError: true,
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      _showValidationMessage('Erreur de connexion', isError: true);
    }
  }

  // == UI HELPERS ==
  void _showValidationMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showCartBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            void updateModalCart(int index, int delta) {
              _updateCartQuantity(index, delta);
              setModalState(() {});
              if (_panier.isEmpty) Navigator.pop(context);
            }

            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Poignée et Titre
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Votre Panier',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),

                  // Liste des articles
                  Expanded(
                    child: _panier.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.remove_shopping_cart,
                                  size: 64,
                                  color: Colors.grey.shade300,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Le panier est vide',
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _panier.length,
                            separatorBuilder: (context, index) =>
                                const Divider(),
                            itemBuilder: (context, index) {
                              final item = _panier[index];
                              final nom = item['produit']['nom'];
                              final prixU = item['prix_unitaire'];
                              final qty = item['quantite'];

                              return Row(
                                children: [
                                  // Icone Produit
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.medication,
                                      color: Color(0xFF2E7D32),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  // Infos
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          nom,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${prixU.toStringAsFixed(0)} FC',
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Quantité Controls
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.remove_circle_outline,
                                          color: Colors.red,
                                        ),
                                        onPressed: () =>
                                            updateModalCart(index, -1),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                        ),
                                        child: Text(
                                          '$qty',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.add_circle_outline,
                                          color: Color(0xFF2E7D32),
                                        ),
                                        onPressed: () =>
                                            updateModalCart(index, 1),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            },
                          ),
                  ),

                  // Section Validation
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: _clientController,
                            decoration: InputDecoration(
                              labelText: 'Nom du client (Optionnel)',
                              prefixIcon: const Icon(Icons.person_outline),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            initialValue: _modePaiement,
                            decoration: InputDecoration(
                              labelText: 'Mode de paiement',
                              prefixIcon: const Icon(Icons.payment),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            items: ['Comptant', 'Crédit']
                                .map(
                                  (m) => DropdownMenuItem(
                                    value: m,
                                    child: Text(m),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setModalState(() => _modePaiement = val);
                              }
                            },
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total à Payer',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${_totalPanier.toStringAsFixed(0)} FC',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2E7D32),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              onPressed: _panier.isEmpty || _isSaving
                                  ? null
                                  : () {
                                      Navigator.pop(context); // Fermer le modal
                                      _validerVente(); // Lancer l'API
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2E7D32),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              child: _isSaving
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'VALIDER L\'ENCAISSEMENT',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
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
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Effectuer une vente',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
            )
          : Column(
              children: [
                // Header avec Recherche et Catégories
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    children: [
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Que cherchez-vous ?',
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Colors.grey,
                          ),
                          suffixIcon: IconButton(
                            icon: const Icon(
                              Icons.qr_code_scanner,
                              color: Color(0xFF2E7D32),
                            ),
                            onPressed: () {
                              _showValidationMessage(
                                'Scanner non implémenté. Utilisez la recherche manuelle.',
                                isError: true,
                              );
                            },
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 36,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _categories.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final cat = _categories[index];
                            final isSelected = cat == _selectedCategory;
                            return InkWell(
                              onTap: () => _selectCategory(cat),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF2E7D32)
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF2E7D32)
                                        : Colors.grey.shade300,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  cat,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.grey.shade700,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Liste des produits
                Expanded(
                  child: _filteredProduits.isEmpty
                      ? Center(
                          child: Text(
                            'Aucun produit trouvé',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 16,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredProduits.length,
                          itemBuilder: (context, index) {
                            final p = _filteredProduits[index];
                            final nom = p['nom'] ?? 'Inconnu';
                            final prix = p['prix_vente']?.toString() ?? '0';
                            final cat = p['categorie'] != null
                                ? p['categorie']['nom']
                                : 'Générique';
                            final stockQty = _getStockQty(p);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.02),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: InkWell(
                                onTap: () => _addToCart(p),
                                borderRadius: BorderRadius.circular(16),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFF2E7D32,
                                          ).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.medication,
                                          color: Color(0xFF2E7D32),
                                          size: 30,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              nom,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: Color(0xFF2C3E50),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              cat,
                                              style: TextStyle(
                                                color: Colors.grey.shade500,
                                                fontSize: 12,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 2,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.green.shade50,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          4,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    'Stock actuelle: $stockQty',
                                                    style: const TextStyle(
                                                      color: Color(0xFF2E7D32),
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '$prix FC',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: Color(0xFFE65100),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: const BoxDecoration(
                                              color: Color(0xFF2E7D32),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.add_shopping_cart,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),

      // Bottom Bar ancrée avec le résumé de la commande
      bottomNavigationBar: _panier.isEmpty
          ? const SizedBox.shrink()
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total ($_totalArticles article${_totalArticles > 1 ? 's' : ''})',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_totalPanier.toStringAsFixed(0)} FC',
                            style: const TextStyle(
                              color: Color(0xFF2E7D32),
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _showCartBottomSheet,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.shopping_bag,
                            color: Colors.white,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'VOIR PANIER',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
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
