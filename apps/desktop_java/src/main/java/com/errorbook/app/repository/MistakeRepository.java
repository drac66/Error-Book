package com.errorbook.app.repository;

import com.errorbook.app.model.Mistake;
import com.errorbook.app.model.Stats;

import java.util.List;

public interface MistakeRepository {
    List<Mistake> query(String keyword, String category) throws Exception;
    Mistake save(Mistake mistake) throws Exception;
    void delete(String id) throws Exception;
    Mistake randomOne() throws Exception;
    void recordReview(String id, String status) throws Exception;
    Stats stats() throws Exception;

    default List<Mistake> all() throws Exception {
        return query("", "全部分类");
    }
}
