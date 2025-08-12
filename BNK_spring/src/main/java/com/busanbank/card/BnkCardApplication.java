package com.busanbank.card;

import org.mybatis.spring.annotation.MapperScan;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;


@SpringBootApplication(scanBasePackages = "com.busanbank.card")
@MapperScan({"com.busanbank.card.**.dao", "com.busanbank.card.**.mapper"})
public class BnkCardApplication {

	public static void main(String[] args) {
		SpringApplication.run(BnkCardApplication.class, args);
	}

}
