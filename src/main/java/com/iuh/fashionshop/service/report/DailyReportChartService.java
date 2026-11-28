package com.iuh.fashionshop.service.report;

import com.iuh.fashionshop.dto.DailyReportDto;
import com.iuh.fashionshop.dto.DailyReportDto.DayPoint;
import com.iuh.fashionshop.dto.DailyReportDto.ShareItem;
import com.iuh.fashionshop.dto.DailyReportDto.TopProductRow;
import org.jfree.chart.ChartFactory;
import org.jfree.chart.ChartUtils;
import org.jfree.chart.JFreeChart;
import org.jfree.chart.axis.CategoryAxis;
import org.jfree.chart.axis.CategoryLabelPositions;
import org.jfree.chart.axis.NumberAxis;
import org.jfree.chart.labels.StandardCategoryItemLabelGenerator;
import org.jfree.chart.labels.StandardPieSectionLabelGenerator;
import org.jfree.chart.plot.CategoryPlot;
import org.jfree.chart.plot.PiePlot;
import org.jfree.chart.plot.PlotOrientation;
import org.jfree.chart.renderer.category.BarRenderer;
import org.jfree.chart.renderer.category.StandardBarPainter;
import org.jfree.chart.title.LegendTitle;
import org.jfree.chart.title.TextTitle;
import org.jfree.chart.ui.RectangleEdge;
import org.jfree.data.category.DefaultCategoryDataset;
import org.jfree.data.general.DefaultPieDataset;
import org.springframework.stereotype.Service;

import java.awt.*;
import java.io.ByteArrayOutputStream;
import java.math.BigDecimal;
import java.text.DecimalFormat;
import java.text.NumberFormat;
import java.util.Base64;
import java.util.List;
import java.util.Locale;

/**
 * Vẽ các biểu đồ PNG sắc nét (có chú giải, đơn vị trục và số liệu trên từng cột/miếng)
 * dưới dạng Base64 Data URI để nhúng trực tiếp vào file PDF báo cáo mà không phụ thuộc mạng ngoài.
 */
@Service
public class DailyReportChartService {

    private static final Locale VI = Locale.forLanguageTag("vi-VN");
    private static final Font FONT_TITLE = new Font("SansSerif", Font.BOLD, 14);
    private static final Font FONT_SUBTITLE = new Font("SansSerif", Font.PLAIN, 10);
    private static final Font FONT_AXIS = new Font("SansSerif", Font.BOLD, 10);
    private static final Font FONT_TICK = new Font("SansSerif", Font.PLAIN, 10);
    private static final Font FONT_LABEL = new Font("SansSerif", Font.BOLD, 10);

    /**
     * Biểu đồ cột: Xu hướng doanh thu 7 ngày gần nhất (cột hôm nay nổi bật màu xanh đậm).
     */
    public String renderRevenue7DaysChart(DailyReportDto report) {
        DefaultCategoryDataset dataset = new DefaultCategoryDataset();
        for (DayPoint point : report.trend7Days()) {
            double valInThousands = point.revenue().doubleValue() / 1000.0;
            dataset.addValue(valInThousands, "Doanh thu (nghìn đồng)", point.label());
        }

        JFreeChart chart = ChartFactory.createBarChart(
                "Xu hướng doanh thu 7 ngày gần nhất",
                "Ngày",
                "Doanh thu (nghìn đ)",
                dataset,
                PlotOrientation.VERTICAL,
                true,
                false,
                false
        );

        styleBaseChart(chart, "Đơn vị: Nghìn đồng (k) | Cột cuối là ngày báo cáo hiện tại");

        CategoryPlot plot = chart.getCategoryPlot();
        styleCategoryPlot(plot);

        BarRenderer renderer = new BarRenderer() {
            @Override
            public Paint getItemPaint(int row, int column) {
                return column == report.trend7Days().size() - 1
                        ? new Color(37, 99, 235)   // Hôm nay: xanh dương đậm
                        : new Color(147, 197, 253); // Các ngày trước: xanh nhạt
            }
        };
        styleBarRenderer(renderer, "{2}k");
        plot.setRenderer(renderer);

        NumberAxis rangeAxis = (NumberAxis) plot.getRangeAxis();
        rangeAxis.setUpperMargin(0.22);
        rangeAxis.setNumberFormatOverride(NumberFormat.getIntegerInstance(VI));

        return toBase64Png(chart, 760, 290);
    }

    /**
     * Biểu đồ cột ngang: Top sản phẩm mang lại doanh thu cao nhất hôm nay.
     */
    public String renderTopProductsChart(DailyReportDto report) {
        List<TopProductRow> tops = report.topProducts();
        if (tops == null || tops.isEmpty()) {
            return null;
        }

        DefaultCategoryDataset dataset = new DefaultCategoryDataset();
        for (TopProductRow p : tops) {
            String shortName = truncate(p.productName(), 28);
            dataset.addValue(p.revenue().doubleValue() / 1000.0, "Doanh thu (nghìn đ)", "#" + p.rank() + " " + shortName);
        }

        JFreeChart chart = ChartFactory.createBarChart(
                "Top sản phẩm doanh thu cao nhất ngày " + report.reportDateLabel(),
                "Sản phẩm",
                "Doanh thu (nghìn đ)",
                dataset,
                PlotOrientation.HORIZONTAL,
                true,
                false,
                false
        );

        styleBaseChart(chart, "Đơn vị: Nghìn đồng (k) | Top 3 đóng góp " + DailyReportService.fmt1(report.top3RevenueShare()) + "% tổng doanh thu");

        CategoryPlot plot = chart.getCategoryPlot();
        styleCategoryPlot(plot);

        BarRenderer renderer = new BarRenderer();
        renderer.setSeriesPaint(0, new Color(16, 185, 129));
        styleBarRenderer(renderer, "{2}k");
        plot.setRenderer(renderer);

        NumberAxis rangeAxis = (NumberAxis) plot.getRangeAxis();
        rangeAxis.setUpperMargin(0.25);
        rangeAxis.setNumberFormatOverride(NumberFormat.getIntegerInstance(VI));

        return toBase64Png(chart, 760, 270);
    }

