package com.busanbank.card.branch.mapper;

import java.util.List;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import com.busanbank.card.branch.dto.BranchDto;

@Mapper
public interface BranchMapper {

    List<BranchDto> selectAll();

    // 좌표가 비어있는 지점만
    List<BranchDto> selectAllWithoutLatLng();

    // 좌표 업데이트
    int updateBranchLocation(
            @Param("branchNo") Long branchNo,
            @Param("latitude") Double latitude,
            @Param("longitude") Double longitude
    );
    
    List<BranchDto> searchBranches(@Param("keyword") String keyword);
    
    long count(@Param("q") String q);
    List<BranchDto> selectPage(@Param("q") String q,
                               @Param("offset") int offset,
                               @Param("size") int size);
    BranchDto findById(@Param("id") Long id);
    int insert(BranchDto dto);
    int deleteById(@Param("id") Long id);
}