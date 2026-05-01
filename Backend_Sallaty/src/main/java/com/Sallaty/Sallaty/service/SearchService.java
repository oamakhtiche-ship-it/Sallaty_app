package com.Sallaty.Sallaty.service;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

import org.springframework.stereotype.Service;

import com.Sallaty.Sallaty.Dto.MarchandSearchDTO;
import com.Sallaty.Sallaty.Dto.OffreDTO;
import com.Sallaty.Sallaty.model.CategoryType;

import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;

@Service
public class SearchService {

    @PersistenceContext
    private EntityManager entityManager;

    @SuppressWarnings("unchecked")
    public Map<String, Object> search(
            String query,
            String wilayaFilter,
            Double minPrice,
            Double maxPrice,
            String categoryTypeFilter) {

        // ✅ query est maintenant OPTIONNEL
        String q = (query != null && !query.trim().isEmpty())
            ? "%" + query.trim().toLowerCase() + "%"
            : null;

        StringBuilder sqlOffre = new StringBuilder(
            "SELECT o.id, o.marchand_id, o.category_type, " +
            "o.title, o.description, o.price, o.quantity, " +
            "o.wilaya, o.photo, o.status, o.original_price, " +
            "o.discount_price, o.expire_at, o.nb_reservations, " +
            "o.nb_favoris, o.created_at " +
            "FROM offres o " +
            "WHERE o.status IN ('ACTIVE', 'RESERVED') ");

        // ✅ filtre texte optionnel
        if (q != null) {
            sqlOffre.append(
                "AND (" +
                "  LOWER(o.title)            LIKE :q " +
                "  OR LOWER(o.wilaya)        LIKE :q " +
                "  OR LOWER(o.status)        LIKE :q " +
                "  OR LOWER(o.category_type) LIKE :q " +
                "  OR CAST(o.price AS CHAR)  LIKE :q " +
                ") ");
        }

        if (wilayaFilter != null && !wilayaFilter.isEmpty())
            sqlOffre.append("AND LOWER(o.wilaya) = LOWER(:wilaya) ");
        if (minPrice != null)
            sqlOffre.append("AND o.price >= :minPrice ");
        if (maxPrice != null)
            sqlOffre.append("AND o.price <= :maxPrice ");
        if (categoryTypeFilter != null && !categoryTypeFilter.isEmpty())
            sqlOffre.append("AND o.category_type = :categoryType ");

        sqlOffre.append("ORDER BY o.created_at DESC");

        var offreQuery = entityManager.createNativeQuery(sqlOffre.toString());

        // ✅ setParameter seulement si non null
        if (q != null) offreQuery.setParameter("q", q);
        if (wilayaFilter != null && !wilayaFilter.isEmpty())
            offreQuery.setParameter("wilaya", wilayaFilter);
        if (minPrice != null)
            offreQuery.setParameter("minPrice", minPrice);
        if (maxPrice != null)
            offreQuery.setParameter("maxPrice", maxPrice);
        if (categoryTypeFilter != null && !categoryTypeFilter.isEmpty())
            offreQuery.setParameter("categoryType", categoryTypeFilter.toUpperCase());

        List<OffreDTO> offres =
            ((List<Object[]>) offreQuery.getResultList())
                .stream()
                .map(this::rowToOffreDTO)
                .collect(Collectors.toList());

        // ✅ marchands — aussi optionnel
        List<MarchandSearchDTO> marchands = List.of();
        if (q != null) {
            marchands = ((List<Object[]>) entityManager
                .createNativeQuery(
                    "SELECT m.user_id, m.business_name, " +
                    "m.full_name, u.profile_image, " +
                    "m.business_type, u.wilaya, " +
                    "m.nb_followers, " +
                    "m.status_marchand, " +
                    "(SELECT COUNT(*) FROM offres o2 " +
                    " WHERE o2.marchand_id = m.user_id) AS nb_offres " +
                    "FROM marchands m " +
                    "JOIN users u ON u.id = m.user_id " +
                    "WHERE m.status_marchand = 'VERIFIED' " +
                    "AND (" +
                    "  LOWER(m.business_name) LIKE :q " +
                    "  OR LOWER(m.full_name)  LIKE :q " +
                    "  OR LOWER(u.first_name) LIKE :q " +
                    "  OR LOWER(u.surname)    LIKE :q " +
                    ") " +
                    "ORDER BY m.nb_followers DESC")
                .setParameter("q", q)
                .getResultList())
                .stream()
                .map(this::rowToMarchandDTO)
                .collect(Collectors.toList());
        }

        return Map.of("offres", offres, "marchands", marchands);
    }

