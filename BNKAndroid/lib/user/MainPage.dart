import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class CardMainPage extends StatefulWidget {
  @override
  _CardMainPageState createState() => _CardMainPageState();
}

class _CardMainPageState extends State<CardMainPage> {
  final PageController _pageController = PageController();
  int currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Image.asset('assets/logo.png', height: 30),
        actions: [
          TextButton(onPressed: () {}, child: Text('로그인')),
          IconButton(icon: Icon(Icons.menu), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 🔍 검색창
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: '민생회복 소비쿠폰 바로가기',
                  prefixIcon: Icon(Icons.search),
                  suffixIcon: Icon(Icons.arrow_forward),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                ),
              ),
            ),

            // 📱 카드 슬라이더
            SizedBox(
              height: 250,
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) => setState(() => currentPage = index),
                children: List.generate(8, (index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        image: DecorationImage(
                          image: AssetImage('assets/card_${index + 1}.png'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // 🔘 인디케이터
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SmoothPageIndicator(
                controller: _pageController,
                count: 8,
                effect: WormEffect(dotHeight: 8, dotWidth: 8),
              ),
            ),

            // 🎯 인기/추천 카드 영역
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Text('인기 · 추천카드', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  Spacer(),
                  Icon(Icons.arrow_forward),
                ],
              ),
            ),
            SizedBox(
              height: 180,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 5,
                itemBuilder: (_, index) => Container(
                  width: 150,
                  margin: EdgeInsets.only(left: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.asset('assets/recommend_${index + 1}.png', height: 100),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          '신한카드 Discount Plan',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
