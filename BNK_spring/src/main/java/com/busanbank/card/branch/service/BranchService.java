package com.busanbank.card.branch.service;

import java.util.List;

import org.springframework.stereotype.Service;

import com.busanbank.card.branch.dto.BranchDto;
import com.busanbank.card.branch.mapper.BranchMapper;
import com.busanbank.card.branch.util.NaverGeocodingClient;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class BranchService {
    private final BranchMapper branchMapper;
    private final NaverGeocodingClient geocodingClient;

    public List<BranchDto> getBranchesWithCoordinates() {
        List<BranchDto> branches = branchMapper.findAllBranches();

        for (BranchDto branch : branches) {
            var coord = geocodingClient.geocode(branch.getBranchAddress());
            if (coord != null) {
                branch.setLatitude(coord.getLat());
                branch.setLongitude(coord.getLng());
            }
        }

        return branches;
    }
}