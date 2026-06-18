# PDF

## Rule
All invoice PDFs use JK's Classic design. PDF generation is only available for Sale invoices. No Purchase invoice PDFs.

## Service

`lib/services/invoicePdfService.dart` provides static methods:

| Method | Purpose |
|---|---|
| `generateInvoicePdf(invoice, business)` | Returns `pw.Document` with full JK's Classic layout |
| `sharePdf(doc, fileName)` | Shares via system share sheet |
| `printPdf(doc)` | Prints via system print dialog |

## Layout (JK's Classic)

The PDF is A4 format with these sections:

1. **Header** — Business name, logo, address, GSTIN, phone
2. **Invoice Header** — Invoice #, date, due date
3. **Bill To / Ship To** — Party name, address, GSTIN
4. **Items Table** — Columns: HSN, Description, Qty, Rate, CGST, SGST, Amount
5. **Footer** — Subtotal, discount, taxable amount, CGST/SGST totals, grand total (in words), bank details, signature, terms

### Implementation Notes

- Font: `PdfGoogleFonts.robotoRegular()` / `robotoBold()`
- A4 page format
- All monetary values in INR (₹)

## DO
- Call `InvoicePdfService.generateInvoicePdf()` from screens via `context.read<Core>()`
- Use JK's Classic layout only
- Generate PDFs for Sale invoices only

## DON'T
- Create alternative PDF layouts — JK's Classic is the only design
- Generate PDFs for Purchase invoices
- Use custom fonts other than Roboto (via PdfGoogleFonts)
- Build PDF content directly in screen files — always use `InvoicePdfService`
