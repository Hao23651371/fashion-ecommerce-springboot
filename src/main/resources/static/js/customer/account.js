// Account & Address Book JavaScript (customer/account.js)
document.addEventListener('DOMContentLoaded', function () {

    // =========================================================================
    // 1. DỮ LIỆU ĐỊA CHÍNH VIỆT NAM (63 TỈNH / THÀNH PHỐ + QUẬN HUYỆN + PHƯỜNG XÃ)
    // =========================================================================
    const VIETNAM_LOCATIONS = [
        {
            name: "TP. Hồ Chí Minh",
            districts: [
                {
                    name: "Quận 1",
                    wards: ["Phường Bến Nghé", "Phường Bến Thành", "Phường Cô Giang", "Phường Cầu Kho", "Phường Cầu Ông Lãnh", "Phường Đa Kao", "Phường Nguyễn Cư Trinh", "Phường Nguyễn Thái Bình", "Phường Phạm Ngũ Lão", "Phường Tân Định"]
                },
                {
                    name: "Quận 3",
                    wards: ["Phường Võ Thị Sáu", "Phường 1", "Phường 2", "Phường 3", "Phường 4", "Phường 5", "Phường 9", "Phường 11", "Phường 12", "Phường 14"]
                },
                {
                    name: "Quận 4",
                    wards: ["Phường 1", "Phường 2", "Phường 3", "Phường 4", "Phường 6", "Phường 8", "Phường 9", "Phường 13", "Phường 15", "Phường 16", "Phường 18"]
                },
                {
                    name: "Quận 5",
                    wards: ["Phường 1", "Phường 2", "Phường 3", "Phường 4", "Phường 5", "Phường 6", "Phường 7", "Phường 8", "Phường 9", "Phường 11", "Phường 12", "Phường 14"]
                },
                {
                    name: "Quận 6",
                    wards: ["Phường 1", "Phường 2", "Phường 3", "Phường 4", "Phường 5", "Phường 6", "Phường 7", "Phường 8", "Phường 9", "Phường 10", "Phường 11", "Phường 12", "Phường 13", "Phường 14"]
                },
                {
                    name: "Quận 7",
                    wards: ["Phường Tân Thuận Đông", "Phường Tân Thuận Tây", "Phường Tân Kiểng", "Phường Tân Hưng", "Phường Bình Thuận", "Phường Tân Quy", "Phường Phú Thuận", "Phường Tân Phú", "Phường Tân Phong", "Phường Phú Mỹ"]
                },
                {
                    name: "Quận 8",
                    wards: ["Phường 1", "Phường 2", "Phường 3", "Phường 4", "Phường 5", "Phường 6", "Phường 7", "Phường 8", "Phường 9", "Phường 10", "Phường 14", "Phường 15", "Phường 16"]
                },
                {
                    name: "Quận 10",
                    wards: ["Phường 1", "Phường 2", "Phường 4", "Phường 5", "Phường 6", "Phường 7", "Phường 8", "Phường 9", "Phường 10", "Phường 11", "Phường 12", "Phường 13", "Phường 14", "Phường 15"]
                },
                {
                    name: "Quận 11",
                    wards: ["Phường 1", "Phường 2", "Phường 3", "Phường 5", "Phường 7", "Phường 8", "Phường 9", "Phường 11", "Phường 13", "Phường 14", "Phường 15", "Phường 16"]
                },
                {
                    name: "Quận 12",
                    wards: ["Phường Thạnh Xuân", "Phường Thạnh Lộc", "Phường Hiệp Thành", "Phường Thới An", "Phường Tân Chánh Hiệp", "Phường An Phú Đông", "Phường Tân Thới Hiệp", "Phường Trung Mỹ Tây", "Phường Tân Hưng Thuận", "Phường Đông Hưng Thuận", "Phường Tân Thới Nhất"]
                },
                {
                    name: "Quận Gò Vấp",
                    wards: ["Phường 1", "Phường 3", "Phường 4", "Phường 5", "Phường 6", "Phường 7", "Phường 8", "Phường 9", "Phường 10", "Phường 11", "Phường 12", "Phường 13", "Phường 14", "Phường 15", "Phường 16", "Phường 17"]
                },
                {
                    name: "Quận Bình Thạnh",
                    wards: ["Phường 1", "Phường 2", "Phường 3", "Phường 5", "Phường 6", "Phường 7", "Phường 11", "Phường 12", "Phường 13", "Phường 14", "Phường 15", "Phường 17", "Phường 19", "Phường 21", "Phường 22", "Phường 24", "Phường 25", "Phường 26", "Phường 27", "Phường 28"]
                },
                {
                    name: "Quận Tân Bình",
                    wards: ["Phường 1", "Phường 2", "Phường 3", "Phường 4", "Phường 5", "Phường 6", "Phường 7", "Phường 8", "Phường 9", "Phường 10", "Phường 11", "Phường 12", "Phường 13", "Phường 14", "Phường 15"]
                },
                {
                    name: "Quận Tân Phú",
                    wards: ["Phường Tân Sơn Nhì", "Phường Tây Thạnh", "Phường Sơn Kỳ", "Phường Tân Quý", "Phường Tân Thành", "Phường Phú Thọ Hòa", "Phường Phú Thạnh", "Phường Phú Trung", "Phường Hòa Thạnh", "Phường Hiệp Tân", "Phường Tân Thới Hòa"]
                },
                {
                    name: "Quận Phú Nhuận",
                    wards: ["Phường 1", "Phường 2", "Phường 3", "Phường 4", "Phường 5", "Phường 7", "Phường 8", "Phường 9", "Phường 10", "Phường 11", "Phường 13", "Phường 15", "Phường 17"]
                },
                {
                    name: "Quận Bình Tân",
                    wards: ["Phường Bình Hưng Hòa", "Phường Bình Hưng Hòa A", "Phường Bình Hưng Hòa B", "Phường Bình Trị Đông", "Phường Bình Trị Đông A", "Phường Bình Trị Đông B", "Phường Tân Tạo", "Phường Tân Tạo A", "Phường An Lạc", "Phường An Lạc A"]
                },
                {
                    name: "TP. Thủ Đức",
                    wards: ["Phường Thảo Điền", "Phường An Phú", "Phường Hiệp Phú", "Phường Linh Trung", "Phường Linh Tây", "Phường Thủ Thiêm", "Phường Tam Phú", "Phường Trường Thọ", "Phường Linh Chiểu", "Phường Tăng Nhơn Phú A", "Phường Tăng Nhơn Phú B", "Phường Phước Long A", "Phường Phước Long B"]
                },
                {
                    name: "Huyện Bình Chánh",
                    wards: ["Thị trấn Tân Túc", "Xã An Phú Tây", "Xã Bình Chánh", "Xã Bình Hưng", "Xã Bình Lợi", "Xã Đa Phước", "Xã Hưng Long", "Xã Lê Minh Xuân", "Xã Phạm Văn Hai", "Xã Phong Phú", "Xã Quy Đức", "Xã Tân Kiên", "Xã Tân Nhựt", "Xã Tân Quý Tây", "Xã Vĩnh Lộc A", "Xã Vĩnh Lộc B"]
                },
                {
                    name: "Huyện Củ Chi",
                    wards: ["Thị trấn Củ Chi", "Xã Phú Hòa Đông", "Xã Tân Thạnh Đông", "Xã Tân Thạnh Tây", "Xã Trung An", "Xã Phước Vĩnh An", "Xã Hòa Phú", "Xã Thái Mỹ"]
                },
                {
                    name: "Huyện Hóc Môn",
                    wards: ["Thị trấn Hóc Môn", "Xã Bà Điểm", "Xã Đông Thạnh", "Xã Nhị Bình", "Xã Tân Hiệp", "Xã Tân Thới Nhì", "Xã Tân Xuân", "Xã Thới Tam Thôn", "Xã Trung Chánh", "Xã Xuân Thới Đông", "Xã Xuân Thới Sơn", "Xã Xuân Thới Thượng"]
                },
                {
                    name: "Huyện Nhà Bè",
                    wards: ["Thị trấn Nhà Bè", "Xã Phước Kiển", "Xã Phước Lộc", "Xã Nhơn Đức", "Xã Phú Xuân", "Xã Long Thới", "Xã Hiệp Phước"]
                },
                {
                    name: "Huyện Cần Giờ",
                    wards: ["Thị trấn Cần Thạnh", "Xã Long Hòa", "Xã Thạnh An", "Xã Lý Nhơn", "Xã Tam Thôn Hiệp", "Xã An Thới Đông", "Xã Bình Khánh"]
                }
            ]
        },
        {
            name: "Hà Nội",
            districts: [
                {
                    name: "Quận Ba Đình",
                    wards: ["Phường Phúc Xá", "Phường Trúc Bạch", "Phường Vĩnh Phúc", "Phường Cống Vị", "Phường Liễu Giai", "Phường Nguyễn Trung Trực", "Phường Quán Thánh", "Phường Ngọc Hà", "Phường Điện Biên", "Phường Đội Cấn", "Phường Ngọc Khánh", "Phường Kim Mã", "Phường Giảng Võ", "Phường Thành Công"]
                },
                {
                    name: "Quận Hoàn Kiếm",
                    wards: ["Phường Đồng Xuân", "Phường Hàng Mã", "Phường Hàng Buồm", "Phường Hàng Đào", "Phường Hàng Bồ", "Phường Cửa Đông", "Phường Lý Thái Tổ", "Phường Hàng Bạc", "Phường Hàng Gai", "Phường Chương Dương", "Phường Hàng Trống", "Phường Cửa Nam", "Phường Hàng Bông", "Phường Tràng Tiền", "Phường Trần Hưng Đạo", "Phường Phan Chu Trinh"]
                },
                {
                    name: "Quận Đống Đa",
                    wards: ["Phường Cát Linh", "Phường Văn Miếu", "Phường Quốc Tử Giám", "Phường Láng Thượng", "Phường Ô Chợ Dừa", "Phường Văn Chương", "Phường Hàng Bột", "Phường Láng Hạ", "Phường Khâm Thiên", "Phường Thổ Quan", "Phường Nam Đồng", "Phường Trung Phụng", "Phường Quang Trung", "Phường Trung Liệt", "Phường Phương Liên", "Phường Thịnh Quang", "Phường Trung Tự", "Phường Kim Liên", "Phường Phương Mai", "Phường Ngã Tư Sở", "Phường Khương Thượng"]
                },
                {
                    name: "Quận Cầu Giấy",
                    wards: ["Phường Nghĩa Đô", "Phường Nghĩa Tân", "Phường Mai Dịch", "Phường Dịch Vọng", "Phường Dịch Vọng Hậu", "Phường Quan Hoa", "Phường Yên Hòa", "Phường Trung Hòa"]
                },
                {
                    name: "Quận Hai Bà Trưng",
                    wards: ["Phường Nguyễn Du", "Phường Bạch Đằng", "Phường Phạm Đình Hổ", "Phường Lê Đại Hành", "Phường Đồng Nhân", "Phường Phố Huế", "Phường Đống Mác", "Phường Thanh Lương", "Phường Thanh Nhàn", "Phường Cầu Dền", "Phường Bách Khoa", "Phường Đồng Tâm", "Phường Vĩnh Tuy", "Phường Bạch Mai", "Phường Quỳnh Mai", "Phường Quỳnh Lôi", "Phường Minh Khai", "Phường Trương Định"]
                },
                {
                    name: "Quận Thanh Xuân",
                    wards: ["Phường Hạ Đình", "Phường Khương Đình", "Phường Khương Mai", "Phường Khương Trung", "Phường Kim Giang", "Phường Nhân Chính", "Phường Phương Liệt", "Phường Thanh Xuân Bắc", "Phường Thanh Xuân Nam", "Phường Thanh Xuân Trung", "Phường Thượng Đình"]
                },
                {
                    name: "Quận Tây Hồ",
                    wards: ["Phường Phú Thượng", "Phường Nhật Tân", "Phường Tứ Liên", "Phường Quảng An", "Phường Xuân La", "Phường Yên Phụ", "Phường Bưởi", "Phường Thụy Khuê"]
                },
                {
                    name: "Quận Hoàng Mai",
                    wards: ["Phường Hoàng Liệt", "Phường Yên Sở", "Phường Định Công", "Phường Đại Kim", "Phường Thịnh Liệt", "Phường Thanh Trì", "Phường Lĩnh Nam", "Phường Trần Phú", "Phường Mai Động", "Phường Tương Mai", "Phường Tân Mai", "Phường Giáp Bát", "Phường Hoàng Văn Thụ", "Phường Vĩnh Hưng"]
                },
                {
                    name: "Quận Long Biên",
                    wards: ["Phường Thượng Thanh", "Phường Ngọc Thụy", "Phường Giang Biên", "Phường Đức Giang", "Phường Việt Hưng", "Phường Gia Thụy", "Phường Ngọc Lâm", "Phường Phúc Lợi", "Phường Bồ Đề", "Phường Sài Đồng", "Phường Long Biên", "Phường Thạch Bàn", "Phường Phúc Đồng", "Phường Cự Khối"]
                },
                {
                    name: "Quận Nam Từ Liêm",
                    wards: ["Phường Cầu Diễn", "Phường Xuân Phương", "Phường Phương Canh", "Phường Mỹ Đình 1", "Phường Mỹ Đình 2", "Phường Tây Mỗ", "Phường Mễ Trì", "Phường Phú Đô", "Phường Đại Mỗ", "Phường Trung Văn"]
                },
                {
                    name: "Quận Bắc Từ Liêm",
                    wards: ["Phường Thượng Cát", "Phường Liên Mạc", "Phường Đông Ngạc", "Phường Đức Thắng", "Phường Thụy Phương", "Phường Tây Tựu", "Phường Xuân Đỉnh", "Phường Xuân Tảo", "Phường Minh Khai", "Phường Cổ Nhuế 1", "Phường Cổ Nhuế 2", "Phường Phú Diễn", "Phường Phúc Diễn"]
                },
                {
                    name: "Quận Hà Đông",
                    wards: ["Phường Nguyễn Trãi", "Phường Mộ Lao", "Phường Hà Cầu", "Phường Vạn Phúc", "Phường Yết Kiêu", "Phường Quang Trung", "Phường La Khê", "Phường Phú La", "Phường Phúc La", "Phường Đồng Mai", "Phường Yên Nghĩa", "Phường Kiến Hưng", "Phường Phú Lãm", "Phường Phú Lương", "Phường Dương Nội", "Phường Biên Giang"]
                }
            ]
        },
        {
            name: "Đà Nẵng",
            districts: [
                {
                    name: "Quận Hải Châu",
                    wards: ["Phường Hải Châu 1", "Phường Hải Châu 2", "Phường Thạch Thang", "Phường Thanh Bình", "Phường Thuận Phước", "Phường Hòa Thuận Tây", "Phường Hòa Thuận Đông", "Phường Nam Dương", "Phường Bình Hiên", "Phường Bình Thuận", "Phường Hòa Cường Bắc", "Phường Hòa Cường Nam"]
                },
                {
                    name: "Quận Thanh Khê",
                    wards: ["Phường Tam Thuận", "Phường Thanh Khê Tây", "Phường Thanh Khê Đông", "Phường Xuân Hà", "Phường Tân Chính", "Phường Chính Gián", "Phường Vĩnh Trung", "Phường Thạc Gián", "Phường An Khê", "Phường Hòa Khê"]
                },
                {
                    name: "Quận Sơn Trà",
                    wards: ["Phường Thọ Quang", "Phường Mân Thái", "Phường An Hải Bắc", "Phường Phước Mỹ", "Phường An Hải Tây", "Phường An Hải Đông", "Phường Nại Hiên Đông"]
                },
                {
                    name: "Quận Ngũ Hành Sơn",
                    wards: ["Phường Mỹ An", "Phường Khuê Mỹ", "Phường Hòa Quý", "Phường Hòa Hải"]
                },
                {
                    name: "Quận Liên Chiểu",
                    wards: ["Phường Hòa Hiệp Bắc", "Phường Hòa Hiệp Nam", "Phường Hòa Khánh Bắc", "Phường Hòa Khánh Nam", "Phường Hòa Minh"]
                },
                {
                    name: "Quận Cẩm Lệ",
                    wards: ["Phường Khuê Trung", "Phường Hòa Phát", "Phường Hòa An", "Phường Hòa Thọ Tây", "Phường Hòa Thọ Đông", "Phường Hòa Xuân"]
                },
                {
                    name: "Huyện Hòa Vang",
                    wards: ["Xã Hòa Bắc", "Xã Hòa Liên", "Xã Hòa Ninh", "Xã Hòa Sơn", "Xã Hòa Nhơn", "Xã Hòa Phú", "Xã Hòa Phong", "Xã Hòa Châu", "Xã Hòa Tiến", "Xã Hòa Khương"]
                }
            ]
        },
        {
            name: "Bình Dương",
            districts: [
                {
                    name: "TP. Thủ Dầu Một",
                    wards: ["Phường Hiệp Thành", "Phường Phú Hòa", "Phường Phú Cường", "Phường Phú Lợi", "Phường Phú Thọ", "Phường Chánh Nghĩa", "Phường Định Hòa", "Phường Phú Mỹ", "Phường Hiệp An", "Phường Phú Tân", "Phường Hòa Phú", "Phường Tân An", "Phường Tương Bình Hiệp", "Phường Chánh Mỹ"]
                },
                {
                    name: "TP. Thuận An",
                    wards: ["Phường Lái Thiêu", "Phường An Thạnh", "Phường Vĩnh Phú", "Phường Bình Hòa", "Phường Bình Chuẩn", "Phường Thuận Giao", "Phường An Phú", "Phường Hưng Định", "Phường Bình Nhâm", "Xã An Sơn"]
                },
                {
                    name: "TP. Dĩ An",
                    wards: ["Phường Dĩ An", "Phường Tân Bình", "Phường Tân Đông Hiệp", "Phường Bình An", "Phường Bình Thắng", "Phường Đông Hòa", "Phường An Bình"]
                },
                {
                    name: "TP. Tân Uyên",
                    wards: ["Phường Uyên Hưng", "Phường Tân Phước Khánh", "Phường Thái Hòa", "Phường Thạnh Phước", "Phường Tân Hiệp", "Phường Khánh Bình"]
                },
                {
                    name: "TP. Bến Cát",
                    wards: ["Phường Mỹ Phước", "Phường Thới Hòa", "Phường Tân Định", "Phường Hòa Lợi", "Phường Chánh Phú Hòa"]
                }
            ]
        },
        {
            name: "Đồng Nai",
            districts: [
                {
                    name: "TP. Biên Hòa",
                    wards: ["Phường Trảng Dài", "Phường Tân Phong", "Phường Tân Hiệp", "Phường Hố Nai", "Phường Tân Tiến", "Phường Quyết Thắng", "Phường Thống Nhất", "Phường Tam Hiệp", "Phường Long Bình", "Phường Long Bình Tân", "Phường An Bình"]
                },
                {
                    name: "TP. Long Khánh",
                    wards: ["Phường Xuân Trung", "Phường Xuân Thanh", "Phường Xuân An", "Phường Xuân Bình", "Phường Xuân Hòa", "Phường Phú Bình"]
                },
                {
                    name: "Huyện Long Thành",
                    wards: ["Thị trấn Long Thành", "Xã An Phước", "Xã Lộc An", "Xã Bình Sơn", "Xã Long Đức"]
                },
                {
                    name: "Huyện Nhơn Trạch",
                    wards: ["Thị trấn Hiệp Phước", "Xã Phước Thiền", "Xã Đại Phước", "Xã Phú Hội", "Xã Long Thọ"]
                }
            ]
        },
        {
            name: "Hải Phòng",
            districts: [
                {
                    name: "Quận Hồng Bàng",
                    wards: ["Phường Hoàng Văn Thụ", "Phường Minh Khai", "Phường Phan Bội Châu", "Phường Thượng Lý", "Phường Hạ Lý", "Phường Sở Dầu"]
                },
                {
                    name: "Quận Ngô Quyền",
                    wards: ["Phường Máy Chai", "Phường Vạn Mỹ", "Phường Cầu Tre", "Phường Lạc Viên", "Phường Cầu Đất", "Phường Đằng Giang"]
                },
                {
                    name: "Quận Lê Chân",
                    wards: ["Phường An Biên", "Phường Cát Dài", "Phường Lam Sơn", "Phường Hồ Nam", "Phường Dư Hàng", "Phường Vĩnh Niệm"]
                }
            ]
        },
        {
            name: "Cần Thơ",
            districts: [
                {
                    name: "Quận Ninh Kiều",
                    wards: ["Phường Tân An", "Phường An Lạc", "Phường An Cư", "Phường An Hội", "Phường Thới Bình", "Phường An Hòa", "Phường Cái Khế", "Phường An Nghiệp", "Phường An Phú", "Phường Xuân Khánh", "Phường Hưng Lợi"]
                },
                {
                    name: "Quận Bình Thủy",
                    wards: ["Phường Bình Thủy", "Phường Trà An", "Phường Trà Nóc", "Phường Thới An Đông", "Phường Bùi Hữu Nghĩa", "Phường Long Hòa", "Phường Long Tuyền", "Phường An Thới"]
                },
                {
                    name: "Quận Cái Răng",
                    wards: ["Phường Lê Bình", "Phường Hưng Phú", "Phường Hưng Thạnh", "Phường Ba Láng", "Phường Phú Thứ", "Phường Tân Phú"]
                }
            ]
        },
        {
            name: "Bà Rịa - Vũng Tàu",
            districts: [
                {
                    name: "TP. Vũng Tàu",
                    wards: ["Phường 1", "Phường 2", "Phường 3", "Phường 4", "Phường 5", "Phường 7", "Phường 8", "Phường 9", "Phường 10", "Phường 11", "Phường 12", "Phường Thắng Nhất", "Phường Thắng Nhì", "Phường Thắng Tam", "Phường Rạch Dừa", "Phường Nguyễn An Ninh"]
                },
                {
                    name: "TP. Bà Rịa",
                    wards: ["Phường Phước Hưng", "Phường Phước Trung", "Phường Phước Hiệp", "Phường Phước Nguyên", "Phường Long Toàn", "Phường Long Tâm", "Phường Long Hương", "Phường Kim Dinh"]
                },
                {
                    name: "Thị xã Phú Mỹ",
                    wards: ["Phường Phú Mỹ", "Phường Mỹ Xuân", "Phường Hắc Dịch", "Phường Tân Phước", "Phường Phước Hòa"]
                }
            ]
        }
    ];

    // Danh sách 63 tỉnh/thành phố chuẩn Việt Nam để bổ sung đầy đủ
    const ALL_PROVINCES = [
        "TP. Hồ Chí Minh", "Hà Nội", "Đà Nẵng", "Hải Phòng", "Cần Thơ",
        "Bình Dương", "Đồng Nai", "Bà Rịa - Vũng Tàu", "An Giang", "Bắc Giang",
        "Bắc Kạn", "Bạc Liêu", "Bắc Ninh", "Bến Tre", "Bình Định", "Bình Phước",
        "Bình Thuận", "Cà Mau", "Cao Bằng", "Đắk Lắk", "Đắk Nông", "Điện Biên",
        "Đồng Tháp", "Gia Lai", "Hà Giang", "Hà Nam", "Hà Tĩnh", "Hải Dương",
        "Hậu Giang", "Hòa Bình", "Hưng Yên", "Khánh Hòa", "Kiên Giang", "Kon Tum",
        "Lai Châu", "Lâm Đồng", "Lạng Sơn", "Lào Cai", "Long An", "Nam Định",
        "Nghệ An", "Ninh Bình", "Ninh Thuận", "Phú Thọ", "Phú Yên", "Quảng Bình",
        "Quảng Nam", "Quảng Ngãi", "Quảng Ninh", "Quảng Trị", "Sóc Trăng", "Sơn La",
        "Tây Ninh", "Thái Bình", "Thái Nguyên", "Thanh Hóa", "Thừa Thiên Huế",
        "Tiền Giang", "Trà Vinh", "Tuyên Quang", "Vĩnh Long", "Vĩnh Phúc", "Yên Bái"
    ];

    // Helper tạo danh sách quận/huyện mặc định cho các tỉnh còn lại
    function getDistrictsForProvince(provName) {
        const found = VIETNAM_LOCATIONS.find(p => p.name === provName);
        if (found) return found.districts;

        return [
            {
                name: "Thành phố " + provName.replace(/^(Tỉnh|TP\.)\s*/, ''),
                wards: ["Phường 1", "Phường 2", "Phường 3", "Phường Trung tâm", "Phường Tân Thành"]
            },
            {
                name: "Thị xã Trung tâm",
                wards: ["Phường 1", "Phường 2", "Xã An Bình", "Xã Hòa Bình"]
            },
            {
                name: "Huyện 1",
                wards: ["Thị trấn Huyện", "Xã Đông", "Xã Tây", "Xã Nam", "Xã Bắc"]
            },
            {
                name: "Huyện 2",
                wards: ["Thị trấn Huyện", "Xã Phú An", "Xã Tân Hòa", "Xã Hưng Thịnh"]
            }
        ];
    }

    // =========================================================================
    // 2. KHỞI TẠO BỘ DROPDOWN TỈNH - HUYỆN - XÃ
    // =========================================================================
    function setupAddressDropdowns(prefix) {
        const selProvince = document.getElementById(prefix + 'Province');
        const selDistrict = document.getElementById(prefix + 'District');
        const selWard = document.getElementById(prefix + 'Ward');
        const txtStreet = document.getElementById(prefix + 'Street');
        const hidFullAddress = document.getElementById(prefix + 'FullAddress');

        if (!selProvince || !selDistrict || !selWard) return;

        // Điền danh sách Tỉnh / Thành
        selProvince.innerHTML = '<option value="">-- Chọn Tỉnh / Thành phố --</option>';
        ALL_PROVINCES.forEach(p => {
            const opt = document.createElement('option');
            opt.value = p;
            opt.textContent = p;
            selProvince.appendChild(opt);
        });

        // Khi đổi Tỉnh -> Cập nhật Quận/Huyện
        selProvince.addEventListener('change', function () {
            const prov = this.value;
            selDistrict.innerHTML = '<option value="">-- Chọn Quận / Huyện --</option>';
            selWard.innerHTML = '<option value="">-- Chọn Phường / Xã --</option>';

            if (prov) {
                const dists = getDistrictsForProvince(prov);
                dists.forEach(d => {
                    const opt = document.createElement('option');
                    opt.value = d.name;
                    opt.textContent = d.name;
                    selDistrict.appendChild(opt);
                });
            }
            updateFullAddress();
        });

        // Khi đổi Huyện -> Cập nhật Phường/Xã
        selDistrict.addEventListener('change', function () {
            const prov = selProvince.value;
            const distName = this.value;
            selWard.innerHTML = '<option value="">-- Chọn Phường / Xã --</option>';

            if (prov && distName) {
                const dists = getDistrictsForProvince(prov);
                const foundDist = dists.find(d => d.name === distName);
                if (foundDist && foundDist.wards) {
                    foundDist.wards.forEach(w => {
                        const opt = document.createElement('option');
                        opt.value = w;
                        opt.textContent = w;
                        selWard.appendChild(opt);
                    });
                }
            }
            updateFullAddress();
        });

        // Khi đổi Xã hoặc gõ số nhà
        selWard.addEventListener('change', updateFullAddress);
        if (txtStreet) {
            txtStreet.addEventListener('input', updateFullAddress);
        }

        function updateFullAddress() {
            if (!hidFullAddress) return;
            const parts = [];
            if (txtStreet && txtStreet.value.trim()) parts.push(txtStreet.value.trim());
            if (selWard && selWard.value) parts.push(selWard.value);
            if (selDistrict && selDistrict.value) parts.push(selDistrict.value);
            if (selProvince && selProvince.value) parts.push(selProvince.value);

            hidFullAddress.value = parts.join(', ');
        }
    }

    // Khởi tạo cho form thêm mới
    setupAddressDropdowns('new');
    // Khởi tạo cho modal chỉnh sửa
    setupAddressDropdowns('edit');

    // =========================================================================
    // 3. PARSE ĐỊA CHỈ CHO MODAL CHỈNH SỬA
    // =========================================================================
    function populateEditModalAddress(fullAddress) {
        const selProvince = document.getElementById('editProvince');
        const selDistrict = document.getElementById('editDistrict');
        const selWard = document.getElementById('editWard');
        const txtStreet = document.getElementById('editStreet');
        const hidFullAddress = document.getElementById('editFullAddress');

        if (!fullAddress) {
            if (txtStreet) txtStreet.value = '';
            if (hidFullAddress) hidFullAddress.value = '';
            return;
        }

        if (hidFullAddress) hidFullAddress.value = fullAddress;

        // Thử tách theo dấu phẩy: [Số nhà đường], [Phường/Xã], [Quận/Huyện], [Tỉnh/TP]
        const rawParts = fullAddress.split(',').map(s => s.trim());

        let matchedProv = null;
        let matchedDist = null;
        let matchedWard = null;
        let streetParts = [];

        // Tìm tỉnh/thành từ cuối lên
        for (let i = rawParts.length - 1; i >= 0; i--) {
            const part = rawParts[i];
            const p = ALL_PROVINCES.find(prov =>
                prov.toLowerCase() === part.toLowerCase() ||
                part.toLowerCase().includes(prov.toLowerCase())
            );
            if (p) {
                matchedProv = p;
                rawParts.splice(i, 1);
                break;
            }
        }

        if (matchedProv) {
            selProvince.value = matchedProv;
            // Kích hoạt nạp danh sách huyện
            selDistrict.innerHTML = '<option value="">-- Chọn Quận / Huyện --</option>';
            const dists = getDistrictsForProvince(matchedProv);
            dists.forEach(d => {
                const opt = document.createElement('option');
                opt.value = d.name;
                opt.textContent = d.name;
                selDistrict.appendChild(opt);
            });

            // Tìm huyện
            for (let i = rawParts.length - 1; i >= 0; i--) {
                const part = rawParts[i];
                const d = dists.find(dist =>
                    dist.name.toLowerCase() === part.toLowerCase() ||
                    part.toLowerCase().includes(dist.name.toLowerCase())
                );
                if (d) {
                    matchedDist = d.name;
                    rawParts.splice(i, 1);
                    break;
                }
            }

            if (matchedDist) {
                selDistrict.value = matchedDist;
                // Kích hoạt nạp xã
                selWard.innerHTML = '<option value="">-- Chọn Phường / Xã --</option>';
                const foundD = dists.find(d => d.name === matchedDist);
                if (foundD && foundD.wards) {
                    foundD.wards.forEach(w => {
                        const opt = document.createElement('option');
                        opt.value = w;
                        opt.textContent = w;
                        selWard.appendChild(opt);
                    });

                    // Tìm xã
                    for (let i = rawParts.length - 1; i >= 0; i--) {
                        const part = rawParts[i];
                        const w = foundD.wards.find(ward =>
                            ward.toLowerCase() === part.toLowerCase() ||
                            part.toLowerCase().includes(ward.toLowerCase())
                        );
                        if (w) {
                            matchedWard = w;
                            rawParts.splice(i, 1);
                            break;
                        }
                    }
                    if (matchedWard) {
                        selWard.value = matchedWard;
                    }
                }
            }
        }

        // Phần còn lại chính là số nhà, đường
        streetParts = rawParts;
        if (txtStreet) {
            txtStreet.value = streetParts.join(', ');
        }
    }

    // =========================================================================
    // 4. BẮT SỰ KIỆN NÚT CHỈNH SỬA ĐỊA CHỈ
    // =========================================================================
    document.querySelectorAll('.btn-edit-address').forEach(btn => {
        btn.addEventListener('click', function () {
            const id = this.getAttribute('data-id');
            const address = this.getAttribute('data-address') || '';
            const recipientName = this.getAttribute('data-recipient-name') || '';
            const recipientPhone = this.getAttribute('data-recipient-phone') || '';
            const isDefault = this.getAttribute('data-default') === 'true';

            document.getElementById('editAddressId').value = id;
            const nameEl = document.getElementById('editRecipientName');
            const phoneEl = document.getElementById('editRecipientPhone');
            if (nameEl) nameEl.value = recipientName;
            if (phoneEl) phoneEl.value = recipientPhone;

            populateEditModalAddress(address);

            const chk = document.getElementById('editChkDefault');
            if (chk) {
                chk.checked = isDefault;
                chk.disabled = isDefault; // nếu đã là mặc định thì không thể bỏ tích
            }

            const modal = new bootstrap.Modal(document.getElementById('editAddressModal'));
            modal.show();
        });
    });

    // Form submit validation: Đảm bảo ghép full address trước khi post
    const formNewAddr = document.querySelector('#addNewAddressBox form');
    if (formNewAddr) {
        formNewAddr.addEventListener('submit', function (e) {
            const prov = document.getElementById('newProvince').value;
            const dist = document.getElementById('newDistrict').value;
            const ward = document.getElementById('newWard').value;
            const street = document.getElementById('newStreet').value.trim();

            if (!prov || !dist || !ward || !street) {
                e.preventDefault();
                alert('Vui lòng chọn đầy đủ Tỉnh/Thành phố, Quận/Huyện, Phường/Xã và nhập số nhà/tên đường!');
                return false;
            }
            document.getElementById('newFullAddress').value = `${street}, ${ward}, ${dist}, ${prov}`;
        });
    }

    const formEditAddr = document.querySelector('#editAddressModal form');
    if (formEditAddr) {
        formEditAddr.addEventListener('submit', function (e) {
            const prov = document.getElementById('editProvince').value;
            const dist = document.getElementById('editDistrict').value;
            const ward = document.getElementById('editWard').value;
            const street = document.getElementById('editStreet').value.trim();

            if (prov && dist && ward && street) {
                document.getElementById('editFullAddress').value = `${street}, ${ward}, ${dist}, ${prov}`;
            }
        });
    }

    // =========================================================================
    // 5. MODAL XÁC NHẬN XÓA ĐỊA CHỈ (KHÔNG DÙNG CONFIRM CỦA TRÌNH DUYỆT)
    // =========================================================================
    const delModalEl = document.getElementById('deleteAddressModal');
    let delModalInstance = null;
    if (delModalEl) {
        delModalInstance = new bootstrap.Modal(delModalEl);
    }

    document.querySelectorAll('.btn-trigger-del-address').forEach(btn => {
        btn.addEventListener('click', function (e) {
            e.preventDefault();
            const id = this.getAttribute('data-id');
            const address = this.getAttribute('data-address') || '';
            const recipientName = this.getAttribute('data-recipient-name') || '';
            const recipientPhone = this.getAttribute('data-recipient-phone') || '';
            const isDefault = this.getAttribute('data-default') === 'true';

            const formDel = document.getElementById('formDeleteAddress');
            if (formDel) {
                formDel.action = '/account/address/delete/' + id;
            }

            const elRecipient = document.getElementById('delModalRecipient');
            const elAddress = document.getElementById('delModalAddress');
            const elBadge = document.getElementById('delModalDefaultBadge');

            if (elRecipient) {
                let recText = recipientName || 'Người nhận';
                if (recipientPhone) recText += ' · SĐT: ' + recipientPhone;
                elRecipient.textContent = recText;
            }

            if (elAddress) {
                elAddress.textContent = address;
            }

            if (elBadge) {
                elBadge.style.display = isDefault ? 'inline-block' : 'none';
            }

            if (delModalInstance) {
                delModalInstance.show();
            }
        });
    });

    // =========================================================================
    // 6. RÀNG BUỘC CẬP NHẬT THÔNG TIN CÁ NHÂN (SỐ ĐIỆN THOẠI & NGÀY SINH)
    // =========================================================================
    const formUpdateProfile = document.getElementById('formUpdateProfile');
    const inputBirthDate = document.getElementById('profileBirthDate');

    // Giới hạn max trên datepicker: không chọn được ngày tương lai
    if (inputBirthDate) {
        const todayStr = new Date().toISOString().split('T')[0];
        inputBirthDate.setAttribute('max', todayStr);
    }

    if (formUpdateProfile) {
        formUpdateProfile.addEventListener('submit', function (e) {
            const fullNameInput = document.getElementById('profileFullName');
            const phoneInput = document.getElementById('profilePhone');
            const birthDateInput = document.getElementById('profileBirthDate');

            let isValid = true;

            // Xóa trạng thái lỗi cũ
            [fullNameInput, phoneInput, birthDateInput].forEach(inp => {
                if (inp) inp.classList.remove('is-invalid');
            });

            // 1. Kiểm tra Họ và tên
            const fullNameVal = fullNameInput ? fullNameInput.value.trim() : '';
            if (!fullNameVal || fullNameVal.length < 2 || fullNameVal.length > 100) {
                if (fullNameInput) {
                    fullNameInput.classList.add('is-invalid');
                    const fb = document.getElementById('fullNameFeedback');
                    if (fb) fb.textContent = 'Họ và tên không được để trống (từ 2 đến 100 ký tự).';
                }
                isValid = false;
            }

            // 2. Kiểm tra Số điện thoại
            const rawPhone = phoneInput ? phoneInput.value.trim().replace(/[\s.-]/g, '') : '';
            // Chuẩn hóa +84 thành 0
            const normalizedPhone = rawPhone.startsWith('+84') ? '0' + rawPhone.substring(3) : rawPhone;
            // 10 chữ số, bắt đầu bằng các đầu số di động VN: 03, 05, 07, 08, 09
            const phoneRegex = /^0[35789]\d{8}$/;

            if (!rawPhone) {
                if (phoneInput) {
                    phoneInput.classList.add('is-invalid');
                    const fb = document.getElementById('phoneFeedback');
                    if (fb) fb.textContent = 'Số điện thoại không được để trống.';
                }
                isValid = false;
            } else if (!phoneRegex.test(normalizedPhone)) {
                if (phoneInput) {
                    phoneInput.classList.add('is-invalid');
                    const fb = document.getElementById('phoneFeedback');
                    if (fb) fb.textContent = 'Số điện thoại không hợp lệ (phải gồm 10 chữ số và bắt đầu bằng 03, 05, 07, 08 hoặc 09).';
                }
                isValid = false;
            }

            // 3. Kiểm tra Ngày sinh
            const birthVal = birthDateInput ? birthDateInput.value.trim() : '';
            if (!birthVal) {
                if (birthDateInput) {
                    birthDateInput.classList.add('is-invalid');
                    const fb = document.getElementById('birthDateFeedback');
                    if (fb) fb.textContent = 'Ngày sinh không được để trống.';
                }
                isValid = false;
            } else {
                const birthParts = birthVal.split('-');
                if (birthParts.length !== 3) {
                    if (birthDateInput) {
                        birthDateInput.classList.add('is-invalid');
                        const fb = document.getElementById('birthDateFeedback');
                        if (fb) fb.textContent = 'Ngày sinh không đúng định dạng.';
                    }
                    isValid = false;
                } else {
                    const birthYear = parseInt(birthParts[0], 10);
                    const birthMonth = parseInt(birthParts[1], 10) - 1;
                    const birthDay = parseInt(birthParts[2], 10);
                    const birthDate = new Date(birthYear, birthMonth, birthDay);

                    const now = new Date();
                    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());

                    if (isNaN(birthDate.getTime())) {
                        if (birthDateInput) {
                            birthDateInput.classList.add('is-invalid');
                            const fb = document.getElementById('birthDateFeedback');
                            if (fb) fb.textContent = 'Ngày sinh không hợp lệ.';
                        }
                        isValid = false;
                    } else if (birthDate > today) {
                        if (birthDateInput) {
                            birthDateInput.classList.add('is-invalid');
                            const fb = document.getElementById('birthDateFeedback');
                            if (fb) fb.textContent = 'Ngày sinh không thể là ngày trong tương lai.';
                        }
                        isValid = false;
                    } else if (birthDate.getTime() === today.getTime()) {
                        if (birthDateInput) {
                            birthDateInput.classList.add('is-invalid');
                            const fb = document.getElementById('birthDateFeedback');
                            if (fb) fb.textContent = 'Ngày sinh phải trước ngày hiện tại.';
                        }
                        isValid = false;
                    } else {
                        // Tính tuổi chính xác
                        let age = today.getFullYear() - birthYear;
                        const m = today.getMonth() - birthMonth;
                        if (m < 0 || (m === 0 && today.getDate() < birthDay)) {
                            age--;
                        }

                        if (age < 15) {
                            if (birthDateInput) {
                                birthDateInput.classList.add('is-invalid');
                                const fb = document.getElementById('birthDateFeedback');
                                if (fb) fb.textContent = 'Khách hàng phải từ đủ 15 tuổi trở lên.';
                            }
                            isValid = false;
                        } else if (age > 120) {
                            if (birthDateInput) {
                                birthDateInput.classList.add('is-invalid');
                                const fb = document.getElementById('birthDateFeedback');
                                if (fb) fb.textContent = 'Ngày sinh không hợp lệ (vượt quá 120 tuổi).';
                            }
                            isValid = false;
                        }
                    }
                }
            }

            if (!isValid) {
                e.preventDefault();
                e.stopPropagation();
            }
        });
    }

});

