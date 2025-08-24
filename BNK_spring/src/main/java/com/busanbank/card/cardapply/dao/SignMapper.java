package com.busanbank.card.cardapply.dao;

import org.apache.ibatis.annotations.*;

@Mapper
public interface SignMapper {

  @Delete("""
    DELETE FROM CARD_APPLY_SIGNATURE
     WHERE APPLICATION_NO = #{appNo}
  """)
  int deleteByAppNo(@Param("appNo") long appNo);

  @Insert("""
    INSERT INTO CARD_APPLY_SIGNATURE (
      SIGN_NO, APPLICATION_NO, MEMBER_NO, SIGN_IMAGE, SIGNED_AT
    ) VALUES (
      CARD_APPLY_SIGNATURE_SEQ.NEXTVAL, #{appNo}, #{memberNo},
      #{image,jdbcType=BLOB}, SYSDATE
    )
  """)
  int insertSignature(@Param("appNo") long appNo,
                      @Param("memberNo") long memberNo,
                      @Param("image") byte[] image);
}
