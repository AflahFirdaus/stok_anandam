import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stok_anandam/data/api_new_endpoints.dart';
import 'package:stok_anandam/data/models/memo.dart';
import 'package:stok_anandam/data/models/penjadwalan.dart';
import 'package:stok_anandam/data/repositories/memo_repository.dart';
import 'package:stok_anandam/features/memo/utils/memo_print_utils.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stok_anandam/core/errors/app_errors.dart';
import 'package:stok_anandam/data/models/request_delivery.dart';
import 'package:stok_anandam/injection.dart';
import 'package:stok_anandam/core/network/websocket_service.dart';

// Events
abstract class MemoEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadMemos extends MemoEvent {
  final MemoStatus? status;
  LoadMemos({this.status});
  @override
  List<Object?> get props => [status];
}

class LoadDeliveryTasks extends MemoEvent {
  final String tipe; // PENGIRIMAN, TEKNISI, PENGAMBILAN
  final String status; // MENUNGGU_KONFIRMASI, DIJADWALKAN
  LoadDeliveryTasks({this.tipe = 'SEMUA', this.status = 'SEMUA'});
  @override
  List<Object?> get props => [tipe, status];
}

class LoadMemoDetail extends MemoEvent {
  final String id;
  LoadMemoDetail(this.id);
  @override
  List<Object?> get props => [id];
}

class LoadManualTaskDetail extends MemoEvent {
  final String id;
  LoadManualTaskDetail(this.id);
  @override
  List<Object?> get props => [id];
}

class AssignManualTaskEvent extends MemoEvent {
  final String id;
  final Map<String, dynamic> request;
  AssignManualTaskEvent(this.id, this.request);
  @override
  List<Object?> get props => [id, request];
}

class FinishManualTaskProcessEvent extends MemoEvent {
  final String id;
  final XFile photo;
  final String namaPenerima;
  final String? catatanOperasional;
  FinishManualTaskProcessEvent({
    required this.id, 
    required this.photo, 
    required this.namaPenerima, 
    this.catatanOperasional
  });
  @override
  List<Object?> get props => [id, photo, namaPenerima, catatanOperasional];
}

class CreateMemoEvent extends MemoEvent {
  final Map<String, dynamic> request;
  final bool isPending;
  CreateMemoEvent(this.request, {this.isPending = false});
  @override
  List<Object?> get props => [request, isPending];
}

class ApproveMemoEvent extends MemoEvent {
  final String id;
  ApproveMemoEvent(this.id);
  @override
  List<Object?> get props => [id];
}

class RejectMemoEvent extends MemoEvent {
  final String id;
  RejectMemoEvent(this.id);
  @override
  List<Object?> get props => [id];
}

class ReleaseMemoEvent extends MemoEvent {
  final String id;
  ReleaseMemoEvent(this.id);
  @override
  List<Object?> get props => [id];
}

class FinalizeMemoEvent extends MemoEvent {
  final String id;
  FinalizeMemoEvent(this.id);
  @override
  List<Object?> get props => [id];
}

class ContinuePendingMemoEvent extends MemoEvent {
  final String id;
  final Map<String, dynamic> request;
  ContinuePendingMemoEvent(this.id, this.request);
  @override
  List<Object?> get props => [id, request];
}

class FinishPendingMemoEvent extends MemoEvent {
  final String id;
  FinishPendingMemoEvent(this.id);
  @override
  List<Object?> get props => [id];
}

class UpdateItemCatatanEvent extends MemoEvent {
  final int itemId;
  final String catatan;
  final String memoId;
  UpdateItemCatatanEvent(this.itemId, this.catatan, this.memoId);
  @override
  List<Object?> get props => [itemId, catatan, memoId];
}

class FinishGudangProcessEvent extends MemoEvent {
  final String id;
  FinishGudangProcessEvent(this.id);
  @override
  List<Object?> get props => [id];
}

class FinishInvoicingProcessEvent extends MemoEvent {
  final String id;
  final String nomorJl;
  final String? keteranganLog;
  FinishInvoicingProcessEvent(this.id, {required this.nomorJl, this.keteranganLog});
  @override
  List<Object?> get props => [id, nomorJl, keteranganLog];
}

class ConfirmDeliveryRouteEvent extends MemoEvent {
  final String id;
  final int? driverId;
  final int? teknisiId;
  final int? marketingId;
  final String? tanggalJadwal;
  final String? estimasiWaktu;
  // Optional address components to fix "missing address" issue
  final String? desaKelurahan;
  final String? kecamatan;
  final String? kabupatenKota;
  final String? kodePos;

