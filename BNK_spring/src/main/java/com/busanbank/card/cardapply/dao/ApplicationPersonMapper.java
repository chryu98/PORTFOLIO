// src/main/java/com/busanbank/card/cardapply/dao/ApplicationPersonMapper.java
package com.busanbank.card.cardapply.dao;

import org.apache.ibatis.annotations.*;

@Mapper
public interface ApplicationPersonMapper {

  @Select("""
      SELECT 1
        FROM APPLICATION_PERSON_TEMP
       WHERE APPLICATION_NO = #{appNo}
         FOR UPDATE
  """)
  Integer lockTemp(@Param("appNo") long appNo);

  @Select("""
      SELECT COUNT(1)
        FROM APPLICATION_PERSON
       WHERE APPLICATION_NO = #{appNo}
  """)
  Integer existsFinal(@Param("appNo") long appNo);

  @Update("""
      MERGE INTO APPLICATION_PERSON tgt
      USING (
        SELECT APPLICATION_NO,
               NAME, NAME_ENG,
               RRN_FRONT, RRN_GENDER, RRN_TAIL_ENC,
               PHONE, EMAIL,
               ZIP_CODE, ADDRESS1, ADDRESS2,
               JOB, PURPOSE, FUND_SOURCE,
               ADDRESS_TYPE, CARD_BRAND, POSTPAID_CARD,
               CREATED_AT
          FROM APPLICATION_PERSON_TEMP
         WHERE APPLICATION_NO = #{appNo}
      ) src
      ON (tgt.APPLICATION_NO = src.APPLICATION_NO)
      WHEN MATCHED THEN UPDATE SET
        tgt.NAME          = src.NAME,
        tgt.NAME_ENG      = src.NAME_ENG,
        tgt.RRN_FRONT     = src.RRN_FRONT,
        tgt.RRN_GENDER    = src.RRN_GENDER,
        tgt.RRN_TAIL_ENC  = src.RRN_TAIL_ENC,
        tgt.PHONE         = src.PHONE,
        tgt.EMAIL         = src.EMAIL,
        tgt.ZIP_CODE      = src.ZIP_CODE,
        tgt.ADDRESS1      = src.ADDRESS1,
        tgt.ADDRESS2      = src.ADDRESS2,
        tgt.JOB           = src.JOB,
        tgt.PURPOSE       = src.PURPOSE,
        tgt.FUND_SOURCE   = src.FUND_SOURCE,
        tgt.ADDRESS_TYPE  = src.ADDRESS_TYPE,
        tgt.CARD_BRAND    = src.CARD_BRAND,
        tgt.POSTPAID_CARD = src.POSTPAID_CARD
      WHEN NOT MATCHED THEN INSERT (
        INFO_NO, APPLICATION_NO,
        NAME, NAME_ENG,
        RRN_FRONT, RRN_GENDER, RRN_TAIL_ENC,
        PHONE, EMAIL,
        ZIP_CODE, ADDRESS1, ADDRESS2,
        CREATED_AT,
        JOB, PURPOSE, FUND_SOURCE,
        ADDRESS_TYPE, CARD_BRAND, POSTPAID_CARD
      ) VALUES (
        APPLICATION_PERSON_SEQ.NEXTVAL,
        src.APPLICATION_NO,
        src.NAME, src.NAME_ENG,
        src.RRN_FRONT, src.RRN_GENDER, src.RRN_TAIL_ENC,
        src.PHONE, src.EMAIL,
        src.ZIP_CODE, src.ADDRESS1, src.ADDRESS2,
        NVL(src.CREATED_AT, SYSDATE),
        src.JOB, src.PURPOSE, src.FUND_SOURCE,
        src.ADDRESS_TYPE, src.CARD_BRAND, src.POSTPAID_CARD
      )
  """)
  int mergeFromTemp(@Param("appNo") long appNo);

  @Delete("""
      DELETE FROM APPLICATION_PERSON_TEMP
       WHERE APPLICATION_NO = #{appNo}
  """)
  int deleteTemp(@Param("appNo") long appNo);
}
