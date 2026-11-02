<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ include file="common/header.jsp" %>

<div class="dashboard-header">
    <div>
        <h1>Organizer Hub</h1>
        <p class="subtitle">Publish new flash sales and manage event ticket allocations.</p>
    </div>
</div>

<div class="organizer-layout">
    <!-- Show Creation Form -->
    <div class="organizer-form-card">
        <h2>Create New Show</h2>
        <div id="createAlert" class="alert" style="display: none;"></div>

        <form id="createShowForm" onsubmit="handleCreateShow(event)">
            <div class="form-group">
                <label for="title">Event Title</label>
                <input type="text" id="title" required placeholder="e.g. Coldplay: Music of the Spheres">
            </div>

            <div class="form-group">
                <label for="venue">Venue &amp; City</label>
                <input type="text" id="venue" required placeholder="e.g. DY Patil Stadium, Navi Mumbai">
            </div>

            <div class="form-group">
                <label for="showTime">Date &amp; Time</label>
                <input type="datetime-local" id="showTime" required>
            </div>

            <div class="form-group">
                <label for="totalSeats">Total Seat Capacity (Flash Sale Allocation)</label>
                <input type="number" id="totalSeats" min="1" max="100000" value="100" required>
            </div>

            <button type="submit" id="createBtn" class="btn btn-primary btn-block">Publish &amp; Seed Flash Sale</button>
        </form>
    </div>

    <!-- Live Shows List -->
    <div class="organizer-shows-card">
        <h2>Active Shows</h2>
        <div class="table-responsive">
            <table class="data-table">
                <thead>
                    <tr>
                        <th>Title</th>
                        <th>Show Time</th>
                        <th>Seats Available</th>
                        <th>Action</th>
                    </tr>
                </thead>
                <tbody id="organizerShowsBody">
                    <tr><td colspan="4">Loading shows...</td></tr>
                </tbody>
            </table>
        </div>
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

async function loadShows() {
    try {
        const res = await fetch(contextPath + '/api/shows', { headers: getAuthHeaders() });
        const tbody = document.getElementById('organizerShowsBody');
        if (res.ok) {
            const shows = await res.json();
            if (shows.length === 0) {
                tbody.innerHTML = '<tr><td colspan="4">No shows created yet.</td></tr>';
                return;
            }
            tbody.innerHTML = shows.map(s => `
                <tr>
                    <td><strong>\${escapeHtml(s.title)}</strong><br><small class="text-muted">\${escapeHtml(s.venue || '')}</small></td>
                    <td>\${new Date(s.showTime).toLocaleString()}</td>
                    <td><span class="seats-badge">\${s.availableSeats} / \${s.totalSeats}</span></td>
                    <td><a href="\${contextPath}/events/\${s.id}" class="btn-sm btn-outline">Preview</a></td>
                </tr>
            `).join('');
        }
    } catch (e) {
        console.error(e);
    }
}

async function handleCreateShow(e) {
    e.preventDefault();
    const btn = document.getElementById('createBtn');
    const alertBox = document.getElementById('createAlert');
    const title = document.getElementById('title').value.trim();
    const venue = document.getElementById('venue').value.trim();
    const showTimeInput = document.getElementById('showTime').value;
    const totalSeats = parseInt(document.getElementById('totalSeats').value, 10);

    alertBox.style.display = 'none';
    btn.disabled = true;
    btn.textContent = 'Publishing...';

    try {
        const showTimeIso = new Date(showTimeInput).toISOString();
        const res = await fetch(contextPath + '/api/shows', {
            method: 'POST',
            headers: getAuthHeaders(),
            body: JSON.stringify({
                title: title,
                venue: venue,
                showTime: showTimeIso,
                totalSeats: totalSeats
            })
        });

        if (res.status === 201) {
            alertBox.textContent = '🎉 Show created and Redis inventory seeded successfully!';
            alertBox.className = 'alert alert-success';
            alertBox.style.display = 'block';
            document.getElementById('createShowForm').reset();
            loadShows();
        } else {
            const err = await res.json().catch(() => ({}));
            alertBox.textContent = err.message || 'Failed to create show. Please verify permissions.';
            alertBox.className = 'alert alert-error';
            alertBox.style.display = 'block';
        }
    } catch (err) {
        alertBox.textContent = 'Network error: ' + err.message;
        alertBox.className = 'alert alert-error';
        alertBox.style.display = 'block';
    } finally {
        btn.disabled = false;
        btn.textContent = 'Publish & Seed Flash Sale';
    }
}

document.addEventListener('DOMContentLoaded', function() {
    // Set default datetime picker to tomorrow at 7:00 PM
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    tomorrow.setHours(19, 0, 0, 0);
    const isoLocal = new Date(tomorrow.getTime() - tomorrow.getTimezoneOffset() * 60000).toISOString().slice(0, 16);
    document.getElementById('showTime').value = isoLocal;

    loadShows();
});
</script>

<%@ include file="common/footer.jsp" %>
