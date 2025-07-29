package com.busanbank.card.user.config;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

import com.busanbank.card.user.dao.IUserDao;
import com.busanbank.card.user.dto.UserDto;

@Service
public class CustomUserDetailsService implements UserDetailsService {

	@Autowired
	private IUserDao userDao;
	
	@Override
	public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
		
		UserDto user = userDao.findByUsername(username);
        if (user != null) {
            return new CustomUserDetails(user);
        }
        System.out.println("사용자 없음: " + username);
        throw new UsernameNotFoundException(username + " 사용자가 없습니다.");
		
		//return null;
	}

}
