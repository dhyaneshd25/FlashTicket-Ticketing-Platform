<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>FlashTicket - High Throughput Flash Sales</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&family=JetBrains+Mono:wght@400;600;700;800&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/static/css/style.css">
    <meta name="context-path" content="${pageContext.request.contextPath}">
</head>
<body>
<header class="site-header">
    <div class="header-content">
        <a class="brand" href="${pageContext.request.contextPath}/">⚡ FlashTicket</a>

        <!-- Desktop Navigation Bar (Visible on desktop > 992px) -->
        <nav class="nav-links desktop-nav" id="desktopNavLinks">
            <a href="${pageContext.request.contextPath}/" class="nav-item">Upcoming Shows</a>
            <div id="roleNavLinks" class="role-nav-links"></div>
            <div id="authNavContainer" class="auth-nav">
                <!-- Dynamically populated by JS based on login state -->
            </div>
        </nav>

        <!-- Mobile & Tablet Hamburger Toggle Button (Visible <= 992px) -->
        <button class="hamburger-btn" id="hamburgerBtn" aria-label="Toggle navigation menu" aria-expanded="false" aria-controls="mobileSidebar">
            <span class="hamburger-line"></span>
            <span class="hamburger-line"></span>
            <span class="hamburger-line"></span>
        </button>
    </div>
</header>

<!-- Mobile & Tablet Off-Canvas Sidebar Drawer & Backdrop -->
<div class="sidebar-backdrop" id="sidebarBackdrop"></div>
<aside class="mobile-sidebar" id="mobileSidebar" aria-label="Mobile Navigation Drawer">
    <div class="sidebar-header">
        <a class="brand sidebar-brand" href="${pageContext.request.contextPath}/">⚡ FlashTicket</a>
        <button class="sidebar-close-btn" id="sidebarCloseBtn" aria-label="Close navigation menu">&times;</button>
    </div>

    <!-- User / Auth Profile Card in Sidebar -->
    <div class="sidebar-user-card" id="sidebarUserCard">
        <!-- Dynamically populated by JS -->
    </div>

    <!-- Navigation Sections -->
    <div class="sidebar-nav-content">
        <div class="sidebar-nav-section">
            <div class="sidebar-section-title">NAVIGATION</div>
            <a href="${pageContext.request.contextPath}/" class="sidebar-nav-item">
                <span class="sidebar-nav-icon">🎪</span>
                <span class="sidebar-nav-text">Upcoming Shows</span>
            </a>
            <div id="sidebarUserLinks"></div>
        </div>

        <div class="sidebar-nav-section" id="sidebarManagementSection" style="display: none;">
            <div class="sidebar-section-title">MANAGEMENT</div>
            <div id="sidebarManagementLinks"></div>
        </div>

        <div class="sidebar-nav-section" id="sidebarAdminSection" style="display: none;">
            <div class="sidebar-section-title">SYSTEM ARCHITECTURE</div>
            <div id="sidebarAdminLinks"></div>
        </div>
    </div>

    <!-- Sidebar Bottom Action / Auth Footer -->
    <div class="sidebar-footer" id="sidebarFooter">
        <!-- Dynamically populated by JS -->
    </div>
</aside>

<script>
document.addEventListener('DOMContentLoaded', function() {
    initNavigation();
    initMobileSidebar();
});

