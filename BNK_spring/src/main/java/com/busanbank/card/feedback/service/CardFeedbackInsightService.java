// com/busanbank/card/feedback/service/CardFeedbackInsightService.java
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
        final int d = (days == null || days <= 0) ? 30 : days;
        final int topN = (limit == null || limit <= 0) ? 5 : limit;
        final Double cutoff = (minScore != null && minScore >= 0.0 && minScore <= 1.0) ? minScore : null;

        // 기간 계산
        Date to = new Date();
        Calendar cal = Calendar.getInstance();
        cal.setTime(to);
        cal.add(Calendar.DAY_OF_MONTH, -d);
        Date from = cal.getTime();

        // 분석된 건만 기간 내 조회
        List<CardFeedback> rows = repo.findAnalyzedBetween(from, to);
        if (rows == null) rows = Collections.emptyList();

        // 전체 지표
        long total = rows.size();
        long pos = rows.stream().filter(r -> eq(r.getSentimentLabel(), "POSITIVE")).count();
        long neg = rows.stream().filter(r -> eq(r.getSentimentLabel(), "NEGATIVE")).count();
        double avgRating = rows.stream()
                .map(CardFeedback::getRating).filter(Objects::nonNull)
                .mapToInt(Integer::intValue).average().orElse(0.0);

        double positiveRatio = total == 0 ? 0.0 : (double) pos / total;
        double negativeRatio = total == 0 ? 0.0 : (double) neg / total;

        // 주제(키워드)별 집계
        Map<String, Stats> map = new HashMap<>();
        for (CardFeedback f : rows) {
            // 신뢰도 컷(선택)
            if (cutoff != null && f.getSentimentScore() != null
                    && f.getSentimentScore().doubleValue() < cutoff) {
                continue;
            }

            List<String> kws = splitKeywords(f.getAiKeywords());
            if (kws.isEmpty()) kws = List.of("기타");

            String label = val(f.getSentimentLabel());
            Integer rating = f.getRating();
            Double score = (f.getSentimentScore() == null) ? null : f.getSentimentScore().doubleValue();

            for (String kw : kws) {
                Stats s = map.computeIfAbsent(kw, k -> new Stats());
                s.total++;
                if ("POSITIVE".equals(label))      s.positive++;
                else if ("NEGATIVE".equals(label)) s.negative++;
                else                               s.neutral++;

                if (rating != null) { s.ratingSum += rating; s.ratingCnt++; }
                if (score  != null) { s.scoreSum  += score;  s.scoreCnt++; }

                // 예시는 최대 2개만
                if (s.examples.size() < 2) {
                    String cmt = Optional.ofNullable(f.getFeedbackComment()).orElse("");
                    if (cmt.length() > 120) cmt = cmt.substring(0, 120) + "…";
                    s.examples.add(new TopicInsight.Example(f.getFeedbackNo(), rating, cmt));
                }
            }
        }

        // TopicInsight로 변환
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

        // 정렬 기준
        Comparator<TopicInsight> byPos = Comparator
                .comparing(TopicInsight::getPositiveRatio) // double(원시)라 null 없음
                .reversed()
                .thenComparing(TopicInsight::getTotal, Comparator.reverseOrder());

        Comparator<TopicInsight> byNeg = Comparator
                .comparing((TopicInsight t) -> ratio(t.getNegative(), t.getTotal()))
                .reversed()
                .thenComparing(TopicInsight::getTotal, Comparator.reverseOrder());

        // 상위 목록
        List<TopicInsight> topPositive = allTopics.stream()
                .filter(t -> t.getTotal() >= 1) // 필요시 3으로 올려 노이즈 제거
                .sorted(byPos)
                .limit(topN)
                .collect(Collectors.toList());

        List<TopicInsight> topNegative = allTopics.stream()
                .filter(t -> t.getTotal() >= 1)
                .sorted(byNeg)
                .limit(topN)
                .collect(Collectors.toList());

        return new InsightSummary(positiveRatio, negativeRatio, avgRating, topPositive, topNegative);
    }

    // ── helpers ──────────────────────────────────────────────────────────────
    private static boolean eq(String a, String b) { return Objects.equals(val(a), val(b)); }
    private static String val(String s) { return s == null ? "" : s.trim().toUpperCase(Locale.ROOT); }

    private static List<String> splitKeywords(String s) {
        if (s == null || s.isBlank()) return List.of();
        String[] arr = s.split("\\s*,\\s*"); // 쉼표 + 양쪽 공백 제거
        List<String> out = new ArrayList<>(arr.length);
        for (String a : arr) { if (!a.isBlank()) out.add(a.trim()); }
        return out;
    }

    private static Double round2(Double v) { return v == null ? null : Math.round(v * 100.0) / 100.0; }
    private static double ratio(long a, long b) { return b == 0 ? 0.0 : (double) a / b; }

    private static final class Stats {
        long total, positive, negative, neutral;
        long ratingSum; int ratingCnt;
        double scoreSum; int scoreCnt;
        List<TopicInsight.Example> examples = new ArrayList<>();
    }
}
