/// Where the till looks to find out whether a newer build exists.
///
/// ─────────────────────────────────────────────────────────────────────────────
/// READ THIS BEFORE CHANGING ANYTHING IN THIS FILE.
///
/// This is the one address in the product that cannot be corrected by shipping an
/// update. Every other mistake in the updater is recoverable: publish a fixed build
/// and the tills pick it up. If a till is checking an address that no longer answers,
/// the fix can never reach it, because the fix travels over the very thing that is
/// broken. That till becomes a site visit with a USB stick.
///
/// So the design is two layers of indirection and two independent roots.
/// ─────────────────────────────────────────────────────────────────────────────
///
/// ## Layer 1 — the pointer
///
/// The app asks a small JSON file what the newest version is and *where the installer
/// lives*. The installer's address is therefore data, not code. Moving the builds to
/// R2, S3, a VPS or anywhere else is a one-line edit to that JSON: no release, no
/// bridging build, no window in which a till is checking somewhere dead.
///
/// ## Layer 2 — the build
///
/// Named by the `url` field inside the pointer. Nothing in the app knows or cares
/// where it is.
///
/// ## Why a list rather than one URL
///
/// One baked-in address is still one address. [pointerUrls] is tried strictly in
/// order until one answers, so stranding a till requires losing *both* roots at once
/// — a domain registrar and GitHub, simultaneously. A single failure is survivable by
/// design rather than by luck.
///
/// ## Adding the dedicated domain later
///
/// Not registered yet, so today the list has one entry. When it exists, insert it at
/// position 0 and keep the GitHub entry below it. Nothing else in the codebase
/// changes — no model, no parser, no call site. That is the whole point of the list.
///
///     static const List<String> pointerUrls = [
///       'https://updates.<domain>/v1/pos/windows/latest.json',   // ← new primary
///       'https://raw.githubusercontent.com/...',                  // ← keeps working
///     ];
///
/// Tills already in the field reach the new domain on the release *after* the one
/// that introduces it. Until then they keep using GitHub, which is exactly why the
/// GitHub entry must never be removed in the same release that adds a new primary.
///
/// ## If the primary ever has to be retired, the order is not optional
///
///   1. While the old address still answers, publish a build carrying the new
///      address *and* the old one.
///   2. Confirm every till has taken that build. Not "wait a while" — confirm, using
///      the version each shop reports on login (see [UpdateService.currentVersion]
///      and the POS version column in the super admin).
///   3. Only then let the old address lapse.
///
/// Done out of order, any till that had not yet taken the crossover build is checking
/// a dead address permanently.
class UpdateEndpoints {
  UpdateEndpoints._();

  /// Pointer locations, most-preferred first. Tried in order; the first that returns
  /// a well-formed manifest wins. Every failure below is a silent no-op.
  ///
  /// Verified live before being committed:
  ///   curl -sS -o /dev/null -w '%{http_code}' \
  ///     https://raw.githubusercontent.com/Bridge77tech/POS-Release/main/README.md
  ///   → 200, anonymously, with no token.
  ///
  /// Anonymous access matters more than it looks. The source repositories are
  /// private, so release assets there would need a credential baked into the app —
  /// and a credential that expires strands every till exactly as a dead domain would.
  /// POS-Release is public and carries no source for that reason.
  ///
  /// The path is deliberately all lower case. raw.githubusercontent.com is
  /// case-insensitive about the owner and repository (checked: `pos-release` and
  /// `bridge77tech` both return 200) but case-*sensitive* about everything after the
  /// branch, because that part is a git tree path.
  static const List<String> pointerUrls = [
    'https://raw.githubusercontent.com/Bridge77tech/POS-Release/main/v1/pos/windows/latest.json',
  ];

  /// How long to wait on any single pointer before giving up on it.
  ///
  /// Short on purpose. This runs while the owner is trying to start selling, and the
  /// answer "no update" is worth nothing to them. A till on a bad connection should
  /// fall through the whole list and forget about it in well under half a minute.
  static const Duration pointerTimeout = Duration(seconds: 6);

  /// Applies to the installer download, which is tens of megabytes on connections
  /// that routinely stall — so it is generous where the pointer check is not. The
  /// owner has explicitly agreed to this one and can see it happening.
  static const Duration downloadIdleTimeout = Duration(minutes: 2);
}
