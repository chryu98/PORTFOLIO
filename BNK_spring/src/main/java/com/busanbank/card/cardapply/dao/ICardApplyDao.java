// src/main/java/com/busanbank/card/cardapply/dao/ICardApplyDao.java
package com.busanbank.card.cardapply.dao;

import java.util.List;

import org.apache.ibatis.annotations.Insert;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Result;
import org.apache.ibatis.annotations.Results;
import org.apache.ibatis.annotations.Select;
import org.apache.ibatis.annotations.SelectKey;
import org.apache.ibatis.annotations.Update;

import com.busanbank.card.card.mybatis.BlobToBytesTypeHandler; // TypeHandler
import com.busanbank.card.cardapply.dto.AddressDto;
import com.busanbank.card.cardapply.dto.ApplicationPersonDto;
import com.busanbank.card.cardapply.dto.ApplicationPersonTempDto;
import com.busanbank.card.cardapply.dto.CardApplicationDto;
import com.busanbank.card.cardapply.dto.CardApplicationTempDto;
import com.busanbank.card.cardapply.dto.CardOptionDto;
import com.busanbank.card.cardapply.dto.ContactInfoDto;
import com.busanbank.card.cardapply.dto.JobInfoDto;
import com.busanbank.card.cardapply.dto.PdfBytesRow;
import com.busanbank.card.cardapply.dto.PdfFilesDto;

@Mapper
public interface ICardApplyDao {

	/* -------------------- 신청 temp -------------------- */

	@Insert("""
			    INSERT INTO CARD_APPLICATION_TEMP (
			        APPLICATION_NO, MEMBER_NO, CARD_NO, STATUS, IS_CREDIT_CARD,
			        HAS_ACCOUNT_AT_KYC, IS_SHORT_TERM_MULTI, CREATED_AT, UPDATED_AT
			    ) VALUES (
			        CARD_APPLICATION_TEMP_SEQ.NEXTVAL, #{memberNo}, #{cardNo}, #{status},
			        #{isCreditCard}, #{hasAccountAtKyc}, #{isShortTermMulti}, SYSDATE, SYSDATE
			    )
			""")
	@SelectKey(statement = "SELECT CARD_APPLICATION_TEMP_SEQ.CURRVAL FROM DUAL", keyProperty = "applicationNo", before = false, resultType = Integer.class)
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

	@Update("""
			    UPDATE APPLICATION_PERSON_TEMP
			       SET JOB = #{job}, PURPOSE = #{purpose}, FUND_SOURCE = #{fundSource}
			     WHERE APPLICATION_NO = #{applicationNo}
			""")
	int updateApplicationJobTemp(JobInfoDto jobInfo);

	/* -------------------- 약관 / PDF -------------------- */

	// 목록(메타만: pdf_data 제외)
	@Select("""
			    SELECT cf.pdf_no        AS pdfNo,
			           cf.pdf_name      AS pdfName,
			           ct.is_required   AS isRequired
			      FROM card_terms ct
			      JOIN pdf_files cf ON ct.pdf_no = cf.pdf_no
			     WHERE ct.card_no = #{cardNo}
			     ORDER BY ct.display_order
			""")
	List<PdfFilesDto> getTermsByCardNo(@Param("cardNo") long cardNo);

	// 단건(필요시만 사용) : pdf_data 포함 → TypeHandler로 BLOB→byte[]
	@Select("""
			    SELECT pdf_no   AS pdfNo,
			           pdf_name AS pdfName,
			           pdf_data AS pdfData
			      FROM pdf_files
			     WHERE pdf_no = #{pdfNo}
			""")
	@Results(id = "PdfWithDataMap", value = { @Result(column = "pdfNo", property = "pdfNo"),
			@Result(column = "pdfName", property = "pdfName"),
			@Result(column = "pdfData", property = "pdfData", typeHandler = BlobToBytesTypeHandler.class) })
	PdfFilesDto getPdfByNo(@Param("pdfNo") long pdfNo);

	// ★ 스트리밍용: pdf_data만 딱 한 컬럼 (가장 빠름)
	@Select("""
			    SELECT pdf_data AS data
			      FROM pdf_files
			     WHERE pdf_no = #{pdfNo}
			""")
	@Results(value = { @Result(column = "data", property = "data", typeHandler = BlobToBytesTypeHandler.class) })
	PdfBytesRow getPdfRawRowByNo(@Param("pdfNo") long pdfNo);

