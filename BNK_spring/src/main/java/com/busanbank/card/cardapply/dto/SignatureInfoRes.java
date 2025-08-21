package com.busanbank.card.cardapply.dto;

import lombok.Data;

@Data
public class SignatureInfoRes {
  private Long signNo;
  private Long applicationNo;
  private Long memberNo;
  private String signedAt; // ISO 문자열 등으로 가공해서 내려줄 예정
  private boolean exists;
}
