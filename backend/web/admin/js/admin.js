const API_URL = '/api/v1';

// --- Utility Functions ---
const getHeaders = () => ({
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${localStorage.getItem('admin_token')}`
});

const handleResponse = async (response) => {
    if (response.status === 401) {
        localStorage.removeItem('admin_token');
        window.location.href = 'index.html';
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
                window.location.href = 'dashboard.html';
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
        window.location.href = 'index.html';
    });

    // Navigation
    const navLinks = document.querySelectorAll('.nav-link');
    const sections = document.querySelectorAll('.cms-section');

    navLinks.forEach(link => {
        link.addEventListener('click', (e) => {
            e.preventDefault();
            const targetId = link.getAttribute('data-target');
            
            navLinks.forEach(l => l.classList.remove('active'));
            link.classList.add('active');

            sections.forEach(s => s.style.display = 'none');
            document.getElementById(targetId).style.display = 'block';
            
            loadSectionData(targetId);
        });
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
            
            loadSectionData('overview');
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
    }

    // --- Banners Manager ---
    async function loadBanners() {
        const banners = await handleResponse(await fetch(`${API_URL}/admin/banners`, { headers: getHeaders() }));
        const list = document.getElementById('bannerList');
        list.innerHTML = banners.map(b => `
            <tr>
                <td><img src="${b.image_url || 'https://via.placeholder.com/80x40'}" class="preview-img" style="width: 60px"></td>
                <td>${b.title}</td>
                <td>${b.position}</td>
                <td>${b.sort_order}</td>
                <td>
                    <button class="action-btn edit-btn" onclick="openBannerModal(${JSON.stringify(b).replace(/"/g, '&quot;')})">Edit</button>
                    <button class="action-btn delete-btn" onclick="deleteItem('banners', ${b.id})">Del</button>
                </td>
            </tr>
        `).join('');
    }

    // --- Categories Manager ---
    async function loadCategories() {
        const categories = await handleResponse(await fetch(`${API_URL}/admin/categories`, { headers: getHeaders() }));
        const list = document.getElementById('categoryList');
        list.innerHTML = categories.map(c => `
            <tr>
                <td><i class="material-icons">${c.icon_name}</i></td>
                <td>${c.name}</td>
                <td>${c.slug}</td>
                <td>${c.sort_order}</td>
                <td>
                    <button class="action-btn edit-btn" onclick="openCategoryModal(${JSON.stringify(c).replace(/"/g, '&quot;')})">Edit</button>
                    <button class="action-btn delete-btn" onclick="deleteItem('categories', ${c.id})">Del</button>
                </td>
            </tr>
        `).join('');
    }

    // --- Products Manager ---
    async function loadProducts() {
        const products = await handleResponse(await fetch(`${API_URL}/admin/products`, { headers: getHeaders() }));
        const list = document.getElementById('productList');
        list.innerHTML = products.map(p => `
            <tr>
                <td><img src="${p.image_url}" class="preview-img" style="width: 40px"></td>
                <td>${p.name}</td>
                <td>Rp ${p.price.toLocaleString()}</td>
                <td>
                    <button class="action-btn edit-btn" onclick="openProductModal(${JSON.stringify(p).replace(/"/g, '&quot;')})">Edit</button>
                    <button class="action-btn delete-btn" onclick="deleteItem('products', ${p.id})">Del</button>
                </td>
            </tr>
        `).join('');
    }

    // --- Stores Manager ---
    async function loadStores() {
        const stores = await handleResponse(await fetch(`${API_URL}/admin/stores`, { headers: getHeaders() }));
        const list = document.getElementById('storeList');
        if (!list) return;
        list.innerHTML = stores.map(s => {
            let statusColor = '#FFA500'; // pending
            if (s.status === 'approved') statusColor = '#4CAF50';
            if (s.status === 'rejected') statusColor = '#f44336';

            return `
                <tr>
                    <td><strong>${s.name}</strong></td>
                    <td>${s.user ? s.user.first_name + ' ' + s.user.last_name : 'Unknown'}</td>
                    <td>${s.category}</td>
                    <td>${new Date(s.created_at).toLocaleDateString('id-ID')}</td>
                    <td><span style="color: ${statusColor}; font-weight: bold">${s.status.toUpperCase()}</span></td>
                    <td>
                        ${s.status === 'pending' ? `
                            <button class="action-btn edit-btn" onclick="updateMitraStatus('stores', ${s.id}, 'approved')">Approve</button>
                            <button class="action-btn delete-btn" onclick="updateMitraStatus('stores', ${s.id}, 'rejected')">Reject</button>
                        ` : '-'}
                    </td>
                </tr>
            `;
        }).join('');
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
                    <button class="action-btn edit-btn" onclick="openSectionModal(${JSON.stringify(s).replace(/"/g, '&quot;')})">Edit</button>
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
