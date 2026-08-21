package com.keito.calendar_backend;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import java.time.LocalDateTime;

@SpringBootApplication
public class CalendarBackendApplication {
	public static void main(String[] args) {
		SpringApplication.run(CalendarBackendApplication.class, args);
	}

	@Bean
	CommandLineRunner initDatabase(EventRepository repository) {
		return args -> {
			if(repository.count() == 0) {
				LocalDateTime startDateTime = LocalDateTime.of(2026, 3, 29,21,0);
				DailyEvent testEvent = new DailyEvent("Project Start",
					"",
					startDateTime,
					startDateTime.plusHours(1),
					"Task",
					false,
					false
				);
			repository.save(testEvent);
			System.out.println(">>> Sample Event Saved to Database!");
			}
		};
	}
}
