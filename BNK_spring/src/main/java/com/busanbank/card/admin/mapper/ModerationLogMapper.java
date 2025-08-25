package com.busanbank.card.admin.mapper;

import com.busanbank.card.admin.dto.ModerationLogDto;
import com.busanbank.card.admin.dto.ModerationLogSearchDto;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

@Mapper
public interface ModerationLogMapper {
    List<ModerationLogDto> findLogs(@Param("s") ModerationLogSearchDto s,
                                    @Param("offset") int offset,
                                    @Param("size") int size,
                                    @Param("toPlus1") String toPlus1);

    int countLogs(@Param("s") ModerationLogSearchDto s,
                  @Param("toPlus1") String toPlus1);
}
