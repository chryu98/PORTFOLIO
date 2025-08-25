package com.busanbank.card.branch.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class BranchDto {
	private Long branchNo;
	
	@NotBlank(message = "지점명을 입력하세요.")
    @Size(max = 100)
    private String branchName;
	
	@NotBlank(message = "주소를 입력하세요.")
    @Size(max = 200)
    private String branchAddress;
	
	@Size(max = 20)
    private String branchTel;
    private Double latitude;
    private Double longitude;
}
