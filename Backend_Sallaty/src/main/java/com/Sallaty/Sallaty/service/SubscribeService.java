package com.Sallaty.Sallaty.service;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.Sallaty.Sallaty.model.Notification.NotificationType;
import com.Sallaty.Sallaty.model.Subscribe;
import com.Sallaty.Sallaty.repository.SubscribeRepository;
import com.Sallaty.Sallaty.repository.UserRepository;

@Service
public class SubscribeService {

    @Autowired
    private SubscribeRepository subscribeRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private NotificationService notificationService;

    // ═══════════════════════════════════════════════
    //  subscribe()
    // ═══════════════════════════════════════════════
    public Subscribe subscribe(int userId, int marchandId) {

        if (!userRepository.existsById(userId))
            throw new RuntimeException("User non trouvé !");

        if (!userRepository.existsById(marchandId))
            throw new RuntimeException("Marchand non trouvé !");

        if (subscribeRepository.existsByUserIdAndMarchandId(userId, marchandId))
            throw new RuntimeException("Déjà abonné !");

        Subscribe subscribe = new Subscribe(userId, marchandId);
        Subscribe saved = subscribeRepository.save(subscribe);

        notificationService.sendNotification(
            marchandId,
            "Nouvel abonné 🔔",
            "Un utilisateur vient de s'abonner à votre boutique.",
            NotificationType.NEW_SUBSCRIBER);

        return saved;
    }

    // ═══════════════════════════════════════════════
    //  unsubscribe() ✅ @Transactional ajouté
    // ═══════════════════════════════════════════════
    @Transactional
    public void unsubscribe(int userId, int marchandId) {

        if (!subscribeRepository.existsByUserIdAndMarchandId(userId, marchandId))
            throw new RuntimeException("Abonnement non trouvé !");

        subscribeRepository.deleteByUserIdAndMarchandId(userId, marchandId);
    }

    // ═══════════════════════════════════════════════
    //  getMySubscriptions()
    // ═══════════════════════════════════════════════
    public List<Subscribe> getMySubscriptions(int userId) {

        if (!userRepository.existsById(userId))
            throw new RuntimeException("User non trouvé !");

        return subscribeRepository.findByUserId(userId);
    }

    // ═══════════════════════════════════════════════
    //  getSubscribers()
    // ═══════════════════════════════════════════════
    public List<Subscribe> getSubscribers(int marchandId) {

        if (!userRepository.existsById(marchandId))
            throw new RuntimeException("Marchand non trouvé !");

        return subscribeRepository.findByMarchandId(marchandId);
    }

    // ═══════════════════════════════════════════════
    //  isSubscribed()
    // ═══════════════════════════════════════════════
    public boolean isSubscribed(int userId, int marchandId) {
        return subscribeRepository.existsByUserIdAndMarchandId(userId, marchandId);
    }

    // ═══════════════════════════════════════════════
    //  countSubscribers()
    // ═══════════════════════════════════════════════
    public int countSubscribers(int marchandId) {
        return subscribeRepository.countByMarchandId(marchandId);
    }
}