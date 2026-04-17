const API_URL = '/api/v1';

// --- Utility Functions ---
const getHeaders = () => ({
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${localStorage.getItem('admin_token')}`
});

const handleResponse = async (response) => {
    if (response.status === 401) {
        localStorage.removeItem('admin_token');
        window.location.href = '/admin/index.html';
        return;
    }
    const data = await response.json();
    if (!data.success) throw new Error(data.message || 'Request failed');
    return data.data;
};

const formatCurrency = (amount) => {
    return new Intl.NumberFormat('id-ID', {
        style: 'currency',
        currency: 'IDR',
        minimumFractionDigits: 0
    }).format(amount);
};

// --- Auth ---
const loginForm = document.getElementById('loginForm');
if (loginForm) {
    loginForm.addEventListener('submit', async (e) => {
        e.preventDefault();
        const username = document.getElementById('username').value;
        const password = document.getElementById('password').value;
        const errorMsg = document.getElementById('errorMessage');
        const loginBtn = document.getElementById('loginBtn');

        loginBtn.disabled = true;
        loginBtn.innerText = 'Logging in...';

        try {
            const response = await fetch(`${API_URL}/admin/login`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ username, password })
            });
            const data = await response.json();
            
            if (data.success) {
                localStorage.setItem('admin_token', data.data.token);
                localStorage.setItem('admin_user', data.data.username);
                window.location.href = '/admin/dashboard.html';
            } else {
                errorMsg.innerText = data.message;
                errorMsg.style.display = 'block';
            }
        } catch (err) {
            errorMsg.innerText = 'Connection error. Check backend.';
            errorMsg.style.display = 'block';
        } finally {
            loginBtn.disabled = false;
            loginBtn.innerText = 'Login';
        }
    });
}

// --- Dashboard & Sections ---
const currentPath = window.location.pathname;
const isLoginPage = currentPath === '/admin' || currentPath === '/admin/' || currentPath.includes('index.html');
const isAdminPath = currentPath.startsWith('/admin');

if (isAdminPath && !isLoginPage) {
    const adminUser = localStorage.getItem('admin_user');
    if (document.getElementById('adminName')) {
        document.getElementById('adminName').innerText = adminUser || 'Admin';
    }

    // Logout
    document.getElementById('logoutBtn')?.addEventListener('click', () => {
        localStorage.removeItem('admin_token');
        window.location.href = '/admin/index.html';
    });

    // Navigation Logic
    function switchSection(targetId, updateHistory = true) {
        const navLinks = document.querySelectorAll('.nav-link');
        const sections = document.querySelectorAll('.cms-section');
        const activeLink = document.querySelector(`.nav-link[data-target="${targetId}"]`);

        if (!activeLink) {
            // Fallback to overview if section not found
            if (targetId !== 'overview') switchSection('overview', updateHistory);
            return;
        }

        // UI Update
        navLinks.forEach(l => l.classList.remove('active'));
        activeLink.classList.add('active');

        sections.forEach(s => s.style.display = 'none');
        const targetSection = document.getElementById(targetId);
        if (targetSection) targetSection.style.display = 'block';

        // Title sync
        const sectionTitle = document.getElementById('sectionTitle');
        if (sectionTitle) sectionTitle.innerText = activeLink.innerText.trim();

        // State & History Management
        if (updateHistory) {
            localStorage.setItem('active_admin_section', targetId);
            // Sync Hash (e.g., #stores)
            const currentHash = window.location.hash;
            const baseUrl = currentHash.includes('?') ? currentHash.split('?')[0] : currentHash;
            if (baseUrl !== `#${targetId}`) {
                window.location.hash = targetId;
            }
        }

        // Data Load
        loadSectionData(targetId);
    }

    // Event Listeners for Nav
    document.querySelectorAll('.nav-link').forEach(link => {
        link.addEventListener('click', (e) => {
            e.preventDefault();
            const targetId = link.getAttribute('data-target');
            switchSection(targetId);
        });
    });

    // Listen for back/forward (SPA)
    window.addEventListener('popstate', (e) => {
        const targetId = (e.state && e.state.section) 
            ? e.state.section 
            : window.location.pathname.split('/').pop();
        switchSection(targetId || 'overview', false);
    });

    // Initial Load
    async function initDashboard() {
        try {
            const stats = await handleResponse(await fetch(`${API_URL}/admin/stats`, { headers: getHeaders() }));
            document.getElementById('bannerCount').innerText = stats.banners;
            document.getElementById('categoryCount').innerText = stats.categories;
            document.getElementById('productCount').innerText = stats.products;
            document.getElementById('storeCount').innerText = stats.stores || 0;
            document.getElementById('driverCount').innerText = stats.drivers || 0;
            
            // Initialize Form Listeners
            initFormListeners();

            // --- State Restoration Logic ---
            let sectionToLoad = 'overview';
            const hash = window.location.hash.substring(1).split('?')[0];
            const savedSection = localStorage.getItem('active_admin_section');

            if (hash) {
                sectionToLoad = hash;
            } else if (savedSection) {
                sectionToLoad = savedSection;
            }

            // Restore section
            switchSection(sectionToLoad, false);

            // Restore category filter if in categories section
            if (sectionToLoad === 'categories') {
                const params = new URLSearchParams(window.location.hash.includes('?') ? window.location.hash.split('?')[1] : '');
                const hashType = params.get('type');
                const savedType = localStorage.getItem('active_category_tab');
                const typeToApply = hashType || savedType || '';
                
                // Allow some time for DOM to stabilize if needed, but normally direct call is fine
                filterCategories(typeToApply, false);
            }

            // Global Hash Listener for deep linking
            window.addEventListener('hashchange', () => {
                const newHash = window.location.hash.substring(1).split('?')[0];
                if (newHash) switchSection(newHash, false);
            });

        } catch (err) {
            console.error('Failed to load dashboard:', err);
        }
    }

    async function loadSectionData(sectionId) {
        if (sectionId === 'banners') await loadBanners();
        if (sectionId === 'categories') await loadCategories();
        if (sectionId === 'products') await loadProducts();
        if (sectionId === 'stores') await loadStores();
        if (sectionId === 'drivers') await loadDrivers();
        if (sectionId === 'sections') await loadHomeSections();
        if (sectionId === 'vouchers') await loadVouchers();
    }

    // --- Banners Manager ---
    async function loadBanners() {
        const data = await handleResponse(await fetch(`${API_URL}/admin/banners`, { headers: getHeaders() }));
        window.allBanners = data;
        const list = document.getElementById('bannerList');
        
        const getPositionBadges = (posString) => {
            const positions = posString.split(',').filter(p => p.trim() !== '');
            return positions.map(p => {
                const isMain = ['home', 'food', 'umkm'].includes(p);
                return `<span class="badge ${isMain ? 'badge-blue' : 'badge-green'}" style="margin-right: 2px;">${p.toUpperCase()}</span>`;
            }).join('');
        };

        if (list) {
            list.innerHTML = data.map(b => `
                <tr>
                    <td><img src="${b.image_url}" class="preview-img" style="width: 60px"></td>
                    <td>${getPositionBadges(b.position)}</td>
                    <td>${b.sort_order}</td>
                    <td>
                        <button class="action-btn edit-btn" onclick="openBannerModalById(${b.id})">Edit</button>
                        <button class="action-btn delete-btn" onclick="deleteItem('banners', ${b.id})">Del</button>
                    </td>
                </tr>
            `).join('');
        }
    }

    // --- Categories Manager ---
    window.filterCategories = async (serviceType, updateHistory = true) => {
        // Update Tab Active State
        document.querySelectorAll('.tab-btn').forEach(btn => btn.classList.remove('active'));
        const activeTab = Array.from(document.querySelectorAll('.tab-btn')).find(btn => 
            (serviceType === '' && btn.innerText === 'Semua') || 
            (serviceType && btn.getAttribute('onclick').includes(`'${serviceType}'`))
        );
        
        if (activeTab) {
            activeTab.classList.add('active');
            // Auto-scroll tab into view
            activeTab.scrollIntoView({ behavior: 'smooth', block: 'nearest', inline: 'center' });
        }

        // Persistence
        if (updateHistory) {
            localStorage.setItem('active_category_tab', serviceType);
            // Update Hash with param (e.g., #categories?type=food)
            const baseUrl = window.location.hash.split('?')[0] || '#categories';
            if (serviceType) {
                window.location.hash = `${baseUrl}?type=${serviceType}`;
            } else {
                window.location.hash = baseUrl;
            }
        }

        const url = serviceType ? `${API_URL}/admin/categories?service_type=${serviceType}` : `${API_URL}/admin/categories`;
        const data = handleResponse(await fetch(url, { headers: getHeaders() }));
        renderCategories(await data);
    };

    async function loadCategories() {
        const data = await handleResponse(await fetch(`${API_URL}/admin/categories`, { headers: getHeaders() }));
        window.allCategories = data;
        renderCategories(data);
    }

    function renderCategories(data) {
        const list = document.getElementById('categoryList');
        if (!list) return;
        list.innerHTML = data.map(c => {
            const safeType = c.type || 'BARANG';
            return `
                <tr>
                    <td><i class="material-icons">${c.icon_name}</i></td>
                    <td>${c.name}</td>
                    <td><span class="badge badge-blue">${c.service_type || 'mart'}</span></td>
                    <td>${c.slug}</td>
                    <td><span class="badge badge-${safeType.toLowerCase()}">${safeType}</span></td>
                    <td>${c.sort_order}</td>
                    <td>
                        <button class="action-btn edit-btn" onclick="openCategoryModalById(${c.id})">Edit</button>
                        <button class="action-btn delete-btn" onclick="deleteItem('categories', ${c.id})">Del</button>
                    </td>
                </tr>
            `;
        }).join('');
    }

    // --- Products Manager ---
    async function loadProducts() {
        const data = await handleResponse(await fetch(`${API_URL}/admin/products`, { headers: getHeaders() }));
        window.allProducts = data;
        const list = document.getElementById('productList');
        list.innerHTML = data.map(p => `
            <tr>
                <td><img src="${p.image_url}" class="preview-img" style="width: 40px"></td>
                <td>${p.name}</td>
                <td>${p.category?.name || 'N/A'}</td>
                <td>${formatCurrency(p.price)}</td>
                <td>
                    <button class="action-btn edit-btn" onclick="openProductModalById(${p.id})">Edit</button>
                    <button class="action-btn delete-btn" onclick="deleteItem('products', ${p.id})">Del</button>
                </td>
            </tr>
        `).join('');
    }

    // --- Stores Manager ---
    async function loadStores() {
        const data = await handleResponse(await fetch(`${API_URL}/admin/stores`, { headers: getHeaders() }));
        window.allStores = data;
        const list = document.getElementById('storeList');
        if (!list) return;

        const getModuleBadge = (mod) => {
            const colors = {
                'food': '#4CAF50', 'kost': '#2196F3', 'rental': '#FF9800', 
                'transport': '#3F51B5', 'jasa': '#009688', 'umkm': '#9C27B0', 
                'bumi': '#795548', 'wisata': '#00BCD4', 'second': '#E91E63'
            };
            const label = mod.name || mod.code;
            const color = colors[mod.code] || '#607D8B';
            return `<span class="badge" style="background: ${color}; color: white; margin: 2px; font-size: 0.7rem;">${label}</span>`;
        };

        list.innerHTML = data.map(s => `
            <tr>
                <td><strong>${s.name}</strong></td>
                <td>${s.user ? s.user.first_name + ' ' + s.user.last_name : 'N/A'}</td>
                <td style="max-width: 250px;">
                    ${(s.business_modules || []).map(m => getModuleBadge(m)).join('') || '<span style="color: grey; font-style: italic;">No Modules</span>'}
                </td>
                <td><span class="badge ${s.status === 'approved' ? 'badge-blue' : (s.status === 'rejected' ? 'badge-rental' : 'badge-green')}">
                    ${s.status.toUpperCase()} ${s.is_verified ? '✓' : ''}
                </span></td>
                <td>
                    <button class="action-btn edit-btn" onclick="openStoreModalById(${s.id})">View/Edit</button>
                </td>
            </tr>
        `).join('');
    }

    // --- Drivers Manager ---
    async function loadDrivers() {
        const data = await handleResponse(await fetch(`${API_URL}/admin/drivers`, { headers: getHeaders() }));
        window.allDrivers = data;
        const list = document.getElementById('driverList');
        if (!list) return;
        list.innerHTML = data.map(d => {
            let statusColor = '#FFA500'; // pending
            if (d.status === 'approved') statusColor = '#4CAF50';
            if (d.status === 'rejected') statusColor = '#f44336';

            return `
                <tr>
                    <td><strong>${d.user ? d.user.first_name + ' ' + d.user.last_name : 'Unknown'}</strong></td>
                    <td>${d.plate_number}</td>
                    <td>${d.vehicle_type}</td>
                    <td>${d.phone_number || '-'}</td>
                    <td>Rp ${d.balance.toLocaleString()}</td>
                    <td><span style="color: ${statusColor}; font-weight: bold">${d.status.toUpperCase()}</span></td>
                    <td>
                        ${d.status === 'pending' ? `
                            <button class="action-btn edit-btn" onclick="updateMitraStatus('drivers', ${d.id}, 'approved')">Approve</button>
                            <button class="action-btn delete-btn" onclick="updateMitraStatus('drivers', ${d.id}, 'rejected')">Reject</button>
                        ` : '-'}
                    </td>
                </tr>
            `;
        }).join('');
    }

    // --- Home Sections (On/Off) ---
    async function loadHomeSections() {
        const data = await handleResponse(await fetch(`${API_URL}/admin/sections`, { headers: getHeaders() }));
        window.allSections = data;
        const list = document.getElementById('homeSectionList');
        list.innerHTML = data.map(s => `
            <tr>
                <td>${s.title}</td>
                <td>${s.key}</td>
                <td>${s.sort_order}</td>
                <td>
                    <input type="checkbox" ${s.is_active ? 'checked' : ''} onchange="toggleSection(${s.id}, this.checked)">
                </td>
                <td>
                    <button class="action-btn edit-btn" onclick="openSectionModalById(${s.id})">Edit</button>
                </td>
            </tr>
        `).join('');
    }

    async function loadVouchers() {
        const data = await handleResponse(await fetch(`${API_URL}/admin/vouchers`, { headers: getHeaders() }));
        window.allVouchers = data;
        const list = document.getElementById('voucherList');
        if (!list) return;
        list.innerHTML = data.map(v => `
            <tr>
                <td><strong>${v.code}</strong></td>
                <td><span class="badge ${v.type === 'PERCENT' ? 'badge-blue' : 'badge-green'}">${v.type}</span></td>
                <td>${v.type === 'PERCENT' ? v.value + '%' : 'Rp ' + v.value.toLocaleString()} ${v.max_discount > 0 ? '(Max Rp ' + v.max_discount.toLocaleString() + ')' : ''}</td>
                <td>Rp ${v.min_order.toLocaleString()}</td>
                <td><span style="color: ${v.is_active ? '#4CAF50' : '#f44336'}; font-weight: bold">${v.is_active ? 'ACTIVE' : 'INACTIVE'}</span></td>
                <td>
                    <button class="action-btn edit-btn" onclick="openVoucherModalById(${v.id})">Edit</button>
                    <button class="action-btn delete-btn" onclick="deleteItem('vouchers', ${v.id})">Del</button>
                </td>
            </tr>
        `).join('');
    }

    // --- Modal Helpers ---
    window.openBannerModalById = (id) => {
        const data = (window.allBanners || []).find(b => b.id == id);
        openBannerModal(data);
    };
    window.openCategoryModalById = (id) => {
        const data = (window.allCategories || []).find(c => c.id == id);
        openCategoryModal(data);
    };
    window.openProductModalById = (id) => {
        const data = (window.allProducts || []).find(p => p.id == id);
        openProductModal(data);
    };
    window.openStoreModalById = (id) => {
        const data = (window.allStores || []).find(s => s.id == id);
        openStoreModal(data);
    };
    window.openDriverModalById = (id) => {
        const data = (window.allDrivers || []).find(d => d.id == id);
        openDriverModal(data);
    };
    window.openSectionModalById = (id) => {
        const data = (window.allSections || []).find(s => s.id == id);
        openSectionModal(data);
    };
    window.openVoucherModalById = (id) => {
        const data = (window.allVouchers || []).find(v => v.id == id);
        openVoucherModal(data);
    };

    window.openBannerModal = (data = null) => {
        const modal = document.getElementById('bannerModal');
        document.getElementById('bannerForm').reset();
        document.getElementById('b_preview').src = '';
        
        // Reset checkboxes
        document.querySelectorAll('input[name="b_pos"]').forEach(cb => cb.checked = false);

        if (data) {
            document.getElementById('bannerId').value = data.id;
            document.getElementById('b_title').value = data.title || 'Banner Promo';
            document.getElementById('b_image_url').value = data.image_url;
            document.getElementById('b_preview').src = data.image_url;
            document.getElementById('b_order').value = data.sort_order;

            // Check appropriate boxes
            if (data.position) {
                const activePos = data.position.split(',');
                document.querySelectorAll('input[name="b_pos"]').forEach(cb => {
                    if (activePos.includes(cb.value)) cb.checked = true;
                });
            }
        } else { 
            document.getElementById('bannerId').value = ''; 
            document.getElementById('b_title').value = 'Banner Promo';
        }
        modal.style.display = 'flex';
    };

    window.openCategoryModal = (data = null) => {
        const modal = document.getElementById('categoryModal');
        document.getElementById('categoryForm').reset();
        if (data) {
            document.getElementById('categoryId').value = data.id;
            document.getElementById('c_name').value = data.name;
            document.getElementById('c_slug').value = data.slug;
            document.getElementById('c_icon_name').value = data.icon_name;
            document.getElementById('c_service_type').value = data.service_type || 'mart';
            document.getElementById('c_type').value = data.type || 'BARANG';
            document.getElementById('c_order').value = data.sort_order;
        } else { 
            document.getElementById('categoryId').value = ''; 
            document.getElementById('c_service_type').value = '';
        }
        modal.style.display = 'flex';
    };

    window.openProductModal = async (data = null) => {
        const modal = document.getElementById('productModal');
        document.getElementById('productForm').reset();
        document.getElementById('p_preview').src = '';
        
        const catSelect = document.getElementById('p_cat_id');
        catSelect.innerHTML = '<option value="">Pilih Modul Dulu...</option>';
        catSelect.disabled = true;

        if (data) {
            document.getElementById('productId').value = data.id;
            document.getElementById('p_name').value = data.name;
            document.getElementById('p_price').value = data.price;
            document.getElementById('p_image_url').value = data.image_url;
            document.getElementById('p_preview').src = data.image_url;
            document.getElementById('p_desc').value = data.description;
            
            // Set Service Type first
            const serviceType = data.service_type || 'mart';
            document.getElementById('p_service_type').value = serviceType;
            
            // Load and set categories for this service type
            await handleModuleChange(data.category_id);
        } else { 
            document.getElementById('productId').value = ''; 
        }
        modal.style.display = 'flex';
    };

    window.openStoreModal = async (data = null) => {
        const modal = document.getElementById('storeModal');
        const form = document.getElementById('storeForm');
        form.reset();
        
        const container = document.getElementById('moduleCheckboxContainer');
        container.innerHTML = 'Loading modules...';

        if (!data) return; // Store create not supported via admin for now

        // 1. Populate basic info
        document.getElementById('storeId').value = data.id;
        document.getElementById('s_store_name').value = data.name;
        document.getElementById('s_owner_name').value = data.user ? `${data.user.first_name} ${data.user.last_name}` : 'Unknown';
        document.getElementById('s_status').value = data.status || 'pending';
        document.getElementById('s_level').value = data.level || 'regular';
        document.getElementById('s_is_verified').checked = data.is_verified;

        // 2. Fetch all possible modules for checkboxes
        try {
            const constants = await handleResponse(await fetch(`${API_URL}/store/constants`));
            const availableModules = constants.modules || [];
            const currentModuleCodes = (data.business_modules || []).map(m => m.code);

            container.innerHTML = availableModules.map(m => `
                <div style="display: flex; align-items: center; gap: 0.5rem; padding: 0.3rem;">
                    <input type="checkbox" name="module_ids" value="${m.id}" id="mod_${m.code}" ${currentModuleCodes.includes(m.code) ? 'checked' : ''} style="width: auto;">
                    <label for="mod_${m.code}" style="margin: 0; cursor: pointer; font-size: 0.85rem;">${m.name}</label>
                </div>
            `).join('');

        } catch (err) {
            container.innerHTML = '<span style="color: red;">Gagal memuat daftar modul</span>';
        }

        modal.style.display = 'flex';
    };

    window.handleModuleChange = async (selectedCategoryId = null) => {
        const serviceType = document.getElementById('p_service_type').value;
        const catSelect = document.getElementById('p_cat_id');
        const loader = document.getElementById('catLoading');

        if (!serviceType) {
            catSelect.innerHTML = '<option value="">Pilih Modul Dulu...</option>';
            catSelect.disabled = true;
            return;
        }

        // Show loading state
        catSelect.disabled = true;
        catSelect.innerHTML = '<option value="">Loading categories...</option>';
        if (loader) loader.style.display = 'block';

        try {
            const url = `${API_URL}/admin/categories?service_type=${serviceType}`;
            const categories = await handleResponse(await fetch(url, { headers: getHeaders() }));
            
            catSelect.innerHTML = categories.length > 0 
                ? categories.map(c => `<option value="${c.id}" ${selectedCategoryId == c.id ? 'selected' : ''}>${c.name}</option>`).join('')
                : '<option value="">Tidak ada kategori untuk modul ini</option>';
            
            catSelect.disabled = categories.length === 0;
        } catch (err) {
            catSelect.innerHTML = '<option value="">Gagal memuat data</option>';
        } finally {
            if (loader) loader.style.display = 'none';
        }
    };

    window.openVoucherModal = (data = null) => {
        const modal = document.getElementById('voucherModal');
        document.getElementById('voucherForm').reset();
        if (data) {
            document.getElementById('voucherId').value = data.id;
            document.getElementById('v_code').value = data.code;
            document.getElementById('v_type').value = data.type;
            document.getElementById('v_value').value = data.value;
            document.getElementById('v_min_order').value = data.min_order;
            document.getElementById('v_max_discount').value = data.max_discount;
        } else { document.getElementById('voucherId').value = ''; }
        modal.style.display = 'flex';
    };

    window.openSectionModal = (data = null) => {
        const modal = document.getElementById('sectionModal');
        document.getElementById('sectionForm').reset();
        if (data) {
            document.getElementById('sectionId').value = data.id;
            document.getElementById('s_title').value = data.title;
            document.getElementById('s_key').value = data.key;
            document.getElementById('s_order').value = data.sort_order;
        } else { document.getElementById('sectionId').value = ''; }
        modal.style.display = 'flex';
    };

    window.closeModals = () => {
        document.querySelectorAll('.modal').forEach(m => m.style.display = 'none');
    };

    // --- Forms Submission ---
    window.initFormListeners = () => {
        const bannerForm = document.getElementById('bannerForm');
        if (bannerForm) bannerForm.onsubmit = (e) => {
            const selectedPos = Array.from(document.querySelectorAll('input[name="b_pos"]:checked'))
                .map(cb => cb.value)
                .join(',');
            
            if (!selectedPos) {
                alert('Pilih setidaknya satu target modul!');
                e.preventDefault();
                return;
            }

            submitForm(e, 'bannerId', 'banners', {
                title: document.getElementById('b_title').value,
                image_url: document.getElementById('b_image_url').value,
                position: selectedPos,
                sort_order: parseInt(document.getElementById('b_order').value),
                is_active: true
            });
        };

        const categoryForm = document.getElementById('categoryForm');
        if (categoryForm) categoryForm.onsubmit = (e) => {
            const serviceType = document.getElementById('c_service_type').value;
            if (!serviceType) {
                alert('Pilih Modul / Layanan terlebih dahulu!');
                return;
            }
            submitForm(e, 'categoryId', 'categories', {
                name: document.getElementById('c_name').value,
                slug: document.getElementById('c_slug').value,
                icon_name: document.getElementById('c_icon_name').value,
                service_type: serviceType,
                type: document.getElementById('c_type').value,
                sort_order: parseInt(document.getElementById('c_order').value),
                is_active: true
            });
        };

        const productForm = document.getElementById('productForm');
        if (productForm) productForm.onsubmit = (e) => submitForm(e, 'productId', 'products', {
            name: document.getElementById('p_name').value,
            category_id: parseInt(document.getElementById('p_cat_id').value),
            service_type: document.getElementById('p_service_type').value,
            price: parseFloat(document.getElementById('p_price').value),
            image_url: document.getElementById('p_image_url').value,
            description: document.getElementById('p_desc').value,
            is_active: true
        });

        const voucherForm = document.getElementById('voucherForm');
        if (voucherForm) voucherForm.onsubmit = (e) => submitForm(e, 'voucherId', 'vouchers', {
            code: document.getElementById('v_code').value,
            type: document.getElementById('v_type').value,
            value: parseFloat(document.getElementById('v_value').value),
            min_order: parseFloat(document.getElementById('v_min_order').value),
            max_discount: parseFloat(document.getElementById('v_max_discount').value),
            is_active: true
        });

        const storeForm = document.getElementById('storeForm');
        if (storeForm) storeForm.onsubmit = async (e) => {
            e.preventDefault();
            const id = document.getElementById('storeId').value;
            
            // Get selected modules
            const selectedModuleIds = Array.from(document.querySelectorAll('input[name="module_ids"]:checked'))
                .map(cb => parseInt(cb.value));

            const payload = {
                status: document.getElementById('s_status').value,
                level: document.getElementById('s_level').value,
                is_verified: document.getElementById('s_is_verified').checked,
                business_module_ids: selectedModuleIds
            };

            const submitBtn = storeForm.querySelector('button[type="submit"]');
            submitBtn.disabled = true;
            submitBtn.innerText = 'Saving...';

            try {
                await handleResponse(await fetch(`${API_URL}/admin/stores/${id}`, {
                    method: 'PUT',
                    headers: getHeaders(),
                    body: JSON.stringify(payload)
                }));
                
                alert('Success: Data toko berhasil diperbarui!');
                location.reload();
            } catch (err) {
                alert('Error: ' + err.message);
            } finally {
                submitBtn.disabled = false;
                submitBtn.innerText = 'Save Store Metadata';
            }
        };
    };

    async function submitForm(e, idField, type, payload) {
        e.preventDefault();
        const id = document.getElementById(idField).value;
        const url = id ? `${API_URL}/admin/${type}/${id}` : `${API_URL}/admin/${type}`;
        const method = id ? 'PUT' : 'POST';
        try {
            await handleResponse(await fetch(url, {
                method, headers: getHeaders(), body: JSON.stringify(payload)
            }));
            location.reload();
        } catch (err) { alert(err.message); }
    }

    initDashboard();
}

