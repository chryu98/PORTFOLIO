package com.busanbank.card.cardapply.dao;

import com.busanbank.card.cardapply.dto.CardPaswwordDto;
import org.apache.ibatis.annotations.*;

@Mapper
public interface CardPasswordMapper {

    @Delete("""
        DELETE FROM CARD_PASSWORD
         WHERE MEMBER_NO = #{memberNo}
           AND CARD_NO   = #{cardNo}
    """)
    int deleteByMemberCard(@Param("memberNo") long memberNo,
                           @Param("cardNo") long cardNo);

    @Insert("""
        INSERT INTO CARD_PASSWORD (MEMBER_NO, CARD_NO, PIN_PHC, CREATED_AT, LAST_MODIFIED_DATE)
        VALUES (#{memberNo}, #{cardNo}, #{pinPhc}, SYSDATE, SYSDATE)
    """)
    @Options(useGeneratedKeys = true, keyProperty = "cpNo", keyColumn = "CP_NO")
    int insert(CardPaswwordDto rec);
}
