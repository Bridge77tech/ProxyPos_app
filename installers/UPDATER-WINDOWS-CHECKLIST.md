# Auto-update: the Windows checklist

Everything in `lib/core/update` is covered by tests that run on a Mac — the offline
paths driven against real sockets, and a live run against GitHub:

```sh
flutter test                                                  # 134 pass, live ones skipped
PROXYPOS_LIVE_TESTS=1 flutter test test/update/update_live_network_test.dart
```

What none of that can do is build a `.exe`, run an installer, or replace a running application —
`flutter build windows` refuses to run off a Windows host and Inno Setup's compiler is
Windows-only. So the last mile is yours.

Budget about ten minutes, plus build time. Run it on a Windows machine that is **not**
a shop's till.

---

## 0. Before you start

- Inno Setup 6 installed, and `flutter doctor` clean for Windows desktop.
- You will see **"Windows protected your PC"** and **"Unknown publisher"** at every
  install. That is expected until the certificate arrives — click *More info* →
  *Run anyway*. It is not a symptom of anything being wrong.
- Every update needs a **UAC prompt**, because the app installs into Program Files.
  The owner has to click Yes. There is no way around that without changing where the
  app installs, which would move everybody's data.

---

## 1. Build 1.1.0 and check it knows its own version

```powershell
git pull
powershell -ExecutionPolicy Bypass -File installers\build_installer.ps1
```

Expect, at the end:

```
Installer: ...\installers\ProxyPOS-1.1.0.exe
SHA-256:   <64 hex characters>
Manifest:  ...\installers\latest.json
```

**Watch the build output for plugin DLL errors.** Adding `package_info_plus` moved
`win32` from 5.15.0 to 6.4.0, and `flutter_secure_storage` goes through `win32` too.

The resolved set looks right, and the detail that matters is that the resolver did not
leave secure storage behind: it moved `flutter_secure_storage_windows` from 4.1.0 to
4.2.2 in the same step. 4.1.0 asks for `win32: ^5.5.4`, 4.2.2 asks for `win32: ^6.0.1`,
and 4.2.0's changelog entry is *"Fix DPAPI FFI calls for compatibility with win32
6.0.0"*. So 6.4.0 is the version that release was written against, not one it is
tolerating — and 4.2.1 and 4.2.2 fix a Windows bug where concurrent reads and writes
could lose data. On paper this is a better combination than the one it replaced.

On paper is the operative phrase: none of it can be executed off a Windows host, which
is why step 1a below exists and is not optional. If the build fails here, this is the
first place to look, and `installers/WIN32-DEPENDENCY-NOTES.md` has the full picture
and the fallback — do not start pinning versions before reading it.

Then install it and open it:

- [ ] The app starts normally.
- [ ] Sign in works. (Signing in now also reports the version — step 5.)
- [ ] It opens just as fast as it used to. If startup feels slower, something is
      wrong: the check is not supposed to be on that path.

### 1a. Secure storage — do this one properly

**Launching is not the test.** This is:

- [ ] Sign in.
- [ ] Ring up a sale, and queue one offline (pull the network, complete a sale, so
      there is something in the offline queue).
- [ ] **Close the app completely.** Not minimised — closed, and gone from Task Manager.
- [ ] Reopen it.
- [ ] **You are still signed in.** You did not land on the login screen.
- [ ] **The queued offline sale is still there**, and still shows its contents.

Why this and not "does it launch": the Hive encryption key lives in Windows secure
storage (DPAPI, via `flutter_secure_storage`). The auth session, the user profile and
**the offline sale queue** are all in encrypted boxes keyed by it
(`lib/data/storage_box.dart`).

If DPAPI reads fail, `_getOrGenerateEncryptionKey` does not crash — it quietly mints a
*new* key (`lib/data/local_storage_service_impl.dart:148`), and if it throws a
`PlatformException` it returns null and the boxes open unencrypted. Either way the app
launches perfectly happily, and the previously encrypted data is simply unreadable. The
only symptom is that you are logged out and the queue is empty: a sale a shopkeeper
rang up and is waiting to sync, gone, with no error anywhere.

This is also the one failure auto-update cannot rescue, because it breaks sign-in
itself. If this step fails, stop and tell me — do not ship the build.

---

## 2. Prove it is harmless with no internet

