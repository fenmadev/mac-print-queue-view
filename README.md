# Mac Print Queue View

A small macOS app that shows what is actually being printed from the **existing macOS print
queue**: select a print job and you immediately see a print preview of its content.

- Left column: the printers set up on this Mac, with the number of jobs in their queue.
- Middle column: the jobs for the selected printer. **In Queue** shows a thumbnail of the
  first page and a coloured status label for each job; **Completed** (the 50 with the highest job numbers) shows
  a compact list with a status icon. Make the thumbnails larger or smaller in seven steps with
  the arrow buttons in the toolbar of this column or with ⌥⌘= / ⌥⌘-; the column (and if needed
  the window) widens with them. (If macOS Accessibility Zoom has "Use keyboard shortcuts to zoom"
  turned on, macOS takes ⌥⌘= / ⌥⌘- itself; then use the toolbar buttons.)
- Right: the print preview. Page through with ⌘↑ / ⌘↓ or by scrolling, and zoom with
  ⌘= (zoom in), ⌘- (zoom out), ⌘0 (zoom to fit) or by pinching on the trackpad.
  Select several jobs in **In Queue** (⌘-click, or ⇧-click for a range) to see their first
  pages side by side in a grid, each with its order number.
- Drag the divider (with the grip) between the job list and the preview to resize the columns.

The queue is refreshed every 2 seconds, so new and disappearing jobs show up automatically.

The app only shows **your own** print jobs; other users' jobs on this Mac are not requested
(CUPS `my-jobs`).

## Languages

The app is available in **English**, **Dutch** and **Turkish** and follows the system language
by default: it uses the first of these languages in your macOS language list, or English if
none of them is in the list. To choose a language for the app itself,
open **Settings… (⌘,)** and pick a language; the app uses it after a restart ("Restart Now").
This is the same setting as *System Settings → General → Language & Region → Applications*.

Translations live in the String Catalog `MacPrintQueueView/Localizable.xcstrings`.
Xcode adds new strings to it automatically when building in the IDE; after building with
`xcodebuild` (or another editor), make a **Debug** build, run `Tools/sync-strings.sh [derived-data-path]`
(default `build`) and translate the new entries.

## Managing jobs

- **Cancel a job** in the queue with the cancel button (✕), ⌫ or the context menu
  (right-click). This happens immediately, also for a job that is printing; the job then moves
  to **Completed** as "Canceled", from where it can be printed again.
- **Pause a job** that is waiting to print: it stays in the queue but is skipped, so the other
  jobs keep printing (`Hold-Job`). **Resume** puts it back in its place (`Release-Job`).
  A job that is already printing cannot be paused (CUPS would abort it and start again from
  page 1): the app checks the current state with macOS right before pausing.
- **Change the order** of waiting jobs by dragging them, with the arrow buttons
  (⌥⌘↑ / ⌥⌘↓) or via the context menu. CUPS has no "move to position X"; it prints by
  **priority** (highest first) and then by job number. The app therefore sets the priority of
  your own jobs so that the desired order results (`Set-Job-Attributes`, `job-priority`).
  A job that is already printing stays where it is. When you drop a job, the app first checks
  the current queue again: if the job has started printing in the meantime, nothing is moved.
- **Several jobs at once**: select several jobs in **In Queue** with ⌘-click. The toolbar, the
  context menu and ⌫ then act on all of them: pause, resume, move (the selected jobs are first
  gathered into one block, which then moves one place) and cancel (after a confirmation).
  In the preview grid, drag a block onto another block to change the order of the selected jobs
  in the queue right away.
- **Print again**: a job from **Completed** (including a deleted one) can be put back in the
  queue with "Print Again" (`Restart-Job`), as long as macOS still retains its document.
  Note: this really prints it again.
- **Quick actions on completed jobs**: point at a completed job (or select it) to show small
  "print again" and "remove" buttons in the row, or swipe on the trackpad: swipe right to print
  again, swipe left to remove. Both ask for confirmation first.
- **Clear completed jobs** with ⌫ / the trash button (one job) or with **Clear…** next to the
  "Completed" header (all your completed jobs for that printer, including older ones not shown
  in the list). This also removes the retained document and cannot be undone.

## How it works

macOS uses CUPS as its printing system. A job in the queue contains the original document
(usually a PDF) in `/private/var/spool/cups`. That directory is readable by root only, so the
app does **not** read those files itself. Instead it requests the document from the local
printing service (`cupsd`) using the standard CUPS operation **`CUPS-Get-Document`**, over the
local socket `/private/var/run/cupsd`.

Over that socket cupsd knows who is asking, and only hands the document to the **owner of the
job** (or an administrator). So no root access, administrator password or helper tool is
needed, and you can never view another user's documents.

Furthermore:

- The app only changes the queue when you ask it to: canceling, pausing or resuming a job,
  printing it again, changing the order or removing completed jobs. This is only possible for your **own** jobs
  and requires no password.
- The app runs in the **App Sandbox** with only the printing entitlement
  (`com.apple.security.print`).
- The fetched document is kept in memory; the temporary file CUPS needs for the transfer is
  deleted immediately after it is created.

## When is there no preview?

The app clearly says when a preview is not possible, for example:

- the document is no longer in the queue (CUPS removes the files of completed jobs after a
  while);
- the document format cannot be displayed. Supported are PDF (which macOS apps almost always
  send), images (JPEG, PNG, TIFF, HEIC, …) and plain text. Since macOS 14, macOS can no longer
  convert PostScript or printer-specific data itself.

## Building

Requires Xcode 16 or later; the app runs on macOS 14 (Sonoma) and later.

