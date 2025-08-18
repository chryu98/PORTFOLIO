package com.busanbank.card.verify.entity;

import jakarta.persistence.*; 
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class VerifyLog {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long logNo;

    private String userNo;
    private String status;
    private String reason;
    private LocalDateTime createdAt = LocalDateTime.now();

    @PrePersist  // ✅ INSERT 전에 자동 실행
    protected void onCreate() {
        this.createdAt = LocalDateTime.now();
    }

    public VerifyLog(String userNo, String status, String reason) {
        this.userNo = userNo;
        this.status = status;
        this.reason = reason;
    }
}
