package com.Sallaty.Sallaty.security;

import com.Sallaty.Sallaty.model.Client;
import com.Sallaty.Sallaty.model.Role;
import com.Sallaty.Sallaty.model.User;
import com.Sallaty.Sallaty.repository.ClientRepository;
import com.Sallaty.Sallaty.repository.UserRepository;
import com.Sallaty.Sallaty.service.RoleService;

import org.springframework.security.oauth2.client.userinfo.DefaultOAuth2UserService;
import org.springframework.security.oauth2.client.userinfo.OAuth2UserRequest;
import org.springframework.security.oauth2.core.user.OAuth2User;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.Map;

@Service
public class CustomGoogleOAuth2UserService
        extends DefaultOAuth2UserService {

    // ═══════════════════════════════════════════════
    //  DEPENDENCIES
    // ═══════════════════════════════════════════════
    private final UserRepository userRepository;
    private final ClientRepository clientRepository;
    private final RoleService roleService;

    public CustomGoogleOAuth2UserService(
            UserRepository userRepository,
            ClientRepository clientRepository,
            RoleService roleService) {
        this.userRepository   = userRepository;
        this.clientRepository = clientRepository;
        this.roleService      = roleService;
    }

    // ═══════════════════════════════════════════════
    //  loadUser()
    // ═══════════════════════════════════════════════
    @Override
    public OAuth2User loadUser(
            OAuth2UserRequest userRequest) {

        OAuth2User oauth2User =
            super.loadUser(userRequest);

        Map<String, Object> attrs =
            oauth2User.getAttributes();

        // 1. Extraire données Google
        String firstName =
            (String) attrs.get("given_name");
        String lastName  =
            (String) attrs.get("family_name");
        String email     =
            (String) attrs.get("email");

        // 2. Vérifier si user existe
        User user = userRepository
            .findByContact(email)
            .orElse(null);

        // 3. Si user n'existe pas → créer
        if (user == null) {

            user = new User();
            user.setFirstName(firstName);
            user.setSurname(lastName);
            user.setContact(email);
            user.setAccountType(User.gmailext);
            user.setAccountState(User.ACTIVE);
            user.setNbOffer(0);
            user.setNbOrder(0);
            user.setBalance(0.0);
            user.setDateTime(LocalDateTime.now());

            User savedUser =
                userRepository.save(user);

            // 4. Assigner rôle CLIENT
            roleService.assignRole(
                savedUser.getId(), Role.CLIENT);

            // 5. Créer objet Client
            Client client = new Client();
            client.setId(savedUser.getId());
            client.setNbReservations(0);
            client.setNbCancellations(0);
            client.setTotalSpent(0);
            clientRepository.save(client);
        }

        return oauth2User;
    }
}