# DIBControls
Source code for some multimedia controls I wrote for Delphi a (very) long time ago


## Installation

(For BC++ installation see bottom of file)

This package requires at least Delphi 5, however, I am now only going to provide
packages for Delphi 7 and the latest Win32 version of Delphi.

Unzip the files with paths.
Add the main component path to your library path (MENU: Tools-Environment options)
In addition to the component path, you will need to add the following sub directories

.\OpenSource
.\PictureFormats
.\PictureFormats\PngImage

Install
DIBRuntime.dpk
DIBPNGSupport.dpk
DIBInstall.dpk

PS: I would love to see some demos etc !




## 3rd party files

  * http://objectmodeler.com
    * DIBPasParser.pas (originally PasParser.pas)
    * DIBOpenTools.pas (originally OpenTools.pas)
    * DIBStrConst.pas (Originally StrConst.pas)
  * Unknown
    * DIBLZH.pas  (Original turbo pascal author unknown, I converted to delphi abstract class)
  * http://pngdelphi.sourceforge.net/
    * .\PictureFormats\PngImage\*.*

## BC++ installation
Thanks to m.scholze@sh.cvut.cz for the following information

 * Do everything stated in the Delphi installation above.
 * C++ Builder5 menu Component|Install component.
 * Select Tab "Into new package"
 * Unit file name = DIBReg.pas
 * Package file name ... everything you want with .bpk extension
 * Before compiling & installing package do this:
    * in directory ToolsAPI compile dsgnintf.dcu (from cmdline : dcc32.exe dsgnintf.pas) and move it somewhere compiler can find it.
    *~~~~ in Project manager add to the Requirments files vclsmp50.bpi and vcljpg50.bpi

Now compile and install the package.
