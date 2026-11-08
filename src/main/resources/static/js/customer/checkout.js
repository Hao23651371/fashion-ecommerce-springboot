/**
 * checkout.js — áp dụng mã giảm giá (AJAX), format tiền VND.
 * Nạp riêng trên trang checkout, không gắn vào layout.
 */
(function () {
    'use strict';

    function formatVnd(n) {
        if (n == null || isNaN(n)) return '0 ₫';
        var num = Math.round(Number(n));
        return num.toString().replace(/\B(?=(\d{3})+(?!\d))/g, '.') + ' ₫';
    }

    var applyBtn = document.getElementById('couponApplyBtn');
    var codeInput = document.getElementById('couponCodeInput');
    var hint = document.getElementById('couponHint');
    var sumDiscount = document.getElementById('sumDiscount');
    var sumShipping = document.getElementById('sumShipping');
    var sumGrand = document.getElementById('sumGrand');

    if (!applyBtn || !codeInput) return;

    applyBtn.addEventListener('click', function () {
        var code = (codeInput.value || '').trim();
        if (!code) {
            if (hint) {
                hint.textContent = 'Vui lòng nhập mã giảm giá';
                hint.className = 'coupon-hint text-danger';
            }
            return;
        }

        applyBtn.disabled = true;
        applyBtn.textContent = 'Đang kiểm tra...';

        var body = new URLSearchParams();
        body.append('couponCode', code);

        fetch('/checkout/coupon', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/x-www-form-urlencoded',
                'X-Requested-With': 'XMLHttpRequest'
            },
            body: body.toString()
        })
            .then(function (res) {
                return res.json().then(function (data) {
                    return { ok: res.ok, data: data };
                });
            })
            .then(function (result) {
                var data = result.data || {};
                if (result.ok && data.success) {
                    if (hint) {
                        hint.textContent = data.message || 'Áp dụng thành công';
                        hint.className = 'coupon-hint text-success';
                    }
                    if (sumDiscount) {
                        sumDiscount.textContent = data.discountAmount > 0
                            ? ('− ' + formatVnd(data.discountAmount))
                            : '0 ₫';
                    }
                    if (sumShipping) sumShipping.textContent = formatVnd(data.shippingFee);
                    if (sumGrand) sumGrand.textContent = formatVnd(data.grandTotal);
                    if (data.code) codeInput.value = data.code;
                } else {
                    if (hint) {
                        hint.textContent = data.message || 'Mã không hợp lệ';
                        hint.className = 'coupon-hint text-danger';
                    }
                }
            })
            .catch(function () {
                if (hint) {
                    hint.textContent = 'Không thể kiểm tra mã. Thử lại sau.';
                    hint.className = 'coupon-hint text-danger';
                }
            })
            .finally(function () {
                applyBtn.disabled = false;
                applyBtn.textContent = 'Áp dụng';
            });
    });

    // Enter trong ô mã → áp dụng
    codeInput.addEventListener('keydown', function (e) {
        if (e.key === 'Enter') {
            e.preventDefault();
            applyBtn.click();
        }
    });
})();
