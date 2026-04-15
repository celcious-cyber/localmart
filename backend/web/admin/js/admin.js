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
// This part will run if we are on dashboard.html
if (window.location.pathname.includes('dashboard.html')) {
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

        // History Management
        if (updateHistory) {
            const newPath = `/admin/${targetId}`;
            if (window.location.pathname !== newPath) {
                history.pushState({ section: targetId }, '', newPath);
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
            
            // Detection from Pathname (SPA)
            const pathSegments = window.location.pathname.split('/');
            const initialSection = pathSegments[pathSegments.length - 1];
            
            if (initialSection && initialSection !== 'admin' && initialSection !== 'dashboard.html') {
                switchSection(initialSection, false);
            } else {
                switchSection('overview', false);
            }
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
        const banners = await handleResponse(await fetch(`${API_URL}/admin/banners`, { headers: getHeaders() }));
        window.allBanners = banners;
        const list = document.getElementById('bannerList');
        list.innerHTML = banners.map(b => `
            <tr>
                <td><img src="${b.image_url}" class="preview-img" style="width: 60px"></td>
                <td>${b.title}</td>
                <td>${b.position}</td>
                <td>${b.sort_order}</td>
                <td>
                    <button class="action-btn edit-btn" onclick="openBannerModalById(${b.id})">Edit</button>
                    <button class="action-btn delete-btn" onclick="deleteItem('banners', ${b.id})">Del</button>
                </td>
            </tr>
        `).join('');
    }

    // --- Categories Manager ---
    async function loadCategories() {
        const categories = await handleResponse(await fetch(`${API_URL}/admin/categories`, { headers: getHeaders() }));
        window.allCategories = categories; // Cache for lookup
        const list = document.getElementById('categoryList');
        list.innerHTML = categories.map(c => {
            const safeType = c.type || 'BARANG';
            return `
                <tr>
                    <td><i class="material-icons">${c.icon_name}</i></td>
                    <td>${c.name}</td>
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
        const products = await handleResponse(await fetch(`${API_URL}/admin/products`, { headers: getHeaders() }));
        window.allProducts = products;
        const list = document.getElementById('productList');
        list.innerHTML = products.map(p => `
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
        const stores = await handleResponse(await fetch(`${API_URL}/admin/stores`, { headers: getHeaders() }));
        window.allStores = stores;
        const list = document.getElementById('storeList');
        list.innerHTML = stores.map(s => `
            <tr>
                <td>${s.name}</td>
                <td>${s.owner?.first_name} ${s.owner?.last_name}</td>
                <td><span class="badge ${s.is_verified ? 'badge-barang' : 'badge-rental'}">${s.is_verified ? 'Verified' : 'Pending'}</span></td>
                <td>
                    <button class="action-btn edit-btn" onclick="openStoreModalById(${s.id})">View/Edit</button>
                </td>
            </tr>
        `).join('');
    }

    // --- Drivers Manager ---
    async function loadDrivers() {
        const drivers = await handleResponse(await fetch(`${API_URL}/admin/drivers`, { headers: getHeaders() }));
        const list = document.getElementById('driverList');
        if (!list) return;
        list.innerHTML = drivers.map(d => {
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
        const homeSections = await handleResponse(await fetch(`${API_URL}/admin/sections`, { headers: getHeaders() }));
        const list = document.getElementById('homeSectionList');
        list.innerHTML = homeSections.map(s => `
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
    // --- Voucher Manager ---
    async function loadVouchers() {
        const vouchers = await handleResponse(await fetch(`${API_URL}/admin/vouchers`, { headers: getHeaders() }));
        const list = document.getElementById('voucherList');
        if (!list) return;
        list.innerHTML = vouchers.map(v => `
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
