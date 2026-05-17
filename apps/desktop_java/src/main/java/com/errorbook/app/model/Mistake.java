package com.errorbook.app.model;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

public class Mistake {
    public static final String DEFAULT_NOTEBOOK_ID = "default";
    public static final String DEFAULT_CATEGORY = "未分类";
    public static final String STATUS_NEW = "new";
    public static final String STATUS_REVIEWING = "reviewing";
    public static final String STATUS_MASTERED = "mastered";

    private String id;
    private String notebookId = DEFAULT_NOTEBOOK_ID;
    private String question;
    private String wrongAnswer;
    private String correctAnswer;
    private String reason;
    private String category;
    private String questionImagePath = "";
    private String wrongAnswerImagePath = "";
    private String correctAnswerImagePath = "";
    private List<String> tags = new ArrayList<>();
    private String masteryStatus = STATUS_NEW;
    private int reviewCount = 0;
    private String createdAt;
    private String updatedAt;
    private String lastReviewedAt;

    public Mistake() {}

    public Mistake(String id, String question, String wrongAnswer, String correctAnswer, String reason, String category) {
        this.id = valueOrEmpty(id);
        this.question = valueOrEmpty(question);
        this.wrongAnswer = valueOrEmpty(wrongAnswer);
        this.correctAnswer = valueOrEmpty(correctAnswer);
        this.reason = valueOrEmpty(reason);
        this.category = valueOrDefault(category, DEFAULT_CATEGORY);
        String now = Instant.now().toString();
        this.createdAt = now;
        this.updatedAt = now;
        normalize();
    }

    public void normalize() {
        id = valueOrEmpty(id);
        notebookId = valueOrDefault(notebookId, DEFAULT_NOTEBOOK_ID);
        question = valueOrEmpty(question);
        wrongAnswer = valueOrEmpty(wrongAnswer);
        correctAnswer = valueOrEmpty(correctAnswer);
        reason = valueOrEmpty(reason);
        category = valueOrDefault(category, DEFAULT_CATEGORY);
        questionImagePath = valueOrEmpty(questionImagePath);
        wrongAnswerImagePath = valueOrEmpty(wrongAnswerImagePath);
        correctAnswerImagePath = valueOrEmpty(correctAnswerImagePath);
        tags = tags == null ? new ArrayList<>() : new ArrayList<>(tags);
        masteryStatus = normalizeStatus(masteryStatus);
        if (reviewCount < 0) reviewCount = 0;
        String now = Instant.now().toString();
        createdAt = valueOrDefault(createdAt, now);
        updatedAt = valueOrDefault(updatedAt, now);
        lastReviewedAt = blankToNull(lastReviewedAt);
    }

    public String getId() { return id; }
    public void setId(String id) { this.id = valueOrEmpty(id); }
    public String getNotebookId() { return notebookId; }
    public void setNotebookId(String notebookId) { this.notebookId = valueOrDefault(notebookId, DEFAULT_NOTEBOOK_ID); }
    public String getQuestion() { return question; }
    public void setQuestion(String question) { this.question = valueOrEmpty(question); }
    public String getWrongAnswer() { return wrongAnswer; }
    public void setWrongAnswer(String wrongAnswer) { this.wrongAnswer = valueOrEmpty(wrongAnswer); }
    public String getCorrectAnswer() { return correctAnswer; }
    public void setCorrectAnswer(String correctAnswer) { this.correctAnswer = valueOrEmpty(correctAnswer); }
    public String getReason() { return reason; }
    public void setReason(String reason) { this.reason = valueOrEmpty(reason); }
    public String getCategory() { return category; }
    public void setCategory(String category) { this.category = valueOrDefault(category, DEFAULT_CATEGORY); }
    public String getQuestionImagePath() { return questionImagePath; }
    public void setQuestionImagePath(String questionImagePath) { this.questionImagePath = valueOrEmpty(questionImagePath); }
    public String getWrongAnswerImagePath() { return wrongAnswerImagePath; }
    public void setWrongAnswerImagePath(String wrongAnswerImagePath) { this.wrongAnswerImagePath = valueOrEmpty(wrongAnswerImagePath); }
    public String getCorrectAnswerImagePath() { return correctAnswerImagePath; }
    public void setCorrectAnswerImagePath(String correctAnswerImagePath) { this.correctAnswerImagePath = valueOrEmpty(correctAnswerImagePath); }
    public List<String> getTags() { return tags == null ? new ArrayList<>() : new ArrayList<>(tags); }
    public void setTags(List<String> tags) { this.tags = tags == null ? new ArrayList<>() : new ArrayList<>(tags); }
    public String getMasteryStatus() { return masteryStatus; }
    public void setMasteryStatus(String masteryStatus) { this.masteryStatus = normalizeStatus(masteryStatus); }
    public int getReviewCount() { return reviewCount; }
    public void setReviewCount(int reviewCount) { this.reviewCount = Math.max(0, reviewCount); }
    public String getCreatedAt() { return createdAt; }
    public void setCreatedAt(String createdAt) { this.createdAt = valueOrEmpty(createdAt); }
    public String getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(String updatedAt) { this.updatedAt = valueOrEmpty(updatedAt); }
    public String getLastReviewedAt() { return lastReviewedAt; }
    public void setLastReviewedAt(String lastReviewedAt) { this.lastReviewedAt = blankToNull(lastReviewedAt); }

    public void markUpdated() {
        updatedAt = Instant.now().toString();
    }

    public void recordReview(String status) {
        masteryStatus = normalizeStatus(status);
        reviewCount++;
        String now = Instant.now().toString();
        lastReviewedAt = now;
        updatedAt = now;
    }

    public Object[] toRow() {
        return new Object[]{question.isBlank() ? "图片错题" : question, category, statusLabel(), reviewCount, id};
    }

    public String statusLabel() {
        return switch (masteryStatus) {
            case STATUS_REVIEWING -> "复习中";
            case STATUS_MASTERED -> "已掌握";
            default -> "新错题";
        };
    }

    @Override
    public String toString() {
        return question == null || question.isBlank() ? "图片错题" : question;
    }

    public static String normalizeStatus(String status) {
        String text = valueOrEmpty(status).trim();
        if (STATUS_REVIEWING.equals(text) || STATUS_MASTERED.equals(text)) return text;
        return STATUS_NEW;
    }

    private static String valueOrEmpty(String value) {
        return value == null ? "" : value;
    }

    private static String valueOrDefault(String value, String fallback) {
        String normalized = valueOrEmpty(value).trim();
        return normalized.isEmpty() ? fallback : normalized;
    }

    private static String blankToNull(String value) {
        String normalized = valueOrEmpty(value).trim();
        return normalized.isEmpty() ? null : normalized;
    }
}
