package com.keito.calendar_backend;

import org.springframework.web.bind.annotation.*;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

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
        String seriesId = UUID.randomUUID().toString();
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
            repeatedEvent.setSeriesId(seriesId);
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

    @DeleteMapping("/future/{id}")
    public void deleteFutureEvents(@PathVariable Long id){
        DailyEvent targetEvent = repository.findById(id).orElse(null);
        if(targetEvent == null) return;
        if(targetEvent.getSeriesId() != null && !targetEvent.getSeriesId().isEmpty()){
            String seriesId = targetEvent.getSeriesId();
            repository.deleteBySeriesIdAndStartTimeGreaterThanEqual(
                seriesId, 
                targetEvent.getStartTime()
            );
            java.util.List<DailyEvent> remainingEvents = repository.findBySeriesId(seriesId);
            if(remainingEvents.size() >= 1){
                DailyEvent lastEvent = remainingEvents.get(remainingEvents.size() - 1);
                lastEvent.setIsRepeating(false);
                lastEvent.setRepeatType(null);
                repository.save(lastEvent);
            }
            repository.deleteById(id);
        }
    }

    @PutMapping("/{id}")
    public List<DailyEvent> updateEvent(@PathVariable Long id, @RequestBody DailyEvent updatedEvent){
        DailyEvent existingEvent = repository.findById(id).orElse(null);
        if(existingEvent == null){
            updatedEvent.setId(id);
            List<DailyEvent> list = new ArrayList<>();
            list.add(repository.save(updatedEvent));
            return list;
        }
        if(existingEvent.getSeriesId() != null && !existingEvent.getSeriesId().isEmpty()){
            repository.deleteBySeriesIdAndStartTimeGreaterThanEqual(
                existingEvent.getSeriesId(),
                existingEvent.getStartTime()
            );
        }else{
            repository.deleteById(id);
        }
        String seriesId = (existingEvent.getSeriesId() != null && !existingEvent.getSeriesId().isEmpty())
            ? existingEvent.getSeriesId()
            : UUID.randomUUID().toString();
        LocalDateTime currentStartTime = updatedEvent.getStartTime();
        LocalDateTime currentEndTime = updatedEvent.getEndTime();
        LocalDateTime repeatEndDate = updatedEvent.getRepeatEndDate();
        String repeatType = updatedEvent.getRepeatType();
        int maxCount = 1000;
        for(int i=0; i<maxCount; i++){
            if(repeatEndDate != null && currentStartTime.isAfter(repeatEndDate)){
                break;
            }
            DailyEvent repeatedEvent = new DailyEvent(
                updatedEvent.getTitle(),
                updatedEvent.getDescription(),
                currentStartTime,
                currentEndTime,
                updatedEvent.getEventType,
                updatedEvent.getIsAllDay(),
                true
            );
            repeatedEvent.setRepeatType(repeatType);
            repeatEvent.setSeriesId(seriesId);
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

    @PostMapping("/batch")
    public List<DailyEvent> createEvents(@RequestBody List<DailyEvent> events) {
        return repository.saveAll(events);
    }
}
