package com.busanbank.card.branch.dto;

import lombok.Data;

@Data
public class BranchDto {
	private Long branchNo;
    private String branchName;
    private String branchAddress;
    private String branchTel;
    private Double latitude;
    private Double longitude;
}
