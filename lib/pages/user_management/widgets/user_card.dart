import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:phone_system_app/models/user.dart';
import '../constants/user_management_colors.dart';
import '../controllers/user_management_controller.dart';
import 'user_dialogs.dart';

class UserCard extends StatelessWidget {
  final AppUser user;
  final int index;
  final UserManagementController controller;

  const UserCard({
    super.key,
    required this.user,
    required this.index,
    required this.controller,
  });

  bool get isOwner => user.role == 1;

  @override
  Widget build(BuildContext context) {
    return AnimationConfiguration.staggeredList(
      position: index,
      duration: const Duration(milliseconds: 500),
      child: SlideAnimation(
        verticalOffset: 50.0,
        child: FadeInAnimation(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: _buildCardContent(context),
          ),
        ),
      ),
    );
  }

  Widget _buildCardContent(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: isOwner ? _ownerGradient : null,
        color: isOwner ? null : UserManagementColors.surface,
        boxShadow: [_buildShadow()],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border.all(
                color: isOwner
                    ? UserManagementColors.ownerGradientStart
                        .withValues(alpha: 0.3)
                    : Colors.grey.withValues(alpha: 0.1),
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                _buildHeader(context),
                const SizedBox(height: 20),
                _buildUserInfo(context),
                const SizedBox(height: 20),
                _buildActionButtons(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (isOwner) _buildOwnerBadge() else const SizedBox(),
        Row(
          children: [
            _buildIconButton(
              icon: Icons.edit_rounded,
              color: UserManagementColors.primary,
              onPressed: () =>
                  UserDialogs.showFullEdit(context, user, controller),
            ),
            const SizedBox(width: 8),
            if (!isOwner)
              _buildIconButton(
                icon: Icons.delete_rounded,
                color: UserManagementColors.accent,
                onPressed: () => UserDialogs.showDeleteConfirmation(
                    context, user, controller),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildOwnerBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            UserManagementColors.ownerGradientStart,
            UserManagementColors.ownerGradientEnd,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color:
                UserManagementColors.ownerGradientStart.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, color: Colors.white, size: 16),
          SizedBox(width: 6),
          Text(
            "المالك",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfo(BuildContext context) {
    return Row(
      children: [
        _buildAvatar(context),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.name ?? 'غير محدد',
                style: TextStyle(
                  fontSize: isOwner ? 22 : 20,
                  fontWeight: FontWeight.bold,
                  color: isOwner
                      ? UserManagementColors.ownerText
                      : UserManagementColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              _buildSecpassBadge(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar(BuildContext context) {
    return GestureDetector(
      onTap: () => UserDialogs.showImageOptions(context, user, controller),
      child: Hero(
        tag: 'user_${user.uid}',
        child: Container(
          width: isOwner ? 90 : 80,
          height: isOwner ? 90 : 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isOwner
                  ? [
                      UserManagementColors.ownerGradientStart,
                      UserManagementColors.ownerGradientEnd,
                    ]
                  : [
                      UserManagementColors.primary,
                      UserManagementColors.secondary,
                    ],
            ),
            boxShadow: [
              BoxShadow(
                color: (isOwner
                        ? UserManagementColors.ownerGradientStart
                        : UserManagementColors.primary)
                    .withValues(alpha: 0.4),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(3),
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            padding: const EdgeInsets.all(3),
            child: ClipOval(
              child: user.avatarUrl != null
                  ? Image.network(
                      user.avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildDefaultAvatar(),
                    )
                  : _buildDefaultAvatar(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Image.asset(
      isOwner ? 'assets/images/owner.png' : 'assets/images/MKQ.png',
      fit: BoxFit.cover,
    );
  }

  Widget _buildSecpassBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isOwner
            ? UserManagementColors.ownerBackground
            : UserManagementColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOwner
              ? UserManagementColors.ownerGradientStart
              : UserManagementColors.primary,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.security_rounded,
            size: 14,
            color: isOwner
                ? UserManagementColors.ownerGradientStart
                : UserManagementColors.primary,
          ),
          const SizedBox(width: 6),
          Text(
            'كلمة المرور: ${user.secpass ?? 'غير محدد'}',
            style: TextStyle(
              fontSize: 13,
              color: isOwner
                  ? UserManagementColors.ownerText
                  : UserManagementColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.end,
      children: [
        _buildActionChip(
          icon: Icons.person_rounded,
          label: 'تعديل الاسم',
          onPressed: () => UserDialogs.showEditName(context, user, controller),
        ),
        _buildActionChip(
          icon: Icons.security_rounded,
          label: 'كلمة المرور الثانية',
          onPressed: () =>
              UserDialogs.showEditSecpass(context, user, controller),
        ),
        _buildActionChip(
          icon: Icons.lock_rounded,
          label: 'كلمة المرور',
          onPressed: () =>
              UserDialogs.showEditPassword(context, user, controller),
        ),
      ],
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: 20),
        onPressed: onPressed,
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(),
      ),
    );
  }

  Widget _buildActionChip({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: UserManagementColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: UserManagementColors.textSecondary, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: UserManagementColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  LinearGradient get _ownerGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          UserManagementColors.ownerBackground,
          UserManagementColors.ownerBackgroundLight,
        ],
      );

  BoxShadow _buildShadow() {
    return BoxShadow(
      color: isOwner
          ? UserManagementColors.ownerGradientStart.withValues(alpha: 0.2)
          : Colors.black.withValues(alpha: 0.08),
      blurRadius: 20,
      offset: const Offset(0, 10),
    );
  }
}
