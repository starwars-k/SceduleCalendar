package com.keito.calendar_backend;

import org.springframework.web.bind.annotation.*;
import java.time.LocalDateTime;
import java.util.ArrayList;
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
        List<DailyEvent> eventsToSave = new ArrayList<>();
        if(!event.getIsRepeating() || event.getRepeatType() == null){
            eventsToSave.add(repository.save(event));
            return eventsToSave;
        }
        LocalDateTime currentStartTime = event.getStartTime();
        LocalDateTime currentEndTime = event.getEndTime();
        LocalDateTime repeatEndOn = event.getRepeatEndOn();
        int maxCount = 1000; // Limit to prevent infinite loops
        for(int i = 0; i < maxCount; i++){
            if(repeatEndOn != null && currentStartTime.isAfter(repeatEndOn)){
                break;
            }
            DailyEvent repeatedEvent = new DailyEvent(
                event.getTitle(),
                event.getDescription(),
                currentStartTime,
                currentEndTime,
                event.getEventType(),
                event.getIsAllDay(),
                true
            );
            repeatedEvent.setRepeatType(event.getRepeatType());
            eventsToSave.add(repeatedEvent);

            switch(event.getRepeatType().toLowerCase()){
                case "daily":
                    currentStartTime = currentStartTime.plusDays(1);
                    currentEndTime = currentEndTime.plusDays(1);
                    break;
                case "weekly":
                    currentStartTime = currentStartTime.plusWeeks(1);
                    currentEndTime = currentEndTime.plusWeeks(1);
                    break;
                case "biweekly":
                    currentStartTime = currentStartTime.plusWeeks(2);
                    currentEndTime = currentEndTime.plusWeeks(2);
                    break;
                case "monthly":
                    currentStartTime = currentStartTime.plusMonths(1);
                    currentEndTime = currentEndTime.plusMonths(1);
                    break;
                case "yearly":
                    currentStartTime = currentStartTime.plusYears(1);
                    currentEndTime = currentEndTime.plusYears(1);
                    break;
                default:
                    i = maxCount;
                    break;
            }
        }
        return repository.saveAll(eventsToSave);
    }
        
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
