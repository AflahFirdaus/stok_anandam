// MANUAL MODEL - DO NOT USE BUILD_RUNNER FOR THIS FILE

class EmployeeSalesResponse {
  final String? empName;
  final String? empCode;
  final Object? totalSales;

  EmployeeSalesResponse({
    this.empName,
    this.empCode,
    this.totalSales,
  });

  factory EmployeeSalesResponse.fromJson(Map<String, dynamic> json) {
    return EmployeeSalesResponse(
      empName: json['empName'] as String?,
      empCode: json['empCode'] as String?,
      totalSales: json['totalSales'],
    );
  }

  Map<String, dynamic> toJson() {
    final val = <String, dynamic>{};
    void writeNotNull(String key, dynamic value) {
      if (value != null) val[key] = value;
    }
    writeNotNull('empName', empName);
    writeNotNull('empCode', empCode);
    writeNotNull('totalSales', totalSales);
    return val;
  }

  @override
  String toString() => toJson().toString();
}