  ConfirmDeliveryRouteEvent(this.id,
      {this.driverId,
      this.teknisiId,
      this.marketingId,
      this.tanggalJadwal,
      this.estimasiWaktu,
      this.desaKelurahan,
      this.kecamatan,
      this.kabupatenKota,
      this.kodePos});

  @override
  List<Object?> get props => [
        id,
        driverId,
        teknisiId,
        marketingId,
        tanggalJadwal,
        estimasiWaktu,
        desaKelurahan,
        kecamatan,
        kabupatenKota,
        kodePos
      ];
}

class ConfirmPickupRouteEvent extends MemoEvent {
  final String id;
  final XFile photo;
  ConfirmPickupRouteEvent(this.id, this.photo);
  @override
  List<Object?> get props => [id, photo];
}

class ConfirmPickupFinalEvent extends MemoEvent {
  final String id;
  ConfirmPickupFinalEvent(this.id);
  @override
  List<Object?> get props => [id];
}

class ReportPhysicalIssueEvent extends MemoEvent {
  final String id;
  final String catatan;
  ReportPhysicalIssueEvent(this.id, this.catatan);
  @override
  List<Object?> get props => [id, catatan];
}

class ForceCompleteMemoEvent extends MemoEvent {
  final String id;
  final String alasan;
  ForceCompleteMemoEvent(this.id, this.alasan);
  @override
  List<Object?> get props => [id, alasan];
}

class FinishTechnicianProcessEvent extends MemoEvent {
  final String id;
  FinishTechnicianProcessEvent(this.id);
  @override
  List<Object?> get props => [id];
}

class FinishDeliveryProcessEvent extends MemoEvent {
  final String id;
  final XFile photo;
  final String? catatan;
  FinishDeliveryProcessEvent({required this.id, required this.photo, this.catatan});
  @override
  List<Object?> get props => [id, photo, catatan];
}

class CompleteMemoEvent extends MemoEvent {
  final String id;
  CompleteMemoEvent(this.id);
  @override
  List<Object?> get props => [id];
}

class BulkCompleteMemoEvent extends MemoEvent {
  final List<String> ids;
  BulkCompleteMemoEvent(this.ids);
  @override
  List<Object?> get props => [ids];
}

class KonfirmasiKirimEvent extends MemoEvent {
  final String memoId;
  final List<Map<String, dynamic>> items;
  final XFile photo;
  KonfirmasiKirimEvent(this.memoId, this.items, {required this.photo});
  @override
  List<Object?> get props => [memoId, items, photo];
}

class UpdateMemoStatusEvent extends MemoEvent {

  final String id;
  final MemoStatus targetStatus;
  final String keterangan;
  UpdateMemoStatusEvent(this.id, this.targetStatus, this.keterangan);
  @override
  List<Object?> get props => [id, targetStatus, keterangan];
}

class BulkUpdateMemoStatusEvent extends MemoEvent {
  final List<String> ids;
  final MemoStatus targetStatus;
  final String keterangan;
  final String? nomorJl;
  BulkUpdateMemoStatusEvent(this.ids, this.targetStatus, this.keterangan, {this.nomorJl});
  @override
  List<Object?> get props => [ids, targetStatus, keterangan, nomorJl];
}

class UpdateMemoResiEvent extends MemoEvent {
  final String id;
  final String resi;
  UpdateMemoResiEvent(this.id, this.resi);
  @override
  List<Object?> get props => [id, resi];
}

class BulkPrintMemoEvent extends MemoEvent {
  final List<MemoDetail> memos;
  BulkPrintMemoEvent(this.memos);
  @override
  List<Object?> get props => [memos];
}

class BulkConfirmDeliveryRouteEvent extends MemoEvent {
  final List<String> ids;
  final Map<String, dynamic> request;
  BulkConfirmDeliveryRouteEvent(this.ids, this.request);
  @override
  List<Object?> get props => [ids, request];
}

class CreateBatchDropOffEvent extends MemoEvent {
  final List<String>? memoIds;
  final List<int>? requestDeliveryIds;
  final int personelId;
  final DateTime tanggalRencana;
  final String expeditionName;

  CreateBatchDropOffEvent({
    this.memoIds,
    this.requestDeliveryIds,
    required this.personelId,
    required this.tanggalRencana,
    required this.expeditionName,
  });

  @override
  List<Object?> get props => [
        memoIds,
        requestDeliveryIds,
        personelId,
        tanggalRencana,
        expeditionName,
      ];
}

class UpdateMemoEvent extends MemoEvent {
  final String id;
  final Map<String, dynamic> request;
  UpdateMemoEvent(this.id, this.request);
  @override
  List<Object?> get props => [id, request];
}

