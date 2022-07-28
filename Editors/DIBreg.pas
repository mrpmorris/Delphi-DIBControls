unit DIBreg;

interface

uses
  Classes;

procedure Register;

implementation

uses
  TypInfo,
  cDIB, cDIBPanel, cDIBImageList,
  cDIBAnimMgr, cDIBButton, cDIBCompressor, cDIBControl, cDIBDial,
  cDIBFadeLabel, cDIBFeatures, cDIBFormShaper, cDIBImage,
  cDIBMagnifier, cDIBPalette, cDIBSettings, cDIBSlider, cDIBWavList,
  cDIBStandardCompressors, cDIBStandardFilters, cDIBTimer,
  cDIBAnimContainer, cDIBEdit, cDIBBorder, cDIBGlyphButton, cDIBKnob;


procedure Register;
begin
  RegisterNoIcon([TDIBAnimation]);
  RegisterComponents('DIB',
    [TDIBContainer,
    TDIBImageContainer,
    TDIBAnimContainer,
    TDIBImageAnimContainer,
    TDIBImageList,
    TDIBImage,
    TDIBAnimManager,
    TDIBButton,
    TDIBDial,
    TDIBFadeLabel,
    TDIBFormShaper,
    TDIBMagnifier,
    TDIBPalette,
    TDIBSettings,
    TDIBSlider,
    TDIBTimer,
    TDIBWavList,
    TDIBEdit,
    TDIBBorder,
    TDIBGlyphButton,
    TDIBKnob
    ]);

end;

end.
