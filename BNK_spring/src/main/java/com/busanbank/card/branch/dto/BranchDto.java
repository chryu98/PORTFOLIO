package com.busanbank.card.branch.dto;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class BranchDto {
	private Long branchNo;
    private String branchName;
    private String branchAddress;
    private String branchTel;
    private Double latitude;
    private Double longitude;
}