class BulkMulaiDeliveryEvent extends MemoEvent {
  final List<int> penjadwalanIds;
  BulkMulaiDeliveryEvent(this.penjadwalanIds);
  @override
  List<Object?> get props => [penjadwalanIds];
}

class BulkSelesaikanDeliveryEvent extends MemoEvent {
  final List<int> penjadwalanIds;
  final XFile photo;
  final String namaPenerima;
  final String? catatan;
  BulkSelesaikanDeliveryEvent({
    required this.penjadwalanIds,
    required this.photo,
    required this.namaPenerima,
    this.catatan,
  });
  @override
  List<Object?> get props => [penjadwalanIds, photo, namaPenerima, catatan];
}



// States
abstract class MemoState extends Equatable {
  const MemoState();
  @override
  List<Object?> get props => [];
}

class MemoInitial extends MemoState {}
class MemoLoading extends MemoState {}
class MemoLoaded extends MemoState {
  final List<MemoDetail> memos;
  final List<PenjadwalanResponse>? tasks;
  final Map<String, int>? counts;
  const MemoLoaded(this.memos, {this.tasks, this.counts});
  @override
  List<Object?> get props => [memos, tasks, counts];
}
class MemoDetailLoaded extends MemoState {
  final MemoDetail detail;
  MemoDetailLoaded(this.detail);
  @override
  List<Object?> get props => [detail];
}

class ManualTaskDetailLoaded extends MemoState {
  final PenjadwalanResponse task;
  ManualTaskDetailLoaded(this.task);
  @override
  List<Object?> get props => [task];
}
class MemoOperationSuccess extends MemoState {
  final String message;
  final String? id;
  final MemoStatus? targetStatus;
  MemoOperationSuccess(this.message, {this.id, this.targetStatus});
  @override
  List<Object?> get props => [message, id, targetStatus];
}

class MemoError extends MemoState {
  final String error;
  MemoError(this.error);
  @override
  List<Object?> get props => [error];
}

// Bloc
class MemoBloc extends Bloc<MemoEvent, MemoState> {
  final MemoRepository _repository;
  StreamSubscription? _wsSubscription;
  MemoStatus? _lastStatus;
  String? _lastDetailId;
  String? _lastDeliveryTipe;
  String? _lastDeliveryStatus;

  MemoBloc(this._repository) : super(MemoInitial()) {
    on<LoadMemos>(_onLoadMemos);
    on<LoadMemoDetail>(_onLoadMemoDetail);
    on<LoadDeliveryTasks>(_onLoadDeliveryTasks);
    on<CreateMemoEvent>(_onCreateMemo);
    on<ApproveMemoEvent>(_onApproveMemo);
    on<RejectMemoEvent>(_onRejectMemo);
    on<ReleaseMemoEvent>(_onReleaseMemo);
    on<FinalizeMemoEvent>(_onFinalizeMemo);
    on<UpdateItemCatatanEvent>(_onUpdateItemCatatan);
    on<FinishGudangProcessEvent>(_onFinishGudangProcess);
    on<FinishInvoicingProcessEvent>(_onFinishInvoicingProcess);
    on<ConfirmDeliveryRouteEvent>(_onConfirmDeliveryRoute);
    on<ConfirmPickupRouteEvent>(_onConfirmPickupRoute);
    on<ConfirmPickupFinalEvent>(_onConfirmPickupFinal);
    on<ReportPhysicalIssueEvent>(_onReportPhysicalIssue);
    on<ForceCompleteMemoEvent>(_onForceCompleteMemo);
    on<FinishTechnicianProcessEvent>(_onFinishTechnicianProcess);
    on<FinishDeliveryProcessEvent>(_onFinishDeliveryProcess);
    on<CompleteMemoEvent>(_onCompleteMemo);
    on<UpdateMemoStatusEvent>(_onUpdateMemoStatus);
    on<ContinuePendingMemoEvent>(_onContinuePendingMemo);
    on<FinishPendingMemoEvent>(_onFinishPendingMemo);
    on<BulkCompleteMemoEvent>(_onBulkCompleteMemo);
    on<KonfirmasiKirimEvent>(_onKonfirmasiKirim);
    on<BulkUpdateMemoStatusEvent>(_onBulkUpdateMemoStatus);
    on<BulkPrintMemoEvent>(_onBulkPrintMemo);
    on<BulkConfirmDeliveryRouteEvent>(_onBulkConfirmDeliveryRoute);
    on<LoadManualTaskDetail>(_onLoadManualTaskDetail);
    on<AssignManualTaskEvent>(_onAssignManualTask);
    on<FinishManualTaskProcessEvent>(_onFinishManualTaskProcess);
    on<CreateBatchDropOffEvent>(_onCreateBatchDropOff);
    on<UpdateMemoEvent>(_onUpdateMemo);
    on<UpdateMemoResiEvent>(_onUpdateMemoResi);
    on<BulkMulaiDeliveryEvent>(_onBulkMulaiDelivery);
    on<BulkSelesaikanDeliveryEvent>(_onBulkSelesaikanDelivery);

    // Hubungkan ke WebSocket untuk update otomatis
    final ws = getIt<WebSocketService>();
    _wsSubscription = ws.memoUpdateStream.listen((data) {
      // Lebih fleksibel terhadap format data (string biasa atau JSON)
      if (data.toUpperCase().contains('REFRESH')) {
        if (_lastDetailId != null) {
          add(LoadMemoDetail(_lastDetailId!));
        } else if (_lastDeliveryTipe != null) {
          // Refresh Delivery/Technician tasks if in that mode
          add(LoadDeliveryTasks(
            tipe: _lastDeliveryTipe!,
            status: _lastDeliveryStatus ?? 'SEMUA',
          ));
        } else {
          // Selalu muat ulang daftar dan hitungan (counts) jika sedang di mode list
          add(LoadMemos(status: _lastStatus));
        }
      }
    });
  }

