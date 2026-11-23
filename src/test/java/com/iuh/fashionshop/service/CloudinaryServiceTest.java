package com.iuh.fashionshop.service;

import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockMultipartFile;

import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;

class CloudinaryServiceTest {

    @Test
    void validateImageFile_rejectsEmptyFile() {
        CloudinaryService service = new CloudinaryService("demo", "key", "secret");
        MockMultipartFile emptyFile = new MockMultipartFile(
                "image", "empty.png", "image/png", new byte[0]);

        IllegalArgumentException ex = assertThrows(
                IllegalArgumentException.class,
                () -> service.validateImageFile(emptyFile));
        assertTrue(ex.getMessage().contains("không được để trống"));
    }

    @Test
    void validateImageFile_rejectsUnsupportedExtension() {
        CloudinaryService service = new CloudinaryService("demo", "key", "secret");
        MockMultipartFile gifFile = new MockMultipartFile(
                "image", "avatar.gif", "image/gif", new byte[]{1, 2, 3});

        IllegalArgumentException ex = assertThrows(
                IllegalArgumentException.class,
                () -> service.validateImageFile(gifFile));
        assertTrue(ex.getMessage().contains("jpg, jpeg, png, webp"));
    }

    @Test
    void validateImageFile_rejectsUnsupportedContentType() {
        CloudinaryService service = new CloudinaryService("demo", "key", "secret");
        MockMultipartFile fakePng = new MockMultipartFile(
                "image", "fake.png", "text/plain", new byte[]{1, 2, 3});

        assertThrows(IllegalArgumentException.class, () -> service.validateImageFile(fakePng));
    }

    @Test
    void uploadImage_throwsWhenNotConfigured() {
        CloudinaryService service = new CloudinaryService("", "", "");
        MockMultipartFile validFile = new MockMultipartFile(
                "image", "shirt.webp", "image/webp", new byte[]{1, 2, 3});

        assertThrows(IllegalStateException.class, () -> service.uploadImage(validFile));
    }

    @Test
    void uploadImage_returnsSecureUrlAndPublicId() {
        CloudinaryService service = new CloudinaryService("jgeiayv9", "972987957115115", "secret") {
            @Override
            protected Map<?, ?> uploadBytes(byte[] bytes) {
                return Map.of(
                        "secure_url", "https://res.cloudinary.com/jgeiayv9/image/upload/v1/fashionshop/products/abc.png",
                        "public_id", "fashionshop/products/abc"
                );
            }
        };

        MockMultipartFile validFile = new MockMultipartFile(
                "image", "shirt.png", "image/png", new byte[]{1, 2, 3, 4});

        CloudinaryService.CloudinaryUploadResult result = service.uploadImage(validFile);

        assertEquals("https://res.cloudinary.com/jgeiayv9/image/upload/v1/fashionshop/products/abc.png",
                result.secureUrl());
        assertEquals("fashionshop/products/abc", result.publicId());
    }
}
