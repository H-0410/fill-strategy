import 'package:flutter/material.dart';

const primaryBlue = Color(0xFF2B65D8);
const primaryBlueDark = Color(0xFF1E4FA8);
const accentOrange = Color(0xFFFF7D00);
const successGreen = Color(0xFF00B42A);
const dangerRed = Color(0xFFF53F3F);
const neutralGray = Color(0xFF86909C);
const textPrimary = Color(0xFF1D2129);
const textSecondary = Color(0xFF4E5969);
const bgPage = Color(0xFFF7F8FA);
const bgEyeCare = Color(0xFFFFF9E8);
const cardBg = Colors.white;
const dividerColor = Color(0xFFE5E6EB);

ThemeData buildTheme({
  required bool eyeCare,
  required double scale,
}) {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: eyeCare ? bgEyeCare : bgPage,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryBlue,
      primary: primaryBlue,
    ),
    textTheme: ThemeData.light().textTheme.apply(
          fontSizeFactor: scale,
          bodyColor: textPrimary,
          displayColor: textPrimary,
        ),
    cardTheme: CardTheme(
      color: cardBg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      backgroundColor: primaryBlue,
      foregroundColor: Colors.white,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: IconThemeData(color: Colors.white),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: primaryBlue,
      unselectedItemColor: neutralGray,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      unselectedLabelStyle: TextStyle(fontSize: 12),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: primaryBlue,
      inactiveTrackColor: const Color(0xFFE5E6EB),
      thumbColor: Colors.white,
      overlayColor: primaryBlue.withOpacity(0.1),
      valueIndicatorColor: primaryBlue,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) return primaryBlue;
        return Colors.white;
      }),
      trackColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) return primaryBlue.withOpacity(0.5);
        return const Color(0xFFE5E6EB);
      }),
    ),
    dividerTheme: const DividerThemeData(
      color: dividerColor,
      thickness: 0.5,
    ),
  );
}

/// 通用卡片容器
Widget cardContainer({
  required Widget child,
  EdgeInsetsGeometry padding = const EdgeInsets.all(18),
  Color? color,
  VoidCallback? onTap,
}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: color ?? cardBg,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    ),
  );
}

/// 大按钮
Widget bigButton({
  required String text,
  required VoidCallback? onPressed,
  Color color = accentOrange,
  Color textColor = Colors.white,
  bool outlined = false,
}) {
  return SizedBox(
    height: 56,
    width: double.infinity,
    child: outlined
        ? OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: color, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              foregroundColor: color,
              textStyle: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            child: Text(text),
          )
        : FilledButton(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: onPressed == null ? neutralGray : color,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              foregroundColor: textColor,
              textStyle: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            child: Text(text),
          ),
  );
}
