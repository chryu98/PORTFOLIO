package com.busanbank.card.feedback.dto;

import java.util.List;

public record AnalysisUpdateReq(
    Long feedbackNo,
    String sentimentLabel,
    Double sentimentScore,
    List<String> keywords,
    boolean inconsistency,
    String reason
) {}
