package com.busanbank.card.feedback.repo;

import com.busanbank.card.feedback.entity.CardFeedback;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Date;
import java.util.List;

public interface CardFeedbackRepository extends JpaRepository<CardFeedback, Long> {

    /** 감성 라벨 카운트 (분석된 건만) */
    @Query("""
      SELECT cf.sentimentLabel, COUNT(cf)
      FROM CardFeedback cf
      WHERE cf.analyzedAt IS NOT NULL
      GROUP BY cf.sentimentLabel
    """)
    List<Object[]> countBySentiment();

    /** 키워드 TOP N (Oracle 네이티브) */
    @Query(value = """
      SELECT keyword, cnt FROM (
        SELECT REGEXP_SUBSTR(ai_keywords, '[^,]+', 1, LEVEL) AS keyword,
               COUNT(*) AS cnt
          FROM card_feedback
         WHERE ai_keywords IS NOT NULL
        CONNECT BY REGEXP_SUBSTR(ai_keywords, '[^,]+', 1, LEVEL) IS NOT NULL
               AND PRIOR feedback_no = feedback_no
               AND PRIOR SYS_GUID() IS NOT NULL
         GROUP BY REGEXP_SUBSTR(ai_keywords, '[^,]+', 1, LEVEL)
         ORDER BY cnt DESC
      ) WHERE ROWNUM <= :topN
    """, nativeQuery = true)
    List<Object[]> topKeywords(@Param("topN") int topN);

    /** 이상치(Y) 최근순 */
    @Query("""
      SELECT cf FROM CardFeedback cf
      WHERE cf.inconsistencyFlag = 'Y'
      ORDER BY cf.createdAt DESC
    """)
    List<CardFeedback> findInconsistencies();

    /** 전체 평점 평균 */
    @Query("SELECT AVG(cf.rating) FROM CardFeedback cf")
    Double avgRatingAll();

    /** 기간 조회 */
    @Query("""
      SELECT cf FROM CardFeedback cf
      WHERE cf.createdAt >= :start AND cf.createdAt < :end
      ORDER BY cf.createdAt DESC
    """)
    List<CardFeedback> findRange(@Param("start") Date start, @Param("end") Date end);

    /** 최근 20개 (파생 메서드) */
    List<CardFeedback> findTop20ByOrderByCreatedAtDesc();

    /** 가변 개수 필요 시 Page 사용 */
    Page<CardFeedback> findAllByOrderByCreatedAtDesc(Pageable pageable);

    /** 분석 완료 데이터 범위 조회(선택) */
    @Query("""
    		  select f from CardFeedback f
    		   where f.analyzedAt is not null
    		     and (:from is null or f.createdAt >= :from)
    		     and (:to   is null or f.createdAt <  :to)
    		   order by f.createdAt desc
    		""")
    List<CardFeedback> findAnalyzedBetween(@Param("from") Date from, @Param("to") Date to);

    /** 분석 완료만 조회(Insights 집계용) */
    List<CardFeedback> findByAnalyzedAtIsNotNull();
}
