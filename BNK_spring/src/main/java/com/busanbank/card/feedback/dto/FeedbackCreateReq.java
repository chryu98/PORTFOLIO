package com.busanbank.card.feedback.dto;

public record FeedbackCreateReq(
    Long cardNo,
    Long userNo,
    Integer rating,
    String comment
) {}
