package com.busanbank.card.verify.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "VERIFY_LOG")
@Getter @Setter
@NoArgsConstructor
@AllArgsConstructor
public class VerifyLog {

    @Id
    @GeneratedValue(strategy = GenerationType.SEQUENCE, generator = "verify_log_seq")
    @SequenceGenerator(
        name = "verify_log_seq",
        sequenceName = "VERIFY_LOG_SEQ",  // 오라클 시퀀스명과 정확히 일치
        allocationSize = 1
    )
    @Column(name = "LOG_NO")
    private Long logNo;

    @Column(name = "USER_NO", nullable = false, length = 50)
    private String userNo;

    @Column(name = "STATUS", nullable = false, length = 20)
    private String status;

    // ★ 길이 늘려서 ORA-12899 방지
    @Column(name = "REASON", length = 1000)
    private String reason;

    // DB DEFAULT(SYSDATE) 있을 때만 insertable=false 유지
    @Column(name = "CREATED_AT", insertable = false, updatable = false)
    private LocalDateTime createdAt;

    public VerifyLog(String userNo, String status, String reason) {
        this.userNo = userNo;
        this.status = status;
        this.reason = reason;
    }
}
