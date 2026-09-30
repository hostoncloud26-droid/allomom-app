
enum AllowearPermissionIssueType {
  permanentlyDenied,
  denied,
  locationServiceDisabled,
  bluetoothDisabled,
}

class AllowearPermissionIssue {
  final AllowearPermissionIssueType type;
  final String title;
  final String description;
  final String actionText;
  final bool isSettingsAction;

  const AllowearPermissionIssue({
    required this.type,
    required this.title,
    required this.description,
    required this.actionText,
    required this.isSettingsAction,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AllowearPermissionIssue &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          actionText == other.actionText &&
          isSettingsAction == other.isSettingsAction;

  @override
  int get hashCode =>
      type.hashCode ^ actionText.hashCode ^ isSettingsAction.hashCode;
}
