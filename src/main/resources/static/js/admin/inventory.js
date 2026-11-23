/**
 * Quản lý kho hàng & kiểm kê, nhập kho đa dòng
 * Path: /static/js/admin/inventory.js
 */

// ================= XỬ LÝ CHỌN NHIỀU SKU TRÊN BẢNG TỒN KHO =================
function toggleSelectAllVariants(master) {
    const checkboxes = document.querySelectorAll('.variant-row-checkbox');
    checkboxes.forEach(cb => cb.checked = master.checked);
    updateBulkActionBar();
}

function onVariantCheckboxChange() {
    const master = document.getElementById('selectAllVariantsCheckbox');
    const checkboxes = Array.from(document.querySelectorAll('.variant-row-checkbox'));
    const checkedCount = checkboxes.filter(cb => cb.checked).length;
    if (master) {
        master.checked = (checkboxes.length > 0 && checkedCount === checkboxes.length);
        master.indeterminate = (checkedCount > 0 && checkedCount < checkboxes.length);
    }
    updateBulkActionBar();
}

function updateBulkActionBar() {
    const checkedBoxes = document.querySelectorAll('.variant-row-checkbox:checked');
    const bar = document.getElementById('bulkActionBar');
    const countText = document.getElementById('bulkSelectedCount');
    if (bar && countText) {
        if (checkedBoxes.length > 0) {
            bar.style.display = 'flex';
            countText.textContent = checkedBoxes.length;
        } else {
            bar.style.display = 'none';
            countText.textContent = '0';
        }
    }
}

function deselectAllVariants() {
    const master = document.getElementById('selectAllVariantsCheckbox');
    if (master) master.checked = false;
    document.querySelectorAll('.variant-row-checkbox').forEach(cb => cb.checked = false);
    updateBulkActionBar();
}

// ================= XỬ LÝ FORM NHẬP KHO NHIỀU DÒNG (MULTI-ROW IMPORT) =================
function formatVND(amount) {
    return Number(amount || 0).toLocaleString('vi-VN') + ' đ';
}

function showImportFormAlert(msg) {
    const alertBox = document.getElementById('importFormAlert');
    const alertText = document.getElementById('importFormAlertText');
    if (alertBox && alertText) {
        alertText.textContent = msg;
        alertBox.classList.remove('d-none');
    }
}

function hideImportFormAlert() {
    const alertBox = document.getElementById('importFormAlert');
    if (alertBox) alertBox.classList.add('d-none');
}

function reindexImportRows() {
    const tbody = document.getElementById('importItemsTbody');
    const rows = tbody.querySelectorAll('tr.import-item-row');
    rows.forEach((tr, index) => {
        const idxCell = tr.querySelector('.row-index-cell');
        if (idxCell) idxCell.textContent = index + 1;
    });
    updateImportSummary();
}

function updateImportSummary() {
    const tbody = document.getElementById('importItemsTbody');
    const rows = tbody.querySelectorAll('tr.import-item-row');
    let totalQty = 0;
    let totalAmount = 0;

    rows.forEach(tr => {
        const qtyInput = tr.querySelector('.import-qty-input');
        const priceInput = tr.querySelector('.import-price-input');
        const totalCell = tr.querySelector('.import-line-total');

        const qty = parseInt(qtyInput ? qtyInput.value : '0', 10) || 0;
        const price = parseFloat(priceInput ? priceInput.value : '0') || 0;
        const lineTotal = (qty > 0 && price >= 0) ? (qty * price) : 0;

        if (totalCell) {
            totalCell.textContent = formatVND(lineTotal);
        }

        if (qty > 0) {
            totalQty += qty;
        }
        totalAmount += lineTotal;
    });

    const rowsCountEl = document.getElementById('importSummaryRowsCount');
    const totalQtyEl = document.getElementById('importSummaryTotalQty');
    const totalAmountEl = document.getElementById('importSummaryTotalAmount');

    if (rowsCountEl) rowsCountEl.textContent = rows.length;
    if (totalQtyEl) totalQtyEl.textContent = totalQty;
    if (totalAmountEl) totalAmountEl.textContent = formatVND(totalAmount);
}

