package com.busanbank.card.faq.dao;

import com.busanbank.card.faq.dto.FaqDto;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.List;

@Repository
public class FaqDao {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    public int countFaqs(String keyword) {
        String sql = """
            SELECT COUNT(*)
              FROM FAQ
             WHERE FAQ_QUESTION LIKE ?
                OR FAQ_ANSWER LIKE ?
        """;

        String likeKeyword = "%" + keyword + "%";

        return jdbcTemplate.queryForObject(
                sql,
                Integer.class,
                likeKeyword,
                likeKeyword
        );
    }

    public List<FaqDto> searchFaqsWithPaging(String keyword, int startRow, int endRow) {
        String sql = """
            SELECT * FROM (
                SELECT ROWNUM AS rnum, A.* 
                  FROM (
                        SELECT FAQ_NO, FAQ_QUESTION, FAQ_ANSWER,
                               REG_DATE, WRITER, ADMIN, CATTEGORY
                          FROM FAQ
                         WHERE FAQ_QUESTION LIKE ?
                            OR FAQ_ANSWER LIKE ?
                         ORDER BY FAQ_NO
                       ) A
                 WHERE ROWNUM <= ?
            )
            WHERE rnum >= ?
        """;

        String likeKeyword = "%" + keyword + "%";

        return jdbcTemplate.query(
                sql,
                (rs, rowNum) -> mapRow(rs),
                likeKeyword,
                likeKeyword,
                endRow,
                startRow
        );
    }

    public List<FaqDto> getAllFaqs() {
        String sql = """
            SELECT FAQ_NO, FAQ_QUESTION, FAQ_ANSWER,
                   REG_DATE, WRITER, ADMIN, CATTEGORY
              FROM FAQ
            ORDER BY FAQ_NO
        """;

        return jdbcTemplate.query(sql, (rs, rowNum) -> mapRow(rs));
    }

    public void insertFaq(FaqDto dto) {
        String sql = """
            INSERT INTO FAQ (
                FAQ_NO, FAQ_QUESTION, FAQ_ANSWER,
                REG_DATE, WRITER, ADMIN, CATTEGORY
            )
            VALUES (
                FAQ_SEQ.NEXTVAL, ?, ?, SYSDATE, ?, ?, ?
            )
        """;

        jdbcTemplate.update(sql,
            dto.getFaqQuestion(),
            dto.getFaqAnswer(),
            dto.getWriter(),
            dto.getAdmin(),
            dto.getCattegory()
        );
    }

    public void updateFaq(FaqDto dto) {
        String sql = """
            UPDATE FAQ
               SET FAQ_QUESTION = ?,
                   FAQ_ANSWER = ?,
                   WRITER = ?,
                   ADMIN = ?,
                   CATTEGORY = ?
             WHERE FAQ_NO = ?
        """;

        jdbcTemplate.update(sql,
            dto.getFaqQuestion(),
            dto.getFaqAnswer(),
            dto.getWriter(),
            dto.getAdmin(),
            dto.getCattegory(),
            dto.getFaqNo()
        );
    }

    public void deleteFaq(Long faqNo) {
        String sql = """
            DELETE FROM FAQ
             WHERE FAQ_NO = ?
        """;

        jdbcTemplate.update(sql, faqNo);
    }

    private FaqDto mapRow(ResultSet rs) throws SQLException {
        return new FaqDto(
            (int) rs.getLong("FAQ_NO"),
            rs.getString("FAQ_QUESTION"),
            rs.getString("FAQ_ANSWER"),
            rs.getTimestamp("REG_DATE"),   // getDate() → getTimestamp()로 교체
            rs.getString("WRITER"),
            rs.getString("ADMIN"),
            rs.getString("CATTEGORY")
        );
    }

    public FaqDto getFaqById(int faqNo) {
        String sql = """
            SELECT FAQ_NO, FAQ_QUESTION, FAQ_ANSWER,
                   REG_DATE, WRITER, ADMIN, CATTEGORY
              FROM FAQ
             WHERE FAQ_NO = ?
        """;

        return jdbcTemplate.queryForObject(
            sql,
            (rs, rowNum) -> mapRow(rs),
            faqNo
        );
    }

    public List<FaqDto> searchFaqs(String keyword) {
        String sql = """
            SELECT FAQ_NO, FAQ_QUESTION, FAQ_ANSWER,
                   REG_DATE, WRITER, ADMIN, CATTEGORY
              FROM FAQ
             WHERE FAQ_QUESTION LIKE ?
                OR FAQ_ANSWER LIKE ?
            ORDER BY FAQ_NO
        """;

        String likeKeyword = "%" + keyword + "%";

        return jdbcTemplate.query(
            sql,
            (rs, rowNum) -> mapRow(rs),
            likeKeyword,
            likeKeyword
        );
    }
    
    public int countFaqsAdvanced(String keyword, String category) {
        StringBuilder sql = new StringBuilder("""
            SELECT COUNT(*)
              FROM FAQ
             WHERE (FAQ_QUESTION LIKE ? OR FAQ_ANSWER LIKE ?)
        """);
        var params = new java.util.ArrayList<Object>();
        String like = "%" + (keyword == null ? "" : keyword) + "%";
        params.add(like); params.add(like);

        if (category != null && !category.isBlank() && !"전체".equals(category)) {
            sql.append(" AND CATTEGORY = ? ");
            params.add(category);
        }
        return jdbcTemplate.queryForObject(sql.toString(), Integer.class, params.toArray());
    }

    /** sort: "latest" | "popular" (그 외는 popular 처리), 1-based ROWNUM 페이징 유지 */
    public List<FaqDto> searchFaqsWithPagingAdvanced(
            String keyword, String category, String sort, int startRow, int endRow) {

        String orderBy = "LATEST".equalsIgnoreCase(sort)
                ? " REG_DATE DESC "
                : " NVL(HELPFUL_CNT,0) DESC, REG_DATE DESC "; // popular 기본

        StringBuilder inner = new StringBuilder("""
            SELECT FAQ_NO, FAQ_QUESTION, FAQ_ANSWER,
                   REG_DATE, WRITER, ADMIN, CATTEGORY, NVL(HELPFUL_CNT,0) AS HELPFUL_CNT
              FROM FAQ
             WHERE (FAQ_QUESTION LIKE ? OR FAQ_ANSWER LIKE ?)
        """);
        var params = new java.util.ArrayList<Object>();
        String like = "%" + (keyword == null ? "" : keyword) + "%";
        params.add(like); params.add(like);

        if (category != null && !category.isBlank() && !"전체".equals(category)) {
            inner.append(" AND CATTEGORY = ? ");
            params.add(category);
        }

        inner.append(" ORDER BY ").append(orderBy);

        String sql = """
            SELECT * FROM (
                SELECT ROWNUM AS rnum, A.* FROM ( %s ) A WHERE ROWNUM <= ?
            ) WHERE rnum >= ?
        """.formatted(inner);

        params.add(endRow);
        params.add(startRow);

        return jdbcTemplate.query(sql, (rs, i) -> mapRow(rs), params.toArray());
    }

}
