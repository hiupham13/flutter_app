# 🐛 Bug Fix: PrimaryButton Infinite Width Error

**Ngày:** 06/01/2026  
**Severity:** HIGH (App crash)  
**Component:** [`PrimaryButton`](../what_eat_app/lib/core/widgets/primary_button.dart)

---

## 🔥 Mô Tả Lỗi

### Error Log:
```
FlutterError: BoxConstraints forces an infinite width.
BoxConstraints(w=Infinity, 48.0<=h<=Infinity)

RenderConstrainedBox.performLayout (package:flutter/src/rendering/proxy_box.dart:293:14)
_RenderInputPadding
RenderPhysicalShape (ElevatedButton)
```

### Triệu chứng:
- App crash với error "BoxConstraints forces an infinite width"
- Xảy ra khi PrimaryButton được dùng với `expand: true` (default)
- Button không được render, màn hình hiện lỗi layout

---

## 🎯 Nguyên Nhân

### Code cũ (Lỗi):
```dart
// primary_button.dart - Line 125-128
return ConstrainedBox(
  constraints: BoxConstraints(
    minWidth: widget.expand ? double.infinity : (widget.width ?? 0),
  ),
  child: ElevatedButton(...),
);
```

### Vấn đề:
1. **ConstrainedBox với `minWidth: double.infinity`** là không hợp lệ
2. ElevatedButton bên trong cũng có `minimumSize: Size(double.infinity, ...)`
3. Khi button nằm trong context không có bounded width (Stack, Align, etc.), layout engine không thể resolve infinite constraint
4. Flutter framework không cho phép "force" width = infinity mà không có parent constraint

### Root Cause:
**ConstrainedBox chỉ nên dùng để giới hạn (constrain), KHÔNG nên dùng để expand.**  
Để expand full width, nên dùng **SizedBox(width: double.infinity)** hoặc wrap trong **Expanded/Flexible**.

---

## ✅ Giải Pháp

### Code mới (Fixed):
```dart
@override
Widget build(BuildContext context) {
  final content = widget.isLoading
      ? const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        )
      : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.leadingIcon != null) ...[
              Icon(widget.leadingIcon, size: 18),
              const SizedBox(width: AppSpacing.xs),
            ],
            Flexible(
              child: Text(
                widget.label,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );

  final button = GestureDetector(
    onTapDown: (_) => setState(() => _pressed = true),
    onTapUp: (_) => setState(() => _pressed = false),
    onTapCancel: () => setState(() => _pressed = false),
    child: AnimatedScale(
      duration: AppDurations.fast,
      scale: _pressed && !widget.isLoading ? 0.98 : 1.0,
      child: ElevatedButton(
        onPressed: widget.isLoading ? null : widget.onPressed,
        style: _style(context),
        child: content,
      ),
    ),
  );

  // ✅ FIX: Use SizedBox for full width expansion
  if (widget.expand) {
    return SizedBox(
      width: double.infinity,
      height: _height(),
      child: button,
    );
  }

  // For non-expanding buttons, use ConstrainedBox
  return ConstrainedBox(
    constraints: BoxConstraints(
      minWidth: widget.width ?? 0,
      minHeight: _height(),
    ),
    child: button,
  );
}
```

### Key Changes:
1. ✅ **Extract button widget** để reuse
2. ✅ **Conditional rendering:** 
   - `expand = true` → `SizedBox(width: double.infinity)`
   - `expand = false` → `ConstrainedBox(minWidth: ...)`
3. ✅ **Add explicit height** để button có size cố định
4. ✅ **Remove infinite constraint** khỏi ConstrainedBox

---

## 🧪 Testing

### Test Cases:
1. ✅ Button trong Column (expand = true) → OK
2. ✅ Button trong Row (expand = false) → OK
3. ✅ Button trong Stack/Align (expand = true) → OK (fixed)
4. ✅ Button với custom width → OK
5. ✅ Loading state → OK
6. ✅ Disabled state → OK

