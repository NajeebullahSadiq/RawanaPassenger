import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const here = path.dirname(fileURLToPath(import.meta.url));
const pyPath = path.join(here, "generate_l10n.py");
const src = fs.readFileSync(pyPath, "utf8");
const start = src.indexOf("STRINGS: dict[str, dict[str, str]] = {");
const end = src.indexOf("\nPLACEHOLDER_RE", start);
if (start < 0 || end < 0) {
  throw new Error("Could not find STRINGS dict in generate_l10n.py");
}
function stripHashComments(text) {
  let out = "";
  let inString = false;
  for (let i = 0; i < text.length; i++) {
    const ch = text[i];
    if (inString) {
      out += ch;
      if (ch === "\\" && i + 1 < text.length) {
        out += text[++i];
      } else if (ch === '"') {
        inString = false;
      }
      continue;
    }
    if (ch === '"') {
      inString = true;
      out += ch;
      continue;
    }
    if (ch === "#") {
      while (i < text.length && text[i] !== "\n") i++;
      out += "\n";
      continue;
    }
    out += ch;
  }
  return out;
}

const dictSrc = stripHashComments(src.slice(src.indexOf("{", start), end))
  .replace(/,\s*}/g, "}")
  .replace(/,\s*]/g, "]");
const STRINGS = JSON.parse(dictSrc);

const PLACEHOLDER_RE = /\{(\w+)\}/g;

function placeholders(text) {
  const names = [...text.matchAll(PLACEHOLDER_RE)].map((m) => m[1]);
  return Object.fromEntries(names.map((n) => [n, { type: "String" }]));
}

function uniqueParams(en) {
  const seen = [];
  for (const m of en.matchAll(PLACEHOLDER_RE)) {
    if (!seen.includes(m[1])) seen.push(m[1]);
  }
  return seen;
}

function dartLiteral(text) {
  const parts = text.split(PLACEHOLDER_RE);
  let out = "";
  for (let i = 0; i < parts.length; i++) {
    if (i % 2 === 1) {
      out += "${" + parts[i] + "}";
    } else {
      out += parts[i]
        .replaceAll("\\", "\\\\")
        .replaceAll("$", "\\$")
        .replaceAll("'", "\\'")
        .replaceAll("\n", "\\n")
        .replaceAll("\r", "\\r");
    }
  }
  return `'${out}'`;
}

function writeArb(file, locale) {
  const data = { "@@locale": locale };
  for (const [key, langs] of Object.entries(STRINGS)) {
    data[key] = langs[locale];
    const ph = placeholders(langs.en);
    if (Object.keys(ph).length) data[`@${key}`] = { placeholders: ph };
  }
  fs.writeFileSync(file, JSON.stringify(data, null, 2) + "\n", "utf8");
}

function writeImpl(file, locale, suffix) {
  let lines = [
    "// ignore: unused_import",
    "import 'package:intl/intl.dart' as intl;",
    "import 'app_localizations.dart';",
    "",
    "// ignore_for_file: type=lint",
    "",
    `/// The translations for ${locale} (\`${locale}\`).`,
    `class AppLocalizations${suffix} extends AppLocalizations {`,
    `  AppLocalizations${suffix}([String locale = '${locale}']) : super(locale);`,
    "",
  ];
  for (const [key, langs] of Object.entries(STRINGS)) {
    const params = uniqueParams(langs.en);
    const value = dartLiteral(langs[locale]);
    if (params.length) {
      const sig = params.map((p) => `String ${p}`).join(", ");
      lines.push("  @override");
      lines.push(`  String ${key}(${sig}) {`);
      lines.push(`    return ${value};`);
      lines.push("  }");
      lines.push("");
    } else {
      lines.push("  @override");
      lines.push(`  String get ${key} => ${value};`);
      lines.push("");
    }
  }
  lines.push("}");
  lines.push("");
  fs.writeFileSync(file, lines.join("\n"), "utf8");
}

