package com.Sallaty.Sallaty.model;

import jakarta.persistence.*;

@Entity
@Table(name = "faq_items")
public class FaqItem {

    public static final String ORDERS_DELIVERY          = "ORDERS_DELIVERY";
    public static final String ACCOUNT_PROFILE          = "ACCOUNT_PROFILE";
    public static final String PAYMENTS                 = "PAYMENTS";
    public static final String MERCHANT_SELLING         = "MERCHANT_SELLING";
    public static final String GENERAL_TROUBLESHOOTING  = "GENERAL_TROUBLESHOOTING";

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private int id;

    @Column(name = "category", nullable = false)
    private String category;

    @Column(name = "question", nullable = false, columnDefinition = "TEXT")
    private String question;

    @Column(name = "answer", nullable = false, columnDefinition = "TEXT")
    private String answer;

    @Column(name = "display_order")
    private int displayOrder = 0;

    public FaqItem() {}

    public FaqItem(String category, String question,
                   String answer, int displayOrder) {
        this.category     = category;
        this.question     = question;
        this.answer       = answer;
        this.displayOrder = displayOrder;
    }

    public int    getId()           { return id; }
    public String getCategory()     { return category; }
    public String getQuestion()     { return question; }
    public String getAnswer()       { return answer; }
    public int    getDisplayOrder() { return displayOrder; }

    public void setId(int id)                     { this.id = id; }
    public void setCategory(String category)      { this.category = category; }
    public void setQuestion(String question)      { this.question = question; }
    public void setAnswer(String answer)          { this.answer = answer; }
    public void setDisplayOrder(int displayOrder) { this.displayOrder = displayOrder; }
}