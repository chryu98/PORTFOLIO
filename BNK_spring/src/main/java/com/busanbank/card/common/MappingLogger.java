// com/busanbank/card/common/MappingLogger.java
package com.busanbank.card.common;

import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.mvc.method.annotation.RequestMappingHandlerMapping;

@Component
public class MappingLogger {
  private final RequestMappingHandlerMapping m;
  public MappingLogger(RequestMappingHandlerMapping m) { this.m = m; }

  @EventListener(ApplicationReadyEvent.class)
  public void log() {
    m.getHandlerMethods().forEach((info, hm) -> System.out.println("[MAPPING] " + info));
  }
}
