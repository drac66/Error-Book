package com.errorbook.app.service;

import com.errorbook.app.model.Mistake;
import com.errorbook.app.model.Stats;
import com.errorbook.app.repository.MistakeRepository;

import java.util.List;

public class MistakeService {
    private final MistakeRepository repository;

    public MistakeService(MistakeRepository repository) {
        this.repository = repository;
    }

    public List<Mistake> all() {
        try {
            return repository.all();
        } catch (Exception ignored) {
            return List.of();
        }
    }

    public List<Mistake> query(String keyword, String category) {
        try {
            return repository.query(keyword, category);
        } catch (Exception ignored) {
            return List.of();
        }
    }

    public Mistake addOrUpdate(Mistake mistake) {
        try {
            return repository.save(mistake);
        } catch (Exception ignored) {
            return mistake;
        }
    }

    public void delete(String id) {
        try {
            repository.delete(id);
        } catch (Exception ignored) {
        }
    }

    public Mistake randomOne() {
        try {
            return repository.randomOne();
        } catch (Exception ignored) {
            return null;
        }
    }

    public void recordReview(String id, String status) {
        try {
            repository.recordReview(id, status);
        } catch (Exception ignored) {
        }
    }

    public Stats stats() {
        try {
            Stats stats = repository.stats();
            return stats == null ? Stats.empty() : stats;
        } catch (Exception ignored) {
            return Stats.empty();
        }
    }
}
