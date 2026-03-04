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
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Sous-boutons
          if (_isFabExpanded) ...[
            FloatingActionButton.extended(
              onPressed: () async {
                setState(() {
                  _isFabExpanded = false;
                });
                _animationController.reverse();

                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AjouterProduit(),
                  ),
                );

                if (result == true) {
                  _loadProduits(); // Rafraîchir la liste des produits
                }
              },
              backgroundColor: Colors.green,
              icon: const Icon(Icons.add, size: 20, color: Colors.white),
              label: const Text(
                'Ajouter',
                style: TextStyle(fontSize: 12, color: Colors.white),
              ),
            ),
            const SizedBox(height: 8),
            FloatingActionButton.extended(
              onPressed: () {
                setState(() {
                  _isFabExpanded = false;
                });
                _animationController.reverse();
                // TODO: Importer des produits
              },
              backgroundColor: Colors.green,
              icon: const Icon(
                Icons.upload_file,
                size: 20,
                color: Colors.white,
              ),
              label: const Text(
                'Exporter',
                style: TextStyle(fontSize: 12, color: Colors.white),
              ),
            ),
            const SizedBox(height: 8),
            FloatingActionButton.extended(
              onPressed: () {
                setState(() {
                  _isFabExpanded = false;
                });
                _animationController.reverse();
                // TODO: Exporter des produits
              },
              backgroundColor: Colors.green,
              icon: const Icon(Icons.download, size: 20, color: Colors.white),
              label: const Text(
                'Importer',
                style: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Bouton principal
          FloatingActionButton(
            onPressed: () {
              setState(() {
                _isFabExpanded = !_isFabExpanded;
              });
              if (_isFabExpanded) {
                _animationController.forward();
              } else {
                _animationController.reverse();
              }
            },
            backgroundColor: const Color(0xFF2E7D32),
            child: AnimatedIcon(
              icon: AnimatedIcons.menu_close,
              progress: _animation,
              color: Colors.white,
            ),
          ),
        ],
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
            // TODO: Gérer les actions
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 16),
                  SizedBox(width: 8),
                  Text('Modifier'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'stock',
              child: Row(
                children: [
                  Icon(Icons.inventory, size: 16),
                  SizedBox(width: 8),
                  Text('Voir stock'),
                ],
              ),
            ),
            PopupMenuItem(
              value: isActive ? 'disable' : 'enable',
              child: Row(
                children: [
                  Icon(isActive ? Icons.block : Icons.check_circle, size: 16),
                  const SizedBox(width: 8),
                  Text(isActive ? 'Désactiver' : 'Activer'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
