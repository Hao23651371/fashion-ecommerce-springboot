package com.iuh.fashionshop.model.enums;

public enum Role {
    ADMIN("Quản trị viên"),
    CUSTOMER("Khách hàng");

    private final String label;

    Role(String label) {
        this.label = label;
    }

    public String getLabel() {
        return label;
    }
}
