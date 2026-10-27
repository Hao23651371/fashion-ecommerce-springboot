function initAdminStatistics() {
    const filterForm = document.getElementById('statsFilterForm');
    const startDateInput = document.getElementById('startDateInput');
    const endDateInput = document.getElementById('endDateInput');
    const rangeGroup = document.querySelector('[data-toggle-group="range"]');

    function formatDate(date) {
        const year = date.getFullYear();
        const month = String(date.getMonth() + 1).padStart(2, '0');
        const day = String(date.getDate()).padStart(2, '0');
        return `${year}-${month}-${day}`;
    }

    // Tự động kích hoạt nút preset phù hợp dựa trên ngày đang chọn khi tải trang
    function syncActivePreset() {
        if (!rangeGroup || !startDateInput || !endDateInput) return;
        const sVal = startDateInput.value;
        const eVal = endDateInput.value;

        const today = new Date();
        const todayStr = formatDate(today);

        const d7 = new Date(today);
        d7.setDate(today.getDate() - 6);
        const d7Str = formatDate(d7);

        const mStart = new Date(today.getFullYear(), today.getMonth(), 1);
        const mEnd = new Date(today.getFullYear(), today.getMonth() + 1, 0);
        const mStartStr = formatDate(mStart);
        const mEndStr = formatDate(mEnd);

        let activePreset = 'custom';
        if (sVal === todayStr && eVal === todayStr) {
            activePreset = 'today';
        } else if (sVal === d7Str && eVal === todayStr) {
            activePreset = '7days';
        } else if (sVal === mStartStr && eVal === mEndStr) {
            activePreset = 'thisMonth';
        }

        rangeGroup.querySelectorAll('button').forEach(function (btn) {
            btn.classList.toggle('active', btn.getAttribute('data-preset') === activePreset);
        });
    }

    // Quản lý trạng thái các nhóm nút toggle
    document.querySelectorAll('[data-toggle-group]').forEach(function (group) {
        group.querySelectorAll('button').forEach(function (btn) {
            btn.addEventListener('click', function () {
                group.querySelectorAll('button').forEach(function (item) {
                    item.classList.remove('active');
                });
                btn.classList.add('active');

                // Nếu là nhóm range preset thì tính toán ngày tương ứng
                if (group.getAttribute('data-toggle-group') === 'range') {
                    const preset = btn.getAttribute('data-preset');
                    if (preset && preset !== 'custom') {
                        applyDatePreset(preset);
                    }
                }
            });
        });
    });

    // Hàm hỗ trợ chọn nhanh khoảng thời gian
    function applyDatePreset(preset) {
        const today = new Date();
        let start = new Date();
        let end = new Date();

        if (preset === 'today') {
            start = today;
            end = today;
        } else if (preset === '7days') {
            start = new Date(today);
            start.setDate(today.getDate() - 6);
            end = today;
        } else if (preset === 'thisMonth') {
            start = new Date(today.getFullYear(), today.getMonth(), 1);
            end = new Date(today.getFullYear(), today.getMonth() + 1, 0);
        }

        if (startDateInput && endDateInput && filterForm) {
            startDateInput.value = formatDate(start);
            endDateInput.value = formatDate(end);
            filterForm.submit();
        }
    }

    // Nếu người dùng tự chỉnh ô ngày, chuyển nút sang Tùy chọn
    if (startDateInput && endDateInput) {
        const handleManualDateChange = function () {
            if (rangeGroup) {
                rangeGroup.querySelectorAll('button').forEach(function (btn) {
                    btn.classList.toggle('active', btn.getAttribute('data-preset') === 'custom');
                });
            }
        };
        startDateInput.addEventListener('change', handleManualDateChange);
        endDateInput.addEventListener('change', handleManualDateChange);
    }

    // Phím tắt Ctrl+K để focus ô tìm kiếm & lọc bảng Top sản phẩm theo từ khóa
    const searchInput = document.getElementById('statsSearchInput');
    if (searchInput) {
        document.addEventListener('keydown', function (e) {
            if ((e.ctrlKey || e.metaKey) && e.key === 'k') {
                e.preventDefault();
                searchInput.focus();
            }
        });

        // Tìm kiếm nhanh trên bảng Top 5 sản phẩm
        searchInput.addEventListener('input', function () {
            const query = searchInput.value.trim().toLowerCase();
            const rows = document.querySelectorAll('#topProductsTable tbody tr');
            rows.forEach(function (row) {
                // Bỏ qua dòng thông báo trống
                if (row.cells.length < 5) return;
                const text = row.innerText.toLowerCase();
                row.style.display = (!query || text.includes(query)) ? '' : 'none';
            });
        });
    }

    // Khởi chạy đồng bộ trạng thái ban đầu
    syncActivePreset();
}

if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initAdminStatistics);
} else {
    initAdminStatistics();
}
