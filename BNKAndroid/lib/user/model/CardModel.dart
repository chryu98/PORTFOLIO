class CardModel {
  final int cardNo;
  final String cardName;
  final String? cardSlogan;
  final String cardUrl;
  final String? popularImgUrl; // ✅ 슬라이더용 이미지
  final int viewCount;

  CardModel({
    required this.cardNo,
    required this.cardName,
    required this.cardUrl,
    this.cardSlogan,
    this.popularImgUrl,
    required this.viewCount,
  });

  factory CardModel.fromJson(Map<String, dynamic> json) {
    return CardModel(
      cardNo: json['cardNo'],
      cardName: json['cardName'],
      cardSlogan: json['cardSlogan'],
      cardUrl: json['cardUrl'],
      popularImgUrl: json['popularImgUrl'],
      viewCount: json['viewCount'],
    );
  }
}
