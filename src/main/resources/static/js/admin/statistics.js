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

    // Đồng bộ đường dẫn xuất file Excel theo khoảng ngày
    const exportExcelBtn = document.getElementById('statsExportExcelBtn');
    function updateExportExcelLink() {
        if (!exportExcelBtn || !startDateInput || !endDateInput) return;
        const s = startDateInput.value.trim();
        const e = endDateInput.value.trim();
        const params = new URLSearchParams();
        if (s) params.set('startDate', s);
        if (e) params.set('endDate', e);
        const query = params.toString();
        exportExcelBtn.href = '/admin/statistics/export' + (query ? '?' + query : '');
    }

    // Nếu người dùng tự chỉnh ô ngày, chuyển nút sang Tùy chọn & cập nhật link tải Excel
    if (startDateInput && endDateInput) {
        const handleManualDateChange = function () {
            if (rangeGroup) {
                rangeGroup.querySelectorAll('button').forEach(function (btn) {
                    btn.classList.toggle('active', btn.getAttribute('data-preset') === 'custom');
                });
            }
            updateExportExcelLink();
        };
        startDateInput.addEventListener('change', handleManualDateChange);
        endDateInput.addEventListener('change', handleManualDateChange);
    }

    // Chức năng tìm kiếm thông minh & phím tắt Ctrl+K
    const searchInput = document.getElementById('statsSearchInput');
    const searchClear = document.getElementById('statsSearchClear');
    const searchResults = document.getElementById('statsSearchResults');
    const chartContainer = document.getElementById('weeklyStatsChart');
    const floatingTooltip = document.getElementById('statsChartFloatingTooltip');

    function escapeHtml(str) {
        return (str || '').replace(/[&<>"']/g, function (m) {
            return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#039;' }[m];
        });
    }

    function removeVietnameseTones(str) {
        if (!str) return '';
        return str
            .normalize('NFD')
            .replace(/[\u0300-\u036f]/g, '')
            .replace(/đ/g, 'd')
            .replace(/Đ/g, 'd')
            .toLowerCase();
    }

    function textMatches(target, needle) {
        if (!target || !needle) return false;
        const t = target.toLowerCase();
        const n = needle.toLowerCase();
        if (t.includes(n)) return true;
        return removeVietnameseTones(target).includes(removeVietnameseTones(needle));
    }

    let activeCol = null;

    function closeTooltip() {
        if (!floatingTooltip) return;
        activeCol = null;
        floatingTooltip.classList.remove('visible');
        if (chartContainer) {
            chartContainer.querySelectorAll('.stats-bar-col.has-orders').forEach(function (c) {
                c.classList.remove('is-active');
            });
        }
        setTimeout(function () {
            if (!activeCol && floatingTooltip && !floatingTooltip.classList.contains('visible')) {
                floatingTooltip.style.display = 'none';
            }
        }, 180);
    }

    function openTooltip(col) {
        if (!chartContainer || !floatingTooltip || !col) return;
        const template = col.querySelector('.stats-bar-tooltip-template');
        if (!template) return;

        const isNewCol = (activeCol !== col);
        activeCol = col;

        // Đánh dấu cột đang được mở
        chartContainer.querySelectorAll('.stats-bar-col.has-orders').forEach(function (c) {
            c.classList.toggle('is-active', c === col);
        });

        if (isNewCol) {
            if (template.content && template.content.firstElementChild) {
                floatingTooltip.innerHTML = '';
                floatingTooltip.appendChild(template.content.cloneNode(true));
            } else {
                floatingTooltip.innerHTML = template.innerHTML;
            }

            // Lắng nghe nút ấn 'x' đóng cửa sổ bên trong
            const closeBtn = floatingTooltip.querySelector('.stats-tooltip-close-btn');
            if (closeBtn) {
                closeBtn.addEventListener('click', function (e) {
                    e.stopPropagation();
                    closeTooltip();
                });
            }
        }

        floatingTooltip.style.display = 'block';

        const chartRect = chartContainer.getBoundingClientRect();
        const colRect = col.getBoundingClientRect();
        const bar = col.querySelector('.stats-bar');
        const barRect = bar ? bar.getBoundingClientRect() : colRect;

        const tooltipWidth = floatingTooltip.offsetWidth || 340;
        const tooltipHeight = floatingTooltip.offsetHeight || 220;

        let targetLeft;
        let targetTop;

        const barTopInChart = barRect.top - chartRect.top;
        const spaceAbove = barTopInChart;

        if (spaceAbove >= tooltipHeight + 15) {
            // Đủ khoảng trống phía trên cột
            targetTop = barTopInChart - tooltipHeight - 10;
            targetLeft = (colRect.left - chartRect.left) + (colRect.width / 2) - (tooltipWidth / 2);
        } else {
            // Cột cao hoặc không đủ chỗ trên, chuyển sang bên cạnh (phải hoặc trái)
            const spaceRight = chartRect.right - colRect.right;
            if (spaceRight >= tooltipWidth + 15) {
                targetLeft = (colRect.right - chartRect.left) + 12;
                targetTop = Math.max(0, Math.min(barTopInChart, chartRect.height - tooltipHeight - 10));
            } else {
                targetLeft = (colRect.left - chartRect.left) - tooltipWidth - 12;
                targetTop = Math.max(0, Math.min(barTopInChart, chartRect.height - tooltipHeight - 10));
            }
        }

        // Giới hạn biên an toàn trong container biểu đồ
        const minLeft = 6;
        const maxLeft = Math.max(minLeft, chartRect.width - tooltipWidth - 6);
        if (targetLeft < minLeft) targetLeft = minLeft;
        if (targetLeft > maxLeft) targetLeft = maxLeft;

        floatingTooltip.style.left = `${Math.round(targetLeft)}px`;
        floatingTooltip.style.top = `${Math.round(targetTop)}px`;

        requestAnimationFrame(function () {
            floatingTooltip.classList.add('visible');
        });
    }

    if (searchInput) {
        // Phím tắt Ctrl+K hoặc Cmd+K để focus nhanh vào ô tìm kiếm
        document.addEventListener('keydown', function (e) {
            if ((e.ctrlKey || e.metaKey) && e.key === 'k') {
                e.preventDefault();
                searchInput.focus();
                searchInput.select();
            }
        });

        // Hàm trích xuất các sản phẩm / đơn hàng có trên biểu đồ tuần
        function extractChartItems() {
            const list = [];
            if (!chartContainer) return list;
            const barCols = chartContainer.querySelectorAll('.stats-bar-col.has-orders');
            barCols.forEach(function (col) {
                const tpl = col.querySelector('.stats-bar-tooltip-template');
                if (!tpl) return;

                let root;
                if (tpl.content && tpl.content.firstElementChild) {
                    root = tpl.content.cloneNode(true);
                } else {
                    root = document.createElement('div');
                    root.innerHTML = tpl.innerHTML;
                }

                const period = (root.querySelector('.stats-tooltip-period strong')?.textContent || '').trim();
                const itemEls = root.querySelectorAll('.stats-tooltip-item');
                itemEls.forEach(function (itemEl) {
                    const name = (itemEl.querySelector('.stats-tooltip-item-name')?.textContent || '').trim();
                    const orderCode = (itemEl.querySelector('.stats-cell-order .stats-cell-value')?.textContent || '').replace('#', '').trim();
                    const price = (itemEl.querySelector('.stats-tooltip-cell .text-primary')?.textContent || '').trim();
                    const quantity = (itemEl.querySelector('.stats-tooltip-cell .fw-semibold')?.textContent || '').trim();
                    const date = (itemEl.querySelector('.stats-tooltip-cell .text-secondary span')?.textContent || '').trim();
                    if (name || orderCode) {
                        list.push({
                            type: 'chart_item',
                            name: name,
                            orderCode: orderCode,
                            price: price,
                            quantity: quantity,
                            date: date,
                            period: period,
                            col: col
                        });
                    }
                });
            });
            return list;
        }

        // Hàm trích xuất dữ liệu từ bảng Top 5 sản phẩm
        function extractTopProducts() {
            const list = [];
            const rows = document.querySelectorAll('#topProductsTable tbody tr');
            rows.forEach(function (row) {
                if (row.cells.length < 5) return;
                const rank = (row.querySelector('.stats-rank')?.textContent || '').trim();
                const name = (row.querySelector('.stats-product strong')?.textContent || '').trim();
                const category = (row.querySelector('.stats-product small')?.textContent || '').trim();
                const sold = (row.cells[2]?.textContent || '').trim();
                const revenue = (row.cells[3]?.textContent || '').trim();
                list.push({
                    type: 'top_product',
                    rank: rank,
                    name: name,
                    category: category,
                    sold: sold,
                    revenue: revenue,
                    row: row
                });
            });
            return list;
        }

        // Thực hiện tìm kiếm và hiển thị gợi ý
        function handleSearch() {
            const query = searchInput.value.trim();
            const cleanQuery = query.replace(/^#/, '').trim();

            if (searchClear) {
                searchClear.style.display = query ? 'block' : 'none';
            }

            // Lọc bảng Top sản phẩm
            const rows = document.querySelectorAll('#topProductsTable tbody tr');
            rows.forEach(function (row) {
                if (row.cells.length < 5) return;
                const text = row.textContent || '';
                const isMatch = !query || textMatches(text, query);
                row.style.display = isMatch ? '' : 'none';
            });

            if (!searchResults) return;

            if (!query) {
                searchResults.style.display = 'none';
                searchResults.innerHTML = '';
                return;
            }

            const chartItems = extractChartItems();
            const topProducts = extractTopProducts();

            const matchedChartItems = chartItems.filter(function (item) {
                return textMatches(item.name, query) ||
                    textMatches(item.orderCode, cleanQuery) ||
                    textMatches(item.period, query);
            }).slice(0, 5);

            const matchedTopProducts = topProducts.filter(function (p) {
                return textMatches(p.name, query) ||
                    textMatches(p.category, query);
            }).slice(0, 4);

            let html = '';

            if (matchedChartItems.length > 0) {
                html += '<div class="stats-search-section-title">Đơn hàng trong kỳ báo cáo</div>';
                matchedChartItems.forEach(function (item, idx) {
                    html += `
                        <div class="stats-search-item" data-action="chart" data-index="${idx}">
                            <div class="stats-search-item-left">
                                <span class="stats-search-item-icon icon-order"><i class="bi bi-receipt"></i></span>
                                <div class="stats-search-item-info">
                                    <div class="stats-search-item-title">#${escapeHtml(item.orderCode)} • ${escapeHtml(item.name)}</div>
                                    <div class="stats-search-item-sub">${escapeHtml(item.period)} • ${escapeHtml(item.date)} • SL: ${escapeHtml(item.quantity)}</div>
                                </div>
                            </div>
                            <div class="stats-search-item-right">
                                <div class="stats-search-item-price">${escapeHtml(item.price)}</div>
                            </div>
                        </div>
                    `;
                });
            }

            if (matchedTopProducts.length > 0) {
                html += '<div class="stats-search-section-title">Top sản phẩm bán chạy</div>';
                matchedTopProducts.forEach(function (p, idx) {
                    html += `
                        <div class="stats-search-item" data-action="top" data-index="${idx}">
                            <div class="stats-search-item-left">
                                <span class="stats-search-item-icon"><i class="bi bi-bag-check"></i></span>
                                <div class="stats-search-item-info">
                                    <div class="stats-search-item-title">Top ${escapeHtml(p.rank)}: ${escapeHtml(p.name)}</div>
                                    <div class="stats-search-item-sub">${escapeHtml(p.category)} • Đã bán ${escapeHtml(p.sold)}</div>
                                </div>
                            </div>
                            <div class="stats-search-item-right">
                                <div class="stats-search-item-price">${escapeHtml(p.revenue)}</div>
                            </div>
                        </div>
                    `;
                });
            }

            if (matchedChartItems.length === 0 && matchedTopProducts.length === 0) {
                html += `<div class="stats-search-empty"><i class="bi bi-search me-1"></i> Không có dữ liệu trang thống kê trùng khớp với "<strong>${escapeHtml(query)}</strong>"</div>`;
            }

            // Lối tắt chuyển trang nhanh
            html += `
                <a href="/admin/orders?keyword=${encodeURIComponent(cleanQuery)}" class="stats-search-item-action">
                    <i class="bi bi-receipt-cutoff me-1"></i> Tìm đơn hàng <strong>"${escapeHtml(query)}"</strong> trong Quản lý đơn hàng ➔
                </a>
                <a href="/admin/products?keyword=${encodeURIComponent(cleanQuery)}" class="stats-search-item-action">
                    <i class="bi bi-box-seam me-1"></i> Tìm sản phẩm <strong>"${escapeHtml(query)}"</strong> trong Quản lý sản phẩm ➔
                </a>
            `;

            searchResults.innerHTML = html;
            searchResults.style.display = 'block';

            // Gán sự kiện click cho các item gợi ý
            searchResults.querySelectorAll('.stats-search-item').forEach(function (el) {
                el.addEventListener('click', function () {
                    const action = el.getAttribute('data-action');
                    const idx = parseInt(el.getAttribute('data-index'), 10);

                    if (action === 'chart') {
                        const target = matchedChartItems[idx];
                        if (target && target.col) {
                            searchResults.style.display = 'none';
                            target.col.scrollIntoView({ behavior: 'smooth', block: 'center' });
                            setTimeout(function () {
                                openTooltip(target.col);
                            }, 120);
                        }
                    } else if (action === 'top') {
                        const target = matchedTopProducts[idx];
                        if (target && target.row) {
                            searchResults.style.display = 'none';
                            target.row.scrollIntoView({ behavior: 'smooth', block: 'center' });
                            target.row.classList.remove('table-row-highlight');
                            void target.row.offsetWidth;
                            target.row.classList.add('table-row-highlight');
                        }
                    }
                });
            });
        }

        searchInput.addEventListener('input', handleSearch);
        searchInput.addEventListener('focus', function () {
            if (searchInput.value.trim()) {
                handleSearch();
            }
        });

        // Bấm phím Enter
        searchInput.addEventListener('keydown', function (e) {
            if (e.key === 'Enter') {
                e.preventDefault();
                const query = searchInput.value.trim();
                if (!query) return;

                const firstItem = searchResults ? searchResults.querySelector('.stats-search-item') : null;
                const isOrderQuery = /^#?FS/i.test(query) || /^\d+$/.test(query);

                if (isOrderQuery) {
                    window.location.href = '/admin/orders?keyword=' + encodeURIComponent(query.replace(/^#/, ''));
                } else if (firstItem) {
                    firstItem.click();
                } else {
                    window.location.href = '/admin/orders?keyword=' + encodeURIComponent(query);
                }
            } else if (e.key === 'Escape') {
                if (searchResults) searchResults.style.display = 'none';
            }
        });

        // Nút xóa tìm kiếm
        if (searchClear) {
            searchClear.addEventListener('click', function () {
                searchInput.value = '';
                searchInput.focus();
                handleSearch();
            });
        }

        // Đóng dropdown khi click ra ngoài
        document.addEventListener('click', function (e) {
            if (searchResults && !searchInput.contains(e.target) && !searchResults.contains(e.target) && (!searchClear || !searchClear.contains(e.target))) {
                searchResults.style.display = 'none';
            }
        });
    }

    // Xử lý hiển thị cửa sổ thông tin sản phẩm và đơn hàng khi click chuột vào cột biểu đồ
    if (chartContainer && floatingTooltip) {
        const barColsWithOrders = chartContainer.querySelectorAll('.stats-bar-col.has-orders');

        // Sự kiện click vào cột biểu đồ có đơn hàng để mở/đóng cửa sổ thông tin
        barColsWithOrders.forEach(function (col) {
            col.addEventListener('click', function (e) {
                e.stopPropagation();
                if (activeCol === col && floatingTooltip.classList.contains('visible')) {
                    // Click lại vào chính cột đang mở -> đóng lại
                    closeTooltip();
                } else {
                    // Click để hiển thị cửa sổ thông tin
                    openTooltip(col);
                }
            });
        });

        // Click ra ngoài cửa sổ thông tin và ngoài các cột để đóng
        document.addEventListener('click', function (e) {
            if (floatingTooltip.classList.contains('visible')) {
                const clickedCol = e.target.closest('.stats-bar-col.has-orders');
                if (!floatingTooltip.contains(e.target) && !clickedCol) {
                    closeTooltip();
                }
            }
        });

        // Phím Escape để đóng nhanh cửa sổ thông tin
        document.addEventListener('keydown', function (e) {
            if (e.key === 'Escape' && floatingTooltip.classList.contains('visible')) {
                closeTooltip();
            }
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
