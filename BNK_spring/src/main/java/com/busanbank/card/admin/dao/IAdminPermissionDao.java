package com.busanbank.card.admin.dao;

import java.util.List;

import org.apache.ibatis.annotations.Mapper;

import com.busanbank.card.admin.dto.PermissionDto;

@Mapper
public interface IAdminPermissionDao {

	 List<PermissionDto> selectAllPermissions();
}
