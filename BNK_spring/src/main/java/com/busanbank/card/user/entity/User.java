package com.busanbank.card.user.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "member")  // 실제 DB 테이블명
@Getter @Setter
@NoArgsConstructor
@AllArgsConstructor
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long memberNo;

    private String username;
    private String password;
    private String name;

    // 주민번호 관련
    private String rrnFront;
    private String rrnGender;
    private String rrnTailEnc;  // AESUtil로 암호화된 뒷자리

    // 주소
    private String zipCode;
    private String address1;
    private String address2;

    private String role;
}
