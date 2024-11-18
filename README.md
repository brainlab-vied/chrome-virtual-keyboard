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

Brainlab Fork
=========================================

## About the Brainlab fork
The Brainlab fork of this plugin adds patches to make it kiosk mode friendly.

## Additional sources
For automating the generation of the crx file, the [crx3.proto](./scripts/crx3.proto) file was added. This file originates from the [CRX3-Creator](https://github.com/pawliczka/CRX3-Creator) project and is distributed under the MIT License quoted in [LICENSE.crx3](./LICENSE.crx3). For more details please visit:

https://github.com/pawliczka/CRX3-Creator

## Version tagging
As this is a fork, but we also have to define version numbers, we introduce the following convention for Brainlab created versions:
~~~shell
major.minor.patch_blxx
~~~
Where:
- *major.minor.patch* refers to the version of the upstream project we are based upon
- *blxx* refers to "Brainlab version XX"

Example:
- 1.12.8_bl01

## CRX file generation
The crx generation is automated by scripts.

For local development - while using the Yocto SDK to provide the toolchain binaries - please execute the [generate.sh](./scripts/generate.sh) wrapper script.

For compiling the crx file from within yocto, please run [generate-crx.sh](./scripts/generate-crx.sh) while recreating the sysroot from the wrapper script via yocto.

### A word on signing keys
During creation the crx file must be signed. We use a disposable temp key file for this, as we are not planning to distribute this plugin publically. See [generate-crx.sh](./scripts/generate-crx.sh) for details.
