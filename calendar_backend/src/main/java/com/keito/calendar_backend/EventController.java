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

    @PostMapping({"", "/"})
    public List<DailyEvent> createEvent(@RequestBody DailyEvent event) {
        List<DailyEvent> eventsToSave = new ArrayList<>();
        if(!event.getIsRepeating() || event.getRepeatType() == null){
            eventsToSave.add(repository.save(event));
            return eventsToSave;
        }
        LocalDateTime currentStartTime = event.getStartTime();
        LocalDateTime currentEndTime = event.getEndTime();
        LocalDateTime repeatEndOn = event.getRepeatEndOn();
        String repeatType = event.getRepeatType();

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
            repeatedEvent.setRepeatType(repeatType);
            eventsToSave.add(repeatedEvent);

            if("Daily".equalsIgnoreCase(repeatType)){
                currentStartTime = currentStartTime.plusDays(1);
                currentEndTime = currentEndTime.plusDays(1);
            }else if("Weekly".equalsIgnoreCase(repeatType)){
                currentStartTime = currentStartTime.plusWeeks(1);
                currentEndTime = currentEndTime.plusWeeks(1);
            }else if("Biweekly".equalsIgnoreCase(repeatType)){
                currentStartTime = currentStartTime.plusWeeks(2);
                currentEndTime = currentEndTime.plusWeeks(2);
            }else if("monthly".equalsIgnoreCase(repeatType)){
                currentStartTime = currentStartTime.plusMonths(1);
                currentEndTime = currentEndTime.plusMonths(1);
                break;
            }else if("yearly".equalsIgnoreCase(repeatType)){
                currentStartTime = currentStartTime.plusYears(1);
                currentEndTime = currentEndTime.plusYears(1);
            }else{
                break;
            }
        }
        return repository.saveAll(eventsToSave);
    }
        
    @DeleteMapping("/{id}")
    public void deleteEvent(@PathVariable Long id){
        repository.deleteById(id);
    }

    @PutMapping("/{id}")
    public DailyEvent updateEvent(@PathVariable Long id, @RequestBody DailyEvent updatedEvent){
        return repository.findById(id)
            .map(existingEvent -> {
                existingEvent.setTitle(updatedEvent.getTitle());
                existingEvent.setDescription(updatedEvent.getDescription());
                existingEvent.setStartTime(updatedEvent.getStartTime());
                existingEvent.setEndTime(updatedEvent.getEndTime());
                existingEvent.setEventType(updatedEvent.getEventType());
                existingEvent.setIsAllDay(updatedEvent.getIsAllDay());
                existingEvent.setIsRepeating(updatedEvent.getIsRepeating());
                existingEvent.setRepeatType(updatedEvent.getRepeatType());
                existingEvent.setRepeatEndOn(updatedEvent.getRepeatEndOn());
                existingEvent.setEndOn(updatedEvent.getEndOn());
                return repository.save(existingEvent);
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
