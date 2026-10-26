package com.iuh.fashionshop.dto;

import com.iuh.fashionshop.model.enums.AccountStatus;
import com.iuh.fashionshop.model.enums.Role;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.springframework.format.annotation.DateTimeFormat;

import java.time.LocalDateTime;

@Getter
@Setter
@NoArgsConstructor
public class AccountForm {

    private Long id;

    @NotBlank(message = "Email không được để trống")
    @Email(message = "Email không đúng định dạng")
    @Size(max = 150, message = "Email tối đa 150 ký tự")
    private String email;

    private String password;

    @NotNull(message = "Vai trò không được để trống")
    private Role role = Role.CUSTOMER;

    @NotNull(message = "Trạng thái không được để trống")
    private AccountStatus status = AccountStatus.ACTIVE;

    private boolean emailVerified = false;

    @Size(max = 100, message = "Mã xác thực tối đa 100 ký tự")
    private String verificationCode;

    @DateTimeFormat(pattern = "yyyy-MM-dd'T'HH:mm")
    private LocalDateTime verificationExpiry;
}
