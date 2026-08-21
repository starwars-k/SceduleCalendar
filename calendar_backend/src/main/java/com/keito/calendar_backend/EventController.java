package com.keito.calendar_backend;

import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/events")
public class EventController {
    private final EventRepository repository;

    public EventController(EventRepository repository) {
        this.repository = repository;
    }

    @GetMapping
    public List<DailyEvent> getAllEvents() {
        return repository.findAll();
    }

    @PostMapping
    public DailyEvent createEvent(@RequestBody DailyEvent event) {
        return repository.save(event);
    }

    @DeleteMapping("/{id}")
    public void deleteEvent(@PathVariable Long id){
        repository.deleteById(id);
    }

    @PutMapping("/{id}")
    public DailyEvent updateEvent(@PathVariable Long id, @RequestBody DailyEvent updatedEvent){
        return repository.findById(id)
            .map(event -> {
                event.setTitle(updatedEvent.getTitle());
                event.setDescription(updatedEvent.getDescription());
                event.setStartTime(updatedEvent.getStartTime());
                event.setEndTime(updatedEvent.getEndTime());
                event.setEventType(updatedEvent.getEventType());
                event.setIsAllDay(updatedEvent.getIsAllDay());
                event.setIsRepeating(updatedEvent.getIsRepeating());
                return repository.save(event);
            })
            .orElseGet(() -> {
                updatedEvent.setId(id);
                return repository.save(updatedEvent);
            });
    }

    @PostMapping("/batch")
    public List<DailyEvent> createEvents(@RequestBody List<DailyEvent> events) {
        return repository.saveAll(events);
    }
}
