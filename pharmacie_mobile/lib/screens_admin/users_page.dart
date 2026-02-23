import 'package:flutter/material.dart';
import 'package:pharmacie_mobile/services/api_service.dart';
import 'dart:convert';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  bool _isLoading = true;
  String _selectedFilter = 'Tous';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService.getUsers();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _users = List<Map<String, dynamic>>.from(data['users'] ?? []);
          _filteredUsers = _users;
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

  void _filterUsers() {
    setState(() {
      _filteredUsers = _users.where((user) {
        final searchLower = _searchController.text.toLowerCase();
        final name = user['name']?.toString().toLowerCase() ?? '';
        final email = user['email']?.toString().toLowerCase() ?? '';

        bool matchesSearch =
            searchLower.isEmpty ||
            name.contains(searchLower) ||
            email.contains(searchLower);

        bool matchesFilter = _selectedFilter == 'Tous';
        if (_selectedFilter != 'Tous') {
          final roleName = user['role']?['nom']?.toString() ?? 'Utilisateur';
          final isActif = user['actif'] == 1 || user['actif'] == true;

          switch (_selectedFilter) {
            case 'Administrateurs':
              matchesFilter = roleName.toLowerCase().contains('admin');
              break;
            case 'Vendeurs':
              matchesFilter =
                  roleName.toLowerCase().contains('vendeur') ||
                  roleName.toLowerCase().contains('vendeur');
              break;
            case 'Inactifs':
              matchesFilter = !isActif;
              break;
          }
        }

        return matchesSearch && matchesFilter;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Utilisateurs'),
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
      body: CustomScrollView(
        slivers: [
          // Recherche et filtres
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Barre de recherche
                  TextField(
                    controller: _searchController,
                    onChanged: (value) => _filterUsers(),
                    decoration: InputDecoration(
                      hintText: 'Rechercher un utilisateur...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Filtre par rôle
                  Container(
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedFilter,
                        onChanged: (value) {
                          setState(() {
                            _selectedFilter = value!;
                          });
                          _filterUsers();
                        },
                        items:
                            ['Tous', 'Administrateurs', 'Vendeurs', 'Inactifs']
                                .map(
                                  (filter) => DropdownMenuItem(
                                    value: filter,
                                    child: Text(filter),
                                  ),
                                )
                                .toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Liste des utilisateurs
          _isLoading
              ? const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ),
                )
              : _filteredUsers.isEmpty
              ? const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text('Aucun utilisateur trouvé'),
                    ),
                  ),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final user = _filteredUsers[index];
                    final roleName =
                        user['role']?['nom']?.toString() ?? 'Utilisateur';
                    final isActive =
                        user['actif'] == 1 || user['actif'] == true;
                    final status = isActive ? 'Actif' : 'Inactif';

                    IconData icon = Icons.person;
                    Color color = Colors.green;

                    if (!isActive) {
                      icon = Icons.person_off;
                      color = Colors.grey;
                    } else if (roleName.toLowerCase().contains('admin')) {
                      icon = Icons.admin_panel_settings;
                      color = Colors.purple;
                    } else if (roleName.toLowerCase().contains('gérant') ||
                        roleName.toLowerCase().contains('gerant')) {
                      icon = Icons.person_pin;
                      color = Colors.blue;
                    }

                    return _buildUserTile(
                      user['name'] ?? 'Inconnu',
                      user['email'] ?? '',
                      roleName,
                      status,
                      icon,
                      color,
                      isActive,
                      user,
                      () {
                        _showUserDetails(user);
                      },
                    );
                  }, childCount: _filteredUsers.length),
                ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddUserDialog();
        },
        backgroundColor: const Color(0xFF2E7D32),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
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
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTile(
    String name,
    String email,
    String role,
    String status,
    IconData icon,
    Color color,
    bool isActive,
    Map<String, dynamic> user,
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
        border: !isActive
            ? Border.all(color: Colors.grey.withOpacity(0.3))
            : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isActive ? Colors.green : Colors.grey,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                status,
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
              email,
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
            const SizedBox(height: 2),
            Text(
              role,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(Icons.more_vert, size: 14, color: Colors.grey[600]),
          ),
          onSelected: (value) {
            _handleUserAction(value, user);
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'view',
              child: Row(
                children: [
                  const Icon(Icons.visibility, size: 16),
                  const SizedBox(width: 8),
                  Text('Voir profil'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  const Icon(Icons.edit, size: 16),
                  const SizedBox(width: 8),
                  Text('Modifier'),
                ],
              ),
            ),
            if (isActive)
              PopupMenuItem(
                value: 'deactivate',
                child: Row(
                  children: [
                    const Icon(Icons.block, size: 16),
                    const SizedBox(width: 8),
                    Text('Désactiver'),
                  ],
                ),
              )
            else
              PopupMenuItem(
                value: 'activate',
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, size: 16),
                    const SizedBox(width: 8),
                    Text('Activer'),
                  ],
                ),
              ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  const Icon(Icons.delete, size: 16, color: Colors.red),
                  const SizedBox(width: 8),
                  Text('Supprimer', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  void _showUserDetails(Map<String, dynamic> user) {
    final name = user['name'] ?? 'Inconnu';
    final role = user['role']?['nom']?.toString() ?? 'Utilisateur';
    final email = user['email'] ?? '';
    final dateAjout = user['created_at'] != null
        ? user['created_at'].toString().substring(0, 10)
        : '';

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
              child: const Icon(
                Icons.person,
                color: Color(0xFF2E7D32),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Profil de $name', overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Nom:', name),
            _buildDetailRow('Rôle:', role),
            _buildDetailRow('Email:', email),
            _buildDetailRow('Date d\'ajout:', dateAjout),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Modifier l'utilisateur
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
            ),
            child: const Text('Modifier'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: TextStyle(color: Colors.grey[700])),
          ),
        ],
      ),
    );
  }

  void _handleUserAction(String action, Map<String, dynamic> user) {
    final userName = user['name'] ?? 'Inconnu';
    switch (action) {
      case 'view':
        _showUserDetails(user);
        break;
      case 'edit':
        // TODO: Modifier l'utilisateur
        break;
      case 'activate':
        _showActivateDialog(userName);
        break;
      case 'deactivate':
        _showDeactivateDialog(userName);
        break;
      case 'delete':
        _showDeleteDialog(userName);
        break;
    }
  }

  void _showAddUserDialog() {
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
            const Text('Ajouter un utilisateur'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Remplissez les informations du nouvel utilisateur:',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            // TODO: Ajouter les champs du formulaire
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
              // TODO: Ajouter l'utilisateur
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

  void _showActivateDialog(String userName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Activer $userName'),
        content: Text('Êtes-vous sûr de vouloir activer cet utilisateur ?'),
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
              // TODO: Activer l'utilisateur
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Activer'),
          ),
        ],
      ),
    );
  }

  void _showDeactivateDialog(String userName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Désactiver $userName'),
        content: Text('Êtes-vous sûr de vouloir désactiver cet utilisateur ?'),
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
              // TODO: Désactiver l'utilisateur
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Désactiver'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(String userName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning, color: Colors.red),
            const SizedBox(width: 8),
            Text('Supprimer $userName'),
          ],
        ),
        content: const Text(
          'Attention : Cette action est irréversible. Êtes-vous sûr de vouloir supprimer cet utilisateur ?',
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
              // TODO: Supprimer l'utilisateur
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}
