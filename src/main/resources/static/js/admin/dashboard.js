/**
 * FASHION SHOP - ATELIER ADMIN DASHBOARD JAVASCRIPT
 * Tích hợp ApexCharts biểu đồ đơn hàng trong ngày (24 giờ) & điều phối xử lý nhanh đơn mới.
 */

let dashboardChartInstance = null;
let currentGrain = 'today'; // 'today', 'week', 'month'
let currentStatusFilter = 'ALL'; // 'ALL', 'PENDING', 'CONFIRMED'
let currentHourFilter = null; // null hoặc 0..23

// Bộ nhớ đệm dữ liệu biểu đồ
let chartDataStore = {
    today: { labels: [], orders: [], pending: [], confirmed: [], revenues: [] },
    week: { labels: [], revenues: [], orders: [] },
    month: { labels: [], revenues: [], orders: [], peakNote: '' }
};

document.addEventListener('DOMContentLoaded', function () {
    parseChartData();
    initChart();
    initGrainButtons();
    initStatusFilterButtons();
    initPipelineFilter();
    initQuickActions();
});

/**
 * Trích xuất dữ liệu từ các thuộc tính data-* trên thẻ #dashboardAreaChart
 */
function parseChartData() {
    const el = document.getElementById('dashboardAreaChart');
    if (!el) return;

    // 1. Dữ liệu Hôm nay (24 giờ)
    const rawTodayLabels = el.getAttribute('data-today-labels') || '';
    const rawTodayOrders = el.getAttribute('data-today-orders') || '';
    const rawTodayPending = el.getAttribute('data-today-pending') || '';
    const rawTodayConfirmed = el.getAttribute('data-today-confirmed') || '';
    const rawTodayRevenues = el.getAttribute('data-today-revenues') || '';

    chartDataStore.today.labels = rawTodayLabels
        ? rawTodayLabels.split(',')
        : Array.from({ length: 24 }, (_, i) => String(i).padStart(2, '0') + ':00');
    chartDataStore.today.orders = rawTodayOrders
        ? rawTodayOrders.split(',').map(v => parseInt(v, 10) || 0)
        : Array(24).fill(0);
    chartDataStore.today.pending = rawTodayPending
        ? rawTodayPending.split(',').map(v => parseInt(v, 10) || 0)
        : Array(24).fill(0);
    chartDataStore.today.confirmed = rawTodayConfirmed
        ? rawTodayConfirmed.split(',').map(v => parseInt(v, 10) || 0)
        : Array(24).fill(0);
    chartDataStore.today.revenues = rawTodayRevenues
        ? rawTodayRevenues.split(',').map(v => parseFloat(v) || 0)
        : Array(24).fill(0);

    // 2. Dữ liệu 7 ngày qua
    const rawWeekLabels = el.getAttribute('data-week-labels') || '';
    const rawWeekRevenues = el.getAttribute('data-week-revenues') || '';
    const rawWeekOrders = el.getAttribute('data-week-orders') || '';

    chartDataStore.week.labels = rawWeekLabels
        ? rawWeekLabels.split(',')
        : ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    chartDataStore.week.revenues = rawWeekRevenues
        ? rawWeekRevenues.split(',').map(v => parseFloat(v) || 0)
        : Array(7).fill(0);
    chartDataStore.week.orders = rawWeekOrders
        ? rawWeekOrders.split(',').map(v => parseInt(v, 10) || 0)
        : Array(7).fill(0);

    // 3. Dữ liệu 12 tháng
    const rawMonthLabels = el.getAttribute('data-month-labels') || '';
    const rawMonthRevenues = el.getAttribute('data-month-revenues') || '';
    const rawMonthOrders = el.getAttribute('data-month-orders') || '';
    chartDataStore.month.peakNote = el.getAttribute('data-peak-note') || '';

    chartDataStore.month.labels = rawMonthLabels
        ? rawMonthLabels.split(',')
        : ['T1', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'T8', 'T9', 'T10', 'T11', 'T12'];
    chartDataStore.month.revenues = rawMonthRevenues
        ? rawMonthRevenues.split(',').map(v => parseFloat(v) || 0)
        : Array(12).fill(0);
    chartDataStore.month.orders = rawMonthOrders
        ? rawMonthOrders.split(',').map(v => parseInt(v, 10) || 0)
        : Array(12).fill(0);
}

