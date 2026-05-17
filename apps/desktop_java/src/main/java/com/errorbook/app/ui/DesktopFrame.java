package com.errorbook.app.ui;

import com.errorbook.app.model.Mistake;
import com.errorbook.app.model.Stats;
import com.errorbook.app.repository.LocalJsonMistakeRepository;
import com.errorbook.app.service.MistakeService;

import javax.swing.*;
import javax.swing.border.EmptyBorder;
import javax.swing.table.DefaultTableModel;
import java.awt.*;
import java.util.List;
import java.util.Map;

public class DesktopFrame extends JFrame {
    private final MistakeService service = new MistakeService(new LocalJsonMistakeRepository());

    private final JTextField searchField = new JTextField();
    private final DefaultListModel<String> categoryModel = new DefaultListModel<>();
    private final JList<String> categoryList = new JList<>(categoryModel);
    private final DefaultTableModel tableModel = new DefaultTableModel(new Object[]{"题目", "分类", "状态", "复习次数", "ID"}, 0) {
        @Override public boolean isCellEditable(int row, int column) { return false; }
    };
    private final JTable table = new JTable(tableModel);
    private final JTextArea detail = new JTextArea();
    private final JLabel statsLabel = new JLabel("总错题 0");

    private List<Mistake> current = List.of();

    public DesktopFrame() {
        setTitle("Error Book - Desktop(Java Offline)");
        setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        setSize(1220, 780);
        setLocationRelativeTo(null);
        setLayout(new BorderLayout());

        add(buildTopBar(), BorderLayout.NORTH);
        add(buildMainSplit(), BorderLayout.CENTER);

        refreshCategories();
        applyFilter();
    }

    private JPanel buildTopBar() {
        JPanel panel = new JPanel(new BorderLayout());
        panel.setBorder(new EmptyBorder(8, 12, 8, 12));

        JLabel title = new JLabel("错题本（电脑端 · 离线 JSON）");
        title.setFont(title.getFont().deriveFont(Font.BOLD, 18f));

        searchField.setPreferredSize(new Dimension(280, 32));
        searchField.setToolTipText("关键词搜索题干、答案、解析、分类或标签");

        JButton searchBtn = new JButton("搜索");
        JButton resetBtn = new JButton("重置");
        JButton addBtn = new JButton("新增错题");
        JButton randomBtn = new JButton("随机复习");

        searchBtn.addActionListener(e -> applyFilter());
        resetBtn.addActionListener(e -> { searchField.setText(""); categoryList.setSelectedIndex(0); applyFilter(); });
        addBtn.addActionListener(e -> onAdd());
        randomBtn.addActionListener(e -> onRandomReview());

        JPanel right = new JPanel(new FlowLayout(FlowLayout.RIGHT, 8, 0));
        right.add(new JLabel("搜索:"));
        right.add(searchField);
        right.add(searchBtn);
        right.add(resetBtn);
        right.add(addBtn);
        right.add(randomBtn);

        JPanel left = new JPanel(new FlowLayout(FlowLayout.LEFT, 12, 0));
        left.add(title);
        left.add(statsLabel);

        panel.add(left, BorderLayout.WEST);
        panel.add(right, BorderLayout.EAST);
        return panel;
    }

    private JSplitPane buildMainSplit() {
        JSplitPane rightSplit = new JSplitPane(JSplitPane.HORIZONTAL_SPLIT, buildListPanel(), buildDetailPanel());
        rightSplit.setResizeWeight(0.58);

        JSplitPane mainSplit = new JSplitPane(JSplitPane.HORIZONTAL_SPLIT, buildFilterPanel(), rightSplit);
        mainSplit.setResizeWeight(0.2);
        return mainSplit;
    }

    private JPanel buildFilterPanel() {
        JPanel panel = new JPanel(new BorderLayout());
        panel.setBorder(new EmptyBorder(12, 12, 12, 12));
        panel.add(new JLabel("分类筛选"), BorderLayout.NORTH);

        categoryList.addListSelectionListener(e -> { if (!e.getValueIsAdjusting()) applyFilter(); });
        panel.add(new JScrollPane(categoryList), BorderLayout.CENTER);
        return panel;
    }

    private JPanel buildListPanel() {
        JPanel panel = new JPanel(new BorderLayout());
        panel.setBorder(new EmptyBorder(12, 12, 12, 6));

        table.setRowHeight(28);
        table.getSelectionModel().addListSelectionListener(e -> { if (!e.getValueIsAdjusting()) showSelectedDetail(); });

        panel.add(new JLabel("错题列表"), BorderLayout.NORTH);
        panel.add(new JScrollPane(table), BorderLayout.CENTER);
        return panel;
    }

    private JPanel buildDetailPanel() {
        JPanel panel = new JPanel(new BorderLayout());
        panel.setBorder(new EmptyBorder(12, 6, 12, 12));

        detail.setEditable(false);
        detail.setLineWrap(true);
        detail.setWrapStyleWord(true);
        detail.setText("选择一条错题查看详情");

        JButton editBtn = new JButton("编辑");
        JButton deleteBtn = new JButton("删除");

        editBtn.addActionListener(e -> onEdit());
        deleteBtn.addActionListener(e -> onDelete());

        JPanel actions = new JPanel(new FlowLayout(FlowLayout.RIGHT));
        actions.add(editBtn);
        actions.add(deleteBtn);

        panel.add(new JLabel("错题详情"), BorderLayout.NORTH);
        panel.add(new JScrollPane(detail), BorderLayout.CENTER);
        panel.add(actions, BorderLayout.SOUTH);
        return panel;
    }

