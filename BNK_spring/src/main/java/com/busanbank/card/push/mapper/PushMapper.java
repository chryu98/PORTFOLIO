// src/main/java/com/busanbank/card/push/mapper/PushMapper.java
package com.busanbank.card.push.mapper;

import com.busanbank.card.push.dto.PushDto;
import org.apache.ibatis.annotations.*;

@Mapper
public interface PushMapper {

	@Insert("""
			  INSERT INTO PUSH (TITLE, CONTENT, TARGET_TYPE, CREATED_BY)
			  VALUES (#{title}, #{content}, #{targetType}, #{createdBy})
			""")
			@Options(useGeneratedKeys = true, keyProperty = "pushNo", keyColumn = "PUSH_NO")
			int insert(PushDto row);


  @Select("""
    SELECT PUSH_NO, TITLE, CONTENT, TARGET_TYPE, CREATED_BY, CREATED_AT
      FROM PUSH
     WHERE PUSH_NO = #{pushNo}
  """)
  PushDto findById(Long pushNo);
}
