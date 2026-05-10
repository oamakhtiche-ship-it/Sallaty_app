package com.Sallaty.Sallaty.service;

import java.time.LocalDateTime;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.Sallaty.Sallaty.model.Otpcode;
import com.Sallaty.Sallaty.repository.OtpcodeRepository;
import com.Sallaty.Sallaty.repository.UserRepository;
import com.twilio.Twilio;
import com.twilio.rest.api.v2010.account.Message;
import com.twilio.type.PhoneNumber;

@Service
public class OtpcodeService {

    @Autowired
    private OtpcodeRepository otpcodeRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private JavaMailSender mailSender;

    @Value("${twilio.account.sid}")
    private String ACCOUNT_SID;

    @Value("${twilio.auth.token}")
    private String AUTH_TOKEN;

    @Value("${twilio.phone.number}")
    private String TWILIO_NUMBER;

    // ═══════════════════════════════════════════════
    //  generateOTP()
    // ═══════════════════════════════════════════════
    public String generateOTP() {
        int otp = (int)(Math.random() * 900000) + 100000;
        return String.valueOf(otp);
    }

    // ═══════════════════════════════════════════════
    //  sendVerifCodeSignup()
    // ═══════════════════════════════════════════════
    @Transactional
    public void sendVerifCodeSignup(
            String contact, int userId) {

        if (contact == null || contact.isEmpty())
            throw new IllegalArgumentException(
                "Mandatory contact !");

        if (!userRepository.existsById(userId))
            throw new RuntimeException(
                "User not found!");

        // 1. Générer le code
        String code = generateOTP();

        // 2. Supprimer ancien OTP ✅
        otpcodeRepository.deleteByUserId(userId);

        // 3. Sauvegarder nouveau OTP D'ABORD ✅
        Otpcode otp = new Otpcode();
        otp.setUserId(userId);
        otp.setCode(code);
        otp.setExpireAt(
            LocalDateTime.now().plusMinutes(10));
        otp.setUtilise(false);
        otpcodeRepository.save(otp);

        // 4. Envoyer APRÈS ✅
        try {
            if (validatePhoneNumberFormat(contact)) {
                sendSMS(contact, code);
            } else {
                sendEmail(contact, code);
            }
        } catch (Exception e) {
            System.err.println(
                "Erreur envoi OTP : " + e.getMessage());
        }
    }

    // ═══════════════════════════════════════════════
    //  sendVerifCodeLogin()
    // ═══════════════════════════════════════════════
    @Transactional
    public void sendVerifCodeLogin(
            String contact, int userId) {

        if (contact == null || contact.isEmpty())
            throw new IllegalArgumentException(
                "Mandatory contact!");

        if (!userRepository.existsById(userId))
            throw new RuntimeException(
                "User not found !");

        // 1. Générer le code
        String code = generateOTP();

        // 2. Supprimer ancien OTP ✅
        otpcodeRepository.deleteByUserId(userId);

        // 3. Sauvegarder nouveau OTP D'ABORD ✅
        Otpcode otp = new Otpcode();
        otp.setUserId(userId);
        otp.setCode(code);
        otp.setExpireAt(
            LocalDateTime.now().plusMinutes(10));
        otp.setUtilise(false);
        otpcodeRepository.save(otp);

        // 4. Envoyer APRÈS ✅
        try {
            if (validatePhoneNumberFormat(contact)) {
                sendSMS(contact, code);
            } else {
                sendEmail(contact, code);
            }
        } catch (Exception e) {
            System.err.println(
                "Erreur envoi OTP : " + e.getMessage());
        }
    }

    // ═══════════════════════════════════════════════
    //  verifyCode()
    // ═══════════════════════════════════════════════
    public boolean verifyCode(int userId, String code) {

        if (code == null || code.isEmpty())
            throw new IllegalArgumentException(
                "Code obligatoire !");

        Otpcode otp = otpcodeRepository
            .findByUserId(userId)
            .orElseThrow(() ->
                new RuntimeException(
                    "Code not found !"));

        if (otp.isUtilise())
            throw new RuntimeException(
                "Code aleardy used!");

        if (otp.getExpireAt()
                .isBefore(LocalDateTime.now()))
            throw new RuntimeException(
                "Code expired !");

        if (!otp.getCode().equals(code))
            return false;

        otp.setUtilise(true);
        otpcodeRepository.save(otp);

        return true;
    }

    // ═══════════════════════════════════════════════
    //  sendSMS()
    // ═══════════════════════════════════════════════
    private void sendSMS(String phone, String code) {
    try {
        // Convertir 0671428003 → +213671428003
        if (phone.startsWith("0")) {
            phone = "+213" + phone.substring(1);
        }
        
        Twilio.init(ACCOUNT_SID, AUTH_TOKEN);
        Message.creator(
            new PhoneNumber(phone),
            new PhoneNumber(TWILIO_NUMBER),
            "Sallaty: Your verification code is"
                + code + ". Valid for 10 minutes."
        ).create();
    } catch (Exception e) {
        throw new RuntimeException(
            "Erreur envoi SMS : " + e.getMessage());
    }
}

    // ═══════════════════════════════════════════════
    //  sendEmail()
    // ═══════════════════════════════════════════════
    private void sendEmail(String email, String code) {
        try {
            SimpleMailMessage message =
                new SimpleMailMessage();
            message.setTo(email);
            message.setSubject(
                "Sallaty verification code");
            message.setText(
                "Good morning,\n\n"
                + "Your verification code is :\n\n"
                + "     " + code + "\n\n"
                + "This code expires in 10 minutes.\n\n"
                + "The Sallaty team");
            mailSender.send(message);
        } catch (Exception e) {
            throw new RuntimeException(
                "Email sending error : " + e.getMessage());
        }
    }

    // ═══════════════════════════════════════════════
    //  validatePhoneNumberFormat()
    // ═══════════════════════════════════════════════
    private boolean validatePhoneNumberFormat(
            String phone) {
        if (phone == null || phone.isEmpty())
            return false;
        return phone.matches(
            "^(\\+213|0)[567][0-9]{8}$");
    }
}