function escapeHtml(str) {
    return String(str ?? '')
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#39;');
}

function updateVariantMetaCells(tr, select, sizeClass, colorClass, stockClass) {
    const sizeCell = tr.querySelector('.' + sizeClass);
    const colorCell = tr.querySelector('.' + colorClass);
    const stockBadge = tr.querySelector('.' + stockClass);
    const opt = select ? select.options[select.selectedIndex] : null;

    if (opt && opt.value) {
        const size = opt.getAttribute('data-size') || '-';
        const color = opt.getAttribute('data-color') || '-';
        const colorHex = opt.getAttribute('data-color-hex') || '#cfcfcf';
        const stock = opt.getAttribute('data-stock') || '0';

        if (sizeCell) {
            sizeCell.innerHTML = `<span class="modal-size-badge">${escapeHtml(size)}</span>`;
        }
        if (colorCell) {
            colorCell.innerHTML = `
                <span class="modal-color-cell">
                    <span class="color-dot" style="background-color: ${escapeHtml(colorHex)};"></span>
                    <span>${escapeHtml(color)}</span>
                </span>
            `;
        }
        if (stockBadge) {
            stockBadge.textContent = stock + ' chiếc';
            stockBadge.className = 'badge bg-light text-dark border ' + stockClass;
        }
        return { selected: true, stock: parseInt(stock, 10) || 0, size, color, colorHex };
    } else {
        if (sizeCell) {
            sizeCell.innerHTML = '<span class="modal-size-badge is-empty">-</span>';
        }
        if (colorCell) {
            colorCell.innerHTML = '<span class="modal-color-cell is-empty">-</span>';
        }
        if (stockBadge) {
            stockBadge.textContent = '-';
            stockBadge.className = 'badge bg-light text-muted border ' + stockClass;
        }
        return { selected: false, stock: 0 };
    }
}

function onImportSkuChange(select) {
    const tr = select.closest('tr');
    if (!tr) return;
    updateVariantMetaCells(tr, select, 'import-row-size', 'import-row-color', 'import-row-stock');
    hideImportFormAlert();
    updateImportSummary();
}

function onImportRowDataChange(input) {
    hideImportFormAlert();
    updateImportSummary();
}

function removeImportRow(btn) {
    const tr = btn.closest('tr');
    if (tr) {
        tr.remove();
        reindexImportRows();
        hideImportFormAlert();
    }
}

function addImportRow(preselectedVariantId, initialQty = 10, initialPrice = '') {
    const tbody = document.getElementById('importItemsTbody');
    const template = document.getElementById('variantTemplateSelect');
    if (!tbody || !template) return;

    const tr = document.createElement('tr');
    tr.className = 'import-item-row';

    // Clone options from template
    const selectHtml = template.innerHTML;

    tr.innerHTML = `
        <td class="text-center fw-semibold text-muted row-index-cell" style="font-size: 0.8rem;"></td>
        <td>
            <select name="variantId" class="form-select form-select-sm import-sku-select" required onchange="onImportSkuChange(this)">
                ${selectHtml}
            </select>
        </td>
        <td class="text-center import-row-size">
            <span class="modal-size-badge is-empty">-</span>
        </td>
        <td class="import-row-color">
            <span class="modal-color-cell is-empty">-</span>
        </td>
        <td class="text-center">
            <span class="badge bg-light text-muted border import-row-stock">-</span>
        </td>
        <td>
            <div class="input-group input-group-sm">
                <input type="number" name="quantity" class="form-control form-control-sm import-qty-input" min="1" value="${initialQty}" required oninput="onImportRowDataChange(this)">
                <span class="input-group-text">Chiếc</span>
            </div>
        </td>
        <td>
            <div class="input-group input-group-sm">
                <input type="number" name="importPrice" class="form-control form-control-sm import-price-input" min="0" step="1000" placeholder="0" value="${initialPrice}" oninput="onImportRowDataChange(this)">
                <span class="input-group-text">VNĐ</span>
            </div>
        </td>
        <td class="text-end">
            <span class="fw-bold import-line-total text-dark" style="font-size: 0.8rem;">0 đ</span>
        </td>
        <td class="text-center">
            <button type="button" class="btn btn-sm btn-outline-danger p-1 px-2" onclick="removeImportRow(this)" title="Xóa dòng này">
                <i class="bi bi-trash3"></i>
            </button>
        </td>
    `;

    tbody.appendChild(tr);

    const select = tr.querySelector('.import-sku-select');
    if (preselectedVariantId && select) {
        select.value = preselectedVariantId;
        onImportSkuChange(select);
    }

    reindexImportRows();
}

