// Wishlist customer page script
document.addEventListener('DOMContentLoaded', function () {
    const grid = document.getElementById('wishlistGrid');
    const emptyBox = document.getElementById('wishlistEmpty');
    const actionsBar = document.getElementById('wishlistActions');
    const titleCount = document.getElementById('titleWishlistCount');
    const sidebarCount = document.getElementById('sidebarWishlistCount');
    const toast = document.getElementById('wishlistToast');
    const toastMsg = document.getElementById('toastMessage');

    let toastTimer = null;
    function showToast(message, isSuccess = true) {
        if (!toast) return;
        toastMsg.textContent = message;
        const icon = toast.querySelector('i');
        if (icon) {
            icon.className = isSuccess ? 'bi bi-check2-circle fs-5 text-success' : 'bi bi-exclamation-circle fs-5 text-warning';
        }
        toast.classList.add('show');
        clearTimeout(toastTimer);
        toastTimer = setTimeout(() => {
            toast.classList.remove('show');
        }, 2800);
    }

    function updateBadgeCounts(count) {
        // Cập nhật số lượng trên tiêu đề
        if (titleCount) {
            titleCount.textContent = `(${count} món)`;
        }
        // Cập nhật số lượng trên menu bên trái
        if (sidebarCount) {
            sidebarCount.textContent = count;
            sidebarCount.style.display = count > 0 ? 'inline' : 'none';
        }
        // Cập nhật badge trên header chính
        const headerBadge = document.querySelector('.site-icon-btn[aria-label="Yêu thích"] .site-badge');
        if (headerBadge) {
            if (count > 0) {
                headerBadge.textContent = count;
                headerBadge.style.display = '';
            } else {
                headerBadge.style.display = 'none';
            }
        }
        // Nếu số lượng về 0, chuyển sang giao diện trống
        if (count === 0) {
            if (grid) grid.style.display = 'none';
            if (actionsBar) actionsBar.classList.add('d-none');
            if (emptyBox) emptyBox.classList.remove('d-none');
            const dot = document.querySelector('.acc-menu .acc-dot');
            if (dot) dot.style.display = 'none';
        }
    }

    // 1. Xóa từng sản phẩm
    document.addEventListener('click', function (e) {
        const btn = e.target.closest('.btn-wishlist-del');
        if (!btn) return;

        const productId = btn.getAttribute('data-id');
        const productName = btn.getAttribute('data-name') || 'Sản phẩm';
        const cardCol = document.getElementById('wishlist-card-' + productId);

        btn.disabled = true;

        fetch('/wishlist/remove/' + productId, {
            method: 'POST',
            headers: {
                'X-Requested-With': 'XMLHttpRequest'
            }
        })
            .then(res => {
                if (res.redirected || res.status === 401 || res.status === 403) {
                    window.location.href = '/login';
                    return null;
                }
                return res.json();
            })
            .then(data => {
                if (!data) return;
                if (data.success) {
                    showToast(`Đã xóa "${productName}" khỏi danh sách yêu thích.`);
                    if (cardCol) {
                        cardCol.style.transition = 'all 0.3s ease';
                        cardCol.style.opacity = '0';
                        cardCol.style.transform = 'scale(0.85)';
                        setTimeout(() => {
                            cardCol.remove();
                            updateBadgeCounts(data.count);
                        }, 300);
                    } else {
                        updateBadgeCounts(data.count);
                    }
                } else {
                    showToast(data.message || 'Không thể xóa sản phẩm.', false);
                    btn.disabled = false;
                }
            })
            .catch(err => {
                console.error('Lỗi khi xóa yêu thích:', err);
                showToast('Đã có lỗi xảy ra. Vui lòng thử lại!', false);
                btn.disabled = false;
            });
    });

    // 2. Xóa tất cả với Modal xác nhận đẹp mắt
    const btnClear = document.getElementById('btnClearWishlist');
    const clearModalEl = document.getElementById('clearWishlistModal');
    const btnConfirmClear = document.getElementById('btnConfirmClearWishlist');
    let clearModalInstance = null;

    if (btnClear && clearModalEl) {
        clearModalInstance = new bootstrap.Modal(clearModalEl);

        btnClear.addEventListener('click', function () {
            clearModalInstance.show();
        });

        if (btnConfirmClear) {
            btnConfirmClear.addEventListener('click', function () {
                btnConfirmClear.disabled = true;
                btnConfirmClear.innerHTML = '<span class="spinner-border spinner-border-sm me-1" role="status" aria-hidden="true"></span> Đang xóa...';

                fetch('/wishlist/clear', {
                    method: 'POST',
                    headers: {
                        'X-Requested-With': 'XMLHttpRequest'
                    }
                })
                    .then(res => {
                        if (res.redirected || res.status === 401 || res.status === 403) {
                            window.location.href = '/login';
                            return null;
                        }
                        return res.json();
                    })
                    .then(data => {
                        clearModalInstance.hide();
                        btnConfirmClear.disabled = false;
                        btnConfirmClear.innerHTML = '<i class="bi bi-trash3 me-1"></i> Xác nhận xóa';

                        if (!data) return;
                        if (data.success) {
                            showToast('Đã dọn sạch toàn bộ danh sách yêu thích!');
                            updateBadgeCounts(0);
                        } else {
                            showToast(data.message || 'Không thể dọn danh sách.', false);
                        }
                    })
                    .catch(err => {
                        clearModalInstance.hide();
                        btnConfirmClear.disabled = false;
                        btnConfirmClear.innerHTML = '<i class="bi bi-trash3 me-1"></i> Xác nhận xóa';
                        console.error('Lỗi khi dọn danh sách yêu thích:', err);
                        showToast('Đã có lỗi xảy ra. Vui lòng thử lại!', false);
                    });
            });
        }
    }
});