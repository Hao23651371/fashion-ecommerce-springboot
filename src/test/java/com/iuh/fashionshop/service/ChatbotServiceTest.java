package com.iuh.fashionshop.service;

import com.iuh.fashionshop.dto.ProductDetailDto;
import com.iuh.fashionshop.dto.ProductDetailDto.ColorDto;
import com.iuh.fashionshop.dto.ProductDetailDto.VariantDto;
import com.iuh.fashionshop.model.Coupon;
import com.iuh.fashionshop.model.enums.CouponStatus;
import com.iuh.fashionshop.model.enums.DiscountType;
import com.iuh.fashionshop.model.enums.Gender;
import com.iuh.fashionshop.model.enums.ProductStatus;
import com.iuh.fashionshop.repository.CouponRepository;
import com.iuh.fashionshop.service.ai.GeminiChatClient;
import com.iuh.fashionshop.service.ai.OllamaChatClient;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class ChatbotServiceTest {

    @Mock
    private ProductSearchService searchService;

    @Mock
    private ProductService productService;

    @Mock
    private CouponRepository couponRepository;

    @Mock
    private OllamaChatClient ollamaChatClient;

    @Mock
    private GeminiChatClient geminiChatClient;

    private ChatbotService chatbotService;

    private List<ProductDetailDto> mockProducts;

    @BeforeEach
    void setUp() {
        chatbotService = new ChatbotService(
                searchService,
                productService,
                couponRepository,
                ollamaChatClient,
                geminiChatClient,
                "ollama",
                false
        );

        // Chuẩn bị danh sách sản phẩm mẫu đầy đủ thông tin size, màu, tồn kho
        mockProducts = List.of(
                new ProductDetailDto(
                        1L, "Đầm lụa dáng dài màu be", 1L, "Đầm", "Mô tả đầm lụa",
                        "img1.jpg", BigDecimal.valueOf(1850000), BigDecimal.valueOf(1590000),
                        true, 14, BigDecimal.valueOf(1590000), Gender.FEMALE, "Thời trang Nữ",
                        ProductStatus.ACTIVE, LocalDateTime.now(), 35, false,
                        List.of(
                                new VariantDto(101L, "S", "Be", "SKU1-S", 12, true),
                                new VariantDto(102L, "M", "Be", "SKU1-M", 15, true),
                                new VariantDto(103L, "L", "Be", "SKU1-L", 8, true)
                        ),
                        List.of(new ColorDto("Be", "#d8c3a5")),
                        List.of("S", "M", "L")
                ),
                new ProductDetailDto(
                        2L, "Áo sơ mi linen trắng tối giản", 2L, "Áo sơ mi", "Mô tả sơ mi",
                        "img2.jpg", BigDecimal.valueOf(690000), null,
                        false, 0, BigDecimal.valueOf(690000), Gender.UNISEX, "Thời trang Nam Nữ",
                        ProductStatus.ACTIVE, LocalDateTime.now(), 73, false,
                        List.of(
                                new VariantDto(201L, "S", "Trắng", "SKU2-S", 20, true),
                                new VariantDto(202L, "M", "Trắng", "SKU2-M", 25, true),
                                new VariantDto(203L, "L", "Trắng", "SKU2-L", 18, true),
                                new VariantDto(204L, "M", "Xanh nhạt", "SKU2-XM", 10, true)
                        ),
                        List.of(new ColorDto("Trắng", "#ffffff"), new ColorDto("Xanh nhạt", "#bcd4e6")),
                        List.of("S", "M", "L")
                ),
                new ProductDetailDto(
                        8L, "Áo thun cotton basic cổ tròn màu trắng", 3L, "Áo thun", "Mô tả áo thun",
                        "img8.jpg", BigDecimal.valueOf(290000), null,
                        false, 0, BigDecimal.valueOf(290000), Gender.UNISEX, "Thời trang Nam Nữ",
                        ProductStatus.ACTIVE, LocalDateTime.now(), 150, false,
                        List.of(
                                new VariantDto(801L, "S", "Trắng", "SKU8-S", 30, true),
                                new VariantDto(802L, "M", "Trắng", "SKU8-M", 40, true),
                                new VariantDto(803L, "L", "Trắng", "SKU8-L", 35, true),
                                new VariantDto(804L, "XL", "Trắng", "SKU8-XL", 20, true),
                                new VariantDto(805L, "M", "Đen", "SKU8-MD", 25, true)
                        ),
                        List.of(new ColorDto("Trắng", "#ffffff"), new ColorDto("Đen", "#111111")),
                        List.of("S", "M", "L", "XL")
                ),
                new ProductDetailDto(
                        9L, "Áo thun oversize màu đen in chữ", 3L, "Áo thun", "Mô tả áo thun over",
                        "img9.jpg", BigDecimal.valueOf(390000), BigDecimal.valueOf(329000),
                        true, 16, BigDecimal.valueOf(329000), Gender.UNISEX, "Thời trang Nam Nữ",
                        ProductStatus.ACTIVE, LocalDateTime.now(), 63, false,
                        List.of(
                                new VariantDto(901L, "M", "Đen", "SKU9-M", 22, true),
                                new VariantDto(902L, "L", "Đen", "SKU9-L", 26, true),
                                new VariantDto(903L, "XL", "Đen", "SKU9-XL", 15, true)
                        ),
                        List.of(new ColorDto("Đen", "#111111")),
                        List.of("M", "L", "XL")
                ),
                new ProductDetailDto(
                        12L, "Quần short kaki nam màu xanh rêu", 4L, "Quần", "Mô tả quần short",
                        "img12.jpg", BigDecimal.valueOf(490000), null,
                        false, 0, BigDecimal.valueOf(490000), Gender.MALE, "Thời trang Nam",
                        ProductStatus.ACTIVE, LocalDateTime.now(), 39, false,
                        List.of(
                                new VariantDto(1201L, "M", "Xanh rêu", "SKU12-M", 14, true),
                                new VariantDto(1202L, "L", "Xanh rêu", "SKU12-L", 16, true),
                                new VariantDto(1203L, "XL", "Xanh rêu", "SKU12-XL", 9, true)
                        ),
                        List.of(new ColorDto("Xanh rêu", "#6b7a3d")),
                        List.of("M", "L", "XL")
                ),
                new ProductDetailDto(
                        13L, "Đầm midi hoa nhí màu hồng phấn", 1L, "Đầm", "Mô tả đầm hoa",
                        "img13.jpg", BigDecimal.valueOf(1250000), BigDecimal.valueOf(990000),
                        true, 21, BigDecimal.valueOf(990000), Gender.FEMALE, "Thời trang Nữ",
                        ProductStatus.ACTIVE, LocalDateTime.now(), 26, false,
                        List.of(
                                new VariantDto(1301L, "S", "Hồng phấn", "SKU13-S", 8, true),
                                new VariantDto(1302L, "M", "Hồng phấn", "SKU13-M", 12, true),
                                new VariantDto(1303L, "L", "Hồng phấn", "SKU13-L", 6, true)
                        ),
                        List.of(new ColorDto("Hồng phấn", "#f4c2c2")),
                        List.of("S", "M", "L")
                )
        );
    }

    @Test
    void testCouponInquiry_DoesNotConfuseWithSale() {
        Coupon c = new Coupon();
        c.setCode("SUMMER20");
        c.setName("Giảm giá mùa hè");
        c.setDiscountType(DiscountType.PERCENT);
        c.setDiscountValue(BigDecimal.valueOf(20));
        c.setMinOrderValue(BigDecimal.valueOf(500000));
        c.setStartDate(LocalDateTime.now().minusDays(1));
        c.setEndDate(LocalDateTime.now().plusDays(10));
        c.setQuantity(100);
        c.setUsedCount(5);
        c.setStatus(CouponStatus.ACTIVE);

        when(couponRepository.findActiveCoupons(eq(CouponStatus.ACTIVE), any())).thenReturn(List.of(c));

        String reply1 = chatbotService.reply("Có mã giảm giá không?");
        assertNotNull(reply1);
        assertTrue(reply1.contains("SUMMER20"));
        assertTrue(reply1.contains("Mã Giảm Giá"));
        // Đảm bảo không bị nhầm sang danh sách sản phẩm sale
        assertFalse(reply1.contains("Đầm lụa dáng dài"));

        String reply2 = chatbotService.reply("shop có voucher nào không?");
        assertTrue(reply2.contains("SUMMER20"));
    }

    @Test
    void testCategorySale_OnlyReturnsDresses() {
        when(productService.getAllActiveDetails()).thenReturn(mockProducts);

        // "Đầm nào đang giảm giá?"
        String reply = chatbotService.reply("Đầm nào đang giảm giá?");
        assertNotNull(reply);
        // Phải chứa các đầm đang sale
        assertTrue(reply.contains("Đầm lụa dáng dài màu be"));
        assertTrue(reply.contains("Đầm midi hoa nhí màu hồng phấn"));
        // Tuyệt đối KHÔNG chứa áo thun sale hay áo sơ mi không phải đầm
        assertFalse(reply.contains("Áo thun oversize"));
        assertFalse(reply.contains("Áo sơ mi linen"));
        // Có link /shop/
        assertTrue(reply.contains("/shop/1"));
        assertTrue(reply.contains("/shop/13"));
    }

    @Test
    void testPriceFilter_Under500k_ReturnsAtLeast5Items() {
        when(productService.getAllActiveDetails()).thenReturn(mockProducts);

        String reply = chatbotService.reply("dưới 500k");
        assertNotNull(reply);
        // Kiểm tra danh sách hiển thị
        assertTrue(reply.contains("Áo thun cotton basic cổ tròn màu trắng"));
        assertTrue(reply.contains("Áo thun oversize màu đen in chữ"));
        assertTrue(reply.contains("Quần short kaki nam màu xanh rêu"));

        // Kiểm tra cam kết ít nhất 5 món: có ít nhất 5 mục "1.", "2.", "3.", "4.", "5."
        assertTrue(reply.contains("1."));
        assertTrue(reply.contains("2."));
        assertTrue(reply.contains("3."));
        assertTrue(reply.contains("4."));
        assertTrue(reply.contains("5."));
    }

    @Test
    void testStockAndVariantsInquiry() {
        when(productService.getAllActiveDetails()).thenReturn(mockProducts);

        // Khách hỏi về tồn kho của Đầm lụa
        String reply = chatbotService.reply("Đầm lụa còn size M không?");
        assertNotNull(reply);
        assertTrue(reply.contains("Đầm lụa dáng dài màu be"));
        assertTrue(reply.contains("Kích cỡ có sẵn"));
        assertTrue(reply.contains("S, M, L"));
        assertTrue(reply.contains("Màu sắc có sẵn"));
        assertTrue(reply.contains("Be"));
        assertTrue(reply.contains("Size M"));
        assertTrue(reply.contains("Tổng tồn kho"));
        assertTrue(reply.contains("35 sản phẩm"));
        assertTrue(reply.contains("/shop/1"));
    }

    @Test
    void testStorePolicy() {
        String reply = chatbotService.reply("chính sách đổi trả của shop thế nào?");
        assertNotNull(reply);
        assertTrue(reply.contains("Đổi trả dễ dàng"));
        assertTrue(reply.contains("7 ngày"));
        assertTrue(reply.contains("1900 6868"));
    }
}
