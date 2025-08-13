// BranchController.java
package com.busanbank.card.branch.controller;

import java.util.List;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.busanbank.card.branch.dto.BranchDto;
import com.busanbank.card.branch.service.BranchService;

import lombok.RequiredArgsConstructor;

@RestController
@RequiredArgsConstructor
public class BranchController {

    private final BranchService branchService;

    // Flutter에서 호출: 항상 latitude/longitude가 채워진 상태로 내려가도록 보정
    @GetMapping("/api/branches")
    public List<BranchDto> getBranches() {
        return branchService.getAllBranches();
    }

    // (선택) 관리용: 좌표 없는 데이터 일괄 보정
    @PostMapping("/api/branches/backfill-latlng")
    public int backfill() {
        return branchService.backfillLatLngForAll();
    }
    
    @GetMapping("/api/branches/search")
    public List<BranchDto> searchBranches(@RequestParam("q") String keyword) {
    	System.out.println("검색결과"+branchService.searchBranches(keyword));
        return branchService.searchBranches(keyword);
    }
}