  @override
  Future<void> close() {
    _wsSubscription?.cancel();
    return super.close();
  }

  Future<void> _onLoadManualTaskDetail(LoadManualTaskDetail event, Emitter<MemoState> emit) async {
    emit(MemoLoading());
    try {
      if (event.id.startsWith('req-')) {
        final reqId = int.parse(event.id.replaceFirst('req-', ''));
        final req = await _repository.getRequestDeliveryDetail(reqId);
        if (req != null) {
          if (req.penjadwalanId != null) {
            final task = await _repository.getTugasDetail(req.penjadwalanId.toString());
            if (task != null) {
              emit(ManualTaskDetailLoaded(task));
              return;
            }
          }
          emit(ManualTaskDetailLoaded(_mapRequestToTask(req)));
        } else {
          emit(MemoError("Request Delivery tidak ditemukan"));
        }
      } else {
        final task = await _repository.getTugasDetail(event.id);
        if (task != null) {
          emit(ManualTaskDetailLoaded(task));
        } else {
          emit(MemoError("Tugas tidak ditemukan"));
        }
      }
    } catch (e) {
      emit(MemoError(AppErrors.userMessageFromException(e)));
    }
  }

  PenjadwalanResponse _mapRequestToTask(RequestDelivery req) {
    return PenjadwalanResponse(
      id: req.penjadwalanId,
      requestDeliveryId: req.id,
      nomorRequest: req.nomorRequest,
      tipeTugas: 'PENGIRIMAN',
      statusJadwal: _mapReqStatusToJadwalStatus(req.status),
      alamatLengkap: req.alamatLengkap,
      alamatMaps: req.alamatMaps,
      catatan: req.keterangan,
      manualCustomerName: req.receiverName,
      manualNoHp: req.receiverPhone,
      marketingName: req.creatorName,
    );
  }

  String _mapReqStatusToJadwalStatus(RequestDeliveryStatus status) {
    switch (status) {
      case RequestDeliveryStatus.MENUNGGU_GUDANG:
        return 'MENUNGGU_KONFIRMASI';
      case RequestDeliveryStatus.MENUNGGU_PENGIRIMAN:
        return 'MENUNGGU_KONFIRMASI';
      case RequestDeliveryStatus.DALAM_PENGIRIMAN:
        return 'DALAM_PENGIRIMAN';
      case RequestDeliveryStatus.SELESAI:
        return 'SELESAI';
      case RequestDeliveryStatus.DIBATALKAN:
        return 'BATAL';
      default:
        return 'MENUNGGU_KONFIRMASI';
    }
  }

  Future<void> _onAssignManualTask(AssignManualTaskEvent event, Emitter<MemoState> emit) async {
    emit(MemoLoading());
    try {
      if (event.id.startsWith('req-')) {
        int rdId = int.parse(event.id.replaceAll('req-', ''));
        String tgl = event.request['tanggalJadwal'].toString();
        // Convert 'dd-MM-yyyy' to 'yyyy-MM-dd' or try pass it
        String formattedDate = tgl;
        try {
          final parts = tgl.split('-');
          if (parts.length == 3 && parts[2].length == 4) {
             formattedDate = "${parts[2]}-${parts[1]}-${parts[0]}"; // yyyy-MM-dd
          }
        } catch (_) {}

        await getIt<ApiNewEndpoints>().createBulkPenjadwalan(
           requestDeliveryIds: [rdId],
           personelId: event.request['personelId'],
           tanggalRencana: DateTime.parse(formattedDate),
        );
      } else {
        await _repository.updateManualTask(event.id, event.request);
      }
      emit(MemoOperationSuccess("Penugasan Manual Task Berhasil Diperbarui"));
      add(LoadManualTaskDetail(event.id));
    } catch (e) {
      emit(MemoError(AppErrors.userMessageFromException(e)));
    }
  }