function writeAbstract(file) {
  const getters = [];
  for (const [key, langs] of Object.entries(STRINGS)) {
    const params = uniqueParams(langs.en);
    if (params.length) {
      getters.push(`  String ${key}(${params.map((p) => `String ${p}`).join(", ")});\n`);
    } else {
      getters.push(`  String get ${key};\n`);
    }
  }
  const content = `import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fa.dart';
import 'app_localizations_ps.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with \`AppLocalizations.of(context)\`.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)
        ?? lookupAppLocalizations(const Locale('en'));
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fa'),
    Locale('ps'),
  ];

${getters.join("\n")}}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fa', 'ps'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fa':
      return AppLocalizationsFa();
    case 'ps':
      return AppLocalizationsPs();
  }

  return AppLocalizationsEn();
}
`;
  fs.writeFileSync(file, content, "utf8");
}

function writeExtension(file) {
  fs.writeFileSync(
    file,
    `import 'package:flutter/widgets.dart';
import 'app_localizations.dart';

extension RawanaL10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

extension RawanaL10nHelpers on AppLocalizations {
  String tripStatusLabel(String apiValue) {
    switch (apiValue) {
      case 'searching':
        return statusSearching;
      case 'accepted':
        return statusAccepted;
      case 'driver_arriving':
        return statusDriverArriving;
      case 'trip_started':
        return statusTripStarted;
      case 'completed':
        return statusCompleted;
      case 'cancelled':
        return statusCancelled;
      default:
        return apiValue.replaceAll('_', ' ');
    }
  }

  String authError(String key, {String? detail}) {
    switch (key) {
      case 'supabase_not_configured':
        return detail ?? authSupabaseNotConfigured;
      case 'invalid_credentials':
        return authInvalidCredentials;
      case 'email_not_verified':
        return authEmailNotVerified;
      case 'email_already_exists':
        return authEmailAlreadyExists;
      case 'rate_limit':
        return authRateLimit;
      case 'database_signup_failed':
        return authDatabaseSignupFailed;
      case 'weak_password':
        return authWeakPassword;
      case 'invalid_email':
        return authInvalidEmail;
      case 'invalid_phone':
        return authInvalidPhone;
      case 'invalid_otp':
        return authInvalidOtp;
      case 'whatsapp_api_not_configured':
        return authWhatsAppUnavailable;
      default:
        return detail ?? authGenericError;
    }
  }

  String languageName(String code) {
    switch (code) {
      case 'fa':
        return languageDari;
      case 'ps':
        return languagePashto;
      default:
        return languageEnglish;
    }
  }
}
`,
    "utf8",
  );
}

function generate(outDir) {
  fs.mkdirSync(outDir, { recursive: true });
  writeArb(path.join(outDir, "app_en.arb"), "en");
  writeArb(path.join(outDir, "app_fa.arb"), "fa");
  writeArb(path.join(outDir, "app_ps.arb"), "ps");
  writeAbstract(path.join(outDir, "app_localizations.dart"));
  writeImpl(path.join(outDir, "app_localizations_en.dart"), "en", "En");
  writeImpl(path.join(outDir, "app_localizations_fa.dart"), "fa", "Fa");
  writeImpl(path.join(outDir, "app_localizations_ps.dart"), "ps", "Ps");
  writeExtension(path.join(outDir, "l10n_extensions.dart"));
  console.log(`Generated ${Object.keys(STRINGS).length} keys in ${outDir}`);
}

const passengerL10n = path.resolve(here, "../lib/l10n");
generate(passengerL10n);
const repo = path.resolve(here, "../../../../");
const driverL10n = path.join(repo, "driver_app/packages/rawana_core/lib/l10n");
generate(driverL10n);
fs.mkdirSync(path.join(repo, "driver_app/packages/rawana_core/tool"), { recursive: true });
fs.copyFileSync(pyPath, path.join(repo, "driver_app/packages/rawana_core/tool/generate_l10n.py"));
fs.copyFileSync(
  path.join(here, "generate_l10n.mjs"),
  path.join(repo, "driver_app/packages/rawana_core/tool/generate_l10n.mjs"),
);
