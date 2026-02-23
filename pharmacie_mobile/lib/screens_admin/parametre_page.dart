import 'package:flutter/material.dart';
import 'package:pharmacie_mobile/screens_admin/audit_page_improved.dart';
import 'package:pharmacie_mobile/screens_admin/notification_page.dart';
import 'package:pharmacie_mobile/screens_admin/users_page.dart';

class ParametresPage extends StatefulWidget {
  const ParametresPage({super.key});

  @override
  State<ParametresPage> createState() => _ParametresPagePageState();
}

class _ParametresPagePageState extends State<ParametresPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Paramètres'),
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
          // Header avec profil
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [const Color(0xFF2E7D32), const Color(0xFF43A047)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2E7D32).withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 30,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Jonathan Kabongo',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'jnthnkabongo@gmail.com',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.edit,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Section Pharmacie
          SliverToBoxAdapter(
            child: _buildSectionHeader('Pharmacie', Icons.store),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              _buildModernSettingTile(
                'Informations',
                'Nom, adresse, téléphone',
                Icons.info,
                Colors.blue,
                () {
                  // TODO: Modifier infos pharmacie
                },
              ),
            ]),
          ),

          // Section Utilisateurs
          SliverToBoxAdapter(
            child: _buildSectionHeader('Utilisateurs', Icons.people),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              _buildModernSettingTile(
                'Rôles et permissions',
                'Configurer les accès',
                Icons.admin_panel_settings,
                Colors.red,
                () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const UsersPage()),
                  );
                },
              ),
            ]),
          ),

          // Section Système
          SliverToBoxAdapter(
            child: _buildSectionHeader('Système', Icons.computer),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              _buildModernSettingTile(
                'Sauvegarde',
                'Backup et restauration',
                Icons.backup,
                Colors.indigo,
                () {
                  // TODO: Sauvegarde
                },
              ),
              _buildModernSettingTile(
                'Import/Export',
                'Importer et exporter des données',
                Icons.swap_horiz,
                Colors.teal,
                () {
                  // TODO: Import/Export
                },
              ),
              _buildModernSettingTile(
                'Journal d\'audit',
                'Historique des actions',
                Icons.history,
                Colors.amber,
                () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const AuditPage()),
                  );
                },
              ),
            ]),
          ),

          // Section Notifications
          SliverToBoxAdapter(
            child: _buildSectionHeader('Notifications', Icons.notifications),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              _buildModernSettingTile(
                'Notification & Alertes de stock',
                'Configurer les seuils',
                Icons.notifications_active,
                Colors.deepOrange,
                () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const NotificationPage(),
                    ),
                  );
                },
              ),
            ]),
          ),

          // Section À propos
          SliverToBoxAdapter(
            child: _buildSectionHeader('À propos', Icons.info_outline),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              _buildModernSettingTile(
                'Version',
                '1.0.0',
                Icons.info_outline,
                Colors.grey,
                () {
                  // TODO: Informations version
                },
              ),
              _buildModernSettingTile(
                'Aide',
                'Documentation et support',
                Icons.help,
                Colors.cyan,
                () {
                  // TODO: Aide et support
                },
              ),
            ]),
          ),

          // Bouton de déconnexion
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: () {
                  _showLogoutDialog();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Déconnexion',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF2E7D32), size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernSettingTile(
    String title,
    String subtitle,
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
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
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

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.warning, color: Colors.red, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Déconnexion'),
          ],
        ),
        content: const Text(
          'Êtes-vous sûr de vouloir vous déconnecter ?',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.grey[600]),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
  }
}
