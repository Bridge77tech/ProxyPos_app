# The win32 bump: the picture, ready in case the Windows build fails

Written so that if step 1 of the Windows checklist fails, the dependency situation is
already worked out rather than being reasoned about under pressure.

**Nothing here has been applied.** The resolved versions are what `flutter pub get`
chose. Do not pin anything until a Windows build has actually failed.

---

## What changed, exactly

Adding `package_info_plus` to `pubspec.yaml` moved four things (`git diff pubspec.lock`):

| Package | Before | After |
|---|---|---|
| `win32` | 5.15.0 | **6.4.0** |
| `flutter_secure_storage_windows` | 4.1.0 | **4.2.2** |
| `ffi` | 2.1.5 | 2.2.0 |
| `ffi_leak_tracker` | — | 0.1.2 (new) |
| `package_info_plus` | — | 10.2.2 (new) |

## Who depends on `win32`, and what each one asks for

From `flutter pub deps` and each package's own `pubspec.yaml` in `~/.pub-cache`:

| Package | Version | Declares |
|---|---|---|
| `package_info_plus` | 10.2.2 | `win32: ^6.0.1` |
| `flutter_secure_storage_windows` | 4.2.2 | `win32: ^6.0.1` |
| `path_provider_windows` | 2.3.0 | no `win32` dependency |

Both packages that use `win32` want the same major, and 6.4.0 satisfies both. There is
no constraint conflict here and no version was forced.

## Is 6.x officially supported by secure storage?

Yes, and this is the part worth knowing before touching anything. From
[the `flutter_secure_storage_windows` changelog](https://pub.dev/packages/flutter_secure_storage_windows/changelog):

- **4.2.0** — *"Fix DPAPI FFI calls for compatibility with `win32` 6.0.0."*
- **4.2.1** — *"Fix concurrent read/write operations causing data loss or a
  `PathAccessException` on Windows (issue #634)."*
- **4.2.2** — *"Fixed `deleteAll` and `containsKey` not acquiring the mutex lock, which
  could cause data races under concurrent access."*

4.2.0 exists **because of** win32 6.0.0. The previous 4.1.0 (`win32: ^5.5.4`) is the one
that would break against 6.x, and the resolver did not leave us there. 4.2.1 and 4.2.2
then fix a Windows data-loss bug that 4.1.0 still has.

So the expected outcome is that this build is *better* than the one before it. That is
a prediction, not a result — see below.

## Why it still has to be proven on Windows

`win32` is FFI bindings onto the Win32 API. Secure storage reaches DPAPI through them.
A mismatch there is a runtime failure in native calls, which no amount of resolving on
a Mac can tell you about.

And it fails quietly. `LocalStorageServiceImpl._getOrGenerateEncryptionKey`
(`lib/data/local_storage_service_impl.dart:114`) does this:

- a failed **read** is indistinguishable from "no key yet", so it mints a **new** key;
- a `PlatformException` is caught and it returns `null`, so boxes open **unencrypted**.

Either way the app launches normally. What is gone is everything in the encrypted
boxes — `auth_v1`, `user_profile_v1`, and `create_new_sale_v1`, **the offline sale
queue** (`lib/data/storage_box.dart`). A shopkeeper's queued sale would simply not be
there, with no error.

That is why checklist step **1a** is sign in → queue an offline sale → fully close →
reopen → *still signed in, sale still queued*. "It launched" would pass while the
product was broken.

## If the build fails — the fallback, in order

1. **Read the actual error first.** A link error naming a `win32` symbol is one thing;
   a missing `package_info_plus` plugin registration is another and is not this.

2. **Try dropping `package_info_plus` rather than pinning `win32`.** It is the thing
   that pulled the upgrade, and the updater needs one string from it. The replacement
   is a generated constant written by `build_installer.ps1` from `pubspec.yaml` at
   build time, which removes the dependency entirely and keeps pubspec as the single
   source of the version. Slightly more build machinery, no FFI at all.

3. **Pinning `win32: 5.15.0` is not available.** It would force
   `flutter_secure_storage_windows` back to 4.1.0, which means re-adopting the
   concurrent-write data-loss bug fixed in 4.2.1 — on a till, where the thing being
   written concurrently is a sale. Do not take that trade to keep a version number.

4. **If secure storage is what broke**, check `flutter_secure_storage` itself for a
   newer release before changing `win32`; the Windows implementation is a separate
   package and moves on its own.

## Unrelated, but found while looking

`ios/Runner/Runner.entitlements` declares keychain access group
`com.fasahahaus.inventoryAppPos`, while the iOS bundle identifier in
`ios/Runner.xcodeproj/project.pbxproj` is `com.fasahahaus-co.inventoryAppPos`. Those do
not match, and on iOS a mismatched access group breaks keychain reads — the same class
of silent session loss as above. Not touched: it is an iOS build question and the iOS
app is signed under Apple team `6DGPP4FWV8`, which is a separate decision.
