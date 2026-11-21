import 'package:flutter/widgets.dart';

import '../../auth/auth_error_messages.dart';
import '../../auth/auth_exception.dart';
import '../../l10n/l10n_extensions.dart';

/// Readable, localised message for any sign-in failure.
String rawanaAuthFailure(BuildContext context, Object error) {
  if (error is RawanaAuthException) return authErrorMessage(error.messageKey, l10n: context.l10n);
  return context.l10n.friendlyApiError(error);
}
