import '../../../models/reward_model.dart';
import '../../../core/constants/rewards_constants.dart';

/// Mock redemption offers for testing and demo
/// 
/// This file contains fake data for:
/// - Voucher offers (3 tiers)
/// - Cash withdrawal offers (4 tiers)
/// - Premium offers (2 items)
/// - Partner restaurants
class MockRedemptionData {
  MockRedemptionData._();

  // ============================================================================
  // VOUCHER OFFERS
  // ============================================================================

  static List<RedemptionOffer> get voucherOffers => [
        // Tier 1: Entry level
        RedemptionOffer(
          id: 'vchr_10k',
          title: 'Voucher 10,000đ',
          description: 'Giảm 10K cho hóa đơn từ 50K trở lên',
          type: RedemptionType.voucher,
          coinsRequired: RewardsConstants.voucher10kCoins,
          cashValue: 10000,
          imageUrl: 'https://via.placeholder.com/300x200/4CAF50/FFFFFF?text=10K',
          isActive: true,
          stockRemaining: null, // Unlimited
          terms: [
            'Áp dụng cho hóa đơn từ 50,000đ',
            'Sử dụng 1 lần duy nhất',
            'Không hoàn trả xu nếu hủy',
            'Valid 30 ngày từ ngày đổi',
            'Áp dụng tại các nhà hàng đối tác',
          ],
          metadata: {
            'tier': 1,
            'min_bill': 50000,
            'popular': true,
          },
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
          updatedAt: DateTime.now(),
        ),

        RedemptionOffer(
          id: 'vchr_20k',
          title: 'Voucher 20,000đ',
          description: 'Giảm 20K cho hóa đơn từ 100K trở lên',
          type: RedemptionType.voucher,
          coinsRequired: RewardsConstants.voucher20kCoins,
          cashValue: 20000,
          imageUrl: 'https://via.placeholder.com/300x200/FF9800/FFFFFF?text=20K',
          isActive: true,
          stockRemaining: 500,
          terms: [
            'Áp dụng cho hóa đơn từ 100,000đ',
            'Sử dụng 1 lần duy nhất',
            'Không hoàn trả xu nếu hủy',
            'Valid 30 ngày từ ngày đổi',
            'Áp dụng tại các nhà hàng đối tác',
          ],
          metadata: {
            'tier': 2,
            'min_bill': 100000,
            'popular': true,
          },
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
          updatedAt: DateTime.now(),
        ),

        RedemptionOffer(
          id: 'vchr_50k',
          title: 'Voucher 50,000đ',
          description: 'Giảm 50K cho hóa đơn từ 200K trở lên',
          type: RedemptionType.voucher,
          coinsRequired: RewardsConstants.voucher50kCoins,
          cashValue: 50000,
          imageUrl: 'https://via.placeholder.com/300x200/F44336/FFFFFF?text=50K',
          isActive: true,
          stockRemaining: 200,
          terms: [
            'Áp dụng cho hóa đơn từ 200,000đ',
            'Sử dụng 1 lần duy nhất',
            'Không hoàn trả xu nếu hủy',
            'Valid 30 ngày từ ngày đổi',
            'Áp dụng tại các nhà hàng đối tác',
          ],
          metadata: {
            'tier': 3,
            'min_bill': 200000,
            'featured': true,
          },
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
          updatedAt: DateTime.now(),
        ),

        // Special vouchers
        RedemptionOffer(
          id: 'vchr_free_drink',
          title: 'Nước Uống Miễn Phí',
          description: 'Free 1 ly nước ngọt hoặc trà khi order món',
          type: RedemptionType.voucher,
          coinsRequired: 600,
          cashValue: 15000,
          imageUrl: 'https://via.placeholder.com/300x200/2196F3/FFFFFF?text=Drink',
          isActive: true,
          stockRemaining: null,
          terms: [
            'Chọn 1 trong các loại: Coca, Pepsi, Trà Đá',
            'Khi order bất kỳ món ăn nào',
            'Sử dụng 1 lần duy nhất',
            'Valid 30 ngày từ ngày đổi',
          ],
          metadata: {
            'tier': 1,
            'type': 'beverage',
            'popular': true,
          },
          createdAt: DateTime.now().subtract(const Duration(days: 20)),
          updatedAt: DateTime.now(),
        ),

        RedemptionOffer(
          id: 'vchr_free_dessert',
          title: 'Tráng Miệng Miễn Phí',
          description: 'Free 1 món tráng miệng khi order món chính',
          type: RedemptionType.voucher,
          coinsRequired: 1000,
          cashValue: 25000,
          imageUrl:
              'https://via.placeholder.com/300x200/9C27B0/FFFFFF?text=Dessert',
          isActive: true,
          stockRemaining: 300,
          terms: [
            'Chọn 1 món tráng miệng dưới 25K',
            'Khi order món chính từ 80K',
            'Sử dụng 1 lần duy nhất',
            'Valid 30 ngày từ ngày đổi',
          ],
          metadata: {
            'tier': 2,
            'type': 'dessert',
          },
          createdAt: DateTime.now().subtract(const Duration(days: 15)),
          updatedAt: DateTime.now(),
        ),
      ];

