package com.Sallaty.Sallaty.service;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.time.LocalDateTime;
import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import com.Sallaty.Sallaty.Dto.OffreDTO;
import com.Sallaty.Sallaty.model.CategoryType;
import com.Sallaty.Sallaty.model.Notification.NotificationType;
import com.Sallaty.Sallaty.model.Offre;
import com.Sallaty.Sallaty.repository.CategoryRepository;
import com.Sallaty.Sallaty.repository.OffreRepository;
import org.springframework.scheduling.annotation.Scheduled;

import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
@Service
public class OffreService {

    @Autowired
    private OffreRepository offreRepository;

    @Autowired
    private CategoryRepository categoryRepository;

    @Autowired
    private MarchandService marchandService;

    @Autowired
    private RoleService roleService;

    @Autowired
    private NotificationService notificationService;
    
    @PersistenceContext
    private EntityManager entityManager;



    
    
    @Transactional  // ← ajoute ça
public Offre createOffre(
        int marchandId, CategoryType categoryType,
        String title, String description,
        double price, int quantity,
        String wilaya, LocalDateTime expireAt,
        String status) {

    if (!roleService.isMarchand(marchandId))
        throw new RuntimeException("Vous n'êtes pas marchand !");
    if (title == null || title.isEmpty())
        throw new IllegalArgumentException("Titre obligatoire !");
    if (price <= 0)
        throw new IllegalArgumentException("Prix invalide !");
    if (quantity <= 0)
        throw new IllegalArgumentException("Quantité invalide !");

    Offre offre = new Offre();
    offre.setMarchandId(marchandId);
    offre.setCategoryType(categoryType);
    offre.setTitle(title);
    offre.setDescription(description);
    offre.setPrice(price);
    offre.setQuantity(quantity);
    offre.setWilaya(wilaya);
    offre.setOriginalPrice(price);
    offre.setDiscountPrice(0);
    offre.setExpireAt(expireAt);
    offre.setStatus(status != null ? status : Offre.ACTIVE);

    Offre savedOffre = offreRepository.save(offre);

    entityManager.createNativeQuery(
        "UPDATE users SET nb_offer = nb_offer + 1 WHERE id = :marchandId")
        .setParameter("marchandId", marchandId)
        .executeUpdate();

    return savedOffre;
}

// updateOffre()
public Offre updateOffre(
        int offreId, int marchandId,
        CategoryType categoryType, String title,
        String description, double price,
        int quantity, String wilaya,
        LocalDateTime expireAt, String status) {

    Offre offre = offreRepository.findById(offreId)
        .orElseThrow(() ->
            new RuntimeException("Offre non trouvée !"));

    if (offre.getMarchandId() != marchandId)
        throw new RuntimeException("Pas autorisé !");

    if (categoryType != null)
        offre.setCategoryType(categoryType);  // ✅
    if (title != null && !title.isEmpty())
        offre.setTitle(title);
    if (description != null && !description.isEmpty())
        offre.setDescription(description);
    if (price > 0) {
        offre.setPrice(price);
        offre.setOriginalPrice(price);
    }
    if (quantity > 0)
        offre.setQuantity(quantity);
    if (wilaya != null && !wilaya.isEmpty())
        offre.setWilaya(wilaya);
    if (expireAt != null)
        offre.setExpireAt(expireAt);
    if (status != null && !status.isEmpty())
        offre.setStatus(status);

    return offreRepository.save(offre);
}



    // ═══════════════════════════════════════════════
    //  archiveOffre()
    // ═══════════════════════════════════════════════
    public void archiveOffre(int offreId, int marchandId) {

        Offre offre = offreRepository.findById(offreId)
            .orElseThrow(() -> new RuntimeException("Offre non trouvée !"));

        if (offre.getMarchandId() != marchandId)
            throw new RuntimeException("Pas autorisé !");

        if (offre.getStatus().equals(Offre.ARCHIVED))
            throw new RuntimeException("Offre déjà archivée !");

        offre.setStatus(Offre.ARCHIVED);
        offreRepository.save(offre);
    }

