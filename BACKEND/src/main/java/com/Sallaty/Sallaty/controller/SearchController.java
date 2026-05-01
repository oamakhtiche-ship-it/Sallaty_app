package com.Sallaty.Sallaty.controller;

import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.Sallaty.Sallaty.service.SearchService;

@RestController
@RequestMapping("/api/search")
public class SearchController {

    @Autowired
    private SearchService searchService;

    // ═══════════════════════════════════════════════
    //  GET /api/search — PUBLIC
    //  ✅ GPS params (lat, lng, distance) ajoutés
    //  Exemples :
    //  GET /api/search?q=alger
    //  GET /api/search?q=pain&wilaya=Alger&minPrice=10
    //  GET /api/search?q=fish&categoryType=FISH
    //  GET /api/search?lat=36.7&lng=3.0&distance=5
    // ═══════════════════════════════════════════════
    @GetMapping
    public ResponseEntity<?> search(
            @RequestParam(required = false) String q,
            @RequestParam(required = false) String wilaya,
            @RequestParam(required = false) Double minPrice,
            @RequestParam(required = false) Double maxPrice,
            @RequestParam(required = false) String categoryType,
            @RequestParam(required = false) Double lat,
            @RequestParam(required = false) Double lng,
            @RequestParam(required = false) Double distance) {

        return ResponseEntity.ok(
            searchService.searchWithFilters(
                q, wilaya, minPrice, maxPrice,
                categoryType, lat, lng, distance));
    }
}