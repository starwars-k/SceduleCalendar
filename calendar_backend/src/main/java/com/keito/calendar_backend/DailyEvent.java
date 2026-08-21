package com.keito.calendar_backend;
import jakarta.persistence.*;
import java.time.LocalDateTime;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.annotation.JsonFormat;
@Entity
@Table(name = "daily_events")

public class DailyEvent {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    private String title;
    @JsonProperty("isAllDay")
    private boolean isAllDay;
    @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss.SSS")
    private LocalDateTime startTime;
    @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss.SSS")
    private LocalDateTime endTime;
    private boolean isRepeating;
    private String repeatType;
    private boolean endOn;
    private LocalDateTime repeatEndOn;
    private String description;
    private String eventType;
    public DailyEvent(){}
    
    public DailyEvent(String title, String description, LocalDateTime startTime, LocalDateTime endTime, String eventType, boolean isAllDay){
        this.title = title;
        this.isAllDay = isAllDay;
        this.startTime = startTime;
        this.endTime = endTime;
        this.isRepeating = false;
        this.eventType = eventType;
        this.description = description;
    }
    public DailyEvent(String title, String description, LocalDateTime startTime, LocalDateTime endTime, String eventType, boolean isAllDay, boolean isRepeating){
        this.title = title;
        this.description = description;
        this.startTime = startTime;
        this.endTime = endTime;
        this.eventType = eventType;
        this.isRepeating = isRepeating;
        this.isAllDay = isAllDay;
    }

    public Long getId() {
        return id;
    }
    public void setId(Long id) {
        this.id = id;
    }
    public String getTitle() {
        return title;
    }
    public void setTitle(String title) {
        this.title = title;
    }
    public String getDescription() {
        return description;
    }
    public void setDescription(String description) {
        this.description = description;
    }
    public LocalDateTime getStartTime() {
        return startTime;
    }
    public void setStartTime(LocalDateTime startTime) {
        this.startTime = startTime;
    }
    public LocalDateTime getEndTime() {
        return endTime;
    }
    public void setEndTime(LocalDateTime endTime) {
        this.endTime = endTime;
    }
    public String getEventType() {
        return eventType;
    }
    public void setEventType(String eventType) {
        this.eventType = eventType;
    }
    public boolean getIsRepeating(){
        return isRepeating;
    }
    public void setIsRepeating(boolean isRepeating){
        this.isRepeating = isRepeating;
    }
    public boolean getIsAllDay() {
        return isAllDay;
    }
    public void setIsAllDay(boolean isAllDay) {
        this.isAllDay = isAllDay;
    }
    public String getRepeatType(){
        return repeatType;
    }
    public void setRepeatType(String repeatType){
        this.repeatType = repeatType;
    }
    public boolean getEndOn(){
        return endOn;
    }
    public void setEndOn(boolean endOn){
        this.endOn = endOn;
    }
    public LocalDateTime getRepeatEndOn(){
        return repeatEndOn;
    }
    public void setRepeatEndOn(LocalDateTime repeatEndOn){
        this.repeatEndOn = repeatEndOn;
    }
}