    @SuppressWarnings("unchecked")
    public Map<String, Object> searchWithFilters(
            String query,
            String wilayaFilter,
            Double minPrice,
            Double maxPrice,
            String categoryTypeFilter,
            Double userLat,
            Double userLng,
            Double distanceKm) {

        // ✅ query OPTIONNEL
        String q = (query != null && !query.trim().isEmpty())
            ? "%" + query.trim().toLowerCase() + "%"
            : null;

        StringBuilder sqlOffre = new StringBuilder(
            "SELECT o.id, o.marchand_id, " +
            "o.category_type, o.title, " +
            "o.description, o.price, o.quantity, " +
            "o.wilaya, o.photo, o.status, " +
            "o.original_price, o.discount_price, " +
            "o.expire_at, o.nb_reservations, " +
            "o.nb_favoris, o.created_at ");

        if (userLat != null && userLng != null) {
            sqlOffre.append(
                ", (6371 * ACOS(GREATEST(-1, LEAST(1, " +
                "COS(RADIANS(:lat)) * " +
                "COS(RADIANS(u.latitude)) * " +
                "COS(RADIANS(u.longitude) - RADIANS(:lng)) + " +
                "SIN(RADIANS(:lat)) * " +
                "SIN(RADIANS(u.latitude))" +
                ")))) AS distance ");
        }

        if (userLat != null && userLng != null) {
            sqlOffre.append(
                "FROM offres o " +
                "JOIN users u ON u.id = o.marchand_id " +
                "WHERE o.status IN ('ACTIVE', 'RESERVED') ");
        } else {
            sqlOffre.append(
                "FROM offres o " +
                "WHERE o.status IN ('ACTIVE', 'RESERVED') ");
        }

        // ✅ filtre texte optionnel
        if (q != null) {
            sqlOffre.append(
                "AND (" +
                "  LOWER(o.title)            LIKE :q " +
                "  OR LOWER(o.wilaya)        LIKE :q " +
                "  OR LOWER(o.status)        LIKE :q " +
                "  OR LOWER(o.category_type) LIKE :q " +
                "  OR CAST(o.price AS CHAR)  LIKE :q " +
                ") ");
        }

        if (wilayaFilter != null && !wilayaFilter.isEmpty())
            sqlOffre.append("AND LOWER(o.wilaya) = LOWER(:wilaya) ");
        if (minPrice != null)
            sqlOffre.append("AND o.price >= :minPrice ");
        if (maxPrice != null)
            sqlOffre.append("AND o.price <= :maxPrice ");
        if (categoryTypeFilter != null && !categoryTypeFilter.isEmpty())
            sqlOffre.append("AND o.category_type = :categoryType ");

        if (userLat != null && userLng != null && distanceKm != null) {
            sqlOffre.append(
                "HAVING distance <= :distanceKm " +
                "ORDER BY distance ASC");
        } else {
            sqlOffre.append("ORDER BY o.created_at DESC");
        }

        var offreQuery = entityManager.createNativeQuery(sqlOffre.toString());

        if (q != null) offreQuery.setParameter("q", q);
        if (userLat != null && userLng != null) {
            offreQuery.setParameter("lat", userLat);
            offreQuery.setParameter("lng", userLng);
        }
        if (wilayaFilter != null && !wilayaFilter.isEmpty())
            offreQuery.setParameter("wilaya", wilayaFilter);
        if (minPrice != null)
            offreQuery.setParameter("minPrice", minPrice);
        if (maxPrice != null)
            offreQuery.setParameter("maxPrice", maxPrice);
        if (categoryTypeFilter != null && !categoryTypeFilter.isEmpty())
            offreQuery.setParameter("categoryType", categoryTypeFilter.toUpperCase());
        if (userLat != null && userLng != null && distanceKm != null)
            offreQuery.setParameter("distanceKm", distanceKm);

        List<OffreDTO> offres =
            ((List<Object[]>) offreQuery.getResultList())
                .stream()
                .map(this::rowToOffreDTO)
                .collect(Collectors.toList());

        // ── Marchands ──────────────────────────────────────────────
        List<MarchandSearchDTO> marchands = List.of();
        if (q != null) {
            StringBuilder sqlMarchand = new StringBuilder(
                "SELECT m.user_id, m.business_name, " +
                "m.full_name, u.profile_image, " +
                "m.business_type, u.wilaya, " +
                "m.nb_followers, " +
                "m.status_marchand, " +
                "(SELECT COUNT(*) FROM offres o2 " +
                " WHERE o2.marchand_id = m.user_id) AS nb_offres ");

            if (userLat != null && userLng != null) {
                sqlMarchand.append(
                    ", (6371 * ACOS(GREATEST(-1, LEAST(1, " +
                    "COS(RADIANS(:lat)) * " +
                    "COS(RADIANS(u.latitude)) * " +
                    "COS(RADIANS(u.longitude) - RADIANS(:lng)) + " +
                    "SIN(RADIANS(:lat)) * " +
                    "SIN(RADIANS(u.latitude))" +
                    ")))) AS distance ");
            }

            sqlMarchand.append(
                "FROM marchands m " +
                "JOIN users u ON u.id = m.user_id " +
                "WHERE m.status_marchand = 'VERIFIED' " +
                "AND (" +
                "  LOWER(m.business_name) LIKE :q " +
                "  OR LOWER(m.full_name)  LIKE :q " +
                "  OR LOWER(u.first_name) LIKE :q " +
                "  OR LOWER(u.surname)    LIKE :q " +
                ") ");

            if (userLat != null && userLng != null && distanceKm != null) {
                sqlMarchand.append(
                    "HAVING distance <= :distanceKm " +
                    "ORDER BY distance ASC");
            } else {
                sqlMarchand.append("ORDER BY m.nb_followers DESC");
            }

            var marchandQuery = entityManager.createNativeQuery(sqlMarchand.toString());
            marchandQuery.setParameter("q", q);
            if (userLat != null && userLng != null) {
                marchandQuery.setParameter("lat", userLat);
                marchandQuery.setParameter("lng", userLng);
            }
            if (userLat != null && userLng != null && distanceKm != null)
                marchandQuery.setParameter("distanceKm", distanceKm);

            marchands = ((List<Object[]>) marchandQuery.getResultList())
                .stream()
                .map(this::rowToMarchandDTO)
                .collect(Collectors.toList());
        }

        return Map.of("offres", offres, "marchands", marchands);
    }

