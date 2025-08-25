// BranchService.java
package com.busanbank.card.branch.service;

import java.math.BigDecimal;
import java.util.List;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.busanbank.card.branch.dto.BranchDto;
import com.busanbank.card.branch.mapper.BranchMapper;
import com.busanbank.card.branch.util.GovGeocodingClient;
import com.busanbank.card.branch.util.GovGeocodingClient.LatLng;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Service
@RequiredArgsConstructor
@Slf4j
public class BranchService {

    private final BranchMapper branchMapper;
    private final GovGeocodingClient geocodingClient;

    /**
     * 전체 지점 조회.
     * 좌표가 비어있는 행은 실시간으로 지오코딩하여 DB 업데이트 후 응답에 좌표를 포함.
     */
    @Transactional
    public List<BranchDto> getAllBranches() {
        List<BranchDto> list = branchMapper.selectAll();

        for (BranchDto b : list) {
            if (b.getLatitude() == null || b.getLongitude() == null) {
                LatLng ll = geocodingClient.geocode(b.getBranchAddress());
                if (ll != null) {
                    branchMapper.updateBranchLocation(b.getBranchNo(), ll.getLat(), ll.getLng());
                    b.setLatitude(ll.getLat());
                    b.setLongitude(ll.getLng());
                    log.info("Geocoded & updated: {} ({}) -> {}, {}", b.getBranchName(), b.getBranchNo(), ll.getLat(), ll.getLng());
                } else {
                    log.warn("Geocode failed: {} ({}) - address: {}", b.getBranchName(), b.getBranchNo(), b.getBranchAddress());
                }
            }
        }
        return list;
    }

    /**
     * (선택) 좌표 없는 지점만 일괄 보정하는 배치성 메서드.
     * 관리용 API에서 한 번 호출해두면, 이후에는 실시간 지오코딩 빈도를 줄일 수 있음.
     */
    @Transactional
    public int backfillLatLngForAll() {
        int success = 0;
        List<BranchDto> targets = branchMapper.selectAllWithoutLatLng();
        for (BranchDto b : targets) {
            LatLng ll = geocodingClient.geocode(b.getBranchAddress());
            if (ll != null) {
                int updated = branchMapper.updateBranchLocation(b.getBranchNo(), ll.getLat(), ll.getLng());
                if (updated > 0) success += 1;
            }
        }
        log.info("Backfill completed. success={}/{}", success, targets.size());
        return success;
    }
    
    
    public List<BranchDto> searchBranches(String keyword) {
        return branchMapper.searchBranches("%" + keyword + "%");
    }
    
    @Transactional(readOnly = true)
    public Paged<BranchDto> list(String q, int page, int size) {
        page = Math.max(page, 1);
        size = Math.max(size, 10);
        int offset = (page - 1) * size;

        long total = branchMapper.count(q);
        var items = branchMapper.selectPage(q, offset, size);
        return new Paged<>(items, page, size, total);
    }

    @Transactional
    public void create(BranchDto dto) {
        // 좌표가 없으면 주소로 보정
        if ((dto.getLatitude() == null || dto.getLongitude() == null)
            && dto.getBranchAddress() != null && !dto.getBranchAddress().isBlank()) {

            var latLng = geocodingClient.geocode(dto.getBranchAddress());
            if (latLng != null) {
                dto.setLatitude(latLng.getLat());
                dto.setLongitude(latLng.getLng());
            }
        }
        branchMapper.insert(dto);
    }

    @Transactional
    public void delete(Long id) {
    	branchMapper.deleteById(id);
    }

    // 간단한 페이지 응답용 DTO
    public record Paged<T>(java.util.List<T> items, int page, int size, long total) {
        // JSP EL이 인식할 수 있도록 JavaBean 게터 추가
        public java.util.List<T> getItems() { return items; }
        public int getPage() { return page; }
        public int getSize() { return size; }
        public long getTotal() { return total; }
        public long getTotalPages() { return (total + size - 1) / size; }
    }
}
