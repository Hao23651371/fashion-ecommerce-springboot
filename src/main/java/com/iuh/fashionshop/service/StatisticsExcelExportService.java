package com.iuh.fashionshop.service;

import com.iuh.fashionshop.dto.AdminStatisticsDto;
import org.springframework.stereotype.Service;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.zip.ZipEntry;
import java.util.zip.ZipOutputStream;

@Service
public class StatisticsExcelExportService {

    private static final DateTimeFormatter EXPORT_TIME_FORMAT = DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm:ss");

    public byte[] exportToExcel(AdminStatisticsDto stats) {
        try (ByteArrayOutputStream baos = new ByteArrayOutputStream();
             ZipOutputStream zos = new ZipOutputStream(baos)) {

            // 1. [Content_Types].xml
            addZipEntry(zos, "[Content_Types].xml", buildContentTypesXml());

            // 2. _rels/.rels
            addZipEntry(zos, "_rels/.rels", buildGlobalRelsXml());

            // 3. xl/workbook.xml
            addZipEntry(zos, "xl/workbook.xml", buildWorkbookXml());

            // 4. xl/_rels/workbook.xml.rels
            addZipEntry(zos, "xl/_rels/workbook.xml.rels", buildWorkbookRelsXml());

            // 5. xl/styles.xml
            addZipEntry(zos, "xl/styles.xml", buildStylesXml());

            // 6. xl/worksheets/sheet1.xml (Tổng quan & KPI)
            addZipEntry(zos, "xl/worksheets/sheet1.xml", buildOverviewSheet(stats));

            // 7. xl/worksheets/sheet2.xml (Chi tiết đơn hàng & Sản phẩm bán)
            addZipEntry(zos, "xl/worksheets/sheet2.xml", buildSoldItemsSheet(stats));

            // 8. xl/worksheets/sheet3.xml (Top sản phẩm)
            addZipEntry(zos, "xl/worksheets/sheet3.xml", buildTopProductsSheet(stats));

            zos.finish();
            return baos.toByteArray();
        } catch (IOException e) {
            throw new RuntimeException("Lỗi tạo file Excel: " + e.getMessage(), e);
        }
    }

    private void addZipEntry(ZipOutputStream zos, String entryName, String content) throws IOException {
        ZipEntry entry = new ZipEntry(entryName);
        zos.putNextEntry(entry);
        byte[] bytes = content.getBytes(StandardCharsets.UTF_8);
        zos.write(bytes, 0, bytes.length);
        zos.closeEntry();
    }

    private String buildContentTypesXml() {
        return """
                <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
                <Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
                  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
                  <Default Extension="xml" ContentType="application/xml"/>
                  <Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
                  <Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>
                  <Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
                  <Override PartName="/xl/worksheets/sheet2.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
                  <Override PartName="/xl/worksheets/sheet3.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
                </Types>
                """.trim();
    }

    private String buildGlobalRelsXml() {
        return """
                <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
                <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
                  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
                </Relationships>
                """.trim();
    }

    private String buildWorkbookXml() {
        return """
                <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
                <workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
                  <sheets>
                    <sheet name="Tổng quan &amp; KPI" sheetId="1" r:id="rId1"/>
                    <sheet name="Chi tiết đơn hàng" sheetId="2" r:id="rId2"/>
                    <sheet name="Top sản phẩm" sheetId="3" r:id="rId3"/>
                  </sheets>
                </workbook>
                """.trim();
    }

    private String buildWorkbookRelsXml() {
        return """
                <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
                <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
                  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>
                  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet2.xml"/>
                  <Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet3.xml"/>
                  <Relationship Id="rId4" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
                </Relationships>
                """.trim();
    }

