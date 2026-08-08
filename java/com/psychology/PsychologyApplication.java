package com.psychology;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.web.servlet.ServletComponentScan;

/**
 * Spring Boot 项目启动类
 * 放在 com.psychology 包根目录，自动扫描所有子包
 */
@SpringBootApplication
@ServletComponentScan // 自动扫描所有 @WebServlet、@WebFilter、@WebListener 注解
public class PsychologyApplication {
    public static void main(String[] args) {
        SpringApplication.run(PsychologyApplication.class, args);
    }
}