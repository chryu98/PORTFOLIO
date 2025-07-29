package com.busanbank.card.busancrawler.test;

import org.openqa.selenium.WebDriver;
import org.openqa.selenium.chrome.ChromeDriver;

public class SeleniumTest {
    public static void main(String[] args) {
        // 드라이버 경로 설정
        System.setProperty("webdriver.chrome.driver", "C:/Users/GGG/Desktop/chromedriver-win64/chromedriver.exe");

        // WebDriver 실행
        WebDriver driver = new ChromeDriver();
        driver.get("https://www.naver.com");

        // 몇 초 후 브라우저 종료 (테스트용)
        try {
            Thread.sleep(5000);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }

        driver.quit();
    }
}