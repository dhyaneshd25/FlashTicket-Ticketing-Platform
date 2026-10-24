<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ include file="common/header.jsp" %>

<h1>Upcoming Shows</h1>
<p class="subtitle">Flash sales go live at the show time — inventory is capped, so seats move fast.</p>

<div class="show-grid">
    <c:forEach var="show" items="${shows}">
        <div class="show-card">
            <h2>${show.title}</h2>
            <p class="venue">${show.venue}</p>
            <p class="show-time">${show.showTime}</p>
            <p class="ticket-price">🎟️ <strong>$${show.price != null ? show.price : '50.00'}</strong> <small class="text-muted">/ seat</small></p>
            <p class="seats-left">
                <c:choose>
                    <c:when test="${show.availableSeats > 0}">
                        ${show.availableSeats} / ${show.totalSeats} seats left
                    </c:when>
                    <c:otherwise>
                        <span class="sold-out">SOLD OUT</span>
                    </c:otherwise>
                </c:choose>
            </p>
            <a class="btn btn-primary" href="${pageContext.request.contextPath}/events/${show.id}">View &amp; Buy</a>
        </div>
    </c:forEach>

    <c:if test="${empty shows}">
        <p>No shows configured yet. Insert a row into <code>event_shows</code> to get started (see README).</p>
    </c:if>
</div>

<%@ include file="common/footer.jsp" %>
