import 'dart:convert';

class TeacherResponse {
  final String status;
  final String message;
  final TeacherData data;

  TeacherResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory TeacherResponse.fromJson(Map<String, dynamic> json) => TeacherResponse(
    status: json['status'] as String,
    message: json['message'] as String,
    data: TeacherData.fromJson(json['data'] as Map<String, dynamic>),
  );

  Map<String, dynamic> toJson() => {
    'status': status,
    'message': message,
    'data': data.toJson(),
  };

  @override
  String toString() => jsonEncode(toJson());
}

class TeacherData {
  final String userName;
  final String currentTime; // formatted as HH:mm
  final int lessonNumber;
  final String startTime;
  final String endTime;
  final int duration;
  final int breakDuration;
  final String subject;

  TeacherData({
    required this.userName,
    required this.currentTime,
    required this.lessonNumber,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.breakDuration,
    required this.subject,
  });

  factory TeacherData.fromJson(Map<String, dynamic> json) => TeacherData(
    userName: json['userName'] as String,
    currentTime: json['currentTime'] as String,
    lessonNumber: json['lessonNumber'] as int,
    startTime: json['startTime'] as String,
    endTime: json['endTime'] as String,
    duration: json['duration'] as int,
    breakDuration: json['breakDuration'] as int,
    subject: json['subject'] as String,
  );

  Map<String, dynamic> toJson() => {
    'userName': userName,
    'currentTime': currentTime,
    'lessonNumber': lessonNumber,
    'startTime': startTime,
    'endTime': endTime,
    'duration': duration,
    'breakDuration': breakDuration,
    'subject': subject,
  };

  @override
  String toString() => jsonEncode(toJson());
}
