package com.busanbank.card.cardapply.dto;

import lombok.Data;
import java.sql.Timestamp;

@Data
public class CardApplySignatureRec {
  private Long signNo;
  private Long applicationNo;
  private Long memberNo;
  private Timestamp signedAt;
  private byte[] signImage; // BLOB
}
