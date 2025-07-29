package com.busanbank.card.busancrawler.service;

import java.time.Duration;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

import org.openqa.selenium.By;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;
import org.openqa.selenium.chrome.ChromeDriver;
import org.openqa.selenium.support.ui.ExpectedConditions;
import org.openqa.selenium.support.ui.WebDriverWait;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.busanbank.card.busancrawler.dto.ScrapCardDto;
import com.busanbank.card.busancrawler.mapper.ScrapCardMapper;

@Service
public class SeleniumCardCrawler {
    
    @Autowired
    ScrapCardMapper scrapCardMapper;
    
    public String crawlShinhanCards() {
        
        List<ScrapCardDto> cardList = new ArrayList<>();
        //크롬 드라이버
        System.setProperty("webdriver.chrome.driver", "C:/Users/GGG/Desktop/chromedriver-win64/chromedriver.exe");
        WebDriver driver = new ChromeDriver();
        
        try { //크롤링할 페이지 URL
            String url = "https://www.shinhancard.com/pconts/html/card/check/MOBFM282R11.html?crustMenuId=ms527";
            driver.get(url);
            
            WebDriverWait wait = new WebDriverWait(driver, Duration.ofSeconds(15));
            wait.until(ExpectedConditions.presenceOfElementLocated(By.cssSelector(".card_thumb_list_wrap li")));
            
            List<WebElement> cardItems = driver.findElements(By.cssSelector(".card_thumb_list_wrap li"));
            StringBuilder result = new StringBuilder();
            
            int limit = Math.min(9, cardItems.size());
            for (int i = 0; i < limit; i++) {
                try {
                    
                    cardItems = driver.findElements(By.cssSelector(".card_thumb_list_wrap li"));
                    WebElement card = cardItems.get(i);
                    
                    String cardName = card.findElement(By.cssSelector(".card_name")).getText();
                    String imgUrl = card.findElement(By.cssSelector(".card_img_wrap img")).getAttribute("src");
                    String benefit = card.findElement(By.cssSelector(".benefit_wrap a")).getText();
                    String detailUrl = card.findElement(By.cssSelector(".card_name")).getAttribute("href");
                    
                    // 상세 페이지 이동
                    driver.navigate().to(detailUrl);
                    Thread.sleep(2000);
                    
                    // ✅ 슬로건 크롤링
                    String slogan = "-";
                    try {
                        WebElement sloganElement = driver.findElement(By.cssSelector(".info-summary"));
                        slogan = sloganElement.getText().trim();
                    } catch (Exception e) {
                        slogan = "슬로건 없음";
                    }

                    // ✅ 연회비 크롤링
                    String annualFee = "";
                    int fee = 0;
                    try {
                        WebElement feeElement = driver.findElement(By.cssSelector(".card_info_list dd"));
                        annualFee = feeElement.getText();
                        if (!annualFee.contains("없음")) {
                            fee = Integer.parseInt(annualFee.replaceAll("[^0-9]", ""));
                        }
                    } catch (Exception e) {
                        annualFee = "연회비 정보 없음";
                        fee = 0;
                    }
                    
                    String benefitDetails = "-";
                    try {
                        List<WebElement> liElements = driver.findElements(By.cssSelector("ul.info-benefit li"));
                        List<String> lines = new ArrayList<>();
                        for (WebElement li : liElements) {
                            String label = li.findElement(By.tagName("span")).getText().trim();
                            String value = li.findElement(By.tagName("b")).getText().trim();
                            lines.add("• " + label + " " + value);
                        }
                        benefitDetails = String.join("<br>", lines);
                    } catch (Exception e) {
                        benefitDetails = "세부 혜택 없음";
                    }
                    
                    // 카드 데이터 저장
                    ScrapCardDto dto = new ScrapCardDto();
                    dto.setScCardName(cardName);
                    dto.setScCardUrl(imgUrl);
                    dto.setScCardSlogan(slogan);
                    dto.setScSService(benefit);
                    dto.setScAnnualFee(fee);
                    dto.setScDate(LocalDate.now());
                    dto.setScBenefits(benefitDetails);
                    
                    cardList.add(dto);
                    
                    // 결과 출력
                    result.append("카드명: ").append(cardName).append("\n");
                    result.append("이미지: ").append(imgUrl).append("\n");
                    result.append("슬로건: ").append(slogan).append("\n");
                    result.append("혜택: ").append(benefit).append("\n");
                    result.append("연회비: ").append(annualFee).append("\n");
                    result.append("상세 URL: ").append(detailUrl).append("\n\n");
                    
                    // 목록으로 돌아가기
                    driver.navigate().back();
                    wait.until(ExpectedConditions.presenceOfElementLocated(By.cssSelector(".card_thumb_list_wrap li")));
                    Thread.sleep(1000);
                    
                } catch (Exception e) {
                    result.append("카드 처리 중 오류: ").append(e.getMessage()).append("\n\n");
                }
            }
            
            if (!cardList.isEmpty()) {
                for (ScrapCardDto card : cardList) {
                    scrapCardMapper.insertCard(card);
                }
                result.append("\n").append(cardList.size()).append("건 DB 저장 완료됨.");
                System.out.println("db저장 완료");
            }
            
            return result.toString();
            
        } catch (Exception e) {
            System.out.println(e.getMessage());
            return "크롤링 실패: " + e.getMessage();
        } finally {
            driver.quit();
        }
    }

    public List<ScrapCardDto> getScrapList() {
        return scrapCardMapper.getScrapList();
    }

    public int deleteAllScrapCards() {
        return scrapCardMapper.deleteAllCards();
    }
}
