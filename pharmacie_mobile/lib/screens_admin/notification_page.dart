import 'package:flutter/material.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
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
      body: CustomScrollView(
        slivers: [
          // Statistiques des alertes
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildAlertCard('Critiques', '3', Colors.red),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildAlertCard('Urgentes', '7', Colors.orange),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: _buildAlertCard('Info', '12', Colors.blue)),
                ],
              ),
            ),
          ),

          // Section Alertes de stock
          SliverToBoxAdapter(
            child: _buildSectionHeader('Alertes de Stock', Icons.warning),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              _buildStockAlertTile(
                'Paracétamol 500mg',
                'Stock critique: 5 unités restantes',
                'Seuil: 20 unités',
                Icons.error,
                Colors.red,
                'CRITIQUE',
                () {
                  // TODO: Action critique
                },
              ),
              _buildStockAlertTile(
                'Amoxicilline 1g',
                'Stock faible: 15 unités restantes',
                'Seuil: 25 unités',
                Icons.warning,
                Colors.orange,
                'URGENT',
                () {
                  // TODO: Action urgente
                },
              ),
              _buildStockAlertTile(
                'Ibuprofène 400mg',
                'Stock bas: 28 unités restantes',
                'Seuil: 30 unités',
                Icons.info,
                Colors.blue,
                'INFO',
                () {
                  // TODO: Action info
                },
              ),
            ]),
          ),

          // Section Notifications système
          SliverToBoxAdapter(
            child: _buildSectionHeader(
              'Notifications Système',
              Icons.notifications,
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              _buildNotificationTile(
                'Nouvelle vente enregistrée',
                'Vente #1234 - Client: Jean Dupont',
                'Il y a 5 minutes',
                Icons.receipt,
                Colors.green,
                () {
                  // TODO: Voir détails vente
                },
              ),
              _buildNotificationTile(
                'Produit ajouté avec succès',
                'Vitamine C ajoutée au catalogue',
                'Il y a 1 heure',
                Icons.add_circle,
                Colors.blue,
                () {
                  // TODO: Voir produit
                },
              ),
              _buildNotificationTile(
                'Rappel: Inventaire programmé',
                'Inventaire mensuel prévu demain',
                'Il y a 2 heures',
                Icons.schedule,
                Colors.purple,
                () {
                  // TODO: Voir calendrier
                },
              ),
            ]),
          ),

          // Section Rappels
          SliverToBoxAdapter(
            child: _buildSectionHeader('Rappels', Icons.alarm),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              _buildReminderTile(
                'Commande fournisseur',
                'Passer commande pour Fournisseur A',
                'Aujourd\'hui, 14:00',
                Icons.shopping_cart,
                Colors.orange,
                true,
                () {
                  // TODO: Passer commande
                },
              ),
              _buildReminderTile(
                'Vérifier péremptions',
                'Produits expirant ce mois',
                'Demain, 09:00',
                Icons.date_range,
                Colors.red,
                false,
                () {
                  // TODO: Voir péremptions
                },
              ),
              _buildReminderTile(
                'Backup hebdomadaire',
                'Sauvegarder les données',
                'Vendredi, 18:00',
                Icons.backup,
                Colors.blue,
                false,
                () {
                  // TODO: Lancer backup
                },
              ),
            ]),
          ),

          // Section Configuration
          SliverToBoxAdapter(
            child: _buildSectionHeader(
              'Configuration des Alertes',
              Icons.settings,
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              _buildConfigTile(
                'Seuils de stock',
                'Configurer les alertes automatiques',
                Icons.tune,
                Colors.indigo,
                () {
                  // TODO: Configurer seuils
                },
              ),
              _buildConfigTile(
                'Fréquence des notifications',
                'Choisir quand recevoir les alertes',
                Icons.timer,
                Colors.teal,
                () {
                  // TODO: Configurer fréquence
                },
              ),
              _buildConfigTile(
                'Types de notifications',
                'Sélectionner les alertes à recevoir',
                Icons.filter_list,
                Colors.purple,
                () {
                  // TODO: Configurer types
                },
              ),
            ]),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddNotificationDialog();
        },
        backgroundColor: const Color(0xFF2E7D32),
        child: const Icon(Icons.add),
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

  Widget _buildStockAlertTile(
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

  Widget _buildReminderTile(
    String title,
    String subtitle,
    String time,
    IconData icon,
    Color color,
    bool isToday,
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
        border: isToday ? Border.all(color: color.withOpacity(0.3)) : null,
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
            if (isToday)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'AUJOURD\'HUI',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
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
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
            const SizedBox(height: 2),
            Text(
              time,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w600,
              ),
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

  Widget _buildConfigTile(
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
