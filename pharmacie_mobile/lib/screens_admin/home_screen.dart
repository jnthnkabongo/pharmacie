import 'package:flutter/material.dart';
import 'package:pharmacie_mobile/services/api_service.dart';
import 'package:pharmacie_mobile/screens_admin/vente_page_fixed.dart';

class HomeScreenAdmin extends StatefulWidget {
  const HomeScreenAdmin({super.key});

  @override
  State<HomeScreenAdmin> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreenAdmin> {
  Map<String, dynamic>? _userInfo;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final userInfo = await ApiService.getUserInfo();
    setState(() {
      _userInfo = userInfo;
    });
  }

  Future<void> _logout() async {
    await ApiService.logout();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'PharmaConnect',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
            ),
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (String value) {
              if (value == 'logout') {
                _logout();
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, size: 20),
                      SizedBox(width: 8),
                      Text('Déconnexion'),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: _userInfo == null
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF2E7D32)),
                  SizedBox(height: 20),
                  Text(
                    'Chargement de vos informations...',
                    style: TextStyle(color: Color(0xFF6B7280), fontSize: 16),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadUserInfo,
              color: const Color(0xFF2E7D32),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Carte de bienvenue
                    SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF2E7D32),
                            const Color(0xFF43A047),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2E7D32).withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.person,
                                    color: Colors.white,
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
                                        'Bienvenue Administrateur,',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.9),
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        _userInfo!['name'] ?? 'Utilisateur',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
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
                                'Nom: ${_userInfo!['nom'] ?? 'N/A'}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 22),

                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.1,
                      children: [
                        // GESTION PHARMACIE
                        _buildActionCard(
                          'Pharmacie',
                          Icons.local_hospital,
                          const Color(0xFFE91E63),
                          '1',
                          onTap: () {
                            // TODO: Navigation vers gestion pharmacie
                          },
                        ),
                        // GESTION UTILISATEURS
                        _buildActionCard(
                          'Utilisateurs',
                          Icons.people,
                          const Color(0xFF3F51B5),
                          '12',
                          onTap: () {
                            // TODO: Navigation vers gestion utilisateurs
                          },
                        ),
                        // GESTION PRODUITS
                        _buildActionCard(
                          'Produits',
                          Icons.medication,
                          const Color(0xFF2196F3),
                          '156',
                          onTap: () {
                            // TODO: Navigation vers gestion produits
                          },
                        ),
                        // GESTION STOCK
                        _buildActionCard(
                          'Stock',
                          Icons.inventory_2,
                          const Color(0xFFFF9800),
                          '89',
                          onTap: () {
                            // TODO: Navigation vers gestion stock
                          },
                        ),
                        // APPROVISIONNEMENT
                        _buildActionCard(
                          'Approvisionnement',
                          Icons.local_shipping,
                          const Color(0xFF4CAF50),
                          '24',
                          onTap: () {
                            // TODO: Navigation vers approvisionnement
                          },
                        ),
                        // VENTES
                        _buildActionCard(
                          'Ventes',
                          Icons.point_of_sale,
                          const Color(0xFF9C27B0),
                          '45',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const VentePage(),
                              ),
                            );
                          },
                        ),
                        // CLIENTS
                        _buildActionCard(
                          'Clients',
                          Icons.people_alt,
                          const Color(0xFFA22448),
                          '234',
                          onTap: () {
                            // TODO: Navigation vers gestion clients
                          },
                        ),
                        // RAPPORTS
                        _buildActionCard(
                          'Rapports',
                          Icons.analytics,
                          const Color(0xFF607D8B),
                          '8',
                          onTap: () {
                            // TODO: Navigation vers rapports
                          },
                        ),
                        // AUDIT
                        _buildActionCard(
                          'Audit',
                          Icons.history,
                          const Color(0xFF9E9E9E),
                          '156',
                          onTap: () {
                            // TODO: Navigation vers journal d\'audit
                          },
                        ),
                        // NOTIFICATIONS
                        _buildActionCard(
                          'Notifications',
                          Icons.notifications_active,
                          const Color(0xFFFF5722),
                          '3',
                          onTap: () {
                            // TODO: Navigation vers notifications
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildActionCard(
    String title,
    IconData icon,
    Color color,
    String value, {
    VoidCallback? onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        color: Colors.white,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: color.withOpacity(0.1),
        highlightColor: color.withOpacity(0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 45),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(color: Colors.grey, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