    private String buildStylesXml() {
        return """
                <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
                <styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
                  <numFmts count="3">
                    <numFmt numFmtId="164" formatCode="#,##0&quot; ₫&quot;"/>
                    <numFmt numFmtId="165" formatCode="0.0&quot;%&quot;"/>
                    <numFmt numFmtId="166" formatCode="#,##0"/>
                  </numFmts>
                  <fonts count="6">
                    <font><sz val="11"/><color rgb="FF1E293B"/><name val="Calibri"/></font>
                    <font><b/><sz val="11"/><color rgb="FFFFFFFF"/><name val="Calibri"/></font>
                    <font><b/><sz val="16"/><color rgb="FF0F172A"/><name val="Calibri"/></font>
                    <font><i/><sz val="10"/><color rgb="FF64748B"/><name val="Calibri"/></font>
                    <font><b/><sz val="12"/><color rgb="FF1E3A8A"/><name val="Calibri"/></font>
                    <font><b/><sz val="11"/><color rgb="FF1E293B"/><name val="Calibri"/></font>
                  </fonts>
                  <fills count="5">
                    <fill><patternFill fillType="none"/></fill>
                    <fill><patternFill fillType="gray125"/></fill>
                    <fill><patternFill fillType="solid"><fgColor rgb="FF0F172A"/></patternFill></fill>
                    <fill><patternFill fillType="solid"><fgColor rgb="FF2563EB"/></patternFill></fill>
                    <fill><patternFill fillType="solid"><fgColor rgb="FFF1F5F9"/></patternFill></fill>
                  </fills>
                  <borders count="2">
                    <border><left/><right/><top/><bottom/></border>
                    <border>
                      <left style="thin"><color rgb="FFCBD5E1"/></left>
                      <right style="thin"><color rgb="FFCBD5E1"/></right>
                      <top style="thin"><color rgb="FFCBD5E1"/></top>
                      <bottom style="thin"><color rgb="FFCBD5E1"/></bottom>
                    </border>
                  </borders>
                  <cellStyleXfs count="1">
                    <xf numFmtId="0" fontId="0" fillId="0" borderId="0"/>
                  </cellStyleXfs>
                  <cellXfs count="15">
                    <xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>
                    <xf numFmtId="0" fontId="2" fillId="0" borderId="0" xfId="0" applyFont="1"/>
                    <xf numFmtId="0" fontId="3" fillId="0" borderId="0" xfId="0" applyFont="1"/>
                    <xf numFmtId="0" fontId="4" fillId="0" borderId="0" xfId="0" applyFont="1"/>
                    <xf numFmtId="0" fontId="1" fillId="2" borderId="1" xfId="0" applyFont="1" applyFill="1" applyBorder="1" applyAlignment="1"><alignment horizontal="center" vertical="center" wrapText="1"/></xf>
                    <xf numFmtId="0" fontId="1" fillId="3" borderId="1" xfId="0" applyFont="1" applyFill="1" applyBorder="1" applyAlignment="1"><alignment horizontal="center" vertical="center" wrapText="1"/></xf>
                    <xf numFmtId="0" fontId="0" fillId="0" borderId="1" xfId="0" applyBorder="1" applyAlignment="1"><alignment vertical="center"/></xf>
                    <xf numFmtId="0" fontId="0" fillId="0" borderId="1" xfId="0" applyBorder="1" applyAlignment="1"><alignment horizontal="center" vertical="center"/></xf>
                    <xf numFmtId="166" fontId="0" fillId="0" borderId="1" xfId="0" applyNumberFormat="1" applyBorder="1" applyAlignment="1"><alignment horizontal="right" vertical="center"/></xf>
                    <xf numFmtId="164" fontId="5" fillId="0" borderId="1" xfId="0" applyNumberFormat="1" applyFont="1" applyBorder="1" applyAlignment="1"><alignment horizontal="right" vertical="center"/></xf>
                    <xf numFmtId="165" fontId="0" fillId="0" borderId="1" xfId="0" applyNumberFormat="1" applyBorder="1" applyAlignment="1"><alignment horizontal="right" vertical="center"/></xf>
                    <xf numFmtId="0" fontId="0" fillId="0" borderId="1" xfId="0" applyBorder="1" applyAlignment="1"><alignment horizontal="center" vertical="center"/></xf>
                    <xf numFmtId="0" fontId="5" fillId="4" borderId="1" xfId="0" applyFont="1" applyFill="1" applyBorder="1" applyAlignment="1"><alignment vertical="center"/></xf>
                    <xf numFmtId="166" fontId="5" fillId="4" borderId="1" xfId="0" applyNumberFormat="1" applyFont="1" applyFill="1" applyBorder="1" applyAlignment="1"><alignment horizontal="right" vertical="center"/></xf>
                    <xf numFmtId="164" fontId="5" fillId="4" borderId="1" xfId="0" applyNumberFormat="1" applyFont="1" applyFill="1" applyBorder="1" applyAlignment="1"><alignment horizontal="right" vertical="center"/></xf>
                  </cellXfs>
                </styleSheet>
                """.trim();
    }

