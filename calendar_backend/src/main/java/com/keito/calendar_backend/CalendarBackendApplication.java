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
				DailyEvent testEvent = new DailyEvent(
					"Project Start",
					"",
					startDateTime,
					startDateTime.plusHours(1),
					"Task",
					false,
					false
				);
				DailyEvent testEvent2 = new DailyEvent(
					"Backend Upload on GitHub and RENDER",
					"",
					LocalDateTime.of(2026, 8, 20, 21, 0),
					LocalDateTime.of(2026, 8, 20, 22, 0),
					"Task",
					true,
					false
				);
				repository.save(testEvent);
				repository.save(testEvent2);
				System.out.println(">>> Sample Events Saved to Database!");
			}
		};
	}
}