  Future<void> _onFinishManualTaskProcess(FinishManualTaskProcessEvent event, Emitter<MemoState> emit) async {
    emit(MemoLoading());
    try {
      await _repository.finishManualTask(
        event.id,
        filePath: event.photo.path,
        fileName: event.photo.name,
        namaPenerima: event.namaPenerima,
        catatanOperasional: event.catatanOperasional,
      );
      emit(MemoOperationSuccess("Pengiriman Manual Task Selesai"));
      add(LoadManualTaskDetail(event.id));
    } catch (e) {
      emit(MemoError(AppErrors.userMessageFromException(e)));
    }
  }

  Future<void> _onLoadMemos(LoadMemos event, Emitter<MemoState> emitter) async {
    _lastStatus = event.status;
    _lastDetailId = null;
    emitter(MemoLoading());
    try {
      // Fetch only memos and counts
      final results = await Future.wait([
        _repository.getListMemo(status: event.status),
        _repository.getMemoCounts(),
      ]);

      final memos = results[0] as List<MemoDetail>;
      final counts = results[1] as Map<String, int>;

      emitter(MemoLoaded(memos, tasks: const [], counts: counts));
    } catch (e) {
      emitter(MemoError(AppErrors.userMessageFromException(e)));
    }
  }

  Future<void> _onLoadDeliveryTasks(
      LoadDeliveryTasks event, Emitter<MemoState> emit) async {
    _lastDeliveryTipe = event.tipe;
    _lastDeliveryStatus = event.status;
    _lastDetailId = null;
    emit(MemoLoading());
    try {
      // Identify memo status equivalent for the given task status filter
      // Set to null to fetch all memos the user has access to,
      // and rely on the UI (PengirimanPage) to properly map and filter 
      // complex combined statuses like BUFFER_ZONE and MENUNGGU_PENGIRIMAN
      MemoStatus? memoStatusFilter = null;

      // Fetch both to ensure all deliverable items are visible to admin/gudang
      final results = await Future.wait([
        _repository.getListMemo(status: memoStatusFilter),
        _repository.getListTugas(tipe: event.tipe, status: event.status),
        _repository.getMemoCounts(),
      ]);

      final memos = results[0] as List<MemoDetail>;
      final tasks = results[1] as List<PenjadwalanResponse>;
      final counts = results[2] as Map<String, int>;

      emit(MemoLoaded(memos, tasks: tasks, counts: counts));
    } catch (e) {
      emit(MemoError(AppErrors.userMessageFromException(e)));
    }
  }

  Future<void> _onLoadMemoDetail(LoadMemoDetail event, Emitter<MemoState> emit) async {
    _lastDetailId = event.id;
    emit(MemoLoading());
    try {
      final detail = await _repository.getMemoDetail(event.id);
      if (detail != null) {
        emit(MemoDetailLoaded(detail));
      } else {
        emit(MemoError("Memo tidak ditemukan"));
      }
    } catch (e) {
      emit(MemoError(AppErrors.userMessageFromException(e)));
    }
  }

  Future<void> _onCreateMemo(CreateMemoEvent event, Emitter<MemoState> emit) async {
    emit(MemoLoading());
    try {
      final id = await _repository.createMemo(event.request, isPending: event.isPending);
      emit(MemoOperationSuccess("Memo berhasil dibuat", id: id));
    } catch (e) {

      emit(MemoError(AppErrors.userMessageFromException(e)));
    }
  }

  Future<void> _onApproveMemo(ApproveMemoEvent event, Emitter<MemoState> emit) async {
    emit(MemoLoading());
    try {
      await _repository.approveMemo(event.id);
      emit(MemoOperationSuccess("Memo berhasil disetujui"));
      add(LoadMemoDetail(event.id)); // Refresh detail
    } catch (e) {
      emit(MemoError(AppErrors.userMessageFromException(e)));
    }
  }

