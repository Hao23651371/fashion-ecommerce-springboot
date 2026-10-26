package com.iuh.fashionshop.repository;

import com.iuh.fashionshop.model.Account;
import com.iuh.fashionshop.model.enums.AccountStatus;
import com.iuh.fashionshop.model.enums.Role;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface AccountRepository extends JpaRepository<Account, Long>, JpaSpecificationExecutor<Account> {
    Optional<Account> findByEmail(String email);
    boolean existsByEmail(String email);
    long countByStatus(AccountStatus status);
    long countByRole(Role role);
}
