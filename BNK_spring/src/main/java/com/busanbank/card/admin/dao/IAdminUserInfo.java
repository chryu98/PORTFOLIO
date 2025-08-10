package com.busanbank.card.admin.dao;

import java.util.List;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Select;

import com.busanbank.card.user.dto.UserDto;

@Mapper
public interface IAdminUserInfo {

	@Select({
	    "SELECT",
	    "   MEMBER_NO     AS memberNo,",
	    "   USERNAME      AS username,",
	    "   PASSWORD      AS password,",
	    "   NAME          AS name,",
	    "   ROLE          AS role,",
	    "   RRN_FRONT     AS rrnFront,",
	    "   RRN_GENDER    AS rrnGender,",
	    "   RRN_TAIL_ENC  AS rrnTailEnc,",
	    "   ZIP_CODE      AS zipCode,",
	    "   ADDRESS1      AS address1,",
	    "   ADDRESS2      AS address2",
	    "FROM MEMBER",
	    "ORDER BY MEMBER_NO DESC"
	})
	List<UserDto> findAllUsers();

}
