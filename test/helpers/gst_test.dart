import 'package:flutter_test/flutter_test.dart';
import 'package:vyaparsetu/helpers/gst.dart';

void main() {
  group('stateCodeFromGstin', () {
    test('reads the leading two digits', () {
      expect(stateCodeFromGstin('24AAACC1206D1ZM'), '24'); // Gujarat
      expect(stateCodeFromGstin('27AAPFU0939F1ZV'), '27'); // Maharashtra
      expect(stateCodeFromGstin('07AAACA1234A1Z5'), '07'); // Delhi
    });

    test('tolerates surrounding whitespace', () {
      expect(stateCodeFromGstin('  24AAACC1206D1ZM '), '24');
    });

    test('returns null for anything that is not a state code', () {
      expect(stateCodeFromGstin(null), isNull);
      expect(stateCodeFromGstin(''), isNull);
      expect(stateCodeFromGstin('X'), isNull);
      expect(stateCodeFromGstin('ABAACC1206D1ZM'), isNull);
      expect(stateCodeFromGstin('99AAACC1206D1ZM'), isNull); // unassigned
    });
  });

  group('stateCodeFromName', () {
    test('matches canonical names regardless of case or spacing', () {
      expect(stateCodeFromName('Gujarat'), '24');
      expect(stateCodeFromName('  gujarat  '), '24');
      expect(stateCodeFromName('MAHARASHTRA'), '27');
    });

    test('handles ampersands and punctuation', () {
      expect(stateCodeFromName('Jammu & Kashmir'), '01');
      expect(stateCodeFromName('Andaman & Nicobar Islands'), '35');
    });

    test('handles common alternate spellings', () {
      expect(stateCodeFromName('Orissa'), stateCodeFromName('Odisha'));
      expect(stateCodeFromName('Pondicherry'), '34');
      expect(stateCodeFromName('Tamilnadu'), '33');
      expect(stateCodeFromName('New Delhi'), '07');
    });

    test('returns null for unknown or empty input', () {
      expect(stateCodeFromName(null), isNull);
      expect(stateCodeFromName('   '), isNull);
      expect(stateCodeFromName('Atlantis'), isNull);
    });
  });

  group('resolveStateCode', () {
    test('prefers the GSTIN over the typed state name', () {
      // GSTIN says Maharashtra, free text says Gujarat - GSTIN wins.
      expect(
        resolveStateCode(gstin: '27AAPFU0939F1ZV', stateName: 'Gujarat'),
        '27',
      );
    });

    test('falls back to the name when there is no usable GSTIN', () {
      expect(resolveStateCode(gstin: null, stateName: 'Gujarat'), '24');
      expect(resolveStateCode(gstin: 'garbage', stateName: 'Gujarat'), '24');
    });

    test('is null when neither side is usable', () {
      expect(resolveStateCode(gstin: null, stateName: null), isNull);
    });
  });

  group('isInterStateSupply', () {
    test('same state is intra-state', () {
      expect(isInterStateSupply(sellerCode: '24', buyerCode: '24'), isFalse);
    });

    test('different states is inter-state', () {
      expect(isInterStateSupply(sellerCode: '24', buyerCode: '27'), isTrue);
    });

    test('an unknown side keeps the existing intra-state behaviour', () {
      // Parties recorded before the state field existed must not silently
      // flip to IGST.
      expect(isInterStateSupply(sellerCode: '24', buyerCode: null), isFalse);
      expect(isInterStateSupply(sellerCode: null, buyerCode: '27'), isFalse);
      expect(isInterStateSupply(sellerCode: null, buyerCode: null), isFalse);
    });
  });

  group('GstSplit', () {
    test('intra-state splits into equal CGST and SGST halves', () {
      final split = GstSplit.amounts(
        isInterState: false,
        subTotal: 1000,
        taxAmount: 180,
      );
      expect(split.rate, closeTo(18, 0.0001));
      expect(split.cgstRate, closeTo(9, 0.0001));
      expect(split.sgstRate, closeTo(9, 0.0001));
      expect(split.cgstAmount, closeTo(90, 0.0001));
      expect(split.sgstAmount, closeTo(90, 0.0001));
      expect(split.igstRate, 0);
      expect(split.igstAmount, 0);
    });

    test('inter-state is a single IGST line at the full rate', () {
      final split = GstSplit.amounts(
        isInterState: true,
        subTotal: 1000,
        taxAmount: 180,
      );
      expect(split.igstRate, closeTo(18, 0.0001));
      expect(split.igstAmount, closeTo(180, 0.0001));
      expect(split.cgstRate, 0);
      expect(split.sgstRate, 0);
      expect(split.cgstAmount, 0);
      expect(split.sgstAmount, 0);
    });

    test('the parts always add back up to the total', () {
      for (final interState in [true, false]) {
        final split = GstSplit.amounts(
          isInterState: interState,
          subTotal: 1234.56,
          taxAmount: 222.22,
        );
        expect(
          split.cgstAmount + split.sgstAmount + split.igstAmount,
          closeTo(222.22, 0.0001),
        );
      }
    });

    test('a zero subtotal or zero tax yields a zero rate, not NaN', () {
      final noSub = GstSplit.amounts(
        isInterState: false,
        subTotal: 0,
        taxAmount: 100,
      );
      expect(noSub.rate, 0);
      expect(noSub.rate.isNaN, isFalse);

      final noTax = GstSplit.amounts(
        isInterState: false,
        subTotal: 1000,
        taxAmount: 0,
      );
      expect(noTax.rate, 0);
      expect(noTax.cgstAmount, 0);
    });

    test('ofRate splits a per-line rate the same way', () {
      final intra = GstSplit.ofRate(isInterState: false, rate: 12);
      expect(intra.cgstRate, closeTo(6, 0.0001));
      expect(intra.sgstRate, closeTo(6, 0.0001));
      expect(intra.igstRate, 0);

      final inter = GstSplit.ofRate(isInterState: true, rate: 12);
      expect(inter.igstRate, closeTo(12, 0.0001));
      expect(inter.cgstRate, 0);
    });
  });

  group('stateNameFromCode', () {
    test('maps back to a printable name', () {
      expect(stateNameFromCode('24'), 'Gujarat');
      expect(stateNameFromCode('27'), 'Maharashtra');
    });

    test('returns null for unknown codes', () {
      expect(stateNameFromCode(null), isNull);
      expect(stateNameFromCode('99'), isNull);
    });
  });
}
