<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ include file="common/header.jsp" %>

<div class="dashboard-header">
    <div>
        <h1>Admin Control Panel</h1>
        <p class="subtitle">Platform oversight: metrics, user roles, system orders, show controls, and distributed architecture operations.</p>
    </div>
    <div style="display: flex; gap: 10px; flex-wrap: wrap;">
        <a href="${pageContext.request.contextPath}/simulation" class="btn btn-primary" style="background: var(--gradient-orange); border: none;">
            ⚡ Kafka &amp; Redis Simulation
        </a>
        <a href="${pageContext.request.contextPath}/organizer" class="btn btn-outline">+ Create Show</a>
    </div>
</div>

<!-- Admin Architecture Operations Banner -->
<div class="sim-control-card mb-4" style="border-left: 4px solid var(--color-orange-primary); background: linear-gradient(135deg, rgba(249, 115, 22, 0.08) 0%, rgba(16, 185, 129, 0.06) 100%);">
    <div class="flex-between">
        <div>
            <div class="flex-align-gap" style="margin-bottom: 6px;">
                <h3 style="margin: 0; color: #ffffff;">⚡ High-Throughput Architecture Simulation (Admin Access)</h3>
                <span class="badge-role role-badge-admin">ADMIN PRIVILEGE</span>
            </div>
            <p class="text-muted" style="margin: 0; font-size: 14px; line-height: 1.5;">
                As an <strong>Administrator</strong>, you have full privileges to test flash sale concurrency bursts, inspect live <strong>Redis In-Memory Atomic Gates</strong>, 
                monitor the <strong>PostgreSQL Transactional Outbox</strong>, and trace partitioned <strong>Apache Kafka Streams</strong> (6 partitions, consumer groups).
            </p>
        </div>
        <div style="display: flex; gap: 10px; margin-top: 8px;">
            <a href="${pageContext.request.contextPath}/simulation" class="btn btn-primary">
                🔬 Launch Architecture Simulation ➔
            </a>
        </div>
    </div>
</div>

<!-- Metrics Cards -->
<div class="stats-grid" id="statsGrid">
    <div class="stat-card">
        <span class="stat-label">Total Users</span>
        <span class="stat-value" id="statUsers">...</span>
    </div>
    <div class="stat-card">
        <span class="stat-label">Total Shows</span>
        <span class="stat-value" id="statShows">...</span>
    </div>
    <div class="stat-card">
        <span class="stat-label">Total Orders</span>
        <span class="stat-value" id="statOrders">...</span>
    </div>
    <div class="stat-card">
        <span class="stat-label">Confirmed Orders</span>
        <span class="stat-value stat-confirmed" id="statConfirmed">...</span>
    </div>
    <div class="stat-card">
        <span class="stat-label">Total Revenue</span>
        <span class="stat-value stat-revenue" id="statRevenue">...</span>
    </div>
</div>

<!-- Tabs -->
<div class="admin-tabs">
    <button class="tab-btn active" onclick="switchTab('usersTab', this)">User Management</button>
    <button class="tab-btn" onclick="switchTab('ordersTab', this)">All Orders</button>
    <button class="tab-btn" onclick="switchTab('showsTab', this)">Show Inventory</button>
    <button class="tab-btn" onclick="window.location.href='${pageContext.request.contextPath}/simulation'" style="color: var(--text-orange); font-weight: 700;">
        ⚡ Kafka &amp; Redis Simulation Console ➔
    </button>
</div>

<div id="adminAlert" class="alert" style="display: none;"></div>

<!-- Tab 1: Users -->
<div id="usersTab" class="tab-content active">
    <h2>Registered Users</h2>
    <div class="table-responsive">
        <table class="data-table">
            <thead>
                <tr>
                    <th>Full Name</th>
                    <th>Email</th>
                    <th>Current Role</th>
                    <th>Registered At</th>
                    <th>Change Role</th>
                </tr>
            </thead>
            <tbody id="usersTableBody">
                <tr><td colspan="5">Loading users...</td></tr>
            </tbody>
        </table>
    </div>
