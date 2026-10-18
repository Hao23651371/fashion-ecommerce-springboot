package com.iuh.fashionshop.config;

import com.iuh.fashionshop.service.AccountUserDetailsService;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.authentication.AuthenticationProvider;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.LockedException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.core.authority.AuthorityUtils;


import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.AuthenticationFailureHandler;
import org.springframework.security.web.authentication.AuthenticationSuccessHandler;

import java.io.IOException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;

import java.util.Set;

@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
                .csrf(csrf -> csrf.disable()) // Tắt CSRF để thuận tiện test
                .authorizeHttpRequests(auth -> auth
                        .requestMatchers("/css/**", "/js/**", "/images/**", "/fonts/**", "/webjars/**").permitAll()
                        .requestMatchers("/login", "/register", "/logout").permitAll()
                        .requestMatchers("/admin/**").hasRole("ADMIN")
                        .anyRequest().permitAll()
                )
                .formLogin(form -> form
                        .loginPage("/login")
                        .loginProcessingUrl("/login")
                        .successHandler(customAuthenticationSuccessHandler())
                        .failureHandler(customAuthenticationFailureHandler()) // thay cho failureUrl("/login?error=true")
                        .permitAll()
                )
                .logout(logout -> logout
                        .logoutUrl("/logout")
                        .logoutSuccessUrl("/login?logout=true")
                        .invalidateHttpSession(true)
                        .deleteCookies("JSESSIONID")
                        .permitAll()
                );

        return http.build();
    }

    /**
     * Điều hướng thông minh sau đăng nhập:
     * - Role ADMIN -> /admin/dashboard
     * - Role CUSTOMER -> / (Trang chủ khách hàng)
     */
    @Bean
    public AuthenticationSuccessHandler customAuthenticationSuccessHandler() {
        return new AuthenticationSuccessHandler() {
            @Override
            public void onAuthenticationSuccess(HttpServletRequest request,
                                                HttpServletResponse response,
                                                Authentication authentication) throws IOException, ServletException {
                Set<String> roles = AuthorityUtils.authorityListToSet(authentication.getAuthorities());
                if (roles.contains("ROLE_ADMIN")) {
                    response.sendRedirect("/admin/dashboard");
                } else {
                    response.sendRedirect("/");
                }
            }
        };
    }

    /**
     * Phân loại lỗi đăng nhập để trang login hiển thị đúng chỗ:
     * - error=email    : email/tài khoản không tồn tại  -> báo dưới ô email
     * - error=password : đúng email nhưng sai mật khẩu  -> báo dưới ô mật khẩu
     * - error=locked   : tài khoản bị khóa              -> báo ở khung trên cùng
     * - error=unknown  : lỗi khác                       -> báo ở khung trên cùng
     * Email được gửi lại qua tham số "username" để điền sẵn vào ô (KHÔNG gửi mật khẩu).
     */
    @Bean
    public AuthenticationFailureHandler customAuthenticationFailureHandler() {
        return (request, response, exception) -> {
            String errorType;
            if (exception instanceof UsernameNotFoundException) {
                errorType = "email";
            } else if (exception instanceof LockedException) {
                errorType = "locked";
            } else if (exception instanceof BadCredentialsException) {
                errorType = "password";
            } else {
                errorType = "unknown";
            }

            StringBuilder url = new StringBuilder("/login?error=").append(errorType);
            String username = request.getParameter("username");
            if (username != null && !username.isBlank()) {
                url.append("&username=").append(URLEncoder.encode(username.trim(), StandardCharsets.UTF_8));
            }
            response.sendRedirect(url.toString());
        };
    }

    /**
     * AuthenticationProvider:
     * 1) Tài khoản test cứng (1/1 -> ADMIN, 1/2 hoặc 2/2 -> CUSTOMER)
     * 2) Tài khoản thật từ CSDL qua AccountUserDetailsService + BCryptPasswordEncoder
     *
     * Ném đúng loại exception để failure handler phân biệt:
     * UsernameNotFoundException (sai email) / BadCredentialsException (sai mật khẩu) / LockedException (bị khóa)
     */
    /**
     * AuthenticationProvider: xác thực tài khoản thật từ CSDL qua
     * AccountUserDetailsService + BCryptPasswordEncoder.
     *
     * Ném đúng loại exception để failure handler phân biệt:
     * UsernameNotFoundException (sai email) / BadCredentialsException (sai mật khẩu) / LockedException (bị khóa)
     */
    @Bean
    public AuthenticationProvider customAuthenticationProvider(AccountUserDetailsService accountUserDetailsService,
                                                               PasswordEncoder passwordEncoder) {
        return new AuthenticationProvider() {
            @Override
            public Authentication authenticate(Authentication authentication) throws AuthenticationException {
                String username = authentication.getName() != null ? authentication.getName().trim() : "";
                String password = authentication.getCredentials() != null ? authentication.getCredentials().toString().trim() : "";

                // Không tìm thấy email -> UsernameNotFoundException (để nguyên, không nuốt)
                UserDetails userDetails = accountUserDetailsService.loadUserByUsername(username);

                if (!passwordEncoder.matches(password, userDetails.getPassword())) {
                    throw new BadCredentialsException("Sai mật khẩu");
                }
                if (!userDetails.isAccountNonLocked()) {
                    throw new LockedException("Tài khoản của bạn đã bị khóa");
                }
                return new UsernamePasswordAuthenticationToken(userDetails, password, userDetails.getAuthorities());
            }

            @Override
            public boolean supports(Class<?> authentication) {
                return UsernamePasswordAuthenticationToken.class.isAssignableFrom(authentication);
            }
        };
    }
}