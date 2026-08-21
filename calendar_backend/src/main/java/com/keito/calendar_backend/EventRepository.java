package com.keito.calendar_backend;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.transaction.annotation.Transactional;
import java.time.LocalDateTime;
//import org.springframework.stereotype.Repository;

//@Repository
public interface EventRepository extends JpaRepository<DailyEvent, Long> {
    @Transactional
    void deleteBySeriesIdAndStartTimeGreaterThanEqual(String seriesId, LocalDateTime startTime);
    java.util.List<DailyEvent> findBySeriesIdAndStartTimeGreaterThanEqual(String seriesId);
}
