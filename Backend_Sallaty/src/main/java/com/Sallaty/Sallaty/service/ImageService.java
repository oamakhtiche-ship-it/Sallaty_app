package com.Sallaty.Sallaty.service;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Arrays;
import java.util.List;
import java.util.UUID;

import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

@Service
public class ImageService {

    // ═══════════════════════════════════════════════
    //  VARIABLES
    // ═══════════════════════════════════════════════
    private final String UPLOAD_DIR = "uploads/profiles/";

    private final List<String> ALLOWED_EXTENSIONS =
        Arrays.asList("jpg", "jpeg", "png", "webp");

    private final long MAX_SIZE = 5 * 1024 * 1024; // 5MB

    // ═══════════════════════════════════════════════
    //  validateImage()
    // ═══════════════════════════════════════════════
    public boolean validateImage(MultipartFile image) {

        // 1. Image vide ?
        if (image == null || image.isEmpty())
            return false;

        // 2. Trop grande ?
        if (image.getSize() > MAX_SIZE)
            return false;

        // 3. Extension valide ?
        String extension = getExtension(
            image.getOriginalFilename());
        return ALLOWED_EXTENSIONS.contains(
            extension.toLowerCase());
    }

    // ═══════════════════════════════════════════════
    //  saveImage()
    // ═══════════════════════════════════════════════
    public String saveImage(
            MultipartFile image, int userId) {

        // 1. Valider l'image
        if (!validateImage(image))
            throw new IllegalArgumentException(
                "Image invalide ! (max 5MB, formats: jpg/jpeg/png/webp)");

        try {
            // 2. Créer le dossier si inexistant
            File dir = new File(UPLOAD_DIR);
            if (!dir.exists()) dir.mkdirs();

            // 3. Supprimer l'ancienne image
            deleteOldImage(userId);

            // 4. Générer un nom unique
            String extension = getExtension(
                image.getOriginalFilename());
            String fileName = userId + "_"
                + UUID.randomUUID() + "." + extension;

            // 5. Sauvegarder le fichier
            Path path = Paths.get(UPLOAD_DIR + fileName);
            Files.write(path, image.getBytes());

            return UPLOAD_DIR + fileName;

        } catch (IOException e) {
            throw new RuntimeException(
                "Erreur sauvegarde image : "
                + e.getMessage());
        }
    }

    // ═══════════════════════════════════════════════
    //  deleteOldImage()
    // ═══════════════════════════════════════════════
    public void deleteOldImage(int userId) {

        File dir = new File(UPLOAD_DIR);
        if (!dir.exists()) return;

        File[] files = dir.listFiles();
        if (files == null) return;

        for (File file : files) {
            if (file.getName().startsWith(userId + "_")) {
                file.delete();
            }
        }
    }

    // ═══════════════════════════════════════════════
    //  getExtension()  — private
    // ═══════════════════════════════════════════════
    private String getExtension(String fileName) {
        if (fileName == null || !fileName.contains("."))
            throw new IllegalArgumentException(
                "Fichier sans extension !");
        return fileName.substring(
            fileName.lastIndexOf(".") + 1);
    }
}