// Mở modal Nhập kho từ Menu ("Nhập kho mới") -> Form mở nhưng chưa có dòng nào
function openImportNewModal() {
    const supplierInput = document.getElementById('importSupplier');
    const reasonInput = document.getElementById('importReason');
    const tbody = document.getElementById('importItemsTbody');
    if (supplierInput) supplierInput.value = '';
    if (reasonInput) reasonInput.value = '';
    if (tbody) tbody.innerHTML = '';
    hideImportFormAlert();
    updateImportSummary();

    const modal = bootstrap.Modal.getOrCreateInstance(document.getElementById('importModal'));
    modal.show();
}

// Mở modal Nhập kho từ danh sách các SKU được tick chọn
function openImportModalFromCheckboxes() {
    const checkedBoxes = Array.from(document.querySelectorAll('.variant-row-checkbox:checked'));
    if (checkedBoxes.length === 0) {
        alert('Vui lòng chọn ít nhất một mã SKU trong danh sách để nhập kho.');
        return;
    }

    const supplierInput = document.getElementById('importSupplier');
    const reasonInput = document.getElementById('importReason');
    const tbody = document.getElementById('importItemsTbody');
    if (supplierInput) supplierInput.value = '';
    if (reasonInput) reasonInput.value = '';
    if (tbody) tbody.innerHTML = '';
    hideImportFormAlert();

    checkedBoxes.forEach(cb => {
        addImportRow(cb.value);
    });

    const modal = bootstrap.Modal.getOrCreateInstance(document.getElementById('importModal'));
    modal.show();
}

// Mở modal Nhập kho từ 1 dòng biến thể đơn lẻ
function openImportModalForSingle(btn) {
    const id = btn.getAttribute('data-id');
    const supplierInput = document.getElementById('importSupplier');
    const reasonInput = document.getElementById('importReason');
    const tbody = document.getElementById('importItemsTbody');
    if (supplierInput) supplierInput.value = '';
    if (reasonInput) reasonInput.value = '';
    if (tbody) tbody.innerHTML = '';
    hideImportFormAlert();

    if (id) {
        addImportRow(id);
    }

    const modal = bootstrap.Modal.getOrCreateInstance(document.getElementById('importModal'));
    modal.show();
}

// ================= XỬ LÝ FORM KIỂM KÊ KHO NHIỀU DÒNG (MULTI-ROW AUDIT) =================
function showAuditFormAlert(msg) {
    const alertBox = document.getElementById('auditFormAlert');
    const alertText = document.getElementById('auditFormAlertText');
    if (alertBox && alertText) {
        alertText.textContent = msg;
        alertBox.classList.remove('d-none');
    }
}

function hideAuditFormAlert() {
    const alertBox = document.getElementById('auditFormAlert');
    if (alertBox) alertBox.classList.add('d-none');
}

function onAuditReasonPresetChange(select) {
    const reasonInput = document.getElementById('auditCommonReason');
    if (!reasonInput) return;
    if (select.value) {
        reasonInput.value = select.value;
    } else {
        reasonInput.value = '';
        reasonInput.focus();
    }
    hideAuditFormAlert();
}