    /**
     * Biểu đồ tròn: Cơ cấu kênh thanh toán hoặc trạng thái đơn hàng.
     */
    @SuppressWarnings("unchecked")
    public String renderPieChart(String title, String subtitle, List<ShareItem> items, boolean byAmount) {
        if (items == null || items.isEmpty()) {
            return null;
        }

        DefaultPieDataset<String> dataset = new DefaultPieDataset<>();
        for (ShareItem item : items) {
            double val = byAmount
                    ? (item.amount() != null ? item.amount().doubleValue() : 0)
                    : item.quantity();
            if (val > 0) {
                dataset.setValue(item.label(), val);
            }
        }
        if (dataset.getItemCount() == 0) {
            return null;
        }

        JFreeChart chart = ChartFactory.createPieChart(title, dataset, true, false, false);
        styleBaseChart(chart, subtitle);

        PiePlot<String> plot = (PiePlot<String>) chart.getPlot();
        plot.setBackgroundPaint(Color.WHITE);
        plot.setOutlineVisible(false);
        plot.setShadowPaint(null);
        plot.setLabelFont(FONT_LABEL);
        plot.setLabelBackgroundPaint(new Color(248, 250, 252));
        plot.setLabelOutlinePaint(new Color(203, 213, 225));
        plot.setLabelShadowPaint(null);
        plot.setSimpleLabels(false);

        StandardPieSectionLabelGenerator gen = new StandardPieSectionLabelGenerator(
                "{0}: {2}",
                NumberFormat.getIntegerInstance(VI),
                new DecimalFormat("0.0%")
        );
        plot.setLabelGenerator(gen);

        for (ShareItem item : items) {
            if (item.color() != null && item.color().startsWith("#") && item.color().length() == 7) {
                try {
                    plot.setSectionPaint(item.label(), Color.decode(item.color()));
                } catch (Exception ignored) {
                }
            }
        }

        return toBase64Png(chart, 370, 250);
    }

    private void styleBaseChart(JFreeChart chart, String subtitle) {
        chart.setBackgroundPaint(Color.WHITE);
        chart.setAntiAlias(true);
        chart.setTextAntiAlias(true);
        if (chart.getTitle() != null) {
            chart.getTitle().setFont(FONT_TITLE);
            chart.getTitle().setPaint(new Color(15, 23, 42));
        }
        if (subtitle != null && !subtitle.isBlank()) {
            TextTitle sub = new TextTitle(subtitle, FONT_SUBTITLE);
            sub.setPaint(new Color(100, 116, 139));
            chart.addSubtitle(sub);
        }
        LegendTitle legend = chart.getLegend();
        if (legend != null) {
            legend.setPosition(RectangleEdge.BOTTOM);
            legend.setItemFont(FONT_TICK);
            legend.setFrame(org.jfree.chart.block.BlockBorder.NONE);
        }
    }

    private void styleCategoryPlot(CategoryPlot plot) {
        plot.setBackgroundPaint(Color.WHITE);
        plot.setOutlineVisible(false);
        plot.setRangeGridlinePaint(new Color(226, 232, 240));
        plot.setDomainGridlinesVisible(false);

        CategoryAxis domainAxis = plot.getDomainAxis();
        domainAxis.setLabelFont(FONT_AXIS);
        domainAxis.setTickLabelFont(FONT_TICK);
        domainAxis.setTickLabelPaint(new Color(51, 65, 85));
        domainAxis.setCategoryLabelPositions(CategoryLabelPositions.STANDARD);

        plot.getRangeAxis().setLabelFont(FONT_AXIS);
        plot.getRangeAxis().setTickLabelFont(FONT_TICK);
        plot.getRangeAxis().setTickLabelPaint(new Color(51, 65, 85));
    }

    private void styleBarRenderer(BarRenderer renderer, String labelFormat) {
        renderer.setBarPainter(new StandardBarPainter());
        renderer.setShadowVisible(false);
        renderer.setMaximumBarWidth(0.14);
        renderer.setDefaultItemLabelsVisible(true);
        renderer.setDefaultItemLabelFont(FONT_LABEL);
        renderer.setDefaultItemLabelPaint(new Color(15, 23, 42));
        renderer.setDefaultItemLabelGenerator(new StandardCategoryItemLabelGenerator(
                labelFormat,
                NumberFormat.getIntegerInstance(VI)
        ));
    }

    private String toBase64Png(JFreeChart chart, int width, int height) {
        try (ByteArrayOutputStream out = new ByteArrayOutputStream()) {
            ChartUtils.writeChartAsPNG(out, chart, width, height);
            return "data:image/png;base64," + Base64.getEncoder().encodeToString(out.toByteArray());
        } catch (Exception e) {
            return null;
        }
    }

    private static String truncate(String s, int max) {
        if (s == null) return "";
        return s.length() <= max ? s : s.substring(0, max - 1) + "…";
    }
}
