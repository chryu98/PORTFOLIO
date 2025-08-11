class Branch {
  final int branchNo;
  final String branchName;
  final String branchAddress;
  final String branchTel;
  final double latitude;
  final double longitude;

  Branch({
    required this.branchNo,
    required this.branchName,
    required this.branchAddress,
    required this.branchTel,
    required this.latitude,
    required this.longitude,
  });

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      branchNo: json['branchNo'],
      branchName: json['branchName'],
      branchAddress: json['branchAddress'],
      branchTel: json['branchTel'],
      latitude: json['latitude'],
      longitude: json['longitude'],
    );
  }
}
