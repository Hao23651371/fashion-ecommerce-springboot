// Chuyển sort trang sale
function onSortChange(sortVal) {
    const urlParams = new URLSearchParams(window.location.search);
    const currentGender = urlParams.get('gender') || 'ALL';
    window.location.href = '/sale?gender=' + encodeURIComponent(currentGender) + '&sort=' + encodeURIComponent(sortVal);
}

// Sao chép coupon
let saleToastTimer = null;
function copyCouponCode(btn) {
    const code = btn.getAttribute('data-code');
    if (!code) return;

    navigator.clipboard.writeText(code).then(() => {
        const originalHtml = btn.innerHTML;
        btn.innerHTML = '<i class="bi bi-check2"></i> Đã chép';
        btn.classList.add('copied');

        const toast = document.getElementById('saleToast');
        const toastMsg = document.getElementById('saleToastMsg');
        if (toast && toastMsg) {
            toastMsg.textContent = `Đã sao chép mã "${code}" thành công!`;
            toast.classList.add('show');
            clearTimeout(saleToastTimer);
            saleToastTimer = setTimeout(() => {
                toast.classList.remove('show');
            }, 2500);
        }

        setTimeout(() => {
            btn.innerHTML = originalHtml;
            btn.classList.remove('copied');
        }, 2000);
    }).catch(err => {
        console.error('Không thể chép mã:', err);
    });
}

