package com.iuh.fashionshop.service;

import com.iuh.fashionshop.model.Account;
import com.iuh.fashionshop.model.CartItem;
import com.iuh.fashionshop.model.ProductVariant;
import com.iuh.fashionshop.model.UserProfile;
import com.iuh.fashionshop.model.enums.VariantStatus;
import com.iuh.fashionshop.repository.AccountRepository;
import com.iuh.fashionshop.repository.CartItemRepository;
import com.iuh.fashionshop.repository.ProductVariantRepository;
import com.iuh.fashionshop.repository.UserProfileRepository;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

@Service
@Transactional
public class CartService {

    private final CartItemRepository cartItemRepository;
    private final ProductVariantRepository productVariantRepository;
    private final UserProfileRepository userProfileRepository;
    private final AccountRepository accountRepository;

    public CartService(CartItemRepository cartItemRepository,
                       ProductVariantRepository productVariantRepository,
                       UserProfileRepository userProfileRepository,
                       AccountRepository accountRepository) {
        this.cartItemRepository = cartItemRepository;
        this.productVariantRepository = productVariantRepository;
        this.userProfileRepository = userProfileRepository;
        this.accountRepository = accountRepository;
    }

    @Transactional(readOnly = true)
    public List<CartItem> getCartItems(Authentication auth) {
        UserProfile profile = getOrCreateProfile(auth);
        if (profile == null) {
            return new ArrayList<>();
        }
        return cartItemRepository.findByProfileIdWithDetails(profile.getId());
    }

    @Transactional(readOnly = true)
    public int getCartCount(Authentication auth) {
        UserProfile profile = getOrCreateProfile(auth);
        if (profile == null) {
            return 0;
        }
        return cartItemRepository.countTotalQuantityByProfileId(profile.getId());
    }

    @Transactional(readOnly = true)
    public BigDecimal getCartSubtotal(Authentication auth) {
        List<CartItem> items = getCartItems(auth);
        BigDecimal subtotal = BigDecimal.ZERO;
        for (CartItem item : items) {
            subtotal = subtotal.add(item.calculateSubtotal());
        }
        return subtotal;
    }

    public int addToCart(Long variantId, int quantity, Authentication auth) {
        if (quantity <= 0) {
            throw new IllegalArgumentException("Số lượng phải lớn hơn 0");
        }
        UserProfile profile = getOrCreateProfile(auth);
        if (profile == null) {
            throw new IllegalStateException("Vui lòng đăng nhập để thêm sản phẩm vào giỏ hàng");
        }

        ProductVariant variant = productVariantRepository.findByIdWithProduct(variantId)
                .orElseThrow(() -> new IllegalArgumentException("Biến thể sản phẩm không tồn tại"));

        if (variant.getStatus() != VariantStatus.ACTIVE || variant.getStockQuantity() <= 0) {
            throw new IllegalStateException("Sản phẩm này hiện đang hết hàng");
        }

        Optional<CartItem> existingOpt = cartItemRepository.findByUserProfileIdAndVariantId(profile.getId(), variantId);
        if (existingOpt.isPresent()) {
            CartItem existing = existingOpt.get();
            int newQty = existing.getQuantity() + quantity;
            if (newQty > variant.getStockQuantity()) {
                newQty = variant.getStockQuantity();
            }
            existing.setQuantity(newQty);
            cartItemRepository.save(existing);
        } else {
            int initialQty = Math.min(quantity, variant.getStockQuantity());
            CartItem item = new CartItem();
            item.setUserProfile(profile);
            item.setVariant(variant);
            item.setQuantity(initialQty);
            cartItemRepository.save(item);
        }

        return cartItemRepository.countTotalQuantityByProfileId(profile.getId());
    }

    public void updateQuantity(Long cartItemId, int quantity, Authentication auth) {
        UserProfile profile = getOrCreateProfile(auth);
        if (profile == null) {
            throw new IllegalStateException("Vui lòng đăng nhập");
        }

        CartItem item = cartItemRepository.findById(cartItemId)
                .orElseThrow(() -> new IllegalArgumentException("Mục giỏ hàng không tồn tại"));

        if (!item.getUserProfile().getId().equals(profile.getId())) {
            throw new IllegalStateException("Bạn không có quyền chỉnh sửa mục này");
        }

        if (quantity <= 0) {
            cartItemRepository.delete(item);
            return;
        }

        int maxStock = item.getVariant().getStockQuantity();
        item.setQuantity(Math.min(quantity, maxStock));
        cartItemRepository.save(item);
    }

    public int removeItem(Long cartItemId, Authentication auth) {
        UserProfile profile = getOrCreateProfile(auth);
        if (profile == null) {
            throw new IllegalStateException("Vui lòng đăng nhập");
        }

        CartItem item = cartItemRepository.findById(cartItemId)
                .orElseThrow(() -> new IllegalArgumentException("Mục giỏ hàng không tồn tại"));

        if (!item.getUserProfile().getId().equals(profile.getId())) {
            throw new IllegalStateException("Bạn không có quyền xóa mục này");
        }

        cartItemRepository.delete(item);
        return cartItemRepository.countTotalQuantityByProfileId(profile.getId());
    }

    public void clearCart(Authentication auth) {
        UserProfile profile = getOrCreateProfile(auth);
        if (profile != null) {
            cartItemRepository.deleteAllByUserProfileId(profile.getId());
        }
    }

    public UserProfile getOrCreateProfile(Authentication auth) {
        if (auth == null || !auth.isAuthenticated() || "anonymousUser".equals(auth.getName())) {
            return null;
        }
        String email = auth.getName().trim().toLowerCase();
        Optional<UserProfile> profileOpt = userProfileRepository.findByAccountEmail(email);
        if (profileOpt.isPresent()) {
            return profileOpt.get();
        }

        Optional<Account> accountOpt = accountRepository.findByEmail(email);
        if (accountOpt.isPresent()) {
            UserProfile profile = new UserProfile();
            profile.setAccount(accountOpt.get());
            profile.setFullName(email);
            return userProfileRepository.save(profile);
        }

        return null;
    }
}

