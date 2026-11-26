import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PasswordRulesHelper {
  static bool hasMinLength(String password) => password.length >= 8;
  static bool hasUppercase(String password) => RegExp(r'[A-Z]').hasMatch(password);
  static bool hasNumber(String password) => RegExp(r'[0-9]').hasMatch(password);

  static bool isValid(String password) =>
      hasMinLength(password) && hasUppercase(password) && hasNumber(password);

  static int score(String password) =>
      (hasMinLength(password) ? 1 : 0) +
      (hasUppercase(password) ? 1 : 0) +
      (hasNumber(password) ? 1 : 0);
}

/// Checklist syarat kata sandi proaktif (muncul sebelum user gagal submit):
/// menunjukkan progres real-time saat mengetik lengkap dengan bar kekuatan.
class PasswordRulesChecklist extends StatelessWidget {
  final String password;

  const PasswordRulesChecklist({
    super.key,
    required this.password,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasMinLen = PasswordRulesHelper.hasMinLength(password);
    final bool hasUpper = PasswordRulesHelper.hasUppercase(password);
    final bool hasNumber = PasswordRulesHelper.hasNumber(password);
    final int score = PasswordRulesHelper.score(password);

    Color barColor = context.border;
    String strengthText = '';
    if (password.isNotEmpty) {
      if (score <= 1) {
        barColor = const Color(0xFFEF4444);
        strengthText = 'Lemah';
      } else if (score == 2) {
        barColor = const Color(0xFFF59E0B);
        strengthText = 'Sedang';
      } else {
        barColor = const Color(0xFF10B981);
        strengthText = 'Kuat';
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: context.isDark
            ? AppTheme.darkSurfaceElevated.withValues(alpha: 0.65)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: List.generate(3, (idx) {
                    final bool active = password.isNotEmpty && idx < score.clamp(1, 3);
                    return Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 4,
                        margin: EdgeInsets.only(right: idx == 2 ? 0 : 5),
                        decoration: BoxDecoration(
                          color: active ? barColor : context.border,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              if (strengthText.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(
                  strengthText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: barColor,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          _buildRuleRow(context, hasMinLen, 'Minimal 8 karakter'),
          const SizedBox(height: 5),
          _buildRuleRow(context, hasUpper, 'Ada huruf besar (A–Z)'),
          const SizedBox(height: 5),
          _buildRuleRow(context, hasNumber, 'Ada angka (0–9)'),
        ],
      ),
    );
  }

  Widget _buildRuleRow(BuildContext context, bool met, String label) {
    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: met ? const Color(0xFF10B981) : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(
              color: met ? const Color(0xFF10B981) : context.textMuted.withValues(alpha: 0.55),
              width: 1.5,
            ),
          ),
          child: met ? const Icon(Icons.check_rounded, size: 11, color: Colors.white) : null,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: met ? FontWeight.w700 : FontWeight.w500,
            color: met ? context.textPrimary : context.textMuted,
          ),
        ),
      ],
    );
  }
}

class PasswordMatchIndicator extends StatelessWidget {
  final String password;
  final String confirmPassword;

  const PasswordMatchIndicator({
    super.key,
    required this.password,
    required this.confirmPassword,
  });

  @override
  Widget build(BuildContext context) {
    if (confirmPassword.isEmpty) return const SizedBox.shrink();
    final bool matched = password == confirmPassword;
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 2),
      child: Row(
        children: [
          Icon(
            matched ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 14,
            color: matched ? const Color(0xFF059669) : const Color(0xFFDC2626),
          ),
          const SizedBox(width: 6),
          Text(
            matched ? 'Kata sandi cocok' : 'Kata sandi belum cocok',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: matched ? const Color(0xFF059669) : const Color(0xFFDC2626),
            ),
          ),
        ],
      ),
    );
  }
}
