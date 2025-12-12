# Core Style Guide

Tone: Xanh ngọc dịu làm primary, cam ấm làm accent. Phong cách hiện đại, nhẹ mắt, ưu tiên độ tương phản cao, nhiều không gian trắng, bo góc mềm và bóng đổ nhẹ.

## Palette

- Primary: Teal 500 `#14B8A6`
- Primary Dark: `#0F766E`
- Primary Soft: `#8BE3D8`
- Accent: Orange 500 `#FF7A45`
- Accent Soft: `#FFC7A1`
- Background: `#F6F9FB`
- Surface: `#FFFFFF`
- Surface Muted: `#F0F4F8`
- Border/Subtle Line: `#D8DFE8`
- Text Primary: `#0F172A`
- Text Secondary: `#475467`
- Success: `#22C55E`
- Warning: `#F59E0B`
- Error: `#EF4444`
- Shadow color: `rgba(15, 23, 42, 0.12)`

Rules:
- Primary cho CTA, sliders, focus ring. Accent cho nhấn mạnh (badges, pill, highlights).
- Nền ưu tiên Background, card dùng Surface hoặc Surface Muted.
- Border sử dụng line mỏng trên bề mặt sáng. Tránh viền đậm; ưu tiên bóng đổ nhẹ.

## Typography (Inter)

- Display/Large: 28/34, w700
- Title 1: 22/28, w700
- Title 2: 18/24, w600
- Body 1: 16/22, w500
- Body 2: 14/20, w500
- Caption: 12/16, w500
- Button: 16/20, w700 (all-caps tùy ngữ cảnh; ưu tiên Title Case)
- Label micro: 11/16, w600

## Spacing & Radius

- Spacing scale (px): 4, 8, 12, 16, 20, 24, 32, 40.
- Radius: 8 (base), 12 (card), 16 (sheet), 999 (pill).
- Hit area tối thiểu 44x44 px cho thao tác chạm.

## Elevation & Shadows

- Card/Tile: blur 12, spread 0, y 8, alpha 0.08.
- FAB/Primary CTA: blur 16, y 10, alpha 0.12.
- Input/Toolbar: blur 10, y 4, alpha 0.06.

## Gradients

- Primary gradient: 135° từ `#14B8A6` → `#8BE3D8`.
- Accent sweep: 135° từ `#FF7A45` → `#FFC7A1` (sử dụng tiết kiệm cho highlight).

## States

- Hover (web/desktop): nâng nhẹ + background tint 4%.
- Pressed: giảm sáng 6%, scale 0.98, shadow nhỏ hơn.
- Disabled: giảm opacity còn 38% (text), 24% (fill); giữ contrast đủ đọc được.
- Focus: outline 2px màu Primary Soft/Accent Soft, radius theo component.

## Breakpoints & Responsive

- Compact (<360): giảm padding ngang còn 16, dùng Body 2 cho phụ.
- Mobile default (360-600): padding 20-24 cho màn chính; card radius 12.
- Tablet (>=600): tăng grid/card width, padding 24-32, text Title 1/Body 1 nhiều hơn.
- MediaQuery/LayoutBuilder để co giãn component; tránh fixed width cứng.

## Component Guidelines (áp dụng cho Module 5.4)

- PrimaryButton: 3 size (small/medium/large), variants (primary, secondary/ghost, tonal). Có loading, disabled, icon leading. Min height 48 (mobile), 56 cho CTA lớn.
- CustomTextField: đệm 16x14, fill Surface Muted, focus ring teal; hỗ trợ prefix/suffix, trạng thái lỗi.
- LoadingIndicator: size trung tính, có optional overlay semi-transparent, text Body 2.
- Error/Empty: icon tròn tint accent/secondary, message ngắn gọn, CTA tùy chọn.
- FoodImageCard: bo 12-16, ratio 4:3 hoặc 1:1, có overlay gradient nhẹ + badge price/tag.
- PriceBadge: pill, nền accent soft/primary soft tùy tone, icon nhỏ.
- FoodTagsChip: FilterChip style, radius pill, border subtle, selected dùng Primary.

## Accessibility

- Tương phản >= 4.5 cho text chính, >= 3.0 cho text lớn.
- Touch target 44px, spacing đủ để tránh bấm nhầm.
- Icon kèm text ở CTA quan trọng; trạng thái rõ ràng (loading/disabled/focus).

## Implementation Notes

- Sử dụng `AppColors`, `AppTypography`, `AppSpacing/AppRadius`, `AppShadows` để thống nhất.
- ThemeData áp dụng Inter, colorScheme dựa trên palette trên; ElevatedButtonTheme, InputDecorationTheme, ChipTheme đồng nhất.
- Áp dụng gradient/blur tiết kiệm, ưu tiên nền phẳng và viền/bóng nhẹ.

