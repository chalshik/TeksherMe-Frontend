import 'package:flutter/material.dart';
import 'glassmorphic_container.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final bool useGlassmorphism;
  final Color? backgroundColor;
  final double elevation;
  final Widget? flexibleSpace;
  final bool automaticallyImplyLeading;
  final double height;
  final Widget? titleWidget;
  final Widget? bottom;
  
  const CustomAppBar({
    super.key,
    this.title = '',
    this.actions,
    this.leading,
    this.centerTitle = true,
    this.useGlassmorphism = true,
    this.backgroundColor,
    this.elevation = 0,
    this.flexibleSpace,
    this.automaticallyImplyLeading = true,
    this.height = kToolbarHeight + 16,
    this.titleWidget,
    this.bottom,
  });

  @override
  Size get preferredSize => Size.fromHeight(height + (bottom != null ? 56 : 0));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    Widget? leadingWidget = leading;
    if (leadingWidget == null && automaticallyImplyLeading) {
      final ModalRoute<dynamic>? parentRoute = ModalRoute.of(context);
      final bool canPop = parentRoute?.canPop ?? false;
      
      if (canPop) {
        leadingWidget = IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        );
      }
    }
    
    final appBarWidget = AppBar(
      backgroundColor: useGlassmorphism ? Colors.transparent : backgroundColor ?? theme.colorScheme.surface,
      elevation: elevation,
      leading: leadingWidget,
      automaticallyImplyLeading: automaticallyImplyLeading,
      flexibleSpace: flexibleSpace,
      centerTitle: centerTitle,
      title: titleWidget ?? Text(
        title,
        style: TextStyle(
          fontFamily: theme.textTheme.headlineMedium?.fontFamily,
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
      ),
      actions: actions,
      bottom: bottom != null ? PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: bottom!,
      ) : null,
    );
    
    if (useGlassmorphism) {
      // Only apply glassmorphism if specified
      return GlassmorphicContainer(
        height: preferredSize.height,
        blur: 10,
        opacity: 0.2,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        padding: EdgeInsets.zero,
        child: appBarWidget,
      );
    } else {
      return appBarWidget;
    }
  }
}

// Sliver version of the custom app bar
class CustomSliverAppBar extends StatelessWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final bool useGlassmorphism;
  final Color? backgroundColor;
  final double expandedHeight;
  final bool floating;
  final bool pinned;
  final Widget? flexibleSpace;
  final Widget? background;
  final Widget? titleWidget;
  
  const CustomSliverAppBar({
    super.key,
    this.title = '',
    this.actions,
    this.leading,
    this.centerTitle = true,
    this.useGlassmorphism = true,
    this.backgroundColor,
    this.expandedHeight = 200,
    this.floating = false,
    this.pinned = true,
    this.flexibleSpace,
    this.background,
    this.titleWidget,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SliverAppBar(
      expandedHeight: expandedHeight,
      floating: floating,
      pinned: pinned,
      backgroundColor: useGlassmorphism 
          ? Colors.transparent 
          : backgroundColor ?? theme.colorScheme.surface,
      elevation: 0,
      leading: leading,
      centerTitle: centerTitle,
      title: titleWidget ?? Text(
        title,
        style: TextStyle(
          fontFamily: theme.textTheme.headlineMedium?.fontFamily,
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
      ),
      actions: actions,
      flexibleSpace: flexibleSpace ?? FlexibleSpaceBar(
        background: useGlassmorphism 
            ? GlassmorphicContainer(
                blur: 8,
                opacity: 0.1,
                padding: EdgeInsets.zero,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                child: background ?? Container(color: theme.colorScheme.surface),
              )
            : background ?? Container(color: theme.colorScheme.surface),
      ),
    );
  }
} 