package com.iuh.fashionshop.service;

import com.iuh.fashionshop.controller.AdminCouponController.CouponRow;
import org.springframework.stereotype.Service;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.zip.ZipEntry;
import java.util.zip.ZipOutputStream;

@Service
public class CouponExcelExportService {

    private static final DateTimeFormatter EXPORT_TIME_FORMAT = DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm:ss");

    public byte[] exportToExcel(List<CouponRow> rows) {
        try (ByteArrayOutputStream baos = new ByteArrayOutputStream();
             ZipOutputStream zos = new ZipOutputStream(baos)) {

            addZipEntry(zos, "[Content_Types].xml", buildContentTypesXml());
            addZipEntry(zos, "_rels/.rels", buildGlobalRelsXml());
            addZipEntry(zos, "xl/workbook.xml", buildWorkbookXml());
            addZipEntry(zos, "xl/_rels/workbook.xml.rels", buildWorkbookRelsXml());
            addZipEntry(zos, "xl/styles.xml", buildStylesXml());
            addZipEntry(zos, "xl/worksheets/sheet1.xml", buildCouponsSheet(rows));

            zos.finish();
            return baos.toByteArray();
        } catch (IOException e) {
            throw new RuntimeException("Lỗi tạo file Excel mã giảm giá: " + e.getMessage(), e);
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
                    <sheet name="Danh sách mã giảm giá" sheetId="1" r:id="rId1"/>
                  </sheets>
                </workbook>
                """.trim();
    }

    private String buildWorkbookRelsXml() {
        return """
                <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
                <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
                  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>
                  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
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
                    <fill><patternFill fillType="solid"><fgColor rgb="FF4F46E5"/></patternFill></fill>
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
                    <xf numFmtId="166" fontId="5" fillId="4" borderId="1" xfId="0" applyNumberFormat="1" applyFont="1" applyBorder="1" applyAlignment="1"><alignment horizontal="right" vertical="center"/></xf>
                    <xf numFmtId="164" fontId="5" fillId="4" borderId="1" xfId="0" applyNumberFormat="1" applyFont="1" applyFill="1" applyBorder="1" applyAlignment="1"><alignment horizontal="right" vertical="center"/></xf>
                  </cellXfs>
                </styleSheet>
                """.trim();
    }

    private String buildCouponsSheet(List<CouponRow> rows) {
        StringBuilder sb = new StringBuilder();
        sb.append("<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>\n");
        sb.append("<worksheet xmlns=\"http://schemas.openxmlformats.org/spreadsheetml/2006/main\">\n");
        sb.append("  <cols>\n");
        sb.append("    <col min=\"1\" max=\"1\" width=\"8\" customWidth=\"1\"/>\n");   // STT
        sb.append("    <col min=\"2\" max=\"2\" width=\"18\" customWidth=\"1\"/>\n");  // Mã code
        sb.append("    <col min=\"3\" max=\"3\" width=\"32\" customWidth=\"1\"/>\n");  // Tên chương trình
        sb.append("    <col min=\"4\" max=\"4\" width=\"22\" customWidth=\"1\"/>\n");  // Loại & giá trị
        sb.append("    <col min=\"5\" max=\"5\" width=\"18\" customWidth=\"1\"/>\n");  // Giảm tối đa
        sb.append("    <col min=\"6\" max=\"6\" width=\"18\" customWidth=\"1\"/>\n");  // Đơn tối thiểu
        sb.append("    <col min=\"7\" max=\"7\" width=\"12\" customWidth=\"1\"/>\n");  // Đã dùng
        sb.append("    <col min=\"8\" max=\"8\" width=\"12\" customWidth=\"1\"/>\n");  // Tổng lượt
        sb.append("    <col min=\"9\" max=\"9\" width=\"14\" customWidth=\"1\"/>\n");  // Giới hạn/khách
        sb.append("    <col min=\"10\" max=\"10\" width=\"24\" customWidth=\"1\"/>\n"); // Đối tượng
        sb.append("    <col min=\"11\" max=\"11\" width=\"22\" customWidth=\"1\"/>\n"); // Danh mục
        sb.append("    <col min=\"12\" max=\"12\" width=\"20\" customWidth=\"1\"/>\n"); // Bắt đầu
        sb.append("    <col min=\"13\" max=\"13\" width=\"20\" customWidth=\"1\"/>\n"); // Kết thúc
        sb.append("    <col min=\"14\" max=\"14\" width=\"16\" customWidth=\"1\"/>\n"); // Trạng thái
        sb.append("    <col min=\"15\" max=\"15\" width=\"20\" customWidth=\"1\"/>\n"); // Tổng tiền đã giảm
        sb.append("    <col min=\"16\" max=\"16\" width=\"22\" customWidth=\"1\"/>\n"); // Doanh thu mang lại
        sb.append("  </cols>\n");
        sb.append("  <sheetData>\n");

        int r = 1;
        startRow(sb, r);
        appendTextCell(sb, 1, r, 1, "DANH SÁCH MÃ GIẢM GIÁ & BÁO CÁO HIỆU QUẢ CHIẾN DỊCH");
        endRow(sb);
        r++;

        startRow(sb, r);
        appendTextCell(sb, 1, r, 2, "Thời gian xuất file: " + LocalDateTime.now().format(EXPORT_TIME_FORMAT));
        endRow(sb);
        r += 2;

        startRow(sb, r);
        appendTextCell(sb, 1, r, 5, "STT");
        appendTextCell(sb, 2, r, 5, "MÃ CODE");
        appendTextCell(sb, 3, r, 5, "TÊN CHƯƠNG TRÌNH");
        appendTextCell(sb, 4, r, 5, "LOẠI & GIÁ TRỊ");
        appendTextCell(sb, 5, r, 5, "GIẢM TỐI ĐA");
        appendTextCell(sb, 6, r, 5, "ĐƠN TỐI THIỂU");
        appendTextCell(sb, 7, r, 5, "ĐÃ DÙNG");
        appendTextCell(sb, 8, r, 5, "TỔNG LƯỢT");
        appendTextCell(sb, 9, r, 5, "GIỚI HẠN/KHÁCH");
        appendTextCell(sb, 10, r, 5, "ĐỐI TƯỢNG ÁP DỤNG");
        appendTextCell(sb, 11, r, 5, "DANH MỤC ÁP DỤNG");
        appendTextCell(sb, 12, r, 5, "BẮT ĐẦU");
        appendTextCell(sb, 13, r, 5, "KẾT THÚC");
        appendTextCell(sb, 14, r, 5, "TRẠNG THÁI");
        appendTextCell(sb, 15, r, 5, "TỔNG TIỀN ĐÃ GIẢM");
        appendTextCell(sb, 16, r, 5, "DOANH THU MANG LẠI");
        endRow(sb);
        r++;

        int index = 1;
        long sumUsed = 0;
        long sumQuantity = 0;
        BigDecimal sumDiscount = BigDecimal.ZERO;
        BigDecimal sumRevenue = BigDecimal.ZERO;

        for (CouponRow c : rows) {
            startRow(sb, r);
            appendNumberCell(sb, 1, r, 7, index++);
            appendTextCell(sb, 2, r, 7, c.getCode());
            appendTextCell(sb, 3, r, 6, c.getName());
            appendTextCell(sb, 4, r, 7, c.getDiscountText());
            appendTextCell(sb, 5, r, 7, c.getMaxDiscountText());
            appendTextCell(sb, 6, r, 7, c.getMinOrderText());
            appendNumberCell(sb, 7, r, 8, c.getUsedCount());
            appendNumberCell(sb, 8, r, 8, c.getQuantity());
            appendTextCell(sb, 9, r, 7, c.getPerUserLimit() + " lần/khách");
            appendTextCell(sb, 10, r, 6, c.getTargetCustomerText());
            appendTextCell(sb, 11, r, 6, c.getCategoryText());
            appendTextCell(sb, 12, r, 11, c.getStartDateText());
            appendTextCell(sb, 13, r, 11, c.getEndDateText());
            appendTextCell(sb, 14, r, 7, c.getComputedStatusText());
            appendNumberCell(sb, 15, r, 9, c.getTotalDiscount());
            appendNumberCell(sb, 16, r, 9, c.getTotalRevenue());
            endRow(sb);

            sumUsed += c.getUsedCount();
            sumQuantity += c.getQuantity();
            sumDiscount = sumDiscount.add(c.getTotalDiscount());
            sumRevenue = sumRevenue.add(c.getTotalRevenue());
            r++;
        }

        if (!rows.isEmpty()) {
            startRow(sb, r);
            appendTextCell(sb, 1, r, 12, "Tổng cộng");
            appendTextCell(sb, 2, r, 12, rows.size() + " mã");
            appendTextCell(sb, 3, r, 12, "");
            appendTextCell(sb, 4, r, 12, "");
            appendTextCell(sb, 5, r, 12, "");
            appendTextCell(sb, 6, r, 12, "");
            appendNumberCell(sb, 7, r, 13, sumUsed);
            appendNumberCell(sb, 8, r, 13, sumQuantity);
            appendTextCell(sb, 9, r, 12, "");
            appendTextCell(sb, 10, r, 12, "");
            appendTextCell(sb, 11, r, 12, "");
            appendTextCell(sb, 12, r, 12, "");
            appendTextCell(sb, 13, r, 12, "");
            appendTextCell(sb, 14, r, 12, "");
            appendNumberCell(sb, 15, r, 14, sumDiscount);
            appendNumberCell(sb, 16, r, 14, sumRevenue);
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
