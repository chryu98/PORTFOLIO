package com.busanbank.card.user.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.busanbank.card.user.dao.IUserDao;
import com.busanbank.card.user.dto.UserDto;
import com.busanbank.card.user.dto.UserJoinDto;

@Service
public class JoinService {

	@Autowired
	private IUserDao userDao;
	
	public String validateJoinUser(UserJoinDto joinUser) {
		
		UserDto exists = userDao.findByUsername(joinUser.getUsername());
		
		//성명 검사
		if(joinUser.getName() == null) {
			return "성명을 입력해주세요.";			
		}
		
		//성명 형식 검사
		if (!joinUser.getName().matches("^[가-힣]{2,20}$")) {
			return "성명은 한글 2~20자여야 합니다.";
		}
		
		//아이디 검사
		if(joinUser.getUsername() == null) {
			return "아이디를 입력해주세요.";			
		}
		
		//아이디 중복 검사
		if(exists != null) {
			return "이미 사용중인 아이디입니다.";
		}
		
		//비밀번호 검사
		if(joinUser.getPassword() == null) {
			return "비밀번호를 입력해주세요.";			
		}
		if(joinUser.getPasswordCheck() == null) {
			return "비밀번호를 확인하세요.";			
		}
		if(!joinUser.getPassword().equals(joinUser.getPasswordCheck())) {
			return "비밀번호가 일치하지 않습니다.";
		}
		if(!joinUser.getPassword().matches("^(?=.*[A-Za-z])(?=.*\\d)(?=.*[!@#$%^&*()_+\\[\\]{}|\\\\;:'\",.<>?/`~\\-]).{8,12}$")) {
		    return "비밀번호는 영문자, 숫자, 특수문자를 포함한 8~12자리여야 합니다.";			
		}
		
		//주민등록번호 검사
		String front = joinUser.getRrnFront();
		String back = joinUser.getRrnBack();
		
		if(front == null || front.length() != 6 || back == null || back.length() != 7) {
			return "주민번호를 확인해주세요.";
		}
		
		//주민등록번호 현식 검사
		int month = Integer.parseInt(front.substring(2, 4));
		int day = Integer.parseInt(front.substring(4, 6));
		char genderCode = back.charAt(0);
		
		if(month < 1 || month > 12 || day < 1 || day > 31) {
			return "주민등록번호 형식이 잘못되었습니다.";
		}
		if(genderCode < '1' || genderCode > '4') {
			return "주민등록번호 성별 코드가 유효하지 않습니다.";
		}
		
		//주소 검사
		if(joinUser.getZipCode() == null || joinUser.getZipCode().trim().isEmpty() ||
		   joinUser.getAddress1() == null || joinUser.getAddress1().trim().isEmpty()) {
			return "주소를 입력해주세요.";
		}
		
		//상세주소 null 체크
		if (joinUser.getAddress2() == null || joinUser.getAddress2().trim().isEmpty()) {
			return "상세주소를 입력해주세요.";
		}
		
		return null;
	}
}
