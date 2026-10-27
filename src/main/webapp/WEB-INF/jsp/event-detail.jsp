<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ include file="common/header.jsp" %>

<div class="event-detail-container" data-show-id="${show.id}">
    <!-- Top Bar Navigation -->
    <a href="${pageContext.request.contextPath}/" class="back-link">&larr; Back to all shows</a>

    <div class="event-hero-header">
        <div>
            <h1>${show.title}</h1>
            <p class="venue">📍 ${show.venue} &middot; 📅 ${show.showTime}</p>
        </div>
        <div class="header-badges">
            <span class="price-chip">$${show.price != null ? show.price : '50.00'} <small>/ seat</small></span>
            <span class="status-chip ${show.availableSeats > 0 ? 'status-chip-available' : 'status-chip-soldout'}">
                <c:choose>
                    <c:when test="${show.availableSeats > 0}">🟢 ${show.availableSeats} Seats Left</c:when>
                    <c:otherwise>🔴 Sold Out</c:otherwise>
                </c:choose>
            </span>
        </div>
    </div>

    <!-- Seat Notice Toast Notification -->
    <div id="seatNoticeToast" class="seat-toast" style="display: none;"></div>

    <div class="event-detail-layout">
        <!-- Left: Interactive Seat Matrix Section -->
        <div class="seat-matrix-section">
            <div class="matrix-card">
                <div class="matrix-header">
                    <h2>Select Your Seats</h2>
                    <p class="subtitle">Click any available seat to reserve. Red seats are already booked.</p>
                </div>

                <!-- Stage / Screen Bar -->
                <div class="screen-stage">
                    <div class="screen-glow"></div>
                    <div class="stage-text">🎭 STAGE / SCREEN 🎭</div>
                </div>

                <!-- Legend Bar -->
                <div class="seat-legend">
                    <div class="legend-item">
                        <span class="seat-sample seat-sample-available"></span>
                        <span>Available</span>
                    </div>
                    <div class="legend-item">
                        <span class="seat-sample seat-sample-selected"></span>
                        <span>Selected</span>
                    </div>
                    <div class="legend-item">
                        <span class="seat-sample seat-sample-booked"></span>
                        <span>Already Booked</span>
                    </div>
                </div>

                <!-- Seat Matrix Grid Container (Rendered by JS) -->
                <div class="matrix-scroll-wrapper">
                    <div id="seatMatrixGrid" class="seat-grid-container">
                        <div class="matrix-loading">
                            <span class="spinner"></span> Loading real-time seat availability from Redis & PostgreSQL...
                        </div>
                    </div>
                </div>

                <!-- Matrix Quick Actions -->
                <div class="matrix-quick-actions">
                    <span class="quick-label">Quick Pick:</span>
                    <button type="button" class="btn-xs btn-outline" onclick="quickSelect(1)">1 Seat</button>
                    <button type="button" class="btn-xs btn-outline" onclick="quickSelect(2)">2 Seats</button>
                    <button type="button" class="btn-xs btn-outline" onclick="quickSelect(4)">4 Seats</button>
                    <button type="button" class="btn-xs btn-outline btn-clear" onclick="clearSeatSelection()">Clear Selection</button>
                </div>
            </div>
        </div>

        <!-- Right: Checkout & Reservation Panel -->
        <div class="checkout-sidebar">
            <div class="purchase-panel" id="purchasePanel">
                <c:choose>
                    <c:when test="${show.availableSeats <= 0}">
                        <div class="sold-out-box">
                            <h3>⛔ Show Sold Out</h3>
                            <p>All flash sale seats for this show have been booked by active buyers.</p>
                            <a href="${pageContext.request.contextPath}/" class="btn btn-outline btn-block mt-2">Explore Other Events</a>
                        </div>
                    </c:when>
                    <c:otherwise>
                        <!-- Logged Out State: Enforces Authentication -->
                        <div id="loggedOutPanel" class="auth-block-panel">
                            <div class="auth-lock-icon">🔒</div>
                            <h3>Sign In Required</h3>
                            <p>You must be signed in to reserve tickets and participate in this flash sale.</p>
                            <a href="${pageContext.request.contextPath}/login?redirect=${pageContext.request.requestURI}" class="btn btn-primary btn-block">
                                Sign In to Reserve Seats
                            </a>
                            <a href="${pageContext.request.contextPath}/register?redirect=${pageContext.request.requestURI}" class="btn btn-outline btn-block mt-2">
                                Create Account
                            </a>
                        </div>

                        <!-- Logged In State: Live Interactive Reservation Form -->
                        <div id="loggedInPanel" class="booking-active-panel" style="display: none;">
                            <h3>Order Summary</h3>

                            <!-- Selected Seats Badges -->
                            <div class="selected-seats-container">
                                <label class="summary-label">Selected Seats:</label>
                                <div id="selectedSeatsPills" class="seats-pills-list">
                                    <span class="no-seats-hint">Click seats in the matrix to select</span>
                                </div>
                            </div>

                            <!-- Live Price Breakdown -->
                            <div class="price-breakdown">
                                <div class="breakdown-row">
                                    <span>Ticket Price:</span>
                                    <span id="unitPriceValue" data-price="${show.price != null ? show.price : '50.00'}">
                                        $${show.price != null ? show.price : '50.00'}
                                    </span>
                                </div>
                                <div class="breakdown-row">
                                    <span>Seats Selected:</span>
                                    <span id="selectedCountDisplay">0</span>
                                </div>
                                <div class="breakdown-row total-row">
                                    <span>Total Due:</span>
                                    <span id="breakdownTotal" class="total-amount">$0.00</span>
                                </div>
                            </div>

                            <button id="buyNowBtn" class="btn btn-primary btn-block btn-lg" disabled>
                                Select Seats to Continue
                            </button>

                            <p id="purchaseMessage" class="message"></p>
                        </div>
                    </c:otherwise>
                </c:choose>
            </div>
        </div>
    </div>
</div>

<script src="${pageContext.request.contextPath}/static/js/checkout.js"></script>

<%@ include file="common/footer.jsp" %>
