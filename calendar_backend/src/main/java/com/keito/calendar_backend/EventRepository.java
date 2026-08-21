package com.keito.calendar_backend;

import org.springframework.data.jpa.repository.JpaRepository;
//import org.springframework.stereotype.Repository;

//@Repository
public interface EventRepository extends JpaRepository<DailyEvent, Long> {
    
}