/**
 * Khởi tạo ApexCharts với chế độ Hôm nay (24 khung giờ) làm mặc định
 */
function initChart() {
    const chartEl = document.getElementById('dashboardAreaChart');
    if (!chartEl) return;

    const options = {
        series: [
            {
                name: 'Đơn mới phát sinh',
                type: 'column',
                data: chartDataStore.today.orders
            },
            {
                name: 'Đã xử lý / Xác nhận',
                type: 'column',
                data: chartDataStore.today.confirmed
            },
            {
                name: 'Chờ duyệt',
                type: 'line',
                data: chartDataStore.today.pending
            }
        ],
        chart: {
            height: 255,
            type: 'line',
            toolbar: { show: false },
            zoom: { enabled: false },
            fontFamily: 'Plus Jakarta Sans, sans-serif',
            events: {
                dataPointSelection: function (event, chartContext, config) {
                    if (currentGrain === 'today') {
                        const idx = config.dataPointIndex;
                        if (idx >= 0 && idx < chartDataStore.today.labels.length) {
                            filterTodayOrdersByHour(idx, chartDataStore.today.labels[idx]);
                        }
                    }
                }
            }
        },
        plotOptions: {
            bar: {
                columnWidth: '55%',
                borderRadius: 4
            }
        },
        stroke: {
            curve: 'smooth',
            width: [0, 0, 3],
            dashArray: [0, 0, 0]
        },
        colors: ['#4f46e5', '#10b981', '#f59e0b'],
        fill: {
            opacity: [0.9, 0.9, 1]
        },
        markers: {
            size: [0, 0, 4],
            colors: ['#f59e0b'],
            strokeColors: '#ffffff',
            strokeWidth: 2,
            hover: { size: 6 }
        },
        xaxis: {
            categories: chartDataStore.today.labels,
            axisBorder: { show: false },
            axisTicks: { show: false },
            labels: {
                style: { colors: '#94a3b8', fontSize: '11px', fontWeight: 600 },
                rotate: 0,
                hideOverlappingLabels: true
            }
        },
        yaxis: [
            {
                title: { text: undefined },
                labels: {
                    formatter: function (val) {
                        return Math.round(val);
                    },
                    style: { colors: '#94a3b8', fontSize: '11px' }
                },
                min: 0,
                forceNiceScale: true
            }
        ],
        grid: {
            borderColor: '#f1f5f9',
            strokeDashArray: 4,
            padding: { left: 10, right: 10, top: 0, bottom: 0 }
        },
        tooltip: {
            theme: 'dark',
            shared: true,
            intersect: false,
            custom: function ({ series, seriesIndex, dataPointIndex, w }) {
                if (currentGrain === 'today') {
                    const hour = chartDataStore.today.labels[dataPointIndex] || '';
                    const ordersCount = series[0][dataPointIndex] || 0;
                    const confirmedCount = series[1][dataPointIndex] || 0;
                    const pendingCount = series[2][dataPointIndex] || 0;
                    const rev = chartDataStore.today.revenues[dataPointIndex] || 0;

                    return `
                        <div class="px-3 py-2" style="font-size: 12px; line-height: 1.5;">
                            <div class="fw-bold border-bottom pb-1 mb-1 text-light">
                                <i class="bi bi-clock me-1 text-warning"></i>Khung giờ: ${hour}
                            </div>
                            <div style="color: #c7d2fe;">• Đơn mới: <strong class="text-white">${ordersCount}</strong></div>
                            <div style="color: #a7f3d0;">• Đã xử lý: <strong class="text-white">${confirmedCount}</strong></div>
                            <div style="color: #fde68a;">• Chờ duyệt: <strong class="text-white">${pendingCount}</strong></div>
                            <div style="color: #a5f3fc;" class="pt-1 border-top mt-1">
                                • Doanh thu: <strong class="text-white">${rev.toLocaleString('vi-VN')} đ</strong>
                            </div>
                            <div class="text-secondary small fst-italic mt-1" style="font-size: 10px;">
                                💡 Nhấp chuột để lọc danh sách bên dưới
                            </div>
                        </div>
                    `;
                } else {
                    const cat = w.globals.categoryLabels[dataPointIndex] || '';
                    const rev = series[0] ? series[0][dataPointIndex] : 0;
                    const ord = series[1] ? series[1][dataPointIndex] : 0;
                    return `
                        <div class="px-3 py-2" style="font-size: 12px;">
                            <div class="fw-bold border-bottom pb-1 mb-1 text-light">${cat}</div>
                            <div style="color: #c7d2fe;">• Doanh thu: <strong class="text-white">${(rev || 0).toLocaleString('vi-VN')} đ</strong></div>
                            <div style="color: #a7f3d0;">• Đơn hàng: <strong class="text-white">${ord || 0} đơn</strong></div>
                        </div>
                    `;
                }
            }
        },
        legend: { show: false }
    };

    dashboardChartInstance = new ApexCharts(chartEl, options);
    dashboardChartInstance.render();
}

