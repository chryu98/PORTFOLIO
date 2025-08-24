package com.busanbank.card.feedback.entity;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.util.Date;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "CARD_FEEDBACK")
@Getter @Setter @NoArgsConstructor
public class CardFeedback {

    @Id
    @GeneratedValue(strategy = GenerationType.SEQUENCE, generator = "card_feedback_seq")
    @SequenceGenerator(
        name = "card_feedback_seq",
        sequenceName = "SEQ_CARD_FEEDBACK", // DB에 만든 시퀀스명
        allocationSize = 1
    )
    @Column(name = "FEEDBACK_NO")
    private Long feedbackNo;

    @Column(name = "CARD_NO", nullable = false)
    private Long cardNo;

    @Column(name = "USER_NO")
    private Long userNo;

    @Column(name = "RATING")
    private Integer rating;

    @Column(name = "FEEDBACK_COMMENT")
    private String feedbackComment; // ← 필드명 통일

    @Column(name = "SENTIMENT_LABEL")
    private String sentimentLabel;

    @Column(name = "SENTIMENT_SCORE", precision = 5, scale = 4)
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
    @Column(name = "created_at", nullable = false) // insertable/updatable 기본값(true) 유지
    private Date createdAt;

    @PrePersist
    protected void onCreate() {
        if (createdAt == null) {
            createdAt = new Date();
        }
    }
}