This is the one that matters most, and the one worth doing properly.

- [ ] **Unplug the network / turn off wifi**, then start the app.
      It must open, reach the login screen, and work exactly as before. No error, no
      toast, no dialog, no spinner that outlasts the launch.
- [ ] **Connect to a network with no internet** (a phone hotspot with mobile data off
      is the easiest). Start the app. Same result.
      This case is different from the one above and is the one that catches lazy
      implementations: the connection exists, so nothing fails fast — it just hangs.
      The app must not wait for it.
- [ ] Start the app with internet but while the pointer does not exist yet (true right
      now — the production manifest is deliberately unpublished). Same result again.

If the owner can tell the difference between any of these three and a normal launch,
stop and say so.

---

## 3. Publish 1.2.0 and take the update

Make a visible change first so you can tell the versions apart — then:

```powershell
# in pubspec.yaml: version: 1.2.0+1
powershell -ExecutionPolicy Bypass -File installers\build_installer.ps1
```

Publish it, **in this order**:

```powershell
gh release create v1.2.0 installers\ProxyPOS-1.2.0.exe `
  --repo Bridge77tech/POS-Release --title "1.2.0"

# only once the upload has finished:
#   copy installers\latest.json over v1/pos/windows/latest.json in POS-Release, commit, push
```

The order is not a style preference. The manifest is what tills act on; publishing it
first points every till at a file that does not exist yet.

Now, on the machine still running 1.1.0:

- [ ] Start the app. Within a few seconds: **"Update available"**, naming 1.2.0 and
      saying the till is on 1.1.0.
- [ ] It does **not** appear mid-session. Use the app for a few minutes — no prompt.
- [ ] Click **Later**. The app carries on. Restart it: *no prompt this time* — a
      refusal is remembered per version.
- [ ] Clear it (`%APPDATA%\..\inventory_app_pos` Hive box `app_update_v1`, or just
      publish 1.3.0) and get the prompt back.
- [ ] Click **Install now**. Progress bar, then UAC, then the till closes, installs,
      and **comes back up on its own**.
- [ ] It reports 1.2.0, and **your data is still there** — products, settings, and
      anything queued offline. Check the offline queue specifically.

---

## 4. Break the download on purpose

- [ ] Start an update and **pull the network mid-download**.
      Expect: *"The download stopped before it finished. Your current version is
      untouched."* The app is still 1.1.0 and still works. Nothing is half-installed.
- [ ] Reconnect, click **Try again**. It resumes rather than starting from zero —
      watch the progress bar pick up above where it stopped.
- [ ] Edit the `sha256` in the published manifest to something wrong, and update.
      Expect: *"The download did not arrive intact and was discarded."* The app must
      refuse to run it. **Put the manifest back afterwards.**

---

## 5. Confirm the till reported itself

In the super admin, on the shop list:

- [ ] A **Till version** column, showing the version that till just reported.
- [ ] Hover it: the date it reported.
- [ ] A shop that has never run a reporting build shows `—`, not a version.

Run the migration first, on a database you have dumped:

```sh
pg_dump "$DATABASE_URL" > ~/backups/proxypos-$(date +%F).sql   # outside the repo
npm run migrate:pos-app-version
```

This column is not a nicety. It is the only way to answer *"has every till taken the
build?"*, which is the step that makes moving the update address safe. Without it that
move is a guess, and a wrong guess strands a shop permanently.

---

## 6. When the certificate arrives

Two commands, both already written out in `build_installer.ps1` under
"Signing (waiting on a certificate)". No updater code changes: the download is verified
by SHA-256, which is about the file arriving intact and has nothing to do with who
signed it.

Signing changes exactly one thing the owner sees — "Unknown publisher" becomes your
company name. The identity it will show is now consistent: `Runner.rc` and the
installer both say **Bridge77 Technologies**.

`MyAppURL` in `inventory_pos.iss` is `https://bridge77.vercel.app/products/ProxyPos` —
the publisher, support and updates links on the installer pages and in Add/Remove
Programs. Verified 200 before it went in. Note the `www.` form fails TLS and the path is
case-sensitive. It is cosmetic — the update check does not read it.

---

## What to tell me if something fails

The exact step number, what you saw instead, and — for anything at step 1 — the last
thirty lines of the build output. For step 3 or 4, whether the app still ran afterwards.
