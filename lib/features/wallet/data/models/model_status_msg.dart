class ModelStatusMsg {
  int? statusCode;
  String? reference;
  String? result;
  String? message;

  ModelStatusMsg({this.statusCode, this.reference, this.result, this.message});

  ModelStatusMsg.fromJson(Map<String, dynamic> json) {
    statusCode = json['status_code'] as int? ?? json['status'] as int?;
    reference = json['reference']?.toString();
    result = json['result']?.toString();
    message = json['message']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status_code'] = statusCode;
    data['reference'] = reference;
    data['result'] = result;
    data['message'] = message;
    return data;
  }
}
