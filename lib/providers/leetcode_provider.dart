import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/leetcode_stats.dart';
import '../services/leetcode_service.dart';

class LeetCodeProvider extends ChangeNotifier {
  LeetCodeStats? _stats;
  bool _isLoading = false;
  String? _error;
  String _username = '';

  LeetCodeStats? get stats => _stats;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get username => _username;
  bool get hasUsername => _username.isNotEmpty;

  Future<void> loadSavedUsername() async {
    final prefs = await SharedPreferences.getInstance();
    _username = prefs.getString('leetcode_username') ?? '';
    if (_username.isNotEmpty) {
      await fetchStats();
    }
  }

  Future<void> setUsername(String username) async {
    _username = username.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('leetcode_username', _username);
    notifyListeners();
    if (_username.isNotEmpty) {
      await fetchStats();
    }
  }

  Future<void> fetchStats() async {
    if (_username.isEmpty) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await LeetCodeService.fetchStats(_username);
    if (result != null) {
      _stats = result;
      _error = null;
    } else {
      _error = 'Could not fetch data for "$_username"';
    }
    _isLoading = false;
    notifyListeners();
  }
}
