package com.iuh.fashionshop.form;

import com.iuh.fashionshop.model.enums.PaymentMethod;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class CheckoutForm {

    @NotBlank(message = "Họ tên người nhận không được để trống")
    @Size(max = 100)
    private String recipientName;

    @NotBlank(message = "Số điện thoại không được để trống")
    @Size(max = 15)
    private String recipientPhone;

    @NotBlank(message = "Địa chỉ giao hàng không được để trống")
    @Size(max = 255)
    private String shippingAddress;

    @Size(max = 255)
    private String note;

    @NotNull(message = "Vui lòng chọn phương thức thanh toán")
    private PaymentMethod paymentMethod = PaymentMethod.COD;

    /** Mã giảm giá (tuỳ chọn) */
    @Size(max = 50)
    private String couponCode;
}
