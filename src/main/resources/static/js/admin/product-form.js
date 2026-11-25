/**
 * Quản lý form thêm/sửa sản phẩm & ma trận biến thể, upload ảnh Cloudinary
 * Path: /static/js/admin/product-form.js
 */
(function () {
    const config = window.PRODUCT_FORM_CONFIG || {};
    const isEditMode = Boolean(config.isEditMode);
    const initialActiveVariantKeys = Array.isArray(config.initialActiveVariantKeys) ? config.initialActiveVariantKeys : [];
    const STORAGE_KEY = 'admin_product_form_draft_v1';

    const form = document.getElementById('productForm');
    const submitButton = document.getElementById('submitButton');
    const nameInput = document.getElementById('productName');
    const categorySelect = document.getElementById('categoryId');
    const descriptionInput = document.getElementById('productDescription');
    const priceInput = document.getElementById('price');
    const salePriceInput = document.getElementById('salePrice');
    const imageFileGroup = document.getElementById('imageFileGroup');
    const imageUrlGroup = document.getElementById('imageUrlGroup');
    const imageSourceRadios = document.querySelectorAll('input[name="imageSourceMode"]');
    const imageFileInput = document.getElementById('imageFile');
    const imageUrlInput = document.getElementById('imageUrl');
    const imagePreview = document.getElementById('imagePreview');
    const draftAlert = document.getElementById('draftAlert');
    const draftTime = document.getElementById('draftTime');
    const clearDraftBtn = document.getElementById('clearDraftBtn');
    const cancelBtn = document.getElementById('cancelBtn');

    const matrixTable = document.getElementById('variantMatrixTable');
    const matrixScroll = document.getElementById('variantMatrixScroll');
    const countSelectedEl = document.getElementById('variantCountSelected');
    const countTotalEl = document.getElementById('variantCountTotal');
    const btnToggleAllMatrix = document.getElementById('btnToggleAllMatrix');
    const matrixError = document.getElementById('matrixError');

    const nameError = document.getElementById('nameError');
    const categoryError = document.getElementById('categoryError');
    const descriptionError = document.getElementById('descriptionError');
    const priceError = document.getElementById('priceError');
    const salePriceError = document.getElementById('salePriceError');
    const imageFileError = document.getElementById('imageFileError');
    const imageUrlError = document.getElementById('imageUrlError');
    const sizeError = document.getElementById('sizeError');
    const colorError = document.getElementById('colorError');

    // Bảng lưu trữ trạng thái checkbox của từng ô ma trận: "SIZE___COLOR" -> boolean
    const matrixState = {};

    // Khởi tạo trạng thái ban đầu cho edit mode nếu có danh sách biến thể đang hoạt động
    if (isEditMode && Array.isArray(initialActiveVariantKeys)) {
        const initialSizes = Array.from(document.querySelectorAll('input[name="sizes"]:checked')).map(cb => cb.value.trim());
        const initialColors = Array.from(document.querySelectorAll('input[name="colors"]:checked')).map(cb => cb.value.trim());
        const activeSet = new Set(initialActiveVariantKeys.map(k => (k || '').trim().toUpperCase()));
        initialSizes.forEach(s => {
            initialColors.forEach(c => {
                const key = s.toUpperCase() + '___' + c.toUpperCase();
                matrixState[key] = activeSet.has(key);
            });
        });
    }

    // Theo dõi trạng thái đã tương tác (touched) của từng trường
    const touched = {
        name: false,
        categoryId: false,
        description: false,
        price: false,
        salePrice: false,
        imageUrl: false,
        sizes: false,
        colors: false
    };

    let autoSaveTimer = null;
    let isSubmitting = false;

    // ================= CÁC HÀM VALIDATE TỪNG Ô INPUT =================
    function validateName(showError = true) {
        const val = nameInput.value.trim();
        let error = '';
        if (!val) {
            error = 'Vui lòng nhập tên sản phẩm.';
        } else if (val.length > 200) {
            error = 'Tên sản phẩm không được vượt quá 200 ký tự.';
        }
        if (showError || touched.name) {
            nameError.textContent = error;
            nameInput.classList.toggle('input-error', !!error);
        }
        return !error;
    }

    function validateCategory(showError = true) {
        const val = categorySelect.value;
        let error = '';
        if (!val) {
            error = 'Vui lòng chọn danh mục sản phẩm.';
        }
        if (showError || touched.categoryId) {
            categoryError.textContent = error;
            categorySelect.classList.toggle('input-error', !!error);
        }
        return !error;
    }

    function validateDescription(showError = true) {
        const val = descriptionInput.value.trim();
        let error = '';
        if (!val) {
            error = 'Vui lòng nhập mô tả chi tiết sản phẩm.';
        } else if (val.length > 2000) {
            error = 'Mô tả không được vượt quá 2000 ký tự.';
        }
        if (showError || touched.description) {
            descriptionError.textContent = error;
            descriptionInput.classList.toggle('input-error', !!error);
        }
        return !error;
    }

    function validatePrice(showError = true) {
        const raw = priceInput.value.trim();
        let error = '';
        if (!raw) {
            error = 'Vui lòng nhập giá gốc sản phẩm.';
        } else {
            const num = Number(raw);
            if (isNaN(num) || num <= 0 || !Number.isInteger(num)) {
                error = 'Giá gốc phải là số nguyên lớn hơn 0 VNĐ.';
            } else if (num % 1000 !== 0) {
                error = 'Giá gốc phải là bội số của 1.000 VNĐ.';
            }
        }

        if (showError || touched.price) {
            priceError.textContent = error;
            priceInput.classList.toggle('input-error', !!error);
        }

        // Cập nhật gợi ý placeholder cho giá khuyến mãi nếu người dùng chưa nhập
        if (raw && !isNaN(Number(raw)) && Number(raw) > 0) {
            salePriceInput.placeholder = 'Mặc định = ' + Number(raw).toLocaleString('vi-VN') + ' VNĐ';
        } else {
            salePriceInput.placeholder = 'Mặc định = giá gốc';
        }

        // Nếu ô giá khuyến mãi đã có giá trị, cần validate lại theo giá gốc mới
        if (salePriceInput.value.trim() !== '') {
            validateSalePrice(touched.salePrice);
        }

        return !error;
    }

    function validateSalePrice(showError = true) {
        const raw = salePriceInput.value.trim();
        let error = '';
        if (raw !== '') {
            const num = Number(raw);
            const priceRaw = priceInput.value.trim();
            const priceNum = Number(priceRaw);

            if (isNaN(num) || num < 0 || !Number.isInteger(num)) {
                error = 'Giá khuyến mãi phải là số nguyên không âm.';
            } else if (num % 1000 !== 0) {
                error = 'Giá khuyến mãi phải là bội số của 1.000 VNĐ.';
            } else if (priceRaw !== '' && !isNaN(priceNum) && priceNum > 0 && num > priceNum) {
                error = 'Giá khuyến mãi không được lớn hơn giá gốc.';
            }
        }

        if (showError || touched.salePrice) {
            salePriceError.textContent = error;
            salePriceInput.classList.toggle('input-error', !!error);
        }
        return !error;
    }

    function getImageSourceMode() {
        const checked = document.querySelector('input[name="imageSourceMode"]:checked');
        return checked ? checked.value : 'file';
    }

    function syncImageSourceMode() {
        const mode = getImageSourceMode();
        const isFileMode = mode === 'file';
        if (imageFileGroup) imageFileGroup.style.display = isFileMode ? 'block' : 'none';
        if (imageUrlGroup) imageUrlGroup.style.display = isFileMode ? 'none' : 'block';
        if (imageFileInput) imageFileInput.disabled = !isFileMode;
        if (imageUrlInput) imageUrlInput.disabled = isFileMode;

        if (isFileMode) {
            if (imageUrlError) imageUrlError.textContent = '';
            if (imageUrlInput) imageUrlInput.classList.remove('input-error');
        } else {
            if (imageFileError) imageFileError.textContent = '';
            if (imageFileInput) imageFileInput.classList.remove('input-error');
        }
    }

    function validateImageFile(showError = true) {
        if (getImageSourceMode() !== 'file') {
            if (imageFileError) imageFileError.textContent = '';
            if (imageFileInput) imageFileInput.classList.remove('input-error');
            return true;
        }
        const file = imageFileInput && imageFileInput.files ? imageFileInput.files[0] : null;
        let error = '';
        if (!file) {
            error = 'Vui lòng chọn file ảnh từ máy tính.';
        } else {
            const ext = file.name.split('.').pop().toLowerCase();
            if (!['jpg', 'jpeg', 'png', 'webp'].includes(ext)) {
                error = 'Định dạng file không hợp lệ. Chỉ hỗ trợ JPG, JPEG, PNG, WEBP.';
            } else if (file.size > 10 * 1024 * 1024) {
                error = 'Kích thước ảnh vượt quá giới hạn 10MB.';
            }
        }
        if ((showError || touched.imageUrl) && imageFileError) {
            imageFileError.textContent = error;
            imageFileInput.classList.toggle('input-error', !!error);
        }
        return !error;
    }

    function validateImageUrl(showError = true) {
        if (getImageSourceMode() === 'file') {
            return validateImageFile(showError);
        }
        const raw = imageUrlInput.value.trim();
        let error = '';
        if (!raw) {
            error = 'Vui lòng nhập URL hình ảnh sản phẩm.';
        } else {
            try {
                const u = new URL(raw);
                if (u.protocol !== 'http:' && u.protocol !== 'https:') {
                    error = 'URL hình ảnh phải bắt đầu bằng http:// hoặc https://';
                }
            } catch (e) {
                error = 'Định dạng URL hình ảnh không hợp lệ.';
            }
        }

        if (showError || touched.imageUrl) {
            imageUrlError.textContent = error;
            imageUrlInput.classList.toggle('input-error', !!error);
        }
        return !error;
    }

    function validateSizes(showError = true) {
        const checked = document.querySelectorAll('input[name="sizes"]:checked');
        let error = '';
        if (checked.length === 0) {
            error = 'Vui lòng chọn ít nhất một kích thước (size).';
        }
        if (showError || touched.sizes) {
            sizeError.textContent = error;
        }
        return !error;
    }

    function validateColors(showError = true) {
        const checked = document.querySelectorAll('input[name="colors"]:checked');
        let error = '';
        if (checked.length === 0) {
            error = 'Vui lòng chọn ít nhất một màu sắc.';
        }
        if (showError || touched.colors) {
            colorError.textContent = error;
        }
        return !error;
    }

    function validateMatrix(showError = true) {
        const selectedSizes = Array.from(document.querySelectorAll('input[name="sizes"]:checked')).map(cb => cb.value.trim());
        const selectedColors = Array.from(document.querySelectorAll('input[name="colors"]:checked')).map(cb => cb.value.trim());
        let error = '';

        if (selectedSizes.length === 0 || selectedColors.length === 0) {
            error = 'Vui lòng chọn size và màu để hiển thị bảng ma trận biến thể.';
        } else {
            let selectedCount = 0;
            selectedSizes.forEach(s => {
                selectedColors.forEach(c => {
                    const key = s.toUpperCase() + '___' + c.toUpperCase();
                    if (matrixState[key]) {
                        selectedCount++;
                    }
                });
            });
            if (selectedCount === 0) {
                error = 'Bắt buộc chọn ít nhất một biến thể trong bảng ma trận.';
            }
        }

        if (showError || touched.sizes || touched.colors) {
            if (matrixError) {
                matrixError.textContent = error;
            }
        }
        return !error;
    }

    // Kiểm tra toàn bộ form có thỏa mãn hay không
    function isFormValid() {
        const vName = validateName(false);
        const vCat = validateCategory(false);
        const vDesc = validateDescription(false);
        const vPrice = validatePrice(false);
        const vSale = validateSalePrice(false);
        const vImg = validateImageUrl(false);
        const vSize = validateSizes(false);
        const vColor = validateColors(false);
        const vMatrix = validateMatrix(false);
        return vName && vCat && vDesc && vPrice && vSale && vImg && vSize && vColor && vMatrix;
    }

    // Cập nhật trạng thái nút submit
    function updateSubmitState() {
        const valid = isFormValid();
        submitButton.disabled = !valid;
        if (valid) {
            submitButton.removeAttribute('title');
        } else {
            submitButton.setAttribute('title', 'Vui lòng điền đầy đủ và chính xác các thông tin bắt buộc');
        }
    }

    // Đánh dấu tất cả là touched khi submit
    function touchAll() {
        Object.keys(touched).forEach(k => touched[k] = true);
        validateName(true);
        validateCategory(true);
        validateDescription(true);
        validatePrice(true);
        validateSalePrice(true);
        validateImageUrl(true);
        validateSizes(true);
        validateColors(true);
        validateMatrix(true);
    }

    // ================= CẬP NHẬT MA TRẬN BIẾN THỂ & PREVIEW ẢNH =================
    function updateMatrixCounts() {
        const selectedSizes = Array.from(document.querySelectorAll('input[name="sizes"]:checked')).map(cb => cb.value.trim());
        const selectedColors = Array.from(document.querySelectorAll('input[name="colors"]:checked')).map(cb => cb.value.trim());
        const total = selectedSizes.length * selectedColors.length;

        let selected = 0;
        selectedSizes.forEach(s => {
            selectedColors.forEach(c => {
                const key = s.toUpperCase() + '___' + c.toUpperCase();
                if (matrixState[key]) {
                    selected++;
                }
            });
        });

        if (countSelectedEl) countSelectedEl.textContent = selected;
        if (countTotalEl) countTotalEl.textContent = total;

        if (matrixError && (touched.sizes || touched.colors)) {
            if (total > 0 && selected === 0) {
                matrixError.textContent = 'Bắt buộc chọn ít nhất một biến thể trong bảng ma trận.';
            } else if (total > 0 && selected > 0) {
                matrixError.textContent = '';
            }
        }
    }

    function renderMatrix() {
        if (!matrixTable) return;
        const selectedSizes = Array.from(document.querySelectorAll('input[name="sizes"]:checked')).map(cb => cb.value.trim());
        const selectedColors = Array.from(document.querySelectorAll('input[name="colors"]:checked')).map(cb => cb.value.trim());

        if (selectedSizes.length === 0 || selectedColors.length === 0) {
            matrixTable.innerHTML = '<tbody><tr><td class="text-muted py-3" style="font-size:0.75rem;">Vui lòng chọn ít nhất 1 size và 1 màu để hiển thị bảng ma trận biến thể.</td></tr></tbody>';
            if (countSelectedEl) countSelectedEl.textContent = '0';
            if (countTotalEl) countTotalEl.textContent = '0';
            return;
        }

        // Điền mặc định true cho các ô mới tạo chưa có trong matrixState (bảo toàn ô cũ)
        selectedSizes.forEach(s => {
            selectedColors.forEach(c => {
                const key = s.toUpperCase() + '___' + c.toUpperCase();
                if (matrixState[key] === undefined) {
                    matrixState[key] = true;
                }
            });
        });

        // Xây dựng tiêu đề cột (Màu sắc)
        let html = '<thead><tr>';
        html += '<th style="min-width: 80px;">Size \\ Màu</th>';
        selectedColors.forEach(c => {
            html += `<th>
                <div style="font-weight: 700; color: #1f2937;">${c}</div>
                <button type="button" class="btn-matrix-toggle" data-col="${c}" title="Chọn / Bỏ chọn toàn bộ cột ${c}">
                    <i class="bi bi-arrows-vertical"></i> Cột
                </button>
            </th>`;
        });
        html += '</tr></thead><tbody>';

        // Xây dựng từng hàng (Size)
        selectedSizes.forEach(s => {
            html += '<tr>';
            html += `<th>
                <div style="font-weight: 700; color: #1f2937;">${s}</div>
                <button type="button" class="btn-matrix-toggle" data-row="${s}" title="Chọn / Bỏ chọn toàn bộ hàng ${s}">
                    <i class="bi bi-arrows-collapse"></i> Hàng
                </button>
            </th>`;
            selectedColors.forEach(c => {
                const key = s.toUpperCase() + '___' + c.toUpperCase();
                const isChecked = !!matrixState[key];
                html += `<td>
                    <label class="variant-cell-label">
                        <input type="checkbox" name="selectedVariants" value="${s}___${c}" ${isChecked ? 'checked' : ''} data-size="${s}" data-color="${c}">
                    </label>
                </td>`;
            });
            html += '</tr>';
        });
        html += '</tbody>';
        matrixTable.innerHTML = html;

        updateMatrixCounts();
    }

    function toggleRow(s) {
        const selectedColors = Array.from(document.querySelectorAll('input[name="colors"]:checked')).map(cb => cb.value.trim());
        if (selectedColors.length === 0) return;
        const allChecked = selectedColors.every(c => matrixState[s.toUpperCase() + '___' + c.toUpperCase()]);
        const targetState = !allChecked;
        selectedColors.forEach(c => {
            matrixState[s.toUpperCase() + '___' + c.toUpperCase()] = targetState;
        });
        renderMatrix();
        updateSubmitState();
        triggerDebouncedSave();
    }

    function toggleCol(c) {
        const selectedSizes = Array.from(document.querySelectorAll('input[name="sizes"]:checked')).map(cb => cb.value.trim());
        if (selectedSizes.length === 0) return;
        const allChecked = selectedSizes.every(s => matrixState[s.toUpperCase() + '___' + c.toUpperCase()]);
        const targetState = !allChecked;
        selectedSizes.forEach(s => {
            matrixState[s.toUpperCase() + '___' + c.toUpperCase()] = targetState;
        });
        renderMatrix();
        updateSubmitState();
        triggerDebouncedSave();
    }

    function updateImagePreview() {
        if (getImageSourceMode() === 'file') {
            const file = imageFileInput && imageFileInput.files ? imageFileInput.files[0] : null;
            if (file && validateImageFile(false)) {
                const objectUrl = URL.createObjectURL(file);
                imagePreview.innerHTML = '<img src="' + objectUrl + '" alt="Ảnh sản phẩm xem trước">';
            } else {
                imagePreview.innerHTML = '<i class="bi bi-image"></i><span>Chưa có ảnh được chọn</span>';
            }
            return;
        }
        const url = imageUrlInput.value.trim();
        if (!url) {
            imagePreview.innerHTML = '<i class="bi bi-image"></i><span>Chưa có ảnh được chọn</span>';
            return;
        }
        imagePreview.innerHTML = '<img src="' + url + '" alt="Ảnh sản phẩm" onerror="this.onerror=null; this.parentElement.innerHTML=\'<i class=\\\'bi bi-exclamation-triangle text-warning\\\'></i><span class=\\\'text-danger\\\'>Không tải được hình ảnh từ URL</span>\';">';
    }

    // ================= LƯU & KHÔI PHỤC DRAFT (LOCALSTORAGE) =================
    function saveDraft() {
        if (isSubmitting || isEditMode) return;
        try {
            const sizes = Array.from(document.querySelectorAll('input[name="sizes"]:checked')).map(cb => cb.value);
            const colors = Array.from(document.querySelectorAll('input[name="colors"]:checked')).map(cb => cb.value);
            const gender = document.querySelector('input[name="gender"]:checked')?.value || 'FEMALE';

            const data = {
                name: nameInput.value,
                categoryId: categorySelect.value,
                gender: gender,
                description: descriptionInput.value,
                price: priceInput.value,
                salePrice: salePriceInput.value,
                imageSourceMode: getImageSourceMode(),
                imageUrl: imageUrlInput.value,
                sizes: sizes,
                colors: colors,
                matrixState: matrixState,
                savedAt: new Date().toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' }) + ', ' + new Date().toLocaleDateString('vi-VN')
            };

            // Chỉ lưu nếu có dữ liệu người dùng nhập
            const hasData = data.name.trim() || data.categoryId || data.description.trim() || data.price.trim() || data.imageUrl.trim();
            if (hasData) {
                localStorage.setItem(STORAGE_KEY, JSON.stringify(data));
            }
        } catch (e) {
            console.warn('Lỗi khi lưu nháp:', e);
        }
    }

    function triggerDebouncedSave() {
        if (isEditMode) return;
        clearTimeout(autoSaveTimer);
        autoSaveTimer = setTimeout(saveDraft, 400);
    }

    function restoreDraft() {
        if (isEditMode) return false;
        try {
            const raw = localStorage.getItem(STORAGE_KEY);
            if (!raw) return false;
            const data = JSON.parse(raw);
            if (!data) return false;

            if (data.name !== undefined) nameInput.value = data.name;
            if (data.categoryId !== undefined) categorySelect.value = data.categoryId;
            if (data.description !== undefined) descriptionInput.value = data.description;
            if (data.price !== undefined) priceInput.value = data.price;
            if (data.salePrice !== undefined) salePriceInput.value = data.salePrice;
            if (data.imageSourceMode) {
                const modeRadio = document.querySelector('input[name="imageSourceMode"][value="' + data.imageSourceMode + '"]');
                if (modeRadio) modeRadio.checked = true;
            }
            if (data.imageUrl !== undefined) imageUrlInput.value = data.imageUrl;

            if (data.gender) {
                const gRadio = document.querySelector('input[name="gender"][value="' + data.gender + '"]');
                if (gRadio) gRadio.checked = true;
            }

            if (Array.isArray(data.sizes)) {
                document.querySelectorAll('input[name="sizes"]').forEach(cb => {
                    cb.checked = data.sizes.includes(cb.value);
                });
            }

            if (Array.isArray(data.colors)) {
                document.querySelectorAll('input[name="colors"]').forEach(cb => {
                    cb.checked = data.colors.includes(cb.value);
                });
            }

            if (data.matrixState && typeof data.matrixState === 'object') {
                Object.assign(matrixState, data.matrixState);
            }

            updateImagePreview();
            renderMatrix();

            if (draftAlert) {
                if (data.savedAt && draftTime) {
                    draftTime.textContent = 'Đã lưu tự động lúc ' + data.savedAt;
                }
                draftAlert.style.display = 'flex';
            }

            return true;
        } catch (e) {
            console.warn('Lỗi khi khôi phục nháp:', e);
            return false;
        }
    }

    function clearDraft() {
        if (isEditMode) return;
        try {
            localStorage.removeItem(STORAGE_KEY);
        } catch (e) {}
        if (draftAlert) {
            draftAlert.style.display = 'none';
        }
    }

    // ================= GẮN SỰ KIỆN KIỂM TRA TỪNG Ô INPUT =================
    // 1. Tên sản phẩm: Tự bắt lỗi khi blur, re-validate khi input nếu đã touched
    nameInput.addEventListener('blur', function () {
        touched.name = true;
        validateName(true);
        updateSubmitState();
    });
    nameInput.addEventListener('input', function () {
        if (touched.name) validateName(true);
        updateSubmitState();
        triggerDebouncedSave();
    });

    // 2. Danh mục
    categorySelect.addEventListener('change', function () {
        touched.categoryId = true;
        validateCategory(true);
        updateSubmitState();
        triggerDebouncedSave();
    });
    categorySelect.addEventListener('blur', function () {
        touched.categoryId = true;
        validateCategory(true);
        updateSubmitState();
    });

    // 3. Giới tính
    document.querySelectorAll('input[name="gender"]').forEach(radio => {
        radio.addEventListener('change', triggerDebouncedSave);
    });

    // 4. Mô tả chi tiết: Tự bắt lỗi khi blur, re-validate khi input nếu đã touched
    descriptionInput.addEventListener('blur', function () {
        touched.description = true;
        validateDescription(true);
        updateSubmitState();
    });
    descriptionInput.addEventListener('input', function () {
        if (touched.description) validateDescription(true);
        updateSubmitState();
        triggerDebouncedSave();
    });

    // 5. Giá gốc: Tự bắt lỗi khi blur, re-validate khi input nếu đã touched
    priceInput.addEventListener('blur', function () {
        touched.price = true;
        validatePrice(true);
        updateSubmitState();
    });
    priceInput.addEventListener('input', function () {
        if (touched.price) validatePrice(true);
        updateSubmitState();
        triggerDebouncedSave();
    });

    // 6. Giá khuyến mãi
    salePriceInput.addEventListener('blur', function () {
        touched.salePrice = true;
        validateSalePrice(true);
        updateSubmitState();
    });
    salePriceInput.addEventListener('input', function () {
        if (touched.salePrice) validateSalePrice(true);
        updateSubmitState();
        triggerDebouncedSave();
    });

    // 7. Ảnh sản phẩm: Chọn 1 trong 2 (gửi file từ máy tính hoặc gửi URL)
    imageSourceRadios.forEach(radio => {
        radio.addEventListener('change', function () {
            syncImageSourceMode();
            if (touched.imageUrl) validateImageUrl(true);
            updateImagePreview();
            updateSubmitState();
            triggerDebouncedSave();
        });
    });
    if (imageFileInput) {
        imageFileInput.addEventListener('change', function () {
            touched.imageUrl = true;
            validateImageUrl(true);
            updateImagePreview();
            updateSubmitState();
        });
    }
    imageUrlInput.addEventListener('blur', function () {
        touched.imageUrl = true;
        validateImageUrl(true);
        updateImagePreview();
        updateSubmitState();
    });
    imageUrlInput.addEventListener('input', function () {
        updateImagePreview();
        if (touched.imageUrl) validateImageUrl(true);
        updateSubmitState();
        triggerDebouncedSave();
    });

    // 8. Size & Màu sắc
    const variantCheckboxes = document.querySelectorAll('input[name="sizes"], input[name="colors"]');
    variantCheckboxes.forEach(cb => {
        cb.addEventListener('change', function () {
            if (this.name === 'sizes') {
                touched.sizes = true;
                validateSizes(true);
            } else if (this.name === 'colors') {
                touched.colors = true;
                validateColors(true);
            }
            renderMatrix();
            validateMatrix(true);
            updateSubmitState();
            triggerDebouncedSave();
        });
    });

    // Hỗ trợ click trực tiếp trên label biến thể
    document.querySelectorAll('.choice-list label').forEach(label => {
        label.addEventListener('click', function () {
            setTimeout(function () {
                renderMatrix();
                validateMatrix(true);
                updateSubmitState();
                triggerDebouncedSave();
            }, 10);
        });
    });

    // Bắt sự kiện trên Bảng ma trận biến thể (chọn/bỏ chọn ô, toggle hàng, toggle cột)
    if (matrixTable) {
        matrixTable.addEventListener('change', function (e) {
            if (e.target.matches('input[name="selectedVariants"]')) {
                const s = e.target.getAttribute('data-size');
                const c = e.target.getAttribute('data-color');
                if (s && c) {
                    const key = s.toUpperCase() + '___' + c.toUpperCase();
                    matrixState[key] = e.target.checked;
                    updateMatrixCounts();
                    validateMatrix(true);
                    updateSubmitState();
                    triggerDebouncedSave();
                }
            }
        });

        matrixTable.addEventListener('click', function (e) {
            const rowBtn = e.target.closest('[data-row]');
            if (rowBtn) {
                e.preventDefault();
                toggleRow(rowBtn.getAttribute('data-row'));
                return;
            }
            const colBtn = e.target.closest('[data-col]');
            if (colBtn) {
                e.preventDefault();
                toggleCol(colBtn.getAttribute('data-col'));
                return;
            }
        });
    }

    // Bật / Tắt toàn bộ ma trận biến thể
    if (btnToggleAllMatrix) {
        btnToggleAllMatrix.addEventListener('click', function (e) {
            e.preventDefault();
            const selectedSizes = Array.from(document.querySelectorAll('input[name="sizes"]:checked')).map(cb => cb.value.trim());
            const selectedColors = Array.from(document.querySelectorAll('input[name="colors"]:checked')).map(cb => cb.value.trim());
            if (selectedSizes.length === 0 || selectedColors.length === 0) return;

            let allChecked = true;
            for (const s of selectedSizes) {
                for (const c of selectedColors) {
                    if (!matrixState[s.toUpperCase() + '___' + c.toUpperCase()]) {
                        allChecked = false;
                        break;
                    }
                }
                if (!allChecked) break;
            }

            const targetState = !allChecked;
            selectedSizes.forEach(s => {
                selectedColors.forEach(c => {
                    matrixState[s.toUpperCase() + '___' + c.toUpperCase()] = targetState;
                });
            });
            renderMatrix();
            validateMatrix(true);
            updateSubmitState();
            triggerDebouncedSave();
        });
    }

    // Nút Xóa bản nháp
    if (clearDraftBtn) {
        clearDraftBtn.addEventListener('click', function () {
            if (confirm('Bạn có chắc muốn xóa bản nháp này và nhập lại từ đầu?')) {
                clearDraft();
                form.reset();
                // Khôi phục mặc định M và Đen
                document.querySelectorAll('input[name="sizes"]').forEach(cb => cb.checked = (cb.value === 'M'));
                document.querySelectorAll('input[name="colors"]').forEach(cb => cb.checked = (cb.value === 'Đen'));
                // Reset trạng thái ma trận
                Object.keys(matrixState).forEach(k => delete matrixState[k]);
                // Reset touched và lỗi
                Object.keys(touched).forEach(k => touched[k] = false);
                document.querySelectorAll('.field-error').forEach(el => el.textContent = '');
                document.querySelectorAll('.input-error').forEach(el => el.classList.remove('input-error'));
                syncImageSourceMode();
                updateImagePreview();
                renderMatrix();
                updateSubmitState();
            }
        });
    }

    // Nút Hủy thay đổi
    if (cancelBtn) {
        cancelBtn.addEventListener('click', function (e) {
            if (isEditMode) return;
            const hasDraft = localStorage.getItem(STORAGE_KEY);
            if (hasDraft) {
                if (confirm('Bạn có chắc muốn hủy thay đổi? Bản nháp sản phẩm đang tạo sẽ bị xóa.')) {
                    clearDraft();
                } else {
                    e.preventDefault();
                }
            }
        });
    }

    // Lưu nháp trước khi rời trang nếu lỡ bấm link điều hướng (chỉ khi không phải đang submit)
    window.addEventListener('beforeunload', function () {
        if (!isSubmitting && !isEditMode) {
            saveDraft();
        }
    });
    window.addEventListener('pagehide', function () {
        if (!isSubmitting && !isEditMode) {
            saveDraft();
        }
    });

    // Xử lý submit form
    form.addEventListener('submit', function (e) {
        touchAll();
        if (!isFormValid()) {
            e.preventDefault();
            // Focus vào ô lỗi đầu tiên
            const firstErrorInput = form.querySelector('.input-error, input[name="sizes"]:not(:checked), #variantMatrixTable');
            if (firstErrorInput) {
                firstErrorInput.focus();
            }
            return;
        }

        // Ràng buộc: nếu không nhập giá khuyến mãi, giá khuyến mãi mặc định = giá gốc
        if (!salePriceInput.value.trim() && priceInput.value.trim()) {
            salePriceInput.value = priceInput.value.trim();
        }

        // Đánh dấu isSubmitting để không lưu lại nháp khi trang unload và xóa hoàn toàn bản nháp
        isSubmitting = true;
        if (!isEditMode) {
            clearDraft();
        }
    });

    // ================= KHỞI TẠO BAN ĐẦU KHI TẢI TRANG =================
    if (!isEditMode) {
        restoreDraft();
    }
    syncImageSourceMode();
    renderMatrix();
    updateImagePreview();
    updateSubmitState();
})();
