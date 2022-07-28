unit DIBEditorsReg;

interface

uses
  Classes;

procedure Register;

implementation

{$I ..\OpenSource\dfs.inc}

uses
  {$IFDEF DFS_NO_DSGNINTF}
  DesignEditors, DesignIntf,
  {$ELSE}
  DsgnIntf,
  {$ENDIF}
  TypInfo,
  cDIB, cDIBPanel, cDIBImageList,
  cDIBAnimMgr, cDIBButton, cDIBCompressor, cDIBControl, cDIBDial,
  cDIBFadeLabel, cDIBFeatures, cDIBFormShaper, cDIBImage, 
  cDIBMagnifier, cDIBPalette, cDIBSettings, cDIBSlider, cDIBWavList,
  cDIBStandardCompressors, cDIBStandardFilters, cDIBTimer,
  cDIBAnimContainer,
  DIBAnimEditor, DIBCompressorEditor, DIBControlEditor, DIBEditor,
  DIBFeatureEditor, DIBImageIndexEditor,
  DIBAnimContainerEditor, DIBWavEditor, DIBPaletteEditor, cDIBEdit,
  cDIBBorder, DIBCommon, DIBCommonEditors;


procedure Register;
begin
  //DIBAnimEditor
  RegisterPropertyEditor(TDIBAnimMgrList.ClassInfo, TDIBAnimManager,
    '', TDIBAnimMgrListProperty);
  RegisterPropertyEditor(TDIBFrameList.ClassInfo, TDIBAnimation, '', TDIBFrameListProperty);

  //DIBCompressorEditor
  RegisterPropertyEditor(TypeInfo(String), TDIBSettings, 'DIBCompressor',
    TDIBCompressorProperty);

  //DIBControlEditor
  RegisterComponentEditor(TCustomDIBControl, TDIBControlEditor);

  //DIBAnimContainerEditor
  RegisterComponentEditor(TCustomDIBAnimContainer, TDIBAnimContainerEditor);

  //DIBEditor
  RegisterPropertyEditor(TypeInfo(TAbstractSuperDIB), nil, '', TAbstractSuperDIBProperty);

  //DIBFeatureEditor
  RegisterPropertyEditor(TypeInfo(String), TDIBFeatureItem,
    'FeatureClassName', TFeatureClassProperty);
  RegisterPropertyEditor(TypeInfo(String), TDIBFeatureItem,
    'FeatureParameters', TFeatureParametersProperty);

  //DIBImageIndexEditor
  RegisterPropertyEditor(TypeInfo(TDIBImageLink), nil, '', TDIBImageIndexProperty);

  //DIBWav.DisplayName editor
  RegisterPropertyEditor(TypeInfo(String), TDIBWav, 'DisplayName', TDIBWavProperty);

  //DIBPalette editor
  RegisterComponentEditor(TDIBPalette, TDIBPaletteEditor);
end;

end.
