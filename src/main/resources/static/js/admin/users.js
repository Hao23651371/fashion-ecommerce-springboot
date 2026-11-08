/**
 * JavaScript riêng cho trang Quản lý Tài khoản (Admin Users)
 * Hỗ trợ AJAX tìm kiếm, bộ lọc tức thì không load lại trang, sắp xếp ID động và quản lý Modal.
 */

function initAdminUsers() {
    const filterForm = document.getElementById('filterAccountForm');
    const filterBtn = document.getElementById('filterSubmitBtn');
    const resetBtn = document.getElementById('resetFilterBtn');
    const tableWrapper = document.getElementById('accountTableWrapper');

    // =========================================================================
    // 1. AJAX TẢI DỮ LIỆU BẢNG & THỐNG KÊ (MƯỢT MÀ, KHÔNG RELOAD TRANG)
    // =========================================================================
    function loadAccountsAjax(targetUrl, pushState = true) {
        if (!tableWrapper) return;

        // Hiệu ứng mờ bảng trong khi tải
        tableWrapper.classList.add('table-loading');
        if (filterBtn) {
            filterBtn.disabled = true;
            filterBtn.innerHTML = '<span class="spinner-border spinner-border-sm me-1" role="status" aria-hidden="true"></span><span>Đang lọc...</span>';
        }

        fetch(targetUrl, {
            headers: { 'X-Requested-With': 'XMLHttpRequest' }
        })
        .then(res => {
            if (!res.ok) throw new Error('Phản hồi mạng không thành công');
            return res.text();
        })
        .then(html => {
            const parser = new DOMParser();
            const doc = parser.parseFromString(html, 'text/html');

            // Dọn dẹp popover cũ trước khi đổi HTML
            document.querySelectorAll('.verification-popover-trigger').forEach(function (el) {
                if (typeof bootstrap !== 'undefined' && bootstrap.Popover) {
                    const pop = bootstrap.Popover.getInstance(el);
                    if (pop) pop.dispose();
                }
            });

            // Cập nhật Bảng dữ liệu và phân trang
            const newTable = doc.getElementById('accountTableWrapper');
            if (newTable && tableWrapper) {
                tableWrapper.innerHTML = newTable.innerHTML;
            }

            // Cập nhật Thẻ thống kê
            const newStats = doc.getElementById('statsCardsRow');
            const currentStats = document.getElementById('statsCardsRow');
            if (newStats && currentStats) {
                currentStats.innerHTML = newStats.innerHTML;
            }

            // Cập nhật URL trình duyệt
            if (pushState) {
                window.history.pushState({ url: targetUrl }, '', targetUrl);
            }

            // Đồng bộ giá trị input sortDir ngầm trong form
            try {
                const urlObj = new URL(targetUrl, window.location.origin);
                const currentSort = urlObj.searchParams.get('sortDir') || 'asc';
                const sortDirInput = document.getElementById('sortDirInput');
                if (sortDirInput) {
                    sortDirInput.value = currentSort;
                }
            } catch (e) {
                console.warn('URL parse fallback:', e);
            }

            // Gắn lại sự kiện cho phân trang, nút sắp xếp ID và Popovers
            bindAjaxPagination();
            bindSortToggle();
            initVerificationPopovers();
        })
        .catch(err => {
            console.error('Lỗi khi tải dữ liệu qua AJAX:', err);
            // Fallback load trang nếu gặp sự cố mạng
            window.location.href = targetUrl;
        })
        .finally(() => {
            tableWrapper.classList.remove('table-loading');
            if (filterBtn) {
                filterBtn.disabled = false;
                filterBtn.innerHTML = '<i class="bi bi-funnel-fill me-1"></i><span>Lọc</span>';
            }
        });
    }

    // =========================================================================
    // 2. NÚT SẮP XẾP ID: TĂNG DẦN (MẶC ĐỊNH - TẮT) / GIẢM DẦN (SÁNG MÀU)
    // =========================================================================
    function bindSortToggle() {
        const toggleSortBtn = document.getElementById('toggleSortBtn');
        const sortDirInput = document.getElementById('sortDirInput');

        if (toggleSortBtn && sortDirInput) {
            // Xóa listener cũ tránh trùng lặp
            toggleSortBtn.onclick = function (e) {
                e.preventDefault();
                e.stopPropagation();

                const currentDir = (sortDirInput.value || 'asc').toLowerCase();
                const nextDir = (currentDir === 'desc') ? 'asc' : 'desc';
                sortDirInput.value = nextDir;

                // Cập nhật giao diện tức thì
                if (nextDir === 'desc') {
                    toggleSortBtn.classList.remove('btn-light', 'text-secondary', 'bg-white');
                    toggleSortBtn.classList.add('btn-primary', 'text-white', 'shadow-sm', 'sort-active');
                    toggleSortBtn.title = 'Đang sắp xếp giảm dần (Sáng màu). Bấm để tắt và sắp xếp ID tăng dần';
                } else {
                    toggleSortBtn.classList.remove('btn-primary', 'text-white', 'shadow-sm', 'sort-active');
                    toggleSortBtn.classList.add('btn-light', 'text-secondary', 'border', 'bg-white');
                    toggleSortBtn.title = 'Đang sắp xếp tăng dần mặc định (Tắt). Bấm để sắp xếp ID giảm dần';
                }

                // Kích hoạt submit form để lấy dữ liệu mới qua AJAX
                if (filterForm) {
                    filterForm.dispatchEvent(new Event('submit'));
                }
            };
        }
    }
    bindSortToggle();

    // =========================================================================
    // 3. SUBMIT FORM BỘ LỌC QUA AJAX
    // =========================================================================
    if (filterForm) {
        filterForm.addEventListener('submit', function (e) {
            e.preventDefault();
            const formData = new FormData(filterForm);
            const params = new URLSearchParams();

            for (const [key, value] of formData.entries()) {
                if (value && value.toString().trim() !== '') {
                    params.append(key, value.toString().trim());
                }
            }

            // Reset về page 0 khi thực hiện tìm kiếm / lọc mới
            params.set('page', '0');
            if (!params.has('size')) {
                params.set('size', '15');
            }

            const targetUrl = filterForm.getAttribute('action') + '?' + params.toString();
            loadAccountsAjax(targetUrl);
        });
    }

    // =========================================================================
    // 4. NÚT ĐẶT LẠI (RESET) VỀ MẶC ĐỊNH
    // =========================================================================
    if (resetBtn) {
        resetBtn.addEventListener('click', function () {
            document.getElementById('searchKeywordInput').value = '';
            document.getElementById('filterRole').value = '';
            document.getElementById('filterStatus').value = '';
            document.getElementById('filterVerified').value = '';
            const sortDirInput = document.getElementById('sortDirInput');
            if (sortDirInput) {
                sortDirInput.value = 'asc';
            }
            loadAccountsAjax('/admin/users?size=15&sortDir=asc');
        });
    }

    // =========================================================================
    // 5. GẮN SỰ KIỆN CHO CÁC LIÊN KẾT PHÂN TRANG
    // =========================================================================
    function bindAjaxPagination() {
        document.querySelectorAll('.ajax-page-link').forEach(function (link) {
            link.addEventListener('click', function (e) {
                e.preventDefault();
                const href = this.getAttribute('href');
                if (href && !this.closest('.page-item').classList.contains('disabled')) {
                    loadAccountsAjax(href);
                }
            });
        });
    }
    bindAjaxPagination();

    // Lắng nghe nút quay lại / tiến tới trên trình duyệt
    window.addEventListener('popstate', function () {
        loadAccountsAjax(window.location.href, false);
    });

    // =========================================================================
    // 6. MODAL CHỈNH SỬA TÀI KHOẢN (EDIT)
    // =========================================================================
    const editModal = document.getElementById('editAccountModal');
    if (editModal) {
        editModal.addEventListener('show.bs.modal', function (event) {
            const button = event.relatedTarget;
            if (!button) return;

            const id = button.getAttribute('data-id');
            const email = button.getAttribute('data-email');
            const role = button.getAttribute('data-role');
            const status = button.getAttribute('data-status');
            const verified = button.getAttribute('data-verified');
            const code = button.getAttribute('data-code');
            const expiry = button.getAttribute('data-expiry');
            const created = button.getAttribute('data-created');
            const login = button.getAttribute('data-login');

            document.getElementById('editAccountForm').action = '/admin/users/edit/' + id;
            document.getElementById('editId').value = id;
            document.getElementById('editEmail').value = email || '';
            document.getElementById('editRole').value = role || 'CUSTOMER';
            document.getElementById('editStatus').value = status || 'ACTIVE';
            document.getElementById('editVerified').value = (verified === 'true') ? 'true' : 'false';
            document.getElementById('editCode').value = code || '';
            document.getElementById('editExpiry').value = expiry || '';
            document.getElementById('editCreated').textContent = created || '—';
            document.getElementById('editLogin').textContent = login || 'Chưa đăng nhập';

            const editCodeDisplay = document.getElementById('editCodeDisplay');
            if (editCodeDisplay) {
                editCodeDisplay.innerHTML = (code && code.trim() !== '' && code !== 'null')
                    ? `<code class="bg-light text-primary px-2 py-0.5 rounded border font-monospace fw-bold">${code}</code>`
                    : '<span class="text-muted fst-italic">— (Không có)</span>';
            }
            const editExpiryDisplay = document.getElementById('editExpiryDisplay');
            if (editExpiryDisplay) {
                editExpiryDisplay.textContent = (expiry && expiry.trim() !== '' && expiry !== 'null')
                    ? expiry.replace('T', ' ')
                    : '—';
            }
        });
    }

    // =========================================================================
    // 7. MODAL XÁC NHẬN XÓA TÀI KHOẢN (DELETE)
    // =========================================================================
    const deleteModal = document.getElementById('deleteAccountModal');
    if (deleteModal) {
        deleteModal.addEventListener('show.bs.modal', function (event) {
            const button = event.relatedTarget;
            if (!button) return;

            const id = button.getAttribute('data-id');
            const email = button.getAttribute('data-email');

            document.getElementById('deleteAccountForm').action = '/admin/users/' + id + '/delete';
            document.getElementById('deleteAccountEmail').textContent = email + ' (#' + id + ')';
        });
    }

    // =========================================================================
    // 8. MODAL PHÂN QUYỀN TÀI KHOẢN (ROLE ASSIGNMENT & DATABASE SYNC)
    // =========================================================================
    const assignModal = document.getElementById('assignRoleModal');
    if (assignModal) {
        const roleRadios = assignModal.querySelectorAll('.role-radio-input');
        const roleCards = assignModal.querySelectorAll('.role-option-card');
        const summaryBadge = document.getElementById('roleSelectedSummaryBadge');
        const selfWarning = document.getElementById('selfRoleWarning');

        function updateRoleSelectionUI(selectedRole) {
            roleCards.forEach(card => card.classList.remove('selected'));
            const activeRadio = document.getElementById('roleRadio_' + selectedRole);
            if (activeRadio) {
                activeRadio.checked = true;
                const parentCard = activeRadio.closest('.role-option-card');
                if (parentCard) parentCard.classList.add('selected');
            }

            if (summaryBadge) {
                summaryBadge.textContent = selectedRole;
                if (selectedRole === 'ADMIN') {
                    summaryBadge.className = 'badge bg-danger text-white px-2 py-1 small';
                } else if (selectedRole === 'STAFF') {
                    summaryBadge.className = 'badge bg-purple text-white px-2 py-1 small';
                } else {
                    summaryBadge.className = 'badge bg-primary text-white px-2 py-1 small';
                }
            }

            const permItems = assignModal.querySelectorAll('.permission-item');
            permItems.forEach(item => {
                const requiredPerm = item.getAttribute('data-perm');
                let isActive = false;
                if (selectedRole === 'ADMIN') {
                    isActive = true;
                } else if (selectedRole === 'STAFF') {
                    isActive = (requiredPerm === 'ROLE_STAFF' || requiredPerm === 'ROLE_CUSTOMER');
                } else if (selectedRole === 'CUSTOMER') {
                    isActive = (requiredPerm === 'ROLE_CUSTOMER');
                }

                const icon = item.querySelector('.perm-icon');
                if (isActive) {
                    item.classList.remove('inactive');
                    if (icon) {
                        icon.className = 'bi bi-check-circle-fill text-success fs-6 perm-icon';
                    }
                } else {
                    item.classList.add('inactive');
                    if (icon) {
                        icon.className = 'bi bi-dash-circle text-muted fs-6 perm-icon';
                    }
                }
            });
        }

        roleRadios.forEach(radio => {
            radio.addEventListener('change', function () {
                if (this.checked) {
                    updateRoleSelectionUI(this.value);
                }
            });
        });

        assignModal.addEventListener('show.bs.modal', function (event) {
            const button = event.relatedTarget;
            if (!button) return;

            const id = button.getAttribute('data-id');
            const email = button.getAttribute('data-email');
            const role = button.getAttribute('data-role') || 'CUSTOMER';
            const isCurrent = button.getAttribute('data-is-current') === 'true';

            document.getElementById('assignRoleForm').action = '/admin/users/' + id + '/role';
            document.getElementById('roleModalIdBadge').textContent = '#' + id;
            document.getElementById('roleModalEmail').textContent = email || '—';

            const curBadge = document.getElementById('roleModalCurrentRoleBadge');
            if (curBadge) {
                curBadge.textContent = role;
                if (role === 'ADMIN') {
                    curBadge.className = 'badge bg-danger-subtle text-danger border border-danger-subtle px-3 py-1 rounded-pill';
                } else if (role === 'STAFF') {
                    curBadge.className = 'badge bg-purple-subtle text-purple border border-purple-subtle px-3 py-1 rounded-pill';
                } else {
                    curBadge.className = 'badge bg-primary-subtle text-primary border border-primary-subtle px-3 py-1 rounded-pill';
                }
            }

            const staffRadio = document.getElementById('roleRadio_STAFF');
            const customerRadio = document.getElementById('roleRadio_CUSTOMER');
            const staffCard = staffRadio ? staffRadio.closest('.role-option-card') : null;
            const customerCard = customerRadio ? customerRadio.closest('.role-option-card') : null;

            if (isCurrent) {
                if (selfWarning) {
                    selfWarning.classList.remove('d-none');
                    selfWarning.classList.add('d-flex');
                }
                if (staffRadio) staffRadio.disabled = true;
                if (customerRadio) customerRadio.disabled = true;
                if (staffCard) staffCard.classList.add('disabled');
                if (customerCard) customerCard.classList.add('disabled');
            } else {
                if (selfWarning) {
                    selfWarning.classList.add('d-none');
                    selfWarning.classList.remove('d-flex');
                }
                if (staffRadio) staffRadio.disabled = false;
                if (customerRadio) customerRadio.disabled = false;
                if (staffCard) staffCard.classList.remove('disabled');
                if (customerCard) customerCard.classList.remove('disabled');
            }

            updateRoleSelectionUI(role);
        });
    }

    // =========================================================================
    // 9. KHỞI TẠO BOOTSTRAP POPOVER & XỬ LÝ HOVER TÌM KIẾM
    // =========================================================================
    const searchPopoverContent = `
        <div style="font-size: 0.82rem; line-height: 1.5; min-width: 250px;">
            <div class="mb-2 pb-1 border-bottom">
                <span class="badge bg-primary me-1">1. Email</span>
                <strong>Địa chỉ Email</strong>
                <div class="text-secondary small">Tìm theo email đăng nhập (VD: <code>khach1@gmail.com</code>, <code>admin...</code>)</div>
            </div>
            <div>
                <span class="badge bg-secondary me-1">2. ID</span>
                <strong>Mã ID tài khoản</strong>
                <div class="text-secondary small">Nhập số ID tự tăng của tài khoản (VD: <code>1</code>, <code>2</code>, <code>6</code>...)</div>
            </div>
        </div>
    `;

    const popoverTargets = [
        document.getElementById('searchKeywordInput'),
        document.getElementById('searchIcon')
    ];

    popoverTargets.forEach(function (el) {
        if (el && typeof bootstrap !== 'undefined' && bootstrap.Popover) {
            new bootstrap.Popover(el, {
                trigger: 'hover focus',
                placement: 'bottom',
                html: true,
                title: '<div class="fw-bold text-primary"><i class="bi bi-search me-1"></i> Thông tin tìm kiếm</div>',
                content: searchPopoverContent,
                sanitize: false
            });
        }
    });

    // Xử lý card hover bằng JS
    const hoverCard = document.getElementById('searchHoverCard');
    const searchWrapper = document.querySelector('.search-hover-wrapper');
    const searchInput = document.getElementById('searchKeywordInput');

    if (hoverCard && searchWrapper) {
        const showCard = function () { hoverCard.style.display = 'block'; };
        const hideCard = function () { hoverCard.style.display = 'none'; };

        searchWrapper.addEventListener('mouseenter', showCard);
        searchWrapper.addEventListener('mouseleave', hideCard);
        if (searchInput) {
            searchInput.addEventListener('focus', showCard);
            searchInput.addEventListener('blur', hideCard);
        }
    }

    // =========================================================================
    // 10. KHỞI TẠO POPOVER XEM MÃ XÁC THỰC VÀ HẠN MÃ (EMAIL VERIFICATION POPOVER)
    // =========================================================================
    function initVerificationPopovers() {
        if (typeof bootstrap === 'undefined' || !bootstrap.Popover) return;

        // Khởi tạo tooltips
        if (bootstrap.Tooltip) {
            document.querySelectorAll('[data-bs-toggle="tooltip"]').forEach(function (el) {
                const oldTooltip = bootstrap.Tooltip.getInstance(el);
                if (oldTooltip) oldTooltip.dispose();
                new bootstrap.Tooltip(el);
            });
        }

        document.querySelectorAll('.verification-popover-trigger').forEach(function (el) {
            const oldInstance = bootstrap.Popover.getInstance(el);
            if (oldInstance) {
                oldInstance.dispose();
            }

            const isVerified = el.getAttribute('data-verified') === 'true';
            const code = el.getAttribute('data-code');
            const expiry = el.getAttribute('data-expiry');

            const statusBadge = isVerified
                ? '<span class="badge bg-success-subtle text-success border border-success-subtle px-2 py-0.5"><i class="bi bi-check-circle-fill me-1"></i>Đã xác thực</span>'
                : '<span class="badge bg-warning-subtle text-warning-emphasis border border-warning-subtle px-2 py-0.5"><i class="bi bi-clock-history me-1"></i>Chưa xác thực</span>';

            const codeDisplay = (code && code.trim() !== '' && code !== 'null')
                ? `<code class="bg-light text-primary px-2 py-1 rounded border font-monospace fw-bold fs-6">${code}</code>`
                : '<span class="text-muted fst-italic">— (Chưa có mã)</span>';

            const expiryDisplay = (expiry && expiry.trim() !== '' && expiry !== 'null')
                ? `<span class="text-dark fw-medium"><i class="bi bi-calendar-event me-1 text-secondary"></i>${expiry}</span>`
                : '<span class="text-muted fst-italic">—</span>';

            const popoverContent = `
                <div class="p-1" style="font-size: 0.83rem; min-width: 220px;">
                    <div class="d-flex justify-content-between align-items-center mb-2 pb-2 border-bottom">
                        <span class="text-muted">Trạng thái:</span>
                        <div>${statusBadge}</div>
                    </div>
                    <div class="d-flex justify-content-between align-items-center mb-2 pb-2 border-bottom">
                        <span class="text-muted">Mã OTP:</span>
                        <div>${codeDisplay}</div>
                    </div>
                    <div class="d-flex justify-content-between align-items-center">
                        <span class="text-muted">Hết hạn lúc:</span>
                        <div>${expiryDisplay}</div>
                    </div>
                </div>
            `;

            new bootstrap.Popover(el, {
                trigger: 'hover focus',
                placement: 'top',
                html: true,
                title: '<div class="fw-bold text-dark d-flex align-items-center gap-1 small"><i class="bi bi-shield-check text-primary"></i> Thông tin mã xác thực</div>',
                content: popoverContent,
                sanitize: false,
                container: 'body'
            });
        });
    }

    // Khởi tạo popover xác minh email lần đầu
    initVerificationPopovers();
}

// Tự động khởi chạy khi DOM đã sẵn sàng
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initAdminUsers);
} else {
    initAdminUsers();
}
