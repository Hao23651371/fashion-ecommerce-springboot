// Chuyển sort trang sale
function onSortChange(sortVal) {
    const urlParams = new URLSearchParams(window.location.search);
    const currentGender = urlParams.get('gender') || 'ALL';
    window.location.href = '/sale?gender=' + encodeURIComponent(currentGender) + '&sort=' + encodeURIComponent(sortVal);
}

// Carousel điều hướng voucher trượt ngang
document.addEventListener('DOMContentLoaded', function () {
    const track = document.getElementById('couponCarouselTrack');
    const btnPrev = document.getElementById('btnCouponPrev');
    const btnNext = document.getElementById('btnCouponNext');

    if (track && (btnPrev || btnNext)) {
        const updateNavButtons = () => {
            const maxScroll = track.scrollWidth - track.clientWidth;
            if (btnPrev) btnPrev.disabled = track.scrollLeft <= 5;
            if (btnNext) btnNext.disabled = track.scrollLeft >= maxScroll - 5;
        };

        if (btnPrev) {
            btnPrev.addEventListener('click', () => {
                const item = track.querySelector('.coupon-carousel-item');
                const scrollStep = item ? (item.offsetWidth + 16) : 360;
                track.scrollBy({ left: -scrollStep, behavior: 'smooth' });
            });
        }

        if (btnNext) {
            btnNext.addEventListener('click', () => {
                const item = track.querySelector('.coupon-carousel-item');
                const scrollStep = item ? (item.offsetWidth + 16) : 360;
                track.scrollBy({ left: scrollStep, behavior: 'smooth' });
            });
        }

        track.addEventListener('scroll', updateNavButtons, { passive: true });
        window.addEventListener('resize', updateNavButtons);
        updateNavButtons();
    }
});
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

