// com.busanbank.card.verify.service.ExpectedRrnService.java
package com.busanbank.card.verify.service;

import com.busanbank.card.user.util.AESUtil;
import com.busanbank.card.verify.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class ExpectedRrnService {
    private final VerifyQueryRepository repo;

    /**
     * applicationNo로 DB에서 주민번호 구성.
     * @param applicationNo 신청번호
     * @param masked true면 YYMMDD-G****** 형태(권장), false면 YYMMDD-GXXXXXX(전체 비교)
     */
    public String buildExpectedRrn(Long applicationNo, boolean masked) {
        VerifyProjection p = repo.findRrnByApplicationNo(applicationNo);
        if (p == null) throw new IllegalArgumentException("신청번호에 해당하는 사용자 없음");

        String front  = nz(p.getRrnFront());
        String gender = nz(p.getRrnGender());

        if (front.length() != 6)  throw new IllegalStateException("rrnFront 형식 오류");
        if (gender.length() != 1) throw new IllegalStateException("rrnGender 형식 오류");

        String tail = "******";
        if (!masked) {
            try {
                String dec = AESUtil.decrypt(p.getRrnTailEnc()); // 6자리 평문
                if (dec == null || dec.length() != 6) {
                    throw new IllegalStateException("rrnTail 복호화 실패/길이 오류");
                }
                tail = dec;
            } catch (Exception e) {
                throw new IllegalStateException("rrnTail 복호화 실패", e);
            }
        }
        return front + "-" + gender + tail;
    }

    private static String nz(String s) { return s == null ? "" : s.trim(); }
}
