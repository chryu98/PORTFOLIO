package com.busanbank.card.push.dto;

import lombok.Data;

@Data
public class PushDto {
	private Long pushNo;
	private String title;
	private String content;
	private String targetType; // 'ALL' 사용
	private String createdBy;
	private java.sql.Timestamp createdAt;
}