```sh
open MacPrintQueueView.xcodeproj        # then ⌘R
# or from the terminal:
xcodebuild -project MacPrintQueueView.xcodeproj -scheme MacPrintQueueView \
           -configuration Release -derivedDataPath build build
open "build/Build/Products/Release/Mac Print Queue View.app"
```

To build the Release version and copy it to `~/Applications` (the Applications folder in your
home folder, created if needed) in one step, run `Tools/install-release.sh` in Terminal (an
optional argument names another destination folder). It replaces an earlier copy there and quits that copy first if it
is running; copies running from other folders are left alone, and when the list of running
programs cannot be read it stops without replacing anything. A copy started from Terminal through
a symbolic link to the destination is not recognised; quit it first.

Every build raises the build number by one (Debug, Release, an archive and the install script
alike): the build phase "Increase Build Number" runs `Tools/increase-build-number.sh`, which keeps
the last number in `BUILD_NUMBER` and writes the new one into the built app; the About window
shows it as "(Build n)". The build setting `CURRENT_PROJECT_VERSION` stays 1 and is replaced in
every built app, so Xcode's target settings do not show the real number. A failed build may still
use up a number, and two builds at the same moment can get the same number. A build made only to
check something (for a review, for example) should note `BUILD_NUMBER` before building and write
that value back afterwards. The version and its date are the build settings `MARKETING_VERSION`
and `MPQV_VERSION_DATE`.

The project is signed automatically with the FENMA IT B.V. team (Team ID `8RQJ83KNF9`).
To publish to the Mac App Store, use **Product → Archive** in Xcode and then
**Distribute App → App Store Connect**.

Project layout:

```
README.md, LICENSE.md        this documentation and the license
MacPrintQueueView/           Swift source code, translations and the asset catalog (app icon)
MacPrintQueueView.xcodeproj
Tools/                       scripts for the app icon, syncing translations, installing a release build, the test printer and the build number
```

## Testing without wasting paper

There are two ways to put test jobs in a queue without anything being printed.

**1. Held jobs on a real printer** (no setup). A held job waits until it is released, so it is
not printed:

```sh
echo "Test page" > /tmp/mpqv-test.txt        # or use any PDF
lp -H hold -d <printer-name> -t "MPQV test 1" /tmp/mpqv-test.txt    # printer names: lpstat -p
```

The jobs appear as **Paused**. Selecting, the preview grid, moving and canceling can be tried
safely; **do not use Resume**, as that releases the job and it is printed. Pausing cannot be
tried this way. Moving changes the priorities of all your waiting jobs on that printer, so do
not move test jobs while real jobs of yours are waiting there. Afterwards, cancel the test jobs
and remove them with **Remove from List…** (`cancel -x` does not remove them from the completed
jobs).

**2. A test printer that cannot print** (recommended; needs an administrator password). The
printer `MPQV_Testprinter` accepts jobs but never prints them on paper: its address is a port on
this Mac (`socket://127.0.0.1:59100`) where normally nothing listens, so its jobs wait.
`Tools/test-printer.sh` manages it:

```sh
Tools/test-printer.sh jobs        # 5 test jobs (creates the test printer first if needed)
Tools/test-printer.sh jobs 12     # 12 test jobs
Tools/test-printer.sh printing    # put the next waiting job in the "printing" state
Tools/test-printer.sh complete    # let the printing job finish as "completed"
Tools/test-printer.sh create      # only create the test printer
Tools/test-printer.sh remove      # remove the test printer and all its jobs
Tools/test-printer.sh sample      # show the text of one test job without submitting it
```

Each test job contains random text that starts with the current date and time
(for example `2026-11-16 20:57:43`); its title is "MPQV test <n> – <date and time>". The script
refuses to work if `MPQV_Testprinter` uses another address or if another program listens on that
port, and switches a test printer created with the earlier address `ipp://127.0.0.1:9/ipp/print`
to the new one. `remove` only removes `MPQV_Testprinter` when it has one of these two addresses;
a printer with that name and any other address may be a real printer and is left alone. If the
test printer does not accept jobs, the script lets it accept them and checks that it does; when
that cannot be read, it stops. Select **MPQV Testprinter** in the app: the jobs wait in the queue, and
everything can be tried, including pause, resume and moving.

`printing` starts the printer; macOS takes the next waiting job (paused jobs are skipped) and
should keep trying to reach the empty port, so that the job stays "printing" and the others keep
waiting. `complete` starts a temporary receiver on that port for exactly one connection, which
throws the data away (`/dev/null`); the printing job should then finish as completed, and the
printer is stopped again so that the next job does not start. **Not yet confirmed:** these two
commands need an administrator password and have not been run yet; whether the job really stays
"printing" and whether stopping the printer returns a job that has just started to waiting are
to be checked on their first use. The test printer is never shared with other computers. While
`printing` keeps it started, a program that starts listening on port 59100 later would receive
the job's data (the port is checked only when a command starts); stop it with `complete` or
`sudo cupsdisable MPQV_Testprinter` when done.

Done by hand, the test printer is created with:

```sh
sudo lpadmin -p MPQV_Testprinter -D "MPQV Testprinter (prints nothing)" \
  -v socket://127.0.0.1:59100 \
  -P /System/Library/Frameworks/ApplicationServices.framework/Versions/A/Frameworks/PrintCore.framework/Versions/A/Resources/Generic.ppd
sudo cupsaccept MPQV_Testprinter             # accept jobs; the printer stays stopped
```

## License

Copyright © 2026 Fenma IT. All rights reserved. See [LICENSE.md](LICENSE.md).

The source code is proprietary. The app is offered free of charge to everyone through the
Mac App Store.
