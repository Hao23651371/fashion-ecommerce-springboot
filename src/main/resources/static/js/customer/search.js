(function () {
    function initSearch() {
        const input = document.getElementById('siteSearchInput');
        const box = document.getElementById('siteSearchDropdown');
        if (!input || !box) return;

        let timer = null, controller = null;

        const searchUrl = (input.dataset && input.dataset.searchUrl) ? input.dataset.searchUrl : '/api/products/search';
        const detailBaseUrl = (input.dataset && input.dataset.detailUrl) ? input.dataset.detailUrl : '/shop/';
        const base = detailBaseUrl.endsWith('/') ? detailBaseUrl : (detailBaseUrl + '/');

        const money = n => Number(n).toLocaleString('vi-VN') + ' ₫';

        function hide() { box.hidden = true; box.replaceChildren(); }

        function render(items) {
            if (!items.length) { hide(); return; }          // không có kết quả -> không hiện gì
            box.replaceChildren(...items.map(p => {
                const a = document.createElement('a');
                a.className = 'search-item';
                a.href = base + p.id;

                const img = document.createElement('img');
                img.alt = '';
                img.src = p.imageUrl || '';
                img.onerror = () => { img.style.visibility = 'hidden'; };

                const info = document.createElement('div');
                const cat = document.createElement('small');
                cat.textContent = p.categoryName;
                const name = document.createElement('div');
                name.className = 'search-name';
                name.textContent = p.name;
                const price = document.createElement('div');
                price.className = 'search-price';
                price.textContent = money(p.onSale ? p.salePrice : p.price);
                info.append(cat, name, price);

                a.append(img, info);
                return a;
            }));
            box.hidden = false;
        }

        input.addEventListener('input', () => {
            clearTimeout(timer);
            const q = input.value.trim();
            if (!q) { hide(); return; }
            timer = setTimeout(async () => {
                if (controller) controller.abort();          // bỏ yêu cầu cũ nếu gõ tiếp
                controller = new AbortController();
                try {
                    const sep = searchUrl.includes('?') ? '&' : '?';
                    const res = await fetch(searchUrl + sep + 'q=' + encodeURIComponent(q),
                        { signal: controller.signal });
                    if (!res.ok) { hide(); return; }
                    render(await res.json());
                } catch (e) { if (e.name !== 'AbortError') hide(); }
            }, 250);
        });

        document.addEventListener('click', e => {
            if (!e.target.closest('.site-search-wrap')) hide();
        });
        input.addEventListener('keydown', e => { if (e.key === 'Escape') hide(); });
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', initSearch);
    } else {
        initSearch();
    }
})();
