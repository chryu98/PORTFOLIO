// src/main/java/com/busanbank/card/push/mapper/PushMapper.java
package com.busanbank.card.push.mapper;

import com.busanbank.card.push.dto.PushDto;
import org.apache.ibatis.annotations.Insert;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Options;

@Mapper
public interface PushMapper {

	@Insert("INSERT INTO PUSH (TITLE, CONTENT, TARGET_TYPE, CREATED_BY, CREATED_AT) " +
	        "VALUES (#{title}, #{content}, #{targetType}, #{createdBy}, SYSDATE)")
	@Options(useGeneratedKeys = true, keyProperty = "pushNo", keyColumn = "PUSH_NO")
	int insert(PushDto dto);
}