/**
 * Xử lý chuyển đổi giữa Hôm nay (24h) / 7 ngày qua / 12 tháng
 */
function initGrainButtons() {
    document.querySelectorAll('.grain-btn').forEach(btn => {
        btn.addEventListener('click', function () {
            document.querySelectorAll('.grain-btn').forEach(b => b.classList.remove('active'));
            this.classList.add('active');

            const grain = this.getAttribute('data-grain');
            currentGrain = grain;

            const titleEl = document.getElementById('chartHeaderTitle');
            const subTitleEl = document.getElementById('chartHeaderSubtitle');
            const legendOrders = document.getElementById('legend-text-orders');
            const legendConfirmed = document.getElementById('legend-item-confirmed');
            const legendPending = document.getElementById('legend-item-pending');
            const legendRev = document.getElementById('legend-item-revenue');

            if (grain === 'today') {
                if (titleEl) titleEl.innerText = 'Biểu đồ Đơn hàng phát sinh trong ngày';
                if (subTitleEl) subTitleEl.innerText = 'Theo dõi đơn đặt theo 24 khung giờ • Nhấp mốc giờ để lọc nhanh danh sách bên dưới';
                if (legendOrders) legendOrders.innerText = 'Đơn phát sinh';
                if (legendConfirmed) legendConfirmed.style.display = '';
                if (legendPending) legendPending.style.display = '';
                if (legendRev) legendRev.style.display = '';

                dashboardChartInstance.updateOptions({
                    chart: { type: 'line' },
                    stroke: { width: [0, 0, 3], curve: 'smooth' },
                    colors: ['#4f46e5', '#10b981', '#f59e0b'],
                    plotOptions: { bar: { columnWidth: '55%', borderRadius: 4 } },
                    xaxis: { categories: chartDataStore.today.labels }
                });
                dashboardChartInstance.updateSeries([
                    { name: 'Đơn mới phát sinh', type: 'column', data: chartDataStore.today.orders },
                    { name: 'Đã xử lý / Xác nhận', type: 'column', data: chartDataStore.today.confirmed },
                    { name: 'Chờ duyệt', type: 'line', data: chartDataStore.today.pending }
                ]);
            } else if (grain === 'week') {
                if (titleEl) titleEl.innerText = 'Biểu đồ Doanh thu & Đơn hàng 7 ngày qua';
                if (subTitleEl) subTitleEl.innerText = 'Thống kê thực tế 7 ngày gần nhất từ dữ liệu đơn hàng trong hệ thống';
                if (legendOrders) legendOrders.innerText = 'Doanh thu (VNĐ)';
                if (legendConfirmed) legendConfirmed.style.display = 'none';
                if (legendPending) legendPending.style.display = 'none';
                if (legendRev) legendRev.style.display = 'none';

                dashboardChartInstance.updateOptions({
                    chart: { type: 'line' },
                    stroke: { width: [3, 2], curve: 'smooth', dashArray: [0, 4] },
                    colors: ['#4f46e5', '#10b981'],
                    plotOptions: { bar: { columnWidth: '0%' } },
                    xaxis: { categories: chartDataStore.week.labels }
                });
                dashboardChartInstance.updateSeries([
                    { name: 'Doanh thu (VNĐ)', type: 'area', data: chartDataStore.week.revenues },
                    { name: 'Số lượng đơn hàng', type: 'line', data: chartDataStore.week.orders }
                ]);
            } else {
                // 'month' (12 tháng)
                if (titleEl) titleEl.innerText = 'Biểu đồ Doanh thu & Đơn hàng theo tháng';
                if (subTitleEl) subTitleEl.innerText = 'Thống kê doanh thu thời gian thực theo chu kỳ tài chính Atelier';
                if (legendOrders) legendOrders.innerText = 'Doanh thu (VNĐ)';
                if (legendConfirmed) legendConfirmed.style.display = 'none';
                if (legendPending) legendPending.style.display = 'none';
                if (legendRev) legendRev.style.display = 'none';

                dashboardChartInstance.updateOptions({
                    chart: { type: 'line' },
                    stroke: { width: [3, 2], curve: 'smooth', dashArray: [0, 4] },
                    colors: ['#4f46e5', '#10b981'],
                    plotOptions: { bar: { columnWidth: '0%' } },
                    xaxis: { categories: chartDataStore.month.labels }
                });
                dashboardChartInstance.updateSeries([
                    { name: 'Doanh thu (VNĐ)', type: 'area', data: chartDataStore.month.revenues },
                    { name: 'Số lượng đơn hàng', type: 'line', data: chartDataStore.month.orders }
                ]);
            }
        });
    });
}

