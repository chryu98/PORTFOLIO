package com.busanbank.card.card.controller;

import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.net.URLDecoder;
import java.nio.charset.StandardCharsets;

import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@CrossOrigin(origins = "*")
@RestController
@RequestMapping("/proxy")
public class ImageProxyController {

    @GetMapping("/image")
    public ResponseEntity<byte[]> proxyImage(@RequestParam("url") String encodedUrl) {
        try { 
            // ✅ 1. URL 디코딩
            String decodedUrl = URLDecoder.decode(encodedUrl, StandardCharsets.UTF_8);

            // ✅ 2. 외부 이미지 요청
            URL imageUrl = new URL(decodedUrl);
            HttpURLConnection connection = (HttpURLConnection) imageUrl.openConnection();
            connection.setRequestProperty("User-Agent", "Mozilla/5.0");
            connection.connect();

            InputStream in = connection.getInputStream();
            byte[] imageBytes = in.readAllBytes();

            String contentType = connection.getContentType();
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.parseMediaType(contentType));

            return new ResponseEntity<>(imageBytes, headers, HttpStatus.OK);
        } catch (Exception e) {
            e.printStackTrace(); // 디버깅용
            return ResponseEntity.status(HttpStatus.BAD_GATEWAY).build();
        }
    }
}