function reindexAuditRows() {
    const tbody = document.getElementById('auditItemsTbody');
    if (!tbody) return;
    const rows = tbody.querySelectorAll('tr.audit-item-row');
    rows.forEach((tr, index) => {
        const idxCell = tr.querySelector('.row-index-cell');
        if (idxCell) idxCell.textContent = index + 1;

        const select = tr.querySelector('.audit-sku-select');
        const actualInput = tr.querySelector('.audit-actual-input');
        const reasonInput = tr.querySelector('.audit-row-reason');
        if (select) select.name = `items[${index}].variantId`;
        if (actualInput) actualInput.name = `items[${index}].actualStock`;
        if (reasonInput) reasonInput.name = `items[${index}].reason`;
    });
    updateAuditSummary();
}

function updateAuditRowDiff(tr) {
    const select = tr.querySelector('.audit-sku-select');
    const actualInput = tr.querySelector('.audit-actual-input');
    const diffCell = tr.querySelector('.audit-row-diff');
    const opt = select ? select.options[select.selectedIndex] : null;

    if (!opt || !opt.value) {
        if (diffCell) diffCell.innerHTML = '<span class="audit-diff-pill audit-diff-empty">Chưa chọn SKU</span>';
        return null;
    }

    if (!actualInput || actualInput.value.trim() === '') {
        if (diffCell) diffCell.innerHTML = '<span class="audit-diff-pill audit-diff-empty">Chưa nhập</span>';
        return null;
    }

    const systemStock = parseInt(opt.getAttribute('data-stock') || '0', 10) || 0;
    const actualStock = parseInt(actualInput.value, 10);
    if (isNaN(actualStock)) {
        if (diffCell) diffCell.innerHTML = '<span class="audit-diff-pill audit-diff-empty">Không hợp lệ</span>';
        return null;
    }

    const diff = actualStock - systemStock;
    if (diffCell) {
        if (diff > 0) {
            diffCell.innerHTML = `<span class="audit-diff-pill audit-diff-plus">+${diff} (Thừa)</span>`;
        } else if (diff < 0) {
            diffCell.innerHTML = `<span class="audit-diff-pill audit-diff-minus">${diff} (Thiếu)</span>`;
        } else {
            diffCell.innerHTML = '<span class="audit-diff-pill audit-diff-zero">0 (Khớp)</span>';
        }
    }
    return diff;
}

function updateAuditSummary() {
    const tbody = document.getElementById('auditItemsTbody');
    if (!tbody) return;
    const rows = tbody.querySelectorAll('tr.audit-item-row');
    let matchedCount = 0;
    let surplusQty = 0;
    let shortageQty = 0;
    let netDiff = 0;

    rows.forEach(tr => {
        const diff = updateAuditRowDiff(tr);
        if (diff !== null) {
            if (diff === 0) {
                matchedCount++;
            } else if (diff > 0) {
                surplusQty += diff;
            } else {
                shortageQty += diff;
            }
            netDiff += diff;
        }
    });

    const rowsCountEl = document.getElementById('auditSummaryRowsCount');
    const matchedEl = document.getElementById('auditSummaryMatchedCount');
    const surplusEl = document.getElementById('auditSummarySurplusQty');
    const shortageEl = document.getElementById('auditSummaryShortageQty');
    const netDiffEl = document.getElementById('auditSummaryNetDiff');

    if (rowsCountEl) rowsCountEl.textContent = rows.length;
    if (matchedEl) matchedEl.textContent = matchedCount;
    if (surplusEl) surplusEl.textContent = '+' + surplusQty;
    if (shortageEl) shortageEl.textContent = String(shortageQty);
    if (netDiffEl) {
        const formattedNet = (netDiff > 0 ? '+' : '') + netDiff + ' chiếc';
        netDiffEl.textContent = formattedNet;
        netDiffEl.className = 'fs-6 ' + (netDiff > 0 ? 'text-success' : (netDiff < 0 ? 'text-danger' : 'text-primary'));
    }
}