/**
 * Xử lý các nút lọc trạng thái trong bảng điều phối đơn hàng
 */
function initStatusFilterButtons() {
    document.querySelectorAll('.order-filter-btn').forEach(btn => {
        btn.addEventListener('click', function () {
            document.querySelectorAll('.order-filter-btn').forEach(b => b.classList.remove('active'));
            this.classList.add('active');

            currentStatusFilter = this.getAttribute('data-status-filter') || 'ALL';
            applyTodayTableFilters();
        });
    });
}

/**
 * Lọc bảng đơn hàng theo Giờ và Trạng thái
 */
function applyTodayTableFilters() {
    const rows = document.querySelectorAll('.today-order-row');
    let visibleCount = 0;

    rows.forEach(row => {
        const rowHour = parseInt(row.getAttribute('data-hour'), 10);
        const rowStatus = (row.getAttribute('data-status') || '').toUpperCase();

        const matchHour = (currentHourFilter === null || rowHour === currentHourFilter);
        let matchStatus = true;

        if (currentStatusFilter === 'PENDING') {
            matchStatus = (rowStatus === 'PENDING');
        } else if (currentStatusFilter === 'CONFIRMED') {
            matchStatus = (rowStatus !== 'PENDING' && rowStatus !== 'CANCELLED');
        }

        if (matchHour && matchStatus) {
            row.style.display = '';
            visibleCount++;
        } else {
            row.style.display = 'none';
        }
    });

    const emptyRow = document.getElementById('emptyTodayRow');
    if (emptyRow) {
        if (visibleCount === 0) {
            emptyRow.classList.remove('d-none');
            const msgSpan = emptyRow.querySelector('span');
            if (msgSpan) {
                if (currentHourFilter !== null) {
                    msgSpan.innerText = `Không có đơn hàng nào phù hợp với bộ lọc trong khung giờ ${String(currentHourFilter).padStart(2, '0')}:00.`;
                } else if (currentStatusFilter === 'PENDING') {
                    msgSpan.innerText = 'Tuyệt vời! Hiện không còn đơn hàng nào cần chờ duyệt hôm nay.';
                } else {
                    msgSpan.innerText = 'Không có đơn hàng nào phù hợp với tiêu chí lọc.';
                }
            }
        } else {
            emptyRow.classList.add('d-none');
        }
    }
}

/**
 * Kích hoạt khi người dùng nhấp vào một mốc giờ trên biểu đồ
 */
window.filterTodayOrdersByHour = function (hourIndex, hourLabel) {
    currentHourFilter = hourIndex;

    const badge = document.getElementById('hourFilterBadge');
    const textEl = document.getElementById('selectedHourText');
    if (badge && textEl) {
        textEl.innerText = hourLabel || (String(hourIndex).padStart(2, '0') + ':00');
        badge.classList.remove('d-none');
        badge.classList.add('d-inline-flex');
    }

    applyTodayTableFilters();

    // Tự động cuộn nhẹ xuống khu vực điều phối nếu cần
    const box = document.querySelector('.today-dispatcher-box');
    if (box) {
        box.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
    }
};

