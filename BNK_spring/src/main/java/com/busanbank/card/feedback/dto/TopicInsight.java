package com.busanbank.card.feedback.dto;

import java.util.List;

public class TopicInsight {
    private final String topic;
    private final long total;
    private final long positive;
    private final long negative;
    private final long neutral;
    private final double positiveRatio;
    private final Double avgScore;
    private final Double avgRating;
    private final List<Example> examples;

    public TopicInsight(String topic, long total, long positive, long negative, long neutral,
                        double positiveRatio, Double avgScore, Double avgRating, List<Example> examples) {
        this.topic = topic;
        this.total = total;
        this.positive = positive;
        this.negative = negative;
        this.neutral = neutral;
        this.positiveRatio = positiveRatio;
        this.avgScore = avgScore;
        this.avgRating = avgRating;
        this.examples = examples;
    }

    public String getTopic() { return topic; }
    public long getTotal() { return total; }
    public long getPositive() { return positive; }
    public long getNegative() { return negative; }
    public long getNeutral() { return neutral; }
    public double getPositiveRatio() { return positiveRatio; }
    public Double getAvgScore() { return avgScore; }
    public Double getAvgRating() { return avgRating; }
    public List<Example> getExamples() { return examples; }

    // 예시 DTO
    public static class Example {
        private final Long feedbackNo;
        private final Integer rating;
        private final String comment;

        public Example(Long feedbackNo, Integer rating, String comment) {
            this.feedbackNo = feedbackNo;
            this.rating = rating;
            this.comment = comment;
        }

        public Long getFeedbackNo() { return feedbackNo; }
        public Integer getRating()  { return rating; }
        public String getComment()  { return comment; }
    }
}
