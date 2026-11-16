// Draws the icon of the Claude Multi Desktop app and of the account-handoff plugin: two overlapping rounded squares
// with a white symbol. Our own artwork; nothing from Anthropic. Usage: osascript -l JavaScript draw-icon.js OUT.png SYMBOL
ObjC.import('AppKit');
function run(argv) {
  const out = argv[0], symbol = argv[1] || '+', size = 1024;
  const rgb = (n) => $.NSColor.colorWithSRGBRedGreenBlueAlpha(((n >> 16) & 255) / 255, ((n >> 8) & 255) / 255, (n & 255) / 255, 1);
  const rep = $.NSBitmapImageRep.alloc.initWithBitmapDataPlanesPixelsWidePixelsHighBitsPerSampleSamplesPerPixelHasAlphaIsPlanarColorSpaceNameBytesPerRowBitsPerPixel(
    null, size, size, 8, 4, true, false, $.NSDeviceRGBColorSpace, 0, 0);
  $.NSGraphicsContext.saveGraphicsState;
  $.NSGraphicsContext.setCurrentContext($.NSGraphicsContext.graphicsContextWithBitmapImageRep(rep));
  const square = (x, y, s, r) => $.NSBezierPath.bezierPathWithRoundedRectXRadiusYRadius($.NSMakeRect(x, y, s, s), r, r);
  rgb(0x3B6FD8).setFill; square(110, 354, 560, 128).fill;
  $.NSColor.whiteColor.setFill; square(330, 126, 600, 148).fill;
  rgb(0x2E9D6A).setFill; square(354, 150, 552, 128).fill;
  const attrs = $.NSMutableDictionary.dictionary;
  attrs.setObjectForKey($.NSFont.boldSystemFontOfSize(380), $('NSFont'));
  attrs.setObjectForKey($.NSColor.whiteColor, $('NSColor'));
  const s = $.NSString.alloc.initWithString(symbol), sz = s.sizeWithAttributes(attrs);
  s.drawAtPointWithAttributes($.NSMakePoint(630 - sz.width / 2, 426 - sz.height / 2), attrs);
  $.NSGraphicsContext.restoreGraphicsState;
  rep.representationUsingTypeProperties(4, $()).writeToFileAtomically(out, true);
}