  Future<void> _onRejectMemo(RejectMemoEvent event, Emitter<MemoState> emit) async {
    emit(MemoLoading());
    try {
      await _repository.rejectMemo(event.id);
      emit(MemoOperationSuccess("Memo berhasil ditolak"));
      add(LoadMemoDetail(event.id)); // Refresh detail
    } catch (e) {
      emit(MemoError(AppErrors.userMessageFromException(e)));
    }
  }

  Future<void> _onReleaseMemo(ReleaseMemoEvent event, Emitter<MemoState> emit) async {
    emit(MemoLoading());
    try {
      await _repository.releaseMemo(event.id);
      emit(MemoOperationSuccess("Stok booking berhasil dilepaskan"));
      add(LoadMemoDetail(event.id)); // Refresh detail
    } catch (e) {
      emit(MemoError(AppErrors.userMessageFromException(e)));
    }
  }

  Future<void> _onFinalizeMemo(FinalizeMemoEvent event, Emitter<MemoState> emit) async {
    emit(MemoLoading());
    try {
      await _repository.finalizeMemo(event.id);
      emit(MemoOperationSuccess("Memo berhasil dikirim ke Gudang"));
      add(LoadMemoDetail(event.id)); // Refresh detail
    } catch (e) {
      emit(MemoError(AppErrors.userMessageFromException(e)));
    }
  }

  Future<void> _onUpdateItemCatatan(UpdateItemCatatanEvent event, Emitter<MemoState> emit) async {
    emit(MemoLoading());
    try {
      await _repository.updateItemCatatan(event.itemId, event.catatan);
      emit(MemoOperationSuccess("Catatan item berhasil diperbarui"));
      add(LoadMemoDetail(event.memoId)); // Refresh detail
    } catch (e) {
      emit(MemoError(AppErrors.userMessageFromException(e)));
    }
  }

  Future<void> _onFinishGudangProcess(FinishGudangProcessEvent event, Emitter<MemoState> emit) async {
    emit(MemoLoading());
    try {
      await _repository.finishWarehouseProcess(event.id);
      emit(MemoOperationSuccess("Proses Picking Selesai (Menunggu Nota)"));
      add(LoadMemoDetail(event.id)); // Refresh detail
    } catch (e) {
      emit(MemoError(AppErrors.userMessageFromException(e)));
    }
  }

  Future<void> _onFinishInvoicingProcess(FinishInvoicingProcessEvent event, Emitter<MemoState> emit) async {
    emit(MemoLoading());
    try {
      final request = {
        'nomorJl': event.nomorJl,
        'keteranganLog': event.keteranganLog,
      };
      await _repository.finishInvoicingProcess(event.id, request);
      emit(MemoOperationSuccess("Proses Nota/Invoice Selesai (${event.nomorJl})"));
      add(LoadMemoDetail(event.id)); // Refresh detail
    } catch (e) {
      emit(MemoError(AppErrors.userMessageFromException(e)));
    }
  }

  Future<void> _onConfirmDeliveryRoute(ConfirmDeliveryRouteEvent event, Emitter<MemoState> emit) async {
    emit(MemoLoading());
    try {
      // Confirm the delivery route / schedule
      final Map<String, dynamic> request = {
        'driverId': event.driverId,
        'teknisiId': event.teknisiId,
        'marketingId': event.marketingId,
        'tanggalJadwal': event.tanggalJadwal,
        'estimasiWaktu': event.estimasiWaktu,
      };
      await _repository.confirmDeliveryRoute(event.id, request);
      emit(MemoOperationSuccess("Jalur Pengiriman Berhasil Dipilih"));
      add(LoadMemoDetail(event.id));
    } catch (e) {
      emit(MemoError(AppErrors.userMessageFromException(e)));
    }
  }

  Future<void> _onConfirmPickupRoute(ConfirmPickupRouteEvent event, Emitter<MemoState> emit) async {
    emit(MemoLoading());
    try {
      await _repository.confirmPickupRoute(
        event.id,
        filePath: event.photo.path,
        fileName: event.photo.name,
      );
      emit(MemoOperationSuccess("Serah Terima Pickup Selesai"));
      add(LoadMemoDetail(event.id));
    } catch (e) {
      emit(MemoError(AppErrors.userMessageFromException(e)));
    }
  }

  Future<void> _onConfirmPickupFinal(
      ConfirmPickupFinalEvent event, Emitter<MemoState> emit) async {
    emit(MemoLoading());
    try {
      await _repository.confirmPickupFinal(event.id);
      emit(MemoOperationSuccess("Pickup berhasil dikonfirmasi selesai"));
      add(LoadMemoDetail(event.id));
    } catch (e) {
      emit(MemoError(e.toString()));
    }
  }

