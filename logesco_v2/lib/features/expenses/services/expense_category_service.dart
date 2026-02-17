import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/config/api_config.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/models/api_response.dart';
import '../models/expense_category.dart';

class ExpenseCategoryService {
  final AuthService _authService;

  ExpenseCategoryService(this._authService);

  /// Récupère toutes les catégories de dépenses
  Future<ApiResponse<List<ExpenseCategory>>> getExpenseCategories() async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return ApiResponse.error(message: 'Token d\'authentification manquant');
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/expense-categories'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final categories = (jsonData['data'] as List).map((item) => ExpenseCategory.fromJson(item as Map<String, dynamic>)).toList();
        return ApiResponse.success(categories);
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse.error(
          message: errorData['message'] ?? 'Erreur lors de la récupération des catégories',
        );
      }
    } catch (e) {
      return ApiResponse.error(message: 'Erreur de connexion: $e');
    }
  }

  /// Crée une nouvelle catégorie de dépense
  Future<ApiResponse<ExpenseCategory>> createExpenseCategory(CreateExpenseCategoryRequest request) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return ApiResponse.error(message: 'Token d\'authentification manquant');
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/expense-categories'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(request.toJson()),
      );

      if (response.statusCode == 201) {
        final jsonData = json.decode(response.body);
        final category = ExpenseCategory.fromJson(jsonData['data']);
        return ApiResponse.success(category);
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse.error(
          message: errorData['message'] ?? 'Erreur lors de la création de la catégorie',
        );
      }
    } catch (e) {
      return ApiResponse.error(message: 'Erreur de connexion: $e');
    }
  }

  /// Met à jour une catégorie de dépense
  Future<ApiResponse<ExpenseCategory>> updateExpenseCategory(int id, UpdateExpenseCategoryRequest request) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return ApiResponse.error(message: 'Token d\'authentification manquant');
      }

      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/expense-categories/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final category = ExpenseCategory.fromJson(jsonData['data']);
        return ApiResponse.success(category);
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse.error(
          message: errorData['message'] ?? 'Erreur lors de la mise à jour de la catégorie',
        );
      }
    } catch (e) {
      return ApiResponse.error(message: 'Erreur de connexion: $e');
    }
  }

  /// Supprime une catégorie de dépense
  Future<ApiResponse<void>> deleteExpenseCategory(int id) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return ApiResponse.error(message: 'Token d\'authentification manquant');
      }

      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/expense-categories/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return ApiResponse.success(null);
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse.error(
          message: errorData['message'] ?? 'Erreur lors de la suppression de la catégorie',
        );
      }
    } catch (e) {
      return ApiResponse.error(message: 'Erreur de connexion: $e');
    }
  }
}
