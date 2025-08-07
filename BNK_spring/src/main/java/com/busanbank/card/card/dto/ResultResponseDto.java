package com.busanbank.card.card.dto;


import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class ResultResponseDto {
    private boolean success;
    private String message;
}