    private String buildOverviewSheet(AdminStatisticsDto stats) {
        StringBuilder sb = new StringBuilder();
        sb.append("<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>\n");
        sb.append("<worksheet xmlns=\"http://schemas.openxmlformats.org/spreadsheetml/2006/main\">\n");
        sb.append("  <cols>\n");
        sb.append("    <col min=\"1\" max=\"1\" width=\"30\" customWidth=\"1\"/>\n");
        sb.append("    <col min=\"2\" max=\"2\" width=\"25\" customWidth=\"1\"/>\n");
        sb.append("    <col min=\"3\" max=\"3\" width=\"22\" customWidth=\"1\"/>\n");
        sb.append("    <col min=\"4\" max=\"4\" width=\"22\" customWidth=\"1\"/>\n");
        sb.append("  </cols>\n");
        sb.append("  <sheetData>\n");

        int r = 1;
        // Tiêu đề
        startRow(sb, r);
        appendTextCell(sb, 1, r, 1, "BÁO CÁO THỐNG KÊ DOANH THU & KINH DOANH - FASHION SHOP");
        endRow(sb);
        r++;

        // Thông tin kỳ
        startRow(sb, r);
        appendTextCell(sb, 1, r, 2, "Kỳ báo cáo: " + (stats.dateRangeLabel() != null ? stats.dateRangeLabel() : "Tất cả"));
        endRow(sb);
        r++;

        startRow(sb, r);
        appendTextCell(sb, 1, r, 2, "Thời gian xuất file: " + LocalDateTime.now().format(EXPORT_TIME_FORMAT));
        endRow(sb);
        r += 2;

        // BẢNG 1: CÁC CHỈ SỐ KPI CHÍNH
        startRow(sb, r);
        appendTextCell(sb, 1, r, 3, "I. CÁC CHỈ SỐ DOANH THU & KPI CHÍNH");
        endRow(sb);
        r++;

        startRow(sb, r);
        appendTextCell(sb, 1, r, 4, "Chỉ số");
        appendTextCell(sb, 2, r, 4, "Giá trị");
        appendTextCell(sb, 3, r, 4, "Tăng trưởng so với " + stats.previousMonthLabel());
        endRow(sb);
        r++;

        startRow(sb, r);
        appendTextCell(sb, 1, r, 6, "Tổng doanh thu");
        appendNumberCell(sb, 2, r, 9, stats.totalRevenue());
        appendNumberCell(sb, 3, r, 10, stats.revenueKpi().growthRate());
        endRow(sb);
        r++;

        startRow(sb, r);
        appendTextCell(sb, 1, r, 6, "Đơn hàng thành công");
        appendNumberCell(sb, 2, r, 8, stats.ordersKpi().value());
        appendNumberCell(sb, 3, r, 10, stats.ordersKpi().growthRate());
        endRow(sb);
        r++;

        startRow(sb, r);
        appendTextCell(sb, 1, r, 6, "Giá trị đơn trung bình (AOV)");
        appendNumberCell(sb, 2, r, 9, stats.aovKpi().value());
        appendNumberCell(sb, 3, r, 10, stats.aovKpi().growthRate());
        endRow(sb);
        r++;

        startRow(sb, r);
        appendTextCell(sb, 1, r, 6, "Sản phẩm đã bán");
        appendNumberCell(sb, 2, r, 8, stats.soldProductsKpi().value());
        appendNumberCell(sb, 3, r, 10, stats.soldProductsKpi().growthRate());
        endRow(sb);
        r += 2;

        // BẢNG 2: DOANH THU THEO KHOẢNG THỜI GIAN
        startRow(sb, r);
        appendTextCell(sb, 1, r, 3, "II. DOANH THU & ĐƠN HÀNG THEO KHOẢNG THỜI GIAN");
        endRow(sb);
        r++;

        startRow(sb, r);
        appendTextCell(sb, 1, r, 5, "Khoảng thời gian");
        appendTextCell(sb, 2, r, 5, "Số lượng đơn hàng");
        appendTextCell(sb, 3, r, 5, "Doanh thu");
        endRow(sb);
        r++;

        if (stats.weeklyData() != null) {
            for (AdminStatisticsDto.WeeklyData w : stats.weeklyData()) {
                startRow(sb, r);
                appendTextCell(sb, 1, r, 7, w.label());
                appendNumberCell(sb, 2, r, 8, w.orderCount());
                appendNumberCell(sb, 3, r, 9, w.revenue());
                endRow(sb);
                r++;
            }
        }
        r += 2;

        // BẢNG 3: DOANH THU THEO DANH MỤC
        startRow(sb, r);
        appendTextCell(sb, 1, r, 3, "III. DOANH THU THEO DANH MỤC");
        endRow(sb);
        r++;

        startRow(sb, r);
        appendTextCell(sb, 1, r, 4, "Danh mục sản phẩm");
        appendTextCell(sb, 2, r, 4, "Doanh thu");
        appendTextCell(sb, 3, r, 4, "Tỷ trọng doanh thu");
        endRow(sb);
        r++;

        if (stats.categoryRevenues() != null) {
            for (AdminStatisticsDto.CategoryRevenue cat : stats.categoryRevenues()) {
                startRow(sb, r);
                appendTextCell(sb, 1, r, 6, cat.name());
                appendNumberCell(sb, 2, r, 9, cat.revenue());
                appendNumberCell(sb, 3, r, 10, cat.share());
                endRow(sb);
                r++;
            }
        }
        r += 2;

        // BẢNG 4: DOANH THU THEO KÊNH BÁN / PHƯƠNG THỨC THANH TOÁN
        startRow(sb, r);
        appendTextCell(sb, 1, r, 3, "IV. DOANH THU THEO PHƯƠNG THỨC THANH TOÁN");
        endRow(sb);
        r++;

        startRow(sb, r);
        appendTextCell(sb, 1, r, 5, "Phương thức thanh toán");
        appendTextCell(sb, 2, r, 5, "Doanh thu");
        appendTextCell(sb, 3, r, 5, "Tỷ trọng");
        endRow(sb);
        r++;

        if (stats.channelRevenues() != null) {
            for (AdminStatisticsDto.ChannelRevenue ch : stats.channelRevenues()) {
                startRow(sb, r);
                appendTextCell(sb, 1, r, 6, ch.channelName());
                appendNumberCell(sb, 2, r, 9, ch.revenue());
                appendNumberCell(sb, 3, r, 10, ch.share());
                endRow(sb);
                r++;
            }
        }

        sb.append("  </sheetData>\n");
        sb.append("</worksheet>");
        return sb.toString();
    }

