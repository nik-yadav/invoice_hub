import 'dart:convert';
import '../../../../core/database/hive_service.dart';
import '../../domain/models/firm_model.dart';

class FirmLocalDataSource {
  static const String _firmsListKey = 'firms_list';

  Future<List<FirmModel>> getFirms() async {
    final rawData = HiveService.firmsBox.get(_firmsListKey);
    if (rawData == null) {
      return [];
    }

    try {
      final List<dynamic> jsonList;
      if (rawData is String) {
        jsonList = jsonDecode(rawData) as List<dynamic>;
      } else if (rawData is List) {
        jsonList = rawData;
      } else {
        return [];
      }

      return jsonList.map((e) => FirmModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveFirms(List<FirmModel> firms) async {
    final List<Map<String, dynamic>> jsonList = firms.map((e) => e.toJson()).toList();
    await HiveService.firmsBox.put(_firmsListKey, jsonEncode(jsonList));
  }
}