    // ── rowToOffreDTO ─────────────────────────────────────────────
    private OffreDTO rowToOffreDTO(Object[] row) {
        OffreDTO dto = new OffreDTO();
        dto.setId(((Number) row[0]).intValue());
        dto.setMarchandId(((Number) row[1]).intValue());
        dto.setCategoryType(row[2] != null
            ? CategoryType.valueOf((String) row[2]) : null);
        dto.setTitle((String) row[3]);
        dto.setDescription((String) row[4]);
        dto.setPrice(row[5] != null ? ((Number) row[5]).doubleValue() : 0.0);
        dto.setQuantity(row[6] != null ? ((Number) row[6]).intValue() : 0);
        dto.setWilaya((String) row[7]);
        dto.setPhoto((String) row[8]);
        dto.setStatus((String) row[9]);
        dto.setOriginalPrice(row[10] != null ? ((Number) row[10]).doubleValue() : 0.0);
        dto.setDiscountPrice(row[11] != null ? ((Number) row[11]).doubleValue() : 0.0);
        dto.setExpireAt(row[12] != null
            ? ((java.sql.Timestamp) row[12]).toLocalDateTime() : null);
        dto.setNbReservations(row[13] != null ? ((Number) row[13]).intValue() : 0);
        dto.setNbFavoris(row[14] != null ? ((Number) row[14]).intValue() : 0);
        dto.setCreatedAt(row[15] != null
            ? ((java.sql.Timestamp) row[15]).toLocalDateTime() : null);
        return dto;
    }

    // ── rowToMarchandDTO ──────────────────────────────────────────
    private MarchandSearchDTO rowToMarchandDTO(Object[] row) {
        return new MarchandSearchDTO(
            ((Number) row[0]).intValue(),
            (String) row[1],
            (String) row[2],
            (String) row[3],
            (String) row[4],
            (String) row[5],
            row[6] != null ? ((Number) row[6]).intValue() : 0,
            (String) row[7],
            row[8] != null ? ((Number) row[8]).intValue() : 0);
    }
}