function onAuditSkuChange(select) {
    const tr = select.closest('tr');
    if (!tr) return;
    const meta = updateVariantMetaCells(tr, select, 'audit-row-size', 'audit-row-color', 'audit-row-system-stock');
    const actualInput = tr.querySelector('.audit-actual-input');
    if (actualInput) {
        if (meta.selected) {
            actualInput.value = meta.stock;
        } else {
            actualInput.value = '';
        }
    }
    hideAuditFormAlert();
    updateAuditSummary();
}

function onAuditRowDataChange(input) {
    hideAuditFormAlert();
    updateAuditSummary();
}

function removeAuditRow(btn) {
    const tr = btn.closest('tr');
    if (tr) {
        tr.remove();
        reindexAuditRows();
        hideAuditFormAlert();
    }
}

function addAuditRow(preselectedVariantId, initialActualStock = null, initialReason = '') {
    const tbody = document.getElementById('auditItemsTbody');
    const template = document.getElementById('variantTemplateSelect');
    if (!tbody || !template) return;

    const tr = document.createElement('tr');
    tr.className = 'audit-item-row';

    const selectHtml = template.innerHTML;

    tr.innerHTML = `
        <td class="text-center fw-semibold text-muted row-index-cell" style="font-size: 0.8rem;"></td>
        <td>
            <select class="form-select form-select-sm audit-sku-select" required onchange="onAuditSkuChange(this)">
                ${selectHtml}
            </select>
        </td>
        <td class="text-center audit-row-size">
            <span class="modal-size-badge is-empty">-</span>
        </td>
        <td class="audit-row-color">
            <span class="modal-color-cell is-empty">-</span>
        </td>
        <td class="text-center">
            <span class="badge bg-light text-muted border audit-row-system-stock">-</span>
        </td>
        <td>
            <div class="input-group input-group-sm">
                <input type="number" class="form-control form-control-sm audit-actual-input" min="0" placeholder="Nhập SL" required oninput="onAuditRowDataChange(this)">
                <span class="input-group-text">Chiếc</span>
            </div>
        </td>
        <td class="text-center audit-row-diff">
            <span class="audit-diff-pill audit-diff-empty">Chưa chọn SKU</span>
        </td>
        <td>
            <input type="text" class="form-control form-control-sm audit-row-reason" placeholder="Theo lý do chung" value="${escapeHtml(initialReason)}">
        </td>
        <td class="text-center">
            <button type="button" class="btn btn-sm btn-outline-danger p-1 px-2" onclick="removeAuditRow(this)" title="Xóa dòng này">
                <i class="bi bi-trash3"></i>
            </button>
        </td>
    `;

    tbody.appendChild(tr);

    const select = tr.querySelector('.audit-sku-select');
    if (preselectedVariantId && select) {
        select.value = preselectedVariantId;
        onAuditSkuChange(select);
        if (initialActualStock !== null && initialActualStock !== undefined) {
            const actualInput = tr.querySelector('.audit-actual-input');
            if (actualInput) actualInput.value = initialActualStock;
        }
    }

    reindexAuditRows();
}

function resetAuditModalHeaderAndBody() {
    const preset = document.getElementById('auditReasonPreset');
    const reasonInput = document.getElementById('auditCommonReason');
    const tbody = document.getElementById('auditItemsTbody');
    if (preset) preset.value = 'Kiểm kê định kỳ';
    if (reasonInput) reasonInput.value = 'Kiểm kê định kỳ';
    if (tbody) tbody.innerHTML = '';
    hideAuditFormAlert();
}

// Mở modal Kiểm kê nhanh từ nút trên cùng ("Kiểm kê kho")
function openAuditQuickModal() {
    resetAuditModalHeaderAndBody();
    addAuditRow();

    const modal = bootstrap.Modal.getOrCreateInstance(document.getElementById('auditModal'));
    modal.show();
}

