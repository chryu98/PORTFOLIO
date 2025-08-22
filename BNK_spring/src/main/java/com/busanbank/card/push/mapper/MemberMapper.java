// src/main/java/com/busanbank/card/push/mapper/MemberMapper.java
package com.busanbank.card.push.mapper;

import org.apache.ibatis.annotations.*;

import java.util.List;

@Mapper
public interface MemberMapper {

  @Select("""
    SELECT MEMBER_NO
      FROM PUSH_MEMBER
     WHERE PUSH_YN = 'Y'
  """)
  List<Long> findConsentMemberNos();

  @Select("""
    SELECT m.MEMBER_NO
      FROM MEMBER m
      JOIN PUSH_MEMBER c ON c.MEMBER_NO = m.MEMBER_NO
     WHERE c.PUSH_YN = 'Y'
       AND TRUNC(
            MONTHS_BETWEEN(
              SYSDATE,
              TO_DATE(
                CASE
                  WHEN m.RRN_GENDER IN ('1','2','5','6') THEN '19'||m.RRN_FRONT
                  WHEN m.RRN_GENDER IN ('3','4','7','8') THEN '20'||m.RRN_FRONT
                END,'YYYYMMDD'
              )
            )/12
           ) BETWEEN NVL(#{ageFrom},0) AND NVL(#{ageTo},200)
  """)
  List<Long> findConsentMemberNosByAge(@Param("ageFrom") Integer ageFrom,
                                       @Param("ageTo") Integer ageTo);

  @Update("""
    MERGE INTO PUSH_MEMBER t
    USING (SELECT #{memberNo} AS MEMBER_NO FROM dual) s
       ON (t.MEMBER_NO = s.MEMBER_NO)
     WHEN MATCHED THEN UPDATE SET
       t.PUSH_YN   = #{pushYn},
       t.AGREED_AT = CASE WHEN #{pushYn}='Y' THEN SYSDATE ELSE t.AGREED_AT END
     WHEN NOT MATCHED THEN
       INSERT (MEMBER_NO, PUSH_YN, AGREED_AT)
       VALUES (#{memberNo}, #{pushYn},
               CASE WHEN #{pushYn}='Y' THEN SYSDATE ELSE NULL END)
  """)
  int upsertConsent(@Param("memberNo") long memberNo, @Param("pushYn") String pushYn);
}