/**
 * Xóa bỏ bộ lọc khung giờ
 */
window.clearHourFilter = function () {
    currentHourFilter = null;
    const badge = document.getElementById('hourFilterBadge');
    if (badge) {
        badge.classList.remove('d-inline-flex');
        badge.classList.add('d-none');
    }
    applyTodayTableFilters();
};

/**
 * Duyệt nhanh 1 đơn hàng trực tiếp trong bảng hôm nay
 */
window.quickConfirmRow = function (btn) {
    const orderId = btn.getAttribute('data-order-id');
    if (!orderId) return;

    btn.disabled = true;
    const originalHtml = btn.innerHTML;
    btn.innerHTML = '<span class="spinner-border spinner-border-sm"></span>';

    fetch('/admin/dashboard/quick-confirm/' + orderId, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' }
    })
    .then(res => res.json())
    .then(data => {
        if (data.success) {
            const row = document.getElementById('today-order-row-' + orderId);
            if (row) {
                row.setAttribute('data-status', 'CONFIRMED');
                row.classList.add('table-success');
                setTimeout(() => row.classList.remove('table-success'), 1500);

                // Cập nhật badge trạng thái
                const badge = document.getElementById('order-status-badge-' + orderId);
                if (badge) {
                    badge.className = 'badge rounded-pill bg-primary-subtle text-primary border border-primary-subtle';
                    badge.innerText = 'Đã xác nhận';
                }

                // Ẩn nút duyệt
                btn.remove();

                // Cập nhật biểu đồ hôm nay (giảm pending, tăng confirmed tại giờ của đơn)
                const hour = parseInt(row.getAttribute('data-hour'), 10);
                if (!isNaN(hour) && hour >= 0 && hour < 24) {
                    chartDataStore.today.pending[hour] = Math.max(0, chartDataStore.today.pending[hour] - 1);
                    chartDataStore.today.confirmed[hour] = chartDataStore.today.confirmed[hour] + 1;
                    if (currentGrain === 'today' && dashboardChartInstance) {
                        dashboardChartInstance.updateSeries([
                            { name: 'Đơn mới phát sinh', type: 'column', data: chartDataStore.today.orders },
                            { name: 'Đã xử lý / Xác nhận', type: 'column', data: chartDataStore.today.confirmed },
                            { name: 'Chờ duyệt', type: 'line', data: chartDataStore.today.pending }
                        ]);
                    }
                }
            }

            // Cập nhật các bộ đếm trên UI
            decrementPendingCounters();

            // Cập nhật dữ liệu pipeline hôm nay nếu có
            if (pipelineDataStore.today && pipelineDataStore.today.total > 0) {
                pipelineDataStore.today.processing = Math.max(0, pipelineDataStore.today.processing - 1);
                pipelineDataStore.today.completed += 1;
                pipelineDataStore.today.completedPct = Math.round((pipelineDataStore.today.completed * 100 / pipelineDataStore.today.total) * 10) / 10;
                pipelineDataStore.today.processingPct = Math.round((pipelineDataStore.today.processing * 100 / pipelineDataStore.today.total) * 10) / 10;
                if (currentPipelineGrain === 'today') {
                    renderPipelineStats('today');
                }
            }

            // Nếu đang ở filter PENDING thì ẩn hàng này
            if (currentStatusFilter === 'PENDING') {
                applyTodayTableFilters();
            }
        } else {
            alert(data.message || 'Không thể xác nhận đơn hàng.');
            btn.disabled = false;
            btn.innerHTML = originalHtml;
        }
    })
    .catch(err => {
        alert('Lỗi kết nối máy chủ: ' + err);
        btn.disabled = false;
        btn.innerHTML = originalHtml;
    });
};

/**
 * Duyệt nhanh toàn bộ các đơn hàng PENDING trong ngày
 */
