package com.iuh.fashionshop.service;

import com.iuh.fashionshop.dto.ProductCardDto;
import com.iuh.fashionshop.model.Account;
import com.iuh.fashionshop.model.Product;
import com.iuh.fashionshop.model.UserProfile;
import com.iuh.fashionshop.model.WishlistItem;
import com.iuh.fashionshop.repository.AccountRepository;
import com.iuh.fashionshop.repository.OrderRepository;
import com.iuh.fashionshop.repository.ProductRepository;
import com.iuh.fashionshop.repository.UserProfileRepository;
import com.iuh.fashionshop.repository.WishlistItemRepository;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

@Service
@Transactional
public class WishlistService {

    private final WishlistItemRepository wishlistItemRepository;
    private final UserProfileRepository userProfileRepository;
    private final AccountRepository accountRepository;
    private final ProductRepository productRepository;
    private final OrderRepository orderRepository;
    private final ProductService productService;

    public WishlistService(WishlistItemRepository wishlistItemRepository,
                           UserProfileRepository userProfileRepository,
                           AccountRepository accountRepository,
                           ProductRepository productRepository,
                           OrderRepository orderRepository,
                           ProductService productService) {
        this.wishlistItemRepository = wishlistItemRepository;
        this.userProfileRepository = userProfileRepository;
        this.accountRepository = accountRepository;
        this.productRepository = productRepository;
        this.orderRepository = orderRepository;
        this.productService = productService;
    }

    @Transactional(readOnly = true)
    public List<ProductCardDto> getWishlistCards(Authentication auth) {
        Long profileId = getOrCreateProfileId(auth);
        if (profileId == null) {
            return new ArrayList<>();
        }
        List<Long> productIds = wishlistItemRepository.findProductIdsByProfileId(profileId);
        if (productIds == null || productIds.isEmpty()) {
            return new ArrayList<>();
        }
        return productService.getCardsByIds(productIds);
    }

    @Transactional(readOnly = true)
    public int getWishlistCount(Authentication auth) {
        if (auth == null || !auth.isAuthenticated() || "anonymousUser".equals(auth.getName())) {
            return 0;
        }
        return wishlistItemRepository.countByAccountEmail(auth.getName().trim().toLowerCase());
    }

    @Transactional(readOnly = true)
    public long getOrderCount(Authentication auth) {
        Long profileId = getOrCreateProfileId(auth);
        if (profileId == null) {
            return 0;
        }
        return orderRepository.countByUserProfileId(profileId);
    }

    public int removeItem(Long productId, Authentication auth) {
        Long profileId = getOrCreateProfileId(auth);
        if (profileId == null || productId == null) {
            return 0;
        }
        wishlistItemRepository.deleteByUserProfileIdAndProductId(profileId, productId);
        return wishlistItemRepository.countByUserProfileId(profileId);
    }

    public void clearAll(Authentication auth) {
        Long profileId = getOrCreateProfileId(auth);
        if (profileId != null) {
            wishlistItemRepository.deleteAllByUserProfileId(profileId);
        }
    }

    public boolean toggleItem(Long productId, Authentication auth) {
        Long profileId = getOrCreateProfileId(auth);
        if (profileId == null || productId == null) {
            throw new IllegalStateException("Vui lòng đăng nhập");
        }

        Optional<WishlistItem> existing = wishlistItemRepository.findByUserProfileIdAndProductId(profileId, productId);
        if (existing.isPresent()) {
            wishlistItemRepository.delete(existing.get());
            return false;
        }

        UserProfile userProfile = userProfileRepository.findById(profileId)
                .orElseThrow(() -> new IllegalStateException("Hồ sơ người dùng không tồn tại"));
        Product product = productRepository.findById(productId)
                .orElseThrow(() -> new IllegalArgumentException("Sản phẩm không tồn tại"));

        WishlistItem item = new WishlistItem();
        item.setUserProfile(userProfile);
        item.setProduct(product);
        wishlistItemRepository.save(item);
        return true;
    }

    @Transactional(readOnly = true)
    public boolean isWishlisted(Long productId, Authentication auth) {
        Long profileId = getOrCreateProfileId(auth);
        if (profileId == null || productId == null) {
            return false;
        }
        return wishlistItemRepository.existsByUserProfileIdAndProductId(profileId, productId);
    }

    public Long getOrCreateProfileId(Authentication auth) {
        if (auth == null || !auth.isAuthenticated() || "anonymousUser".equals(auth.getName())) {
            return null;
        }
        String email = auth.getName() != null ? auth.getName().trim().toLowerCase() : "";
        Optional<UserProfile> profileOpt = userProfileRepository.findByAccountEmail(email);
        if (profileOpt.isPresent()) {
            return profileOpt.get().getId();
        }

        // Tự động khởi tạo UserProfile nếu Account đã có nhưng chưa có UserProfile
        Optional<Account> accountOpt = accountRepository.findByEmail(email);
        if (accountOpt.isPresent()) {
            UserProfile profile = new UserProfile();
            profile.setAccount(accountOpt.get());
            profile.setFullName(email);
            return userProfileRepository.save(profile).getId();
        }

        return null;
    }
}