  // ============================================================================
  // CASH OFFERS
  // ============================================================================

  static List<RedemptionOffer> get cashOffers => [
        RedemptionOffer(
          id: 'cash_20k',
          title: 'Rút 20,000đ',
          description: 'Chuyển 20K vào tài khoản của bạn',
          type: RedemptionType.cash,
          coinsRequired: RewardsConstants.cash20kCoins,
          cashValue: 20000,
          imageUrl: 'https://via.placeholder.com/300x200/00BCD4/FFFFFF?text=20K',
          isActive: true,
          stockRemaining: null,
          terms: [
            'Xử lý trong 3-5 ngày làm việc',
            'Cần xác minh số điện thoại',
            'Tài khoản tối thiểu 7 ngày',
            'Đã mở tối thiểu 10 hộp quà',
          ],
          metadata: {
            'tier': 1,
            'processing_days': 3,
          },
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
          updatedAt: DateTime.now(),
        ),

        RedemptionOffer(
          id: 'cash_50k',
          title: 'Rút 50,000đ',
          description: 'Chuyển 50K vào tài khoản của bạn',
          type: RedemptionType.cash,
          coinsRequired: RewardsConstants.cash50kCoins,
          cashValue: 50000,
          imageUrl: 'https://via.placeholder.com/300x200/009688/FFFFFF?text=50K',
          isActive: true,
          stockRemaining: null,
          terms: [
            'Xử lý trong 3-5 ngày làm việc',
            'Cần xác minh số điện thoại',
            'Tài khoản tối thiểu 7 ngày',
            'Đã mở tối thiểu 10 hộp quà',
          ],
          metadata: {
            'tier': 2,
            'processing_days': 3,
            'popular': true,
          },
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
          updatedAt: DateTime.now(),
        ),

        RedemptionOffer(
          id: 'cash_100k',
          title: 'Rút 100,000đ',
          description: 'Chuyển 100K vào tài khoản của bạn',
          type: RedemptionType.cash,
          coinsRequired: RewardsConstants.cash100kCoins,
          cashValue: 100000,
          imageUrl: 'https://via.placeholder.com/300x200/4CAF50/FFFFFF?text=100K',
          isActive: true,
          stockRemaining: null,
          terms: [
            'Xử lý trong 3-5 ngày làm việc',
            'Cần xác minh số điện thoại',
            'Tài khoản tối thiểu 7 ngày',
            'Đã mở tối thiểu 10 hộp quà',
          ],
          metadata: {
            'tier': 3,
            'processing_days': 3,
          },
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
          updatedAt: DateTime.now(),
        ),

        RedemptionOffer(
          id: 'cash_200k',
          title: 'Rút 200,000đ',
          description: 'Chuyển 200K vào tài khoản của bạn',
          type: RedemptionType.cash,
          coinsRequired: RewardsConstants.cash200kCoins,
          cashValue: 200000,
          imageUrl: 'https://via.placeholder.com/300x200/FF5722/FFFFFF?text=200K',
          isActive: true,
          stockRemaining: null,
          terms: [
            'Xử lý trong 3-5 ngày làm việc',
            'Cần xác minh số điện thoại',
            'Tài khoản tối thiểu 7 ngày',
            'Đã mở tối thiểu 10 hộp quà',
            'Limit: 200K/ngày',
          ],
          metadata: {
            'tier': 4,
            'processing_days': 3,
          },
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
          updatedAt: DateTime.now(),
        ),
      ];