    private String buildSoldItemsSheet(AdminStatisticsDto stats) {
        StringBuilder sb = new StringBuilder();
        sb.append("<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>\n");
        sb.append("<worksheet xmlns=\"http://schemas.openxmlformats.org/spreadsheetml/2006/main\">\n");
        sb.append("  <cols>\n");
        sb.append("    <col min=\"1\" max=\"1\" width=\"8\" customWidth=\"1\"/>\n");   // STT
        sb.append("    <col min=\"2\" max=\"2\" width=\"18\" customWidth=\"1\"/>\n");  // Mã đơn
        sb.append("    <col min=\"3\" max=\"3\" width=\"36\" customWidth=\"1\"/>\n");  // Tên SP
        sb.append("    <col min=\"4\" max=\"4\" width=\"14\" customWidth=\"1\"/>\n");  // Màu
        sb.append("    <col min=\"5\" max=\"5\" width=\"10\" customWidth=\"1\"/>\n");  // Size
        sb.append("    <col min=\"6\" max=\"6\" width=\"12\" customWidth=\"1\"/>\n");  // SL
        sb.append("    <col min=\"7\" max=\"7\" width=\"18\" customWidth=\"1\"/>\n");  // Đơn giá
        sb.append("    <col min=\"8\" max=\"8\" width=\"20\" customWidth=\"1\"/>\n");  // Thành tiền
        sb.append("    <col min=\"9\" max=\"9\" width=\"22\" customWidth=\"1\"/>\n");  // Thời gian
        sb.append("  </cols>\n");
        sb.append("  <sheetData>\n");

        int r = 1;
        startRow(sb, r);
        appendTextCell(sb, 1, r, 1, "DANH SÁCH CHI TIẾT CÁC MẶT HÀNG ĐÃ BÁN");
        endRow(sb);
        r++;

        startRow(sb, r);
        appendTextCell(sb, 1, r, 2, "Kỳ thống kê: " + (stats.dateRangeLabel() != null ? stats.dateRangeLabel() : "Tất cả"));
        endRow(sb);
        r += 2;

        startRow(sb, r);
        appendTextCell(sb, 1, r, 4, "STT");
        appendTextCell(sb, 2, r, 4, "Mã đơn hàng");
        appendTextCell(sb, 3, r, 4, "Tên sản phẩm");
        appendTextCell(sb, 4, r, 4, "Màu sắc");
        appendTextCell(sb, 5, r, 4, "Size");
        appendTextCell(sb, 6, r, 4, "Số lượng");
        appendTextCell(sb, 7, r, 4, "Đơn giá");
        appendTextCell(sb, 8, r, 4, "Thành tiền");
        appendTextCell(sb, 9, r, 4, "Thời gian đặt hàng");
        endRow(sb);
        r++;

        List<AdminStatisticsDto.SoldItemDetail> allItems = new ArrayList<>();
        if (stats.weeklyData() != null) {
            for (AdminStatisticsDto.WeeklyData w : stats.weeklyData()) {
                if (w.items() != null) {
                    allItems.addAll(w.items());
                }
            }
        }

        int index = 1;
        long totalQuantity = 0;
        BigDecimal totalMoney = BigDecimal.ZERO;

        for (AdminStatisticsDto.SoldItemDetail item : allItems) {
            startRow(sb, r);
            appendNumberCell(sb, 1, r, 7, index++);
            appendTextCell(sb, 2, r, 7, "#" + item.orderCode());
            appendTextCell(sb, 3, r, 6, item.productName());
            appendTextCell(sb, 4, r, 7, item.color() != null && !item.color().isBlank() ? item.color() : "–");
            appendTextCell(sb, 5, r, 7, item.size() != null && !item.size().isBlank() ? item.size() : "–");
            appendNumberCell(sb, 6, r, 8, item.quantity());
            appendNumberCell(sb, 7, r, 9, item.unitPrice());
            appendNumberCell(sb, 8, r, 9, item.totalPrice());
            appendTextCell(sb, 9, r, 11, item.formattedSoldDate() != null ? item.formattedSoldDate() : "");
            endRow(sb);

            totalQuantity += item.quantity();
            if (item.totalPrice() != null) {
                totalMoney = totalMoney.add(item.totalPrice());
            }
            r++;
        }

        // Hàng tổng cộng
        if (!allItems.isEmpty()) {
            startRow(sb, r);
            appendTextCell(sb, 1, r, 12, "Tổng");
            appendTextCell(sb, 2, r, 12, "");
            appendTextCell(sb, 3, r, 12, allItems.size() + " lượt sản phẩm");
            appendTextCell(sb, 4, r, 12, "");
            appendTextCell(sb, 5, r, 12, "");
            appendNumberCell(sb, 6, r, 13, totalQuantity);
            appendTextCell(sb, 7, r, 12, "");
            appendNumberCell(sb, 8, r, 14, totalMoney);
            appendTextCell(sb, 9, r, 12, "");
            endRow(sb);
        } else {
            startRow(sb, r);
            appendTextCell(sb, 1, r, 6, "Không có đơn hàng nào trong khoảng thời gian này.");
            endRow(sb);
        }

        sb.append("  </sheetData>\n");
        sb.append("</worksheet>");
        return sb.toString();
    }

