package com.busanbank.card.custom.mapper;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

@Mapper
public interface CustomCardModerationMapper {

    int updateAiResult(
            @Param("customNo") Long customNo,
            @Param("aiResult") String aiResult,   // ACCEPT / REJECT
            @Param("aiReason") String aiReason    // 사유 문자열
    );
}
