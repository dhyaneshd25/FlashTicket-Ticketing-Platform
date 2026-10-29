<%@ page contentType="text/html;charset=UTF-8" %>
<%@ include file="common/header.jsp" %>

<div class="order-status-wrapper">
    <h1>Live Order Status</h1>
    <p class="subtitle">Real-time status updates from the transactional outbox and payment service.</p>

    <div class="order-status-panel" data-order-id="${orderId}">
        <div class="status-header">
            <span>Order Reference</span>
            <code>${orderId}</code>
        </div>

        <div class="status-body">
            <span class="status-label">Current Status:</span>
            <span id="orderStatus" class="status-badge status-pending">checking...</span>
        </div>

        <div id="paymentPendingAction" style="display: none; margin-top: 20px;">
            <p class="text-muted">Seats are held in Redis. Please complete payment to confirm your booking:</p>
            <a href="${pageContext.request.contextPath}/orders/${orderId}/payment" class="btn btn-primary btn-block">
                💳 Go to Demo Payment Screen &rarr;
            </a>
        </div>

        <div id="confirmedAction" style="display: none; margin-top: 20px;">
            <div class="alert alert-success">✅ Your tickets have been confirmed and issued!</div>
            <a href="${pageContext.request.contextPath}/my-orders" class="btn btn-outline btn-block">
                View in My Orders
            </a>
        </div>

        <div id="failedAction" style="display: none; margin-top: 20px;">
            <div class="alert alert-error">❌ Payment failed or expired. Soft-reserved seats have been released.</div>
            <a href="${pageContext.request.contextPath}/" class="btn btn-outline btn-block">
                Back to Upcoming Shows
            </a>
        </div>
    </div>
</div>

<script src="${pageContext.request.contextPath}/static/js/order-status.js"></script>

<%@ include file="common/footer.jsp" %>
