package com.busanbank.card.cardapply.controller;

import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.busanbank.card.card.dao.CardDao;
import com.busanbank.card.cardapply.dao.ICardApplyDao;
import com.busanbank.card.user.dao.IUserDao;
import com.busanbank.card.user.dto.UserDto;
import com.busanbank.card.user.util.AESUtil;

@RestController
@RequestMapping("/api/card/apply")
public class CardApplyApiController {

    @Autowired
    private IUserDao userDao;
    @Autowired
    private CardDao cardDao;
    @Autowired
    private ICardApplyDao applyDao;

    @GetMapping("/customer-info")
    public ResponseEntity<?> getCustomerInfo(
            @RequestParam("cardNo") int cardNo,
            Authentication authentication) throws Exception {

        // JWT 인증이 안 됐을 경우
        if (authentication == null || authentication.getName() == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                                 .body(Map.of("error", "로그인이 필요합니다."));
        }

        // JWT에서 추출된 사용자 ID
        String username = authentication.getName();
        UserDto loginUser = userDao.findByUsername(username);

        if (loginUser == null) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                                 .body(Map.of("error", "사용자 정보 없음"));
        }

        String rrnTailEnc = AESUtil.decrypt(loginUser.getRrnTailEnc());
        String rrnBack = loginUser.getRrnGender() + rrnTailEnc;

        return ResponseEntity.ok(Map.of(
            "loginUser", loginUser,
            "rrnBack", rrnBack,
            "cardNo", cardNo
        ));
    }
}
