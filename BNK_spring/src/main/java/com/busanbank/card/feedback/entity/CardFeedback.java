package com.busanbank.card.feedback.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.util.Date;

@Getter
@Setter
@Entity
@Table(name = "CARD_FEEDBACK")
public class CardFeedback {

    @Id
    @Column(name = "FEEDBACK_NO")
    private Long feedbackNo;

    @Column(name = "CARD_NO", nullable = false)
    private Long cardNo;

    @Column(name = "USER_NO")
    private Long userNo;

    // DDL: FEEDBACK_COMMENT
    @Column(name = "FEEDBACK_COMMENT")
    private String comment;

    @Column(name = "RATING")
    private Integer rating;

    @Column(name = "SENTIMENT_LABEL")
    private String sentimentLabel;

    @Column(name = "SENTIMENT_SCORE")
    private BigDecimal sentimentScore;

    @Column(name = "AI_KEYWORDS")
    private String aiKeywords;

    @Column(name = "INCONSISTENCY_FLAG")
    private String inconsistencyFlag; // 'Y'/'N'

    @Column(name = "INCONSISTENCY_REASON")
    private String inconsistencyReason;

    @Temporal(TemporalType.TIMESTAMP)
    @Column(name = "ANALYZED_AT")
    private Date analyzedAt;

    @Temporal(TemporalType.TIMESTAMP)
    @Column(name = "CREATED_AT", insertable = false, updatable = false)
    private Date createdAt;
}