    private String buildTopProductsSheet(AdminStatisticsDto stats) {
        StringBuilder sb = new StringBuilder();
        sb.append("<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>\n");
        sb.append("<worksheet xmlns=\"http://schemas.openxmlformats.org/spreadsheetml/2006/main\">\n");
        sb.append("  <cols>\n");
        sb.append("    <col min=\"1\" max=\"1\" width=\"12\" customWidth=\"1\"/>\n");  // Hạng
        sb.append("    <col min=\"2\" max=\"2\" width=\"38\" customWidth=\"1\"/>\n");  // Tên SP
        sb.append("    <col min=\"3\" max=\"3\" width=\"22\" customWidth=\"1\"/>\n");  // Danh mục
        sb.append("    <col min=\"4\" max=\"4\" width=\"16\" customWidth=\"1\"/>\n");  // Đã bán
        sb.append("    <col min=\"5\" max=\"5\" width=\"22\" customWidth=\"1\"/>\n");  // Doanh thu
        sb.append("    <col min=\"6\" max=\"6\" width=\"16\" customWidth=\"1\"/>\n");  // Tỷ trọng
        sb.append("    <col min=\"7\" max=\"7\" width=\"18\" customWidth=\"1\"/>\n");  // Tăng trưởng
        sb.append("  </cols>\n");
        sb.append("  <sheetData>\n");

        int r = 1;
        startRow(sb, r);
        appendTextCell(sb, 1, r, 1, "TOP 5 SẢN PHẨM BÁN CHẠY NHẤT");
        endRow(sb);
        r++;

        startRow(sb, r);
        appendTextCell(sb, 1, r, 2, "Kỳ xếp hạng: " + (stats.dateRangeLabel() != null ? stats.dateRangeLabel() : "Tất cả"));
        endRow(sb);
        r += 2;

        startRow(sb, r);
        appendTextCell(sb, 1, r, 5, "Xếp hạng");
        appendTextCell(sb, 2, r, 5, "Tên sản phẩm");
        appendTextCell(sb, 3, r, 5, "Danh mục");
        appendTextCell(sb, 4, r, 5, "Số lượng bán");
        appendTextCell(sb, 5, r, 5, "Doanh thu");
        appendTextCell(sb, 6, r, 5, "Tỷ trọng doanh thu");
        appendTextCell(sb, 7, r, 5, "Tăng trưởng");
        endRow(sb);
        r++;

        if (stats.topProducts() != null && !stats.topProducts().isEmpty()) {
            for (AdminStatisticsDto.TopProduct p : stats.topProducts()) {
                startRow(sb, r);
                appendTextCell(sb, 1, r, 7, "Top " + p.rank());
                appendTextCell(sb, 2, r, 6, p.productName());
                appendTextCell(sb, 3, r, 7, p.categoryName());
                appendNumberCell(sb, 4, r, 8, p.soldQuantity());
                appendNumberCell(sb, 5, r, 9, p.revenue());
                appendNumberCell(sb, 6, r, 10, p.share());
                appendNumberCell(sb, 7, r, 10, p.growthRate());
                endRow(sb);
                r++;
            }
        } else {
            startRow(sb, r);
            appendTextCell(sb, 1, r, 6, "Chưa có dữ liệu sản phẩm trong khoảng thời gian này.");
            endRow(sb);
        }

        sb.append("  </sheetData>\n");
        sb.append("</worksheet>");
        return sb.toString();
    }

