package com.busanbank.card.cardapply.util;

import java.security.SecureRandom;

public class AccountNumberGenerator {
	 private static final SecureRandom RND = new SecureRandom();

	 /** 13자리, 항상 112로 시작 (예: 1120834019275) */
	    public static String generate() {
	        return "112" + randomDigits(10); // 112 + 10자리 = 13자리
	    }

	    private static String randomDigits(int n) {
	        StringBuilder sb = new StringBuilder(n);
	        for (int i = 0; i < n; i++) {
	            sb.append(RND.nextInt(10)); // 0~9
	        }
	        return sb.toString();
	    }
}