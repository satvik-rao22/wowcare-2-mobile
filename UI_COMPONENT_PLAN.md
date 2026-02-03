# UI Component Plan - WowCare Mobility 2.0

## Table of Contents
1. [Architecture Overview](#architecture-overview)
2. [Theme System](#theme-system)
3. [Text Styles System](#text-styles-system)
4. [Component Organization](#component-organization)
5. [Shared Widgets](#shared-widgets)
6. [Feature-Specific Widgets](#feature-specific-widgets)
7. [Responsive Design](#responsive-design)
8. [Loading States](#loading-states)
9. [Layout Patterns](#layout-patterns)
10. [Creating New Modules](#creating-new-modules)
11. [Best Practices](#best-practices)

---

## Architecture Overview

The UI follows a **layered component architecture** with clear separation:

```
┌─────────────────────────────────────────────────────────┐
│              Feature-Specific Widgets                    │
│  (Staff, Students, Billing, etc.) - Domain UI          │
└──────────────────────┬──────────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────────┐
│                  Shared Widgets                          │
│  (Custom buttons, cards, inputs, etc.) - Reusable       │
└──────────────────────┬──────────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────────┐
│                    Theme System                          │
│  (Colors, Fonts, Decorations, Text Styles)             │
└─────────────────────────────────────────────────────────┘
```

### Layer Responsibilities

- **Theme System**: Colors, fonts, text styles, decorations - Design tokens
- **Shared Widgets**: Reusable components (buttons, cards, inputs, etc.)
- **Feature Widgets**: Domain-specific UI components (staff cards, student cards, etc.)
- **Screens**: Full page layouts combining widgets

---

## Theme System

### Location
`lib/app/theme/`

### Files

1. **`colors.dart`** - All color definitions
2. **`fonts.dart`** - Font family constants
3. **`decorations.dart`** - Reusable BoxDecorations and InputDecorations
4. **`button_themes.dart`** - Button-specific styling
5. **`media_res.dart`** - Asset paths (icons, images)

### Colors (`lib/app/theme/colors.dart`)

**Structure:**
- All colors are static constants in `AppColors` class
- Private constructor prevents instantiation
- Organized by category (primary, secondary, status, etc.)

**Categories:**

1. **Primary Colors**
   - `primaryColor` - Main brand color (RGB: 87, 51, 83)
   - `secondaryColor` - Secondary brand color (RGB: 27, 35, 126)
   - `themeColor` - Theme accent color (RGB: 89, 120, 247)

2. **UI Colors**
   - `cardColor` - Card background (white)
   - `cardBorderColor` - Card border (primary with opacity)
   - `fieldBackgroundColor` - Input field background

3. **Status Colors**
   - `errorColor` - Error states (red)
   - `warningColor` - Warning states (orange)
   - `successColor` - Success states (green)
   - `accentColor` - Accent/highlight (yellow)

4. **Gradients**
   - `primaryGradientColors` - Primary gradient (blue to purple)
   - `secondaryGradientColors` - Secondary gradient
   - `scaffoldGradientColors` - Background gradient
   - Helper methods: `buildPrimaryGradient()`, `buildSecondaryGradient()`, `buildScaffoldGradient()`

5. **Feature-Specific Colors**
   - Billing colors (prefixed with `billing`)
   - Progress bar colors (`lightBlueProgressBar`, `mustardProgressBar`, etc.)
   - Tag colors (`tagColors`, `tagTextColors`)
   - Avatar colors (`profileAvatarColors`)

**Usage:**
```dart
// Always use AppColors constants
Container(
  color: AppColors.primaryColor,
  decoration: BoxDecoration(
    gradient: AppColors.buildPrimaryGradient(),
  ),
)
```

**Rules:**
- ✅ Always use `AppColors` constants
- ✅ Use gradient helpers for gradients
- ✅ Use opacity variants (`.withOpacity()` or `.withValues(alpha: ...)`)
- ❌ Don't hardcode colors
- ❌ Don't create new color constants without discussion

### Fonts (`lib/app/theme/fonts.dart`)

**Structure:**
- Static constants for font families
- Currently supports: `Manrope`, `Inter`, `Imperial_Script`

**Usage:**
```dart
Text(
  'Hello',
  style: TextStyle(fontFamily: Fonts.manrope),
)
```

**Rules:**
- ✅ Use `Fonts` constants
- ✅ Default to `Manrope` for most text
- ❌ Don't hardcode font names

### Decorations (`lib/app/theme/decorations.dart`)

**Structure:**
- `ContainerDecorations` class with static BoxDecoration constants
- `GradientBorderContainer` widget for gradient borders

**Predefined Decorations:**
- `decoration0` through `decoration6` - Various BoxDecoration styles
- `dropdownDecoration` - InputDecoration for dropdowns

**Usage:**
```dart
Container(
  decoration: ContainerDecorations.decoration1,
)

// Gradient border
GradientBorderContainer(
  child: YourWidget(),
)
```

**Rules:**
- ✅ Use predefined decorations when they match your needs
- ✅ Create new decorations if needed, but keep them in this file
- ❌ Don't create decorations inline

---

## Text Styles System

### Location
`lib/shared/common/widgets/app_text_styles.dart`

### Structure

Two main classes:
1. **`AppTextStyles`** - Static TextStyle constants
2. **`AppText`** - Widget with predefined style variants

### AppTextStyles

**Available Styles:**

1. **`label`** - Field labels
   - fontSize: 13, fontWeight: w400, height: 16/13

2. **`value`** - Display values/content
   - fontSize: 14, fontWeight: w500, height: 19/14

3. **`title`** - Section titles
   - fontSize: 16, fontWeight: w700, height: 16/16

4. **`subtitle`** - Subtitles
   - fontSize: 14, fontWeight: w700

5. **`body`** - Regular body text
   - fontSize: 14, fontWeight: w500, height: 19/14

6. **`small`** - Smaller text
   - fontSize: 12, fontWeight: w400, height: 15/12

7. **`sectionHeader`** - Section headers
   - fontSize: 13, fontWeight: w600

8. **`button({color})`** - Button labels
   - fontSize: 16, fontWeight: w700

**Usage:**
```dart
// Direct style
Text(
  'Label',
  style: AppTextStyles.label,
)

// With customization
Text(
  'Label',
  style: AppTextStyles.label.copyWith(color: AppColors.errorColor),
)
```

### AppText Widget

**Variants:**
- `AppText.label(text)` - Label variant
- `AppText.value(text)` - Value variant
- `AppText.title(text)` - Title variant
- `AppText.subtitle(text)` - Subtitle variant
- `AppText.body(text)` - Body variant
- `AppText.small(text)` - Small variant
- `AppText.sectionHeader(text)` - Section header variant

**Properties:**
- `text` - Text content (required)
- `style` - Optional style override
- `textAlign` - Text alignment
- `overflow` - Overflow behavior
- `maxLines` - Maximum lines

**Usage:**
```dart
// Simple usage
AppText.label('Name')

// With customization
AppText.title(
  'Staff Profile',
  style: TextStyle(color: AppColors.primaryColor),
  textAlign: TextAlign.center,
  maxLines: 2,
)
```

**Rules:**
- ✅ Use `AppText` widget for consistent styling
- ✅ Use `AppTextStyles` when you need custom Text widgets
- ✅ Prefer named constructors (`AppText.label()`) over style parameter
- ❌ Don't create inline TextStyle without using AppTextStyles

---

## Component Organization

### Directory Structure

```
lib/
├── app/theme/                    # Theme system
│   ├── colors.dart
│   ├── fonts.dart
│   ├── decorations.dart
│   └── media_res.dart
│
├── shared/                       # Shared/reusable components
│   ├── common/
│   │   ├── widgets/             # Reusable widgets
│   │   │   ├── custom_*.dart    # Custom components
│   │   │   ├── gradient_*.dart  # Gradient components
│   │   │   └── app_text_styles.dart
│   │   └── views/               # Reusable views
│   └── utils/
│       └── responsive_sizing.dart
│
└── presentation/
    └── features/
        └── {feature}/
            ├── view/            # Screens
            ├── widgets/         # Feature-specific widgets
            └── cubit/           # State management
```

### Naming Conventions

1. **Shared Widgets**: `custom_*` prefix (e.g., `custom_button.dart`)
2. **Gradient Components**: `gradient_*` prefix (e.g., `gradient_add_button.dart`)
3. **Feature Widgets**: Feature name prefix (e.g., `staff_card.dart`)
4. **Screens**: `*_screen.dart` suffix (e.g., `staff_screen.dart`)

---

## Shared Widgets

### Location
`lib/shared/common/widgets/`

### Categories

#### 1. Layout & Structure

**`custom_scaffold.dart`** - `GlobalScaffold`
- Main scaffold wrapper with gradient background
- Handles app bar, drawer, navigation bar
- Supports pull-to-refresh, floating action buttons
- Auto-dismisses keyboard on tap

**`custom_section_card.dart`** - `CustomSectionCard`
- Reusable card container
- Standardized padding, margin, border
- Uses `AppColors.cardColor` and `AppColors.cardBorderColor`

**`custom_form_template.dart`** - Form layout template
- Standardized form structure
- Consistent spacing and layout

#### 2. Buttons

**`custom_confirm_button.dart`** - `CustomConfirmButton`
- Primary action button
- Uses primary gradient

**`custom_cancel_button.dart`** - `CustomCancelButton`
- Secondary/cancel button
- Outlined style

**`gradient_add_button.dart`** - `GradientAddButton`
- Floating add button with gradient
- Responsive sizing (tablet support)

**`rounded_button.dart`** - Rounded button variant

**`reusable_cancle_save_buttons.dart`** - `ReusableActionButtons`
- Common cancel/save button pair
- Used in forms

#### 3. Inputs

**`custom_text_field.dart`** - `CustomTextField`
- Standardized text input
- Consistent styling and validation

**`custom_dropdown.dart`** - `CustomDropdown`
- Single-select dropdown

**`custom_multi_select_dropdown.dart`** - `CustomMultiSelectDropdown`
- Multi-select dropdown

**`custom_date_time_field.dart`** - `CustomDateTimeField`
- Date/time picker field

**`custom_search_bar.dart`** - `CustomSearchBar`
- Search input with icon
- Consistent styling

#### 4. Display Components

**`custom_chip.dart`** - `CustomChip`
- Tag/chip component
- Customizable color and label

**`custom_clear_all_chip.dart`** - `CustomClearAllChip`
- Clear filter chip
- Standardized "Clear All" UI

**`custom_toggle.dart`** - `CustomToggle`
- Toggle switch component
- Consistent styling

**`custom_checkbox.dart`** - `CustomCheckbox`
- Checkbox with label
- Custom styling

**`custom_profile_avatar.dart`** - Profile avatar component
- Circular avatar with initials
- Fallback to placeholder

**`custom_stat_bar_card.dart`** - `CustomStatBarCard`
- Statistics card with progress bars
- Used in dashboards

#### 5. Loading & Feedback

**`custom_shimmer_loader.dart`** - Shimmer loading placeholders
- `ShimmerLoader` - Generic shimmer
- `StaffCardShimmer` - Staff card placeholder
- `AttendanceCardShimmer` - Attendance card placeholder
- Customizable size, border radius, margin

**`primary_circular_loader.dart`** - `PrimaryCircularLoader`
- Circular progress indicator
- Uses theme color

**`custom_refresh_indicator.dart`** - `CustomRefreshIndicator`
- Pull-to-refresh wrapper
- Custom styling

#### 6. Navigation & Structure

**`custom_app_bar.dart`** - `CustomAppBar`
- Standardized app bar
- Back button support
- Role-based visibility

**`custom_drawer.dart`** - `CustomDrawer`
- Navigation drawer
- Role-based menu items

**`custom_navigation_bar.dart`** - `CustomNavigationBar`
- Bottom navigation bar
- Tab-based navigation

**`custom_curved_appbar.dart`** - Curved app bar variant

#### 7. Dialogs & Sheets

**`confirmation_bottom_sheet.dart`** - Confirmation bottom sheet
- Standardized confirmation UI

**`delete_confirmation_bottom_sheet.dart`** - Delete confirmation
- Specialized delete confirmation

**`reusable_modal_bottom_sheet.dart`** - `ReusableModalBottomSheet`
- Generic bottom sheet wrapper
- Consistent styling

**`post_add_staff_bottom_sheet.dart`** - Post-add staff prompt
- Feature-specific bottom sheet

#### 8. Specialized Components

**`custom_horizontal_date_picker.dart`** - Horizontal date picker
- Scrollable date selection

**`custom_time_chip.dart`** - Time selection chip
- Time picker component

**`gradient_background.dart`** - `GradientBackground`
- Gradient background wrapper
- Uses scaffold gradient colors

**`custom_text_widget.dart`** - `CustomTextWidget`
- Text widget with responsive sizing
- Auto letter spacing

### Usage Pattern

**Always prefer shared widgets over custom implementations:**

```dart
// ✅ CORRECT - Use shared widget
CustomSectionCard(
  child: Column(
    children: [
      AppText.title('Section Title'),
      CustomTextField(...),
    ],
  ),
)

// ❌ WRONG - Custom implementation
Container(
  decoration: BoxDecoration(...), // Should use CustomSectionCard
  child: Text(...), // Should use AppText
)
```

---

## Feature-Specific Widgets

### Location
`lib/presentation/features/{feature}/widgets/`

### Structure

Each feature has its own widgets folder:
- **Staff**: `staff_card.dart`, `staff_action_panel.dart`, `staff_documents_tab.dart`
- **Students**: Student-specific cards and components
- **Billing**: Billing cards, transaction widgets
- **Activities**: Activity tiles, media previews

### Naming Convention

- Feature prefix: `staff_*`, `student_*`, `billing_*`
- Descriptive names: `staff_card.dart`, `staff_documents_tab.dart`
- Screen suffix for full screens: `*_screen.dart`

### Example: Staff Feature

**Widgets:**
- `staff_card.dart` - Individual staff member card
- `staff_action_panel.dart` - Action panel for selected staff
- `staff_documents_tab.dart` - Documents tab widget
- `staff_profile_tab.dart` - Profile tab widget
- `staff_dates_tab.dart` - Dates tab widget
- `staff_important_dates_tab.dart` - Important dates tab

**Screens:**
- `staff_screen.dart` - Main staff list screen
- `staff_profile_screen.dart` - Staff profile screen
- `add_staff_screen.dart` - Add staff screen
- `add_document_screen.dart` - Add document screen

**Rules:**
- ✅ Feature widgets should use shared widgets internally
- ✅ Keep feature widgets focused on domain logic
- ✅ Reusable across feature → Move to shared widgets
- ❌ Don't duplicate shared widget functionality

---

## Responsive Design

### Location
`lib/shared/utils/responsive_sizing.dart`

### ResponsiveSizing Class

**Methods:**

1. **`isTablet(BuildContext context)`**
   - Returns true if screen width >= 600px

2. **`titleFontSize(BuildContext context)`**
   - Responsive title font size
   - Tablet: 26px
   - Mobile (< 360px): 18px
   - Default: 20px

3. **`titleLineHeight(BuildContext context)`**
   - Calculated line height based on font size
   - Tablet: 34/size
   - Mobile: 28/size

4. **`contentPadding(BuildContext context)`**
   - Responsive content padding
   - Tablet: 24px outer padding
   - Mobile: 16px outer padding
   - Accounts for GlobalScaffold's 8px base padding

### Usage

```dart
// Responsive font size
Text(
  'Title',
  style: TextStyle(
    fontSize: ResponsiveSizing.titleFontSize(context),
  ),
)

// Responsive padding
Padding(
  padding: ResponsiveSizing.contentPadding(context),
  child: YourWidget(),
)

// Tablet check
if (ResponsiveSizing.isTablet(context))
  TabletLayout()
else
  MobileLayout()
```

### Rules

- ✅ Always use `ResponsiveSizing` for font sizes and padding
- ✅ Check `isTablet()` for layout differences
- ✅ Use `contentPadding()` for main content areas
- ❌ Don't hardcode sizes
- ❌ Don't use MediaQuery directly (use ResponsiveSizing)

---

## Loading States

### Shimmer Loaders

**Location:** `lib/shared/common/widgets/custom_shimmer_loader.dart`

**Components:**

1. **`ShimmerLoader`** - Generic shimmer
   - Customizable height, width, border radius
   - Used for simple placeholders

2. **`StaffCardShimmer`** - Staff card placeholder
   - Matches `StaffCard` layout
   - Shows shimmer for all card elements

3. **`AttendanceCardShimmer`** - Attendance card placeholder
   - Matches attendance card layout

**Usage:**
```dart
// Initial loading
if (isLoading && items.isEmpty)
  Column(
    children: List.generate(
      6,
      (index) => StaffCardShimmer(
        margin: EdgeInsets.only(bottom: 8),
      ),
    ),
  )

// Pagination loading
if (isLoadingMore)
  Padding(
    padding: EdgeInsets.all(16),
    child: PrimaryCircularLoader(),
  )
```

### Circular Loader

**Location:** `lib/shared/common/widgets/primary_circular_loader.dart`

**Component:** `PrimaryCircularLoader`
- Uses `AppColors.themeColor`
- Standardized loading indicator
- Used for pagination and inline loading

**Usage:**
```dart
if (isLoadingMore)
  Center(child: PrimaryCircularLoader())
```

### Rules

- ✅ Use shimmer for initial loading (empty list)
- ✅ Use circular loader for pagination/refresh
- ✅ Match shimmer to actual component layout
- ❌ Don't mix loading indicators
- ❌ Don't show loading when data exists (use circular loader)

---

## Layout Patterns

### Screen Structure

**Standard Screen Pattern:**

```dart
class FeatureScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GlobalScaffold(
      body: CustomRefreshIndicator(
        onRefresh: () async {
          // Refresh logic
        },
        child: SingleChildScrollView(
          child: Padding(
            padding: ResponsiveSizing.contentPadding(context),
            child: Column(
              children: [
                // Title
                AppText.title('Feature Name'),
                SizedBox(height: 16),
                
                // Content
                CustomSectionCard(
                  child: Column(...),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: GradientAddButton(
        onTap: () {
          // Add action
        },
      ),
    );
  }
}
```

### Card Pattern

**Standard Card Structure:**

```dart
CustomSectionCard(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Header
      AppText.sectionHeader('Section Title'),
      SizedBox(height: 12),
      
      // Content rows
      _InfoRow(
        label: 'Label',
        value: 'Value',
      ),
      SizedBox(height: 16),
      
      // More content...
    ],
  ),
)
```

### Form Pattern

**Standard Form Structure:**

```dart
CustomFormTemplate(
  children: [
    CustomTextField(
      label: 'Field Label',
      controller: _controller,
    ),
    SizedBox(height: 16),
    
    CustomDropdown(
      label: 'Select Option',
      items: options,
      onChanged: (value) {},
    ),
    
    // Action buttons
    ReusableActionButtons(
      onCancel: () {},
      onSave: () {},
    ),
  ],
)
```

### List Pattern

**Standard List Structure:**

```dart
// Initial loading
if (isLoading && items.isEmpty)
  Column(
    children: List.generate(
      6,
      (index) => ItemShimmer(margin: EdgeInsets.only(bottom: 8)),
    ),
  )

// List items
else
  Column(
    children: [
      ListView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: items.length,
        itemBuilder: (context, index) {
          return ItemCard(
            item: items[index],
            margin: EdgeInsets.only(bottom: 8),
          );
        },
      ),
      
      // Pagination loader
      if (isLoadingMore)
        Padding(
          padding: EdgeInsets.all(16),
          child: PrimaryCircularLoader(),
        ),
    ],
  )
```

---

## Creating New Modules

### Step-by-Step Guide

#### 1. Create Feature Structure

```
lib/presentation/features/{feature}/
├── cubit/
│   ├── {feature}_cubit.dart
│   └── {feature}_state.dart
├── view/
│   └── {feature}_screen.dart
└── widgets/
    └── {feature}_card.dart
```

#### 2. Create Screen

**File:** `lib/presentation/features/{feature}/view/{feature}_screen.dart`

```dart
class FeatureScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GlobalScaffold(
      body: BlocProvider(
        create: (_) => serviceLocator<FeatureCubit>()..loadInitial(),
        child: BlocBuilder<FeatureCubit, FeatureState>(
          builder: (context, state) {
            // Screen content
          },
        ),
      ),
    );
  }
}
```

**Pattern:**
- Use `GlobalScaffold` as wrapper
- Provide Cubit via `BlocProvider`
- Use `BlocBuilder` for reactive UI
- Use `ResponsiveSizing.contentPadding()` for padding
- Use `CustomRefreshIndicator` for pull-to-refresh

#### 3. Create Widgets

**File:** `lib/presentation/features/{feature}/widgets/{feature}_card.dart`

```dart
class FeatureCard extends StatelessWidget {
  final FeatureItem item;
  
  const FeatureCard({required this.item});
  
  @override
  Widget build(BuildContext context) {
    return CustomSectionCard(
      child: Column(
        children: [
          AppText.title(item.title),
          SizedBox(height: 12),
          AppText.value(item.description),
        ],
      ),
    );
  }
}
```

**Pattern:**
- Use shared widgets (`CustomSectionCard`, `AppText`)
- Keep widgets focused and reusable
- Accept data via constructor
- Use `AppColors` for colors

#### 4. Create Shimmer (if needed)

**File:** `lib/shared/common/widgets/custom_shimmer_loader.dart`

Add new shimmer component:

```dart
class FeatureCardShimmer extends StatelessWidget {
  final EdgeInsets? margin;
  
  const FeatureCardShimmer({this.margin});
  
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        margin: margin ?? EdgeInsets.only(bottom: 8),
        // Match FeatureCard layout
      ),
    );
  }
}
```

**Pattern:**
- Match actual component layout
- Use same spacing and sizing
- Add to `custom_shimmer_loader.dart`

#### 5. Register in DI (if needed)

**File:** `lib/app/di/di.dart`

```dart
// Register Cubit
serviceLocator.registerFactory<FeatureCubit>(
  () => FeatureCubit(
    useCase: serviceLocator(),
  ),
);
```

#### 6. Add Navigation Route

**File:** `lib/src/app_router.dart` (or wherever routes are defined)

```dart
case '/feature':
  return MaterialPageRoute(
    builder: (_) => FeatureScreen(),
  );
```

### Checklist

- [ ] Feature folder structure created
- [ ] Screen uses `GlobalScaffold`
- [ ] Widgets use shared components
- [ ] Shimmer loader created (if needed)
- [ ] Colors from `AppColors`
- [ ] Text styles from `AppTextStyles`
- [ ] Responsive sizing used
- [ ] Cubit registered in DI
- [ ] Navigation route added

---

## Best Practices

### 1. Colors
- ✅ Always use `AppColors` constants
- ✅ Use gradient helpers (`buildPrimaryGradient()`)
- ✅ Use opacity variants (`.withOpacity()` or `.withValues(alpha: ...)`)
- ❌ Don't hardcode colors
- ❌ Don't create new color constants without discussion

### 2. Text Styles
- ✅ Use `AppText` widget with named constructors
- ✅ Use `AppTextStyles` for custom Text widgets
- ✅ Prefer `AppText.label()` over `Text(style: AppTextStyles.label)`
- ❌ Don't create inline TextStyle
- ❌ Don't hardcode font sizes (use ResponsiveSizing)

### 3. Components
- ✅ Use shared widgets (`CustomSectionCard`, `CustomTextField`, etc.)
- ✅ Create feature widgets only when needed
- ✅ Move reusable widgets to shared folder
- ❌ Don't duplicate shared widget functionality
- ❌ Don't create one-off components

### 4. Layout
- ✅ Use `GlobalScaffold` for screens
- ✅ Use `ResponsiveSizing.contentPadding()` for content
- ✅ Use `CustomRefreshIndicator` for pull-to-refresh
- ✅ Use `CustomSectionCard` for card containers
- ❌ Don't hardcode padding/margins
- ❌ Don't use raw Scaffold

### 5. Loading States
- ✅ Use shimmer for initial loading (empty list)
- ✅ Use circular loader for pagination
- ✅ Match shimmer to actual component
- ❌ Don't mix loading indicators
- ❌ Don't show loading when data exists

### 6. Responsive Design
- ✅ Always use `ResponsiveSizing` methods
- ✅ Check `isTablet()` for layout differences
- ✅ Use responsive font sizes
- ❌ Don't hardcode sizes
- ❌ Don't use MediaQuery directly

### 7. Naming
- ✅ Use `custom_*` prefix for shared widgets
- ✅ Use `gradient_*` prefix for gradient components
- ✅ Use feature prefix for feature widgets (`staff_*`, `student_*`)
- ✅ Use `*_screen.dart` suffix for screens
- ❌ Don't use generic names (`button.dart`, `card.dart`)

### 8. File Organization
- ✅ Keep shared widgets in `lib/shared/common/widgets/`
- ✅ Keep feature widgets in `lib/presentation/features/{feature}/widgets/`
- ✅ Keep screens in `lib/presentation/features/{feature}/view/`
- ✅ Group related widgets in same file
- ❌ Don't mix shared and feature widgets

---

## Quick Reference

### Common Widgets

| Widget | Location | Usage |
|--------|----------|-------|
| `GlobalScaffold` | `custom_scaffold.dart` | Screen wrapper |
| `CustomSectionCard` | `custom_section_card.dart` | Card container |
| `AppText` | `app_text_styles.dart` | Text with styles |
| `CustomTextField` | `custom_text_field.dart` | Text input |
| `CustomDropdown` | `custom_dropdown.dart` | Dropdown |
| `CustomRefreshIndicator` | `custom_refresh_indicator.dart` | Pull-to-refresh |
| `PrimaryCircularLoader` | `primary_circular_loader.dart` | Loading indicator |
| `GradientAddButton` | `gradient_add_button.dart` | Add button |
| `CustomToggle` | `custom_toggle.dart` | Toggle switch |
| `CustomCheckbox` | `custom_checkbox.dart` | Checkbox |

### Theme Constants

| Constant | Location | Usage |
|----------|----------|-------|
| `AppColors.primaryColor` | `colors.dart` | Primary color |
| `AppColors.cardColor` | `colors.dart` | Card background |
| `AppColors.cardBorderColor` | `colors.dart` | Card border |
| `Fonts.manrope` | `fonts.dart` | Font family |
| `AppTextStyles.label` | `app_text_styles.dart` | Label style |
| `ResponsiveSizing.titleFontSize()` | `responsive_sizing.dart` | Responsive font |

### Creating a New Screen

1. Create screen file in `lib/presentation/features/{feature}/view/`
2. Use `GlobalScaffold` wrapper
3. Use `BlocProvider` for state management
4. Use `ResponsiveSizing.contentPadding()` for padding
5. Use shared widgets for UI components
6. Add navigation route

### Creating a New Widget

1. Determine if it's shared or feature-specific
2. If shared: Add to `lib/shared/common/widgets/`
3. If feature-specific: Add to `lib/presentation/features/{feature}/widgets/`
4. Use `AppColors` for colors
5. Use `AppText` for text
6. Use shared widgets internally
7. Follow naming conventions

---

## Summary

This codebase follows a **consistent UI architecture** with:
- **Centralized theme system** (`AppColors`, `Fonts`, `AppTextStyles`)
- **Reusable shared widgets** (`CustomSectionCard`, `CustomTextField`, etc.)
- **Feature-specific widgets** organized by domain
- **Responsive design** via `ResponsiveSizing`
- **Consistent loading states** (shimmer + circular loader)
- **Standardized layout patterns** (screen, card, form, list)

All UI components follow these patterns, ensuring consistency and maintainability across the application.

