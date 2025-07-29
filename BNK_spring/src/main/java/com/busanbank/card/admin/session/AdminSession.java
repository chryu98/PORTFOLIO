package com.busanbank.card.admin.session;

import org.springframework.stereotype.Component;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;

import com.busanbank.card.admin.dto.AdminDto;

import jakarta.servlet.http.HttpSession;

@Component
public class AdminSession {

    private static final String LOGIN_KEY = "adminLoginUser";

    public void login(AdminDto admin, HttpSession session) {
        session.setAttribute(LOGIN_KEY, admin);
    }

    public void logout(HttpSession session) {
        session.removeAttribute(LOGIN_KEY);
    }

    public boolean isLoggedIn() {
        HttpSession session = getCurrentSession();
        return session != null && session.getAttribute(LOGIN_KEY) != null;
    }

    public AdminDto getLoginUser() {
        HttpSession session = getCurrentSession();
        return session == null ? null : (AdminDto) session.getAttribute(LOGIN_KEY);
    }

    private HttpSession getCurrentSession() {
        ServletRequestAttributes attr = (ServletRequestAttributes) RequestContextHolder.getRequestAttributes();
        return attr == null ? null : attr.getRequest().getSession(false);
    }
}
