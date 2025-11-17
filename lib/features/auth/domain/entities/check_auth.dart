class CheckAuthStatus {
  CheckAuthStatus({required this.message, this.data});

  String message;
  Data? data;
}

class Data {
  Data({required this.status});

  int status;
}
