package com.iuh.fashionshop;

import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.builder.SpringApplicationBuilder;
import org.springframework.context.annotation.Bean;

import java.awt.Desktop;
import java.net.URI;

@SpringBootApplication
public class FashionShopApplication {

	public static void main(String[] args) {
		new SpringApplicationBuilder(FashionShopApplication.class)
				.headless(false)   // quan trọng: cho phép dùng Desktop API
				.run(args);
	}

	@Bean
	public CommandLineRunner openBrowser() {
		return args -> {
			if (Desktop.isDesktopSupported()
					&& Desktop.getDesktop().isSupported(Desktop.Action.BROWSE)) {
				Desktop.getDesktop().browse(new URI("http://localhost:8080/login"));
			}
		};
	}
}