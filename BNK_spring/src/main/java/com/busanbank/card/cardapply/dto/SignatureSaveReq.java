package com.busanbank.card.cardapply.dto;

import lombok.Data;

@Data
public class SignatureSaveReq {
  private Long applicationNo;
  private String imageBase64; // "data:image/png;base64,..." 또는 순수 base64
}