window.batchConfirmTodayOrders = function () {
    const btn = document.getElementById('btnBatchConfirmToday');
    if (!confirm('Bạn có chắc chắn muốn duyệt nhanh TẤT CẢ các đơn hàng đang chờ duyệt không?')) {
        return;
    }

    if (btn) {
        btn.disabled = true;
        btn.innerHTML = '<span class="spinner-border spinner-border-sm me-1"></span> Đang xử lý...';
    }

    fetch('/admin/dashboard/quick-confirm-all', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' }
    })
    .then(res => res.json())
    .then(data => {
        if (data.success) {
            alert(data.message || 'Đã duyệt tất cả đơn hàng thành công!');

            // Cập nhật toàn bộ các hàng PENDING trên bảng
            document.querySelectorAll('.today-order-row[data-status="PENDING"]').forEach(row => {
                row.setAttribute('data-status', 'CONFIRMED');
                const ordId = row.id.replace('today-order-row-', '');
                const badge = document.getElementById('order-status-badge-' + ordId);
                if (badge) {
                    badge.className = 'badge rounded-pill bg-primary-subtle text-primary border border-primary-subtle';
                    badge.innerText = 'Đã xác nhận';
                }
                const actBtn = row.querySelector('.btn-quick-confirm-action');
                if (actBtn) actBtn.remove();
            });

            // Cập nhật số liệu biểu đồ
            for (let h = 0; h < 24; h++) {
                chartDataStore.today.confirmed[h] += chartDataStore.today.pending[h];
                chartDataStore.today.pending[h] = 0;
            }
            if (currentGrain === 'today' && dashboardChartInstance) {
                dashboardChartInstance.updateSeries([
                    { name: 'Đơn mới phát sinh', type: 'column', data: chartDataStore.today.orders },
                    { name: 'Đã xử lý / Xác nhận', type: 'column', data: chartDataStore.today.confirmed },
                    { name: 'Chờ duyệt', type: 'line', data: chartDataStore.today.pending }
                ]);
            }

            // Đặt lại các bộ đếm chờ duyệt về 0
            resetPendingCounters();

            // Cập nhật pipeline hôm nay
            if (pipelineDataStore.today && pipelineDataStore.today.total > 0) {
                pipelineDataStore.today.completed += pipelineDataStore.today.processing;
                pipelineDataStore.today.processing = 0;
                pipelineDataStore.today.completedPct = Math.round((pipelineDataStore.today.completed * 100 / pipelineDataStore.today.total) * 10) / 10;
                pipelineDataStore.today.processingPct = 0;
                if (currentPipelineGrain === 'today') {
                    renderPipelineStats('today');
                }
            }

            applyTodayTableFilters();
        } else {
            alert(data.message || 'Có lỗi xảy ra khi duyệt đơn hàng.');
            if (btn) {
                btn.disabled = false;
                btn.innerHTML = '<i class="bi bi-check2-all me-1"></i> Duyệt nhanh tất cả';
            }
        }
    })
    .catch(err => {
        alert('Lỗi kết nối: ' + err);
        if (btn) {
            btn.disabled = false;
            btn.innerHTML = '<i class="bi bi-check2-all me-1"></i> Duyệt nhanh tất cả';
        }
    });
};

function decrementPendingCounters() {
    const chip = document.getElementById('chipTodayPending');
    const filterPending = document.getElementById('countFilterPending');
    const filterConfirmed = document.getElementById('countFilterConfirmed');
    const batchBtnCount = document.getElementById('btnBatchConfirmCount');
    const batchBtn = document.getElementById('btnBatchConfirmToday');

    let pVal = 0;
    if (chip) {
        pVal = Math.max(0, parseInt(chip.innerText, 10) - 1);
        chip.innerText = pVal;
    }
    if (filterPending) filterPending.innerText = pVal;
    if (batchBtnCount) batchBtnCount.innerText = pVal;

    if (filterConfirmed) {
        const cVal = parseInt(filterConfirmed.innerText, 10) + 1;
        filterConfirmed.innerText = cVal;
    }

    if (pVal === 0 && batchBtn) {
        batchBtn.disabled = true;
    }
}

