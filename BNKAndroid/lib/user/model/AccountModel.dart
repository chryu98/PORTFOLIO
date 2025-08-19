class AccountModel {
  final int acNo;
  final int memberNo;
  final int? cardNo;
  final String accountNumber;
  final String? accountPw;
  final String status;
  final String? createdAt;
  final String? closedAt;

  AccountModel({
    required this.acNo,
    required this.memberNo,
    required this.accountNumber,
    required this.status,
    this.cardNo,
    this.accountPw,
    this.createdAt,
    this.closedAt,
  });

  factory AccountModel.fromJson(Map<String, dynamic> j) {
    return AccountModel(
      acNo: j['acNo'],
      memberNo: j['memberNo'],
      cardNo: j['cardNo'],
      accountNumber: j['accountNumber'],
      accountPw: j['accountPw'],
      status: j['status'],
      createdAt: j['createdAt'],
      closedAt: j['closedAt'],
    );
  }
}
