package com.busanbank.card.feedback.dto;

import java.util.List;

public class InsightSummary {
    private final double positiveRatio;
    private final double negativeRatio;
    private final double avgRating;
    private final List<TopicInsight> topPositive;
    private final List<TopicInsight> topNegative;

    public InsightSummary(double positiveRatio, double negativeRatio, double avgRating,
                          List<TopicInsight> topPositive, List<TopicInsight> topNegative) {
        this.positiveRatio = positiveRatio;
        this.negativeRatio = negativeRatio;
        this.avgRating = avgRating;
        this.topPositive = topPositive;
        this.topNegative = topNegative;
    }

    public double getPositiveRatio() { return positiveRatio; }
    public double getNegativeRatio() { return negativeRatio; }
    public double getAvgRating()     { return avgRating; }
    public List<TopicInsight> getTopPositive() { return topPositive; }
    public List<TopicInsight> getTopNegative() { return topNegative; }
}
