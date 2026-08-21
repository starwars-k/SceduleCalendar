package com.keito.calendar_backend;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.web.SecurityFilterChain;

@Configuration
public class SecurityConfig {
    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .csrf(csf -> csrf.disable()) // Disable CSRF for simplicity; consider enabling it in production
            .authorizeRequests(auth -> auth
                .anyRequest().permitAll() // Require authentication for any other requests
            );
        return http.build();
    }
}
