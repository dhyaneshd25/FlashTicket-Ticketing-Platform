<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ include file="common/header.jsp" %>

<div class="auth-wrapper">
    <div class="auth-card">
        <h2>Create an Account</h2>
        <p class="subtitle">Join FlashTicket to access live flash sales or publish shows.</p>

        <div id="authAlert" class="alert alert-error" style="display: none;"></div>

        <form id="registerForm" onsubmit="handleRegister(event)">
            <input type="hidden" id="redirectUrl" value="${redirect}">

            <div class="form-group">
                <label for="fullName">Full Name</label>
                <input type="text" id="fullName" name="fullName" required placeholder="Jane Doe" autocomplete="name">
            </div>

            <div class="form-group">
                <label for="email">Email Address</label>
                <input type="email" id="email" name="email" required placeholder="you@example.com" autocomplete="email">
            </div>

            <div class="form-group">
                <label for="password">Password (minimum 6 characters)</label>
                <input type="password" id="password" name="password" minlength="6" required placeholder="••••••••" autocomplete="new-password">
            </div>

            <div class="form-group">
                <label for="role">Account Type</label>
                <select id="role" name="role" class="form-select">
                    <option value="ROLE_USER">Ticket Buyer / Customer</option>
                    <option value="ROLE_ORGANIZER">Event Organizer (Publish &amp; Manage Shows)</option>
                </select>
            </div>

            <button type="submit" id="registerBtn" class="btn btn-primary btn-block">Create Account</button>
        </form>

        <p class="auth-footer">
            Already have an account?
            <a href="${pageContext.request.contextPath}/login<c:if test='${not empty redirect}'>?redirect=${redirect}</c:if>">Sign in here</a>
        </p>
    </div>
</div>

<script>
async function handleRegister(e) {
    e.preventDefault();
    const btn = document.getElementById('registerBtn');
    const alertBox = document.getElementById('authAlert');
    const fullName = document.getElementById('fullName').value.trim();
    const email = document.getElementById('email').value.trim();
    const password = document.getElementById('password').value;
    const role = document.getElementById('role').value;
    const redirectUrl = document.getElementById('redirectUrl').value;
    const contextPath = document.querySelector('meta[name="context-path"]')?.getAttribute('content') || '';

    alertBox.style.display = 'none';
    btn.disabled = true;
    btn.textContent = 'Creating account...';

    try {
        const response = await fetch(contextPath + '/api/auth/register', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ fullName, email, password, role })
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
            alertBox.textContent = data.message || 'Registration failed. Please check your details.';
            alertBox.style.display = 'block';
        }
    } catch (err) {
        alertBox.textContent = 'Network error: ' + err.message;
        alertBox.style.display = 'block';
    } finally {
        btn.disabled = false;
        btn.textContent = 'Create Account';
    }
}
</script>

<%@ include file="common/footer.jsp" %>