function resetPendingCounters() {
    const chip = document.getElementById('chipTodayPending');
    const filterPending = document.getElementById('countFilterPending');
    const filterConfirmed = document.getElementById('countFilterConfirmed');
    const filterAll = document.getElementById('countFilterAll');
    const batchBtnCount = document.getElementById('btnBatchConfirmCount');
    const batchBtn = document.getElementById('btnBatchConfirmToday');

    if (chip) chip.innerText = '0';
    if (filterPending) filterPending.innerText = '0';
    if (batchBtnCount) batchBtnCount.innerText = '0';
    if (filterConfirmed && filterAll) {
        filterConfirmed.innerText = filterAll.innerText;
    }
    if (batchBtn) {
        btnBatchConfirmToday.disabled = true;
        btnBatchConfirmToday.innerHTML = '<i class="bi bi-check2-all me-1"></i> Đã duyệt hết';
    }
}

/**
 * =========================================================================
 * BỘ LỌC PHÂN BỔ TRẠNG THÁI ĐƠN HÀNG (PIPELINE): NGÀY, TUẦN, THÁNG, NĂM, TOÀN BỘ
 * =========================================================================
 */
let currentPipelineGrain = 'today';
let pipelineDataStore = {
    today: {},
    week: {},
    month: {},
    year: {},
    all: {}
};

function initPipelineFilter() {
    const el = document.getElementById('orderPipelineSection');
    if (!el) return;

    const targetMonth = el.getAttribute('data-target-month') || '';
    const selectedYear = el.getAttribute('data-selected-year') || '';

    const periods = [
        { key: 'today', label: 'Hôm nay' },
        { key: 'week', label: '7 ngày qua' },
        { key: 'month', label: 'Tháng ' + targetMonth },
        { key: 'year', label: 'Năm ' + selectedYear },
        { key: 'all', label: 'Toàn bộ' }
    ];

    periods.forEach(p => {
        pipelineDataStore[p.key] = {
            label: p.label,
            total: parseInt(el.getAttribute(`data-pipeline-${p.key}-total`), 10) || 0,
            completed: parseInt(el.getAttribute(`data-pipeline-${p.key}-completed`), 10) || 0,
            completedPct: parseFloat(el.getAttribute(`data-pipeline-${p.key}-completed-pct`)) || 0,
            processing: parseInt(el.getAttribute(`data-pipeline-${p.key}-processing`), 10) || 0,
            processingPct: parseFloat(el.getAttribute(`data-pipeline-${p.key}-processing-pct`)) || 0,
            shipping: parseInt(el.getAttribute(`data-pipeline-${p.key}-shipping`), 10) || 0,
            shippingPct: parseFloat(el.getAttribute(`data-pipeline-${p.key}-shipping-pct`)) || 0,
            cancelled: parseInt(el.getAttribute(`data-pipeline-${p.key}-cancelled`), 10) || 0,
            cancelledPct: parseFloat(el.getAttribute(`data-pipeline-${p.key}-cancelled-pct`)) || 0
        };
    });

    document.querySelectorAll('.pipeline-grain-btn').forEach(btn => {
        btn.addEventListener('click', function () {
            document.querySelectorAll('.pipeline-grain-btn').forEach(b => b.classList.remove('active'));
            this.classList.add('active');

            const grain = this.getAttribute('data-pipeline');
            currentPipelineGrain = grain;
            renderPipelineStats(grain);
        });
    });
}

function renderPipelineStats(grain) {
    const data = pipelineDataStore[grain];
    if (!data) return;

    const labelEl = document.getElementById('pipelinePeriodLabel');
    const totalEl = document.getElementById('pipelineTotalBadge');
    const segCompleted = document.getElementById('pipelineSegmentCompleted');
    const segProcessing = document.getElementById('pipelineSegmentProcessing');
    const segShipping = document.getElementById('pipelineSegmentShipping');
    const segCancelled = document.getElementById('pipelineSegmentCancelled');

    const legCompleted = document.getElementById('pipelineLegendCompleted');
    const legProcessing = document.getElementById('pipelineLegendProcessing');
    const legShipping = document.getElementById('pipelineLegendShipping');
    const legCancelled = document.getElementById('pipelineLegendCancelled');

    if (labelEl) labelEl.innerText = data.label;
    if (totalEl) totalEl.innerText = data.total.toLocaleString('vi-VN') + ' đơn tổng';

    if (segCompleted) {
        segCompleted.style.width = data.completedPct + '%';
        segCompleted.title = `Đã hoàn tất: ${data.completedPct}% (${data.completed})`;
    }
    if (segProcessing) {
        segProcessing.style.width = data.processingPct + '%';
        segProcessing.title = `Đang xử lý: ${data.processingPct}% (${data.processing})`;
    }
    if (segShipping) {
        segShipping.style.width = data.shippingPct + '%';
        segShipping.title = `Đang giao: ${data.shippingPct}% (${data.shipping})`;
    }
    if (segCancelled) {
        segCancelled.style.width = data.cancelledPct + '%';
        segCancelled.title = `Hoàn trả/Hủy: ${data.cancelledPct}% (${data.cancelled})`;
    }

    if (legCompleted) legCompleted.innerText = `${data.completedPct}% (${data.completed.toLocaleString('vi-VN')})`;
    if (legProcessing) legProcessing.innerText = `${data.processingPct}% (${data.processing.toLocaleString('vi-VN')})`;
    if (legShipping) legShipping.innerText = `${data.shippingPct}% (${data.shipping.toLocaleString('vi-VN')})`;
    if (legCancelled) legCancelled.innerText = `${data.cancelledPct}% (${data.cancelled.toLocaleString('vi-VN')})`;
}

