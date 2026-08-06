import '../models/firm_model.dart';

abstract class FirmRepository {
  Future<List<FirmModel>> getFirms();
  Future<FirmModel?> getFirmById(String id);
  Future<void> addFirm(FirmModel firm);
  Future<void> updateFirm(FirmModel firm);
  Future<void> deleteFirm(String id);
}