	/* -------------------- 동의/주소/옵션 -------------------- */

	@Insert("""
			    INSERT INTO card_terms_agreement (
			        agreement_no, member_no, card_no, pdf_no, agreed_at, created_at, updated_at
			    ) VALUES (
			        CARD_AGREEMENT_SEQ.NEXTVAL, #{memberNo}, #{cardNo}, #{pdfNo}, SYSDATE, SYSDATE, NULL
			    )
			""")
	void insertAgreement(@Param("memberNo") int memberNo, @Param("cardNo") Long cardNo, @Param("pdfNo") Long pdfNo);

//	상태 추가
	// 상태 업데이트 (memberNo + cardNo 로 찾음)
	@Update("""
	    UPDATE card_application_temp
	    SET status = #{status}, updated_at = SYSDATE
	    WHERE member_no = #{memberNo}
	      AND card_no   = #{cardNo}
	""")
	void updateApplicationStatus(@Param("memberNo") int memberNo,
	                             @Param("cardNo") Long cardNo,
	                             @Param("status") String status);
	@Select("""
			    SELECT zip_code, address1, address2
			      FROM member
			     WHERE member_no = #{memberNo}
			""")
	AddressDto findAddressByMemberNo(@Param("memberNo") int memberNo);

	@Update("""
			    UPDATE APPLICATION_PERSON_TEMP
			       SET zip_code     = #{zipCode},
			           address1     = #{address1},
			           address2     = #{address2},
			           address_type = #{addressType}
			     WHERE APPLICATION_NO = #{applicationNo}
			""")
	int updateApplicationAddressTemp(AddressDto address);

	@Update("""
			    UPDATE APPLICATION_PERSON_TEMP
			       SET card_brand    = #{cardBrand},
			           postpaid_card = #{postpaid}
			     WHERE APPLICATION_NO = #{applicationNo}
			""")
	int updateApplicationCardOptionTemp(CardOptionDto cardOption);

	// 신용카드 신청 전체 조회
	@Select("SELECT ca.*, c.card_name AS cardName " +
	        "FROM card_application ca " +
	        "JOIN card c ON ca.card_no = c.card_no " +
	        "WHERE ca.is_credit_card = 'Y'")
	List<CardApplicationDto> findCreditCard();

	// 여러 신청 번호에 해당하는 신청자 정보 조회
	@Select("<script>" + "SELECT * FROM application_person " + "WHERE application_no IN "
			+ "<foreach item='no' collection='list' open='(' separator=',' close=')'>" + "#{no}" + "</foreach>"
			+ "</script>")
	List<ApplicationPersonDto> findPersonForApplications(List<Integer> applicationNos);

	// 상태 변경(승인/반려)
	@Update("""
		    UPDATE CARD_APPLICATION
		    SET status = #{status},
		        approval_reason = CASE WHEN #{status} = 'APPROVED' THEN #{reason} ELSE NULL END,
		        rejection_reason = CASE WHEN #{status} = 'REJECTED' THEN #{reason} ELSE NULL END,
		        updated_at = SYSDATE
		    WHERE APPLICATION_NO = #{applicationNo}
		""")
	int updateStatusWithReason(@Param("applicationNo") Integer applicationNo,
							   @Param("status") String status,
							   @Param("reason") String reason);
			 
	
	// 카드 앱플리케이션 탬프 (임시 테이블) 상태 변경
	@Update("""
		    UPDATE card_application_temp
		       SET status = #{status}, updated_at = SYSDATE
		     WHERE application_no = #{applicationNo}
		""")
	int updateApplicationStatusByAppNo(@Param("applicationNo") Integer applicationNo,
	                                   @Param("status") String status);

	
	@Update("""
		    UPDATE card_application_temp
		       SET status = #{status}, updated_at = SYSDATE
		     WHERE application_no = #{applicationNo}
		""")
	int updateApplicationStatusByAppNo2(@Param("applicationNo") Long applicationNo,
            @Param("status") String status);


	
}
