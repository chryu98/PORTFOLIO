// com.busanbank.card.verify.repository.VerifyQueryRepository.java
package com.busanbank.card.verify.repository;

import com.busanbank.card.verify.entity.VerifyLog;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

@Repository
public interface VerifyQueryRepository extends JpaRepository<VerifyLog, Long> {

    @Transactional(readOnly = true)
    @Query(value = """
        SELECT 
            a.rrn_front    AS rrnFront,
            a.rrn_gender   AS rrnGender,
            a.rrn_tail_enc AS rrnTailEnc
        FROM APPLICATION_PERSON_TEMP a
        WHERE a.APPLICATION_NO = :applicationNo
        """, nativeQuery = true)
    VerifyProjection findRrnByApplicationNo(@Param("applicationNo") Long applicationNo);
}