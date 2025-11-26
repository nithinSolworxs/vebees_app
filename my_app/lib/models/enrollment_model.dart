class EnrollmentModel {
  final String enrollId;
  final String uuid;
  final Map<String, dynamic> program;

  EnrollmentModel({
    required this.enrollId,
    required this.uuid,
    required this.program,
  });

  factory EnrollmentModel.fromJson(Map<String, dynamic> json) {
    return EnrollmentModel(
      enrollId: json['enId'].toString(),
      uuid: json['enUuid'],
      program: json['program'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "enId": enrollId,
      "enUuid": uuid,
      "program": program,
    };
  }
}
