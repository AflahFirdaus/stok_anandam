// MANUAL MODEL - DO NOT USE BUILD_RUNNER FOR THIS FILE
import 'dashboard_response.dart';
import 'paging_response.dart';

class WebResponseDashboardResponse {
  final Object? status;
  final Object? message;
  final DashboardResponse? data;
  final PagingResponse? paging;

  WebResponseDashboardResponse({
    this.status,
    this.message,
    this.data,
    this.paging,
  });

  factory WebResponseDashboardResponse.fromJson(Map<String, dynamic> json) {
    return WebResponseDashboardResponse(
      status: json['status'],
      message: json['message'],
      data: json['data'] == null 
          ? null 
          : DashboardResponse.fromJson(json['data'] as Map<String, dynamic>),
      paging: json['paging'] == null 
          ? null 
          : PagingResponse.fromJson(json['paging'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    final val = <String, dynamic>{};
    void writeNotNull(String key, dynamic value) {
      if (value != null) val[key] = value;
    }
    writeNotNull('status', status);
    writeNotNull('message', message);
    writeNotNull('data', data?.toJson());
    writeNotNull('paging', paging?.toJson());
    return val;
  }

  @override
  String toString() => toJson().toString();
}
