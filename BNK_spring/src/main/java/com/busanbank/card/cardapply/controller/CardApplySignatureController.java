package com.busanbank.card.cardapply.controller;

import com.busanbank.card.cardapply.dao.CardApplySignatureDao;
import com.busanbank.card.cardapply.dto.CardApplySignatureRec;
import lombok.RequiredArgsConstructor;
import org.springframework.http.*;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.*;

@Controller
@RequestMapping("/card/apply/sign")
@RequiredArgsConstructor
public class CardApplySignatureController {

  private final CardApplySignatureDao dao;

  @GetMapping("/{appNo}/image")
  public ResponseEntity<byte[]> image(@PathVariable Long appNo) {
    CardApplySignatureRec r = dao.findFinalByApplicationNo(appNo);
    if (r == null || r.getSignImage() == null || r.getSignImage().length == 0) {
      return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
    }

    byte[] bytes = r.getSignImage();
    HttpHeaders h = new HttpHeaders();
    h.setCacheControl(CacheControl.noCache());
    h.setContentType(sniff(bytes));
    return new ResponseEntity<>(bytes, h, HttpStatus.OK);
  }

  private MediaType sniff(byte[] d) {
    if (d != null && d.length >= 4) {
      if (d[0]==(byte)0xFF && d[1]==(byte)0xD8) return MediaType.IMAGE_JPEG;
      if (d[0]==(byte)0x89 && d[1]==(byte)0x50) return MediaType.IMAGE_PNG;
      if (d[0]==(byte)0x47 && d[1]==(byte)0x49) return MediaType.IMAGE_GIF;
    }
    return MediaType.APPLICATION_OCTET_STREAM;
  }
}
