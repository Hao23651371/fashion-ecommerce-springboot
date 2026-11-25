/**
 * JavaScript điều khiển luồng 3 bước Quên Mật Khẩu & Popup OTP
 */
let activeEmail = '';
let verifiedOtpCode = '';
let expiryTimerInterval = null;
let resendTimerInterval = null;

const COMMON_GMAIL_TYPOS = new Set([
    'gmai.com', 'gmial.com', 'gmal.com', 'gamil.com', 'gnail.com',
    'gmail.con', 'gmail.co', 'gmail.cm', 'gmail.om', 'gmail.vn', 'gmaill.com'
]);

function validateForgotEmail(emailVal) {
    if (!emailVal) {
        return 'Vui lòng nhập địa chỉ email đã đăng ký.';
    }
    if (/\s/.test(emailVal)) {
        return 'Email không được chứa khoảng trắng.';
    }
    const parts = emailVal.split('@');
    if (parts.length !== 2 || !parts[0] || !parts[1]) {
        return 'Email không đúng định dạng (ví dụ: example@gmail.com).';
    }
    const domain = parts[1].toLowerCase();
    if (COMMON_GMAIL_TYPOS.has(domain)) {
        return 'Có vẻ bạn gõ nhầm tên miền (@' + domain + '). Vui lòng nhập đúng @gmail.com (ví dụ: example@gmail.com).';
    }
    const emailRegex = /^(?!.*\.\.)[A-Za-z0-9](?:[A-Za-z0-9._%+-]*[A-Za-z0-9])?@[A-Za-z0-9.-]+\.[A-Za-z]{2,64}$/;
    if (!emailRegex.test(emailVal)) {
        return 'Email không đúng định dạng (ví dụ: example@gmail.com).';
    }
    return null;
}

// 1. GỬI MÃ OTP (BƯỚC 1 -> MỞ POPUP / ALERT MODAL OTP)
async function handleSendOtp(e) {
    e.preventDefault();
    const emailInput = document.getElementById('email') || document.getElementById('credential');
    const emailVal = emailInput.value.trim();
    const errorBox = document.getElementById('step1ErrorMsg');
    const errorText = document.getElementById('step1ErrorText');
    const submitBtn = document.getElementById('btnStep1Submit');
    const submitText = document.getElementById('btnStep1Text');

    const emailErr = validateForgotEmail(emailVal);
    if (emailErr) {
        errorText.textContent = emailErr;
        errorBox.classList.remove('d-none');
        errorBox.classList.add('d-flex');
        emailInput.focus();
        return;
    }

    submitBtn.disabled = true;
    submitText.textContent = 'ĐANG XỬ LÝ...';
    errorBox.classList.add('d-none');

    try {
        const resp = await fetch('/forgot-password/send-otp', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ email: emailVal, credential: emailVal })
        });
        const data = await resp.json();

        if (data.success) {
            activeEmail = data.email || emailVal;
            verifiedOtpCode = '';

            // Hiển thị email trong modal
            const modalEmail = document.getElementById('modalTargetEmail');
            if (modalEmail) modalEmail.textContent = activeEmail;

            // MỞ MODAL ALERT NHẬP OTP GIỮA MÀN HÌNH
            const modalOverlay = document.getElementById('otpModalOverlay');
            if (modalOverlay) modalOverlay.classList.remove('d-none');

            // Bắt đầu đếm ngược hạn OTP 5 phút và 60s gửi lại
            startExpiryTimer(300);
            startResendTimer(60);

            // Khởi tạo các ô OTP và focus ô đầu
            setupOtpInputs();
            setTimeout(() => {
                const firstDigit = document.querySelector('.otp-box-input[data-idx="0"]');
                if (firstDigit) firstDigit.focus();
            }, 150);
        } else {
            errorText.textContent = data.message || 'Không tìm thấy tài khoản tương ứng với email này.';
            errorBox.classList.remove('d-none');
            emailInput.focus();
        }
    } catch (err) {
        errorText.textContent = 'Không thể kết nối đến máy chủ. Vui lòng thử lại sau.';
        errorBox.classList.remove('d-none');
    } finally {
        submitBtn.disabled = false;
        submitText.textContent = 'GỬI LIÊN KẾT ĐẶT LẠI MẬT KHẨU';
    }
}