// Mở modal Kiểm kê từ danh sách các SKU được tick chọn
function openAuditModalFromCheckboxes() {
    const checkedBoxes = Array.from(document.querySelectorAll('.variant-row-checkbox:checked'));
    if (checkedBoxes.length === 0) {
        alert('Vui lòng chọn ít nhất một mã SKU trong danh sách để kiểm kê.');
        return;
    }

    resetAuditModalHeaderAndBody();
    checkedBoxes.forEach(cb => {
        addAuditRow(cb.value);
    });

    const modal = bootstrap.Modal.getOrCreateInstance(document.getElementById('auditModal'));
    modal.show();
}

// Mở modal Kiểm kê từ 1 dòng biến thể đơn lẻ (có thể bấm "+ Thêm dòng SKU" để kiểm kê thêm)
function openAuditModal(btn) {
    const id = btn.getAttribute('data-id');
    resetAuditModalHeaderAndBody();
    if (id) {
        addAuditRow(id);
    } else {
        addAuditRow();
    }

    const modal = bootstrap.Modal.getOrCreateInstance(document.getElementById('auditModal'));
    modal.show();
}

// Bắt sự kiện submit của form multiImportForm và multiAuditForm để validate dữ liệu
document.addEventListener('DOMContentLoaded', function () {
    const importForm = document.getElementById('multiImportForm');
    if (importForm) {
        importForm.addEventListener('submit', function (e) {
            const rows = importForm.querySelectorAll('tr.import-item-row');
            if (rows.length === 0) {
                e.preventDefault();
                showImportFormAlert('Phiếu nhập kho phải có ít nhất một dòng SKU. Bấm "+ Thêm dòng SKU" để thêm.');
                return;
            }

            const selectedSkus = new Set();
            for (let i = 0; i < rows.length; i++) {
                const tr = rows[i];
                const select = tr.querySelector('.import-sku-select');
                const qtyInput = tr.querySelector('.import-qty-input');
                const priceInput = tr.querySelector('.import-price-input');

                const vId = select ? select.value : '';
                if (!vId) {
                    e.preventDefault();
                    showImportFormAlert('Dòng số ' + (i + 1) + ': Vui lòng chọn mã SKU / Biến thể sản phẩm.');
                    if (select) select.focus();
                    return;
                }

                if (selectedSkus.has(vId)) {
                    e.preventDefault();
                    const skuName = select.options[select.selectedIndex]?.text || ('ID #' + vId);
                    showImportFormAlert('Dòng số ' + (i + 1) + ' bị trùng lặp biến thể (' + skuName + '). Vui lòng gộp số lượng hoặc xóa dòng trùng.');
                    if (select) select.focus();
                    return;
                }
                selectedSkus.add(vId);

                const qty = parseInt(qtyInput ? qtyInput.value : '0', 10);
                if (isNaN(qty) || qty <= 0) {
                    e.preventDefault();
                    showImportFormAlert('Dòng số ' + (i + 1) + ': Số lượng nhập kho phải là số nguyên lớn hơn 0.');
                    if (qtyInput) qtyInput.focus();
                    return;
                }

                if (priceInput && priceInput.value.trim() !== '') {
                    const price = Number(priceInput.value);
                    if (isNaN(price) || price < 0) {
                        e.preventDefault();
                        showImportFormAlert('Dòng số ' + (i + 1) + ': Đơn giá nhập không được là số âm.');
                        priceInput.focus();
                        return;
                    }
                }
            }

            hideImportFormAlert();
        });
    }

    const auditForm = document.getElementById('multiAuditForm');
    if (auditForm) {
        auditForm.addEventListener('submit', function (e) {
            reindexAuditRows();
            const rows = auditForm.querySelectorAll('tr.audit-item-row');
            if (rows.length === 0) {
                e.preventDefault();
                showAuditFormAlert('Phiếu kiểm kê phải có ít nhất một dòng SKU. Bấm "+ Thêm dòng SKU" để thêm.');
                return;
            }

            const commonReasonInput = document.getElementById('auditCommonReason');
            if (commonReasonInput && commonReasonInput.value.trim() === '') {
                e.preventDefault();
                showAuditFormAlert('Vui lòng nhập lý do / ghi chú kiểm kê chung.');
                commonReasonInput.focus();
                return;
            }

            const selectedSkus = new Set();
            for (let i = 0; i < rows.length; i++) {
                const tr = rows[i];
                const select = tr.querySelector('.audit-sku-select');
                const actualInput = tr.querySelector('.audit-actual-input');

                const vId = select ? select.value : '';
                if (!vId) {
                    e.preventDefault();
                    showAuditFormAlert('Dòng số ' + (i + 1) + ': Vui lòng chọn mã SKU / Biến thể sản phẩm.');
                    if (select) select.focus();
                    return;
                }

                if (selectedSkus.has(vId)) {
                    e.preventDefault();
                    const skuName = select.options[select.selectedIndex]?.text || ('ID #' + vId);
                    showAuditFormAlert('Dòng số ' + (i + 1) + ' bị trùng lặp biến thể (' + skuName + '). Vui lòng xóa dòng trùng.');
                    if (select) select.focus();
                    return;
                }
                selectedSkus.add(vId);

                const rawActual = actualInput ? actualInput.value.trim() : '';
                const actual = Number(rawActual);
                if (rawActual === '' || isNaN(actual) || !Number.isInteger(actual) || actual < 0) {
                    e.preventDefault();
                    showAuditFormAlert('Dòng số ' + (i + 1) + ': Tồn thực tế phải là số nguyên không âm (>= 0).');
                    if (actualInput) actualInput.focus();
                    return;
                }
            }

            hideAuditFormAlert();
        });
    }
});

