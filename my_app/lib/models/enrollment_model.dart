class EnrollmentModel {
  final int enrollId; // maps to enId (bigint)
  final String uuid; // enUuid (user id)
  final Map<String, dynamic> program; // program relation
  final String paymentStatus; // e.g. "Pending", "Paid", "Failed"
  final String? paymentId;
  final String? orderId;
  final String? signature;
  final int? paymentAmount;

  EnrollmentModel({
    required this.enrollId,
    required this.uuid,
    required this.program,
    required this.paymentStatus,
    this.paymentId,
    this.orderId,
    this.signature,
    this.paymentAmount,
  });

  factory EnrollmentModel.fromJson(Map<String, dynamic> json) {
    // parse enId robustly (int or string)
    int parsedId;
    final rawId = json['enId'];
    if (rawId == null) {
      parsedId = 0;
    } else if (rawId is int) {
      parsedId = rawId;
    } else {
      parsedId = int.tryParse(rawId.toString()) ?? 0;
    }

    // program relation might be a Map or null
    Map<String, dynamic> programMap = {};
    if (json['program'] is Map) {
      programMap = Map<String, dynamic>.from(json['program'] as Map);
    } else if (json['program'] is List && (json['program'] as List).isNotEmpty) {
      // sometimes supabase returns relation as a single-item list
      programMap = Map<String, dynamic>.from((json['program'] as List).first);
    }

    return EnrollmentModel(
      enrollId: parsedId,
      uuid: (json['enUuid'] ?? '').toString(),
      program: programMap,
      paymentStatus: (json['paymentStatus'] ?? 'Pending').toString(),
      paymentId: json['paymentId']?.toString(),
      orderId: json['orderId']?.toString(),
      signature: json['signature']?.toString(),
      paymentAmount: json['paymentAmount'] is int
          ? json['paymentAmount'] as int
          : (json['paymentAmount'] != null
              ? int.tryParse(json['paymentAmount'].toString())
              : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enId': enrollId,
      'enUuid': uuid,
      'program': program,
      'paymentStatus': paymentStatus,
      'paymentId': paymentId,
      'orderId': orderId,
      'signature': signature,
      'paymentAmount': paymentAmount,
    };
  }
}
