package com.busanbank.card.branch.controller;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.validation.BindingResult;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;

import com.busanbank.card.branch.dto.BranchDto;
import com.busanbank.card.branch.service.BranchService;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;

@Controller
@RequestMapping("/admin/branches")
@RequiredArgsConstructor
public class BranchAdminController {

 private final BranchService service;

 @GetMapping
 public String list(@RequestParam(name = "q", defaultValue = "") String q,
		    @RequestParam(name = "page", defaultValue = "1") int page,
		    @RequestParam(name = "size", defaultValue = "10") int size,
                    Model model) {
     var paged = service.list(q, page, size);
     model.addAttribute("q", q);
     model.addAttribute("paged", paged);
     model.addAttribute("dto", new BranchDto()); // 등록 폼 바인딩
     return "admin/branch_list";
 }

 @PostMapping
 public String create(@Valid @ModelAttribute("dto") BranchDto dto,
                      BindingResult binding,
                      @RequestParam(name = "q", defaultValue = "") String q,
                      @RequestParam(name = "page", defaultValue = "1") int page,
                      @RequestParam(name = "size", defaultValue = "10") int size,
                      Model model) {
     if (binding.hasErrors()) {
         var paged = service.list(q, page, size);
         model.addAttribute("q", q);
         model.addAttribute("paged", paged);
         return "admin/branch_list";
     }
     service.create(dto);
     return "redirect:/admin/branches?q=" + q + "&page=" + page + "&size=" + size;
 }

 @PostMapping("/{id}/delete")
 public String delete(@PathVariable(name = "id") Long id,
		    @RequestParam(name = "q", defaultValue = "") String q,
		    @RequestParam(name = "page", defaultValue = "1") int page,
		    @RequestParam(name = "size", defaultValue = "10") int size) {
     service.delete(id);
     return "redirect:/admin/branches?q=" + q + "&page=" + page + "&size=" + size;
 }
}
