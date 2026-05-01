package com.Sallaty.Sallaty.service;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.Sallaty.Sallaty.model.FaqItem;
import com.Sallaty.Sallaty.model.StaticContent;
import com.Sallaty.Sallaty.repository.FaqItemRepository;
import com.Sallaty.Sallaty.repository.StaticContentRepository;

@Service
public class StaticService {

    @Autowired
    private StaticContentRepository staticContentRepository;

    @Autowired
    private FaqItemRepository faqItemRepository;

    // ═══════════════════════════════════════════════
    //  CONSTANTS
    // ═══════════════════════════════════════════════
    private static final String PRIVACY = "PRIVACY_POLICY";
    private static final String ABOUT   = "ABOUT";
    private static final String TERMS   = "TERMS_CONDITIONS";

    // ═══════════════════════════════════════════════
    //  HELPER — pages statiques
    // ═══════════════════════════════════════════════
    private String getContent(String type) {
        return staticContentRepository
            .findByType(type)
            .map(StaticContent::getContent)
            .orElse("Contenu non disponible.");
    }

    private void updateContent(String type, String newContent) {
        StaticContent content = staticContentRepository
            .findByType(type)
            .orElse(new StaticContent(type, ""));
        content.setContent(newContent);
        staticContentRepository.save(content);
    }

    // ═══════════════════════════════════════════════
    //  GET — pages statiques
    // ═══════════════════════════════════════════════
    public String getPrivacyPolicy()   { return getContent(PRIVACY); }
    public String getAbout()           { return getContent(ABOUT); }
    public String getTermsConditions() { return getContent(TERMS); }

    // ═══════════════════════════════════════════════
    //  UPDATE pages statiques — Admin seulement
    // ═══════════════════════════════════════════════
    public void updatePrivacyPolicy(String content) { updateContent(PRIVACY, content); }
    public void updateAbout(String content)         { updateContent(ABOUT, content); }
    public void updateTermsConditions(String content){ updateContent(TERMS, content); }

    // ═══════════════════════════════════════════════
    //  GET HELP — toutes FAQ groupées par catégorie
    // ═══════════════════════════════════════════════
    public Map<String, List<FaqItem>> getAllFaq() {
        Map<String, List<FaqItem>> result = new LinkedHashMap<>();

        for (String category : List.of(
                FaqItem.ORDERS_DELIVERY,
                FaqItem.ACCOUNT_PROFILE,
                FaqItem.PAYMENTS,
                FaqItem.MERCHANT_SELLING,
                FaqItem.GENERAL_TROUBLESHOOTING)) {

            List<FaqItem> items = faqItemRepository
                .findByCategoryOrderByDisplayOrderAsc(category);

            if (!items.isEmpty())
                result.put(category, items);
        }
        return result;
    }

    // ═══════════════════════════════════════════════
    //  GET FAQ par catégorie
    // ═══════════════════════════════════════════════
    public List<FaqItem> getFaqByCategory(String category) {
        return faqItemRepository
            .findByCategoryOrderByDisplayOrderAsc(category);
    }

    // ═══════════════════════════════════════════════
    //  GET FAQ answer — user clique sur une question
    // ═══════════════════════════════════════════════
    public FaqItem getFaqAnswer(String category, int questionId) {

        FaqItem item = faqItemRepository.findById(questionId)
            .orElseThrow(() ->
                new RuntimeException("Question non trouvée !"));

        if (!item.getCategory().equals(category))
            throw new RuntimeException(
                "Question n'appartient pas à cette catégorie !");

        return item;
    }

    // ═══════════════════════════════════════════════
    //  ADD FAQ — Admin
    // ═══════════════════════════════════════════════
    @Transactional
    public FaqItem addFaq(String category, String question,
                          String answer, int displayOrder) {

        if (!isValidCategory(category))
            throw new IllegalArgumentException("Catégorie invalide !");

        if (question == null || question.isEmpty())
            throw new IllegalArgumentException("Question obligatoire !");

        if (answer == null || answer.isEmpty())
            throw new IllegalArgumentException("Réponse obligatoire !");

        return faqItemRepository.save(
            new FaqItem(category, question, answer, displayOrder));
    }

    // ═══════════════════════════════════════════════
    //  UPDATE FAQ — Admin
    // ═══════════════════════════════════════════════
    @Transactional
    public FaqItem updateFaq(String category, int questionId,
                             String question, String answer) {

        FaqItem item = faqItemRepository.findById(questionId)
            .orElseThrow(() ->
                new RuntimeException("Question non trouvée !"));

        if (!item.getCategory().equals(category))
            throw new RuntimeException(
                "Question n'appartient pas à cette catégorie !");

        if (question != null && !question.isEmpty())
            item.setQuestion(question);

        if (answer != null && !answer.isEmpty())
            item.setAnswer(answer);

        return faqItemRepository.save(item);
    }

    // ═══════════════════════════════════════════════
    //  DELETE FAQ — Admin
    // ═══════════════════════════════════════════════
    @Transactional
    public void deleteFaq(String category, int questionId) {

        FaqItem item = faqItemRepository.findById(questionId)
            .orElseThrow(() ->
                new RuntimeException("Question non trouvée !"));

        if (!item.getCategory().equals(category))
            throw new RuntimeException(
                "Question n'appartient pas à cette catégorie !");

        faqItemRepository.deleteById(questionId);
    }

    // ═══════════════════════════════════════════════
    //  HELPER — valider catégorie
    // ═══════════════════════════════════════════════
    private boolean isValidCategory(String category) {
        return List.of(
            FaqItem.ORDERS_DELIVERY,
            FaqItem.ACCOUNT_PROFILE,
            FaqItem.PAYMENTS,
            FaqItem.MERCHANT_SELLING,
            FaqItem.GENERAL_TROUBLESHOOTING
        ).contains(category);
    }
}