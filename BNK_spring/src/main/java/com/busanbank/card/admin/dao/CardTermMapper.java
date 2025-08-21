package com.busanbank.card.admin.dao;

import com.busanbank.card.card.dto.CardDto;
import com.busanbank.card.admin.dto.PdfFile;
import com.busanbank.card.admin.dto.CardTermDto;
import org.apache.ibatis.annotations.*;

import java.util.List;

@Mapper
public interface CardTermMapper {

    /* ========== 카드 검색 (이름/브랜드/타입) ========== */
    @Select({
        "<script>",
        "SELECT CARD_NO      AS cardNo,",
        "       CARD_NAME    AS cardName,",
        "       CARD_BRAND   AS cardBrand,",
        "       CARD_TYPE    AS cardType",
        "  FROM CARD",
        " <where>",
        "   <if test='q != null and q.trim() != \"\"'>",
        "     (LOWER(CARD_NAME) LIKE '%' || LOWER(#{q}) || '%' ",
        "       OR LOWER(CARD_BRAND) LIKE '%' || LOWER(#{q}) || '%' ",
        "       OR LOWER(CARD_TYPE)  LIKE '%' || LOWER(#{q}) || '%')",
        "   </if>",
        " </where>",
        " ORDER BY EDIT_DATE DESC NULLS LAST, REG_DATE DESC NULLS LAST",
        " FETCH FIRST 50 ROWS ONLY",
        "</script>"
    })
    List<CardDto> searchCards(@Param("q") String q);

    /* ========== PDF 검색 (이름/코드/범위/상태) ========== */
    @Select({
        "<script>",
        "SELECT PDF_NO     AS pdfNo,",
        "       PDF_NAME   AS pdfName,",
        "       TERM_SCOPE AS termScope,",
        "       IS_ACTIVE  AS isActive,",
        "       PDF_CODE   AS pdfCode",
        "  FROM PDF_FILES",
        " <where>",
        "   <if test='q != null and q.trim() != \"\"'>",
        "     (LOWER(PDF_NAME) LIKE '%' || LOWER(#{q}) || '%' ",
        "       OR LOWER(PDF_CODE) LIKE '%' || LOWER(#{q}) || '%')",
        "   </if>",
        "   <if test='scope != null and scope.trim() != \"\"'>",
        "     AND TERM_SCOPE = #{scope}",
        "   </if>",
        "   <if test='active != null and active.trim() != \"\"'>",
        "     AND IS_ACTIVE = #{active}",
        "   </if>",
        " </where>",
        " ORDER BY UPLOAD_DATE DESC",
        " FETCH FIRST 50 ROWS ONLY",
        "</script>"
    })
    List<PdfFile> searchPdfs(@Param("q") String q,
                             @Param("scope") String scope,
                             @Param("active") String active);

    /* ========== 선택 카드의 약관 목록 (이름/범위/코드 포함) ========== */
    @Select({
        "SELECT ct.CARD_NO       AS cardNo,",
        "       ct.PDF_NO        AS pdfNo,",
        "       ct.IS_REQUIRED   AS isRequired,",
        "       ct.DISPLAY_ORDER AS displayOrder,",
        "       pf.PDF_NAME      AS pdfName,",
        "       pf.TERM_SCOPE    AS termScope,",
        "       pf.IS_ACTIVE     AS isActive,",
        "       pf.PDF_CODE      AS pdfCode",
        "  FROM CARD_TERMS ct",
        "  JOIN PDF_FILES pf ON pf.PDF_NO = ct.PDF_NO",
        " WHERE ct.CARD_NO = #{cardNo}",
        " ORDER BY ct.DISPLAY_ORDER ASC, ct.PDF_NO ASC"
    })
    List<CardTermDto> listTermsByCard(@Param("cardNo") Long cardNo);

    /* ========== 매핑 등록 (MERGE로 중복시 업데이트) ========== */
    @Insert({
        "MERGE INTO CARD_TERMS T",
        "USING (SELECT ",
        "   #{cardNo, jdbcType=NUMERIC} AS CARD_NO, ",
        "   #{pdfNo,  jdbcType=NUMERIC} AS PDF_NO ",
        " FROM DUAL) S",
        "ON (T.CARD_NO = S.CARD_NO AND T.PDF_NO = S.PDF_NO)",
        "WHEN MATCHED THEN UPDATE SET",
        "  IS_REQUIRED   = NVL(#{isRequired,   jdbcType=CHAR},    T.IS_REQUIRED),",
        "  DISPLAY_ORDER = NVL(#{displayOrder, jdbcType=NUMERIC}, T.DISPLAY_ORDER)",
        "WHEN NOT MATCHED THEN INSERT (CARD_NO, PDF_NO, IS_REQUIRED, DISPLAY_ORDER)",
        "VALUES (",
        "  #{cardNo,      jdbcType=NUMERIC},",
        "  #{pdfNo,       jdbcType=NUMERIC},",
        "  NVL(#{isRequired,   jdbcType=CHAR},    'Y'),",
        "  NVL(#{displayOrder, jdbcType=NUMERIC}, (",
        "      SELECT NVL(MAX(DISPLAY_ORDER),0)+10 FROM CARD_TERMS ",
        "       WHERE CARD_NO = #{cardNo, jdbcType=NUMERIC}",
        "  ))",
        ")"
    })
    int upsertCardTerm(CardTermDto term);
    
    /* ========== 매핑 수정 (필수/순서 중 전달된 것만) ========== */
    @Update({
        "<script>",
        "UPDATE CARD_TERMS",
        "  <set>",
        "    <if test='isRequired != null'>   IS_REQUIRED = #{isRequired},   </if>",
        "    <if test='displayOrder != null'> DISPLAY_ORDER = #{displayOrder},</if>",
        "  </set>",
        "WHERE CARD_NO = #{cardNo} AND PDF_NO = #{pdfNo}",
        "</script>"
    })
    int updateCardTerm(CardTermDto term);

    /* ========== 매핑 삭제 ========== */
    @Delete("DELETE FROM CARD_TERMS WHERE CARD_NO = #{cardNo} AND PDF_NO = #{pdfNo}")
    int deleteCardTerm(@Param("cardNo") Long cardNo, @Param("pdfNo") Long pdfNo);
}
