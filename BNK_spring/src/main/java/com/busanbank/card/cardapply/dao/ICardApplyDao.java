package com.busanbank.card.cardapply.dao;

import org.apache.ibatis.annotations.Insert;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.SelectKey;

import com.busanbank.card.cardapply.dto.ApplicationPersonTempDto;
import com.busanbank.card.cardapply.dto.CardApplicationTempDto;

@Mapper
public interface ICardApplyDao {

	@Insert("INSERT INTO CARD_APPLICATION_TEMP "
			+ "(APPLICATION_NO, MEMBER_NO, CARD_NO, STATUS, IS_CREDIT_CARD, "
			+ "HAS_ACCOUNT_AT_KYC, IS_SHORT_TERM_MULTI, CREATED_AT, UPDATED_AT) "
			+ "VALUES (CARD_APPLICATION_TEMP_SEQ.NEXTVAL, #{memberNo}, #{cardNo}, #{status}, "
			+ "#{isCreditCard}, #{hasAccountAtKyc}, #{isShortTermMulti}, SYSDATE, SYSDATE)")
	@SelectKey(statement = "SELECT CARD_APPLICATION_TEMP_SEQ.CURRVAL FROM DUAL",
    		   keyProperty = "applicationNo", before = false, resultType = Integer.class)
	int insertCardApplicationTemp(CardApplicationTempDto cardApplicationTemp);

	@Insert("INSERT INTO APPLICATION_PERSON_TEMP "
	          + "(INFO_NO, APPLICATION_NO, NAME, NAME_ENG, RRN_FRONT, RRN_GENDER, RRN_TAIL_ENC, CREATED_AT) "
	          + "VALUES (APPLICATION_PERSON_TEMP_SEQ.NEXTVAL, #{applicationNo}, #{name}, #{nameEng}, "
	          + "#{rrnFront}, #{rrnGender}, #{rrnTailEnc}, SYSDATE)")
	int insertApplicationPersonTemp(ApplicationPersonTempDto personTemp);
}
