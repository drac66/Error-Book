package com.errorbook.app.repository;

import com.errorbook.app.model.Mistake;
import com.errorbook.app.model.Stats;
import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.google.gson.reflect.TypeToken;

import java.io.IOException;
import java.lang.reflect.Type;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.Instant;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import java.util.concurrent.ThreadLocalRandom;
import java.util.stream.Collectors;

public class LocalJsonMistakeRepository implements MistakeRepository {
    private static final Type MISTAKE_LIST_TYPE = new TypeToken<List<Mistake>>() {}.getType();
    private static final String ALL_CATEGORIES = "全部分类";

    private final Gson gson = new GsonBuilder().setPrettyPrinting().create();
    private final Path dataFile;
    private final Path seedFile;

    public LocalJsonMistakeRepository() {
        this(defaultDataFile(), defaultSeedFile());
    }

    public LocalJsonMistakeRepository(Path dataFile, Path seedFile) {
        this.dataFile = dataFile;
        this.seedFile = seedFile;
    }

    @Override
    public synchronized List<Mistake> query(String keyword, String category) throws Exception {
        String q = keyword == null ? "" : keyword.trim();
        String cat = category == null ? ALL_CATEGORIES : category;
        return load().stream()
                .filter(m -> ALL_CATEGORIES.equals(cat) || m.getCategory().equals(cat))
                .filter(m -> q.isBlank() || matches(m, q))
                .collect(Collectors.toList());
    }

    @Override
    public synchronized Mistake save(Mistake mistake) throws Exception {
        List<Mistake> items = load();
        mistake.normalize();
        if (mistake.getId().isBlank()) {
            mistake.setId(UUID.randomUUID().toString());
            String now = Instant.now().toString();
            mistake.setCreatedAt(now);
            mistake.setUpdatedAt(now);
        } else {
            mistake.markUpdated();
        }
        Optional<Mistake> existing = items.stream().filter(m -> m.getId().equals(mistake.getId())).findFirst();
        existing.ifPresent(items::remove);
        items.add(0, mistake);
        persist(items);
        return mistake;
    }

    @Override
    public synchronized void delete(String id) throws Exception {
        List<Mistake> items = load();
        items.removeIf(m -> m.getId().equals(id));
        persist(items);
    }

    @Override
    public synchronized Mistake randomOne() throws Exception {
        List<Mistake> items = load();
        if (items.isEmpty()) return null;
        List<Mistake> pending = items.stream()
                .filter(m -> !Mistake.STATUS_MASTERED.equals(m.getMasteryStatus()))
                .toList();
        List<Mistake> pool = pending.isEmpty() ? items : pending;
        return pool.get(ThreadLocalRandom.current().nextInt(pool.size()));
    }

    @Override
    public synchronized void recordReview(String id, String status) throws Exception {
        List<Mistake> items = load();
        for (Mistake mistake : items) {
            if (mistake.getId().equals(id)) {
                mistake.recordReview(status);
                persist(items);
                return;
            }
        }
    }

    @Override
    public synchronized Stats stats() throws Exception {
        List<Mistake> items = load();
        Map<String, Integer> byCategory = new LinkedHashMap<>();
        Map<String, Integer> byStatus = new LinkedHashMap<>();
        for (Mistake mistake : items) {
            byCategory.merge(mistake.getCategory(), 1, Integer::sum);
            byStatus.merge(mistake.statusLabel(), 1, Integer::sum);
        }
        return new Stats(items.size(), byCategory, byStatus);
    }

    private List<Mistake> load() throws IOException {
        ensureDataFile();
        String raw = Files.readString(dataFile, StandardCharsets.UTF_8);
        List<Mistake> items = gson.fromJson(raw, MISTAKE_LIST_TYPE);
        if (items == null) items = new ArrayList<>();
        for (Mistake item : items) item.normalize();
        return items;
    }

    private void persist(List<Mistake> items) throws IOException {
        Files.createDirectories(dataFile.getParent());
        Files.writeString(dataFile, gson.toJson(items), StandardCharsets.UTF_8);
    }

    private void ensureDataFile() throws IOException {
        if (Files.exists(dataFile)) return;
        Files.createDirectories(dataFile.getParent());
        if (seedFile != null && Files.exists(seedFile)) {
            Files.copy(seedFile, dataFile);
        } else {
            Files.writeString(dataFile, "[]", StandardCharsets.UTF_8);
        }
    }

    private String haystack(Mistake m) {
        return String.join(" ",
                m.getQuestion(),
                m.getWrongAnswer(),
                m.getCorrectAnswer(),
                m.getReason(),
                m.getCategory(),
                String.join(" ", m.getTags())
        ).toLowerCase();
    }

    private boolean matches(Mistake mistake, String query) {
        String normalizedQuery = normalize(query);
        if (normalizedQuery.isBlank()) return true;

        String source = normalize(haystack(mistake));
        if (source.contains(normalizedQuery)) return true;

        String[] tokens = query.split("[\\s,，;；]+");
        List<String> normalizedTokens = new ArrayList<>();
        for (String token : tokens) {
            String t = normalize(token);
            if (!t.isBlank()) normalizedTokens.add(t);
        }
        if (normalizedTokens.size() > 1) {
            return normalizedTokens.stream().allMatch(token -> fuzzyContains(source, token));
        }

        return fuzzyContains(source, normalizedQuery);
    }

    private boolean fuzzyContains(String source, String query) {
        if (source.contains(query)) return true;
        int index = 0;
        for (int i = 0; i < source.length() && index < query.length(); i++) {
            if (source.charAt(i) == query.charAt(index)) {
                index++;
            }
        }
        return index == query.length();
    }

    private String normalize(String text) {
        return text == null ? "" : text.toLowerCase().replaceAll("\\s+", "");
    }

    private static Path defaultDataFile() {
        return Path.of(System.getProperty("user.home"), ".error-book", "desktop-mistakes.json");
    }

    private static Path defaultSeedFile() {
        Path fromDesktop = Path.of("..", "..", "backend", "mock-api", "db.json").normalize();
        if (Files.exists(fromDesktop)) return fromDesktop;
        return Path.of("backend", "mock-api", "db.json");
    }
}
