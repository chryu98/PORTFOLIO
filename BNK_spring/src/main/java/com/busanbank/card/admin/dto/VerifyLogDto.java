package com.busanbank.card.admin.dto;

import java.util.Date;

public class VerifyLogDto {
    private Long logNo;
    private String userNo;
    private String status;
    private String reason;
    private Date createdAt;

    // Getter & Setter
    public Long getLogNo() {
        return logNo;
    }
    public void setLogNo(Long logNo) {
        this.logNo = logNo;
    }

    public String getUserNo() {
        return userNo;
    }
    public void setUserNo(String userNo) {
        this.userNo = userNo;
    }

    public String getStatus() {
        return status;
    }
    public void setStatus(String status) {
        this.status = status;
    }

    public String getReason() {
        return reason;
    }
    public void setReason(String reason) {
        this.reason = reason;
    }

    public Date getCreatedAt() {
        return createdAt;
    }
    public void setCreatedAt(Date createdAt) {
        this.createdAt = createdAt;
    }
}
