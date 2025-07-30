class CardModel {
  final int cardNo;
  final String cardName;
  final String? cardSlogan;
  final String cardUrl;
  final String? popularImgUrl;
  final int viewCount;
  final String? cardType; // ✅ 추가됨

  CardModel({
    required this.cardNo,
    required this.cardName,
    required this.cardUrl,
    this.cardSlogan,
    this.popularImgUrl,
    required this.viewCount,
    this.cardType, // ✅ 생성자에 추가
  });

  factory CardModel.fromJson(Map<String, dynamic> json) {
    return CardModel(
      cardNo: json['cardNo'],
      cardName: json['cardName'],
      cardSlogan: json['cardSlogan'],
      cardUrl: json['cardUrl'],
      popularImgUrl: json['popularImgUrl'],
      viewCount: json['viewCount'],
      cardType: json['cardType'], // ✅ JSON 매핑 추가
    );
  }
}
