# BotListScreen Modernization Plan

## Objective

Update the `BotListScreen` to match the modern design aesthetic of the `WalletScreen` and `ToolsScreen`. This involves structural changes to the header and visual updates to all card components.

## Changes Implemented

### 1. Structural Changes

- **Header:** Removed the standard `AppHeader` (AppBar). Replaced it with a custom in-body header containing:
  - Large Title ("Botlarım") using `GoogleFonts.plusJakartaSans`.
  - Subtitle ("Otomatik strateji yönetimi").
  - Panic Button (Contextual, only shows if active bots exist).
- **Layout:** Wrapped the body in `SafeArea` to accommodate the custom header.

### 2. Design System Updates (Dark Slate Theme)

- **Colors:**
  - Background: `AppColors.background`.
  - Cards: `Color(0xFF1E293B).withValues(alpha: 0.5)` (Dark Slate).
  - Borders: `Colors.white.withValues(alpha: 0.05)`.
  - Shadows: Colored shadows matching the strategy/tool color.
- **Visual Effects:**
  - **Glows:** Added `Positioned` containers with `BoxShadow` inside `Stack` widgets to create subtle background glows on cards.
  - **Glassmorphism:** Used alpha values on backgrounds to blend with the app background.

### 3. Component Updates

- **`_buildSpotlightCard`:**
  - Transformed from full gradient background to dark card with colored accents.
  - Added internal glow effect.
  - Updated typography to match the new dark theme.
- **`_buildStrategyGridCard`:**
  - Aligned with `ToolsScreen` card design.
  - Added entry animations.
- **`_BotCardItem`:**
  - Updated background color to match the new slate theme.
  - Maintained existing functionality (expandable logs, quick actions).

### 4. Animations

- Integrated `flutter_animate` package.
- Added `fadeIn` and `slideY` animations to the Header.
- Added staggered `fadeIn` and `scale` animations to the Strategy Grid items.

## Verification

- Check consistency with `ToolsScreen`.
- Verify "Panic Mode" button visibility and functionality.
- Ensure all tap interactions (TradingView, Stop, Create) work as expected.
