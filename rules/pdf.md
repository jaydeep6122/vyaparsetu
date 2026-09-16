# PDF

## Rule
Bills are rendered on the phone by `lib/services/invoicePdfService.dart`. There
are exactly **two** layouts and no others: a classic tax invoice for GST bills
and a plain bill for non-GST ones. `BillDesign.forTaxMode(invoice.taxMode)`
picks between them — screens never choose a design.

## Service

| Method | Purpose |
|---|---|
| `generate({invoice, business, bankAccount})` | Returns the PDF as `Uint8List` |
| `share({bytes, fileName, message})` | Saves to a temp file and opens the share sheet (WhatsApp, email…) |
| `printBill(bytes, fileName)` | System print dialog |

`PdfPreviewScreen` (`screens/invoices/pdfPreview.dart`) shows the bytes with a
share action.

## Layouts

**GST classic** — bordered A4: header with logo, business address and GSTIN;
bill-to and bill meta boxes; ship-to and transport boxes when present; item
table with HSN, qty, rate, taxable and CGST+SGST (or a single IGST column when
`invoice.isInterState`); charges; totals; amount in words; bank details, terms
and signature.

**Non-GST simple** — the same information without any tax columns.

## Rules of the layout

- Every figure comes from the server (`taxableTotal`, `cgstTotal`, `lineTotal`,
  `roundOff`, …). The PDF never recalculates tax or totals.
- Fonts: Noto Sans through `PdfGoogleFonts`, falling back to Helvetica offline.
  Helvetica has no ₹ glyph, so amounts print as `Rs.` in that fallback.
- The bank block prints the business's default bank account, passed in by the
  caller; there is no bank data on the business itself.
- Logos and signatures are `data:image/...` URIs, decoded with
  `decodeImageDataUri`.

## DO
- Add new sections inside `InvoicePdfService`, not in screens
- Keep both layouts working when you change shared helpers
- Test with a walk-in bill (no party) and an inter-state bill

## DON'T
- Add a third design or per-user design settings
- Compute tax, totals or round-off in the PDF
- Call the backend's own `/invoices/:id/pdf` endpoint from the app — the phone
  builds the bill so it works offline