// ĐÓNG MODAL ALERT OTP
function closeOtpModal() {
    const modalOverlay = document.getElementById('otpModalOverlay');
    if (modalOverlay) modalOverlay.classList.add('d-none');
    clearInterval(expiryTimerInterval);
    clearInterval(resendTimerInterval);
}

// 2. CẤU HÌNH 6 Ô NHẬP OTP TRONG MODAL
function setupOtpInputs() {
    const inputs = document.querySelectorAll('.otp-box-input');

    inputs.forEach((input, index) => {
        input.value = '';
        input.disabled = false;
        input.classList.remove('is-invalid', 'is-valid');

        // Xử lý khi gõ phím
        input.oninput = function () {
            const val = input.value.replace(/[^0-9]/g, '');
            input.value = val;

            if (val && index < inputs.length - 1) {
                inputs[index + 1].focus();
            }

            // Tự động xác thực khi gõ đủ 6 ký tự
            const fullOtp = getFullOtp();
            if (fullOtp.length === 6) {
                validateOtpAjax(fullOtp);
            }
        };

        // Xử lý phím lùi Backspace
        input.onkeydown = function (e) {
            if (e.key === 'Backspace' && !input.value && index > 0) {
                inputs[index - 1].focus();
            }
        };

        // Xử lý dán mã (Paste)
        input.onpaste = function (e) {
            e.preventDefault();
            const pasteData = (e.clipboardData || window.clipboardData).getData('text').trim().replace(/[^0-9]/g, '');
            if (pasteData) {
                const chars = pasteData.slice(0, 6).split('');
                chars.forEach((c, i) => {
                    if (inputs[i]) inputs[i].value = c;
                });
                const nextIdx = Math.min(chars.length, inputs.length - 1);
                inputs[nextIdx].focus();

                const fullOtp = getFullOtp();
                if (fullOtp.length === 6) {
                    validateOtpAjax(fullOtp);
                }
            }
        };
    });

    const alertBox = document.getElementById('otpModalAlert');
    if (alertBox) alertBox.classList.add('d-none');
}

function getFullOtp() {
    const inputs = document.querySelectorAll('.otp-box-input');
    let res = '';
    inputs.forEach(input => { res += input.value.trim(); });
    return res;
}

// XỬ LÝ KHI BẤM NÚT "XÁC THỰC MÃ OTP"
async function handleVerifyOtpClick() {
    const fullOtp = getFullOtp();
    if (fullOtp.length < 6) {
        const feedbackAlert = document.getElementById('otpModalAlert');
        if (feedbackAlert) {
            feedbackAlert.className = 'small mt-2 p-2 rounded-2 text-center text-danger bg-danger bg-opacity-10 border border-danger border-opacity-25';
            feedbackAlert.innerHTML = '<i class="bi bi-exclamation-circle-fill me-1"></i> Vui lòng nhập đủ 6 chữ số mã xác thực OTP!';
            feedbackAlert.classList.remove('d-none');
        }
        return;
    }

    const btn = document.getElementById('btnVerifyOtpOnly');
    const btnText = document.getElementById('btnVerifyOtpText');
    if (btn) btn.disabled = true;
    if (btnText) btnText.textContent = 'ĐANG XÁC THỰC...';

    try {
        await validateOtpAjax(fullOtp);
    } finally {
        if (btn) btn.disabled = false;
        if (btnText) btnText.textContent = 'XÁC THỰC MÃ OTP';
    }
}

