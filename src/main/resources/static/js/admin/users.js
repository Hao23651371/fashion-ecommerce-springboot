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

            // Gắn lại sự kiện cho phân trang và nút sắp xếp ID
            bindAjaxPagination();
            bindSortToggle();
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
    // 8. KHỞI TẠO BOOTSTRAP POPOVER & XỬ LÝ HOVER TÌM KIẾM
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
}

// Tự động khởi chạy khi DOM đã sẵn sàng
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initAdminUsers);
} else {
    initAdminUsers();
}