</div>

<!-- Tab 2: Orders -->
<div id="ordersTab" class="tab-content">
    <h2>All Platform Orders</h2>
    <div class="table-responsive">
        <table class="data-table">
            <thead>
                <tr>
                    <th>Order ID</th>
                    <th>User ID</th>
                    <th>Seats</th>
                    <th>Total</th>
                    <th>Status</th>
                    <th>Action</th>
                </tr>
            </thead>
            <tbody id="ordersTableBody">
                <tr><td colspan="6">Loading orders...</td></tr>
            </tbody>
        </table>
    </div>
</div>

<!-- Tab 3: Shows -->
<div id="showsTab" class="tab-content">
    <h2>Active Show Inventory</h2>
    <div class="table-responsive">
        <table class="data-table">
            <thead>
                <tr>
                    <th>Title</th>
                    <th>Venue</th>
                    <th>Show Time</th>
                    <th>Available / Total</th>
                    <th>Actions</th>
                </tr>
            </thead>
            <tbody id="showsTableBody">
                <tr><td colspan="5">Loading shows...</td></tr>
            </tbody>
        </table>
    </div>
</div>

<script>
const contextPath = document.querySelector('meta[name="context-path"]')?.getAttribute('content') || '';
const token = localStorage.getItem('ft_token');

function getAuthHeaders() {
    return {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ' + token
    };
}

function switchTab(tabId, btn) {
    document.querySelectorAll('.tab-content').forEach(el => el.classList.remove('active'));
    document.querySelectorAll('.tab-btn').forEach(el => el.classList.remove('active'));
    document.getElementById(tabId).classList.add('active');
    btn.classList.add('active');
}

function showAlert(msg, isSuccess = true) {
    const el = document.getElementById('adminAlert');
    el.textContent = msg;
    el.className = 'alert ' + (isSuccess ? 'alert-success' : 'alert-error');
    el.style.display = 'block';
    setTimeout(() => { el.style.display = 'none'; }, 4000);
}

async function loadStats() {
    try {
        const res = await fetch(contextPath + '/api/admin/stats', { headers: getAuthHeaders() });
        if (res.ok) {
            const data = await res.json();
            document.getElementById('statUsers').textContent = data.totalUsers;
            document.getElementById('statShows').textContent = data.totalShows;
            document.getElementById('statOrders').textContent = data.totalOrders;
            document.getElementById('statConfirmed').textContent = data.confirmedOrders;
            document.getElementById('statRevenue').textContent = '$' + (data.totalRevenue || 0).toLocaleString();
        }
    } catch (e) {
        console.error('Failed to load stats', e);
    }
}

async function loadUsers() {
    try {
        const res = await fetch(contextPath + '/api/admin/users', { headers: getAuthHeaders() });
        const tbody = document.getElementById('usersTableBody');
        if (res.ok) {
            const users = await res.json();
            if (users.length === 0) {
                tbody.innerHTML = '<tr><td colspan="5">No users found.</td></tr>';
                return;
            }
            tbody.innerHTML = users.map(u => `
                <tr>
                    <td><strong>\${escapeHtml(u.fullName)}</strong></td>
                    <td>\${escapeHtml(u.email)}</td>
                    <td><span class="role-badge role-\${u.role.toLowerCase()}">\${u.role}</span></td>
                    <td>\${u.createdAt ? new Date(u.createdAt).toLocaleDateString() : 'N/A'}</td>
                    <td>
                        <select onchange="updateUserRole('\${u.id}', this.value)" class="role-select">
                            <option value="ROLE_USER" \${u.role === 'ROLE_USER' ? 'selected' : ''}>ROLE_USER</option>
                            <option value="ROLE_ORGANIZER" \${u.role === 'ROLE_ORGANIZER' ? 'selected' : ''}>ROLE_ORGANIZER</option>
                            <option value="ROLE_ADMIN" \${u.role === 'ROLE_ADMIN' ? 'selected' : ''}>ROLE_ADMIN</option>
                        </select>
                    </td>
                </tr>
            `).join('');
        } else {
            tbody.innerHTML = '<tr><td colspan="5" class="error">Access denied or failed to load.</td></tr>';
        }
    } catch (e) {
        console.error(e);
    }
}

