package com.busanbank.card.admin.dto;

import lombok.Data;
import java.math.BigDecimal;
import java.util.Date;

@Data
public class ModerationLogDto {
    private Long logId;
    private Long customNo;
    private Long memberNo;
    private String decision;       // ACCEPT | REJECT
    private String reason;         // VIOLENCE_GUN ...
    private String label;          // gun | knife
    private BigDecimal confidence;
    private String model;          // yolo+weapons@v1
    private Integer inferenceMs;
    private Date createdAt;

    // joined
    private String imagePath;      // CUSTOM_CARD.image_path
}
