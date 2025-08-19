package com.busanbank.card.cardapply.dao;

import java.util.List;
import org.apache.ibatis.annotations.*;
import com.busanbank.card.cardapply.dto.AccountDto;

@Mapper
public interface AccountMapper {

  @Select("""
    SELECT
      AC_NO          AS acNo,
      MEMBER_NO      AS memberNo,
      CARD_NO        AS cardNo,
      ACCOUNT_NUMBER AS accountNumber,
      ACCOUNT_PW     AS accountPw,
      STATUS         AS status,
      CREATED_AT     AS createdAt,
      CLOSED_AT      AS closedAt
    FROM ACCOUNTS
    WHERE MEMBER_NO = #{memberNo}
      AND STATUS = 'ACTIVE'
    ORDER BY CREATED_AT DESC
  """)
  List<AccountDto> findActiveByMemberNo(Long memberNo);

  @Select("""
    SELECT COUNT(*)
    FROM ACCOUNTS
    WHERE MEMBER_NO = #{memberNo}
      AND STATUS = 'ACTIVE'
  """)
  int countActiveByMemberNo(Long memberNo);

  @Select("""
    SELECT
      AC_NO          AS acNo,
      MEMBER_NO      AS memberNo,
      CARD_NO        AS cardNo,
      ACCOUNT_NUMBER AS accountNumber,
      ACCOUNT_PW     AS accountPw,
      STATUS         AS status,
      CREATED_AT     AS createdAt,
      CLOSED_AT      AS closedAt
    FROM ACCOUNTS
    WHERE ACCOUNT_NUMBER = #{accountNumber}
  """)
  AccountDto findByAccountNumber(String accountNumber);

  @Select("""
    SELECT
      AC_NO          AS acNo,
      MEMBER_NO      AS memberNo,
      CARD_NO        AS cardNo,
      ACCOUNT_NUMBER AS accountNumber,
      ACCOUNT_PW     AS accountPw,
      STATUS         AS status,
      CREATED_AT     AS createdAt,
      CLOSED_AT      AS closedAt
    FROM ACCOUNTS
    WHERE AC_NO = #{acNo}
  """)
  AccountDto findById(Long acNo);

  @SelectKey(
    statement = "SELECT ACCOUNTS_SEQ.NEXTVAL FROM dual",
    keyProperty = "acNo",
    before = true,
    resultType = Long.class
  )
  @Insert("""
    INSERT INTO ACCOUNTS
      (AC_NO, MEMBER_NO, CARD_NO, ACCOUNT_NUMBER, ACCOUNT_PW, STATUS, CREATED_AT)
    VALUES
      (#{acNo},
       #{memberNo},
       #{cardNo,     jdbcType=NUMERIC},
       #{accountNumber},
       #{accountPw,  jdbcType=VARCHAR},
       #{status,     jdbcType=VARCHAR},
       SYSDATE)
  """)
  int insert(AccountDto dto);

  @Update("""
    UPDATE ACCOUNTS
       SET ACCOUNT_PW = #{accountPw, jdbcType=VARCHAR}
     WHERE AC_NO = #{acNo, jdbcType=NUMERIC}
  """)
  int updatePasswordByAcNo(@Param("acNo") Long acNo,
                           @Param("accountPw") String accountPw);

  @Update("""
    UPDATE ACCOUNTS
       SET ACCOUNT_PW = #{hash, jdbcType=VARCHAR}
     WHERE AC_NO = #{acNo, jdbcType=NUMERIC}
       AND MEMBER_NO = #{memberNo, jdbcType=NUMERIC}
       AND STATUS = 'ACTIVE'
  """)
  int updatePasswordByOwner(@Param("acNo") Long acNo,
                            @Param("memberNo") Long memberNo,
                            @Param("hash") String hash);

  @Update("""
    UPDATE ACCOUNTS
       SET STATUS = 'CLOSED',
           CLOSED_AT = SYSDATE
     WHERE AC_NO = #{acNo, jdbcType=NUMERIC}
       AND STATUS = 'ACTIVE'
  """)
  int close(Long acNo);
  
  @Select("""
		  SELECT COUNT(*)
		  FROM ACCOUNTS
		  WHERE MEMBER_NO = #{memberNo}
		    AND CREATED_AT >= SYSDATE - #{days}
		""")
		int countCreatedWithinDays(@Param("memberNo") Long memberNo,
		                           @Param("days") int days);

}
