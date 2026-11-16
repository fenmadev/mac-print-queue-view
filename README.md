# Mac Print Queue View

A small macOS app that shows what is actually being printed from the **existing macOS print
queue**: select a print job and you immediately see a print preview of its content.

- Left column: the printers set up on this Mac, with the number of jobs in their queue.
- Middle column: the jobs for the selected printer. **In Queue** shows a thumbnail of the
  first page and a coloured status label for each job; **Completed** (the 50 with the highest job numbers) shows
  a compact list with a status icon.
- Right: the print preview. Page through with ⌘↑ / ⌘↓ or by scrolling, and zoom with
  ⌘= (zoom in), ⌘- (zoom out), ⌘0 (zoom to fit) or by pinching on the trackpad.

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

The project is signed automatically with the FENMA IT B.V. team (Team ID `8RQJ83KNF9`).
To publish to the Mac App Store, use **Product → Archive** in Xcode and then
**Distribute App → App Store Connect**.

Project layout:

```
README.md, LICENSE.md        this documentation and the license
MacPrintQueueView/           Swift source code, translations and the asset catalog (app icon)
MacPrintQueueView.xcodeproj
Tools/                       scripts for the app icon and for syncing translations
```

## Testing without wasting paper

Put a job in the queue that is **held** and therefore not printed:

```sh
lp -H hold -d <printer-name> document.pdf    # printer names: lpstat -p
cancel <printer-name>-<job-number>           # remove it again afterwards
```

## License

Copyright © 2026 Fenma IT. All rights reserved. See [LICENSE.md](LICENSE.md).

The source code is proprietary. The app is offered free of charge to everyone through the
Mac App Store.
