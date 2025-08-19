package com.busanbank.card.admin.dao;

import java.util.List;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

import com.busanbank.card.admin.dto.ApplicationViewDto;
import com.busanbank.card.user.dto.UserDto;

@Mapper
public interface IAdminUserInfo {

	@Select({
	    "SELECT",
	    "   MEMBER_NO     AS memberNo,",
	    "   USERNAME      AS username,",
	    "   PASSWORD      AS password,",
	    "   NAME          AS name,",
	    "   ROLE          AS role,",
	    "   RRN_FRONT     AS rrnFront,",
	    "   RRN_GENDER    AS rrnGender,",
	    "   RRN_TAIL_ENC  AS rrnTailEnc,",
	    "   ZIP_CODE      AS zipCode,",
	    "   ADDRESS1      AS address1,",
	    "   ADDRESS2      AS address2",
	    "FROM MEMBER",
	    "ORDER BY MEMBER_NO DESC"
	})
	List<UserDto> findAllUsers();

	
	// ★ 신규: 특정 회원의 카드 신청/가입 내역 조회
	@Select({
        "SELECT",
        "  ca.APPLICATION_NO           AS applicationNo,",
        "  ca.MEMBER_NO                AS memberNo,",
        "  ca.CARD_NO                  AS cardNo,",
        "  ca.STATUS                   AS status,",
        "  ca.IS_CREDIT_CARD           AS isCreditCard,",
        "  ca.HAS_ACCOUNT_AT_KYC       AS hasAccountAtKyc,",
        "  ca.IS_SHORT_TERM_MULTI      AS isShortTermMulti,",
        "  TO_CHAR(ca.CREATED_AT, 'YYYY-MM-DD HH24:MI:SS') AS createdAt,",
        "  TO_CHAR(ca.UPDATED_AT, 'YYYY-MM-DD HH24:MI:SS') AS updatedAt,",
        "  c.CARD_NAME                 AS cardName,",
        "  c.CARD_URL                  AS cardUrl",
        "FROM CARD_APPLICATION ca",
        "JOIN CARD c ON ca.CARD_NO = c.CARD_NO",
        "WHERE ca.MEMBER_NO = #{memberNo}",
        "ORDER BY ca.APPLICATION_NO DESC"
    })
    List<ApplicationViewDto> findApplicationsByMember(@Param("memberNo") Long memberNo); // ★ 추가
}