    private void refreshCategories() {
        categoryModel.clear();
        categoryModel.addElement("全部分类");
        service.all().stream().map(Mistake::getCategory).distinct().sorted().forEach(categoryModel::addElement);
        if (categoryModel.getSize() > 0 && categoryList.getSelectedIndex() < 0) categoryList.setSelectedIndex(0);
    }

    private String selectedCategory() {
        String value = categoryList.getSelectedValue();
        return value == null ? "全部分类" : value;
    }

    private void applyFilter() {
        current = service.query(searchField.getText(), selectedCategory());
        tableModel.setRowCount(0);
        for (Mistake mistake : current) tableModel.addRow(mistake.toRow());
        detail.setText(current.isEmpty() ? "暂无数据" : "选择一条错题查看详情");
        refreshStats();
    }

    private Mistake selected() {
        int row = table.getSelectedRow();
        if (row < 0 || row >= current.size()) return null;
        return current.get(row);
    }

    private void showSelectedDetail() {
        Mistake m = selected();
        if (m == null) {
            detail.setText("选择一条错题查看详情");
            return;
        }
        detail.setText(
                "题干:\n" + m.getQuestion() +
                "\n\n错误答案:\n" + m.getWrongAnswer() +
                "\n\n正确答案:\n" + m.getCorrectAnswer() +
                "\n\n错误原因:\n" + m.getReason() +
                "\n\n分类: " + m.getCategory() +
                "\n标签: " + String.join(", ", m.getTags()) +
                "\n状态: " + m.statusLabel() +
                "\n复习次数: " + m.getReviewCount() +
                "\n最近复习: " + (m.getLastReviewedAt() == null ? "无" : m.getLastReviewedAt()) +
                "\n题干图: " + m.getQuestionImagePath() +
                "\n错误答案图: " + m.getWrongAnswerImagePath() +
                "\n正确答案图: " + m.getCorrectAnswerImagePath() +
                "\nID: " + m.getId()
        );
    }

    private void refreshStats() {
        Stats stats = service.stats();
        StringBuilder sb = new StringBuilder("总错题 ").append(stats.getTotal());
        appendCounts(sb, stats.getByCategory());
        appendCounts(sb, stats.getByStatus());
        statsLabel.setText(sb.toString());
    }

    private void appendCounts(StringBuilder sb, Map<String, Integer> counts) {
        if (counts.isEmpty()) return;
        sb.append(" | ");
        boolean first = true;
        for (Map.Entry<String, Integer> entry : counts.entrySet()) {
            if (!first) sb.append(" · ");
            sb.append(entry.getKey()).append(":").append(entry.getValue());
            first = false;
        }
    }

    private void onAdd() {
        MistakeDialog dialog = new MistakeDialog(this, null);
        dialog.setVisible(true);
        Mistake result = dialog.getResult();
        if (result != null) {
            service.addOrUpdate(result);
            refreshCategories();
            applyFilter();
        }
    }

    private void onEdit() {
        Mistake selected = selected();
        if (selected == null) return;
        MistakeDialog dialog = new MistakeDialog(this, selected);
        dialog.setVisible(true);
        Mistake result = dialog.getResult();
        if (result != null) {
            service.addOrUpdate(result);
            refreshCategories();
            applyFilter();
        }
    }

    private void onDelete() {
        Mistake selected = selected();
        if (selected == null) return;
        int ok = JOptionPane.showConfirmDialog(this, "确认删除这条错题？", "删除确认", JOptionPane.YES_NO_OPTION);
        if (ok == JOptionPane.YES_OPTION) {
            service.delete(selected.getId());
            refreshCategories();
            applyFilter();
        }
    }

    private void onRandomReview() {
        Mistake m = service.randomOne();
        if (m == null) {
            JOptionPane.showMessageDialog(this, "当前没有错题可复习");
            return;
        }
        JOptionPane.showMessageDialog(this, "随机复习\n\n题干:\n" + m.getQuestion() + "\n\n请先自己作答，再点击确定查看答案");
        JOptionPane.showMessageDialog(this, "正确答案:\n" + m.getCorrectAnswer() + "\n\n错误原因:\n" + m.getReason());
        Object[] options = {"还不会", "继续复习", "已掌握"};
        int result = JOptionPane.showOptionDialog(this, "这道题现在的掌握情况？", "记录复习",
                JOptionPane.DEFAULT_OPTION, JOptionPane.QUESTION_MESSAGE, null, options, options[1]);
        if (result == 0) service.recordReview(m.getId(), Mistake.STATUS_NEW);
        if (result == 1) service.recordReview(m.getId(), Mistake.STATUS_REVIEWING);
        if (result == 2) service.recordReview(m.getId(), Mistake.STATUS_MASTERED);
        refreshCategories();
        applyFilter();
    }
}
