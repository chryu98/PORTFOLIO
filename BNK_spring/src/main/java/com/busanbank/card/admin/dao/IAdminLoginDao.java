package com.busanbank.card.admin.dao;

import org.apache.ibatis.annotations.Mapper;

import com.busanbank.card.admin.dto.AdminDto;

@Mapper
public interface IAdminLoginDao {

	AdminDto adminLogin(AdminDto adminDto); 
}
