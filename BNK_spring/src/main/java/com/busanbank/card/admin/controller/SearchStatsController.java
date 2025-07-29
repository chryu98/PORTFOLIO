package com.busanbank.card.admin.controller;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.*;

import java.util.*;

@RestController
@RequestMapping("/admin/Search/stats")
public class SearchStatsController {

    private final JdbcTemplate jdbcTemplate;

    public SearchStatsController(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    // 1. 회원/비회원 검색 비율
    @GetMapping("/userType")
    public Map<String, Object> getUserTypeStats() {
        String sql = """
            SELECT
              CASE WHEN MEMBER_NO IS NULL THEN 'nonmember' ELSE 'member' END AS user_type,
              COUNT(*) AS cnt
            FROM SEARCH_LOG
            GROUP BY CASE WHEN MEMBER_NO IS NULL THEN 'nonmember' ELSE 'member' END
        """;
        Map<String, Object> result = new HashMap<>(Map.of("member", 0, "nonmember", 0));
        jdbcTemplate.queryForList(sql).forEach(row -> {
            String type = (String) row.get("user_type");
            int count = ((Number) row.get("cnt")).intValue();
            result.put(type, count);
        });
        return result;
    }

    // 2. 인기 검색어 (회원 / 비회원)
    @GetMapping("/topKeywords")
    public List<Map<String, Object>> getTopKeywords(@RequestParam("type") String type) {
        String condition = "MEMBER_NO IS NULL";
        if ("member".equalsIgnoreCase(type)) {
            condition = "MEMBER_NO IS NOT NULL";
        }
        String sql = """
            SELECT KEYWORD, COUNT(*) AS CNT
            FROM SEARCH_LOG
            WHERE %s AND KEYWORD IS NOT NULL
            GROUP BY KEYWORD
            ORDER BY CNT DESC
            FETCH FIRST 10 ROWS ONLY
        """.formatted(condition);

        return jdbcTemplate.query(sql, (rs, i) -> Map.of(
                "keyword", rs.getString("KEYWORD"),
                "count", rs.getInt("CNT")
        ));
    }

    // 3. 추천어 검색 전환율
    @GetMapping("/recommendedConversionRate")
    public Map<String, Object> getRecommendedConversionRate() {
        String sql = """
            SELECT
              (SELECT COUNT(*) FROM SEARCH_LOG WHERE SEARCH_DATE >= TRUNC(SYSDATE - 30)) AS total_searches,
              (SELECT COUNT(*) FROM SEARCH_LOG WHERE SEARCH_DATE >= TRUNC(SYSDATE - 30) AND IS_RECOMMENDED = 'Y') AS recommended_searches
            FROM DUAL
        """;
        return jdbcTemplate.queryForObject(sql, (rs, i) -> {
            long total = rs.getLong("total_searches");
            long recommended = rs.getLong("recommended_searches");
            double rate = total == 0 ? 0 : (double) recommended / total * 100;
            return Map.of(
                    "total", total,
                    "recommended", recommended,
                    "conversionRate", Math.round(rate * 100) / 100.0
            );
        });
    }

    // 4. 시간대별 검색 건수
    @GetMapping("/searchByHour")
    public List<Map<String, Object>> getSearchByHour(@RequestParam("period") String period) {
        String dateCondition = switch (period) {
            case "day"     -> "SYSDATE - 1";
            case "week"    -> "SYSDATE - 7";
            case "month"   -> "ADD_MONTHS(SYSDATE, -1)";
            case "6months" -> "ADD_MONTHS(SYSDATE, -6)";
            case "year"    -> "ADD_MONTHS(SYSDATE, -12)";
            case "5years"  -> "ADD_MONTHS(SYSDATE, -60)";
            case "all"     -> "TO_DATE('1900-01-01', 'YYYY-MM-DD')";
            default        -> "SYSDATE - 1";
        };

        String sql = """
            SELECT TO_CHAR(SEARCH_DATE, 'HH24') AS hour, COUNT(*) AS cnt
            FROM SEARCH_LOG
            WHERE SEARCH_DATE >= %s
            GROUP BY TO_CHAR(SEARCH_DATE, 'HH24')
            ORDER BY hour ASC
        """.formatted(dateCondition);

        return jdbcTemplate.query(sql, (rs, i) -> Map.of(
                "hour", rs.getString("hour"),
                "count", rs.getInt("cnt")
        ));
    }

    // 5. 나이대별 카드 조회 수
    @GetMapping("/cardViewsByAgeGroup")
    public Map<String, Integer> getCardViewsByAgeGroup() {
        String sql = """
            SELECT age_group, COUNT(*) AS total_views
            FROM (
                SELECT
                  FLOOR((
                    TO_NUMBER(SUBSTR(m.RRN_FRONT, 1, 2)) +
                    CASE WHEN TO_NUMBER(SUBSTR(m.RRN_FRONT, 1, 2)) > TO_NUMBER(TO_CHAR(SYSDATE, 'YY'))
                         THEN 1900 ELSE 2000 END
                    - EXTRACT(YEAR FROM SYSDATE)
                  ) / -10) * 10 AS age_group
                FROM MEMBER m
                JOIN SEARCH_LOG s ON s.MEMBER_NO = m.MEMBER_NO
            )
            GROUP BY age_group
            ORDER BY age_group
        """;
        Map<String, Integer> result = new LinkedHashMap<>();
        jdbcTemplate.query(sql, rs -> {
            int age = rs.getInt("age_group");
            int views = rs.getInt("total_views");
            result.put(age + "대", views);
        });
        return result;
    }

    // 6. 성별별 카드 조회 수
    @GetMapping("/cardViewsByGender")
    public Map<String, Integer> getCardViewsByGender() {
        String sql = """
            SELECT gender, COUNT(*) AS view_count
            FROM (
                SELECT
                  CASE
                    WHEN m.RRN_GENDER IN ('1', '3') THEN '남자'
                    WHEN m.RRN_GENDER IN ('2', '4') THEN '여자'
                    ELSE '기타'
                  END AS gender
                FROM MEMBER m
                JOIN SEARCH_LOG s ON s.MEMBER_NO = m.MEMBER_NO
            )
            GROUP BY gender
        """;
        Map<String, Integer> result = new HashMap<>();
        jdbcTemplate.query(sql, rs -> {
            result.put(rs.getString("gender"), rs.getInt("view_count"));
        });
        return result;
    }

    // 7. 카드 조회 수 TOP 5
    @GetMapping("/topCards")
    public List<Map<String, Object>> getTopCards() {
        String sql = """
            SELECT CARD_NAME, VIEW_COUNT
            FROM CARD
            ORDER BY VIEW_COUNT DESC
            FETCH FIRST 5 ROWS ONLY
        """;
        return jdbcTemplate.query(sql, (rs, i) -> Map.of(
                "cardName", rs.getString("CARD_NAME"),
                "viewCount", rs.getInt("VIEW_COUNT")
        ));
    }
}
