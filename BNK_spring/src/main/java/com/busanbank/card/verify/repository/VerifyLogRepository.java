package com.busanbank.card.verify.repository;

import com.busanbank.card.verify.entity.VerifyLog;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface VerifyLogRepository extends JpaRepository<VerifyLog, Long> {
}
