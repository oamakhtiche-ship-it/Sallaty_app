package com.Sallaty.Sallaty.repository;

import java.time.LocalDateTime;
import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import com.Sallaty.Sallaty.model.CategoryType;
import com.Sallaty.Sallaty.model.Offre;

@Repository
public interface OffreRepository
    extends JpaRepository<Offre, Integer>,
            JpaSpecificationExecutor<Offre> {

    List<Offre> findByMarchandId(int marchandId);
    List<Offre> findByWilaya(String wilaya);
    List<Offre> findByStatus(String status);
    List<Offre> findByStatusIn(List<String> statuses);

    // ✅ categoryType enum
    List<Offre> findByCategoryType(CategoryType categoryType);
    List<Offre> findByCategoryTypeAndStatus(
        CategoryType categoryType, String status);

    List<Offre> findTop20ByOrderByCreatedAtDesc();
    List<Offre> findTop10ByOrderByNbReservationsDesc();
    List<Offre> findByMarchandIdAndStatus(int marchandId, String status);
    List<Offre> findByTitleContainingIgnoreCase(String title);
    List<Offre> findByWilayaAndStatus(String wilaya, String status);
    List<Offre> findByPriceBetween(double minPrice, double maxPrice);
    List<Offre> findByPriceBetweenAndWilaya(
        double minPrice, double maxPrice, String wilaya);
    List<Offre> findByDiscountPriceGreaterThan(double price);
    List<Offre> findByStatusAndExpireAtBetween(
        String status, LocalDateTime start, LocalDateTime end);

    // ✅ search by marchand businessName — native SQL
    @Query(value =
        "SELECT o.* FROM offres o " +
        "JOIN marchands m ON o.marchand_id = m.user_id " +
        "WHERE LOWER(m.business_name) " +
        "LIKE LOWER(CONCAT('%', :businessName, '%')) " +
        "AND o.status IN ('ACTIVE', 'RESERVED')",
        nativeQuery = true)
    List<Offre> searchByBusinessName(
        @Param("businessName") String businessName);

    // ✅ search combined
    @Query(value =
        "SELECT o.* FROM offres o " +
        "JOIN marchands m ON o.marchand_id = m.user_id " +
        "WHERE " +
        "(:title IS NULL OR LOWER(o.title) LIKE LOWER(CONCAT('%', :title, '%'))) AND " +
        "(:wilaya IS NULL OR o.wilaya = :wilaya) AND " +
        "(:categoryType IS NULL OR o.category_type = :categoryType) AND " +
        "(:minPrice IS NULL OR o.price >= :minPrice) AND " +
        "(:maxPrice IS NULL OR o.price <= :maxPrice) AND " +
        "(:businessName IS NULL OR LOWER(m.business_name) LIKE LOWER(CONCAT('%', :businessName, '%'))) AND " +
        "o.status IN ('ACTIVE', 'RESERVED')",
        nativeQuery = true)
    List<Offre> searchAndFilter(
        @Param("title")        String title,
        @Param("wilaya")       String wilaya,
        @Param("categoryType") String categoryType,
        @Param("minPrice")     Double minPrice,
        @Param("maxPrice")     Double maxPrice,
        @Param("businessName") String businessName);

    List<Offre> findByStatusInAndExpireAtBefore(
    List<String> statuses,
    LocalDateTime dateTime
);
}

