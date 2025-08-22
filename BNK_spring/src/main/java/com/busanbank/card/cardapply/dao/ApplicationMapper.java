package com.busanbank.card.cardapply.dao;

import org.apache.ibatis.annotations.*;

@Mapper
public interface ApplicationMapper {

    /** TEMP 레코드 잠금 (없으면 0행) */
    @Select("""
        SELECT 1
          FROM CARD_APPLICATION_TEMP
         WHERE APPLICATION_NO = #{appNo}
           FOR UPDATE
    """)
    Integer lockTemp(@Param("appNo") long appNo);

    /** FINAL 존재 여부 */
    @Select("""
        SELECT COUNT(1)
          FROM CARD_APPLICATION
         WHERE APPLICATION_NO = #{appNo}
    """)
    Integer existsFinal(@Param("appNo") long appNo);

    /** TEMP → FINAL MERGE (STATUS = READY_FOR_SIGN 로 전환) */
    @Update("""
        MERGE INTO CARD_APPLICATION tgt
        USING (
          SELECT APPLICATION_NO, MEMBER_NO, CARD_NO, STATUS,
                 IS_CREDIT_CARD, HAS_ACCOUNT_AT_KYC, IS_SHORT_TERM_MULTI,
                 CREATED_AT, UPDATED_AT
            FROM CARD_APPLICATION_TEMP
           WHERE APPLICATION_NO = #{appNo}
        ) src
        ON (tgt.APPLICATION_NO = src.APPLICATION_NO)
        WHEN MATCHED THEN UPDATE SET
          tgt.MEMBER_NO           = src.MEMBER_NO,
          tgt.CARD_NO             = src.CARD_NO,
          tgt.STATUS              = 'READY_FOR_SIGN',
          tgt.IS_CREDIT_CARD      = src.IS_CREDIT_CARD,
          tgt.HAS_ACCOUNT_AT_KYC  = src.HAS_ACCOUNT_AT_KYC,
          tgt.IS_SHORT_TERM_MULTI = src.IS_SHORT_TERM_MULTI,
          tgt.UPDATED_AT          = SYSDATE
        WHEN NOT MATCHED THEN INSERT (
          APPLICATION_NO, MEMBER_NO, CARD_NO, STATUS,
          IS_CREDIT_CARD, HAS_ACCOUNT_AT_KYC, IS_SHORT_TERM_MULTI,
          CREATED_AT, UPDATED_AT
        ) VALUES (
          src.APPLICATION_NO, src.MEMBER_NO, src.CARD_NO, 'READY_FOR_SIGN',
          src.IS_CREDIT_CARD, src.HAS_ACCOUNT_AT_KYC, src.IS_SHORT_TERM_MULTI,
          NVL(src.CREATED_AT, SYSDATE), SYSDATE
        )
    """)
    int mergeFromTemp(@Param("appNo") long appNo);

    /** TEMP 정리 */
    @Delete("""
        DELETE FROM CARD_APPLICATION_TEMP
         WHERE APPLICATION_NO = #{appNo}
    """)
    int deleteTemp(@Param("appNo") long appNo);

    // ─────────────────────────────────────────────────────────────
    // 전자서명 플로우용 (상태 조회/변경)
    // ─────────────────────────────────────────────────────────────

    /** FINAL 상태 조회 */
    @Select("""
        SELECT STATUS
          FROM CARD_APPLICATION
         WHERE APPLICATION_NO = #{appNo}
    """)
    String getFinalStatus(@Param("appNo") long appNo);

    /** FINAL 상태 업데이트 */
    @Update("""
        UPDATE CARD_APPLICATION
           SET STATUS = #{status},
               UPDATED_AT = SYSDATE
         WHERE APPLICATION_NO = #{appNo}
    """)
    int updateStatus(@Param("appNo") long appNo, @Param("status") String status);

    /** (서명 INSERT 때 사용) 멤버번호 조회 */
    @Select("""
        SELECT MEMBER_NO
          FROM CARD_APPLICATION
         WHERE APPLICATION_NO = #{appNo}
    """)
    Integer findMemberNoByAppNo(@Param("appNo") long appNo);
}