function initNavigation() {
    const desktopAuthContainer = document.getElementById('authNavContainer');
    const desktopRoleNavLinks = document.getElementById('roleNavLinks');
    const sidebarUserCard = document.getElementById('sidebarUserCard');
    const sidebarUserLinks = document.getElementById('sidebarUserLinks');
    const sidebarManagementSection = document.getElementById('sidebarManagementSection');
    const sidebarManagementLinks = document.getElementById('sidebarManagementLinks');
    const sidebarAdminSection = document.getElementById('sidebarAdminSection');
    const sidebarAdminLinks = document.getElementById('sidebarAdminLinks');
    const sidebarFooter = document.getElementById('sidebarFooter');

    const contextPath = document.querySelector('meta[name="context-path"]')?.getAttribute('content') || '';
    const currentPath = encodeURIComponent(window.location.pathname);
    const storedUser = localStorage.getItem('ft_user');
    const token = localStorage.getItem('ft_token');

    if (storedUser && token) {
        try {
            const user = JSON.parse(storedUser);
            const displayName = user.fullName || user.email;
            const role = user.role || 'ROLE_USER';

            // Role formatting
            let roleBadgeClass = 'role-badge-user';
            let roleShortName = 'User';
            if (role === 'ROLE_ADMIN') {
                roleBadgeClass = 'role-badge-admin';
                roleShortName = 'Admin';
            } else if (role === 'ROLE_ORGANIZER') {
                roleBadgeClass = 'role-badge-organizer';
                roleShortName = 'Organizer';
            }

            // 1. Populate Desktop Nav
            let desktopRoleHtml = '<a href="' + contextPath + '/my-orders" class="nav-item">My Orders</a>';
            if (role === 'ROLE_ORGANIZER' || role === 'ROLE_ADMIN') {
                desktopRoleHtml += '<a href="' + contextPath + '/organizer" class="nav-item nav-organizer">Organizer Hub</a>';
            }
            if (role === 'ROLE_ADMIN') {
                desktopRoleHtml += '<a href="' + contextPath + '/admin" class="nav-item nav-admin">Admin Panel</a>';
                desktopRoleHtml += '<a href="' + contextPath + '/simulation" class="nav-item nav-simulator-pill"><span class="sim-pulse-dot"></span>🔬 Kafka &amp; Redis Simulation</a>';
            }
            if (desktopRoleNavLinks) desktopRoleNavLinks.innerHTML = desktopRoleHtml;

            if (desktopAuthContainer) {
                desktopAuthContainer.innerHTML =
                    '<span class="user-greeting">👤 ' + escapeHtml(displayName) +
                    ' <span class="badge-role ' + roleBadgeClass + '">' + roleShortName + '</span></span>' +
                    '<button onclick="handleLogout()" class="btn-sm btn-outline">Logout</button>';
            }

            // 2. Populate Mobile & Tablet Sidebar
            const userInitial = (displayName.trim()[0] || 'U').toUpperCase();
            if (sidebarUserCard) {
                sidebarUserCard.innerHTML =
                    '<div class="sidebar-avatar">' + escapeHtml(userInitial) + '</div>' +
                    '<div class="sidebar-user-details">' +
                        '<div class="sidebar-user-name">' + escapeHtml(displayName) + '</div>' +
                        '<div class="sidebar-user-email">' + escapeHtml(user.email || '') + '</div>' +
                        '<div class="sidebar-user-badge"><span class="badge-role ' + roleBadgeClass + '">' + roleShortName + '</span></div>' +
                    '</div>';
            }

            if (sidebarUserLinks) {
                sidebarUserLinks.innerHTML =
                    '<a href="' + contextPath + '/my-orders" class="sidebar-nav-item">' +
                        '<span class="sidebar-nav-icon">🎟️</span>' +
                        '<span class="sidebar-nav-text">My Orders</span>' +
                    '</a>';
            }

            let sidebarMgmtHtml = '';
            if (role === 'ROLE_ORGANIZER' || role === 'ROLE_ADMIN') {
                sidebarMgmtHtml +=
                    '<a href="' + contextPath + '/organizer" class="sidebar-nav-item sidebar-item-organizer">' +
                        '<span class="sidebar-nav-icon">📊</span>' +
                        '<span class="sidebar-nav-text">Organizer Hub</span>' +
                    '</a>';
            }
            if (role === 'ROLE_ADMIN') {
                sidebarMgmtHtml +=
                    '<a href="' + contextPath + '/admin" class="sidebar-nav-item sidebar-item-admin">' +
                        '<span class="sidebar-nav-icon">⚙️</span>' +
                        '<span class="sidebar-nav-text">Admin Panel</span>' +
                    '</a>';
            }
            if (sidebarManagementSection && sidebarManagementLinks) {
                if (sidebarMgmtHtml) {
                    sidebarManagementLinks.innerHTML = sidebarMgmtHtml;
                    sidebarManagementSection.style.display = 'block';
                } else {
                    sidebarManagementSection.style.display = 'none';
                }
            }

            if (sidebarAdminSection && sidebarAdminLinks) {
                if (role === 'ROLE_ADMIN') {
                    sidebarAdminLinks.innerHTML =
                        '<a href="' + contextPath + '/simulation" class="sidebar-nav-item sidebar-item-sim">' +
                            '<span class="sidebar-nav-icon">🔬</span>' +
                            '<span class="sidebar-nav-text">Kafka &amp; Redis Simulation</span>' +
                            '<span class="sim-pulse-dot"></span>' +
                        '</a>';
                    sidebarAdminSection.style.display = 'block';
                } else {
                    sidebarAdminSection.style.display = 'none';
                }
            }

            if (sidebarFooter) {
                sidebarFooter.innerHTML =
                    '<button onclick="handleLogout()" class="sidebar-logout-btn">' +
                        '<span>🚪</span> Log Out' +
                    '</button>' +
                    '<div class="sidebar-engine-note">⚡ FlashTicket • High Throughput</div>';
            }

            return;
        } catch (e) {
            console.error('Error rendering auth navigation:', e);
        }
    }

    // Guest / Unauthenticated State
    if (desktopRoleNavLinks) desktopRoleNavLinks.innerHTML = '';
    if (desktopAuthContainer) {
        desktopAuthContainer.innerHTML =
            '<a href="' + contextPath + '/login?redirect=' + currentPath + '" class="nav-link">Sign In</a>' +
            '<a href="' + contextPath + '/register?redirect=' + currentPath + '" class="btn-sm btn-primary">Register</a>';
    }

    if (sidebarUserCard) {
        sidebarUserCard.innerHTML =
            '<div class="sidebar-guest-card">' +
                '<div class="sidebar-guest-title">⚡ Welcome to FlashTicket</div>' +
                '<p class="sidebar-guest-sub">Experience high-throughput flash ticket sales powered by Redis and Kafka.</p>' +
            '</div>';
    }

    if (sidebarUserLinks) sidebarUserLinks.innerHTML = '';
    if (sidebarManagementSection) sidebarManagementSection.style.display = 'none';
    if (sidebarAdminSection) sidebarAdminSection.style.display = 'none';

    if (sidebarFooter) {
        sidebarFooter.innerHTML =
            '<div class="sidebar-auth-btns">' +
                '<a href="' + contextPath + '/login?redirect=' + currentPath + '" class="btn btn-outline btn-block">Sign In</a>' +
                '<a href="' + contextPath + '/register?redirect=' + currentPath + '" class="btn btn-primary btn-block">Register</a>' +
            '</div>' +
            '<div class="sidebar-engine-note">⚡ FlashTicket • High Throughput</div>';
    }
}

