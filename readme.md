# ImageTrimmer
Image trimming tool for Machine Learning.

For trimming numerous, fixed size images from one image.

Xcode11 beta / Swift5.0 / OSX

Currently, it's specialized for binary classification.

## Usage

### Common
![Main Window](./Resources/main.png)

1. Drag and drop image onto the upper box.
1. Set output directories and file numbers to start from.
1. Set trim width and height.

### Trim manually
1. [Common](#common)
1. Set x and y(Input value, or just click image).
1. Trimming preview will be shown on the right box.
1. Press "Trim(P)" or "Trim(N)" button to trim and save positive/negative image.

Can zoom, scroll.

### Trim randomly
![Random trimming](./Resources/random.png)

1. [Common](#common)
1. Press "Random" button, then new window will open.
1. Randomly trimmed image will be shown, Press "Positive"/"Negative" button to save image.

## License
[MIT License](./LICENSE)