// XÁC THỰC MÃ OTP VỚI SERVER
async function validateOtpAjax(otpCode) {
    const feedbackAlert = document.getElementById('otpModalAlert');
    const boxesWrap = document.getElementById('otpBoxesWrap');
    const inputs = document.querySelectorAll('.otp-box-input');

    try {
        const resp = await fetch('/forgot-password/verify-otp', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ email: activeEmail, otp: otpCode })
        });
        const data = await resp.json();

        if (data.success) {
            verifiedOtpCode = otpCode;
            inputs.forEach(input => {
                input.classList.remove('is-invalid');
                input.classList.add('is-valid');
                input.disabled = true;
            });

            if (feedbackAlert) {
                feedbackAlert.className = 'small mt-2 p-2 rounded-2 text-center text-success bg-success bg-opacity-10 border border-success border-opacity-25';
                feedbackAlert.innerHTML = '<i class="bi bi-check-circle-fill me-1"></i> ' + (data.message || 'Xác thực OTP thành công! Đang chuyển tiếp...');
                feedbackAlert.classList.remove('d-none');
            }

            clearInterval(expiryTimerInterval);
            clearInterval(resendTimerInterval);

            // Sau 450ms: Đóng modal OTP, ẩn trang nhập Email, hiển thị GIAO DIỆN THIẾT LẬP MẬT KHẨU MỚI
            setTimeout(() => {
                document.getElementById('otpModalOverlay').classList.add('d-none');
                document.getElementById('step1Forgot').classList.add('d-none');
                document.getElementById('step2ResetPassword').classList.remove('d-none');
                window.scrollTo({ top: 0, behavior: 'smooth' });

                const npw = document.getElementById('newPassword');
                const cpw = document.getElementById('confirmPassword');
                if (npw) { npw.value = ''; npw.focus(); }
                if (cpw) { cpw.value = ''; }
            }, 450);

        } else {
            verifiedOtpCode = '';
            // Báo đỏ, hiệu ứng rung lắc
            boxesWrap.classList.remove('shake-error');
            void boxesWrap.offsetWidth; // trigger reflow
            boxesWrap.classList.add('shake-error');

            inputs.forEach(input => {
                input.classList.remove('is-valid');
                input.classList.add('is-invalid');
            });

            if (feedbackAlert) {
                feedbackAlert.className = 'small mt-2 p-2 rounded-2 text-center text-danger bg-danger bg-opacity-10 border border-danger border-opacity-25';
                feedbackAlert.innerHTML = '<i class="bi bi-exclamation-circle-fill me-1"></i> ' + (data.message || 'Mã OTP sai! Đã xóa để nhập lại.');
                feedbackAlert.classList.remove('d-none');
            }

            // Tự động xóa sạch 6 ô và focus lại vào ô đầu tiên sau 600ms
            setTimeout(() => {
                inputs.forEach(input => {
                    input.value = '';
                    input.classList.remove('is-invalid');
                });
                inputs[0].focus();
            }, 600);
        }
    } catch (err) {
        if (feedbackAlert) {
            feedbackAlert.className = 'small mt-2 p-2 rounded-2 text-center text-danger bg-danger bg-opacity-10';
            feedbackAlert.innerHTML = '<i class="bi bi-exclamation-circle-fill me-1"></i> Lỗi kiểm tra mã xác thực!';
            feedbackAlert.classList.remove('d-none');
        }
    }
}

// 3. ĐẾM NGƯỢC HIỆU LỰC & GỬI LẠI MÃ TRONG MODAL
function startExpiryTimer(seconds) {
    clearInterval(expiryTimerInterval);
    let remain = seconds;
    const display = document.getElementById('otpExpiryTimer');

    function update() {
        if (!display) return;
        const m = Math.floor(remain / 60);
        const s = remain % 60;
        display.textContent = `${String(m).padStart(2, '0')}:${String(s).padStart(2, '0')}`;
        if (remain <= 0) {
            clearInterval(expiryTimerInterval);
            display.textContent = 'HẾT HẠN';
        }
        remain--;
    }
    update();
    expiryTimerInterval = setInterval(update, 1000);
}

