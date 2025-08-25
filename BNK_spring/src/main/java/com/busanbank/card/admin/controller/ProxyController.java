package com.busanbank.card.admin.controller;


import org.springframework.http.*;
import org.springframework.util.StreamUtils;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.client.RestTemplate;

import jakarta.servlet.http.HttpServletResponse;
import java.io.InputStream;
import java.net.URI;
import java.nio.charset.StandardCharsets;
import java.time.Duration;

@RestController
@RequestMapping("/admin/api")
public class ProxyController {

 private final RestTemplate rest = new RestTemplate();

 // 관리자 이미지에서의 pdf 액셀 미리보기 카드이미지 들고오는 
 @GetMapping("/proxy-img")
 public void proxyImage(@RequestParam("url") String url,
                        HttpServletResponse resp) {
     try {
         HttpHeaders headers = new HttpHeaders();
         // 일부 CDN은 UA 없으면 403/404 주기도 함
         headers.set("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)");
         headers.set("Accept", "image/avif,image/webp,image/apng,image/*,*/*;q=0.8");
         headers.set("Referer", ""); // 필요시 비움

         RequestEntity<Void> req = new RequestEntity<>(headers, HttpMethod.GET, URI.create(url));
         ResponseEntity<byte[]> res = rest.exchange(req, byte[].class);

         if (!res.getStatusCode().is2xxSuccessful() || res.getBody() == null) {
             resp.setStatus(404);
             return;
         }

         MediaType ct = res.getHeaders().getContentType();
         if (ct == null || !ct.getType().equalsIgnoreCase("image")) {
             // 일부 서버가 content-type을 안 주거나 text/html로 줄 수도 있음
             ct = MediaType.IMAGE_PNG;
         }

         resp.setStatus(200);
         resp.setContentType(ct.toString());
         // 캐시 헤더 선택적으로 부여
         resp.setHeader("Cache-Control", "public, max-age=86400");

         StreamUtils.copy(res.getBody(), resp.getOutputStream());
         resp.flushBuffer();
     } catch (Exception e) {
         resp.setStatus(404);
         try {
             String msg = "NO IMG";
             resp.setContentType(MediaType.TEXT_PLAIN_VALUE);
             resp.getOutputStream().write(msg.getBytes(StandardCharsets.UTF_8));
         } catch (Exception ignored) {}
     }
 }
}