    // ═══════════════════════════════════════════════
    //  blockOffre()
    // ═══════════════════════════════════════════════
    public void blockOffre(int offreId) {

        Offre offre = offreRepository.findById(offreId)
            .orElseThrow(() -> new RuntimeException("Offre non trouvée !"));

        if (offre.getStatus().equals(Offre.INACTIVE))
            throw new RuntimeException("Offre déjà bloquée !");

        offre.setStatus(Offre.INACTIVE);
        offreRepository.save(offre);

        notificationService.sendNotification(
            offre.getMarchandId(),
            "Offre bloquée ❌",
            "Votre offre \"" + offre.getTitle() +
            "\" a été bloquée par l'administrateur.",
            NotificationType.OFFER_BLOCKED);
    }

    // ═══════════════════════════════════════════════
    //  unblockOffre()
    // ═══════════════════════════════════════════════
    public void unblockOffre(int offreId) {

        Offre offre = offreRepository.findById(offreId)
            .orElseThrow(() -> new RuntimeException("Offre non trouvée !"));

        if (offre.getStatus().equals(Offre.ACTIVE))
            throw new RuntimeException("Offre déjà active !");

        offre.setStatus(Offre.ACTIVE);
        offreRepository.save(offre);

        notificationService.sendNotification(
            offre.getMarchandId(),
            "Offre débloquée ✅",
            "Votre offre \"" + offre.getTitle() +
            "\" a été débloquée par l'administrateur.",
            NotificationType.OFFER_BLOCKED);
    }

    // ═══════════════════════════════════════════════
    //  deleteOffre()
    // ═══════════════════════════════════════════════
    public void deleteOffre(int offreId) {
        if (!offreRepository.existsById(offreId))
            throw new RuntimeException("Offre non trouvée !");
        offreRepository.deleteById(offreId);
    }

    // ═══════════════════════════════════════════════
    //  discountOffre()
    // ═══════════════════════════════════════════════
    public Offre discountOffre(
            int marchandId, int offreId, double discountPrice) {

        Offre offre = offreRepository.findById(offreId)
            .orElseThrow(() -> new RuntimeException("Offre non trouvée !"));

        if (offre.getMarchandId() != marchandId)
            throw new RuntimeException("Pas autorisé !");

        if (discountPrice <= 0)
            throw new IllegalArgumentException("Discount price invalide !");

        if (discountPrice >= offre.getPrice())
            throw new IllegalArgumentException(
                "Discount doit être inférieur au prix !");

        offre.setOriginalPrice(offre.getPrice());
        offre.setDiscountPrice(discountPrice);

        Offre savedOffre = offreRepository.save(offre);

        notificationService.sendNotification(
            marchandId,
            "Promotion activée ✅",
            "Votre offre \"" + offre.getTitle() +
            "\" est en promotion à " + discountPrice + " DA.",
            NotificationType.NEW_DISCOUNT);

        return savedOffre;
    }

    // ═══════════════════════════════════════════════
    //  uploadOffrePhoto() ✅ avec MultipartFile
    // ═══════════════════════════════════════════════
    public String uploadOffrePhoto(
            int offreId, MultipartFile file) {

        Offre offre = offreRepository.findById(offreId)
            .orElseThrow(() -> new RuntimeException("Offre non trouvée !"));

        // Supprimer l'ancienne photo si elle existe
        if (offre.getPhoto() != null && !offre.getPhoto().isEmpty()) {
            try {
                Files.deleteIfExists(Paths.get(offre.getPhoto()));
            } catch (Exception e) {
                // ignore
            }
        }

        // Sauvegarder le nouveau fichier
        String fileName = offreId + "_" + file.getOriginalFilename();
        String uploadDir = "uploads/offres/";
        String fullPath = uploadDir + fileName;

        try {
            java.nio.file.Path path = Paths.get(fullPath);
            Files.createDirectories(path.getParent());
            Files.write(path, file.getBytes());
        } catch (IOException e) {
            throw new RuntimeException("Erreur upload photo !");
        }

        offre.setPhoto(fullPath);
        offreRepository.save(offre);

        return fullPath;
    }

    // ═══════════════════════════════════════════════
    //  deleteOffrePhoto()
    // ═══════════════════════════════════════════════
    public void deleteOffrePhoto(int offreId) {

        Offre offre = offreRepository.findById(offreId)
            .orElseThrow(() -> new RuntimeException("Offre non trouvée !"));

        if (offre.getPhoto() == null || offre.getPhoto().isEmpty())
            throw new RuntimeException("Pas de photo !");

        try {
            Files.deleteIfExists(Paths.get(offre.getPhoto()));
        } catch (Exception e) {
            // ignore
        }

        offre.setPhoto(null);
        offreRepository.save(offre);
    }

