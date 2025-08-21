package com.busanbank.card.cardapply.dao;

import com.busanbank.card.cardapply.dto.CardApplySignatureRec;
import org.apache.ibatis.annotations.*;
import org.apache.ibatis.type.JdbcType;

@Mapper
public interface CardApplySignatureDao {

  /* ───────── 단계 확인 ───────── */
  @Select("""
      SELECT CASE WHEN COUNT(1) > 0 THEN 1 ELSE 0 END
        FROM CARD_APPLICATION_TEMP
       WHERE APPLICATION_NO = #{appNo}
  """)
  int existsInTemp(@Param("appNo") Long applicationNo);

  @Select("""
      SELECT CASE WHEN COUNT(1) > 0 THEN 1 ELSE 0 END
        FROM CARD_APPLICATION
       WHERE APPLICATION_NO = #{appNo}
  """)
  int existsInFinal(@Param("appNo") Long applicationNo);


  /* ───────── 승격 (TEMP → FINAL) ─────────
     - CARD_NO 를 TEMP에서 그대로 복사
     - NOT NULL: APPLICATION_NO, MEMBER_NO, CARD_NO, STATUS 충족
  */
  @Insert("""
      INSERT /*+ IGNORE_ROW_ON_DUPKEY_INDEX(CARD_APPLICATION(APPLICATION_NO)) */
      INTO CARD_APPLICATION (
        APPLICATION_NO,
        CARD_NO,
        MEMBER_NO,
        STATUS,
        CREATED_AT,
        UPDATED_AT
      )
      SELECT
        APPLICATION_NO,
        CARD_NO,
        MEMBER_NO,
        'PIN_DONE',
        CREATED_AT,
        SYSDATE
      FROM CARD_APPLICATION_TEMP
      WHERE APPLICATION_NO = #{appNo}
  """)
  int promoteInsertFinal(@Param("appNo") Long applicationNo);

  /* ───────── 자식 테이블 이관/삭제 (APPLICATION_PERSON_TEMP → APPLICATION_PERSON) ─────────
     ※ FINAL에만 있는 컬럼(FUND_SOURCE, ADDRESS_TYPE, CARD_BRAND, POSTPAID_CARD)은 NULL 허용이므로 생략
  */
  @Insert("""
      INSERT INTO APPLICATION_PERSON (
        INFO_NO,
        APPLICATION_NO,
        NAME,
        NAME_ENG,
        RRN_FRONT,
        RRN_GENDER,
        RRN_TAIL_ENC,
        PHONE,
        EMAIL,
        ZIP_CODE,
        ADDRESS1,
        ADDRESS2,
        CREATED_AT,
        JOB,
        PURPOSE
      )
      SELECT
        INFO_NO,
        APPLICATION_NO,
        NAME,
        NAME_ENG,
        RRN_FRONT,
        RRN_GENDER,
        RRN_TAIL_ENC,
        PHONE,
        EMAIL,
        ZIP_CODE,
        ADDRESS1,
        ADDRESS2,
        CREATED_AT,
        JOB,
        PURPOSE
      FROM APPLICATION_PERSON_TEMP
      WHERE APPLICATION_NO = #{appNo}
  """)
  int migratePersonTempToFinal(@Param("appNo") Long appNo);

  @Delete("""
      DELETE FROM APPLICATION_PERSON_TEMP
      WHERE APPLICATION_NO = #{appNo}
  """)
  int deletePersonTemp(@Param("appNo") Long appNo);

  /* ───────── 부모 TEMP 삭제 & 상태 보강 ───────── */
  @Delete("""
      DELETE FROM CARD_APPLICATION_TEMP
       WHERE APPLICATION_NO = #{appNo}
  """)
  int deleteTemp(@Param("appNo") Long applicationNo);

  @Update("""
      UPDATE CARD_APPLICATION
         SET STATUS = 'PIN_DONE',
             UPDATED_AT = SYSDATE
       WHERE APPLICATION_NO = #{appNo}
  """)
  int touchFinal(@Param("appNo") Long applicationNo);


  /* ───────── 오너 체크 (FINAL) ───────── */
  @Select("""
      SELECT CASE WHEN COUNT(1) > 0 THEN 1 ELSE 0 END
        FROM CARD_APPLICATION
       WHERE APPLICATION_NO = #{appNo}
         AND MEMBER_NO      = #{memberNo}
  """)
  int isOwnerInFinal(@Param("appNo") Long applicationNo, @Param("memberNo") Long memberNo);


  /* ───────── 서명 조회/업서트 (FINAL) ───────── */
  @Results(value = {
      @Result(property = "signNo",        column = "SIGN_NO"),
      @Result(property = "applicationNo", column = "APPLICATION_NO"),
      @Result(property = "memberNo",      column = "MEMBER_NO"),
      @Result(property = "signedAt",      column = "SIGNED_AT"),
      @Result(property = "signImage",     column = "SIGN_IMAGE",
              javaType = byte[].class, jdbcType = JdbcType.BLOB)
  })
  @Select("""
      SELECT SIGN_NO, APPLICATION_NO, MEMBER_NO, SIGN_IMAGE, SIGNED_AT
        FROM CARD_APPLY_SIGNATURE
       WHERE APPLICATION_NO = #{appNo}
       ORDER BY SIGNED_AT DESC, SIGN_NO DESC
       FETCH FIRST 1 ROWS ONLY
  """)
  CardApplySignatureRec findFinalByApplicationNo(@Param("appNo") Long applicationNo);

  @Update("""
      MERGE INTO CARD_APPLY_SIGNATURE s
      USING (SELECT #{appNo} AS APPLICATION_NO, #{memberNo} AS MEMBER_NO FROM dual) i
         ON (s.APPLICATION_NO = i.APPLICATION_NO)
      WHEN MATCHED THEN
        UPDATE SET s.MEMBER_NO  = i.MEMBER_NO,
                   s.SIGN_IMAGE = #{image, jdbcType=BLOB},
                   s.SIGNED_AT  = SYSDATE
      WHEN NOT MATCHED THEN
        INSERT (SIGN_NO, APPLICATION_NO, MEMBER_NO, SIGN_IMAGE, SIGNED_AT)
        VALUES (CARD_APPLY_SIGNATURE_SEQ.NEXTVAL, #{appNo}, #{memberNo}, #{image, jdbcType=BLOB}, SYSDATE)
  """)
  int upsertSignatureFinal(@Param("appNo") Long applicationNo,
                           @Param("memberNo") Long memberNo,
                           @Param("image") byte[] imageBytes);
}
