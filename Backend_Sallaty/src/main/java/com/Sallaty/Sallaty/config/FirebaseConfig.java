package com.Sallaty.Sallaty.config;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import org.springframework.context.annotation.Configuration;
import jakarta.annotation.PostConstruct;
import java.io.FileInputStream;
import java.io.IOException;

@Configuration
public class FirebaseConfig {

    @PostConstruct
    public void initialize() {
        try {
            // Mettre le fichier JSON dans src/main/resources/
            FileInputStream serviceAccount =
                new FileInputStream(
                    "src/main/resources/firebase-service-account.json");

            FirebaseOptions options = FirebaseOptions.builder()
                .setCredentials(
                    GoogleCredentials.fromStream(serviceAccount))
                .build();

            if (FirebaseApp.getApps().isEmpty()) {
                FirebaseApp.initializeApp(options);
                System.out.println("Firebase initialized ✅");
            }

        } catch (IOException e) {
            System.err.println(
                "Firebase init error: " + e.getMessage());
        }
    }
}