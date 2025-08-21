package com.busanbank.card.feedback.dto;

import com.busanbank.card.feedback.entity.CardFeedback;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.util.List;

@Getter
@NoArgsConstructor
@AllArgsConstructor
public class DashboardSummary {
    private double positiveRatio;
    private double negativeRatio;
    private double avgRating;
    private List<KeywordStat> topKeywords;
    private List<CardFeedback> recent;
    private List<CardFeedback> anomalies;
}
