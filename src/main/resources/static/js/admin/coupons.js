/**
 * Fashion Shop Admin - Coupon / Voucher Management Module
 * Seamless, zero-reload AJAX operations & Real-time Live Search / Filter
 */
(function () {
    'use strict';

    // 1. Toast Notification Utility
    function getToastContainer() {
        let container = document.getElementById('couponToastContainer');
        if (!container) {
            container = document.createElement('div');
            container.id = 'couponToastContainer';
            container.className = 'coupon-toast-container';
            container.setAttribute('aria-live', 'polite');
            container.setAttribute('aria-atomic', 'true');
            document.body.appendChild(container);
        }
        return container;
    }

    function showToast(message, type = 'success', duration = 3500) {
        const container = getToastContainer();
        const toast = document.createElement('div');
        toast.className = `coupon-toast toast-${type}`;

        let iconHtml = '<i class="bi bi-check-circle-fill toast-icon"></i>';
        if (type === 'error') {
            iconHtml = '<i class="bi bi-exclamation-triangle-fill toast-icon"></i>';
        } else if (type === 'warning') {
            iconHtml = '<i class="bi bi-exclamation-circle-fill toast-icon"></i>';
        } else if (type === 'info') {
            iconHtml = '<i class="bi bi-info-circle-fill toast-icon"></i>';
        }

        toast.innerHTML = `
            ${iconHtml}
            <div class="toast-body">${escapeHtml(message)}</div>
            <button type="button" class="toast-close" aria-label="Đóng">&times;</button>
        `;

        const closeBtn = toast.querySelector('.toast-close');
        let removeTimer = null;

        function dismiss() {
            if (removeTimer) clearTimeout(removeTimer);
            toast.classList.add('toast-hiding');
            setTimeout(() => {
                if (toast.parentElement) toast.parentElement.removeChild(toast);
            }, 300);
        }

        closeBtn.addEventListener('click', dismiss);
        removeTimer = setTimeout(dismiss, duration);

        container.appendChild(toast);
    }

    function escapeHtml(text) {
        if (text === null || text === undefined) return '';
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    }

    // 2. Formatters & KPI Updaters
    function formatNumber(num) {
        if (num === null || num === undefined) return '0';
        return Number(num).toLocaleString('vi-VN');
    }

    function updateKpis(stats) {
        if (!stats) return;

        const setVal = (id, val) => {
            const el = document.getElementById(id);
            if (el) el.textContent = val;
        };

        if (stats.activeCoupons !== undefined) setVal('kpiActiveCoupons', stats.activeCoupons);
        if (stats.upcomingCoupons !== undefined) setVal('kpiUpcomingCoupons', stats.upcomingCoupons + ' sắp tới');
        if (stats.expiredCoupons !== undefined) setVal('kpiExpiredCoupons', stats.expiredCoupons + ' hết hạn');
        if (stats.totalUses !== undefined) setVal('kpiTotalUses', formatNumber(stats.totalUses));
        if (stats.totalQuota !== undefined) setVal('kpiTotalQuota', formatNumber(stats.totalQuota));
        if (stats.formattedTotalDiscount) setVal('kpiTotalDiscount', stats.formattedTotalDiscount);
        if (stats.formattedTotalRevenue) setVal('kpiTotalRevenue', stats.formattedTotalRevenue);

        // Tab counts
        if (stats.totalCoupons !== undefined) setVal('tabCountAll', stats.totalCoupons);
        if (stats.activeCoupons !== undefined) setVal('tabCountActive', stats.activeCoupons);
        if (stats.upcomingCoupons !== undefined) setVal('tabCountUpcoming', stats.upcomingCoupons);
        if (stats.expiredCoupons !== undefined) setVal('tabCountExpired', stats.expiredCoupons);
        if (stats.pausedCoupons !== undefined) setVal('tabCountPaused', stats.pausedCoupons);
        if (stats.totalCoupons !== undefined) setVal('footerTotalCoupons', stats.totalCoupons);
    }

    // 3. Discount Type Logic Synchronizer
    function syncDiscountType(type, labelEl, inputEl, maxCol) {
        if (!labelEl || !inputEl) return;
        const maxInput = maxCol ? maxCol.querySelector('input') : null;
        if (type === 'PERCENT') {
            labelEl.innerHTML = 'Mức giảm (%) <span class="text-danger">*</span>';
            inputEl.placeholder = 'Nhập % giảm (VD: 20)';
            inputEl.max = '100';
            inputEl.required = true;
            if (maxCol) {
                maxCol.style.display = 'block';
                if (maxInput) maxInput.disabled = false;
            }
        } else if (type === 'FIXED_AMOUNT') {
            labelEl.innerHTML = 'Số tiền giảm (VNĐ) <span class="text-danger">*</span>';
            inputEl.placeholder = 'VD: 50000';
            inputEl.removeAttribute('max');
            inputEl.required = true;
            if (maxCol) {
                maxCol.style.display = 'none';
                if (maxInput) {
                    maxInput.disabled = true;
                    maxInput.value = '';
                }
            }
        } else if (type === 'FREESHIP') {
            labelEl.innerHTML = 'Mức giảm phí ship (VNĐ)';
            inputEl.placeholder = '0 hoặc để trống = Miễn phí 100% ship, hoặc nhập mức giảm tối đa (VD: 30000)';
            inputEl.removeAttribute('max');
            inputEl.required = false; // Cho phép để trống = Freeship 100%
            if (maxCol) {
                maxCol.style.display = 'none';
                if (maxInput) {
                    maxInput.disabled = true;
                    maxInput.value = '';
                }
            }
        }
    }

    // 4. Build Table Row HTML from Data
    function buildRowHtml(c) {
        const searchKeywords = `${c.code} ${c.name} ${c.description || ''}`.toLowerCase();
        const targetClass = c.targetCustomerType === 'VIP'
            ? 'bg-warning-subtle text-warning-emphasis'
            : (c.targetCustomerType === 'NEW_CUSTOMER' ? 'bg-info-subtle text-info-emphasis' : 'bg-light text-secondary');

        const isPercent = c.discountType === 'PERCENT';
        const isFreeship = c.discountType === 'FREESHIP';
        const discountColor = isFreeship ? 'text-success' : 'text-primary';
        const freeshipIcon = isFreeship ? '<i class="bi bi-truck me-1"></i>' : '';
        const freeshipSub = isFreeship ? '<small class="text-success d-block">Miễn/giảm phí ship</small>' : '';
        const progressClass = c.usagePercent >= 100 ? 'bg-danger' : (c.usagePercent >= 75 ? 'bg-warning' : 'bg-primary');
        const isActive = c.status === 'ACTIVE';

        return `
            <tr id="coupon-row-${c.id}"
                class="coupon-row coupon-row-new"
                data-id="${c.id}"
                data-status="${(c.computedStatus || '').toLowerCase()}"
                data-type="${c.discountType}"
                data-target="${c.targetCustomerType}"
                data-search="${escapeHtml(searchKeywords)}">
                <td>
                    <div class="d-flex align-items-center gap-1">
                        <span class="code-badge font-monospace">${escapeHtml(c.code)}</span>
                        <button class="btn btn-sm btn-link p-1 copy-code text-secondary" type="button" data-code="${escapeHtml(c.code)}" title="Sao chép mã code">
                            <i class="bi bi-copy"></i>
                        </button>
                    </div>
                </td>
                <td>
                    <div class="coupon-info-cell">
                        <strong class="text-dark d-block">${escapeHtml(c.name)}</strong>
                        ${c.description ? `<small class="text-muted d-block text-truncate" style="max-width: 240px;">${escapeHtml(c.description)}</small>` : ''}
                        <div class="coupon-tags mt-1 d-flex flex-wrap gap-1">
                            <span class="badge badge-target ${targetClass}">${escapeHtml(c.targetCustomerText || '')}</span>
                            ${c.applicableCategoryId ? `<span class="badge bg-primary-subtle text-primary border" title="Mức giảm chỉ tính trên tổng giá trị sản phẩm thuộc danh mục này"><i class="bi bi-tag-fill me-1"></i>Chỉ giảm DM: ${escapeHtml(c.categoryText || '')}</span>` : ''}
                        </div>
                    </div>
                </td>
                <td>
                    <div class="discount-cell">
                        <span class="discount-value fw-bold ${discountColor}">${freeshipIcon}${escapeHtml(c.discountText || '')}</span>
                        ${isPercent && c.maxDiscountText ? `<small class="text-muted d-block">${escapeHtml(c.maxDiscountText)}</small>` : ''}
                        ${freeshipSub}
                    </div>
                </td>
                <td>
                    <span class="text-dark fw-semibold">${escapeHtml(c.minOrderText || '')}</span>
                </td>
                <td>
                    <div class="usage-box">
                        <div class="usage-count d-flex justify-content-between small mb-1">
                            <span><b class="text-dark">${c.usedCount}</b> / <span>${c.quantity}</span></span>
                            <span class="text-muted">${c.usagePercent}%</span>
                        </div>
                        <div class="progress" style="height: 6px;">
                            <div class="progress-bar ${progressClass}" role="progressbar" style="width: ${c.usagePercent}%"></div>
                        </div>
                        <small class="text-muted d-block mt-1">Tối đa ${c.perUserLimit} lần/khách</small>
                    </div>
                </td>
                <td>
                    <div class="revenue-cell">
                        <strong class="text-success d-block">${escapeHtml(c.totalRevenueFormatted || '0 ₫')}</strong>
                        ${c.totalDiscount && Number(c.totalDiscount) > 0 ? `<small class="text-danger d-block">Đã giảm: −${escapeHtml(c.totalDiscountFormatted || '0 ₫')}</small>` : ''}
                    </div>
                </td>
                <td>
                    <div class="date-cell small">
                        <div class="text-secondary"><i class="bi bi-calendar-event me-1"></i><span>${escapeHtml(c.startDateText || '')}</span></div>
                        <div class="text-muted"><i class="bi bi-clock me-1"></i><span>${escapeHtml(c.endDateText || '')}</span></div>
                    </div>
                </td>
                <td>
                    <span class="status-pill badge ${c.statusBadgeClass || ''}">${escapeHtml(c.computedStatusText || '')}</span>
                </td>
                <td class="text-end">
                    <div class="action-btn-group d-inline-flex gap-1">
                        <button type="button" class="btn btn-sm btn-icon toggle-status-btn"
                                data-id="${c.id}" data-code="${escapeHtml(c.code)}"
                                title="${isActive ? 'Tạm dừng mã này' : 'Kích hoạt lại mã'}">
                            <i class="bi ${isActive ? 'bi-pause-circle text-warning' : 'bi-play-circle text-success'}"></i>
                        </button>

                        <button type="button" class="btn btn-sm btn-icon edit-coupon-btn"
                                data-id="${c.id}"
                                data-code="${escapeHtml(c.code)}"
                                data-name="${escapeHtml(c.name)}"
                                data-description="${escapeHtml(c.description || '')}"
                                data-type="${c.discountType}"
                                data-value="${c.discountValue !== undefined && c.discountValue !== null ? c.discountValue : ''}"
                                data-max="${c.maxDiscount !== undefined && c.maxDiscount !== null ? c.maxDiscount : ''}"
                                data-min="${c.minOrderValue !== undefined && c.minOrderValue !== null ? c.minOrderValue : ''}"
                                data-quantity="${c.quantity}"
                                data-peruser="${c.perUserLimit}"
                                data-target="${c.targetCustomerType}"
                                data-cat="${c.applicableCategoryId || ''}"
                                data-start="${c.startDateIso || ''}"
                                data-end="${c.endDateIso || ''}"
                                title="Chỉnh sửa mã">
                            <i class="bi bi-pencil-square text-primary"></i>
                        </button>

                        <button type="button" class="btn btn-sm btn-icon delete-coupon-btn"
                                data-id="${c.id}" data-code="${escapeHtml(c.code)}"
                                title="Xóa mã">
                            <i class="bi bi-trash3 text-danger"></i>
                        </button>
                    </div>
                </td>
            </tr>
        `;
    }

    // 5. Main Initialization
    document.addEventListener('DOMContentLoaded', function () {
        const toggleCreateBtn = document.getElementById('toggleCreateFormBtn');
        const closeCreateBtn = document.getElementById('closeCreateFormBtn');
        const createSection = document.getElementById('create-coupon-section');
        const newCouponForm = document.getElementById('newCouponForm');
        const couponRowsTbody = document.getElementById('couponRows');
        const noResultsRow = document.getElementById('noResultsRow');

        // --- 5.1 Toggle Create Form ---
        function openCreateForm() {
            if (!createSection) return;
            createSection.style.display = 'block';
            createSection.scrollIntoView({ behavior: 'smooth', block: 'start' });
            const codeInput = document.getElementById('couponCodeInput');
            if (codeInput) setTimeout(() => codeInput.focus(), 250);
        }

        function closeCreateForm() {
            if (!createSection) return;
            createSection.style.display = 'none';
        }

        function toggleCreateForm() {
            if (!createSection) return;
            const isHidden = (createSection.style.display === 'none' || !createSection.style.display);
            if (isHidden) {
                openCreateForm();
            } else {
                closeCreateForm();
            }
        }

        if (toggleCreateBtn) toggleCreateBtn.addEventListener('click', toggleCreateForm);
        if (closeCreateBtn) closeCreateBtn.addEventListener('click', closeCreateForm);

        // --- 5.2 Auto-fill default dates ---
        const newStart = document.getElementById('newStartDate');
        const newEnd = document.getElementById('newEndDate');
        function initDefaultDates() {
            if (newStart && !newStart.value) {
                const now = new Date();
                const pad = n => String(n).padStart(2, '0');
                const format = d => `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}`;
                newStart.value = format(now);
                const nextMonth = new Date(now);
                nextMonth.setDate(nextMonth.getDate() + 30);
                if (newEnd && !newEnd.value) newEnd.value = format(nextMonth);
            }
        }
        initDefaultDates();

        // --- 5.3 Generate Random Code ---
        const generateBtn = document.getElementById('generateCodeBtn');
        const codeInput = document.getElementById('couponCodeInput');
        if (generateBtn && codeInput) {
            generateBtn.addEventListener('click', function () {
                const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
                let random = 'FS';
                for (let i = 0; i < 6; i++) {
                    random += chars.charAt(Math.floor(Math.random() * chars.length));
                }
                codeInput.value = random;
                codeInput.classList.add('is-valid');
                setTimeout(() => codeInput.classList.remove('is-valid'), 800);
            });
        }

        // --- 5.4 Discount type sync in Create Form ---
        const discountTypeSelect = document.getElementById('discountTypeSelect');
        const discountValueLabel = document.getElementById('discountValueLabel');
        const discountValueInput = document.getElementById('discountValueInput');
        const maxDiscountCol = document.getElementById('maxDiscountCol');

        if (discountTypeSelect) {
            discountTypeSelect.addEventListener('change', function () {
                syncDiscountType(this.value, discountValueLabel, discountValueInput, maxDiscountCol);
            });
            syncDiscountType(discountTypeSelect.value, discountValueLabel, discountValueInput, maxDiscountCol);
        }

        // --- 5.5 Edit Modal setup & Discount type sync in Edit Modal ---
        const editModalEl = document.getElementById('editCouponModal');
        const editForm = document.getElementById('editCouponForm');
        const modalEditDiscountType = document.getElementById('modalEditDiscountType');
        const modalEditValueLabel = document.getElementById('modalEditValueLabel');
        const modalEditDiscountValue = document.getElementById('modalEditDiscountValue');
        const modalEditMaxDiscountCol = document.getElementById('modalEditMaxDiscountCol');

        if (modalEditDiscountType) {
            modalEditDiscountType.addEventListener('change', function () {
                syncDiscountType(this.value, modalEditValueLabel, modalEditDiscountValue, modalEditMaxDiscountCol);
            });
        }

        function populateEditModal(btn) {
            const id = btn.getAttribute('data-id');
            const code = btn.getAttribute('data-code');
            const name = btn.getAttribute('data-name');
            const description = btn.getAttribute('data-description');
            const type = btn.getAttribute('data-type');
            const value = btn.getAttribute('data-value');
            const max = btn.getAttribute('data-max');
            const min = btn.getAttribute('data-min');
            const quantity = btn.getAttribute('data-quantity');
            const peruser = btn.getAttribute('data-peruser');
            const target = btn.getAttribute('data-target');
            const cat = btn.getAttribute('data-cat');
            const start = btn.getAttribute('data-start');
            const end = btn.getAttribute('data-end');

            if (editForm) {
                editForm.action = `/admin/coupons/${id}/edit`;
                editForm.setAttribute('data-target-row-id', id);
            }

            const codeEl = document.getElementById('modalEditCode');
            if (codeEl) codeEl.innerText = code || '';

            const nameEl = document.getElementById('modalEditName');
            if (nameEl) nameEl.value = name || '';

            const descEl = document.getElementById('modalEditDescription');
            if (descEl) descEl.value = description || '';

            if (modalEditDiscountType) {
                modalEditDiscountType.value = type || 'PERCENT';
                syncDiscountType(modalEditDiscountType.value, modalEditValueLabel, modalEditDiscountValue, modalEditMaxDiscountCol);
            }

            if (modalEditDiscountValue) modalEditDiscountValue.value = value !== '' ? value : 0;
            const maxEl = document.getElementById('modalEditMaxDiscount');
            if (maxEl) maxEl.value = max || '';

            const minEl = document.getElementById('modalEditMinOrder');
            if (minEl) minEl.value = min || '';

            const qtyEl = document.getElementById('modalEditQuantity');
            if (qtyEl) qtyEl.value = quantity || 1;

            const perUserEl = document.getElementById('modalEditPerUser');
            if (perUserEl) perUserEl.value = peruser || 1;

            const targetEl = document.getElementById('modalEditTarget');
            if (targetEl) targetEl.value = target || 'ALL';

            const catEl = document.getElementById('modalEditCategory');
            if (catEl) catEl.value = cat || '';

            const formatIso = iso => iso ? iso.substring(0, 16) : '';
            const startEl = document.getElementById('modalEditStartDate');
            if (startEl) startEl.value = formatIso(start);

            const endEl = document.getElementById('modalEditEndDate');
            if (endEl) endEl.value = formatIso(end);

            if (editModalEl && window.bootstrap) {
                let bsModal = bootstrap.Modal.getInstance(editModalEl);
                if (!bsModal) bsModal = new bootstrap.Modal(editModalEl);
                bsModal.show();
            }
        }

        // --- 5.6 Row Event Binding ---
        function bindRowEvents(row) {
            if (!row) return;

            // Copy Code button
            const copyBtn = row.querySelector('.copy-code');
            if (copyBtn) {
                copyBtn.addEventListener('click', function (e) {
                    e.preventDefault();
                    const code = this.getAttribute('data-code');
                    if (code) {
                        navigator.clipboard.writeText(code).then(() => {
                            showToast(`Đã sao chép mã "${code}" vào bộ nhớ tạm!`, 'info', 2000);
                            const icon = this.querySelector('i');
                            if (icon) {
                                icon.classList.remove('bi-copy');
                                icon.classList.add('bi-check2', 'text-success');
                                setTimeout(() => {
                                    icon.classList.remove('bi-check2', 'text-success');
                                    icon.classList.add('bi-copy');
                                }, 1500);
                            }
                        }).catch(() => {
                            showToast(`Mã code: ${code}`, 'info');
                        });
                    }
                });
            }

            // Edit button
            const editBtn = row.querySelector('.edit-coupon-btn');
            if (editBtn) {
                editBtn.addEventListener('click', function (e) {
                    e.preventDefault();
                    populateEditModal(this);
                });
            }

            // Toggle Status button (AJAX)
            const toggleBtn = row.querySelector('.toggle-status-btn');
            if (toggleBtn) {
                toggleBtn.addEventListener('click', function (e) {
                    e.preventDefault();
                    const id = this.getAttribute('data-id');
                    const code = this.getAttribute('data-code');
                    if (!id) return;

                    const icon = this.querySelector('i');
                    const originalClass = icon ? icon.className : '';
                    if (icon) icon.className = 'spinner-border spinner-border-sm text-secondary';
                    this.disabled = true;

                    fetch(`/admin/coupons/${id}/toggle-status`, {
                        method: 'POST',
                        headers: {
                            'X-Requested-With': 'XMLHttpRequest',
                            'Accept': 'application/json'
                        }
                    })
                    .then(res => res.json())
                    .then(data => {
                        this.disabled = false;
                        if (data.success) {
                            showToast(data.message || `Chuyển trạng thái mã ${code} thành công!`, 'success');
                            updateKpis(data.stats);

                            // Cập nhật DOM hàng
                            const statusPill = row.querySelector('.status-pill');
                            if (statusPill) {
                                statusPill.className = `status-pill badge ${data.statusBadgeClass || ''}`;
                                statusPill.textContent = data.computedStatusText || '';
                            }

                            row.setAttribute('data-status', (data.computedStatus || '').toLowerCase());

                            const isNowActive = data.status === 'ACTIVE';
                            if (icon) {
                                icon.className = isNowActive
                                    ? 'bi bi-pause-circle text-warning'
                                    : 'bi bi-play-circle text-success';
                            }
                            this.setAttribute('title', isNowActive ? 'Tạm dừng mã này' : 'Kích hoạt lại mã');

                            // Re-filter so tab filtering stays consistent
                            filterRows();
                        } else {
                            if (icon) icon.className = originalClass;
                            showToast(data.message || 'Không thể thay đổi trạng thái', 'error');
                        }
                    })
                    .catch(err => {
                        this.disabled = false;
                        if (icon) icon.className = originalClass;
                        showToast('Lỗi kết nối máy chủ: ' + err.message, 'error');
                    });
                });
            }

            // Delete button (AJAX)
            const deleteBtn = row.querySelector('.delete-coupon-btn');
            if (deleteBtn) {
                deleteBtn.addEventListener('click', function (e) {
                    e.preventDefault();
                    const id = this.getAttribute('data-id');
                    const code = this.getAttribute('data-code');
                    if (!id) return;

                    if (!confirm(`Bạn có chắc chắn muốn xóa mã "${code}"? Nếu mã đã được khách sử dụng trong đơn hàng, hệ thống sẽ chuyển sang trạng thái Vô hiệu hóa.`)) {
                        return;
                    }

                    this.disabled = true;
                    const icon = this.querySelector('i');
                    if (icon) icon.className = 'spinner-border spinner-border-sm text-danger';

                    fetch(`/admin/coupons/${id}/delete`, {
                        method: 'POST',
                        headers: {
                            'X-Requested-With': 'XMLHttpRequest',
                            'Accept': 'application/json'
                        }
                    })
                    .then(res => res.json())
                    .then(data => {
                        if (data.success) {
                            showToast(data.message || `Đã xóa mã ${code} thành công!`, 'success');
                            updateKpis(data.stats);

                            if (data.action === 'DELETED') {
                                row.classList.add('coupon-row-fadeout');
                                setTimeout(() => {
                                    row.remove();
                                    filterRows();
                                    checkEmptyState();
                                }, 350);
                            } else if (data.action === 'DISABLED' && data.coupon) {
                                // Cập nhật sang trạng thái DISABLED
                                const statusPill = row.querySelector('.status-pill');
                                if (statusPill) {
                                    statusPill.className = `status-pill badge ${data.coupon.statusBadgeClass || 'status-paused'}`;
                                    statusPill.textContent = data.coupon.computedStatusText || 'Tạm dừng';
                                }
                                row.setAttribute('data-status', (data.coupon.computedStatus || 'paused').toLowerCase());
                                if (icon) icon.className = 'bi bi-trash3 text-danger';
                                this.disabled = false;
                                filterRows();
                            }
                        } else {
                            if (icon) icon.className = 'bi bi-trash3 text-danger';
                            this.disabled = false;
                            showToast(data.message || 'Lỗi khi xóa mã', 'error');
                        }
                    })
                    .catch(err => {
                        if (icon) icon.className = 'bi bi-trash3 text-danger';
                        this.disabled = false;
                        showToast('Lỗi kết nối máy chủ: ' + err.message, 'error');
                    });
                });
            }
        }

        // Bind existing rows on initial load
        document.querySelectorAll('.coupon-row').forEach(bindRowEvents);

        // --- 5.7 AJAX Submit for New Coupon Form ---
        if (newCouponForm) {
            newCouponForm.addEventListener('submit', function (e) {
                e.preventDefault();

                const submitBtn = newCouponForm.querySelector('button[type="submit"]');
                const originalBtnHtml = submitBtn ? submitBtn.innerHTML : '';
                if (submitBtn) {
                    submitBtn.disabled = true;
                    submitBtn.innerHTML = '<span class="spinner-border spinner-border-sm me-1"></span> Đang tạo mã...';
                }

                const formData = new FormData(newCouponForm);
                if (formData.get('discountType') === 'FREESHIP') {
                    if (!formData.get('discountValue') || formData.get('discountValue').trim() === '') {
                        formData.set('discountValue', '0');
                    }
                    formData.delete('maxDiscount');
                } else if (formData.get('discountType') === 'FIXED_AMOUNT') {
                    formData.delete('maxDiscount');
                }

                fetch('/admin/coupons', {
                    method: 'POST',
                    headers: {
                        'X-Requested-With': 'XMLHttpRequest',
                        'Accept': 'application/json'
                    },
                    body: formData
                })
                .then(res => res.json())
                .then(data => {
                    if (submitBtn) {
                        submitBtn.disabled = false;
                        submitBtn.innerHTML = originalBtnHtml;
                    }

                    if (data.success && data.coupon) {
                        showToast(data.message || 'Tạo mã giảm giá thành công!', 'success');
                        updateKpis(data.stats);

                        // Xóa empty state nếu có
                        const emptyStateRow = document.querySelector('.empty-state')?.closest('tr');
                        if (emptyStateRow) emptyStateRow.remove();

                        // Tạo DOM row mới và prepend vào bảng
                        const tempContainer = document.createElement('tbody');
                        tempContainer.innerHTML = buildRowHtml(data.coupon);
                        const newRow = tempContainer.firstElementChild;

                        if (couponRowsTbody) {
                            couponRowsTbody.prepend(newRow);
                            bindRowEvents(newRow);
                        }

                        // Reset form và đóng form tạo mới
                        newCouponForm.reset();
                        initDefaultDates();
                        closeCreateForm();

                        // Scroll đến dòng mới tạo và áp bộ lọc
                        setTimeout(() => {
                            newRow.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
                            filterRows();
                        }, 200);
                    } else {
                        showToast(data.message || 'Không thể tạo mã giảm giá. Vui lòng kiểm tra lại thông tin.', 'error', 4500);
                    }
                })
                .catch(err => {
                    if (submitBtn) {
                        submitBtn.disabled = false;
                        submitBtn.innerHTML = originalBtnHtml;
                    }
                    showToast('Lỗi máy chủ khi tạo mã: ' + err.message, 'error', 4500);
                });
            });
        }

        // --- 5.8 AJAX Submit for Edit Coupon Form ---
        if (editForm) {
            editForm.addEventListener('submit', function (e) {
                e.preventDefault();

                const submitBtn = editForm.querySelector('button[type="submit"]');
                const originalBtnHtml = submitBtn ? submitBtn.innerHTML : '';
                if (submitBtn) {
                    submitBtn.disabled = true;
                    submitBtn.innerHTML = '<span class="spinner-border spinner-border-sm me-1"></span> Đang lưu...';
                }

                const formData = new FormData(editForm);
                if (formData.get('discountType') === 'FREESHIP') {
                    if (!formData.get('discountValue') || formData.get('discountValue').trim() === '') {
                        formData.set('discountValue', '0');
                    }
                    formData.delete('maxDiscount');
                } else if (formData.get('discountType') === 'FIXED_AMOUNT') {
                    formData.delete('maxDiscount');
                }

                const targetRowId = editForm.getAttribute('data-target-row-id');

                fetch(editForm.action, {
                    method: 'POST',
                    headers: {
                        'X-Requested-With': 'XMLHttpRequest',
                        'Accept': 'application/json'
                    },
                    body: formData
                })
                .then(res => res.json())
                .then(data => {
                    if (submitBtn) {
                        submitBtn.disabled = false;
                        submitBtn.innerHTML = originalBtnHtml;
                    }

                    if (data.success && data.coupon) {
                        showToast(data.message || 'Cập nhật mã giảm giá thành công!', 'success');
                        updateKpis(data.stats);

                        // Tìm dòng cũ và thay thế bằng nội dung mới
                        const oldRow = document.getElementById(`coupon-row-${targetRowId}`);
                        if (oldRow) {
                            const tempContainer = document.createElement('tbody');
                            tempContainer.innerHTML = buildRowHtml(data.coupon);
                            const updatedRow = tempContainer.firstElementChild;
                            updatedRow.className = 'coupon-row coupon-row-updated';

                            oldRow.replaceWith(updatedRow);
                            bindRowEvents(updatedRow);
                        }

                        // Đóng modal
                        if (editModalEl && window.bootstrap) {
                            const bsModal = bootstrap.Modal.getInstance(editModalEl);
                            if (bsModal) bsModal.hide();
                        }

                        filterRows();
                    } else {
                        showToast(data.message || 'Lỗi cập nhật mã giảm giá', 'error', 4500);
                    }
                })
                .catch(err => {
                    if (submitBtn) {
                        submitBtn.disabled = false;
                        submitBtn.innerHTML = originalBtnHtml;
                    }
                    showToast('Lỗi kết nối máy chủ: ' + err.message, 'error', 4500);
                });
            });
        }

        // --- 5.9 Dynamic Filtering (Tabs, Instant Search, Dropdowns) ---
        const tabs = document.querySelectorAll('.coupon-tab');
        const searchInput = document.getElementById('couponSearch');
        const typeFilter = document.getElementById('couponTypeFilter');
        const targetFilter = document.getElementById('couponTargetFilter');

        function checkEmptyState() {
            const allRows = document.querySelectorAll('.coupon-row');
            const emptyState = document.getElementById('emptyTableState');
            if (emptyState) {
                emptyState.style.display = allRows.length === 0 ? '' : 'none';
            }
        }

        function filterRows() {
            const activeTab = document.querySelector('.coupon-tab.active')?.getAttribute('data-filter') || 'all';
            const query = (searchInput?.value || '').toLowerCase().trim();
            const selectedType = typeFilter?.value || '';
            const selectedTarget = targetFilter?.value || '';

            const rows = document.querySelectorAll('.coupon-row');
            let visibleCount = 0;

            rows.forEach(function (row) {
                const status = (row.getAttribute('data-status') || '').toLowerCase();
                const type = row.getAttribute('data-type') || '';
                const target = row.getAttribute('data-target') || '';
                const searchData = (row.getAttribute('data-search') || '').toLowerCase();

                let matchesTab = false;
                if (activeTab === 'all') {
                    matchesTab = true;
                } else if (activeTab === 'paused') {
                    matchesTab = (status === 'paused' || status === 'disabled' || status === 'inactive');
                } else {
                    matchesTab = (status === activeTab);
                }

                const matchesSearch = !query || searchData.includes(query);
                const matchesType = !selectedType || (type === selectedType);
                const matchesTarget = !selectedTarget || (target === selectedTarget);

                const isVisible = matchesTab && matchesSearch && matchesType && matchesTarget;
                row.style.display = isVisible ? '' : 'none';
                if (isVisible) visibleCount++;
            });

            if (noResultsRow) {
                noResultsRow.style.display = (visibleCount === 0 && rows.length > 0) ? '' : 'none';
            }
        }

        tabs.forEach(function (tab) {
            tab.addEventListener('click', function () {
                tabs.forEach(t => t.classList.remove('active'));
                this.classList.add('active');
                filterRows();
            });
        });

        let searchDebounceTimer = null;
        if (searchInput) {
            searchInput.addEventListener('input', function () {
                if (searchDebounceTimer) clearTimeout(searchDebounceTimer);
                searchDebounceTimer = setTimeout(filterRows, 150);
            });
        }

        if (typeFilter) typeFilter.addEventListener('change', filterRows);
        if (targetFilter) targetFilter.addEventListener('change', filterRows);

        // Initial filter evaluation
        filterRows();
    });
})();
