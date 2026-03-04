import 'package:flutter/material.dart';
import 'dart:convert';

import 'package:pharmacie_mobile/services/api_service.dart';

class CategoriePage extends StatefulWidget {
  const CategoriePage({super.key});

  @override
  State<CategoriePage> createState() => _CategoriePageState();
}

class _CategoriePageState extends State<CategoriePage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredCategories = [];
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final responese = await ApiService.getCategories();
      if (responese.statusCode == 200) {
        final data = jsonDecode(responese.body);
        setState(() {
          _categories = List<Map<String, dynamic>>.from(
            data['categories'] ?? [],
          );
          _filteredCategories = _categories;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: ${responese.statusCode}'),
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
    }
  }

  void _filterCategories() {
    setState(() {
      final searchLower = _searchController.text.toLowerCase();
      _filteredCategories = _categories.where((categorie) {
        final nom = categorie['nom']?.toString().toLowerCase() ?? '';
        return searchLower.isEmpty || nom.contains(searchLower);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Catégorie'),
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
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => _filterCategories(),
              decoration: InputDecoration(
                hintText: 'Rechercher une catégorie...',
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
                : _filteredCategories.isEmpty
                ? const Center(child: Text('Aucune catégorie trouvée'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredCategories.length,
                    itemBuilder: (context, index) =>
                        _buildCategoryCard(_filteredCategories[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category) {
    final name = category['nom']?.toString() ?? 'Inconnu';
    final description = category['description']?.toString() ?? '';
    final isActive = category['actif'] == 1 || category['actif'] == true;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isActive ? Colors.green : Colors.grey,
          child: Icon(
            isActive ? Icons.category : Icons.category_outlined,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(description),
            const SizedBox(height: 4),
            Text(
              'Statut: ${isActive ? 'Actif' : 'Inactif'}',
              style: TextStyle(
                color: isActive ? Colors.green : Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () {
            // TODO: Implémenter la modification de catégorie
          },
        ),
      ),
    );
  }
}
