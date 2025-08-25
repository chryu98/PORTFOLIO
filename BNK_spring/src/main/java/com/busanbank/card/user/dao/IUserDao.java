package com.busanbank.card.user.dao;

import java.util.List;

import org.apache.ibatis.annotations.Insert;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Select;
import org.apache.ibatis.annotations.Update;

import com.busanbank.card.card.dto.CardDto;
import com.busanbank.card.user.dto.PushMemberDto;
import com.busanbank.card.user.dto.TermDto;
import com.busanbank.card.user.dto.TermsAgreementDto;
import com.busanbank.card.user.dto.UserCardDto;
import com.busanbank.card.user.dto.UserDto;

@Mapper
public interface IUserDao {

    @Select("SELECT * FROM member WHERE username = #{username}")
    UserDto findByUsername(String username);

    //Integer로 통일 (컨트롤러와 맞춤)
    @Select("SELECT * FROM member WHERE member_no = #{memberNo}")
    UserDto findByMemberNo(Integer memberNo);

    @Insert("""
        INSERT INTO member (
            member_no, username, password, rrn_front, rrn_gender, rrn_tail_enc,
            name, zip_code, address1, address2, role
        ) VALUES (
            member_seq.nextval, #{username}, #{password}, #{rrnFront}, #{rrnGender}, #{rrnTailEnc},
            #{name}, #{zipCode}, #{address1}, #{address2}, #{role}
        )
    """)
    int insertMember(UserDto user);
        
    @Update("""
        UPDATE member
           SET password = #{password},
               zip_code = #{zipCode},
               address1 = #{address1},
               address2 = #{address2}
         WHERE member_no = #{memberNo}
    """)
    int updateMember(UserDto user);
    
    @Select("SELECT * FROM terms")
    List<TermDto> findAllTerms();
    
    @Insert("""
        INSERT INTO terms_agreement (
            no, member_no, term_no, agreed_at, created_at, updated_at
        ) VALUES (
            terms_agreement_seq.nextval, #{memberNo}, #{termNo}, SYSDATE, SYSDATE, SYSDATE
        )
    """)
    int insertTermsAgreement(TermsAgreementDto termsAgreementDto);
    
    @Select("SELECT card_url, card_name FROM card WHERE card_no IN (1, 2, 3)")
    List<CardDto> findMyCard();
    
 // AFTER (없으면 INSERT, 있으면 UPDATE)
    @Update("""
      MERGE INTO push_member pm
      USING (SELECT #{memberNo} AS member_no, #{pushYn} AS push_yn FROM dual) src
         ON (pm.member_no = src.member_no)
      WHEN MATCHED THEN
        UPDATE SET pm.push_yn = src.push_yn,
                   pm.agreed_at = SYSDATE
      WHEN NOT MATCHED THEN
        INSERT (member_no, push_yn, agreed_at)
        VALUES (src.member_no, src.push_yn, SYSDATE)
    """)
    int upsertPushMember(PushMemberDto pushMember);
    
    @Select("""
    		  SELECT NVL(MAX(push_yn), 'N')
    		    FROM push_member
    		   WHERE member_no = #{memberNo}
    		""")
    		String findPushYn(int memberNo);
    
    @Select("SELECT c.card_no, "
    		+ "c.card_name, "
    		+ "c.card_url, "
    		+ "ca.application_no, "
    		+ "ca.status, "
    		+ "a.account_number "
    		+ "FROM card_application ca "
    		+ "JOIN card c ON ca.card_no = c.card_no "
    		+ "LEFT JOIN accounts a ON ca.member_no = a.member_no "
    		+ "WHERE ca.member_no = #{memberNo}"
    		+ "  AND ca.status IN ('SIGNED', 'APPROVED')")
    List<UserCardDto> getUserCardList(int memberNo);
    
    
    
    
}
