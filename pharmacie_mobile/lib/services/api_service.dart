import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  //static const String baseUrl = 'http://127.0.0.1:8000/api';
  //static const String baseUrl = 'http://10.0.2.2:8000/api';
  static String get baseUrl {
    if (kIsWeb) {
      //Web
      return 'http://localhost:8000/api';
    } else if (Platform.isAndroid) {
      //Mobile Android
      return 'http://10.0.2.2:8000/api';
    } else if (Platform.isIOS) {
      //Mobile Iphone
      return 'http://127.0.0.1:8000/api';
    }
    // Default fallback for other platforms
    return 'http://localhost:8000/api';
  }

  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_info';

  // Connexion
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'token': data['token'],
          'user': data['user'],
          'roleId': data['user']['role_id'],
          'message': data['message'],
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Erreur de connexion',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur réseau: ${e.toString()}'};
    }
  }

  // Inscription
  static Future<Map<String, dynamic>> register(
    Map<String, dynamic> userData,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(userData),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'user': data['user'],
          'message': data['message'],
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Erreur d\'inscription',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur réseau: ${e.toString()}'};
    }
  }

  // Sauvegarder le token
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  // Récupérer le token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Sauvegarder les infos utilisateur
  static Future<void> saveUserInfo(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user));
  }

  // Récupérer les infos utilisateur
  static Future<Map<String, dynamic>?> getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString(_userKey);
    if (userString != null) {
      return jsonDecode(userString);
    }
    return null;
  }

  // Déconnexion
  static Future<bool> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final token = await getToken();
    print('Token: $token');

    if (token == null) return false;
    final response = await http.post(
      Uri.parse('$baseUrl/logout'),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );

    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    return response.statusCode == 200;
  }

  // Vérifier si l'utilisateur est connecté
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }

  // Requête HTTP avec authentification
  static Future<http.Response> authenticatedRequest(
    String endpoint,
    String method, {
    Map<String, dynamic>? body,
  }) async {
    final token = await getToken();

    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    late http.Response response;
    final uri = Uri.parse('$baseUrl$endpoint');

    switch (method.toUpperCase()) {
      case 'GET':
        response = await http.get(uri, headers: headers);
        break;
      case 'POST':
        response = await http.post(
          uri,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        );
        break;
      case 'PUT':
        response = await http.put(
          uri,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        );
        break;
      case 'DELETE':
        response = await http.delete(uri, headers: headers);
        break;
      default:
        throw Exception('Méthode HTTP non supportée: $method');
    }

    return response;
  }

  // Récupérer les stocks
  static Future<http.Response> getStock() async {
    return await authenticatedRequest('/liste-stock', 'GET');
  }

  // Récupérer les produits
  static Future<http.Response> getProduits() async {
    return await authenticatedRequest('/liste-produits', 'GET');
  }

  // Récupérer les ventes
  static Future<http.Response> getVentes() async {
    return await authenticatedRequest('/liste-ventes', 'GET');
  }

  // Récupérer l'historique
  static Future<http.Response> getHistorique() async {
    return await authenticatedRequest('/historique', 'GET');
  }

  // Ajouter une vente
  static Future<http.Response> addVente(Map<String, dynamic> venteData) async {
    return await authenticatedRequest('/add-vente', 'POST', body: venteData);
  }

  // Récupérer les utilisateurs
  static Future<http.Response> getUsers() async {
    return await authenticatedRequest('/users', 'GET');
  }

  // ==================== APPROVISIONNEMENT ====================

  // Récupérer les approvisionnements
  static Future<http.Response> getApprovisionnements() async {
    return await authenticatedRequest('/liste-approvisionnements', 'GET');
  }

  // Récupérer les fournisseurs
  static Future<http.Response> getFournisseurs() async {
    return await authenticatedRequest('/liste-fournisseurs', 'GET');
  }

  // Ajouter un approvisionnement
  static Future<http.Response> addApprovisionnement(
    Map<String, dynamic> approvisionnementData,
  ) async {
    return await authenticatedRequest(
      '/add-approvisionnement',
      'POST',
      body: approvisionnementData,
    );
  }

  // Ajouter un fournisseur
  static Future<http.Response> addFournisseur(
    Map<String, dynamic> fournisseurData,
  ) async {
    return await authenticatedRequest(
      '/add-fournisseur',
      'POST',
      body: fournisseurData,
    );
  }

  // Supprimer un approvisionnement
  static Future<http.Response> deleteApprovisionnement(String id) async {
    final token = await getToken();

    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final uri = Uri.parse('$baseUrl/delete-approvisionnement/$id');
    return await http.delete(uri, headers: headers);
  }
}
