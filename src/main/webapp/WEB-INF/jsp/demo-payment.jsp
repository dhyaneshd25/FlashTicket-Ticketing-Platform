<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ include file="common/header.jsp" %>

<div class="payment-container">
    <div class="payment-header">
        <h1>⚡ Demo Payment Gateway</h1>
        <p class="subtitle">Complete your transaction to finalize your flash-sale ticket reservation.</p>
    </div>

    <div class="payment-layout">
        <!-- Order Summary Column -->
        <div class="order-summary-card">
            <h2>Order Summary</h2>
            <div class="summary-item">
                <span class="label">Event:</span>
                <span class="value"><strong>${show != null ? show.title : 'Event Show'}</strong></span>
            </div>
            <div class="summary-item">
                <span class="label">Venue:</span>
                <span class="value">${show != null ? show.venue : 'Main Arena'}</span>
            </div>
            <div class="summary-item">
                <span class="label">Date &amp; Time:</span>
                <span class="value">${show != null ? show.showTime : ''}</span>
            </div>
            <hr class="divider">
            <div class="summary-item">
                <span class="label">Seats Reserved:</span>
                <span class="value">
                    <strong>${order.seatQuantity} seat(s)</strong>
                    <c:if test="${order.seatCodes != null && !order.seatCodes.isEmpty()}">
                        <div class="summary-seat-pills">
                            <span class="seat-badge-pill">🪑 ${order.seatCodes}</span>
                        </div>
                    </c:if>
                </span>
            </div>
            <div class="summary-item">
                <span class="label">Price per Seat:</span>
                <span class="value">$${show != null && show.price != null ? show.price : '50.00'}</span>
            </div>
            <div class="summary-item total-item">
                <span class="label">Total Amount Due:</span>
                <span class="value total-price">$${order.totalAmount}</span>
            </div>

            <div class="hold-timer-box">
                <span class="timer-icon">⏱️</span>
                <span>Seats soft-held in Redis for: <strong id="holdTimer">09:59</strong></span>
            </div>

            <div class="order-id-meta">
                <small>Order ID: <code>${order.id}</code></small>
            </div>
        </div>

        <!-- Payment Interactive Column -->
        <div class="payment-action-card">
            <h2>Select Demo Payment Method</h2>

            <div class="payment-tabs">
                <button class="pay-tab-btn active" type="button" onclick="selectPayMethod('card', this)">💳 Card</button>
                <button class="pay-tab-btn" type="button" onclick="selectPayMethod('upi', this)">⚡ UPI / Instant</button>
            </div>

            <div id="paymentAlert" class="alert" style="display: none;"></div>

            <!-- Card View -->
            <div id="cardView" class="payment-method-view active">
                <div class="demo-card-preview">
                    <div class="card-brand">FLASH PAY</div>
                    <div class="card-number">4242 &bull;&bull;&bull;&bull; &bull;&bull;&bull;&bull; 4242</div>
                    <div class="card-bottom">
                        <span class="card-holder" id="cardHolderDisplay">AUTHENTICATED USER</span>
                        <span class="card-expiry">12/28</span>
                    </div>
                </div>

                <div class="form-group">
                    <label>Card Number</label>
                    <input type="text" value="4242 8888 9999 4242" readonly>
                </div>
                <div class="form-row">
                    <div class="form-group half">
                        <label>Expiry</label>
                        <input type="text" value="12/28" readonly>
                    </div>
                    <div class="form-group half">
                        <label>CVV</label>
                        <input type="password" value="123" readonly>
                    </div>
                </div>
            </div>

            <!-- UPI View -->
            <div id="upiView" class="payment-method-view">
                <div class="form-group">
                    <label>Demo UPI ID / Virtual Address</label>
                    <input type="text" value="user@flashticket" readonly>
                    <small class="text-muted">Instant mock authorization enabled.</small>
                </div>
            </div>

            <div class="payment-buttons">
                <button id="paySuccessBtn" class="btn btn-primary btn-block btn-pay" onclick="handlePayment(true)">
                    ✅ Pay $${order.totalAmount} (Simulate Success)
                </button>

                <button id="payFailBtn" class="btn btn-outline btn-block btn-fail" onclick="handlePayment(false)">
                    ❌ Simulate Declined Payment (Tests Seat Release)
                </button>
            </div>
        </div>
    </div>

    <!-- Success Ticket Modal/Panel -->
    <div id="successPanel" class="success-ticket-panel" style="display: none;">
        <div class="ticket-badge-success">🎉 Booking Confirmed!</div>
        <h2>Your Tickets Are Ready!</h2>
        <p>Payment of <strong>$${order.totalAmount}</strong> was confirmed.</p>
        <div class="ticket-stub">
            <div class="stub-header">⚡ FLASHTICKET DIGITAL PASS</div>
            <div class="stub-title">${show != null ? show.title : 'Event Show'}</div>
            <div class="stub-meta">
                Seats: ${order.seatQuantity} <c:if test="${order.seatCodes != null && !order.seatCodes.isEmpty()}">(${order.seatCodes})</c:if> &middot; Venue: ${show != null ? show.venue : 'Main Arena'}
            </div>
            <div class="stub-code">PASS-${order.id.toString().substring(0, 8).toUpperCase()}</div>
        </div>
        <div class="ticket-actions">
            <a href="${pageContext.request.contextPath}/my-orders" class="btn btn-primary">View My Orders</a>
            <a href="${pageContext.request.contextPath}/orders/${order.id}/status" class="btn btn-outline">Order Status Page</a>
        </div>
    </div>
