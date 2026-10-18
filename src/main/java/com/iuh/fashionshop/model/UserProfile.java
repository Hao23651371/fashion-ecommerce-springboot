package com.iuh.fashionshop.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "user_profile")
@Getter
@Setter
@NoArgsConstructor
public class UserProfile {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "full_name", nullable = false, length = 100)
    private String fullName;

    @Column(name = "phone_number", length = 15)
    private String phoneNumber;

    @Column(name = "birth_date")
    private LocalDate birthDate;

    @OneToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "account_id", nullable = false, unique = true)
    private Account account;

    @OneToMany(mappedBy = "userProfile", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<ShippingAddress> addresses = new ArrayList<>();

    public void addAddress(ShippingAddress address) {
        address.setUserProfile(this);
        if (addresses.isEmpty()) {
            address.setDefaultAddress(true);
        }
        addresses.add(address);
    }

    public void setDefaultAddress(Long addressId) {
        for (ShippingAddress a : addresses) {
            a.setDefaultAddress(a.getId() != null && a.getId().equals(addressId));
        }
    }

    public void removeAddress(Long addressId) {
        ShippingAddress toRemove = addresses.stream()
                .filter(a -> a.getId() != null && a.getId().equals(addressId))
                .findFirst()
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy địa chỉ"));
        boolean wasDefault = toRemove.isDefaultAddress();
        addresses.remove(toRemove);
        if (wasDefault && !addresses.isEmpty()) {
            addresses.get(addresses.size() - 1).setDefaultAddress(true);
        }
    }
}
