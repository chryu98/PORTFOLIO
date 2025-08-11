package com.busanbank.card.branch.mapper;

import java.util.List;

import org.apache.ibatis.annotations.Mapper;

import com.busanbank.card.branch.dto.BranchDto;

@Mapper
public interface BranchMapper {
	List<BranchDto> findAllBranches();
}
