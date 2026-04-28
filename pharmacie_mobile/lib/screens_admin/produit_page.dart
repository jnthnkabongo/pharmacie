import 'package:flutter/material.dart';
import 'package:pharmacie_mobile/services/api_service.dart';
import 'dart:convert';
import 'package:pharmacie_mobile/screens_admin/ajouter_produit.dart';

class ProduitPage extends StatefulWidget {
  const ProduitPage({super.key});

  @override
  State<ProduitPage> createState() => _ProduitPageState();
}

class _ProduitPageState extends State<ProduitPage>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  bool _isFabExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  List<Map<String, dynamic>> _produits = [];
  List<Map<String, dynamic>> _filteredProduits = [];
  bool _isLoading = true;

  final int _totalActifs = 0;
  final int _totalInactifs = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_animationController);

    _loadProduits();
  }

  Future<void> _loadProduits() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService.getProduits();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _produits = List<Map<String, dynamic>>.from(data['produits'] ?? []);
          _filteredProduits = _produits;

          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: ${response.statusCode}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur réseau: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterProduits() {
    setState(() {
      final searchLower = _searchController.text.toLowerCase();
      _filteredProduits = _produits.where((produit) {
        final nom = produit['nom']?.toString().toLowerCase() ?? '';
        final categorie =
            produit['categorie']?['nom']?.toString().toLowerCase() ?? '';

        return searchLower.isEmpty ||
            nom.contains(searchLower) ||
            categorie.contains(searchLower);
      }).toList();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Produits'),
        centerTitle: true,
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
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
      body: Column(
        children: [
          // Barre de recherche
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => _filterProduits(),
              decoration: InputDecoration(
                hintText: 'Rechercher un produit...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Liste des produits
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
                  )
                : _filteredProduits.isEmpty
                ? const Center(child: Text('Aucun produit trouvé'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredProduits.length,
                    itemBuilder: (context, index) =>
                        _buildProductCard(_filteredProduits[index]),
                  ),
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AjouterProduit()),
            );
            if (result == true) {
              _loadProduits(); // On rafraîchit si un produit a été ajouté
            }
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final name = product['nom']?.toString() ?? 'Inconnu';
    final category =
        product['categorie']?['nom']?.toString() ?? 'Sans catégorie';
    final fournisseur =
        product['fournisseur']?['nom']?.toString() ?? 'Aucun fournisseur';
    final price = product['prix_vente']?.toString() ?? '0';
    final isActive = product['actif'] == 1 || product['actif'] == true;

    // Récupération de la quantité en stock
    final int stockQty =
        product['stock'] != null && product['stock']['quantite'] != null
        ? (product['stock']['quantite'] is num
              ? (product['stock']['quantite'] as num).toInt()
              : int.tryParse(product['stock']['quantite'].toString()) ?? 0)
        : 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isActive ? Colors.green : Colors.grey,
          child: Icon(
            isActive ? Icons.medication : Icons.medication_outlined,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$category | $fournisseur'),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  '$price FC',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: stockQty > 0
                        ? Colors.blue.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'En stock: $stockQty',
                    style: TextStyle(
                      fontSize: 12,
                      color: stockQty > 0 ? Colors.blue : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            if (value == 'edit') {
              _showEditModalBottomSheet(context, product);
            } else if (value == 'stock') {
              _showDeleteConfirmation(context, product);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 16, color: Colors.orange),
                  SizedBox(width: 8),
                  Text('Modifier'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'stock',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 16, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Supprimer'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditModalBottomSheet(
    BuildContext context,
    Map<String, dynamic> product,
  ) {
    final _nomController = TextEditingController(
      text: product['nom']?.toString() ?? '',
    );
    final _descriptionController = TextEditingController(
      text: product['description']?.toString() ?? '',
    );
    final _prixAchatController = TextEditingController(
      text: product['prix_achat']?.toString() ?? '',
    );
    final _prixVenteController = TextEditingController(
      text: product['prix_vente']?.toString() ?? '',
    );
    final _codeBarreController = TextEditingController(
      text: product['code_barre']?.toString() ?? '',
    );
    final _dateExpirationController = TextEditingController(
      text: _formatDate(product['date_expiration']),
    );
    print('📦 Produit complet: $product');
    print('📊 Stock brut: ${product['stock']}');
    print('📅 Date expiration brute: ${product['date_expiration']}');

    final _stockController = TextEditingController(
      text: product['stock']?['quantite']?.toString() ?? '0',
    );
    final _seuilAlerteController = TextEditingController(
      text: product['seuil_alerte']?.toString() ?? '10',
    );

    print('📦 Stock controller: "${_stockController.text}"');
    print('📅 Date controller: "${_dateExpirationController.text}"');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Modifier le produit',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: _nomController,
                decoration: const InputDecoration(
                  labelText: 'Nom du produit *',
                  prefixIcon: Icon(Icons.medication),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  prefixIcon: Icon(Icons.description),
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _prixAchatController,
                      decoration: const InputDecoration(
                        labelText: 'Prix d\'achat (FC)',
                        prefixIcon: Icon(Icons.shopping_cart),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _prixVenteController,
                      decoration: const InputDecoration(
                        labelText: 'Prix de vente (FC)',
                        prefixIcon: Icon(Icons.payment),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _stockController,
                      decoration: const InputDecoration(
                        labelText: 'Quantité en stock',
                        prefixIcon: Icon(Icons.inventory),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _seuilAlerteController,
                      decoration: const InputDecoration(
                        labelText: 'Seuil d\'alerte',
                        prefixIcon: Icon(Icons.warning),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: _codeBarreController,
                decoration: const InputDecoration(
                  labelText: 'Code barre',
                  prefixIcon: Icon(Icons.qr_code),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: _dateExpirationController,
                decoration: const InputDecoration(
                  labelText: 'Date d\'expiration',
                  prefixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(),
                ),
                readOnly: true,
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2030),
                  );
                  if (date != null) {
                    _dateExpirationController.text =
                        '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
                  }
                },
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: const Text(
                        'Annuler',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_nomController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Le nom du produit est requis'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        try {
                          final response = await ApiService.updateProduit(
                            product['id'].toString(),
                            {
                              'nom': _nomController.text.trim(),
                              'description': _descriptionController.text.trim(),
                              'prix_achat': _prixAchatController.text.trim(),
                              'prix_vente': _prixVenteController.text.trim(),
                              'code_barre': _codeBarreController.text.trim(),
                              'date_expiration': _dateExpirationController.text
                                  .trim(),
                              'quantite': _stockController.text.trim(),
                              'seuil_alerte': _seuilAlerteController.text
                                  .trim(),
                            },
                          );

                          Navigator.pop(context);

                          if (response.statusCode == 200) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Produit modifié avec succès'),
                                backgroundColor: Colors.green,
                              ),
                            );
                            _loadProduits();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Erreur lors de la modification: ${response.body}',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        } catch (e) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Erreur: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: const Text(
                        'Enregistrer',
                        style: TextStyle(color: Colors.white),
                      ),
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

  void _showDeleteConfirmation(
    BuildContext context,
    Map<String, dynamic> product,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer le produit "${product['nom']}" ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              try {
                final response = await ApiService.deleteProduit(
                  product['id'].toString(),
                );

                Navigator.pop(context);

                if (response.statusCode == 200) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Produit supprimé avec succès'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _loadProduits();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Erreur lors de la suppression: ${response.body}',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erreur: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic dateValue) {
    if (dateValue == null || dateValue.toString().isEmpty) {
      return '';
    }

    try {
      // Essayer de parser en DateTime (gère les formats ISO 8601 comme "2027-04-24T00:00:00.000000Z")
      final dateTime = DateTime.parse(dateValue.toString());
      return '${dateTime.day.toString().padLeft(2, '0')}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.year}';
    } catch (e) {
      // Si le parsing échoue, essayer le format simple YYYY-MM-DD
      try {
        final dateString = dateValue.toString();
        if (dateString.contains('-') && dateString.length >= 10) {
          final year = dateString.substring(0, 4);
          final month = dateString.substring(5, 7);
          final day = dateString.substring(8, 10);
          return '$day-$month-$year';
        }
      } catch (e2) {
        // En cas d'erreur double, retourner la valeur brute
        return dateValue.toString();
      }

      return dateValue.toString();
    }
  }
}