// Global Help Functions (called from HTML)
async function deleteItem(type, id) {
    if (!confirm('Yakin ingin menghapus item ini?')) return;
    try {
        await handleResponse(await fetch(`${API_URL}/admin/${type}/${id}`, { 
            method: 'DELETE', 
            headers: getHeaders() 
        }));
        location.reload();
    } catch (err) { alert(err.message); }
}

async function toggleSection(id, isActive) {
    try {
        const sections = await handleResponse(await fetch(`${API_URL}/admin/sections`, { headers: getHeaders() }));
        const section = sections.find(s => s.id === id);
        section.is_active = isActive;
        
        await handleResponse(await fetch(`${API_URL}/admin/sections/${id}`, {
            method: 'PUT',
            headers: getHeaders(),
            body: JSON.stringify(section)
        }));
    } catch (err) { alert(err.message); }
}

async function updateMitraStatus(type, id, newStatus) {
    const actionText = newStatus === 'approved' ? 'menyetujui' : 'menolak';
    if (!confirm(`Yakin ingin ${actionText} pendaftaran ini?`)) return;

    try {
        await handleResponse(await fetch(`${API_URL}/admin/${type}/${id}/status`, {
            method: 'PATCH',
            headers: getHeaders(),
            body: JSON.stringify({ status: newStatus })
        }));
        alert('Status berhasil diperbarui!');
        location.reload();
    } catch (err) { alert(err.message); }
}

// Image Upload Helper
async function uploadImage(fileInputId, previewId, hiddenInputId) {
    const fileInput = document.getElementById(fileInputId);
    if (!fileInput.files[0]) return;

    const formData = new FormData();
    formData.append('image', fileInput.files[0]);

    try {
        const response = await fetch(`${API_URL}/admin/upload`, {
            method: 'POST',
            headers: { 'Authorization': `Bearer ${localStorage.getItem('admin_token')}` },
            body: formData
        });
        const data = await response.json();
        if (data.success) {
            document.getElementById(previewId).src = data.data.url;
            document.getElementById(hiddenInputId).value = data.data.url;
            alert('Upload berhasil!');
        } else {
            alert('Upload gagal: ' + data.message);
        }
    } catch (err) { alert('Upload error.'); }
}
