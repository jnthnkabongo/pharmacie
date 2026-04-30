import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

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
        final rawVentes = List<dynamic>.from(data['ventes'] ?? []);
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
          Map<String, double> prixUnitaires = {};

          for (var d in details) {
            int quantite = d['quantite'] is num
                ? (d['quantite'] as num).toInt()
                : (int.tryParse(d['quantite'].toString()) ?? 0);

            qty += quantite;

            // Récupérer le prix unitaire
            double prixUnitaire = 0;
            if (d['prix_unitaire'] is num) {
              prixUnitaire = (d['prix_unitaire'] as num).toDouble();
            } else {
              prixUnitaire =
                  double.tryParse(d['prix_unitaire']?.toString() ?? '0') ?? 0;
            }

            // Get product name if available
            if (d['produit'] != null && d['produit']['nom'] != null) {
              String productName = d['produit']['nom'].toString();

              // Stocker le prix unitaire pour ce produit
              prixUnitaires[productName] = prixUnitaire;

              // Ajouter chaque unité comme un produit séparé
              for (int i = 0; i < quantite; i++) {
                productNames.add(productName);
              }
            }
          }

          String productDesc = productNames.isNotEmpty
              ? productNames.join(', ')
              : (details.isNotEmpty
                    ? '${details.length} article(s)'
                    : 'Divers');

          String dateStr = v['created_at'] != null
              ? v['created_at'].toString().split('T')[0]
              : '';

          final venteTransformed = {
            'id': v['id'].toString().padLeft(3, '0'),
            'client_id': clientName,
            'produit': productDesc,
            'quantity': qty,
            'price': '$montant FC',
            'date': dateStr,
            'status': v['type_vente'] ?? 'complété',
            'raw_amount': double.tryParse(montant.replaceAll(',', '')) ?? 0.0,
            'prix_unitaires': prixUnitaires,
            'vente_details': details, // Garder les détails bruts pour le PDF
          };

          return venteTransformed;
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
        automaticallyImplyLeading: false,
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
                                    const SizedBox(height: 4),
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
                      '${vente['produit']} (x${vente['quantity']})',
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
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
                color: isTotal ? const Color(0xFF2E7D32) : Colors.black87,
                fontSize: isTotal ? 16 : 14,
              ),
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
    // Debug détaillé de la structure
    if (vente['vente_details'] != null) {
      for (int i = 0; i < (vente['vente_details'] as List).length; i++) {
        var detail = (vente['vente_details'] as List)[i];

        if (detail is Map && detail['produit'] != null) {
          if (detail['produit'] is Map) {}
        }
      }
    } else {
      // Parser les produits multiples si le champ produit contient des virgules
      String produitsStr = vente['produit']?.toString() ?? '';

      List<String> produitsList = [];
      if (produitsStr.contains(',')) {
        produitsList = produitsStr.split(',').map((p) => p.trim()).toList();
        for (int i = 0; i < produitsList.length; i++) {}
      } else {
        produitsList = [produitsStr];
      }
    }

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
                  padding: const pw.EdgeInsets.all(20),
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
                                  '#${vente['id']?.toString() ?? 'unknown'}',
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
                    padding: const pw.EdgeInsets.all(20),
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
                                '#${vente['id']?.toString() ?? 'unknown'}',
                                Icons.receipt,
                              ),
                              _buildPdfRow(
                                'Date',
                                vente['date']?.toString() ?? 'Date inconnue',
                                Icons.access_time,
                              ),
                              _buildPdfRow(
                                'Statut',
                                vente['status']?.toString() ?? 'Inconnu',
                                Icons.check_circle,
                              ),
                            ],
                          ),
                        ),

                        pw.SizedBox(height: 5),

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
                                    pw.SizedBox(height: 4),
                                    pw.Text(
                                      vente['client_id']?.toString() ??
                                          'Client inconnu',
                                      style: pw.TextStyle(
                                        fontSize: 16,
                                        fontWeight: pw.FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        pw.SizedBox(height: 5),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Container(
                              width: double.infinity,
                              padding: const pw.EdgeInsets.all(24),
                              decoration: pw.BoxDecoration(
                                color: PdfColor.fromInt(0xFFF5F7FA),
                                borderRadius: pw.BorderRadius.circular(16),
                              ),
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(
                                    'PRODUITS VENDUS',
                                    style: pw.TextStyle(
                                      fontSize: 12,
                                      fontWeight: pw.FontWeight.bold,
                                      color: const PdfColor.fromInt(0xFF43A047),
                                    ),
                                  ),
                                  pw.SizedBox(height: 8),
                                  pw.Builder(
                                    builder: (context) {
                                      if (vente['prix_unitaires'] != null &&
                                          vente['prix_unitaires'].isNotEmpty) {
                                        Map<String, double> prixUnitaires =
                                            vente['prix_unitaires'];

                                        // Récupérer les quantités depuis vente_details
                                        Map<String, int> quantites = {};
                                        List details =
                                            vente['vente_details'] ?? [];
                                        for (var d in details) {
                                          if (d['produit'] != null &&
                                              d['produit']['nom'] != null) {
                                            String productName =
                                                d['produit']['nom'].toString();
                                            int quantite = d['quantite'] is num
                                                ? (d['quantite'] as num).toInt()
                                                : (int.tryParse(
                                                        d['quantite']
                                                            .toString(),
                                                      ) ??
                                                      0);
                                            quantites[productName] = quantite;
                                          }
                                        }

                                        return pw.Column(
                                          crossAxisAlignment:
                                              pw.CrossAxisAlignment.start,
                                          children: [
                                            for (
                                              int i = 0;
                                              i < prixUnitaires.keys.length;
                                              i++
                                            )
                                              pw.Container(
                                                margin:
                                                    const pw.EdgeInsets.only(
                                                      bottom: 4,
                                                    ),
                                                child: pw.Column(
                                                  crossAxisAlignment: pw
                                                      .CrossAxisAlignment
                                                      .start,
                                                  children: [
                                                    pw.Text(
                                                      '${i + 1}. ${prixUnitaires.keys.elementAt(i)} - ${quantites[prixUnitaires.keys.elementAt(i)] ?? 1} unité(s) - ${prixUnitaires.values.elementAt(i).toStringAsFixed(2)} FC',
                                                      style: pw.TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            pw.FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            pw.SizedBox(height: 8),
                                            pw.Text(
                                              'Total: ${vente['quantity'] ?? 0} article(s) - ${vente['price'] ?? '0'}',
                                              style: pw.TextStyle(
                                                fontSize: 13,
                                                fontWeight: pw.FontWeight.bold,
                                                color: const PdfColor.fromInt(
                                                  0xFF2E7D32,
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      }

                                      // Vérifier si c'est une vente simple ou multiple
                                      final details =
                                          vente['vente_details'] ??
                                          vente['venteDetails'] ??
                                          [];

                                      final isSimpleSale =
                                          details.isEmpty &&
                                          (vente['produit'] != null ||
                                              vente['product'] != null);

                                      if (isSimpleSale) {
                                        // Vente simple - parser la chaîne de produits
                                        final produitsStr =
                                            vente['produit']?.toString() ??
                                            vente['product']?.toString() ??
                                            'Produit inconnu';
                                        final quantite =
                                            vente['quantity']?.toString() ??
                                            vente['quantite']?.toString() ??
                                            '0';
                                        final prix =
                                            vente['price']?.toString() ??
                                            vente['prix_unitaire']
                                                ?.toString() ??
                                            vente['montant_total']
                                                ?.toString() ??
                                            '0';

                                        // Parser la chaîne "aspirine, doliprane..." en liste
                                        List<String> produits = [];
                                        if (produitsStr.contains(',')) {
                                          produits = produitsStr
                                              .split(',')
                                              .map((p) => p.trim())
                                              .toList();
                                        } else {
                                          produits = [produitsStr];
                                        }

                                        // Compter les occurrences et récupérer les prix unitaires
                                        Map<String, Map<String, dynamic>>
                                        productInfo = {};

                                        // Essayer de récupérer les prix depuis les données originales si disponibles

                                        if (vente['vente_details'] != null) {
                                          List details = vente['vente_details'];
                                          for (var d in details) {
                                            // Récupérer le prix unitaire
                                            double prixUnitaire = 0;
                                            if (d['prix_unitaire'] is num) {
                                              prixUnitaire =
                                                  (d['prix_unitaire'] as num)
                                                      .toDouble();
                                            } else {
                                              prixUnitaire =
                                                  double.tryParse(
                                                    d['prix_unitaire']
                                                            ?.toString() ??
                                                        '0',
                                                  ) ??
                                                  0;
                                            }

                                            if (d['produit'] != null &&
                                                d['produit']['nom'] != null) {
                                              String productName =
                                                  d['produit']['nom']
                                                      .toString();
                                              int quantite =
                                                  d['quantite'] is num
                                                  ? (d['quantite'] as num)
                                                        .toInt()
                                                  : int.tryParse(
                                                          d['quantite']
                                                              .toString(),
                                                        ) ??
                                                        0;

                                              productInfo[productName] = {
                                                'quantite': quantite,
                                                'prix_unitaire': prixUnitaire
                                                    .toStringAsFixed(2),
                                              };
                                            }
                                          }
                                        } else {
                                          // Fallback: utiliser les produits de la chaîne et récupérer le prix unitaire depuis d'autres champs
                                          for (String produit in produits) {
                                            if (produit.isNotEmpty) {
                                              if (productInfo.containsKey(
                                                produit,
                                              )) {
                                                productInfo[produit]?['quantite'] =
                                                    (productInfo[produit]?['quantite'] ??
                                                        0) +
                                                    1;
                                              } else {
                                                // Chercher le prix unitaire en brut
                                                var prixUnitaireBrut =
                                                    vente['prix_unitaire'];

                                                productInfo[produit] = {
                                                  'quantite': 1,
                                                  'prix_unitaire':
                                                      prixUnitaireBrut
                                                          ?.toString() ??
                                                      '0',
                                                };
                                              }
                                            }
                                          }
                                          return pw.Column(
                                            crossAxisAlignment:
                                                pw.CrossAxisAlignment.start,
                                            children: [
                                              for (
                                                int i = 0;
                                                i < productInfo.keys.length;
                                                i++
                                              )
                                                pw.Container(
                                                  margin:
                                                      const pw.EdgeInsets.only(
                                                        bottom: 4,
                                                      ),
                                                  child: pw.Column(
                                                    crossAxisAlignment: pw
                                                        .CrossAxisAlignment
                                                        .start,
                                                    children: [
                                                      pw.Text(
                                                        '${i + 1}. ${productInfo.keys.elementAt(i)} - ${productInfo[productInfo.keys.elementAt(i)]?['quantite'] ?? 0} unité - ${productInfo[productInfo.keys.elementAt(i)]?['prix_unitaire'] ?? 0} FC/unité',
                                                        style: pw.TextStyle(
                                                          fontSize: 14,
                                                          fontWeight: pw
                                                              .FontWeight
                                                              .bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              pw.SizedBox(height: 8),
                                              pw.Text(
                                                'Total: $quantite article(s) - $prix FC',
                                                style: pw.TextStyle(
                                                  fontSize: 13,
                                                  fontWeight:
                                                      pw.FontWeight.bold,
                                                  color: const PdfColor.fromInt(
                                                    0xFF2E7D32,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          );
                                        }

                                        if (vente['prix_unitaires'] != null &&
                                            vente['prix_unitaires']
                                                .isNotEmpty) {
                                          Map<String, double> prixUnitaires =
                                              vente['prix_unitaires'];

                                          return pw.Column(
                                            crossAxisAlignment:
                                                pw.CrossAxisAlignment.start,
                                            children: [
                                              for (
                                                int i = 0;
                                                i < prixUnitaires.keys.length;
                                                i++
                                              )
                                                pw.Container(
                                                  margin:
                                                      const pw.EdgeInsets.only(
                                                        bottom: 4,
                                                      ),
                                                  child: pw.Column(
                                                    crossAxisAlignment: pw
                                                        .CrossAxisAlignment
                                                        .start,
                                                    children: [
                                                      pw.Text(
                                                        '${i + 1}. ${prixUnitaires.keys.elementAt(i)} - ${prixUnitaires.values.elementAt(i).toStringAsFixed(2)} FC/unité',
                                                        style: pw.TextStyle(
                                                          fontSize: 14,
                                                          fontWeight: pw
                                                              .FontWeight
                                                              .bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              pw.SizedBox(height: 8),
                                              pw.Text(
                                                'Total: ${vente['quantity'] ?? 0} article(s) - ${vente['price'] ?? '0'}',
                                                style: pw.TextStyle(
                                                  fontSize: 13,
                                                  fontWeight:
                                                      pw.FontWeight.bold,
                                                  color: const PdfColor.fromInt(
                                                    0xFF2E7D32,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          );
                                        }

                                        if (details.isEmpty) {
                                          return pw.Text(
                                            'Aucun produit trouvé',
                                            style: pw.TextStyle(
                                              fontSize: 14,
                                              fontWeight: pw.FontWeight.bold,
                                            ),
                                          );
                                        }

                                        return pw.Column(
                                          crossAxisAlignment:
                                              pw.CrossAxisAlignment.start,
                                          children: [
                                            for (
                                              int i = 0;
                                              i < details.length;
                                              i++
                                            )
                                              pw.Container(
                                                margin:
                                                    const pw.EdgeInsets.only(
                                                      bottom: 8,
                                                    ),
                                                child: pw.Column(
                                                  crossAxisAlignment: pw
                                                      .CrossAxisAlignment
                                                      .start,
                                                  children: [
                                                    pw.Text(
                                                      '${i + 1}. ${details[i]['produit']?['nom']?.toString() ?? 'Produit supprimé'}   x${details[i]['quantite']?.toString() ?? '0'}',
                                                      style: pw.TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            pw.FontWeight.bold,
                                                      ),
                                                    ),
                                                    pw.SizedBox(height: 4),
                                                    pw.Text(
                                                      'Prix : ${details[i]['total']?.toString() ?? '0'} FC',
                                                      style: pw.TextStyle(
                                                        fontSize: 13,
                                                        fontWeight:
                                                            pw.FontWeight.bold,
                                                        color:
                                                            const PdfColor.fromInt(
                                                              0xFF2E7D32,
                                                            ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                          ],
                                        );
                                      }

                                      // Default fallback case
                                      return pw.Text(
                                        'Aucun produit disponible',
                                        style: pw.TextStyle(
                                          fontSize: 14,
                                          fontWeight: pw.FontWeight.bold,
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        pw.SizedBox(height: 5),

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
                                vente['price']?.toString() ?? '0 FC',
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
                                'Pour toute question, contactez-nous au: +243 974133780',
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
      // Demander la permission de stockage
      if (Platform.isAndroid) {
        // Essayer plusieurs permissions pour Android 11+
        var status = await Permission.storage.request();

        // Si la permission storage échoue, essayer manage external storage
        if (status != PermissionStatus.granted) {
          status = await Permission.manageExternalStorage.request();
        }

        // Si toujours échoué, essayer photos (fallback)
        if (status != PermissionStatus.granted) {
          status = await Permission.photos.request();
        }

        if (status != PermissionStatus.granted) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Permission de stockage refusée. Statut: $status. Veuillez autoriser dans les paramètres.",
              ),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      // Valider les données de vente
      if (vente.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Données de vente invalides"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Générer le PDF
      final pdf = await _generatePdf(vente);

      List<int> bytes;
      try {
        bytes = await pdf.save();
      } catch (pdfError) {
        rethrow;
      }

      // Obtenir le répertoire de sauvegarde (avec fallback)
      Directory? saveDir;
      String locationType = "";

      if (Platform.isAndroid) {
        // Essayer d'abord le répertoire Downloads
        try {
          saveDir = Directory('/storage/emulated/0/Download');

          bool exists = await saveDir.exists();

          if (!exists) {
            await saveDir.create(recursive: true);
          }
          locationType = "Downloads";
        } catch (e) {
          // Fallback: utiliser le répertoire de l'application
          saveDir = await getApplicationDocumentsDirectory();
          locationType = "Documents de l'application";
        }
      } else if (Platform.isIOS) {
        saveDir = await getApplicationDocumentsDirectory();
        locationType = "Documents";
      } else {
        saveDir = await getDownloadsDirectory();
        locationType = "Downloads";
      }

      if (saveDir == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Impossible d'accéder au répertoire de sauvegarde"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Créer un nom de fichier unique avec debug
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      final venteId = vente['id']?.toString() ?? 'unknown';

      final fileName = 'Facture_Vente_${venteId}_$timestamp.pdf';

      if (saveDir.path == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Erreur: chemin du répertoire de sauvegarde null"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final filePath = '${saveDir.path}/$fileName';

      // Sauvegarder le fichier avec debug
      try {
        final file = File(filePath);
        await file.writeAsBytes(bytes);
      } catch (fileError) {
        rethrow;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Facture sauvegardée avec succès dans $locationType: $fileName",
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: "OK",
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur lors de la sauvegarde de la facture: $e"),
          backgroundColor: Colors.red,
        ),
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

  /* ==============================
        SAVE PDF FACTURE
  ============================== */

  Future<void> _savePdfInvoice(Map<String, dynamic> vente) async {
    try {
      // Demander la permission de stockage
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (status != PermissionStatus.granted) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Permission de stockage requise pour sauvegarder la facture",
              ),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      // Générer le PDF
      final pdf = await _generatePdf(vente);

      // Obtenir le répertoire de téléchargement
      Directory? downloadsDir;
      if (Platform.isAndroid) {
        downloadsDir = Directory('/storage/emulated/0/Download');
      } else if (Platform.isIOS) {
        downloadsDir = await getApplicationDocumentsDirectory();
      } else {
        downloadsDir = await getDownloadsDirectory();
      }

      if (downloadsDir == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Impossible d'accéder au répertoire de sauvegarde"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Créer un nom de fichier unique
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'Facture_Vente_${vente['id']}_$timestamp.pdf';
      final filePath = '${downloadsDir.path}/$fileName';

      // Sauvegarder le fichier
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Facture sauvegardée avec succès dans: $fileName"),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: "OK",
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );

      // Optionnel: Ouvrir le fichier sauvegardé
      // Note: Pour ouvrir automatiquement le fichier, vous pouvez utiliser le package 'open_filex'
      // if (Platform.isAndroid) {
      //   await OpenFilex.open(filePath);
      // }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur lors de la sauvegarde de la facture: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _sharePdfInvoice(Map<String, dynamic> vente) async {
    try {
      final pdf = await _generatePdf(vente);

      // Utiliser file_picker pour choisir où sauvegarder
      String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Sauvegarder la facture PDF',
        fileName:
            'Facture_Vente_${vente['id']}_${DateTime.now().millisecondsSinceEpoch}.pdf',
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (outputPath != null) {
        final file = File(outputPath);
        await file.writeAsBytes(await pdf.save());

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Facture sauvegardée avec succès: ${file.path}"),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur lors du partage de la facture: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// {
//     "message": "Liste des ventes",
//     "ventes": [
//         {
//             "id": 10,
//             "pharmacie_id": 1,
//             "vendeur_id": 1,
//             "client_id": "bedel",
//             "montant_total": "29300.00",
//             "mode_paiement": "cash",
//             "type_vente": "comptant",
//             "created_at": "2026-04-28T11:16:26.000000Z",
//             "updated_at": "2026-04-28T11:16:26.000000Z",
//             "client": null,
//             "vendeur": {
//                 "id": 1,
//                 "name": "Jonathan kabongo",
//                 "email": "jonathan@gmail.com",
//                 "email_verified_at": "2026-04-23T22:08:41.000000Z",
//                 "pharmacie_id": 1,
//                 "role_id": 1,
//                 "actif": true,
//                 "created_at": "2026-04-23T22:08:41.000000Z",
//                 "updated_at": "2026-04-23T22:08:41.000000Z"
//             },
//             "vente_details": [
//                 {
//                     "id": 21,
//                     "vente_id": 10,
//                     "produit_id": 29,
//                     "quantite": 2,
//                     "prix_unitaire": "1000.00",
//                     "total": "2000.00",
//                     "created_at": "2026-04-28T11:16:26.000000Z",
//                     "updated_at": "2026-04-28T11:16:26.000000Z",
//                     "produit": {
//                         "id": 29,
//                         "pharmacie_id": 1,
//                         "categorie_id": 3,
//                         "fournisseur_id": 1,
//                         "nom": "aspirine",
//                         "description": "ras",
//                         "code_barre": "34567u",
//                         "prix_achat": "500.00",
//                         "prix_vente": "1000.00",
//                         "date_expiration": "2028-04-26T00:00:00.000000Z",
//                         "created_at": "2026-04-26T11:41:35.000000Z",
//                         "updated_at": "2026-04-26T11:41:35.000000Z"
//                     }
//                 },
//                 {
//                     "id": 22,
//                     "vente_id": 10,
//                     "produit_id": 28,
//                     "quantite": 2,
//                     "prix_unitaire": "7000.00",
//                     "total": "14000.00",
//                     "created_at": "2026-04-28T11:16:26.000000Z",
//                     "updated_at": "2026-04-28T11:16:26.000000Z",
//                     "produit": {
//                         "id": 28,
//                         "pharmacie_id": 1,
//                         "categorie_id": 2,
//                         "fournisseur_id": 1,
//                         "nom": "doliprane",
//                         "description": "ras",
//                         "code_barre": "4678383",
//                         "prix_achat": "4500.00",
//                         "prix_vente": "7000.00",
//                         "date_expiration": "2027-08-26T00:00:00.000000Z",
//                         "created_at": "2026-04-26T11:19:32.000000Z",
//                         "updated_at": "2026-04-26T11:19:32.000000Z"
//                     }
//                 },
//                 {
//                     "id": 23,
//                     "vente_id": 10,
//                     "produit_id": 26,
//                     "quantite": 2,
//                     "prix_unitaire": "400.00",
//                     "total": "800.00",
//                     "created_at": "2026-04-28T11:16:26.000000Z",
//                     "updated_at": "2026-04-28T11:16:26.000000Z",
//                     "produit": {
//                         "id": 26,
//                         "pharmacie_id": 1,
//                         "categorie_id": 2,
//                         "fournisseur_id": 1,
//                         "nom": "vermocine",
//                         "description": "ras",
//                         "code_barre": null,
//                         "prix_achat": "300.00",
//                         "prix_vente": "400.00",
//                         "date_expiration": "2028-04-24T00:00:00.000000Z",
//                         "created_at": "2026-04-25T16:06:16.000000Z",
//                         "updated_at": "2026-04-25T16:06:16.000000Z"
//                     }
//                 },
//                 {
//                     "id": 24,
//                     "vente_id": 10,
//                     "produit_id": 27,
//                     "quantite": 1,
//                     "prix_unitaire": "500.00",
//                     "total": "500.00",
//                     "created_at": "2026-04-28T11:16:26.000000Z",
//                     "updated_at": "2026-04-28T11:16:26.000000Z",
//                     "produit": {
//                         "id": 27,
//                         "pharmacie_id": 1,
//                         "categorie_id": 3,
//                         "fournisseur_id": 1,
//                         "nom": "sidasyl",
//                         "description": "ras",
//                         "code_barre": null,
//                         "prix_achat": "200.00",
//                         "prix_vente": "500.00",
//                         "date_expiration": "2027-04-24T00:00:00.000000Z",
//                         "created_at": "2026-04-25T16:06:16.000000Z",
//                         "updated_at": "2026-04-25T16:06:16.000000Z"
//                     }
//                 },
//                 {
//                     "id": 25,
//                     "vente_id": 10,
//                     "produit_id": 21,
//                     "quantite": 2,
//                     "prix_unitaire": "6000.00",
//                     "total": "12000.00",
//                     "created_at": "2026-04-28T11:16:26.000000Z",
//                     "updated_at": "2026-04-28T11:16:26.000000Z",
//                     "produit": {
//                         "id": 21,
//                         "pharmacie_id": 1,
//                         "categorie_id": 1,
//                         "fournisseur_id": 1,
//                         "nom": "lasix",
//                         "description": "produit contre l'insuffissance cardiaque",
//                         "code_barre": "2345678",
//                         "prix_achat": "4000.00",
//                         "prix_vente": "6000.00",
//                         "date_expiration": "2026-04-24T00:00:00.000000Z",
//                         "created_at": "2026-04-24T20:48:54.000000Z",
//                         "updated_at": "2026-04-24T20:48:54.000000Z"
//                     }
//                 }
//             ]
//         },
//     ],
// }
