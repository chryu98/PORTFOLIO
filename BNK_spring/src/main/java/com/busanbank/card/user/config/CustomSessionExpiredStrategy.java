package com.busanbank.card.user.config;

import java.io.IOException;

import org.springframework.http.MediaType;
import org.springframework.security.web.session.SessionInformationExpiredEvent;
import org.springframework.security.web.session.SessionInformationExpiredStrategy;
import org.springframework.stereotype.Component;

import jakarta.servlet.http.HttpServletResponse;

@Component
public class CustomSessionExpiredStrategy implements SessionInformationExpiredStrategy {

	@Override
    public void onExpiredSessionDetected(SessionInformationExpiredEvent event) throws IOException {
        HttpServletResponse response = event.getResponse();

        response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
        response.setContentType(MediaType.APPLICATION_JSON_VALUE);
        String json = "{\"message\":\"다른 위치에서 로그인되어 로그아웃 되었습니다.\"}";
        response.getWriter().write(json);
        response.getWriter().flush();
    }

}