function startResendTimer(seconds) {
    clearInterval(resendTimerInterval);
    let remain = seconds;
    const resendSecCount = document.getElementById('resendSecCount');
    const btnResend = document.getElementById('btnResendOtp');
    if (btnResend) btnResend.disabled = true;

    function update() {
        if (!resendSecCount) return;
        if (remain > 0) {
            resendSecCount.textContent = remain + 's';
            remain--;
        } else {
            clearInterval(resendTimerInterval);
            resendSecCount.textContent = '0s';
            if (btnResend) btnResend.disabled = false;
        }
    }
    update();
    resendTimerInterval = setInterval(update, 1000);
}

// GỬI LẠI MÃ MỚI
async function handleResendOtp() {
    const btnResend = document.getElementById('btnResendOtp');
    if (btnResend) {
        btnResend.disabled = true;
        btnResend.textContent = 'ĐANG GỬI...';
    }

    try {
        const resp = await fetch('/forgot-password/resend-otp', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ email: activeEmail })
        });
        const data = await resp.json();
        if (data.success) {
            startExpiryTimer(300);
            startResendTimer(60);
            setupOtpInputs();

            const feedbackAlert = document.getElementById('otpModalAlert');
            if (feedbackAlert) {
                feedbackAlert.className = 'small mt-2 p-2 rounded-2 text-center text-success bg-success bg-opacity-10 border border-success border-opacity-25';
                feedbackAlert.innerHTML = '<i class="bi bi-check-circle-fill me-1"></i> ' + data.message;
                feedbackAlert.classList.remove('d-none');
            }
            const firstDigit = document.querySelector('.otp-box-input[data-idx="0"]');
            if (firstDigit) firstDigit.focus();
        }
    } catch (err) {
        if (btnResend) btnResend.disabled = false;
    } finally {
        if (btnResend) btnResend.textContent = 'GỬI LẠI NGAY';
    }
}

// 4. KIỂM TRA ĐỘ MẠNH MẬT KHẨU & TÍCH XANH TIÊU CHÍ (TRANG BƯỚC 2)
function initPasswordStrengthMeter() {
    const newPwInput = document.getElementById('newPassword');
    const strengthLabel = document.getElementById('strengthLabel');
    const bars = [
        document.getElementById('bar1'),
        document.getElementById('bar2'),
        document.getElementById('bar3'),
        document.getElementById('bar4')
    ];
    const critLength = document.getElementById('critLength');
    const critCase = document.getElementById('critCase');
    const critNumber = document.getElementById('critNumber');
    const critSpecial = document.getElementById('critSpecial');

    if (!newPwInput) return;

    newPwInput.addEventListener('input', function () {
        const val = newPwInput.value;

        // 4 tiêu chí
        const hasLength = val.length >= 8;
        const hasCase = /[a-z]/.test(val) && /[A-Z]/.test(val);
        const hasNumber = /[0-9]/.test(val);
        const hasSpecial = /[^A-Za-z0-9]/.test(val);

        updateCrit(critLength, hasLength);
        updateCrit(critCase, hasCase);
        updateCrit(critNumber, hasNumber);
        updateCrit(critSpecial, hasSpecial);

        let score = 0;
        if (hasLength) score++;
        if (hasCase) score++;
        if (hasNumber) score++;
        if (hasSpecial) score++;

        // Cập nhật nhãn và 4 vạch
        bars.forEach(b => {
            if (b) b.className = 'strength-bar-item';
        });

        if (!strengthLabel) return;

        if (score <= 1) {
            strengthLabel.textContent = 'YẾU';
            strengthLabel.className = 'fw-bold text-danger';
            if (bars[0]) bars[0].classList.add('level-weak');
        } else if (score === 2) {
            strengthLabel.textContent = 'TRUNG BÌNH';
            strengthLabel.className = 'fw-bold text-warning';
            if (bars[0]) bars[0].classList.add('level-medium');
            if (bars[1]) bars[1].classList.add('level-medium');
        } else if (score === 3) {
            strengthLabel.textContent = 'MẠNH';
            strengthLabel.className = 'fw-bold text-primary';
            if (bars[0]) bars[0].classList.add('level-strong');
            if (bars[1]) bars[1].classList.add('level-strong');
            if (bars[2]) bars[2].classList.add('level-strong');
        } else if (score === 4) {
            strengthLabel.textContent = 'RẤT MẠNH';
            strengthLabel.className = 'fw-bold text-dark';
            bars.forEach(b => { if (b) b.classList.add('level-very-strong'); });
        }
    });
}