  // ============================================================================
  // PREMIUM OFFERS
  // ============================================================================

  static List<RedemptionOffer> get premiumOffers => [
        RedemptionOffer(
          id: 'premium_combo',
          title: 'Combo Meal Premium',
          description: '2 món chính + 2 nước uống + 1 tráng miệng',
          type: RedemptionType.premium,
          coinsRequired: 5000,
          cashValue: 150000,
          imageUrl:
              'https://via.placeholder.com/300x200/FFD700/000000?text=Combo',
          isActive: true,
          stockRemaining: 50,
          terms: [
            'Bao gồm 2 món chính dưới 60K/món',
            '2 nước uống bất kỳ',
            '1 món tráng miệng dưới 30K',
            'Sử dụng tại nhà hàng đối tác',
            'Đặt trước 1 ngày',
            'Valid 30 ngày từ ngày đổi',
          ],
          metadata: {
            'tier': 'premium',
            'meals_included': 2,
            'drinks_included': 2,
            'desserts_included': 1,
          },
          createdAt: DateTime.now().subtract(const Duration(days: 10)),
          updatedAt: DateTime.now(),
        ),

        RedemptionOffer(
          id: 'premium_monthly_pass',
          title: 'Monthly VIP Pass',
          description: 'Free 1 món/ngày trong 30 ngày',
          type: RedemptionType.premium,
          coinsRequired: RewardsConstants.monthlyPassCoins,
          cashValue: 300000,
          imageUrl: 'https://via.placeholder.com/300x200/9C27B0/FFFFFF?text=VIP',
          isActive: true,
          stockRemaining: 20,
          terms: [
            'Free 1 món dưới 100K mỗi ngày',
            'Valid 30 ngày từ khi kích hoạt',
            'Áp dụng tại tất cả nhà hàng đối tác',
            'Không chuyển nhượng',
            'Không hoàn trả xu',
          ],
          metadata: {
            'tier': 'vip',
            'days_valid': 30,
            'meals_per_day': 1,
            'max_meal_value': 100000,
            'exclusive': true,
          },
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
          updatedAt: DateTime.now(),
        ),

        RedemptionOffer(
          id: 'premium_cooking_class',
          title: 'Lớp Học Nấu Ăn',
          description: 'Workshop nấu món Việt với đầu bếp chuyên nghiệp',
          type: RedemptionType.premium,
          coinsRequired: 20000,
          cashValue: 400000,
          imageUrl:
              'https://via.placeholder.com/300x200/FF5722/FFFFFF?text=Cooking',
          isActive: true,
          stockRemaining: 10,
          expiryDate: DateTime.now().add(const Duration(days: 60)),
          terms: [
            'Workshop 3 tiếng',
            'Học nấu 3 món Việt cơ bản',
            'Bao gồm nguyên liệu',
            'Đặt trước 7 ngày',
            'Tối đa 10 người/lớp',
            'Hết hạn sau 60 ngày',
          ],
          metadata: {
            'tier': 'exclusive',
            'duration_hours': 3,
            'dishes_count': 3,
            'max_participants': 10,
            'advance_booking_days': 7,
          },
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
          updatedAt: DateTime.now(),
        ),
      ];

  // ============================================================================
  // ALL OFFERS
  // ============================================================================

  /// Get all mock offers
  static List<RedemptionOffer> get allOffers => [
        ...voucherOffers,
        ...cashOffers,
        ...premiumOffers,
      ];