### Screens Affected (Fixed):
- ✅ [`result_screen.dart`](../what_eat_app/lib/features/recommendation/presentation/result_screen.dart) - 3 buttons
- ✅ [`dashboard_screen.dart`](../what_eat_app/lib/features/dashboard/presentation/dashboard_screen.dart) - 1 button
- ✅ [`error_widget.dart`](../what_eat_app/lib/core/widgets/error_widget.dart) - 1 button
- ✅ [`empty_state_widget.dart`](../what_eat_app/lib/core/widgets/empty_state_widget.dart) - 1 button

---

## 📚 Best Practices (Bài Học)

### ❌ DON'T:
```dart
// DON'T use ConstrainedBox for expansion
ConstrainedBox(
  constraints: BoxConstraints(minWidth: double.infinity), // ❌ Infinite constraint
  child: Widget(),
)

// DON'T mix infinite constraints
Container(
  constraints: BoxConstraints(maxWidth: double.infinity), // ❌ Ambiguous
  child: Widget(),
)
```

### ✅ DO:
```dart
// ✅ Use SizedBox for explicit sizing
SizedBox(
  width: double.infinity,
  height: 48,
  child: ElevatedButton(...),
)

// ✅ Use Expanded in Flex layouts
Row(
  children: [
    Expanded(
      child: ElevatedButton(...),
    ),
  ],
)

// ✅ Use ConstrainedBox for LIMITING only
ConstrainedBox(
  constraints: BoxConstraints(
    maxWidth: 300,  // ✅ Limit max width
    minHeight: 48,  // ✅ Ensure min height
  ),
  child: Widget(),
)
```

### Widget Sizing Guidelines:
1. **Full width expansion:** `SizedBox(width: double.infinity)`
2. **Conditional expansion:** Use `Expanded` or `Flexible` in Flex layouts
3. **Size limiting:** `ConstrainedBox` with `maxWidth`, `maxHeight`
4. **Minimum size:** `ConstrainedBox` with `minWidth`, `minHeight`
5. **Exact size:** `SizedBox(width: ..., height: ...)`

---

## 🎯 Impact

### Before Fix:
- ❌ App crashes on result screen
- ❌ Buttons not rendering
- ❌ Poor user experience

### After Fix:
- ✅ All buttons render correctly
- ✅ No layout errors
- ✅ Smooth user experience
- ✅ Consistent button sizing across screens

### Performance:
- **No performance impact** - Same widget tree depth
- **Cleaner code** - More explicit sizing logic
- **Better maintainability** - Clear separation of expand vs constrain logic

---

## 🔗 Related Files

**Modified:**
- [`what_eat_app/lib/core/widgets/primary_button.dart`](../what_eat_app/lib/core/widgets/primary_button.dart) ✅

**Affected (Fixed):**
- [`what_eat_app/lib/features/recommendation/presentation/result_screen.dart`](../what_eat_app/lib/features/recommendation/presentation/result_screen.dart)
- [`what_eat_app/lib/features/dashboard/presentation/dashboard_screen.dart`](../what_eat_app/lib/features/dashboard/presentation/dashboard_screen.dart)
- [`what_eat_app/lib/core/widgets/error_widget.dart`](../what_eat_app/lib/core/widgets/error_widget.dart)
- [`what_eat_app/lib/core/widgets/empty_state_widget.dart`](../what_eat_app/lib/core/widgets/empty_state_widget.dart)

---

## ✅ Verification Checklist

- [x] Error log analyzed
- [x] Root cause identified
- [x] Fix implemented
- [x] All affected screens tested
- [x] Documentation created
- [x] Best practices documented
- [ ] PR review
- [ ] Deploy to production

---

**Status:** ✅ RESOLVED  
**Priority:** HIGH  
**Type:** Bug Fix  
**Component:** UI Widget (PrimaryButton)
