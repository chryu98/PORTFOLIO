package com.busanbank.card.cardapply.dao;

import java.util.List;

import org.apache.ibatis.annotations.Insert;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;
import org.apache.ibatis.annotations.SelectKey;
import org.apache.ibatis.annotations.Update;

import com.busanbank.card.cardapply.dto.ApplicationPersonTempDto;
import com.busanbank.card.cardapply.dto.CardApplicationTempDto;
import com.busanbank.card.cardapply.dto.ContactInfoDto;
import com.busanbank.card.cardapply.dto.JobInfoDto;
import com.busanbank.card.cardapply.dto.PdfFilesDto;

@Mapper
public interface ICardApplyDao {

    @Insert("""
        INSERT INTO CARD_APPLICATION_TEMP (
            APPLICATION_NO, MEMBER_NO, CARD_NO, STATUS, IS_CREDIT_CARD,
            HAS_ACCOUNT_AT_KYC, IS_SHORT_TERM_MULTI, CREATED_AT, UPDATED_AT
        ) VALUES (
            CARD_APPLICATION_TEMP_SEQ.NEXTVAL, #{memberNo}, #{cardNo}, #{status},
            #{isCreditCard}, #{hasAccountAtKyc}, #{isShortTermMulti}, SYSDATE, SYSDATE
        )
    """)
    @SelectKey(statement = "SELECT CARD_APPLICATION_TEMP_SEQ.CURRVAL FROM DUAL",
               keyProperty = "applicationNo", before = false, resultType = Integer.class)
    int insertCardApplicationTemp(CardApplicationTempDto cardApplicationTemp);

    @Insert("""
        INSERT INTO APPLICATION_PERSON_TEMP (
            INFO_NO, APPLICATION_NO, NAME, NAME_ENG, RRN_FRONT, RRN_GENDER, RRN_TAIL_ENC, CREATED_AT
        ) VALUES (
            APPLICATION_PERSON_TEMP_SEQ.NEXTVAL, #{applicationNo}, #{name}, #{nameEng},
            #{rrnFront}, #{rrnGender}, #{rrnTailEnc}, SYSDATE
        )
    """)
    int insertApplicationPersonTemp(ApplicationPersonTempDto personTemp);

    @Update("""
        UPDATE APPLICATION_PERSON_TEMP
           SET EMAIL = #{email}, PHONE = #{phone}
         WHERE APPLICATION_NO = #{applicationNo}
    """)
    int updateApplicationContactTemp(ContactInfoDto contactInfo);

	@Update("UPDATE APPLICATION_PERSON_TEMP "
			+ "SET JOB = #{job}, PURPOSE = #{purpose}, FUND_SOURCE = #{fundSource} "
			+ "WHERE APPLICATION_NO = #{applicationNo}")
	int updateApplicationJobTemp(JobInfoDto jobInfo);
	
	@Select("""
		    SELECT cf.pdf_no AS pdfNo,
		           cf.pdf_name AS pdfName,
		           cf.pdf_data AS pdfData,
		           ct.is_required AS isRequired
		    FROM card_terms ct
		    JOIN pdf_files cf ON ct.pdf_no = cf.pdf_no
		    WHERE ct.card_no = #{cardNo}
		    ORDER BY ct.display_order
		""")
	List<PdfFilesDto> getTermsByCardNo(long cardNo);
	
	@Insert("INSERT INTO card_terms_agreement (agreement_no, member_no, card_no, pdf_no, agreed_at, created_at, updated_at) " +
	        "VALUES (CARD_AGREEMENT_SEQ.NEXTVAL, #{memberNo}, #{cardNo}, #{pdfNo}, SYSDATE, SYSDATE, NULL)")
	void insertAgreement(@Param("memberNo") int memberNo,
	                     @Param("cardNo") Long cardNo,
	                     @Param("pdfNo") Long pdfNo);

	
}
