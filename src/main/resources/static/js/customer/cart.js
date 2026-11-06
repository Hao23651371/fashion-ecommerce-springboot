// Giỏ hàng - JS xử lý tăng giảm số lượng, xóa sản phẩm và modal xác nhận
document.addEventListener('DOMContentLoaded', function () {
    const toastEl = document.getElementById('cartActionToast');
    const toastIcon = document.getElementById('cartToastIcon');
    const toastMsg = document.getElementById('cartToastMessage');
    const bsToast = toastEl ? new bootstrap.Toast(toastEl, { delay: 2500 }) : null;

    function showCartToast(msg, isSuccess = true) {
        if (!bsToast) return;
        toastMsg.textContent = msg;
        toastIcon.className = isSuccess ? 'bi bi-check-circle-fill text-success fs-6' : 'bi bi-exclamation-circle-fill text-warning fs-6';
        bsToast.show();
    }

    function updateHeaderBadge(count) {
        const badge = document.querySelector('a.site-icon-btn[href*="/cart"] .site-badge');
        if (badge) {
            badge.textContent = count;
            if (count <= 0) {
                badge.classList.add('d-none');
            } else {
                badge.classList.remove('d-none');
            }
        }
    }

    function checkEmptyState(count) {
        if (count <= 0) {
            const wrap = document.getElementById('cartContentWrap');
            const empty = document.getElementById('cartEmptyWrap');
            if (wrap) wrap.classList.add('d-none');
            if (empty) empty.classList.remove('d-none');
        }
    }

    // Xử lý tăng / giảm số lượng
    function changeQty(id, delta) {
        const input = document.getElementById('qty-input-' + id);
        if (!input) return;
        let cur = parseInt(input.value, 10) || 1;
        let max = parseInt(input.max, 10) || 99;
        let newQty = cur + delta;

        if (newQty < 1) {
            promptDeleteItem(id);
            return;
        }
        if (newQty > max) {
            showCartToast('Số lượng đã đạt giới hạn tồn kho (' + max + ')', false);
            return;
        }

        input.value = newQty;

        const params = new URLSearchParams();
        params.append('cartItemId', id);
        params.append('quantity', newQty);

        fetch('/cart/update', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/x-www-form-urlencoded',
                'X-Requested-With': 'XMLHttpRequest'
            },
            body: params
        })
        .then(r => r.json())
        .then(data => {
            if (data.success) {
                updateHeaderBadge(data.cartCount);
                const subtotalEl = document.getElementById('summarySubtotal');
                const totalEl = document.getElementById('summaryTotal');
                if (subtotalEl) subtotalEl.textContent = data.formattedSubtotal;
                if (totalEl) totalEl.textContent = data.formattedSubtotal;

                // Cập nhật lại thành tiền của dòng
                const itemRow = document.getElementById('cart-item-' + id);
                if (itemRow) {
                    const priceText = itemRow.querySelector('.cart-price').textContent;
                    const price = parseInt(priceText.replace(/[^0-9]/g, ''), 10) || 0;
                    const lineTotal = document.getElementById('line-total-' + id);
                    if (lineTotal) {
                        lineTotal.textContent = (price * newQty).toLocaleString('vi-VN') + ' ₫';
                    }
                }
            } else {
                input.value = cur;
                showCartToast(data.message || 'Lỗi cập nhật số lượng', false);
            }
        })
        .catch(err => {
            input.value = cur;
            showCartToast('Không thể kết nối máy chủ', false);
        });
    }

    // Quản lý Modal xác nhận xóa
    let itemToDeleteId = null;
    const deleteModalEl = document.getElementById('cartDeleteConfirmModal');
    const deleteModal = deleteModalEl ? new bootstrap.Modal(deleteModalEl) : null;
    const clearModalEl = document.getElementById('cartClearConfirmModal');
    const clearModal = clearModalEl ? new bootstrap.Modal(clearModalEl) : null;

    function promptDeleteItem(id) {
        itemToDeleteId = id;
        if (deleteModal) {
            deleteModal.show();
        } else {
            executeDeleteItem(id);
        }
    }

    const btnConfirmDelete = document.getElementById('btnConfirmDelete');
    if (btnConfirmDelete) {
        btnConfirmDelete.addEventListener('click', function () {
            if (itemToDeleteId) {
                if (deleteModal) deleteModal.hide();
                executeDeleteItem(itemToDeleteId);
                itemToDeleteId = null;
            }
        });
    }

    // Thực thi xóa 1 sản phẩm
    function executeDeleteItem(id) {
        const params = new URLSearchParams();
        params.append('cartItemId', id);

        fetch('/cart/remove', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/x-www-form-urlencoded',
                'X-Requested-With': 'XMLHttpRequest'
            },
            body: params
        })
        .then(r => r.json())
        .then(data => {
            if (data.success) {
                const itemRow = document.getElementById('cart-item-' + id);
                if (itemRow) {
                    itemRow.style.transition = 'all 0.3s ease';
                    itemRow.style.opacity = '0';
                    itemRow.style.transform = 'translateX(-20px)';
                    setTimeout(() => {
                        itemRow.remove();
                        updateHeaderBadge(data.cartCount);
                        const subtotalEl = document.getElementById('summarySubtotal');
                        const totalEl = document.getElementById('summaryTotal');
                        if (subtotalEl) subtotalEl.textContent = data.formattedSubtotal;
                        if (totalEl) totalEl.textContent = data.formattedSubtotal;
                        checkEmptyState(data.cartCount);
                    }, 300);
                }
                showCartToast(data.message, true);
            } else {
                showCartToast(data.message || 'Lỗi xóa sản phẩm', false);
            }
        })
        .catch(err => {
            showCartToast('Không thể kết nối máy chủ', false);
        });
    }

    // Gán sự kiện click
    document.querySelectorAll('.btn-cart-minus').forEach(btn => {
        btn.addEventListener('click', function () {
            changeQty(this.getAttribute('data-id'), -1);
        });
    });

    document.querySelectorAll('.btn-cart-plus').forEach(btn => {
        btn.addEventListener('click', function () {
            changeQty(this.getAttribute('data-id'), 1);
        });
    });

    document.querySelectorAll('.btn-cart-delete').forEach(btn => {
        btn.addEventListener('click', function () {
            promptDeleteItem(this.getAttribute('data-id'));
        });
    });

    // Xóa toàn bộ giỏ hàng
    const clearBtn = document.getElementById('btnClearCart');
    if (clearBtn) {
        clearBtn.addEventListener('click', function () {
            if (clearModal) {
                clearModal.show();
            } else {
                executeClearCart();
            }
        });
    }

    const btnConfirmClear = document.getElementById('btnConfirmClear');
    if (btnConfirmClear) {
        btnConfirmClear.addEventListener('click', function () {
            if (clearModal) clearModal.hide();
            executeClearCart();
        });
    }

    function executeClearCart() {
        fetch('/cart/clear', {
            method: 'POST',
            headers: { 'X-Requested-With': 'XMLHttpRequest' }
        })
        .then(r => r.json())
        .then(data => {
            if (data.success) {
                updateHeaderBadge(0);
                checkEmptyState(0);
                showCartToast('Đã xóa sạch giỏ hàng!', true);
            }
        })
        .catch(err => {
            showCartToast('Không thể kết nối máy chủ', false);
        });
    }
});