  Future<void> _onReportPhysicalIssue(ReportPhysicalIssueEvent event, Emitter<MemoState> emit) async {
    emit(MemoLoading());
    try {
      await _repository.reportPhysicalIssue(event.id, event.catatan);
      emit(MemoOperationSuccess("Kendala fisik berhasil dilaporkan"));
      add(LoadMemoDetail(event.id));
    } catch (e) {
      emit(MemoError(AppErrors.userMessageFromException(e)));
    }
  }

  Future<void> _onForceCompleteMemo(ForceCompleteMemoEvent event, Emitter<MemoState> emit) async {
    emit(MemoLoading());
    try {
      await _repository.forceComplete(event.id, event.alasan);
      emit(MemoOperationSuccess("Memo diselesaikan secara paksa (Audit)"));
      add(LoadMemoDetail(event.id));
    } catch (e) {
      emit(MemoError(AppErrors.userMessageFromException(e)));
    }
  }

  Future<void> _onFinishTechnicianProcess(FinishTechnicianProcessEvent event, Emitter<MemoState> emit) async {
    emit(MemoLoading());
    try {
      await _repository.finishTechnicianProcess(event.id);
      emit(MemoOperationSuccess("Proses Teknisi Selesai (Buffer Zone)"));
      add(LoadMemoDetail(event.id)); // Refresh detail
    } catch (e) {
      emit(MemoError(AppErrors.userMessageFromException(e)));
    }
  }

  Future<void> _onFinishDeliveryProcess(FinishDeliveryProcessEvent event, Emitter<MemoState> emit) async {
    emit(MemoLoading());
    try {
      await _repository.finishDeliveryProcess(
        event.id,
        filePath: event.photo.path,
        fileName: event.photo.name,
        catatan: event.catatan,
      );
      emit(MemoOperationSuccess("Pengiriman Selesai (Diterima User)"));
      add(LoadMemoDetail(event.id)); // Refresh detail
    } catch (e) {
      emit(MemoError(AppErrors.userMessageFromException(e)));
    }
  }

  Future<void> _onUpdateMemoStatus(UpdateMemoStatusEvent event, Emitter<MemoState> emit) async {

    emit(MemoLoading());
    try {
      await _repository.updateStatus(event.id, event.targetStatus, event.keterangan);
      emit(MemoOperationSuccess("Status memo berhasil diperbarui"));
      add(LoadMemoDetail(event.id)); // Refresh detail
    } catch (e) {
      emit(MemoError(AppErrors.userMessageFromException(e)));
    }
  }

  Future<void> _onCompleteMemo(CompleteMemoEvent event, Emitter<MemoState> emit) async {
    emit(MemoLoading());
    try {
      await _repository.completeMemo(event.id);
      emit(MemoOperationSuccess("Memo berhasil diselesaikan"));
      add(LoadMemoDetail(event.id)); // Refresh detail
    } catch (e) {
      emit(MemoError(AppErrors.userMessageFromException(e)));
    }
  }

  Future<void> _onBulkCompleteMemo(BulkCompleteMemoEvent event, Emitter<MemoState> emit) async {
    emit(MemoLoading());
    try {
      for (final id in event.ids) {
        await _repository.completeMemo(id);
      }
      emit(MemoOperationSuccess("${event.ids.length} memo berhasil diselesaikan"));
      add(LoadMemos()); // Refresh list
    } catch (e) {
      emit(MemoError(AppErrors.userMessageFromException(e)));
    }
  }

  Future<void> _onContinuePendingMemo(ContinuePendingMemoEvent event, Emitter<MemoState> emit) async {
    emit(MemoLoading());
    try {
      await _repository.continuePendingMemo(event.id, event.request);
      emit(MemoOperationSuccess("Memo berhasil dilanjutkan", id: event.id));
      add(LoadMemoDetail(event.id)); // Refresh detail
    } catch (e) {
      emit(MemoError(AppErrors.userMessageFromException(e)));
    }
  }

  Future<void> _onFinishPendingMemo(FinishPendingMemoEvent event, Emitter<MemoState> emit) async {
    emit(MemoLoading());
    try {
      await _repository.finishPendingMemo(event.id);
      emit(MemoOperationSuccess("Booking berhasil diselesaikan"));
      add(LoadMemoDetail(event.id)); // Refresh detail
    } catch (e) {
      emit(MemoError(AppErrors.userMessageFromException(e)));
    }
  }

  Future<void> _onKonfirmasiKirim(KonfirmasiKirimEvent event, Emitter<MemoState> emit) async {
    emit(MemoLoading());
    try {
      await _repository.konfirmasiKirim(event.memoId, event.items, photo: event.photo);
      emit(MemoOperationSuccess("Konfirmasi pengiriman berhasil"));
      add(LoadMemoDetail(event.memoId)); // Refresh detail
    } catch (e) {
      emit(MemoError(AppErrors.userMessageFromException(e)));
    }
  }

