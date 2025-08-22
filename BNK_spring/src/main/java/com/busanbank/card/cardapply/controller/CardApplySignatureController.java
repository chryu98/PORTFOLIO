package com.busanbank.card.cardapply.controller;

import com.busanbank.card.cardapply.dao.CardApplySignatureDao;
import com.busanbank.card.cardapply.dto.CardApplySignatureRec;
import lombok.RequiredArgsConstructor;
import org.springframework.http.*;
import org.springframework.web.bind.annotation.*;

@RestController // ← 바이너리 응답이므로 RestController가 더 안전
@RequestMapping("/card/apply/sign")
@RequiredArgsConstructor
public class CardApplySignatureController {

  private final CardApplySignatureDao dao;

  @GetMapping(value = "/{appNo}/image", produces = MediaType.ALL_VALUE)
  public ResponseEntity<byte[]> image(@PathVariable("appNo") Long appNo) { // ← 이름 명시
    CardApplySignatureRec r = dao.findFinalByApplicationNo(appNo);
    if (r == null || r.getSignImage() == null || r.getSignImage().length == 0) {
      return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
    }

    byte[] bytes = r.getSignImage();
    HttpHeaders headers = new HttpHeaders();
    headers.setCacheControl(CacheControl.noCache());
    headers.setContentType(sniff(bytes));
    headers.setContentLength(bytes.length);
    headers.set(HttpHeaders.CONTENT_DISPOSITION, "inline; filename=\"signature-" + appNo + "\"");

    return new ResponseEntity<>(bytes, headers, HttpStatus.OK);
  }

  private MediaType sniff(byte[] d) {
    if (d != null && d.length >= 4) {
      if (d[0] == (byte) 0xFF && d[1] == (byte) 0xD8) return MediaType.IMAGE_JPEG;
      if (d[0] == (byte) 0x89 && d[1] == (byte) 0x50) return MediaType.IMAGE_PNG;
      if (d[0] == (byte) 0x47 && d[1] == (byte) 0x49) return MediaType.IMAGE_GIF;
    }
    return MediaType.APPLICATION_OCTET_STREAM;
  }
}
