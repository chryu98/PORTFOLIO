package com.busanbank.card.branch.controller;

import java.util.List;

import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.busanbank.card.branch.dto.BranchDto;
import com.busanbank.card.branch.service.BranchService;

import lombok.RequiredArgsConstructor;

@CrossOrigin(origins = "*")
@RestController
@RequestMapping("/api/branches")
@RequiredArgsConstructor
public class BranchController {
    private final BranchService branchService;

    @GetMapping
    public List<BranchDto> getBranches() {
    	System.out.println(branchService.getBranchesWithCoordinates());
        return branchService.getBranchesWithCoordinates();
    }	
}