  Future<void> _onBulkUpdateMemoStatus(BulkUpdateMemoStatusEvent event, Emitter<MemoState> emit) async {
    emit(MemoLoading());
    try {
      await _repository.bulkUpdateStatus(event.ids, event.targetStatus, event.keterangan, nomorJl: event.nomorJl);
      emit(MemoOperationSuccess(
        "Status ${event.ids.length} memo berhasil diperbarui ke ${event.targetStatus.label}",
        targetStatus: event.targetStatus,
      ));
      add(LoadMemos(status: event.targetStatus)); // Refresh list with new status
    } catch (e) {
      emit(MemoError(AppErrors.userMessageFromException(e)));
    }
  }

  Future<void> _onBulkPrintMemo(BulkPrintMemoEvent event, Emitter<MemoState> emit) async {
    try {
      await MemoPrintUtils.printMemoLabels(event.memos);
    } catch (e) {
      emit(MemoError("Gagal mencetak: ${AppErrors.userMessageFromException(e)}"));
    }
  }

  Future<void> _onBulkConfirmDeliveryRoute(BulkConfirmDeliveryRouteEvent event, Emitter<MemoState> emit) async {
    emit(MemoLoading());
    try {
      await _repository.bulkConfirmDeliveryRoute(event.ids, event.request);
      emit(MemoOperationSuccess("Penugasan ${event.ids.length} memo berhasil diperbarui"));
      add(LoadMemos()); // Refresh list
    } catch (e) {
      emit(MemoError(AppErrors.userMessageFromException(e)));
    }
  }

  Future<void> _onCreateBatchDropOff(CreateBatchDropOffEvent event, Emitter<MemoState> emit) async {
    emit(MemoLoading());
    try {
      await _repository.createBatchDropOff(
        memoIds: event.memoIds,
        requestDeliveryIds: event.requestDeliveryIds,
        personelId: event.personelId,
        tanggalRencana: event.tanggalRencana,
        expeditionName: event.expeditionName,
      );
      emit(MemoOperationSuccess("Batch Drop-off Ekspedisi Berhasil Dibuat"));
      add(LoadMemos()); // Refresh list
    } catch (e) {
      emit(MemoError(AppErrors.userMessageFromException(e)));
    }
  }

  Future<void> _onUpdateMemo(UpdateMemoEvent event, Emitter<MemoState> emit) async {
    emit(MemoLoading());
    try {
      await _repository.updateMemo(event.id, event.request);
      emit(MemoOperationSuccess("Memo Berhasil Diperbarui", id: event.id));
      add(LoadMemoDetail(event.id)); // Refresh detail
      add(LoadMemos()); // Refresh list to ensure draft list is updated
    } catch (e) {
      emit(MemoError(AppErrors.userMessageFromException(e)));
    }
  }

  Future<void> _onUpdateMemoResi(UpdateMemoResiEvent event, Emitter<MemoState> emit) async {
    emit(MemoLoading());
    try {
      await _repository.updateResi(event.id, event.resi);
      emit(MemoOperationSuccess("Nomor Resi Berhasil Diperbarui"));
      add(LoadMemoDetail(event.id)); // Refresh detail
    } catch (e) {
      emit(MemoError(AppErrors.userMessageFromException(e)));
    }
  }

  Future<void> _onBulkMulaiDelivery(BulkMulaiDeliveryEvent event, Emitter<MemoState> emit) async {
    emit(MemoLoading());
    try {
      await _repository.bulkMulaiDelivery(event.penjadwalanIds);
      emit(MemoOperationSuccess("Mulai pengiriman massal berhasil"));
      add(LoadMemos());
    } catch (e) {
      emit(MemoError(AppErrors.userMessageFromException(e)));
    }
  }

  Future<void> _onBulkSelesaikanDelivery(BulkSelesaikanDeliveryEvent event, Emitter<MemoState> emit) async {
    emit(MemoLoading());
    try {
      await _repository.bulkSelesaikanDelivery(
        event.penjadwalanIds,
        filePath: event.photo.path,
        fileName: event.photo.name,
        namaPenerima: event.namaPenerima,
        catatanOperasional: event.catatan,
      );
      emit(MemoOperationSuccess("Pengiriman massal berhasil diselesaikan"));
      add(LoadMemos());
    } catch (e) {
      emit(MemoError(AppErrors.userMessageFromException(e)));
    }
  }
}