    // ═══════════════════════════════════════════════
    //  incrementReservations()
    // ═══════════════════════════════════════════════
    public void incrementReservations(int offreId) {
        Offre offre = offreRepository.findById(offreId)
            .orElseThrow(() -> new RuntimeException("Offre non trouvée !"));
        offre.setNbReservations(offre.getNbReservations() + 1);
        offreRepository.save(offre);
    }

    // ═══════════════════════════════════════════════
    //  decrementReservations()
    // ═══════════════════════════════════════════════
    public void decrementReservations(int offreId) {
        Offre offre = offreRepository.findById(offreId)
            .orElseThrow(() -> new RuntimeException("Offre non trouvée !"));
        int nb = offre.getNbReservations();
        if (nb > 0) {
            offre.setNbReservations(nb - 1);
            offreRepository.save(offre);
        }
    }

    // ═══════════════════════════════════════════════
    //  decrementQuantity()
    // ═══════════════════════════════════════════════
    // ═══════════════════════════════════════════════
//  decrementQuantity() — met à jour le status
// ═══════════════════════════════════════════════
public void decrementQuantity(int offreId, int qty) {
    Offre offre = offreRepository.findById(offreId)
        .orElseThrow(() ->
            new RuntimeException("Offre non trouvée !"));

    int newQty = offre.getQuantity() - qty;
    offre.setQuantity(Math.max(newQty, 0));

    // ✅ RÈGLE MÉTIER :
    // quantity == 0 → SOLD_OUT (ou RESERVED selon ta logique)
    // quantity > 0  → reste ACTIVE
    if (newQty <= 0) {
        offre.setQuantity(0);
        offre.setStatus("RESERVED"); // ✅ plus de stock = RESERVED
    }
    // Si quantity > 0, le statut reste ACTIVE

    offreRepository.save(offre);
}
    // ═══════════════════════════════════════════════
    //  incrementQuantity()
    // ═══════════════════════════════════════════════
    public void incrementQuantity(int offreId, int quantity) {
        Offre offre = offreRepository.findById(offreId)
            .orElseThrow(() -> new RuntimeException("Offre non trouvée !"));

        offre.setQuantity(offre.getQuantity() + quantity);

        if (offre.getStatus().equals(Offre.SOLD_OUT))
            offre.setStatus(Offre.ACTIVE);

        offreRepository.save(offre);
    }

    // ═══════════════════════════════════════════════
    //  isExpired()
    // ═══════════════════════════════════════════════
    public boolean isExpired(Offre offre) {
        if (offre.getExpireAt() == null) return false;

        if (LocalDateTime.now().isAfter(offre.getExpireAt())) {
            offre.setStatus(Offre.EXPIRED);
            offreRepository.save(offre);
            return true;
        }
        return false;
    }

    // ═══════════════════════════════════════════════
    //  checkExpiringSoon()
    // ═══════════════════════════════════════════════
    public void checkExpiringSoon() {

        LocalDateTime now   = LocalDateTime.now();
        LocalDateTime in24h = now.plusHours(24);

        List<Offre> expiringSoon = offreRepository
            .findByStatusAndExpireAtBetween(Offre.ACTIVE, now, in24h);

        for (Offre offre : expiringSoon) {
            notificationService.sendNotification(
                offre.getMarchandId(),
                "Offre expire bientôt ⏰",
                "Votre offre \"" + offre.getTitle() +
                "\" expire dans moins de 24h.",
                NotificationType.EXPIRING_SOON);
        }
    }

// searchAndFilter()
public List<Offre> searchAndFilter(
        String title, String wilaya,
        CategoryType categoryType,
        Double minPrice, Double maxPrice,
        String businessName, String sortBy) {

    String categoryStr = categoryType != null
        ? categoryType.name() : null;

    List<Offre> offres = offreRepository.searchAndFilter(
        title, wilaya, categoryStr,
        minPrice, maxPrice, businessName);

    if (sortBy == null) return offres;

    switch (sortBy) {
        case "date" -> offres.sort((a, b) ->
            b.getCreatedAt().compareTo(a.getCreatedAt()));
        case "price_asc" -> offres.sort((a, b) ->
            Double.compare(a.getPrice(), b.getPrice()));
        case "price_desc" -> offres.sort((a, b) ->
            Double.compare(b.getPrice(), a.getPrice()));
        case "reservations" -> offres.sort((a, b) ->
            Integer.compare(
                b.getNbReservations(),
                a.getNbReservations()));
    }

    return offres;
}



