package com.busanbank.card.feedback.service;

import com.busanbank.card.feedback.dto.InsightSummary;
import com.busanbank.card.feedback.dto.TopicInsight;
import com.busanbank.card.feedback.entity.CardFeedback;
import com.busanbank.card.feedback.repo.CardFeedbackRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class CardFeedbackInsightService {

    private final CardFeedbackRepository repo;

    @Transactional(readOnly = true)
    public InsightSummary insights(Integer days, Integer limit, Double minScore) {
        int d = (days == null || days <= 0) ? 30 : days;
        int topN = (limit == null || limit <= 0) ? 5 : limit;
        Double cutoff = (minScore != null && minScore >= 0 && minScore <= 1) ? minScore : null;

        Date to = new Date();
        Calendar cal = Calendar.getInstance();
        cal.setTime(to);
        cal.add(Calendar.DAY_OF_MONTH, -d);
        Date from = cal.getTime();

        List<CardFeedback> rows = repo.findAnalyzedBetween(from, to);

        long total = rows.size();
        long pos = rows.stream().filter(r -> eq(r.getSentimentLabel(), "POSITIVE")).count();
        long neg = rows.stream().filter(r -> eq(r.getSentimentLabel(), "NEGATIVE")).count();
        double avgRating = rows.stream()
                .map(CardFeedback::getRating).filter(Objects::nonNull)
                .mapToInt(Integer::intValue).average().orElse(0.0);

        double positiveRatio = total == 0 ? 0.0 : (double) pos / total;
        double negativeRatio = total == 0 ? 0.0 : (double) neg / total;

        Map<String, Stats> map = new HashMap<>();
        for (CardFeedback f : rows) {
            if (cutoff != null && f.getSentimentScore() != null) {
                double sc = f.getSentimentScore().doubleValue();
                if (sc < cutoff) continue; // 컷 미달 제외
            }
            List<String> kws = splitKeywords(f.getAiKeywords());
            if (kws.isEmpty()) kws = List.of("기타");

            String label = val(f.getSentimentLabel());
            Integer rating = f.getRating();
            Double score = f.getSentimentScore() == null ? null : f.getSentimentScore().doubleValue();

            for (String kw : kws) {
                Stats s = map.computeIfAbsent(kw, k -> new Stats());
                s.total++;
                switch (label) {
                    case "POSITIVE" -> s.positive++;
                    case "NEGATIVE" -> s.negative++;
                    default -> s.neutral++;
                }
                if (rating != null) { s.ratingSum += rating; s.ratingCnt++; }
                if (score != null)  { s.scoreSum  += score;  s.scoreCnt++; }

                if (s.examples.size() < 2) {
                    String cmt = Optional.ofNullable(f.getFeedbackComment()).orElse("");
                    if (cmt.length() > 120) cmt = cmt.substring(0, 120) + "…";
                    s.examples.add(new TopicInsight.Example(f.getFeedbackNo(), rating, cmt));
                }
            }
        }

        List<TopicInsight> allTopics = map.entrySet().stream()
                .map(e -> {
                    Stats s = e.getValue();
                    double pRatio = s.total == 0 ? 0.0 : (double) s.positive / s.total;
                    Double avgSc = s.scoreCnt == 0 ? null : round2(s.scoreSum / s.scoreCnt);
                    Double avgRt = s.ratingCnt == 0 ? null : round2((double) s.ratingSum / s.ratingCnt);
                    return new TopicInsight(
                            e.getKey(), s.total, s.positive, s.negative, s.neutral,
                            pRatio, avgSc, avgRt, List.copyOf(s.examples)
                    );
                })
                .collect(Collectors.toList());

        Comparator<TopicInsight> byPos = Comparator
                .comparing(TopicInsight::getPositiveRatio, Comparator.nullsFirst(Comparator.naturalOrder()))
                .reversed()
                .thenComparing(TopicInsight::getTotal, Comparator.reverseOrder());

        Comparator<TopicInsight> byNeg = Comparator
                .comparing((TopicInsight t) -> ratio(t.getNegative(), t.getTotal()))
                .reversed()
                .thenComparing(TopicInsight::getTotal, Comparator.reverseOrder());

        List<TopicInsight> topPositive = allTopics.stream()
                .filter(t -> t.getTotal() >= 3)
                .sorted(byPos)
                .limit(topN)
                .collect(Collectors.toList());

        List<TopicInsight> topNegative = allTopics.stream()
                .filter(t -> t.getTotal() >= 3)
                .sorted(byNeg)
                .limit(topN)
                .collect(Collectors.toList());

        return new InsightSummary(positiveRatio, negativeRatio, avgRating, topPositive, topNegative);
    }

    // helpers
    private static boolean eq(String a, String b) { return Objects.equals(val(a), b); }
    private static String val(String s) { return s == null ? "" : s.trim().toUpperCase(Locale.ROOT); }

    private static List<String> splitKeywords(String s) {
        if (s == null || s.isBlank()) return List.of();
        String[] arr = s.split("\\s*,\\s*");
        List<String> out = new ArrayList<>();
        for (String a : arr) if (!a.isBlank()) out.add(a.trim());
        return out;
    }
    private static Double round2(Double v) { return v == null ? null : Math.round(v * 100.0) / 100.0; }
    private static double ratio(long a, long b) { return b == 0 ? 0.0 : (double) a / b; }

    private static class Stats {
        long total, positive, negative, neutral;
        long ratingSum; int ratingCnt;
        double scoreSum; int scoreCnt;
        List<TopicInsight.Example> examples = new ArrayList<>();
    }
}
