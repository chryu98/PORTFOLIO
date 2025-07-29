package com.busanbank.card.user.util;

import java.util.Base64;

import javax.crypto.Cipher;
import javax.crypto.spec.SecretKeySpec;

public class AESUtil {

	private static final String ALGORITHM = "AES";
    private static final String KEY = "MySecretKey12345"; // 16바이트 (128bit) 고정

    // 암호화
    public static String encrypt(String plainText) throws Exception {
        SecretKeySpec keySpec = new SecretKeySpec(KEY.getBytes(), ALGORITHM);
        Cipher cipher = Cipher.getInstance(ALGORITHM); // AES/ECB/PKCS5Padding 도 가능
        cipher.init(Cipher.ENCRYPT_MODE, keySpec);
        byte[] encrypted = cipher.doFinal(plainText.getBytes());
        return Base64.getEncoder().encodeToString(encrypted); // 암호문은 문자열로 인코딩해서 저장
    }

    // 복호화
    public static String decrypt(String cipherText) throws Exception {
        SecretKeySpec keySpec = new SecretKeySpec(KEY.getBytes(), ALGORITHM);
        Cipher cipher = Cipher.getInstance(ALGORITHM);
        cipher.init(Cipher.DECRYPT_MODE, keySpec);
        byte[] decoded = Base64.getDecoder().decode(cipherText);
        byte[] decrypted = cipher.doFinal(decoded);
        return new String(decrypted);
    }
}