async function updateUserRole(userId, newRole) {
    try {
        const res = await fetch(contextPath + '/api/admin/users/' + userId + '/role', {
            method: 'PUT',
            headers: getAuthHeaders(),
            body: JSON.stringify({ role: newRole })
        });
        if (res.ok) {
            showAlert('User role updated successfully to ' + newRole);
            loadUsers();
        } else {
            const err = await res.json().catch(() => ({}));
            showAlert(err.message || 'Failed to update user role', false);
        }
    } catch (e) {
        showAlert('Network error: ' + e.message, false);
    }
}

async function loadOrders() {
    try {
        const res = await fetch(contextPath + '/api/admin/orders', { headers: getAuthHeaders() });
        const tbody = document.getElementById('ordersTableBody');
        if (res.ok) {
            const orders = await res.json();
            if (orders.length === 0) {
                tbody.innerHTML = '<tr><td colspan="6">No orders placed yet.</td></tr>';
                return;
            }
            tbody.innerHTML = orders.map(o => `
                <tr>
                    <td><code>\${o.id.substring(0, 8)}...</code></td>
                    <td><code>\${o.userId.substring(0, 8)}...</code></td>
                    <td>
                        <strong>\${o.seatQuantity}</strong>
                        \${o.seatCodes ? '<br><span class="seat-badge-pill">🪑 ' + escapeHtml(o.seatCodes) + '</span>' : ''}
                    </td>
                    <td>$\${o.totalAmount}</td>
                    <td><span class="status-badge status-\${o.status.toLowerCase()}">\${o.status}</span></td>
                    <td><a href="\${contextPath}/orders/\${o.id}/status" class="btn-sm btn-outline">View</a></td>
                </tr>
            `).join('');
        }
    } catch (e) {
        console.error(e);
    }
}

async function loadShows() {
    try {
        const res = await fetch(contextPath + '/api/shows', { headers: getAuthHeaders() });
        const tbody = document.getElementById('showsTableBody');
        if (res.ok) {
            const shows = await res.json();
            if (shows.length === 0) {
                tbody.innerHTML = '<tr><td colspan="5">No shows configured.</td></tr>';
                return;
            }
            tbody.innerHTML = shows.map(s => `
                <tr>
                    <td><strong>\${escapeHtml(s.title)}</strong></td>
                    <td>\${escapeHtml(s.venue || 'N/A')}</td>
                    <td>\${new Date(s.showTime).toLocaleString()}</td>
                    <td>\${s.availableSeats} / \${s.totalSeats}</td>
                    <td>
                        <button onclick="deleteShow('\${s.id}')" class="btn-sm btn-outline btn-danger">Delete</button>
                    </td>
                </tr>
            `).join('');
        }
    } catch (e) {
        console.error(e);
    }
}

async function deleteShow(showId) {
    if (!confirm('Are you sure you want to delete this show?')) return;
    try {
        const res = await fetch(contextPath + '/api/shows/' + showId, {
            method: 'DELETE',
            headers: getAuthHeaders()
        });
        if (res.ok) {
            showAlert('Show deleted successfully.');
            loadShows();
            loadStats();
        } else {
            showAlert('Failed to delete show', false);
        }
    } catch (e) {
        showAlert('Network error: ' + e.message, false);
    }
}

document.addEventListener('DOMContentLoaded', function() {
    loadStats();
    loadUsers();
    loadOrders();
    loadShows();
});
</script>

<%@ include file="common/footer.jsp" %>
