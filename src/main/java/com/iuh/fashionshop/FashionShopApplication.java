package com.iuh.fashionshop;

import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.builder.SpringApplicationBuilder;
import org.springframework.context.annotation.Bean;

import java.awt.Desktop;
import java.awt.GraphicsEnvironment;
import java.net.URI;

@SpringBootApplication
public class FashionShopApplication {

	public static void main(String[] args) {
		boolean isHeadless = GraphicsEnvironment.isHeadless()
				|| System.getenv("PORT") != null
				|| System.getenv("RENDER") != null
				|| "true".equalsIgnoreCase(System.getProperty("java.awt.headless"));

		new SpringApplicationBuilder(FashionShopApplication.class)
				.headless(isHeadless)
				.run(args);
	}

	@Bean
	public CommandLineRunner openBrowser() {
		return args -> {
			try {
				if (!GraphicsEnvironment.isHeadless()
						&& Desktop.isDesktopSupported()
						&& Desktop.getDesktop().isSupported(Desktop.Action.BROWSE)) {
					Desktop.getDesktop().browse(new URI("http://localhost:8080/login"));
				}
			} catch (Throwable t) {
				// Môi trường headless / Docker / Cloud không hỗ trợ mở trình duyệt tự động
			}
		};
	}
}