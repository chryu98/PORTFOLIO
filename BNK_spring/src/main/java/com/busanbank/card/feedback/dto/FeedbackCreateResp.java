package com.busanbank.card.feedback.dto;

@Transactional
public FeedbackCreateResp create(FeedbackCreateReq req) {
    CardFeedback cf = new CardFeedback();
    cf.setCardNo(req.cardNo());
    cf.setUserNo(req.userNo());
    cf.setRating(req.rating());      // Integer로 맞추셨으니 그대로
    cf.setComment(req.comment());
    repo.save(cf);

    try {
        var ar = analysisClient.analyze(cf.getFeedbackNo(), req.comment(), req.rating());
        applyAnalysis(ar);
    } catch (Exception e) {
        // 로그만 찍고, 분석은 나중에 재시도(배치/버튼 등)할 수 있게 둠
        org.slf4j.LoggerFactory.getLogger(getClass())
            .warn("AI 분석 실패, feedbackNo={}", cf.getFeedbackNo(), e);
    }
    return new FeedbackCreateResp(cf.getFeedbackNo());
}
