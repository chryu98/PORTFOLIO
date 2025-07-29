class CardModel {
  final int cardNo;
  final String cardName;
  final String cardUrl;
  final String? cardSlogan;

  CardModel({
    required this.cardNo,
    required this.cardName,
    required this.cardUrl,
    this.cardSlogan,
  });

  factory CardModel.fromJson(Map<String, dynamic> json) {
    return CardModel(
      cardNo: json['cardNo'],
      cardName: json['cardName'],
      cardUrl: json['cardUrl'],
      cardSlogan: json['cardSlogan'],
    );
  }
}
