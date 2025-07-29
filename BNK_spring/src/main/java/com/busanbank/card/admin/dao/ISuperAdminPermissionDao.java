package com.busanbank.card.admin.dao;

import java.util.List;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import com.busanbank.card.admin.dto.PermissionDto;
import com.busanbank.card.card.dto.CardDto;

@Mapper
public interface ISuperAdminPermissionDao {

    CardDto selectCardTemp(@Param("cardNo") Long cardNo);
    CardDto selectCardOriginal(@Param("cardNo") Long cardNo);

    int insertOrUpdateCard(CardDto dto);
    int updatePermissionApprove(@Param("cardNo") Long cardNo, @Param("sAdmin") String sAdmin);
    int updatePermissionReject(@Param("cardNo") Long cardNo, @Param("status") String status, @Param("reason") String reason, @Param("sAdmin") String sAdmin);
    int updatePermissionCancel(@Param("cardNo") Long cardNo, @Param("sAdmin") String sAdmin);

    int deleteCard(@Param("cardNo") Long cardNo);
    int deleteCardTemp(@Param("cardNo") Long cardNo);

    List<PermissionDto> selectPermissionList();
    
    List<PermissionDto> selectPermissionListPaged(
    		 @Param("offset") Integer offset,
    		    @Param("size") Integer size
        );

    int selectPermissionCount();
}
