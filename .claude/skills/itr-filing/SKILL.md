---
name: itr-filing
description: Compute Indian income tax and file ITR-1/ITR-2 on eportal.incometax.gov.in via browser automation. Use when asked to analyse tax documents, compute tax payable, or fill/resume an ITR on the portal. Stops after portal validation passes, before e-verification.
---

# Filing ITR on the Indian e-Filing portal

Two phases: compute everything offline first, then transcribe onto the portal. Never compute on the portal.

## Prerequisites - present this list to the user and wait

Ask the user to place in one folder:
- Form 16 (employer), Form 26AS, AIS PDF
- Broker tax reports: every Indian and foreign broker (equity, MF, bonds) used that FY
- Form 67 acknowledgement + foreign withholding proof if claiming FTC
- Bank interest figures (or rely on AIS)
- Portal password in a plain file (e.g. `.itr_pass` in the docs folder) - read it at runtime only, never print/echo it, and remind the user to delete it after filing
- Which regime, which form (ITR-1/ITR-2), and whether a half-filled draft exists on the portal to resume

## Phase 1 - Offline computation

Parse every document (openpyxl for xlsx, pdfminer for PDFs). Then:

- Hunt duplicates before summing: the same MF redemptions appear in multiple broker reports (match lots by ISIN + quantity); AIS lists the same trade via two RTAs/depositories but marks one "Inactive"; broker dividend lists duplicate AIS SFT data. Beware false duplicates too: a foreign withholding certificate covers Jan-Dec while the broker report covers Apr-Mar - different periods, both valid.
- Trust 26AS for TDS amounts. Where AIS and 26AS disagree on income (accrual vs credit timing), prefer the figure the portal will prefill (AIS) - a few hundred rupees of extra income is cheaper than a CPC mismatch notice.
- Check AIS asset classifications yourself - it mislabels holding periods and asset types (e.g. a listed commodity ETF held over a year tagged "Short term"). Classify by law, not by AIS.
- Write a working paper markdown in the docs folder: every income head, scrip-wise CG, quarterly breakups of dividends AND capital gains by advance-tax windows (up to 15/6, 16/6-15/9, 16/9-15/12, 16/12-15/3, 16/3-31/3 - the portal demands these in 234C accrual tables), FTC, expected tax and payable. Round everything to whole rupees now - the portal rejects decimals everywhere.
- Present the computation to the user before touching the portal.

## Phase 2 - Browser setup

- Launch a dedicated Chrome for Testing (headed) with `--remote-debugging-port` and a scratch `--user-data-dir`, as a background process. Connect from short-lived Playwright scripts via `connect_over_cdp` - shell state does not persist, so every script reconnects and picks the portal tab by URL.
- If connect fails with "Browser context management is not supported", the user's own Chrome has grabbed the port - relaunch on another port.
- Write ad-hoc recon-act-verify scripts per step; screenshot after every action. Do not build a reusable script library - the portal changes every year, so rediscover selectors each time.

## Phase 3 - Portal rules (hard-won; violating these loses the session)

Session:
- Never `page.reload()`, Back, or Forward - all three log you out. Navigate only via in-app clicks.
- ~15 min idle timeout ("Session Time" countdown in header). Any action resets it. Keep a re-login routine: goto login URL, PAN, checkbox, "Password" radio, password from file, Continue; a "Login Here" takeover appears if already logged in elsewhere - click it.
- Resume a draft via the dashboard resume button; a questionnaire page ("fo-proceed") may appear - "Skip Questions" goes straight to the schedule summary. Editing Part A-Gen or the schedule selection re-triggers this questionnaire.

Modals - the most dangerous part:
- ALWAYS read and print a modal's text before clicking anything in it. Never click the first visible button.
- The security popup ("securityReasonPopup") is inverted: "YES" logs you out, "No" continues.
- Info popups close with OK. Delete confirmations need "Yes".

