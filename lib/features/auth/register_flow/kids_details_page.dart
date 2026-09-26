import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:allomom/features/baby/baby_form_sheet.dart';
import 'package:allomom/services/sq_lite/drift_database.dart';
import 'package:allomom/features/auth/register_flow/register_flow_page.dart';

class KidsDetailsPage extends StatelessWidget {
  final String userName;
  final String status;
  final DateTime? eddDate;
  final DateTime? lmpDate;
  final int? averageCycleLength;
  final String? partnerName;
  final String? partnerPhone;
  final String phone;
  final String countryCode;
  final String selectedRole;
  final String? familyCode;
  final bool registerPregnancyForPartner;

  const KidsDetailsPage({
    super.key,
    required this.userName,
    required this.status,
    required this.eddDate,
    this.lmpDate,
    this.averageCycleLength,
    this.partnerName,
    this.partnerPhone,
    this.phone = '',
    this.countryCode = '+91',
    this.selectedRole = 'Mom',
    this.familyCode,
    this.registerPregnancyForPartner = false,
  });

  @override
  Widget build(BuildContext context) {
    return RegisterFlowPage(
      initialStep: RegisterStep.kids,
      userName: userName,
      status: status,
      eddDate: eddDate,
      lmpDate: lmpDate,
      partnerName: partnerName,
      partnerPhone: partnerPhone,
      phone: phone,
      countryCode: countryCode,
      selectedRole: selectedRole,
      familyCode: familyCode,
      registerPregnancyForPartner: registerPregnancyForPartner,
    );
  }
}

class KidsDetailsStepView extends StatefulWidget {
  final List<Baby> children;

  /// Called with the new birth record id once a child is added inline.
  final ValueChanged<String> onChildAdded;

  /// Called with each question the baby asks while a child is being added.
  final ValueChanged<String>? onNarrate;

  /// Called when the inline add form is closed without saving.
  final VoidCallback? onAddCancelled;
  final void Function(Baby baby)? onDeleteChild;
  final String? deletingChildId;
  final bool isLoading;
  final bool isNewMom;
  final VoidCallback onComplete;

  const KidsDetailsStepView({
    super.key,
    required this.children,
    required this.onChildAdded,
    this.onNarrate,
    this.onAddCancelled,
    this.onDeleteChild,
    this.deletingChildId,
    required this.isLoading,
    this.isNewMom = false,
    required this.onComplete,
  });

  @override
  State<KidsDetailsStepView> createState() => _KidsDetailsStepViewState();
}

class _KidsDetailsStepViewState extends State<KidsDetailsStepView> {
  /// Whether the card shows the add-child stepper instead of the list.
  bool _adding = false;

  List<Baby> get children => widget.children;
  void Function(Baby baby)? get onDeleteChild => widget.onDeleteChild;
  String? get deletingChildId => widget.deletingChildId;
  bool get isLoading => widget.isLoading;
  bool get isNewMom => widget.isNewMom;
  VoidCallback get onComplete => widget.onComplete;

  void onAddChild() => setState(() => _adding = true);

  static final _dateFmt = DateFormat('dd MMM yyyy');

  @override
  Widget build(BuildContext context) {
    if (_adding) {
      return BabyFormSteps(
        title: 'Add a child',
        expand: true,
        onNarrate: widget.onNarrate,
        onCancel: () {
          setState(() => _adding = false);
          widget.onAddCancelled?.call();
        },
        onSaved: (id) {
          setState(() => _adding = false);
          widget.onChildAdded(id);
        },
      );
    }

    final bool isRequirementMet = !isNewMom || children.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Your Children (${children.length})',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E2024),
                      ),
                    ),
                    GestureDetector(
                      onTap: onAddChild,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF0F3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFF8FA3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.add_rounded,
                              size: 16,
                              color: Color(0xFFFF4E6A),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Add Child',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFFF4E6A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Children List / Empty Placeholder
                if (children.isEmpty)
                  GestureDetector(
                    onTap: onAddChild,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFE5E7EB),
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.child_care_rounded,
                            size: 32,
                            color: Color(0xFF9CA3AF),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Tap here to add a child',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SizedBox(
                    height: 90,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: children.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final child = children[index];
                        final isDeleting = deletingChildId == child.id;
                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 160,
                              padding: const EdgeInsets.fromLTRB(
                                12,
                                10,
                                26,
                                10,
                              ),
                              decoration: BoxDecoration(
                                color: isDeleting
                                    ? const Color(0xFFF3F4F6)
                                    : const Color(0xFFFFF0F3),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isDeleting
                                      ? const Color(0xFFE5E7EB)
                                      : const Color(0xFFFFD1DC),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    child.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.bold,
                                      color: isDeleting
                                          ? const Color(0xFF9CA3AF)
                                          : const Color(0xFF1E2024),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _dateFmt.format(child.deliveryDate),
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: isDeleting
                                          ? const Color(0xFF9CA3AF)
                                          : const Color(0xFF6B7280),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (onDeleteChild != null)
                              Positioned(
                                top: 4,
                                right: 4,
                                child: InkWell(
                                  onTap: isDeleting
                                      ? null
                                      : () => onDeleteChild!(child),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.08,
                                          ),
                                          blurRadius: 4,
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                    child: isDeleting
                                        ? const SizedBox(
                                            width: 13,
                                            height: 13,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Color(0xFFFF4E6A),
                                            ),
                                          )
                                        : const Icon(
                                            Icons.close_rounded,
                                            size: 13,
                                            color: Color(0xFFFF4E6A),
                                          ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // ─── COMPLETE REGISTRATION BUTTON ───
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: isLoading
                ? null
                : (isRequirementMet ? onComplete : onAddChild),
            style: ElevatedButton.styleFrom(
              backgroundColor: isRequirementMet
                  ? const Color(0xFFFF5277)
                  : const Color(0xFFE5E7EB),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              elevation: 0,
            ),
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    isRequirementMet
                        ? 'Complete Setup'
                        : 'Add at least 1 Child to Continue',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isRequirementMet
                          ? Colors.white
                          : const Color(0xFF9CA3AF),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
