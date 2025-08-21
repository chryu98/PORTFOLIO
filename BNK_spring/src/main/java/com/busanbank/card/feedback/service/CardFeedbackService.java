// com/busanbank/card/feedback/service/CardFeedbackService.java
package com.busanbank.card.feedback.service;

import com.busanbank.card.feedback.dto.*;
import com.busanbank.card.feedback.entity.CardFeedback;
import com.busanbank.card.feedback.repo.CardFeedbackRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Date;
import java.util.Objects;
import java.util.Optional;

@Slf4j
@Service
@RequiredArgsConstructor
public class CardFeedbackService {

    private final CardFeedbackRepository repo;
    private final FeedbackAnalysisClient analysisClient; // 이 Bean이 @Component/@Service 또는 @Bean으로 등록돼 있어야 합니다.

    @Transactional
    public FeedbackCreateResp create(FeedbackCreateReq req) {
        // 1) 저장
        CardFeedback cf = new CardFeedback();
        cf.setCardNo(req.cardNo());
        cf.setUserNo(req.userNo());
        cf.setRating(req.rating());
        // 엔티티 게터/세터명에 맞추세요. (feedbackComment 필드라면 아래처럼)
        cf.setFeedbackComment(req.comment());
        repo.save(cf);

        // 2) ID 보정 (트리거/IDENTITY 환경 방어)
        Long fid = cf.getFeedbackNo();
        if (fid == null) {
            var latest = repo.findAllByOrderByCreatedAtDesc(PageRequest.of(0, 1))
                    .getContent().stream().findFirst();
            if (latest.isPresent()) {
                cf = latest.get();
                fid = cf.getFeedbackNo();
            }
        }

        // 3) AI 분석 (실패해도 저장은 성공하도록)
        try {
            AnalysisUpdateReq ar = analysisClient.analyze(fid, req.comment(), req.rating());
            applyAnalysis(ar);
        } catch (Exception e) {
            log.warn("AI 분석 실패 - feedbackNo={}", fid, e);
        }

        return new FeedbackCreateResp(fid);
    }

    @Transactional
    public void applyAnalysis(AnalysisUpdateReq ar) {
        CardFeedback cf = repo.findById(ar.feedbackNo())
                .orElseThrow(() -> new IllegalArgumentException("Not found: " + ar.feedbackNo()));
        cf.setSentimentLabel(ar.sentimentLabel());
        cf.setSentimentScore(ar.sentimentScore() == null ? null :
                java.math.BigDecimal.valueOf(ar.sentimentScore()));
        cf.setAiKeywords(ar.keywords() == null ? null : String.join(",", ar.keywords()));
        cf.setInconsistencyFlag(ar.inconsistency() ? "Y" : "N");
        cf.setInconsistencyReason(ar.reason());
        cf.setAnalyzedAt(new Date());
        repo.save(cf);
    }

    @Transactional(readOnly = true)
    public DashboardSummary dashboard(int topN) {
        // 감성 비율
        var counts = repo.countBySentiment();
        long total = counts.stream().mapToLong(o -> ((Number) o[1]).longValue()).sum();
        long pos = counts.stream()
                .filter(o -> "POSITIVE".equalsIgnoreCase(Objects.toString(o[0], "")))
                .mapToLong(o -> ((Number) o[1]).longValue()).sum();
        long neg = counts.stream()
                .filter(o -> "NEGATIVE".equalsIgnoreCase(Objects.toString(o[0], "")))
                .mapToLong(o -> ((Number) o[1]).longValue()).sum();

        double positiveRatio = total == 0 ? 0 : (double) pos / total;
        double negativeRatio = total == 0 ? 0 : (double) neg / total;

        // 키워드 TOP N
        var top = repo.topKeywords(Math.max(1, topN)).stream()
                .map(r -> new KeywordStat(
                        r[0] == null ? "" : r[0].toString(),
                        ((Number) r[1]).longValue()))
                .toList();

        // 평균 평점
        double avg = Optional.ofNullable(repo.avgRatingAll()).orElse(0.0);

        // 최근 20개 + 이상치
        var recent = repo.findAllByOrderByCreatedAtDesc(PageRequest.of(0, 20)).getContent();
        var anomalies = repo.findInconsistencies();

        return new DashboardSummary(positiveRatio, negativeRatio, avg, top, recent, anomalies);
    }

    @Transactional(readOnly = true)
    public CardFeedback getOne(Long id) {
        return repo.findById(id).orElseThrow();
    }
}
