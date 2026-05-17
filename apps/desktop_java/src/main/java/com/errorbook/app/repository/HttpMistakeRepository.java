package com.errorbook.app.repository;

import com.errorbook.app.model.Mistake;
import com.errorbook.app.model.Stats;
import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;

import java.io.IOException;
import java.lang.reflect.Type;
import java.net.URI;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.util.List;

public class HttpMistakeRepository implements MistakeRepository {
    private static final Type MISTAKE_LIST_TYPE = new TypeToken<List<Mistake>>() {}.getType();

    private final String baseUrl;
    private final HttpClient client;
    private final Gson gson = new Gson();

    public HttpMistakeRepository(String baseUrl) {
        this(baseUrl, HttpClient.newHttpClient());
    }

    public HttpMistakeRepository(String baseUrl, HttpClient client) {
        this.baseUrl = baseUrl;
        this.client = client;
    }

    @Override
    public List<Mistake> query(String keyword, String category) throws Exception {
        String url = baseUrl + "/mistakes?keyword=" + enc(keyword) + "&category=" + enc(category);
        return gson.fromJson(send(HttpRequest.newBuilder(uri(url)).GET().build()), MISTAKE_LIST_TYPE);
    }

    @Override
    public Mistake save(Mistake mistake) throws Exception {
        normalize(mistake);
        String json = gson.toJson(mistake);
        HttpRequest.Builder builder;
        if (mistake.getId().isBlank()) {
            builder = HttpRequest.newBuilder(uri(baseUrl + "/mistakes")).POST(HttpRequest.BodyPublishers.ofString(json));
        } else {
            builder = HttpRequest.newBuilder(uri(baseUrl + "/mistakes/" + enc(mistake.getId()))).PUT(HttpRequest.BodyPublishers.ofString(json));
        }
        String body = send(builder.header("Content-Type", "application/json").build());
        return normalize(gson.fromJson(body, Mistake.class));
    }

    @Override
    public void delete(String id) throws Exception {
        send(HttpRequest.newBuilder(uri(baseUrl + "/mistakes/" + enc(id))).DELETE().build());
    }

    @Override
    public Mistake randomOne() throws Exception {
        String body = send(HttpRequest.newBuilder(uri(baseUrl + "/mistakes/random")).GET().build());
        if (body == null || body.trim().equals("null")) return null;
        return normalize(gson.fromJson(body, Mistake.class));
    }

    @Override
    public void recordReview(String id, String status) throws Exception {
        Mistake mistake = randomOne();
        List<Mistake> all = all();
        for (Mistake item : all) {
            if (item.getId().equals(id)) {
                mistake = item;
                break;
            }
        }
        if (mistake == null || !mistake.getId().equals(id)) return;
        mistake.recordReview(status);
        save(mistake);
    }

    @Override
    public Stats stats() throws Exception {
        return gson.fromJson(send(HttpRequest.newBuilder(uri(baseUrl + "/stats")).GET().build()), Stats.class);
    }

    private String send(HttpRequest request) throws IOException, InterruptedException {
        HttpResponse<String> response = client.send(request, HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
        if (response.statusCode() / 100 != 2) {
            throw new IOException("HTTP " + response.statusCode() + " from " + request.uri());
        }
        return response.body();
    }

    private URI uri(String url) {
        return URI.create(url);
    }

    private String enc(String value) {
        return URLEncoder.encode(value == null ? "" : value, StandardCharsets.UTF_8);
    }

    private Mistake normalize(Mistake mistake) {
        if (mistake == null) return null;
        mistake.setId(mistake.getId());
        mistake.setQuestion(mistake.getQuestion());
        mistake.setWrongAnswer(mistake.getWrongAnswer());
        mistake.setCorrectAnswer(mistake.getCorrectAnswer());
        mistake.setReason(mistake.getReason());
        mistake.setCategory(mistake.getCategory());
        mistake.setQuestionImagePath(mistake.getQuestionImagePath());
        mistake.setWrongAnswerImagePath(mistake.getWrongAnswerImagePath());
        mistake.setCorrectAnswerImagePath(mistake.getCorrectAnswerImagePath());
        mistake.setTags(mistake.getTags());
        mistake.setMasteryStatus(mistake.getMasteryStatus());
        mistake.setReviewCount(mistake.getReviewCount());
        mistake.setCreatedAt(mistake.getCreatedAt());
        mistake.setUpdatedAt(mistake.getUpdatedAt());
        mistake.setLastReviewedAt(mistake.getLastReviewedAt());
        return mistake;
    }
}
