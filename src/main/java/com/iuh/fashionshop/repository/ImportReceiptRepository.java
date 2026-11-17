package com.iuh.fashionshop.repository;

import com.iuh.fashionshop.model.ImportReceipt;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface ImportReceiptRepository extends JpaRepository<ImportReceipt, Long> {

    Optional<ImportReceipt> findByReceiptCode(String receiptCode);
}