</div>

<script>
const contextPath = document.querySelector('meta[name="context-path"]')?.getAttribute('content') || '';
const orderId = '${order.id}';
const token = localStorage.getItem('ft_token');

// Update card holder name from stored user
try {
    const user = JSON.parse(localStorage.getItem('ft_user') || '{}');
    if (user.fullName) {
        document.getElementById('cardHolderDisplay').textContent = user.fullName.toUpperCase();
    }
} catch (e) {}

// Countdown timer (10 mins)
let secondsLeft = 600;
const timerEl = document.getElementById('holdTimer');
const countdown = setInterval(() => {
    secondsLeft--;
    if (secondsLeft <= 0) {
        clearInterval(countdown);
        timerEl.textContent = 'EXPIRED';
        timerEl.style.color = '#f87171';
        return;
    }
    const mins = Math.floor(secondsLeft / 60).toString().padStart(2, '0');
    const secs = (secondsLeft % 60).toString().padStart(2, '0');
    timerEl.textContent = mins + ':' + secs;
}, 1000);

function selectPayMethod(method, btn) {
    document.querySelectorAll('.pay-tab-btn').forEach(b => b.classList.remove('active'));
    document.querySelectorAll('.payment-method-view').forEach(v => v.classList.remove('active'));
    btn.classList.add('active');
    if (method === 'card') {
        document.getElementById('cardView').classList.add('active');
    } else {
        document.getElementById('upiView').classList.add('active');
    }
}

async function handlePayment(isSuccess) {
    const successBtn = document.getElementById('paySuccessBtn');
    const failBtn = document.getElementById('payFailBtn');
    const alertBox = document.getElementById('paymentAlert');

    alertBox.style.display = 'none';
    successBtn.disabled = true;
    failBtn.disabled = true;

    const endpoint = isSuccess ? ('/api/payment/' + orderId + '/charge') : ('/api/payment/' + orderId + '/fail');
    const headers = { 'Content-Type': 'application/json' };
    if (token) headers['Authorization'] = 'Bearer ' + token;

    try {
        const res = await fetch(contextPath + endpoint, {
            method: 'POST',
            headers: headers
        });

        const data = await res.json().catch(() => ({}));

        if (isSuccess && res.ok && data.success) {
            clearInterval(countdown);
            document.querySelector('.payment-layout').style.display = 'none';
            document.getElementById('successPanel').style.display = 'block';
        } else {
            alertBox.textContent = data.message || (isSuccess ? 'Payment failed.' : 'Payment declined. Seats released.');
            alertBox.className = 'alert ' + (isSuccess ? 'alert-error' : 'alert-info');
            alertBox.style.display = 'block';

            if (!isSuccess) {
                // Change button to redirect home
                failBtn.disabled = false;
                failBtn.textContent = '← Return to Upcoming Shows';
                failBtn.onclick = () => window.location.href = contextPath + '/';
            }
        }
    } catch (err) {
        alertBox.textContent = 'Network error: ' + err.message;
        alertBox.className = 'alert alert-error';
        alertBox.style.display = 'block';
        successBtn.disabled = false;
        failBtn.disabled = false;
    }
}
</script>

<%@ include file="common/footer.jsp" %>
