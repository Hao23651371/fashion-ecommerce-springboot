package com.iuh.fashionshop.repository;

import com.iuh.fashionshop.model.ShippingAddress;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ShippingAddressRepository extends JpaRepository<ShippingAddress, Long> {

    List<ShippingAddress> findByUserProfileIdOrderByDefaultAddressDescIdDesc(Long userProfileId);

    Optional<ShippingAddress> findByUserProfileIdAndDefaultAddressTrue(Long userProfileId);

    @Modifying
    @Query("update ShippingAddress a set a.defaultAddress = false where a.userProfile.id = :profileId")
    void resetDefaultAddress(@Param("profileId") Long profileId);
}

