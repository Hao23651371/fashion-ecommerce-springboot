package com.iuh.fashionshop.controller;

import com.iuh.fashionshop.model.Order;
import com.iuh.fashionshop.model.enums.OrderStatus;
import com.iuh.fashionshop.model.enums.PaymentMethod;
import com.iuh.fashionshop.model.enums.PaymentStatus;
import com.iuh.fashionshop.service.OrderService;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import java.util.List;

/**
 * Admin: danh sách đơn, chi tiết, đổi trạng thái, xác nhận thanh toán COD/CK.
 */
@Controller
@RequestMapping("/admin/orders")
public class AdminOrderController {

    private final OrderService orderService;

    public AdminOrderController(OrderService orderService) {
        this.orderService = orderService;
    }

    @GetMapping
    public String list(@RequestParam(required = false) String q,
                       @RequestParam(required = false) String status,
                       @RequestParam(required = false) String payment,
                       @RequestParam(required = false) String from,
                       @RequestParam(required = false) String to,
                       Model model) {
        List<Order> orders = orderService.searchForAdmin(q, status, payment, from, to);

        model.addAttribute("pageTitle", "Đơn hàng");
        model.addAttribute("orders", orders);
        model.addAttribute("q", q);
        model.addAttribute("status", status);
        model.addAttribute("payment", payment);
        model.addAttribute("from", from);
        model.addAttribute("to", to);

        model.addAttribute("pendingCount", orderService.countByStatus(OrderStatus.PENDING));
        model.addAttribute("confirmedCount", orderService.countByStatus(OrderStatus.CONFIRMED));
        model.addAttribute("shippingCount", orderService.countByStatus(OrderStatus.SHIPPING));
        model.addAttribute("completedCount", orderService.countByStatus(OrderStatus.COMPLETED));
        model.addAttribute("cancelledCount", orderService.countByStatus(OrderStatus.CANCELLED));
        return "admin/orders";
    }

    @GetMapping("/{id}")
    public String detail(@PathVariable Long id, Model model, RedirectAttributes ra) {
        try {
            Order order = orderService.getByIdForAdmin(id);
            model.addAttribute("pageTitle", "Đơn " + order.getOrderCode());
            model.addAttribute("order", order);
            model.addAttribute("canConfirm", order.getStatus() == OrderStatus.PENDING);
            model.addAttribute("canShip", order.getStatus() == OrderStatus.PENDING
                    || order.getStatus() == OrderStatus.CONFIRMED);
            model.addAttribute("canComplete", order.getStatus() == OrderStatus.CONFIRMED
                    || order.getStatus() == OrderStatus.SHIPPING);
            model.addAttribute("canCancel", order.getStatus() == OrderStatus.PENDING
                    || order.getStatus() == OrderStatus.CONFIRMED);

            PaymentMethod method = order.getPaymentInfo() != null
                    ? order.getPaymentInfo().getPaymentMethod() : null;
            PaymentStatus payStatus = order.getPaymentInfo() != null
                    ? order.getPaymentInfo().getPaymentStatus() : null;
            model.addAttribute("canMarkBankPaid",
                    method == PaymentMethod.BANK_TRANSFER && payStatus != PaymentStatus.PAID
                            && order.getStatus() != OrderStatus.CANCELLED);
            model.addAttribute("canMarkCodPaid",
                    method == PaymentMethod.COD && payStatus != PaymentStatus.PAID
                            && order.getStatus() != OrderStatus.CANCELLED);
            return "admin/order-detail";
        } catch (IllegalArgumentException e) {
            ra.addFlashAttribute("errorMessage", e.getMessage());
            return "redirect:/admin/orders";
        }
    }

    @PostMapping("/{id}/status")
    public String updateStatus(@PathVariable Long id,
                               @RequestParam String status,
                               @RequestParam(required = false) String cancelReason,
                               RedirectAttributes ra) {
        try {
            OrderStatus target = OrderStatus.valueOf(status.trim().toUpperCase());
            Order order = orderService.updateStatus(id, target, cancelReason);
            ra.addFlashAttribute("successMessage",
                    "Đã cập nhật đơn " + order.getOrderCode() + " → " + order.getStatus()
                            + (order.getPaymentInfo() != null
                            ? " | Thanh toán: " + order.getPaymentInfo().getPaymentStatus()
                            : ""));
        } catch (Exception e) {
            ra.addFlashAttribute("errorMessage", e.getMessage());
        }
        return "redirect:/admin/orders/" + id;
    }

    @PostMapping("/{id}/mark-bank-paid")
    public String markBankPaid(@PathVariable Long id, RedirectAttributes ra) {
        try {
            Order order = orderService.confirmBankTransferPaid(id);
            ra.addFlashAttribute("successMessage",
                    "Đã xác nhận chuyển khoản cho đơn " + order.getOrderCode());
        } catch (Exception e) {
            ra.addFlashAttribute("errorMessage", e.getMessage());
        }
        return "redirect:/admin/orders/" + id;
    }

    @PostMapping("/{id}/mark-cod-paid")
    public String markCodPaid(@PathVariable Long id, RedirectAttributes ra) {
        try {
            Order order = orderService.confirmCodCollected(id);
            ra.addFlashAttribute("successMessage",
                    "Đã ghi nhận thu COD cho đơn " + order.getOrderCode());
        } catch (Exception e) {
            ra.addFlashAttribute("errorMessage", e.getMessage());
        }
        return "redirect:/admin/orders/" + id;
    }
}
