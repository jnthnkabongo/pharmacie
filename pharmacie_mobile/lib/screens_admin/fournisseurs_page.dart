import 'package:flutter/material.dart';
import 'package:pharmacie_mobile/screens_admin/ajouter_categorie.dart';
import 'package:pharmacie_mobile/screens_admin/ajouter_fournisseur.dart';
import 'dart:convert';

import 'package:pharmacie_mobile/services/api_service.dart';

class FournisseursPage extends StatefulWidget {
  const FournisseursPage({super.key});

  @override
  State<FournisseursPage> createState() => _FournisseursPageState();
}

class _FournisseursPageState extends State<FournisseursPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredFournisseurs = [];
  List<Map<String, dynamic>> _fournisseurs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFournisseurs();
  }

  Future<void> _loadFournisseurs() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService.getFournisseurs();
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _fournisseurs = List<Map<String, dynamic>>.from(
            data['fournisseurs'] ?? [],
          );
          _filteredFournisseurs = _fournisseurs;
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
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _filterCategories() {
    setState(() {
      final searchLower = _searchController.text.toLowerCase();
      _filteredFournisseurs = _fournisseurs.where((fournisseur) {
        final nom = fournisseur['nom']?.toString().toLowerCase() ?? '';
        return searchLower.isEmpty || nom.contains(searchLower);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Fournisseur'),
        centerTitle: true,
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
        //automaticallyImplyLeading: false,
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
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => _filterCategories(),
              decoration: InputDecoration(
                hintText: 'Rechercher une fournisseur...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),

          SizedBox(height: 16),

          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
                  )
                : _filteredFournisseurs.isEmpty
                ? const Center(
                    child: Text('Aucune fornisseur trouvée'),
                  ) //0839025845 - 0899110656 0897024008
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredFournisseurs.length,
                    itemBuilder: (context, index) =>
                        _buildCategoryCard(_filteredFournisseurs[index]),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AjouterFournisseur()),
          );
        },
        backgroundColor: const Color(0xFF2E7D32),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> fournisseur) {
    final id = fournisseur['id']?.toString() ?? '0';
    final name = fournisseur['nom']?.toString() ?? 'Inconnu';
    final telephone = fournisseur['telephone']?.toString() ?? '';
    final adresse = fournisseur['adresse']?.toString() ?? '';
    final createdAt = fournisseur['created_at']?.toString() ?? '';

    // Formater la date
    String formattedDate = '';
    if (createdAt.isNotEmpty) {
      try {
        final dateTime = DateTime.parse(createdAt);
        formattedDate =
            '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
      } catch (e) {
        formattedDate = createdAt.split('T')[0]; // Fallback
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [Colors.white, const Color(0xFFF5F7FA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(8),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
              ),
              borderRadius: BorderRadius.circular(25),
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 16),
          ),
          title: Text(
            name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (telephone.isNotEmpty)
                Row(
                  children: [
                    SizedBox(height: 4),
                    Icon(Icons.phone, size: 18, color: Colors.grey[500]),
                    SizedBox(width: 10),
                    Text(
                      telephone,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),

              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    'Créé le $formattedDate',
                    style: TextStyle(color: Colors.grey[500], fontSize: 11),
                  ),
                  const SizedBox(width: 5),
                  Icon(Icons.email, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    adresse.isNotEmpty ? adresse : 'Email',
                    style: TextStyle(color: Colors.grey[500], fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
          trailing: PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 18),
                    SizedBox(width: 8),
                    Text('Modifier'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Supprimer', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'edit') {
                // TODO: Implémenter la modification de catégorie
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Modification à implémenter'),
                    backgroundColor: Colors.orange,
                  ),
                );
              } else if (value == 'delete') {
                // TODO: Implémenter la suppression de catégorie
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Suppression à implémenter'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
          ),
        ),
      ),
    );
  }
}
