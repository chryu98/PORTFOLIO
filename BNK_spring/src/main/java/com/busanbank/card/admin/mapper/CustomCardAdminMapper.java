package com.busanbank.card.admin.mapper;

import com.busanbank.card.custom.dto.CustomCardDto;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

@Mapper
public interface CustomCardAdminMapper {

    int countCards(@Param("aiResult") String aiResult,
                   @Param("memberNo") Long memberNo,
                   @Param("status") String status);

    List<CustomCardDto> findCards(@Param("aiResult") String aiResult,
                                  @Param("memberNo") Long memberNo,
                                  @Param("status") String status,
                                  @Param("offset") int offset,
                                  @Param("limit") int limit);

    CustomCardDto findOne(@Param("customNo") Long customNo);

    // 선택: 이후 승인 기능 필요 시 사용
    int updateStatus(@Param("customNo") Long customNo,
                     @Param("status") String status,     // APPROVED | REJECTED | PENDING
                     @Param("reason") String reason);    // 반려 사유
}
