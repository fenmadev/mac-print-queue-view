# Scenario overview

What the user sees and can do for each job, by job state. Only the user's own jobs are listed (D6). "Queue" means the active jobs of the selected printer; "Completed" means the 50 finished jobs of that printer with the highest job numbers.

| Job state (CUPS) | Shown as | List | Thumbnail | Preview | Available actions |
| --- | --- | --- | --- | --- | --- |
| pending | Pending (grey) | Queue | yes | yes | Pause, Print Earlier/Later (drag or arrows), Cancel Job |
| held | Paused (orange) | Queue | yes | yes | Resume, Print Earlier/Later (drag or arrows), Cancel Job |
| processing | Printing (blue, spinner) | Queue | yes | yes | Cancel Job only; cannot be paused or moved |
| stopped | Stopped (red) | Queue | yes | yes | Cancel Job |
| completed | Completed (green ✓) | Completed | no | while macOS retains the document | Print Again, Remove from List…, Clear… |
| canceled | Canceled (grey ✕) | Completed | no | while macOS retains the document | Print Again, Remove from List…, Clear… |
| aborted | Aborted (red !) | Completed | no | while macOS retains the document | Print Again, Remove from List…, Clear… |

## Situations

| Situation | What the app does |
| --- | --- |
| A new job appears or a job disappears | The list updates within about 2 seconds. |
| The selected job finishes | It moves from "Queue" to "Completed"; the selection and preview stay. |
| A selected completed job is removed | The selection and preview are cleared. |
| The user clicks Pause while the job has just started printing | The app re-checks with macOS, does not pause, and shows a message suggesting to cancel instead (D17). |
| The user drops a dragged job that has started printing meanwhile | The app re-checks with macOS and moves nothing (D15). |
| The user cancels a job | Immediately, without confirmation (D18); the job appears as "Canceled" under "Completed" and can be printed again. |
| The user prints a completed job again from a row icon or swipe | The app asks for confirmation first (D16). |
| The document of a job is no longer retained by macOS | Preview and "Print Again" are not possible; the app says so. |
| The document format cannot be displayed (for example PostScript) | The app says so instead of showing a preview. |
| Some documents of a job can be displayed and others cannot | The readable pages are shown with a warning naming each missing document (D22). |
| A confirmed removal concerns a job that has meanwhile returned to the queue | The job is not removed; the user is told it is no longer completed. |
| No printers are set up | The printer column says so. |
| The printing service cannot be reached | The printer column shows an error message. |
