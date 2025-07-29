package com.busanbank.card.faq.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import com.fasterxml.jackson.annotation.JsonFormat;
import java.util.Date;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class FaqDto {
    private int faqNo;
    private String faqQuestion;
    private String faqAnswer;

    @JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy-MM-dd HH:mm:ss")
    private Date regDate;

    private String writer;
    private String admin;
    private String cattegory ;
}
