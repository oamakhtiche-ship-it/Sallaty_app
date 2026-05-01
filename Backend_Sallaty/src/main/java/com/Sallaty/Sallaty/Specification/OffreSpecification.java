package com.Sallaty.Sallaty.Specification;

import org.springframework.data.jpa.domain.Specification;

import com.Sallaty.Sallaty.model.Offre;

public class OffreSpecification {

    public static Specification<Offre> hasTitle(
            String title) {
        return (root, query, cb) ->
            title == null ? null :
            cb.like(cb.lower(root.get("title")),
                    "%" + title.toLowerCase() + "%");
    }

    public static Specification<Offre> hasWilaya(
            String wilaya) {
        return (root, query, cb) ->
            wilaya == null ? null :
            cb.equal(root.get("wilaya"), wilaya);
    }

    public static Specification<Offre> hasCategory(
            Integer categoryId) {
        return (root, query, cb) ->
            categoryId == null ? null :
            cb.equal(root.get("categoryId"), categoryId);
    }

    public static Specification<Offre> hasPriceBetween(
            Double minPrice, Double maxPrice) {
        return (root, query, cb) -> {
            if (minPrice == null && maxPrice == null)
                return null;
            if (minPrice == null)
                return cb.lessThanOrEqualTo(
                    root.get("price"), maxPrice);
            if (maxPrice == null)
                return cb.greaterThanOrEqualTo(
                    root.get("price"), minPrice);
            return cb.between(
                root.get("price"), minPrice, maxPrice);
        };
    }

    public static Specification<Offre> hasMarchandName(
        String marchandName) {
    return (root, query, cb) -> {
        if (marchandName == null) return null;

        // Sous-requête sur la table users
        jakarta.persistence.criteria.Subquery<Integer> subquery =
            query.subquery(Integer.class);
        jakarta.persistence.criteria.Root<com.Sallaty.Sallaty.model.User> userRoot =
            subquery.from(com.Sallaty.Sallaty.model.User.class);

        subquery.select(userRoot.get("id"))
            .where(cb.or(
                cb.like(cb.lower(userRoot.get("firstName")),
                    "%" + marchandName.toLowerCase() + "%"),
                cb.like(cb.lower(userRoot.get("surname")),
                    "%" + marchandName.toLowerCase() + "%")
            ));

        return root.get("marchandId").in(subquery);
    };
}

    // ✅ ACTIVE = dispo avec stock
// ✅ RESERVED = stock épuisé mais réservations en cours — NE PAS afficher
public static Specification<Offre> isAvailable() {
    return (root, query, cb) ->
        // ✅ seulement ACTIVE dans la search publique
        cb.equal(root.get("status"), "ACTIVE");
}
}