function initMobileSidebar() {
    const hamburgerBtn = document.getElementById('hamburgerBtn');
    const mobileSidebar = document.getElementById('mobileSidebar');
    const sidebarBackdrop = document.getElementById('sidebarBackdrop');
    const sidebarCloseBtn = document.getElementById('sidebarCloseBtn');

    if (!hamburgerBtn || !mobileSidebar || !sidebarBackdrop) return;

    function openSidebar() {
        mobileSidebar.classList.add('open');
        sidebarBackdrop.classList.add('open');
        hamburgerBtn.classList.add('active');
        hamburgerBtn.setAttribute('aria-expanded', 'true');
        document.body.style.overflow = 'hidden';
    }

    function closeSidebar() {
        mobileSidebar.classList.remove('open');
        sidebarBackdrop.classList.remove('open');
        hamburgerBtn.classList.remove('active');
        hamburgerBtn.setAttribute('aria-expanded', 'false');
        document.body.style.overflow = '';
    }

    hamburgerBtn.addEventListener('click', function(e) {
        e.stopPropagation();
        if (mobileSidebar.classList.contains('open')) {
            closeSidebar();
        } else {
            openSidebar();
        }
    });

    if (sidebarCloseBtn) {
        sidebarCloseBtn.addEventListener('click', function(e) {
            e.stopPropagation();
            closeSidebar();
        });
    }

    sidebarBackdrop.addEventListener('click', function() {
        closeSidebar();
    });

    // Close on Escape key press
    document.addEventListener('keydown', function(e) {
        if (e.key === 'Escape' && mobileSidebar.classList.contains('open')) {
            closeSidebar();
        }
    });

    // Close when navigating via any sidebar link
    mobileSidebar.querySelectorAll('a').forEach(function(link) {
        link.addEventListener('click', function() {
            closeSidebar();
        });
    });

    // Auto-close if resized to desktop width (> 992px)
    window.addEventListener('resize', function() {
        if (window.innerWidth > 992 && mobileSidebar.classList.contains('open')) {
            closeSidebar();
        }
    });
}

function escapeHtml(str) {
    if (!str) return '';
    return str.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;").replace(/'/g, "&#039;");
}

function handleLogout() {
    const contextPath = document.querySelector('meta[name="context-path"]')?.getAttribute('content') || '';
    localStorage.removeItem('ft_token');
    localStorage.removeItem('ft_user');
    window.location.href = contextPath + '/logout';
}
</script>
<main class="container">
