import 'package:image_picker/image_picker.dart';
import 'package:stok_anandam/data/api_new_endpoints.dart';
import 'package:stok_anandam/data/models/memo.dart';
import 'package:stok_anandam/data/models/penjadwalan.dart';
import 'package:stok_anandam/data/models/request_delivery.dart';

class MemoRepository {
  final ApiNewEndpoints _api;

  MemoRepository(this._api);

  Future<String?> createMemo(Map<String, dynamic> request, {bool isPending = false}) async {
    if (isPending) {
      return _api.createPendingMemo(request);
    } else {
      return _api.createMemo(request);
    }
  }

  Future<void> updateMemo(String id, Map<String, dynamic> request) async {
    await _api.updateMemo(id, request);
  }

  Future<MemoDetail?> duplicateRevision(String memoId) async {
    return _api.duplicateRevision(memoId);
  }

  Future<MemoDetail?> duplicateHeader(String memoId) async {
    return _api.duplicateHeader(memoId);
  }

  Future<PenjadwalanResponse?> getTugasDetail(String id) async {
    return _api.getTugasDetail(id);
  }

  Future<void> updateManualTask(String id, Map<String, dynamic> request) async {
    await _api.updateManualTask(id, request);
  }

  Future<void> finishManualTask(String id, {
    required String filePath, 
    required String fileName, 
    required String namaPenerima, 
    String? catatanOperasional
  }) async {
    await _api.finishManualTask(id, 
      filePath: filePath, 
      fileName: fileName, 
      namaPenerima: namaPenerima, 
      catatanOperasional: catatanOperasional
    );
  }

  Future<List<MemoDetail>> getListMemo({MemoStatus? status}) async {
    return _api.getListMemo(status: status?.name);
  }

  Future<Map<String, int>> getMemoCounts() async {
    return _api.getMemoCounts();
  }

  Future<MemoDetail?> getMemoDetail(String id) async {
    return _api.getMemoDetail(id);
  }

  Future<void> approveMemo(String id) async {
    await _api.approvePending(id);
  }

  Future<void> rejectMemo(String id) async {
    await _api.rejectPending(id);
  }

  Future<void> releaseMemo(String id) async {
    await _api.releasePending(id);
  }

  Future<void> continuePendingMemo(String id, Map<String, dynamic> request) async {
    await _api.continuePendingMemo(id, request);
  }

  Future<void> finishPendingMemo(String id) async {
    await _api.finishPendingMemo(id);
  }

  Future<String?> createPenjadwalan(String memoId, Map<String, dynamic> request) async {
    return _api.createPenjadwalan(memoId, request);
  }

  Future<void> finalizeMemo(String id) async {
    await _api.finalizeMemo(id);
  }

  Future<void> updateItemCatatan(int itemId, String catatan) async {
    await _api.updateItemCatatan(itemId, catatan);
  }

  Future<void> finishWarehouseProcess(String id) async {
    await _api.finishWarehouseProcess(id);
  }

  Future<void> finishInvoicingProcess(String id, Map<String, dynamic> request) async {
    await _api.finishInvoicingProcess(id, request);
  }

  Future<void> confirmDeliveryRoute(String id, Map<String, dynamic> request) async {
    await _api.confirmDeliveryRoute(id, request);
  }

  Future<void> confirmPickupRoute(String id, {required String filePath, required String fileName}) async {
    await _api.confirmPickupRoute(id, filePath: filePath, fileName: fileName);
  }

  Future<void> reportPhysicalIssue(String id, String catatan) async {
    await _api.reportPhysicalIssue(id, catatan);
  }

  Future<void> forceComplete(String id, String alasan) async {
    await _api.forceComplete(id, alasan);
  }

  Future<List<UserAccount>> getUsersByRole(String role) async {
    return _api.getUsersByRole(role);
  }

  Future<List<UserAccount>> getAllUsers() async {
    return _api.getAllUsers();
  }

  Future<void> finishTechnicianProcess(String id) async {
    await _api.finishTechnicianProcess(id);
  }

  Future<void> finishDeliveryProcess(String id, {required String filePath, required String fileName, String? catatan}) async {
    await _api.finishDeliveryProcess(id, filePath: filePath, fileName: fileName, catatan: catatan);
  }

  Future<void> updateStatus(String id, MemoStatus targetStatus, String keterangan) async {
    await _api.updateStatus(id, targetStatus.name, keterangan);
  }

  Future<void> updateResi(String id, String resi) async {
    await _api.updateResi(id, resi);
  }

  Future<void> bulkConfirmDeliveryRoute(List<String> ids, Map<String, dynamic> request) async {
    final futures = ids.map((id) => _api.confirmDeliveryRoute(id, request));
    await Future.wait(futures);
  }

  Future<List<PenjadwalanResponse>> getListTugas({
    String tipe = 'SEMUA',
    String status = 'SEMUA',
  }) async {
    return _api.getListTugas(tipe: tipe, status: status);
  }

  Future<void> bulkUpdateStatus(List<String> ids, MemoStatus targetStatus,
      String keterangan,
      {String? nomorJl}) async {
    final futures = ids.map((id) {
      if (targetStatus == MemoStatus.MENUNGGU_NOTA && nomorJl != null && nomorJl.isNotEmpty) {
        // Input JL dari MENUNGGU_NOTA → langsung Buffer Zone
        return _api.finishInvoicingProcess(id, {
          'nomorJl': nomorJl,
          'keteranganLog': keterangan,
        });
      } else {
        return _api.updateStatus(id, targetStatus.name, keterangan);
      }
    });
    await Future.wait(futures);
  }

  Future<void> completeMemo(String id) async {
    await _api.completeMemo(id);
  }

  Future<void> confirmPickupFinal(String id) async {
    await _api.confirmPickupFinal(id);
  }

  Future<void> konfirmasiKirim(String memoId, List<Map<String, dynamic>> items, {required XFile photo}) async {
    await _api.konfirmasiKirim(memoId, items, photo: photo);
  }

  Future<RequestDelivery?> getRequestDeliveryDetail(int id) async {
    return _api.getRequestDeliveryDetail(id);
  }

  Future<void> createBatchDropOff({
    List<String>? memoIds,
    List<int>? requestDeliveryIds,
    required int personelId,
    required DateTime tanggalRencana,
    required String expeditionName,
  }) async {
    await _api.createBatchDropOff(
      memoIds: memoIds,
      requestDeliveryIds: requestDeliveryIds,
      personelId: personelId,
      tanggalRencana: tanggalRencana,
      expeditionName: expeditionName,
    );
  }

  Future<void> bulkMulaiDelivery(List<int> penjadwalanIds) async {
    await _api.bulkMulaiTugas(penjadwalanIds);
  }

  Future<void> bulkSelesaikanDelivery(
    List<int> penjadwalanIds, {
    required String filePath,
    required String fileName,
    required String namaPenerima,
    String? catatanOperasional,
  }) async {
    await _api.bulkSelesaikanTugas(penjadwalanIds,
        filePath: filePath,
        fileName: fileName,
        namaPenerima: namaPenerima,
        catatanOperasional: catatanOperasional);
  }

  Future<void> deleteMemo(String id) async {
    await _api.deleteMemo(id);
  }
}



