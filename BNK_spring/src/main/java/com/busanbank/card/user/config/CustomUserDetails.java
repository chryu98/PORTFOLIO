package com.busanbank.card.user.config;

import java.util.ArrayList;
import java.util.Collection;

import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;

import com.busanbank.card.user.dto.UserDto;

public class CustomUserDetails implements UserDetails {

	private static final long seriaVersionUTD = 1L;
	
	private UserDto user;
	
	public CustomUserDetails(UserDto user) {
		this.user = user;
	}
	
	@Override
	public Collection<? extends GrantedAuthority> getAuthorities() {
		
		Collection<GrantedAuthority> collection = new ArrayList<>();
		collection.add(new GrantedAuthority() {
			
			private static final long serialVersionUID = 1L;
			
			@Override
			public String getAuthority() {
				return user.getRole();
			}
		});
		return collection;
	}

	@Override
	public String getPassword() {
		String password = user.getPassword();
        System.out.println("CustomUserDetails.getPassword() 호출됨, 비밀번호: " + password);
		return password;
	}

	@Override
	public String getUsername() {
		return user.getUsername();
	}
	
	public String getName() {
		return user.getName();
	}
	
	public String getRole() {
		return user.getRole();
	}
	//suwol
	public int getMemberNo() {
        return user.getMemberNo();
    }
	
	@Override
	public boolean equals(Object obj) {
	    if (this == obj) return true;
	    if (!(obj instanceof CustomUserDetails)) return false;
	    CustomUserDetails other = (CustomUserDetails) obj;
	    return this.getUsername().equals(other.getUsername());
	}

	@Override
	public int hashCode() {
	    return this.getUsername().hashCode();
	}

}
