package com.flashticket.auth;

public enum Role {
    ROLE_USER,
    ROLE_ORGANIZER,
    ROLE_ADMIN;

    public static final String USER = "ROLE_USER";
    public static final String ORGANIZER = "ROLE_ORGANIZER";
    public static final String ADMIN = "ROLE_ADMIN";

    public static Role fromString(String roleStr) {
        if (roleStr == null || roleStr.isBlank()) {
            return ROLE_USER;
        }
        String normalized = roleStr.trim().toUpperCase();
        if (!normalized.startsWith("ROLE_")) {
            normalized = "ROLE_" + normalized;
        }
        try {
            return Role.valueOf(normalized);
        } catch (IllegalArgumentException e) {
            return ROLE_USER;
        }
    }
}
