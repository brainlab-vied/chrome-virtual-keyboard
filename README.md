Virtual Keyboard for Google Chrome&trade;
=========================================

## About
Virtual Keyboard for Google Chrome&trade; will popup automatically when the user clicks on an input field such as textboxes and textareas. Futhermore, the keyboard will disappear automatically once no longer needed.

This extension is ideal for touch screen devices. This keyboard works like an iOS/Android/Windows 8 touch virtual keyboard.

<img src="http://apps.xontab.com/content/VirtualKeyboard/1.png" alt="" />

For more details visit: http://apps.xontab.com/VirtualKeyboard/

## Known Limitations
Due to security reasons, communication between frames is restricted in Google Chrome.  The only way to enable the keyboard in cross-origin iFrame scenarios, you need to disable web security using a flags `--disable-web-security --disable-site-isolation-trials --user-data-dir=/tmp`. Warning, these flags make a Chrome browser very vulnerable.  

## Future versions

Planned features are:
* Better support with WebComponents, Angular 1, 2+ and React
* Add support to HTML ContentEditable
* More Keyboard layouts
* More developer options
* Refactoring and Documenation

You can also suggest new features: https://apps.xontab.com/Suggest/VirtualKeyboard/

## Key for signing

Since we modified the source code of the extension, we need a key to sign the new extension .crx. This command was used:

`openssl genrsa 2048 | openssl pkcs8 -topk8 -nocrypt -out chrome-virtual-keyboard.pem`

The resulting key can be found in scripts/chrome-virtual-keyboard.pem