    private void startRow(StringBuilder sb, int row) {
        sb.append("    <row r=\"").append(row).append("\">\n");
    }

    private void endRow(StringBuilder sb) {
        sb.append("    </row>\n");
    }

    private void appendTextCell(StringBuilder sb, int col, int row, int styleId, String text) {
        String ref = toColumnName(col) + row;
        sb.append("      <c r=\"").append(ref).append("\" s=\"").append(styleId)
                .append("\" t=\"inlineStr\"><is><t>").append(escapeXml(text))
                .append("</t></is></c>\n");
    }

    private void appendNumberCell(StringBuilder sb, int col, int row, int styleId, Number num) {
        String ref = toColumnName(col) + row;
        sb.append("      <c r=\"").append(ref).append("\" s=\"").append(styleId)
                .append("\"><v>").append(num != null ? num : 0)
                .append("</v></c>\n");
    }

    private String toColumnName(int colNumber) {
        StringBuilder sb = new StringBuilder();
        while (colNumber > 0) {
            int rem = (colNumber - 1) % 26;
            sb.insert(0, (char) ('A' + rem));
            colNumber = (colNumber - 1) / 26;
        }
        return sb.toString();
    }

    private String escapeXml(String s) {
        if (s == null) return "";
        return s.replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
                .replace("\"", "&quot;")
                .replace("'", "&apos;");
    }
}