    // ═══════════════════════════════════════════════
    //  GET endpoints
    // ═══════════════════════════════════════════════
    public List<Offre> getAllOffres() {
        return offreRepository.findAll();
    }

    public List<Offre> getActivesAndReserved() {
        return offreRepository.findByStatusIn(
            List.of(Offre.ACTIVE, Offre.RESERVED));
    }

    public List<Offre> getOffresByMarchand(int marchandId) {
        return offreRepository.findByMarchandId(marchandId);
    }

    // getOffresByCategory()
public List<Offre> getOffresByCategory(
        CategoryType categoryType) {
    return offreRepository
        .findByCategoryType(categoryType);
}


    public List<Offre> getOffresByWilaya(String wilaya) {
        return offreRepository.findByWilaya(wilaya);
    }

    public List<Offre> getOffresByPrice(double minPrice, double maxPrice) {
        return offreRepository.findByPriceBetween(minPrice, maxPrice);
    }

    public List<Offre> getMostReservedOffres() {
        return offreRepository.findTop10ByOrderByNbReservationsDesc();
    }

    public List<Offre> getSoldOutOffres() {
        return offreRepository.findByStatus(Offre.SOLD_OUT);
    }

    public List<Offre> getArchivedOffres() {
        return offreRepository.findByStatus(Offre.ARCHIVED);
    }

    public List<Offre> getExpiredOffres() {
        return offreRepository.findByStatus(Offre.EXPIRED);
    }

    public List<Offre> getActiveOffres() {
        return offreRepository.findByStatus(Offre.ACTIVE);
    }

    public List<Offre> getInactiveOffres() {
        return offreRepository.findByStatus(Offre.INACTIVE);
    }

    public List<Offre> getRecentOffres() {
        return offreRepository.findTop20ByOrderByCreatedAtDesc();
    }

    public List<Offre> getDiscountOffres() {
        return offreRepository.findByDiscountPriceGreaterThan(0);
    }

    public Offre getOffreById(int offreId) {
        return offreRepository.findById(offreId)
            .orElseThrow(() -> new RuntimeException("Offre non trouvée !"));
    }

    // convertToDTO()
public OffreDTO convertToDTO(Offre offre) {
    return new OffreDTO(
        offre.getId(),
        offre.getMarchandId(),
        offre.getCategoryType(),    // ✅
        offre.getTitle(),
        offre.getDescription(),
        offre.getPrice(),
        offre.getQuantity(),
        offre.getWilaya(),
        offre.getStatus(),
        offre.getOriginalPrice(),
        offre.getDiscountPrice(),
        offre.getExpireAt(),
        offre.getNbReservations(),
        offre.getNbFavoris(),
        offre.getCreatedAt(),
        offre.getPhoto());          // ✅
}

// ═══════════════════════════════════════════════
//  expireOffresAutomatically()
//  Lance toutes les 60 secondes
//  Change ACTIVE/RESERVED → EXPIRED si expire_at dépassé
// ═══════════════════════════════════════════════
@Scheduled(fixedRate = 60000)
@Transactional
public void expireOffresAutomatically() {
    List<Offre> toExpire = offreRepository
        .findByStatusInAndExpireAtBefore(
            List.of(Offre.ACTIVE, Offre.RESERVED),
            LocalDateTime.now()
        );

    for (Offre offre : toExpire) {
        offre.setStatus(Offre.EXPIRED);
        offreRepository.save(offre);
        System.out.println("[OffreService] Offre #" +
            offre.getId() + " '" + offre.getTitle() +
            "' → EXPIRED");

        // ✅ Notifie le marchand
        notificationService.sendNotification(
            offre.getMarchandId(),
            "Offre expirée ⏰",
            "Votre offre \"" + offre.getTitle() +
            "\" a expiré automatiquement.",
            NotificationType.EXPIRING_SOON);
    }
}
}