Angular Material:
- No native `<select>` anywhere. Dropdowns are mat-select with ids like `<FieldBase>_select`; ids contain dots, so use CSS attribute selectors (`[id='Schedule.Foo.0.Bar_select']`), never bare `#id`.
- Open the mat-select, then click the mat-option by exact visible text. Dump all options first - option text often carries a numeric code prefix that must be matched in full (country is "2-UNITED STATES OF AMERICA", not "United States").
- The first mat-select on every page is the language dropdown - never click "the first select". A stray open overlay (cdk-overlay-backdrop) silently swallows clicks; press Escape to clear it.
- `text=` locators match hidden elements; prefer exact ids or unique visible description text.

Data entry:
- Discover fields by dumping all `input`/`mat-select` ids on the open form - ids are hierarchical, `<Schedule>.<Section>.<RowIndex>.<Field>` (e.g. `ScheduleCG.LongTermCapGain.0.FullConsideration`), and self-describing.
- Many sections exist as near-identical short-term and long-term twins with the same label text - Schedule CG has the same "assets other than unquoted shares" wording under both A (short-term) and B (long-term); disambiguate by the id prefix (`ShortTermCapGain` vs `LongTermCapGain`), not the label.
- After filling, press Tab to blur so Angular recomputes, read back the computed totals, verify against the working paper, THEN Save.
- Date inputs: check the placeholder (typically DD-MMM-YYYY).
- Opening a row by generic button text ("Edit", "Modify if required") often hits the wrong schedule - a row-filtered click meant for Schedule Salary can open Part A-Gen. Anchor on the schedule's unique description text (e.g. "Details of Income from Salary") or the button's id.

CSV uploads - avoid:
- Templates have no example row and reject on undocumented format rules ("csv_row_skip"); several attempts failed. Loop over the Add Another form instead - adding multiple rows by form is slower but deterministic. Schedule 112A accepts a single consolidated row (the portal's own convention: ISIN "INNOTREQUIRD", name "CONSOLIDATED", qty 0) - keep it, and use it as the convention for other schedules as well, consolidate wherever allowed.

Prefill:
- Verify prefilled schedules line by line; quality varies wildly - expect duplicate rows and zero-value balance columns. When prefill is junk, delete it all (select-all checkbox, Delete, "Yes") and refill from the broker report. Broker reports themselves can contain impossible values (dates outside the reporting period) - sanity-check against trade history and ask the user for anything unverifiable.
- Quarterly accrual tables (CG Table F, OS dividend table) must sum EXACTLY to the portal's own computed totals (post set-off, per BFLA), which differ by a rupee or two from your computation due to row-wise rounding - if the portal shows 3,40,563 and your working paper says 3,40,565, adjust a quarter by the difference and match the portal. Put loss set-offs in the latest quarter with gains (conservative for 234C).

Schedules:
- On the summary, "Modify if required" = confirmed, "Provide your confirmation" = pending. Confirm every schedule; auto-computed ones (CYLA/BFLA/CFL/SI/VI-A/AMTC) usually just need a "No" to "edit auto-populated?" plus Confirm - but verify their numbers first (SI is where the 112A exemption and special rates land).
- A nil schedule with mandatory fields cannot be confirmed empty - deselect it instead: summary -> Add More Schedules -> category tabs -> uncheck -> Continue -> Skip Questions.
- Part B-TTI asks the foreign-assets Yes/No - answer Yes iff Schedule FA is filled.

Judgment calls: use the user-question tool only for genuinely user-only facts (delete a prefilled schedule? actual account opening date?). Decide defensible tax judgments yourself and disclose them in the summary.

## Stop point

On Part B-TTI, verify the final computation against the working paper (tax, interest, TDS, payable/refund). Do NOT click Pay Now / Pay Later. Click Proceed To Verification once to surface validation errors - they arrive as a grid of field + description, typically prefill-blank dropdowns (nature of employer, 17(2)/17(3) nature rows, secondary-address question, malformed phone). Fix each, re-confirm the touched schedules, re-run Proceed To Verification until zero errors, then STOP. Hand the user: final figures, every judgment call made, and their remaining steps (pay self-assessment challan, submit, e-verify, delete the password file).
