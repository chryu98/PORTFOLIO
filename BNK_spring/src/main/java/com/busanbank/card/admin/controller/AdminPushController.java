package com.busanbank.card.admin.controller;

import com.busanbank.card.admin.service.AdminPushService;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@Controller
@RequestMapping("/admin/push")
public class AdminPushController {
    private final AdminPushService service;

    public AdminPushController(AdminPushService service) { this.service = service; }

    @GetMapping
    public String page() {
        // 뷰리졸버(prefix/suffix)가 처리: /WEB-INF/views/ + admin/push/admin_push + .jsp
        return "admin/push/admin_push";
    }

    @PostMapping("/api/preview")
    @ResponseBody
    public Map<String,Object> preview(@RequestBody Map<String,Object> body) {
        String targetType = String.valueOf(body.getOrDefault("targetType","ALL"));
        @SuppressWarnings("unchecked")
        List<Number> list = (List<Number>) body.get("memberList");
        List<Long> memberList = (list == null) ? List.of() : list.stream().map(Number::longValue).toList();
        int eligible = service.previewCount(targetType, memberList);
        return Map.of("eligible", eligible, "targetType", targetType);
    }

    @PostMapping("/api/send")
    @ResponseBody
    public Map<String,Object> send(@RequestBody Map<String,Object> body,
                                   @RequestHeader(name="X-Admin-Id", required=false) String adminId) {
        String title = (String) body.get("title");
        String content = (String) body.get("content");
        String targetType = (String) body.getOrDefault("targetType","ALL");
        @SuppressWarnings("unchecked")
        List<Number> list = (List<Number>) body.get("memberList");
        List<Long> memberList = (list == null) ? List.of() : list.stream().map(Number::longValue).toList();

        if (adminId == null || adminId.isBlank()) adminId = "admin";

        long pushNo = service.createAndSend(title, content, targetType, memberList, adminId);
        return Map.of("pushNo", pushNo, "status", "OK");
    }

    @GetMapping("/api/list")
    @ResponseBody
    public Map<String,Object> list(
        @RequestParam(name="page", defaultValue="0") int page,
        @RequestParam(name="size", defaultValue="20") int size
    ) {
        return service.list(page, size);
    }

}
