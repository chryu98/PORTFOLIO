package com.busanbank.card.admin.dao;

import com.busanbank.card.admin.dto.AdminPushRow;
import org.apache.ibatis.annotations.Param;

import java.util.List;
import java.util.Map;

public interface AdminPushMapper {
    void insertPush(AdminPushRow row);

    void insertPushTarget(@Param("pushNo") long pushNo,
                          @Param("memberNo") long memberNo);

    int countPreviewAll();
    int countPreviewList(@Param("memberNos") List<Long> memberNos);

    List<Long> selectRecipientsForPush(@Param("pushNo") long pushNo);

    List<Map<String,Object>> selectPushList(@Param("offset") int offset,
                                            @Param("size") int size);

    int countPushList();
}
