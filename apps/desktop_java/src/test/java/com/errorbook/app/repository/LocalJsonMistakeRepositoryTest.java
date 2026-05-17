package com.errorbook.app.repository;

import com.errorbook.app.model.Mistake;
import com.errorbook.app.model.Stats;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

class LocalJsonMistakeRepositoryTest {
    @TempDir
    Path tempDir;

    @Test
    void importsSeedThenSupportsCrudFiltersAndReviewStats() throws Exception {
        Path seed = tempDir.resolve("seed.json");
        Files.writeString(seed, """
                [
                  {
                    "id": "m1",
                    "question": "二分边界",
                    "wrongAnswer": "left < right",
                    "correctAnswer": "left <= right",
                    "reason": "最后一个元素会漏掉",
                    "category": "算法",
                    "tags": ["二分"]
                  }
                ]
                """, StandardCharsets.UTF_8);

        LocalJsonMistakeRepository repository =
                new LocalJsonMistakeRepository(tempDir.resolve("desktop.json"), seed);

        List<Mistake> imported = repository.all();
        assertEquals(1, imported.size());
        assertEquals("算法", imported.get(0).getCategory());
        assertEquals(Mistake.STATUS_NEW, imported.get(0).getMasteryStatus());

        Mistake added = new Mistake();
        added.setQuestion("空指针");
        added.setCategory("");
        added.setTags(List.of("Java"));
        repository.save(added);

        assertEquals(2, repository.all().size());
        assertEquals(1, repository.query("java", "全部分类").size());
        assertEquals("未分类", repository.query("空指针", "全部分类").get(0).getCategory());

        repository.recordReview(added.getId(), Mistake.STATUS_MASTERED);
        Mistake reviewed = repository.query("空指针", "全部分类").get(0);
        assertEquals(Mistake.STATUS_MASTERED, reviewed.getMasteryStatus());
        assertEquals(1, reviewed.getReviewCount());
        assertNotNull(reviewed.getLastReviewedAt());

        Stats stats = repository.stats();
        assertEquals(2, stats.getTotal());
        assertEquals(1, stats.getByStatus().get("已掌握"));

        repository.delete(added.getId());
        assertEquals(1, repository.all().size());
    }
}
