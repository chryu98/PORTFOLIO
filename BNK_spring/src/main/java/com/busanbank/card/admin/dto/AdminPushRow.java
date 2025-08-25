package com.busanbank.card.admin.dto;

public class AdminPushRow {
    private Long pushNo;       // Oracle IDENTITY 반환
    private String title;
    private String content;
    private String targetType; // 'ALL' | 'MEMBER_LIST'
    private String createdBy;

    public Long getPushNo() { return pushNo; }
    public void setPushNo(Long pushNo) { this.pushNo = pushNo; }
    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }
    public String getContent() { return content; }
    public void setContent(String content) { this.content = content; }
    public String getTargetType() { return targetType; }
    public void setTargetType(String targetType) { this.targetType = targetType; }
    public String getCreatedBy() { return createdBy; }
    public void setCreatedBy(String createdBy) { this.createdBy = createdBy; }
}
