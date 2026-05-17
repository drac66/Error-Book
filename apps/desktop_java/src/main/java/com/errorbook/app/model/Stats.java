package com.errorbook.app.model;

import java.util.LinkedHashMap;
import java.util.Map;

public class Stats {
    private int total;
    private Map<String, Integer> byCategory = new LinkedHashMap<>();
    private Map<String, Integer> byStatus = new LinkedHashMap<>();

    public Stats() {}

    public Stats(int total, Map<String, Integer> byCategory) {
        this(total, byCategory, new LinkedHashMap<>());
    }

    public Stats(int total, Map<String, Integer> byCategory, Map<String, Integer> byStatus) {
        this.total = total;
        this.byCategory = byCategory == null ? new LinkedHashMap<>() : new LinkedHashMap<>(byCategory);
        this.byStatus = byStatus == null ? new LinkedHashMap<>() : new LinkedHashMap<>(byStatus);
    }

    public static Stats empty() {
        return new Stats(0, new LinkedHashMap<>(), new LinkedHashMap<>());
    }

    public int getTotal() {
        return total;
    }

    public Map<String, Integer> getByCategory() {
        return byCategory == null ? new LinkedHashMap<>() : byCategory;
    }

    public Map<String, Integer> getByStatus() {
        return byStatus == null ? new LinkedHashMap<>() : byStatus;
    }
}