/**
 * Xử lý các nút duyệt nhanh trong Modal 2 (Pending Orders Modal)
 */
function initQuickActions() {
    document.querySelectorAll('[data-quick-confirm]').forEach(btn => {
        btn.addEventListener('click', function () {
            const orderId = this.getAttribute('data-quick-confirm');
            const row = document.getElementById('pending-order-row-' + orderId);

            if (!confirm('Bạn có chắc chắn muốn xác nhận đơn hàng #' + orderId + ' vào Database?')) {
                return;
            }

            btn.disabled = true;
            btn.innerHTML = '<span class="spinner-border spinner-border-sm"></span> Đang duyệt...';

            fetch('/admin/dashboard/quick-confirm/' + orderId, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' }
            })
            .then(res => res.json())
            .then(data => {
                if (data.success) {
                    alert(data.message);
                    if (row) {
                        row.classList.add('table-success');
                        setTimeout(() => row.remove(), 800);
                    }
                    decrementPendingCounters();
                } else {
                    alert(data.message);
                    btn.disabled = false;
                    btn.innerHTML = '<i class="bi bi-check-lg"></i> Duyệt nhanh';
                }
            })
            .catch(err => {
                alert('Lỗi kết nối máy chủ: ' + err);
                btn.disabled = false;
                btn.innerHTML = '<i class="bi bi-check-lg"></i> Duyệt nhanh';
            });
        });
    });
}

/**
 * Cấu hình Modal mục tiêu kinh doanh
 */
window.openTargetModalForMonth = function (btn) {
    const month = btn.getAttribute('data-set-month');
    const year = btn.getAttribute('data-set-year');
    const target = btn.getAttribute('data-set-target');

    const mInput = document.getElementById('modalTargetMonth');
    const yInput = document.getElementById('modalTargetYear');
    const tInput = document.getElementById('modalMonthlyTarget');

    if (mInput && month) mInput.value = month;
    if (yInput && year) yInput.value = year;
    if (tInput && target) tInput.value = target;

    const modalEl = document.getElementById('targetSettingModal');
    if (modalEl) {
        const modal = bootstrap.Modal.getOrCreateInstance(modalEl);
        modal.show();
    }
};

window.confirmTargetChange = function (e) {
    const month = document.getElementById('modalTargetMonth')?.value;
    const year = document.getElementById('modalTargetYear')?.value;
    const target = document.getElementById('modalMonthlyTarget')?.value;

    const formattedTarget = Number(target || 0).toLocaleString('vi-VN') + ' đ';

    const msg = '⚠️ XÁC NHẬN THAY ĐỔI MỤC TIÊU KINH DOANH:\n\n' +
                'Mục tiêu doanh thu là chỉ tiêu kinh doanh trọng yếu của cửa hàng, ảnh hưởng đến việc đánh giá hiệu suất kinh doanh.\n\n' +
                'Bạn có chắc chắn muốn cập nhật mục tiêu của Tháng ' + month + '/' + year + ' thành: ' + formattedTarget + ' không?';

    if (!confirm(msg)) {
        if (e) e.preventDefault();
        return false;
    }
    return true;
};
