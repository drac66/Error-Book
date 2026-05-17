package com.errorbook.app.ui;

import com.errorbook.app.model.Mistake;

import javax.swing.*;
import java.awt.*;
import java.util.Arrays;
import java.util.List;

public class MistakeDialog extends JDialog {
    private final JTextField question = new JTextField();
    private final JTextField wrong = new JTextField();
    private final JTextField correct = new JTextField();
    private final JTextField reason = new JTextField();
    private final JTextField category = new JTextField();
    private final JTextField tags = new JTextField();
    private final JTextField questionImagePath = new JTextField();
    private final JTextField wrongAnswerImagePath = new JTextField();
    private final JTextField correctAnswerImagePath = new JTextField();
    private final JComboBox<String> status = new JComboBox<>(new String[]{
            Mistake.STATUS_NEW,
            Mistake.STATUS_REVIEWING,
            Mistake.STATUS_MASTERED
    });
    private Mistake result;

    public MistakeDialog(Window owner, Mistake source) {
        super(owner, source == null ? "新增错题" : "编辑错题", ModalityType.APPLICATION_MODAL);
        setSize(720, 520);
        setLocationRelativeTo(owner);
        setLayout(new BorderLayout());

        JPanel form = new JPanel(new GridLayout(10, 2, 8, 8));
        form.setBorder(BorderFactory.createEmptyBorder(12, 12, 12, 12));
        form.add(new JLabel("题干")); form.add(question);
        form.add(new JLabel("错误答案")); form.add(wrong);
        form.add(new JLabel("正确答案")); form.add(correct);
        form.add(new JLabel("错误原因")); form.add(reason);
        form.add(new JLabel("分类")); form.add(category);
        form.add(new JLabel("标签（逗号分隔）")); form.add(tags);
        form.add(new JLabel("题干图片路径")); form.add(questionImagePath);
        form.add(new JLabel("错误答案图片路径")); form.add(wrongAnswerImagePath);
        form.add(new JLabel("正确答案图片路径")); form.add(correctAnswerImagePath);
        form.add(new JLabel("掌握状态")); form.add(status);

        JButton ok = new JButton("保存");
        JButton cancel = new JButton("取消");
        JPanel actions = new JPanel(new FlowLayout(FlowLayout.RIGHT));
        actions.add(cancel); actions.add(ok);

        if (source != null) {
            question.setText(source.getQuestion());
            wrong.setText(source.getWrongAnswer());
            correct.setText(source.getCorrectAnswer());
            reason.setText(source.getReason());
            category.setText(source.getCategory());
            tags.setText(String.join(", ", source.getTags()));
            questionImagePath.setText(source.getQuestionImagePath());
            wrongAnswerImagePath.setText(source.getWrongAnswerImagePath());
            correctAnswerImagePath.setText(source.getCorrectAnswerImagePath());
            status.setSelectedItem(source.getMasteryStatus());
        }

        ok.addActionListener(e -> {
            if (question.getText().isBlank() && questionImagePath.getText().isBlank()) return;
            Mistake mistake = source == null ? new Mistake() : source;
            mistake.setQuestion(question.getText().trim());
            mistake.setWrongAnswer(wrong.getText().trim());
            mistake.setCorrectAnswer(correct.getText().trim());
            mistake.setReason(reason.getText().trim());
            mistake.setCategory(category.getText().trim().isEmpty() ? Mistake.DEFAULT_CATEGORY : category.getText().trim());
            mistake.setTags(parseTags(tags.getText()));
            mistake.setQuestionImagePath(questionImagePath.getText().trim());
            mistake.setWrongAnswerImagePath(wrongAnswerImagePath.getText().trim());
            mistake.setCorrectAnswerImagePath(correctAnswerImagePath.getText().trim());
            mistake.setMasteryStatus((String) status.getSelectedItem());
            result = mistake;
            dispose();
        });
        cancel.addActionListener(e -> dispose());

        add(form, BorderLayout.CENTER);
        add(actions, BorderLayout.SOUTH);
    }

    public Mistake getResult() {
        return result;
    }

    private List<String> parseTags(String raw) {
        if (raw == null || raw.isBlank()) return List.of();
        return Arrays.stream(raw.split("[,，\\s]+"))
                .map(String::trim)
                .filter(s -> !s.isBlank())
                .toList();
    }
}
