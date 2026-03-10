import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:pharmacie_mobile/services/api_service.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  bool _isLoading = false;
  List<dynamic> _seuilAtteint = [];
  List<dynamic> _stockExpires = [];
  List<dynamic> _seuilInferieur = [];

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Charger les trois types d'alertes en parallèle
      final results = await Future.wait([
        _fetchSeuilAtteint(),
        _fetchStockExpires(),
        _fetchSeuilInferieur(),
      ]);

      setState(() {
        _seuilAtteint = results[0];
        _stockExpires = results[1];
        _seuilInferieur = results[2];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<List<dynamic>> _fetchSeuilAtteint() async {
    final response = await ApiService.authenticatedRequest(
      '/seuil-atteint',
      'GET',
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['produits'] ?? [];
    }
    return [];
  }

  Future<List<dynamic>> _fetchStockExpires() async {
    final response = await ApiService.authenticatedRequest(
      '/stock-expire',
      'GET',
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['produits'] ?? [];
    }
    return [];
  }

  Future<List<dynamic>> _fetchSeuilInferieur() async {
    final response = await ApiService.authenticatedRequest(
      '/seuil-inferieur',
      'GET',
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['produits'] ?? [];
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Notifications & Alertes'),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAlerts,
              child: CustomScrollView(
                slivers: [
                  // Statistiques des alertes
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildAlertCard(
                              'Critiques',
                              '${_seuilInferieur.length}',
                              Colors.red,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildAlertCard(
                              'Urgentes',
                              '${_seuilAtteint.length}',
                              Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildAlertCard(
                              'Expirés',
                              '${_stockExpires.length}',
                              Colors.purple,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Section Stock Critique (seuil_inferieur)
                  if (_seuilInferieur.isNotEmpty) ...[
                    SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final produit = _seuilInferieur[index];
                        return _buildProductAlertTile(
                          produit['produit']['nom'] ?? 'Produit inconnu',
                          'Stock critique: ${produit['quantite'] ?? 0} unités',
                          'Seuil: ${produit['seuil_alerte'] ?? 0} unités',
                          Icons.error,
                          Colors.red,
                          'CRITIQUE',
                          () {},
                        );
                      }, childCount: _seuilInferieur.length),
                    ),
                  ],

                  // Section Seuil Atteint (seuil_atteint)
                  if (_seuilAtteint.isNotEmpty) ...[
                    SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final produit = _seuilAtteint[index];
                        return _buildProductAlertTile(
                          produit['produit']['nom'] ?? 'Produit inconnu',
                          'Seuil atteint: ${produit['quantite'] ?? 0} unités',
                          'Seuil: ${produit['seuil_alerte'] ?? 0} unités',
                          Icons.warning,
                          Colors.orange,
                          'URGENT',
                          () {},
                        );
                      }, childCount: _seuilAtteint.length),
                    ),
                  ],

                  // Section Produits Expirés (stock_expires)
                  if (_stockExpires.isNotEmpty) ...[
                    SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final produit = _stockExpires[index];
                        return _buildProductAlertTile(
                          produit['nom'] ?? 'Produit inconnu',
                          'Produit expiré',
                          'Date expiration: ${produit['date_expiration'] ?? 'Inconnue'}',
                          Icons.date_range,
                          Colors.purple,
                          'EXPIRÉ',
                          () {},
                        );
                      }, childCount: _stockExpires.length),
                    ),
                  ],

                  const SliverToBoxAdapter(child: SizedBox(height: 20)),
                ],
              ),
            ),
    );
  }

  Widget _buildAlertCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductAlertTile(
    String title,
    String subtitle,
    String threshold,
    IconData icon,
    Color color,
    String badge,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              threshold,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            Icons.arrow_forward_ios,
            size: 14,
            color: Colors.grey[600],
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildNotificationTile(
    String title,
    String subtitle,
    String time,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
            const SizedBox(height: 2),
            Text(time, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            Icons.arrow_forward_ios,
            size: 14,
            color: Colors.grey[600],
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  void _showAddNotificationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.add, color: Color(0xFF2E7D32), size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Ajouter une notification'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Choisissez le type de notification à ajouter:',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            // TODO: Ajouter les options de notification
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Ajouter notification
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
            ),
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }
}
