package com.errorbook.app.repository;

import com.errorbook.app.model.Mistake;
import com.errorbook.app.model.Stats;
import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpServer;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.io.IOException;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import static org.junit.jupiter.api.Assertions.*;

class HttpMistakeRepositoryTest {
    private HttpServer server;
    private HttpMistakeRepository repository;
    private ExecutorService executor;
    private String lastQuery;

    @BeforeEach
    void setUp() throws Exception {
        server = HttpServer.create(new InetSocketAddress("127.0.0.1", 0), 0);
        server.createContext("/mistakes", this::handleMistakes);
        server.createContext("/mistakes/random", this::handleRandom);
        server.createContext("/stats", this::handleStats);
        executor = Executors.newSingleThreadExecutor();
        server.setExecutor(executor);
        server.start();
        repository = new HttpMistakeRepository("http://127.0.0.1:" + server.getAddress().getPort());
    }

    @AfterEach
    void tearDown() {
        server.stop(0);
        executor.shutdownNow();
    }

    @Test
    void queryEncodesFiltersAndParsesMistakes() throws Exception {
        List<Mistake> mistakes = repository.query("二分", "算法");

        assertEquals(1, mistakes.size());
        assertEquals("m001", mistakes.get(0).getId());
        assertEquals("算法", mistakes.get(0).getCategory());
        assertTrue(lastQuery.contains("keyword=%E4%BA%8C%E5%88%86"));
        assertTrue(lastQuery.contains("category=%E7%AE%97%E6%B3%95"));
    }

    @Test
    void savePostsNewMistakesAndNormalizesResponse() throws Exception {
        Mistake input = new Mistake();
        input.setQuestion("空指针");

        Mistake saved = repository.save(input);

        assertEquals("created", saved.getId());
        assertEquals("未分类", saved.getCategory());
        assertNotNull(saved.getTags());
    }

    @Test
    void parsesRandomAndStats() throws Exception {
        assertEquals("m001", repository.randomOne().getId());

        Stats stats = repository.stats();
        assertEquals(1, stats.getTotal());
        assertEquals(1, stats.getByCategory().get("算法"));
    }

    private void handleMistakes(HttpExchange exchange) throws IOException {
        lastQuery = exchange.getRequestURI().getRawQuery();
        if ("GET".equals(exchange.getRequestMethod())) {
            respond(exchange, 200, "[{\"id\":\"m001\",\"question\":\"二分\",\"wrongAnswer\":\"\",\"correctAnswer\":\"\",\"reason\":\"边界\",\"category\":\"算法\",\"tags\":[\"二分\"],\"questionImagePath\":\"\",\"wrongAnswerImagePath\":\"\",\"correctAnswerImagePath\":\"\"}]");
            return;
        }
        respond(exchange, 201, "{\"id\":\"created\",\"question\":\"空指针\",\"wrongAnswer\":\"\",\"correctAnswer\":\"\",\"reason\":\"\",\"category\":\"未分类\",\"tags\":[],\"questionImagePath\":\"\",\"wrongAnswerImagePath\":\"\",\"correctAnswerImagePath\":\"\"}");
    }

    private void handleRandom(HttpExchange exchange) throws IOException {
        respond(exchange, 200, "{\"id\":\"m001\",\"question\":\"二分\",\"wrongAnswer\":\"\",\"correctAnswer\":\"\",\"reason\":\"边界\",\"category\":\"算法\",\"tags\":[]}");
    }

    private void handleStats(HttpExchange exchange) throws IOException {
        respond(exchange, 200, "{\"total\":1,\"byCategory\":{\"算法\":1}}");
    }

    private void respond(HttpExchange exchange, int status, String body) throws IOException {
        byte[] bytes = body.getBytes(StandardCharsets.UTF_8);
        exchange.getResponseHeaders().add("Content-Type", "application/json; charset=utf-8");
        exchange.sendResponseHeaders(status, bytes.length);
        exchange.getResponseBody().write(bytes);
        exchange.close();
    }
}