  // ============================================================================
  // MOCK PARTNER RESTAURANTS
  // ============================================================================

  static List<Map<String, dynamic>> get mockPartners => [
        {
          'id': 'partner_pho_24',
          'name': 'Phở 24',
          'logo': 'https://via.placeholder.com/100/FF5722/FFFFFF?text=P24',
          'description': 'Chuỗi phở nổi tiếng toàn quốc',
          'locations': [
            'Quận 1, TP.HCM',
            'Quận 3, TP.HCM',
            'Quận 7, TP.HCM',
            'Bình Thạnh, TP.HCM',
          ],
          'accepted_vouchers': ['vchr_10k', 'vchr_20k', 'vchr_50k'],
          'rating': 4.5,
          'phone': '1900-xxxx',
        },
        {
          'id': 'partner_com_tam',
          'name': 'Cơm Tấm Sài Gòn',
          'logo': 'https://via.placeholder.com/100/4CAF50/FFFFFF?text=CT',
          'description': 'Cơm tấm truyền thống Sài Gòn',
          'locations': [
            'Quận 1, TP.HCM',
            'Quận 5, TP.HCM',
            'Tân Bình, TP.HCM',
          ],
          'accepted_vouchers': ['vchr_10k', 'vchr_20k'],
          'rating': 4.3,
          'phone': '028-xxxx-xxxx',
        },
        {
          'id': 'partner_highlands',
          'name': 'Highlands Coffee',
          'logo': 'https://via.placeholder.com/100/8B4513/FFFFFF?text=HC',
          'description': 'Cà phê & đồ uống',
          'locations': [
            'Toàn quốc',
          ],
          'accepted_vouchers': ['vchr_free_drink'],
          'rating': 4.6,
          'phone': '1900-xxxx',
        },
        {
          'id': 'partner_lotteria',
          'name': 'Lotteria',
          'logo': 'https://via.placeholder.com/100/FF0000/FFFFFF?text=L',
          'description': 'Fast food phong cách Hàn Quốc',
          'locations': [
            'Toàn quốc',
          ],
          'accepted_vouchers': [
            'vchr_10k',
            'vchr_20k',
            'vchr_free_drink',
            'vchr_free_dessert'
          ],
          'rating': 4.4,
          'phone': '1900-xxxx',
        },
        {
          'id': 'partner_kichi',
          'name': 'Kichi Kichi',
          'logo': 'https://via.placeholder.com/100/FF9800/FFFFFF?text=KK',
          'description': 'Buffet lẩu băng chuyền',
          'locations': [
            'Quận 1, TP.HCM',
            'Quận 10, TP.HCM',
            'Hà Nội',
          ],
          'accepted_vouchers': ['vchr_20k', 'vchr_50k'],
          'rating': 4.7,
          'phone': '1900-xxxx',
        },
      ];

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Get offers by type
  static List<RedemptionOffer> getOffersByType(RedemptionType type) {
    return allOffers.where((offer) => offer.type == type).toList();
  }

  /// Get offers user can afford
  static List<RedemptionOffer> getAffordableOffers(int userCoins) {
    return allOffers
        .where((offer) => offer.coinsRequired <= userCoins)
        .toList()
      ..sort((a, b) => a.coinsRequired.compareTo(b.coinsRequired));
  }

  /// Get popular offers
  static List<RedemptionOffer> getPopularOffers() {
    return allOffers
        .where((offer) =>
            offer.metadata?['popular'] == true ||
            offer.metadata?['featured'] == true)
        .toList();
  }

  /// Get offer by ID
  static RedemptionOffer? getOfferById(String id) {
    try {
      return allOffers.firstWhere((offer) => offer.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get partners accepting offer
  static List<Map<String, dynamic>> getPartnersForOffer(String offerId) {
    return mockPartners
        .where((partner) =>
            (partner['accepted_vouchers'] as List<String>).contains(offerId))
        .toList();
  }
}
