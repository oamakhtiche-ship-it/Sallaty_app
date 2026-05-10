package com.Sallaty.Sallaty.service;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import com.Sallaty.Sallaty.model.Notification.NotificationType;
import com.Sallaty.Sallaty.model.Offre;
import com.Sallaty.Sallaty.model.OffreFavori;
import com.Sallaty.Sallaty.repository.OffreFavoriRepository;
import com.Sallaty.Sallaty.repository.OffreRepository;
import com.Sallaty.Sallaty.repository.UserRepository;

@Service
public class OffreFavoriService {

    // ═══════════════════════════════════════════════
    //  DEPENDENCIES
    // ═══════════════════════════════════════════════
    @Autowired
    private OffreFavoriRepository offreFavoriRepository;

    @Autowired
    private OffreRepository offreRepository;

    @Autowired
    private UserRepository userRepository;

    // ➕ Notification
    @Autowired
    private NotificationService notificationService;

    // ═══════════════════════════════════════════════
    //  toggleFavori()
    //  ❤️ / 🤍 — ajouter ou retirer
    // ═══════════════════════════════════════════════
    @Transactional
public boolean toggleFavori(int userId, int offreId) {

    if (!userRepository.existsById(userId))
        throw new RuntimeException("User not found !");

    Offre offre = offreRepository
        .findById(offreId)
        .orElseThrow(() ->
            new RuntimeException("Offre not found !"));

    if (offreFavoriRepository.existsByUserIdAndOffreId(userId, offreId)) {

        // ─── RETIRER ───
        offreFavoriRepository
            .deleteByUserIdAndOffreId(userId, offreId);

        if (offre.getNbFavoris() > 0)
            offre.setNbFavoris(offre.getNbFavoris() - 1);
        offreRepository.save(offre);

        return false; // 🤍

    } else {

        // ─── AJOUTER ───
        offreFavoriRepository.save(
            new OffreFavori(userId, offreId));

        offre.setNbFavoris(offre.getNbFavoris() + 1);
        offreRepository.save(offre);

        notificationService.sendNotification(
            offre.getMarchandId(),
            "\r\n" + //
                                "New favorite ❤️",
            "\r\n" + //
                                "A user has added your offer \"" +
            offre.getTitle() + "\" \r\n" + //
                                "to his favorites.",
            NotificationType.NEW_FAVORITE);

        return true; // ❤️
    }
}

    // ═══════════════════════════════════════════════
    //  getMyFavoris()
    //  voir toutes mes offres favorites
    // ═══════════════════════════════════════════════
    public List<OffreFavori> getMyFavoris(
            int userId) {

        if (!userRepository.existsById(userId))
            throw new RuntimeException(
                "User not found !");

        return offreFavoriRepository
            .findByUserId(userId);
    }

    // ═══════════════════════════════════════════════
    //  isFavori()
    //  ❤️ rouge ou 🤍 gris
    // ═══════════════════════════════════════════════
    public boolean isFavori(
            int userId, int offreId) {

        return offreFavoriRepository
            .existsByUserIdAndOffreId(
                userId, offreId);
    }

    // ═══════════════════════════════════════════════
    //  countFavoris()
    //  nombre total de favoris d'une offre
    // ═══════════════════════════════════════════════
    public int countFavoris(int offreId) {
        return offreFavoriRepository
            .countByOffreId(offreId);
    }
}