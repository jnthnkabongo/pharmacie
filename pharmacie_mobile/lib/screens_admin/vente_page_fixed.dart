import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:pharmacie_mobile/services/api_service.dart';
import 'dart:convert';
import 'package:pharmacie_mobile/screens_admin/ajouter_vente.dart';

class VentePage extends StatefulWidget {
  const VentePage({super.key});

  @override
  State<VentePage> createState() => _VentePageState();
}

class _VentePageState extends State<VentePage> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  List<Map<String, dynamic>> _ventes = [];
  List<Map<String, dynamic>> _filteredVentes = [];
  bool _isLoading = true;
  double _totalRevenu = 0;
  int _totalClients = 0;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _fadeController.forward();
    _slideController.forward();

    _loadVentes();
  }

  Future<void> _loadVentes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService.getVentes();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("Response: $response");
        final rawVentes = List<dynamic>.from(data['ventes'] ?? []);
        print("Raw Ventes: $rawVentes");
        final List<Map<String, dynamic>> mappedVentes = rawVentes.map((v) {
          final clientName = v['client_id'] != null
              ? (v['client_id'].toString().isNotEmpty
                    ? v['client_id'].toString()
                    : 'Anonyme')
              : 'Anonyme';
          final montant = v['montant_total']?.toString() ?? '0';

          List details = v['vente_details'] ?? v['venteDetails'] ?? [];
          int qty = 0;
          List<String> productNames = [];

          for (var d in details) {
            qty += (d['quantite'] is num
                ? (d['quantite'] as num).toInt()
                : (int.tryParse(d['quantite'].toString()) ?? 0));

            // Get product name if available
            if (d['produit'] != null && d['produit']['nom'] != null) {
              productNames.add(d['produit']['nom'].toString());
            }
          }

          String productDesc = productNames.isNotEmpty
              ? productNames.take(2).join(', ') +
                    (productNames.length > 2 ? '...' : '')
              : (details.isNotEmpty
                    ? '${details.length} article(s)'
                    : 'Divers');

          String dateStr = v['created_at'] != null
              ? v['created_at'].toString().split('T')[0]
              : '';

          return {
            'id': v['id'].toString().padLeft(3, '0'),
            'client_id': clientName,
            'produit': productDesc,
            'quantity': qty,
            'price': '$montant FC',
            'date': dateStr,
            'status': v['type_vente'] ?? 'complété',
            'raw_amount': double.tryParse(montant.replaceAll(',', '')) ?? 0.0,
          };
        }).toList();

        setState(() {
          _ventes = mappedVentes;
          _filteredVentes = _ventes;
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
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _calculateStats() {
    _totalRevenu = 0;
    Set<String> uniqueClients = {};

    for (var v in _ventes) {
      _totalRevenu += v['raw_amount'] as double;
      uniqueClients.add(v['client_id'] as String);
    }
    _totalClients = uniqueClients.length;
  }

  void _filterSearch(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredVentes = _ventes;
      } else {
        final lowerQuery = query.toLowerCase();
        _filteredVentes = _ventes.where((v) {
          return v['client_id'].toString().toLowerCase().contains(lowerQuery) ||
              v['produit'].toString().toLowerCase().contains(lowerQuery) ||
              v['id'].toString().toLowerCase().contains(lowerQuery);
        }).toList();
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Gestion des Ventes',
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
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () => _showSearchDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onPressed: () => _showFilterDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Section statistiques avec animation
          FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildAnimatedStatCard(
                          'Ventes',
                          _ventes.length.toString(),
                          Icons.shopping_cart,
                          Colors.blue,
                        ),
                        _buildAnimatedStatCard(
                          'Revenu',
                          '${_totalRevenu.toStringAsFixed(0)} FC',
                          Icons.attach_money,
                          Colors.green,
                        ),
                        _buildAnimatedStatCard(
                          'Clients',
                          _totalClients.toString(),
                          Icons.people,
                          Colors.orange,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Liste des ventes
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                // Simuler un rafraîchissement
                await Future.delayed(const Duration(seconds: 1));
                setState(() {});
              },
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF2E7D32),
                      ),
                    )
                  : _filteredVentes.isEmpty
                  ? const Center(child: Text("Aucune vente trouvée"))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filteredVentes.length,
                      itemBuilder: (context, index) {
                        final venteItem = _filteredVentes[index];
                        return AnimatedContainer(
                          duration: Duration(milliseconds: 300 + (index * 100)),
                          curve: Curves.easeOut,
                          margin: const EdgeInsets.only(bottom: 6),
                          transform: Matrix4.translationValues(0, 0, 0),
                          child: Card(
                            elevation: 8,
                            shadowColor: Colors.black.withOpacity(0.1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: LinearGradient(
                                  colors: [Colors.white, Colors.grey.shade50],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(8),
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                    size: 18,
                                  ),
                                ),
                                title: Text(
                                  "Client : ${venteItem['client_id']}",
                                  // venteItem['client_id'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Color(0xFF2C3E50),
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.medication,
                                          size: 14,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(width: 2),
                                        Expanded(
                                          child: Text(
                                            "Produit : ${venteItem['produit']} - ${venteItem['quantity']} unité(s)",
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.access_time,
                                          size: 14,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(width: 2),
                                        Text(
                                          venteItem['date'],
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      venteItem['price'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: Color(0xFF2E7D32),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        venteItem['status'],
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () => _showVenteDetails(venteItem),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
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
              MaterialPageRoute(builder: (context) => const AjouterVente()),
            );
            if (result == true) {
              _loadVentes(); // On rafraîchit si une vente a été ajoutée
            }
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  Widget _buildAnimatedStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      builder: (context, animationValue, child) {
        return Transform.scale(
          scale: animationValue,
          child: Opacity(
            opacity: animationValue,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: Colors.white, size: 20),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /* ==============================
        DIALOG SEARCH
  ============================== */

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rechercher une vente'),
        content: TextField(
          onChanged: (val) {
            _filterSearch(val);
          },
          decoration: const InputDecoration(
            hintText: 'Entrez le nom du client ou du produit...',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              minimumSize: const Size(100, 40),
              textStyle: const TextStyle(fontSize: 16),
            ),
            child: const Text('Rechercher'),
          ),
        ],
      ),
    );
  }

  /* ==============================
        DIALOG FILTER
  ============================== */

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtrer les ventes'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CheckboxListTile(
              title: const Text('Ventes complétées'),
              value: true,
              onChanged: (value) {},
            ),
            CheckboxListTile(
              title: const Text('Ventes en attente'),
              value: true,
              onChanged: (value) {},
            ),
            CheckboxListTile(
              title: const Text('Aujourd\'hui'),
              value: false,
              onChanged: (value) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
            ),
            child: const Text('Appliquer'),
          ),
        ],
      ),
    );
  }

  /* ==============================
        DIALOG ADD VENTE
  ============================== */

  /* ==============================
        DIALOG DETAILS
  ============================== */

  void _showVenteDetails(Map<String, dynamic> vente) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [Colors.white, Colors.grey.shade50],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header avec statut
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        vente['status'] == 'complété'
                            ? Icons.check_circle
                            : Icons.pending,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Détails de la vente',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '#${vente['id']} - ${vente['date']}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        vente['status'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Informations détaillées
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
                  children: [
                    _buildDetailRow(
                      'Numéro vente',
                      '#${vente['id']}',
                      Icons.receipt,
                    ),
                    _buildDetailRow('Client', vente['client_id'], Icons.person),
                    _buildDetailRow(
                      'Produit',
                      vente['produit'],
                      Icons.medication,
                    ),
                    _buildDetailRow(
                      'Quantité',
                      '${vente['quantity']} unités',
                      Icons.inventory,
                    ),
                    _buildDetailRow('Date', vente['date'], Icons.access_time),
                    const SizedBox(height: 8),
                    const Divider(color: Color(0xFF2E7D32)),
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      'Total',
                      vente['price'],
                      Icons.attach_money,
                      isTotal: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Boutons d'action
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _showPrintDialog(vente);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.print, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Imprimer',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
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
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    IconData icon, {
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isTotal
                  ? const Color(0xFF2E7D32).withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: isTotal ? const Color(0xFF2E7D32) : Colors.grey[600],
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: isTotal ? const Color(0xFF2E7D32) : Colors.grey[700],
              fontSize: isTotal ? 16 : 14,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: isTotal ? const Color(0xFF2E7D32) : Colors.black87,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }

  /* ==============================
        DIALOG PRINT
  ============================== */

  void _showPrintDialog(Map<String, dynamic> vente) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [Colors.white, Colors.grey.shade50],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.print,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Options d\'impression',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Options
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
                  children: [
                    _buildPrintOption(
                      title: 'Sauvegarder en PDF',
                      subtitle: 'Télécharger la facture sur votre appareil',
                      icon: Icons.picture_as_pdf,
                      color: Colors.blue,
                      onTap: () {
                        Navigator.pop(context);
                        _savePDF(vente);
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildPrintOption(
                      title: 'Imprimer',
                      subtitle: 'Imprimer via une imprimante',
                      icon: Icons.print,
                      color: Colors.green,
                      onTap: () {
                        Navigator.pop(context);
                        _printPDF(vente);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Bouton annuler
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Color(0xFF2E7D32)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Annuler',
                    style: TextStyle(
                      color: Color(0xFF2E7D32),
                      fontWeight: FontWeight.w600,
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

  Widget _buildPrintOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
          ],
        ),
      ),
    );
  }

  /* ==============================
        PDF GENERATOR (COMMUN)
  ============================== */

  Future<pw.Document> _generatePdf(Map<String, dynamic> vente) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        margin: const pw.EdgeInsets.all(0),
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              gradient: pw.LinearGradient(
                colors: [
                  const PdfColor.fromInt(0xFF2E7D32),
                  const PdfColor.fromInt(0xFF43A047),
                ],
                begin: const pw.Alignment(0, 0),
                end: const pw.Alignment(1, 1),
              ),
            ),
            child: pw.Column(
              children: [
                // Header
                pw.Container(
                  padding: const pw.EdgeInsets.all(40),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                'PHARMACIE PLUS',
                                style: pw.TextStyle(
                                  fontSize: 28,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.white,
                                ),
                              ),
                              pw.SizedBox(height: 8),
                              pw.Text(
                                'Votre santé, notre priorité',
                                style: pw.TextStyle(
                                  fontSize: 14,
                                  color: PdfColors.white,
                                ),
                              ),
                            ],
                          ),
                          pw.Container(
                            padding: const pw.EdgeInsets.all(16),
                            decoration: pw.BoxDecoration(
                              color: PdfColors.white,
                              borderRadius: pw.BorderRadius.circular(12),
                            ),
                            child: pw.Column(
                              children: [
                                pw.Text(
                                  'FACTURE',
                                  style: pw.TextStyle(
                                    fontSize: 18,
                                    fontWeight: pw.FontWeight.bold,
                                    color: const PdfColor.fromInt(0xFF2E7D32),
                                  ),
                                ),
                                pw.Text(
                                  '#${vente['id']}',
                                  style: pw.TextStyle(
                                    fontSize: 14,
                                    color: const PdfColor.fromInt(0xFF2E7D32),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Content
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(40),
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius: pw.BorderRadius.only(
                        topLeft: pw.Radius.circular(30),
                        topRight: pw.Radius.circular(30),
                      ),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        // Informations de la vente
                        pw.Container(
                          padding: const pw.EdgeInsets.all(24),
                          decoration: pw.BoxDecoration(
                            color: PdfColor.fromInt(0xFFF5F7FA),
                            borderRadius: pw.BorderRadius.circular(16),
                          ),
                          child: pw.Column(
                            children: [
                              _buildPdfRow(
                                'Numéro facture',
                                '#${vente['id']}',
                                Icons.receipt,
                              ),
                              _buildPdfRow(
                                'Date',
                                vente['date'],
                                Icons.access_time,
                              ),
                              _buildPdfRow(
                                'Statut',
                                vente['status'],
                                Icons.check_circle,
                              ),
                            ],
                          ),
                        ),

                        pw.SizedBox(height: 24),

                        // Détails du client et produit
                        pw.Row(
                          children: [
                            pw.Expanded(
                              child: pw.Container(
                                padding: const pw.EdgeInsets.all(24),
                                decoration: pw.BoxDecoration(
                                  color: PdfColor.fromInt(0xFFF5F7FA),
                                  borderRadius: pw.BorderRadius.circular(16),
                                ),
                                child: pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.start,
                                  children: [
                                    pw.Text(
                                      'CLIENT',
                                      style: pw.TextStyle(
                                        fontSize: 12,
                                        fontWeight: pw.FontWeight.bold,
                                        color: const PdfColor.fromInt(
                                          0xFF2E7D32,
                                        ),
                                      ),
                                    ),
                                    pw.SizedBox(height: 8),
                                    pw.Text(
                                      vente['client'],
                                      style: pw.TextStyle(
                                        fontSize: 16,
                                        fontWeight: pw.FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            pw.SizedBox(width: 16),
                            pw.Expanded(
                              child: pw.Container(
                                padding: const pw.EdgeInsets.all(24),
                                decoration: pw.BoxDecoration(
                                  color: PdfColor.fromInt(0xFFF5F7FA),
                                  borderRadius: pw.BorderRadius.circular(16),
                                ),
                                child: pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.start,
                                  children: [
                                    pw.Text(
                                      'PRODUIT',
                                      style: pw.TextStyle(
                                        fontSize: 12,
                                        fontWeight: pw.FontWeight.bold,
                                        color: const PdfColor.fromInt(
                                          0xFF43A047,
                                        ),
                                      ),
                                    ),
                                    pw.SizedBox(height: 8),
                                    pw.Text(
                                      vente['produit'],
                                      style: pw.TextStyle(
                                        fontSize: 16,
                                        fontWeight: pw.FontWeight.bold,
                                      ),
                                    ),
                                    pw.SizedBox(height: 4),
                                    pw.Text(
                                      'Quantité: ${vente['quantity']} unités',
                                      style: pw.TextStyle(
                                        fontSize: 12,
                                        color: PdfColors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        pw.SizedBox(height: 24),

                        // Total
                        pw.Container(
                          padding: const pw.EdgeInsets.all(24),
                          decoration: pw.BoxDecoration(
                            gradient: pw.LinearGradient(
                              colors: [
                                const PdfColor.fromInt(0xFF2E7D32),
                                const PdfColor.fromInt(0xFF43A047),
                              ],
                            ),
                            borderRadius: pw.BorderRadius.circular(16),
                          ),
                          child: pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(
                                'TOTAL À PAYER',
                                style: pw.TextStyle(
                                  fontSize: 18,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.white,
                                ),
                              ),
                              pw.Text(
                                vente['price'],
                                style: pw.TextStyle(
                                  fontSize: 24,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.white,
                                ),
                              ),
                            ],
                          ),
                        ),

                        pw.Spacer(),

                        // Footer
                        pw.Container(
                          padding: const pw.EdgeInsets.all(16),
                          decoration: pw.BoxDecoration(
                            color: PdfColor.fromInt(0xFFF5F7FA),
                            borderRadius: pw.BorderRadius.circular(12),
                          ),
                          child: pw.Column(
                            children: [
                              pw.Text(
                                'Merci pour votre confiance!',
                                style: pw.TextStyle(
                                  fontSize: 14,
                                  fontWeight: pw.FontWeight.bold,
                                  color: const PdfColor.fromInt(0xFF2E7D32),
                                ),
                              ),
                              pw.SizedBox(height: 4),
                              pw.Text(
                                'Pour toute question, contactez-nous au: +225 00 00 00 00',
                                style: pw.TextStyle(
                                  fontSize: 10,
                                  color: PdfColors.grey,
                                ),
                              ),
                            ],
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
      ),
    );

    return pdf;
  }

  pw.Widget _buildPdfRow(String label, String value, IconData icon) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        children: [
          pw.Container(
            width: 20,
            height: 20,
            decoration: pw.BoxDecoration(
              color: PdfColor.fromInt(0xFF2E7D32),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Center(
              child: pw.Text(
                _getIconLetter(icon),
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: const PdfColor.fromInt(0xFF2E7D32),
                ),
              ),
            ),
          ),
          pw.SizedBox(width: 12),
          pw.Text(
            label,
            style: pw.TextStyle(fontSize: 12, color: PdfColors.grey),
          ),
          pw.Spacer(),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  String _getIconLetter(IconData icon) {
    if (icon == Icons.receipt) return 'R';
    if (icon == Icons.access_time) return 'T';
    if (icon == Icons.check_circle) return '✓';
    return '•';
  }

  /* ==============================
        SAVE PDF
  ============================== */

  Future<void> _savePDF(Map<String, dynamic> vente) async {
    try {
      final pdf = await _generatePdf(vente);
      final bytes = await pdf.save();

      await Printing.sharePdf(
        bytes: bytes,
        filename: "facture_${vente['id']}.pdf",
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur PDF : $e"), backgroundColor: Colors.red),
      );
    }
  }

  /* ==============================
        PRINT PDF
  ============================== */

  Future<void> _printPDF(Map<String, dynamic> vente) async {
    try {
      final pdf = await _generatePdf(vente);

      await Printing.layoutPdf(onLayout: (format) async => pdf.save());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur impression : $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
