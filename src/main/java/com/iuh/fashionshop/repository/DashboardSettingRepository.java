package com.iuh.fashionshop.repository;

import com.iuh.fashionshop.model.DashboardSetting;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface DashboardSettingRepository extends JpaRepository<DashboardSetting, Long> {
    Optional<DashboardSetting> findFirstByOrderByUpdatedAtDesc();

    Optional<DashboardSetting> findFirstByTargetMonthAndTargetYearOrderByUpdatedAtDesc(Integer targetMonth, Integer targetYear);

    List<DashboardSetting> findAllByTargetYearOrderByTargetMonthAsc(Integer targetYear);
}
