class CardModel {
  final int cardNo;
  final String cardName;
  final String cardUrl;
  final String? popularImgUrl;
  final int viewCount;
  final String? cardType;
  final String? cardSlogan;
  final String? service;
  final String? sService;
  final String? issuedTo;
  final String? benefits;
  final String? scBenefits;
  final int? annualFee;
  final int? scAnnualFee;
  final String cardBrand;
  final String? notice;

  CardModel({
    required this.cardNo,
    required this.cardName,
    required this.cardUrl,
    this.popularImgUrl,
    required this.viewCount,
    this.cardType,
    this.cardSlogan,
    this.service,
    this.sService,
    this.issuedTo,
    this.benefits,
    this.scBenefits,
    this.annualFee,
    this.scAnnualFee,
    required this.cardBrand,
    this.notice,
  });

  factory CardModel.fromJson(Map<String, dynamic> json) {
    return CardModel(
      cardNo: json['cardNo'],
      cardName: json['cardName'],
      cardUrl: json['cardUrl'],
      popularImgUrl: json['popularImgUrl'],
      viewCount: json['viewCount'],
      cardType: json['cardType'],
      cardSlogan: json['cardSlogan'],
      service: json['service'],
      sService: json['sService'],
      issuedTo: json['issuedTo'],
      benefits: json['benefits'],
      scBenefits: json['scBenefits'],
      annualFee: json['annualFee'],
      scAnnualFee: json['scAnnualFee'],
      cardBrand: json['cardBrand'] ?? '',
      notice: json['cardNotice'],
    );
  }
}
//확인