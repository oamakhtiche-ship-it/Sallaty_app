package com.Sallaty.Sallaty.config;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.auth.oauth2.ServiceAccountCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import jakarta.annotation.PostConstruct;

import java.io.IOException;
import java.security.KeyFactory;
import java.security.NoSuchAlgorithmException;
import java.security.interfaces.RSAPrivateKey;
import java.security.spec.InvalidKeySpecException;
import java.security.spec.PKCS8EncodedKeySpec;
import java.util.Base64;
import java.util.Collections;

@Configuration
public class FirebaseConfig {

    @Value("${firebase.project.id:#{environment.FIREBASE_PROJECT_ID}}")
    private String projectId;

    @Value("${firebase.client.email:#{environment.FIREBASE_CLIENT_EMAIL}}")
    private String clientEmail;

    @Value("${firebase.private.key:#{environment.FIREBASE_PRIVATE_KEY}}")
    private String privateKey;

    @Value("${firebase.private.key.id:#{environment.FIREBASE_PRIVATE_KEY_ID}}")
    private String privateKeyId;

    @Value("${firebase.client.id:#{environment.FIREBASE_CLIENT_ID}}")
    private String clientId;

    @PostConstruct
    public void initialize() {
        if (FirebaseApp.getApps().isEmpty()) {
            try {
                GoogleCredentials credentials = buildCredentials();
                FirebaseOptions options = FirebaseOptions.builder()
                        .setCredentials(credentials)
                        .setProjectId(projectId)
                        .build();
                FirebaseApp.initializeApp(options);
                System.out.println("Firebase initialized ✅");
            } catch (Exception e) {
                System.err.println("Firebase init error: " + e.getMessage());
            }
        }
    }

    private GoogleCredentials buildCredentials()
            throws IOException, NoSuchAlgorithmException, InvalidKeySpecException {

        // Normalize the PEM key: environment variables often store newlines as \n literals
        String normalizedKey = privateKey
                .replace("\\n", "\n")
                .replace("-----BEGIN PRIVATE KEY-----", "")
                .replace("-----END PRIVATE KEY-----", "")
                .replaceAll("\\s+", "");

        byte[] keyBytes = Base64.getDecoder().decode(normalizedKey);
        PKCS8EncodedKeySpec keySpec = new PKCS8EncodedKeySpec(keyBytes);
        RSAPrivateKey rsaPrivateKey =
                (RSAPrivateKey) KeyFactory.getInstance("RSA").generatePrivate(keySpec);

        return ServiceAccountCredentials.newBuilder()
                .setProjectId(projectId)
                .setClientEmail(clientEmail)
                .setClientId(clientId)
                .setPrivateKeyId(privateKeyId)
                .setPrivateKey(rsaPrivateKey)
                .setScopes(Collections.singletonList(
                        "https://www.googleapis.com/auth/cloud-platform"))
                .build();
    }
}