class ApiResponse<T extends Serializable> {
  final ResponseStatus status;
  final T data;
  final String? message;

  ApiResponse({
    required this.status,
    required this.data,
    this.message,
  });
}

enum ResponseStatus{success, failure}

abstract class Serializable{
  Map<String, dynamic> toJson();
}