# Web touch usability update

This desktop Web build remains non-responsive by design, but improves browser/touch usability without changing the desktop layout.

- Text buttons and OptionButtons on Web have a minimum height of 52 px and a minimum font size of 17 px.
- Existing large image-driven Move Cards keep their current dimensions.
- Battle Move Cards gain a Web-only `INFO` button. Tapping/clicking `INFO` opens a centered large-card preview with a Close button; tapping the Move Card itself still immediately uses the Move.
- Mouse hover preview remains available on desktop browsers.
- The INFO preview is sized from the current browser viewport so it can fit landscape browser windows more reliably.
