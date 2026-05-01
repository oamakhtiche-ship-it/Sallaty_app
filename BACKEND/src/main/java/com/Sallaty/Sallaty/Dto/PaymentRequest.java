package com.Sallaty.Sallaty.Dto;

import com.Sallaty.Sallaty.model.PaymentMethod;

public class PaymentRequest {

    private int ordreId;
    private PaymentMethod method;
    private String cardNumber;
    private String expiryDate;
    private String cvv;
    private String cardholderName;
    private boolean saveCard;

    public PaymentRequest() {}

    public int getOrdreId() { return ordreId; }
    public PaymentMethod getMethod() { return method; }
    public String getCardNumber() { return cardNumber; }
    public String getExpiryDate() { return expiryDate; }
    public String getCvv() { return cvv; }
    public String getCardholderName() { return cardholderName; }
    public boolean isSaveCard() { return saveCard; }

    public void setOrdreId(int ordreId) { this.ordreId = ordreId; }
    public void setMethod(PaymentMethod method) { this.method = method; }
    public void setCardNumber(String cardNumber) { this.cardNumber = cardNumber; }
    public void setExpiryDate(String expiryDate) { this.expiryDate = expiryDate; }
    public void setCvv(String cvv) { this.cvv = cvv; }
    public void setCardholderName(String cardholderName) { this.cardholderName = cardholderName; }
    public void setSaveCard(boolean saveCard) { this.saveCard = saveCard; }
}