function updateCrit(el, isOk) {
    if (!el) return;
    if (isOk) {
        el.classList.add('is-matched');
    } else {
        el.classList.remove('is-matched');
    }
}

// 5. ẨN/HIỆN MẬT KHẨU
function togglePasswordVisibility(inputId, btn) {
    const input = document.getElementById(inputId);
    if (!input) return;
    const isPassword = input.type === 'password';
    input.type = isPassword ? 'text' : 'password';
    const icon = btn.querySelector('i');
    if (icon) {
        icon.classList.toggle('bi-eye', !isPassword);
        icon.classList.toggle('bi-eye-slash', isPassword);
    }
}

// 6. XỬ LÝ LƯU MẬT KHẨU MỚI (BƯỚC 2 -> BƯỚC 3 THÀNH CÔNG)
async function handleResetPassword(e) {
    e.preventDefault();
    const newPassword = document.getElementById('newPassword').value;
    const confirmPassword = document.getElementById('confirmPassword').value;
    const mismatchError = document.getElementById('pwMismatchError');
    const submitBtn = document.getElementById('btnStep2Submit');
    const submitText = document.getElementById('btnStep2Text');

    if (!verifiedOtpCode || verifiedOtpCode.length < 6) {
        alert('Chưa xác thực mã OTP. Vui lòng thực hiện lại từ đầu!');
        location.reload();
        return;
    }

    if (newPassword.length < 8) {
        alert('Mật khẩu mới phải có tối thiểu 8 ký tự!');
        document.getElementById('newPassword').focus();
        return;
    }

    if (newPassword !== confirmPassword) {
        mismatchError.classList.remove('d-none');
        document.getElementById('confirmPassword').focus();
        return;
    } else {
        mismatchError.classList.add('d-none');
    }

    submitBtn.disabled = true;
    submitText.textContent = 'ĐANG ĐẶT LẠI MẬT KHẨU...';

    try {
        const resp = await fetch('/forgot-password/reset-password', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                email: activeEmail,
                otp: verifiedOtpCode,
                newPassword: newPassword,
                confirmPassword: confirmPassword
            })
        });
        const data = await resp.json();

        if (data.success) {
            // Ẩn Bước 2, Hiển thị Bước 3 (Thành công)
            document.getElementById('step2ResetPassword').classList.add('d-none');
            document.getElementById('step3Success').classList.remove('d-none');
            window.scrollTo({ top: 0, behavior: 'smooth' });
        } else {
            alert(data.message || 'Không thể đặt lại mật khẩu. Vui lòng thử lại!');
        }
    } catch (err) {
        alert('Có lỗi xảy ra khi đặt lại mật khẩu. Vui lòng thử lại!');
    } finally {
        submitBtn.disabled = false;
        submitText.textContent = 'LƯU MẬT KHẨU MỚI & TIẾP TỤC';
    }
}

document.addEventListener('DOMContentLoaded', function () {
    initPasswordStrengthMeter();
    const forgotEmailInput = document.getElementById('email') || document.getElementById('credential');
    const errorBox = document.getElementById('step1ErrorMsg');
    const errorText = document.getElementById('step1ErrorText');
    if (forgotEmailInput && errorBox && errorText) {
        forgotEmailInput.addEventListener('input', () => {
            errorBox.classList.add('d-none');
            errorBox.classList.remove('d-flex');
        });
        forgotEmailInput.addEventListener('blur', () => {
            const val = forgotEmailInput.value.trim();
            if (!val) return;
            const err = validateForgotEmail(val);
            if (err) {
                errorText.textContent = err;
                errorBox.classList.remove('d-none');
                errorBox.classList.add('d-flex');
            }
        });
    }
});
