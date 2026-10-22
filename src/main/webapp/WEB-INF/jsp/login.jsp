<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ include file="common/header.jsp" %>

<div class="auth-wrapper">
    <div class="auth-card">
        <h2>Sign In to FlashTicket</h2>
        <p class="subtitle">Access flash sales, reserve your seats, and track orders.</p>

        <c:if test="${registered}">
            <div class="alert alert-success">Registration successful! Please sign in with your credentials.</div>
        </c:if>
        <c:if test="${loggedOut}">
            <div class="alert alert-info">You have been logged out.</div>
        </c:if>

        <div id="authAlert" class="alert alert-error" style="display: none;"></div>

        <form id="loginForm" onsubmit="handleLogin(event)">
            <input type="hidden" id="redirectUrl" value="${redirect}">

            <div class="form-group">
                <label for="email">Email Address</label>
                <input type="email" id="email" name="email" required placeholder="you@example.com" autocomplete="email">
            </div>

            <div class="form-group">
                <label for="password">Password</label>
                <input type="password" id="password" name="password" required placeholder="••••••••" autocomplete="current-password">
            </div>

            <button type="submit" id="loginBtn" class="btn btn-primary btn-block">Sign In</button>
        </form>

        <p class="auth-footer">
            Don't have an account?
            <a href="${pageContext.request.contextPath}/register<c:if test='${not empty redirect}'>?redirect=${redirect}</c:if>">Create one here</a>
        </p>
    </div>
</div>

<script>
async function handleLogin(e) {
    e.preventDefault();
    const btn = document.getElementById('loginBtn');
    const alertBox = document.getElementById('authAlert');
    const email = document.getElementById('email').value.trim();
    const password = document.getElementById('password').value;
    const redirectUrl = document.getElementById('redirectUrl').value;
    const contextPath = document.querySelector('meta[name="context-path"]')?.getAttribute('content') || '';

    alertBox.style.display = 'none';
    btn.disabled = true;
    btn.textContent = 'Signing in...';

    try {
        const response = await fetch(contextPath + '/api/auth/login', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ email, password })
        });

        const data = await response.json();

        if (response.ok) {
            localStorage.setItem('ft_token', data.token);
            localStorage.setItem('ft_user', JSON.stringify({
                userId: data.userId,
                email: data.email,
                fullName: data.fullName,
                role: data.role
            }));

            // Redirect back to intended page or home
            window.location.href = redirectUrl && redirectUrl !== '' ? redirectUrl : (contextPath + '/');
        } else {
            alertBox.textContent = data.message || 'Invalid email or password.';
            alertBox.style.display = 'block';
        }
    } catch (err) {
        alertBox.textContent = 'Network error: ' + err.message;
        alertBox.style.display = 'block';
    } finally {
        btn.disabled = false;
        btn.textContent = 'Sign In';
    }
}
</script>

<%@ include file="common/footer.jsp" %>
