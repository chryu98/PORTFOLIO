package com.busanbank.card.admin.dto;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

import java.util.Date;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class DropMemberRow {
    private Long applicationNo;
    private Long memberNo;
    private String name;
    private String username;
    private String gender;   // "남" / "여"
    private Integer ageYears; // 정수 나이
    private String lastStatus;
    private Date createdAt;
    private Date updatedAt;

}
