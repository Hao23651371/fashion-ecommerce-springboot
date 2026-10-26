package com.iuh.fashionshop.repository;

import com.iuh.fashionshop.model.UserProfile;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface UserProfileRepository extends JpaRepository<UserProfile, Long> {
    Optional<UserProfile> findByAccountId(Long accountId);
    Optional<UserProfile> findByAccountEmail(String email);
    Optional<UserProfile> findByAccount(com.iuh.fashionshop.model.Account account);
    Optional<UserProfile> findByPhoneNumber(String phoneNumber);
    boolean existsByPhoneNumber(String phoneNumber);
}