// Mở modal Lịch sử biến động qua AJAX
function openHistoryModal(btn) {
    const id = btn.getAttribute('data-id');
    const sku = btn.getAttribute('data-sku');
    const name = btn.getAttribute('data-name');

    document.getElementById('historySkuTitle').textContent = sku;
    document.getElementById('historyProductName').textContent = name;

    const loading = document.getElementById('historyLoading');
    const empty = document.getElementById('historyEmpty');
    const content = document.getElementById('historyContent');
    const tbody = document.getElementById('historyTableBody');

    loading.classList.remove('d-none');
    empty.classList.add('d-none');
    content.classList.add('d-none');
    tbody.innerHTML = '';

    const modal = new bootstrap.Modal(document.getElementById('historyModal'));
    modal.show();

    fetch('/admin/inventory/api/history/' + id)
        .then(res => res.json())
        .then(data => {
            loading.classList.add('d-none');
            if (!data || data.length === 0) {
                empty.classList.remove('d-none');
                return;
            }
            content.classList.remove('d-none');
            tbody.innerHTML = data.map(item => `
                <tr>
                    <td><small class="text-muted">${item.createdAt}</small></td>
                    <td><span class="badge ${item.typeClass}">${item.typeLabel}</span></td>
                    <td><b class="${item.quantityChange > 0 ? 'change-plus' : (item.quantityChange < 0 ? 'change-minus' : 'change-zero')}">${item.formattedChange}</b></td>
                    <td><b>${item.stockAfter} chiếc</b></td>
                    <td>${item.performer}</td>
                    <td>
                        <div>${item.reason || '-'}</div>
                        ${item.supplier !== '-' ? '<small class="text-muted d-block">NCC: ' + item.supplier + '</small>' : ''}
                    </td>
                </tr>
            `).join('');
        })
        .catch(err => {
            loading.classList.add('d-none');
            empty.classList.remove('d-none');
            empty.innerHTML = '<span class="text-danger"><i class="bi bi-exclamation-triangle me-1"></i> Không thể tải dữ liệu lịch sử.</span>';
        });
}
