<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ include file="common/header.jsp" %>

<div class="dashboard-header">
    <div>
        <h1>My Tickets &amp; Orders</h1>
        <p class="subtitle">Track your reservations, payment confirmations, and active tickets.</p>
    </div>
</div>

<div class="table-responsive">
    <table class="data-table">
        <thead>
            <tr>
                <th>Order ID</th>
                <th>Show ID</th>
                <th>Seats</th>
                <th>Total Price</th>
                <th>Order Status</th>
                <th>Placed On</th>
                <th>Live Status</th>
            </tr>
        </thead>
        <tbody id="myOrdersBody">
            <tr><td colspan="7">Loading your orders...</td></tr>
        </tbody>
    </table>
</div>

<script>
const contextPath = document.querySelector('meta[name="context-path"]')?.getAttribute('content') || '';
const token = localStorage.getItem('ft_token');

async function loadMyOrders() {
    const tbody = document.getElementById('myOrdersBody');
    if (!token) {
        tbody.innerHTML = '<tr><td colspan="7" class="text-muted">Please sign in to view your orders.</td></tr>';
        return;
    }

    try {
        const res = await fetch(contextPath + '/api/orders/my-orders', {
            headers: {
                'Authorization': 'Bearer ' + token,
                'Content-Type': 'application/json'
            }
        });

        if (res.ok) {
            const orders = await res.json();
            if (orders.length === 0) {
                tbody.innerHTML = '<tr><td colspan="7">You haven\'t placed any orders yet. <a href="' + contextPath + '/" class="auth-hint-link">Browse shows</a> to buy tickets!</td></tr>';
                return;
            }

            tbody.innerHTML = orders.map(o => `
                <tr>
                    <td><code>\${o.id.substring(0, 8)}...</code></td>
                    <td><code>\${o.showId.substring(0, 8)}...</code></td>
                    <td>
                        <strong>\${o.seatQuantity} seat(s)</strong>
                        \${o.seatCodes ? '<br><span class="seat-badge-pill">🪑 ' + escapeHtml(o.seatCodes) + '</span>' : ''}
                    </td>
                    <td>$\${o.totalAmount}</td>
                    <td><span class="status-badge status-\${o.status.toLowerCase()}">\${o.status}</span></td>
                    <td>\${o.createdAt ? new Date(o.createdAt).toLocaleString() : 'N/A'}</td>
                    <td><a href="\${contextPath}/orders/\${o.id}/status" class="btn-sm btn-outline">Check Status</a></td>
                </tr>
            `).join('');
        } else {
            tbody.innerHTML = '<tr><td colspan="7" class="error">Failed to load orders.</td></tr>';
        }
    } catch (e) {
        tbody.innerHTML = '<tr><td colspan="7" class="error">Network error: ' + e.message + '</td></tr>';
    }
}

document.addEventListener('DOMContentLoaded', loadMyOrders);
</script>

<%@ include file="common/footer.jsp" %>
