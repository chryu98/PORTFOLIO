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
    private String lastStatus;
    private Date createdAt;
    private Date updatedAt;

}
