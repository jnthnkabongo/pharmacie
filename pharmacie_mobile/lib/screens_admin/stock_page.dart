import 'package:flutter/material.dart';
import 'package:pharmacie_mobile/services/api_service.dart';
import 'dart:convert';

class StockPage extends StatefulWidget {
  const StockPage({super.key});

  @override
  State<StockPage> createState() => _StockPageState();
}

class _StockPageState extends State<StockPage> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  bool _isFabExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  List<Map<String, dynamic>> _stocks = [];
  List<Map<String, dynamic>> _filteredStocks = [];
  bool _isLoading = true;

  int _totalItems = 0;
  int _totalAlertes = 0;
  int _totalRuptures = 0;

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

    _loadStock();
  }

  Future<void> _loadStock() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService.getStock();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _stocks = List<Map<String, dynamic>>.from(data['stocks'] ?? []);
          _filteredStocks = _stocks;
          _calculateStats();
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
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur réseau: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _calculateStats() {
    _totalItems = 0;
    _totalAlertes = 0;
    _totalRuptures = 0;

    for (var item in _stocks) {
      final int quantite = item['quantite'] is num
          ? (item['quantite'] as num).toInt()
          : int.tryParse(item['quantite']?.toString() ?? '0') ?? 0;
      final int seuil = item['seuil_alerte'] is num
          ? (item['seuil_alerte'] as num).toInt()
          : int.tryParse(item['seuil_alerte']?.toString() ?? '0') ?? 0;

      _totalItems += quantite;

      if (quantite == 0) {
        _totalRuptures++;
      } else if (quantite <= seuil) {
        _totalAlertes++;
      }
    }
  }

  void _filterStocks() {
    setState(() {
      final searchLower = _searchController.text.toLowerCase();
      _filteredStocks = _stocks.where((item) {
        final nom = item['produit_nom']?.toString().toLowerCase() ?? '';
        return searchLower.isEmpty || nom.contains(searchLower);
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
        title: const Text('Stock'),
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
          SizedBox(height: 12),
          // Statistiques simples
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _buildSimpleCard(
                    'Total Qté',
                    _totalItems.toString(),
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSimpleCard(
                    'Alertes',
                    _totalAlertes.toString(),
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSimpleCard(
                    'Ruptures',
                    _totalRuptures.toString(),
                    Colors.red,
                  ),
                ),
              ],
            ),
          ),
          // Barre de recherche
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => _filterStocks(),
              decoration: InputDecoration(
                hintText: 'Rechercher...',
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
                : _filteredStocks.isEmpty
                ? const Center(child: Text('Aucun stock trouvé'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredStocks.length,
                    itemBuilder: (context, index) =>
                        _buildSimpleProductCard(_filteredStocks[index]),
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
              onPressed: () {
                setState(() {
                  _isFabExpanded = false;
                });
                _animationController.reverse();
                // TODO: Faire inventaire
              },
              backgroundColor: Colors.blue,
              icon: const Icon(Icons.inventory_2, size: 20),
              label: const Text('Inventaire', style: TextStyle(fontSize: 12)),
            ),
            const SizedBox(height: 8),
            FloatingActionButton.extended(
              onPressed: () {
                setState(() {
                  _isFabExpanded = false;
                });
                _animationController.reverse();
                // TODO: Ajuster stock
              },
              backgroundColor: Colors.orange,
              icon: const Icon(Icons.tune, size: 20),
              label: const Text('Ajuster', style: TextStyle(fontSize: 12)),
            ),
            const SizedBox(height: 8),
            FloatingActionButton.extended(
              onPressed: () {
                setState(() {
                  _isFabExpanded = false;
                });
                _animationController.reverse();
                // TODO: Ajouter produit
              },
              backgroundColor: Colors.purple,
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Ajouter', style: TextStyle(fontSize: 12)),
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

  Widget _buildSimpleCard(String title, String value, Color color) {
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

  Widget _buildSimpleProductCard(Map<String, dynamic> product) {
    final name = product['produit_nom']?.toString() ?? 'Inconnu';
    final int stock = product['quantite'] is num
        ? (product['quantite'] as num).toInt()
        : int.tryParse(product['quantite']?.toString() ?? '0') ?? 0;
    final int seuil = product['seuil_alerte'] is num
        ? (product['seuil_alerte'] as num).toInt()
        : int.tryParse(product['seuil_alerte']?.toString() ?? '0') ?? 0;

    final isOutOfStock = stock == 0;
    final isLowStock = stock <= seuil && stock > 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isOutOfStock
              ? Colors.red
              : isLowStock
              ? Colors.orange
              : Colors.green,
          child: Icon(
            isOutOfStock
                ? Icons.error
                : (isLowStock ? Icons.warning : Icons.check_circle),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(name),
        subtitle: Text('Stock: $stock | Seuil: $seuil'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isOutOfStock
                ? Colors.red.withOpacity(0.1)
                : (isLowStock
                      ? Colors.orange.withOpacity(0.1)
                      : Colors.green.withOpacity(0.1)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            isOutOfStock ? 'Rupture' : (isLowStock ? 'Alerte' : 'Normal'),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isOutOfStock
                  ? Colors.red
                  : (isLowStock ? Colors.orange : Colors.green),
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
