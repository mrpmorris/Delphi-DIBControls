(********************************************************)
(*                                                      *)
(*      Object Modeler Class Library                    *)
(*                                                      *)
(*      Open Source Released 2000                       *)
(*      http://objectmodeler.com                        *)
(********************************************************)

unit DIBOpenTools;

interface
{$i ..\OpenSource\dfs.inc}

uses
  Classes, Forms, SysUtils, Windows, DIBPasParser, ToolsAPI, TypInfo;


{ AddClassUnit procedure }

procedure AddClassUnit(Form: TCustomForm; AClass: TClass);

  { AddUnit procedure }

procedure AddUnit(Form: TCustomForm; const UnitName: string);

  { GetFormModule procdure }

function GetFormModule(Form: TCustomForm): IOTAModule;

  { GetOpenToolInterfaces }

procedure GetOpenToolInterfaces(const Obj; Strings: TStrings);

  { Link unit to class }

procedure LinkUnitToClass(AComponent: TPersistent; AClass: TClass);

implementation

type
  THackPersistent = class(TPersistent);

  { Reading and writing routines }

function ReadBuffer(Editor: IOTASourceEditor; Position: Integer;
  Count: Integer): string;
var
  Reader: IOTAEditReader;
begin
  SetLength(Result, Count);
  FillChar(PChar(Result)^, Count, #0);
  Reader := Editor.CreateReader;
  {$IFDEF UNICODE}
    Reader.GetText(Position, PAnsiChar(Result), Count);
  {$ELSE}
    Reader.GetText(Position, PChar(Result), Count);
  {$ENDIF}
  SetLength(Result, StrLen(PChar(Result)));
end;

procedure WriteBuffer(Editor: IOTASourceEditor; StartPosition, EndPosition: Integer;
  const Text: string);
var
  Writer: IOTAEditWriter;
begin
  if Text = '' then Exit;
  Writer := Editor.CreateWriter;
  Writer.CopyTo(StartPosition);
  Writer.DeleteTo(EndPosition);
  {$IFDEF UNICODE}
    Writer.Insert(PAnsiChar(Text));
  {$ELSE}
    Writer.Insert(PChar(Text));
  {$ENDIF}
end;

{ Pascal scanning routines }

type
  TUsesPosition = record
    Column: Integer;
    StartPosition: Integer;
    EndPosition: Integer;
  end;

procedure GetLastUsesPosition(const Buffer: string;
  var UsesPosition: TUsesPosition);
begin
  with TPascalParser.Create(PChar(Buffer), Length(Buffer)) do
    try
      UsesPosition.Column := -1;
      UsesPosition.StartPosition := -1;
      UsesPosition.EndPosition := -1;
      if Scan([tkUses]) <> tkNull then
        repeat
          if Scan([tkIdentifier, tkSemicolon]) = tkIdentifier then
          begin
            UsesPosition.Column := Token.Col + Token.Length;
            UsesPosition.StartPosition := Token.Position + Token.Length;
          end
          else
            Break;
        until False;
      if (UsesPosition.Column > -1) and (Token.Kind = tkSemiColon) then
        UsesPosition.EndPosition := Token.Position;
    finally
      Free;
    end;
end;

procedure GetUsesStrings(const Buffer: string; Strings: TStrings;
  PreserveCase: Boolean = True);
begin
  Strings.Clear;
  Strings.BeginUpdate;
  with TPascalParser.Create(PChar(Buffer), Length(Buffer)) do
    try
      if Scan([tkUses]) <> tkNull then
        repeat
          if Scan([tkIdentifier, tkSemicolon]) = tkIdentifier then
            if PreserveCase then
              Strings.Add(Token.Text)
            else
              Strings.Add(UpperCase(Token.Text))
          else
            Break;
        until False;
    finally
      Free;
      Strings.EndUpdate;
    end;
end;

procedure AddClassUnit(Form: TCustomForm; AClass: TClass);
var
  TI: PTypeInfo;
  TD: PTypeData;
begin
  if AClass = nil then Exit;

  TI := AClass.ClassInfo;
  if TI = nil then Exit;

  TD := GetTypeData(TI);
  if TD = nil then Exit;
  AddUnit(Form, TD^.UnitName);
end;

procedure AddUnit(Form: TCustomForm; const UnitName: string);

  function UsesExists(const Buffer: string): Boolean;
  var
    Strings: TStrings;
  begin
    Strings := TStringList.Create;
    try
      GetUsesStrings(Buffer, Strings, False);
      Result := Strings.IndexOf(UpperCase(UnitName)) > -1;
    finally
      Strings.Free;
    end;;
  end;
var
  Module: IOTAModule;
  Editor: IOTASourceEditor;
  UsesPosition: TUsesPosition;
  S: string;
  I: Integer;
begin
  Module := GetFormModule(Form);
  if Module = nil then Exit;
  Editor := nil;
  for I := 0 to Module.GetModuleFileCount - 1 do
    if Supports(Module.GetModuleFileEditor(I), IOTASourceEditor, Editor) then
      Break;
  if Editor = nil then Exit;
  I := 10240;
  S := '';
  repeat
    S := ReadBuffer(Editor, 0, I);
    I := I div 2;
  until (S <> '') or (I < 255);
  GetLastUsesPosition(S, UsesPosition);
  if UsesExists(S) then Exit;
  with UsesPosition do
    if EndPosition > -1 then
    begin
      if Column + Length(', ' + UnitName) > 80 then
        WriteBuffer(Editor, StartPosition, EndPosition, ','#13#10'  ' +
          UnitName)
      else
        WriteBuffer(Editor, StartPosition, EndPosition, ', ' + UnitName);
    end;
end;

function GetFormModule(Form: TCustomForm): IOTAModule;
var
  ModuleServices: IOTAModuleServices;
  Project: IOTAProject;
  I: Integer;
begin
  ModuleServices := BorlandIDEServices as IOTAModuleServices;
  Project := nil;
  for I := 0 to ModuleServices.ModuleCount - 1 do
  begin
    Result := ModuleServices.Modules[I];
    if Supports(Result, IOTAProject, Project) then
      Break;
  end;
  Result := nil;
  if Project <> nil then
    for I := 0 to Project.GetModuleCount - 1 do
      if Project.GetModule(I).FormName = Form.Name then
      begin
        Result := Project.GetModule(I).OpenModule;
        Break;
      end;
end;

procedure LinkUnitToClass(AComponent: TPersistent; AClass: TClass);
begin
  while (AComponent <> nil) and not (AComponent is TCustomForm) do
    AComponent := THackPersistent(AComponent).GetOwner;

  if AComponent is TCustomForm then AddClassUnit(TCustomForm(AComponent), AClass);
end;


procedure GetOpenToolInterfaces(const Obj; Strings: TStrings);
var
  Unknown: IUnknown absolute Obj;
  Output: IUnknown;
begin
  Strings.BeginUpdate;
  try
    Strings.Clear;
    if Unknown.QueryInterface(IBorlandIDEServices, Output) = S_OK then
      Strings.Add('IBorlandIDEServices');
    if Unknown.QueryInterface(INTAComponent, Output) = S_OK then
      Strings.Add('INTAComponent');
    if Unknown.QueryInterface(INTACustomDrawMessage, Output) = S_OK then
      Strings.Add('INTACustomDrawMessage');
    if Unknown.QueryInterface(INTAEditWindow, Output) = S_OK then
      Strings.Add('INTAEditWindow');
    if Unknown.QueryInterface(INTAFormEditor, Output) = S_OK then
      Strings.Add('INTAFormEditor');
    if Unknown.QueryInterface(INTAServices, Output) = S_OK then
      Strings.Add('INTAServices');
    if Unknown.QueryInterface(INTAServices40, Output) = S_OK then
      Strings.Add('INTAServices40');
    if Unknown.QueryInterface(INTAToDoItem, Output) = S_OK then
      Strings.Add('INTAToDoItem');
    if Unknown.QueryInterface(IOTAActionServices, Output) = S_OK then
      Strings.Add('IOTAActionServices');
    if Unknown.QueryInterface(IOTAAddressBreakpoint, Output) = S_OK then
      Strings.Add('IOTAAddressBreakpoint');
    if Unknown.QueryInterface(IOTABreakpoint, Output) = S_OK then
      Strings.Add('IOTABreakpoint');
    if Unknown.QueryInterface(IOTABreakpoint40, Output) = S_OK then
      Strings.Add('IOTABreakpoint40');
    if Unknown.QueryInterface(IOTABreakpointNotifier, Output) = S_OK then
      Strings.Add('IOTABreakpointNotifier');
    if Unknown.QueryInterface(IOTABufferOptions, Output) = S_OK then
      Strings.Add('IOTABufferOptions');
    if Unknown.QueryInterface(IOTAComponent, Output) = S_OK then
      Strings.Add('IOTAComponent');
    if Unknown.QueryInterface(IOTACreator, Output) = S_OK then
      Strings.Add('IOTACreator');
    if Unknown.QueryInterface(IOTACustomMessage, Output) = S_OK then
      Strings.Add('IOTACustomMessage');
    if Unknown.QueryInterface(IOTACustomMessage50, Output) = S_OK then
      Strings.Add('IOTACustomMessage50');
    if Unknown.QueryInterface(IOTADebuggerNotifier, Output) = S_OK then
      Strings.Add('IOTADebuggerNotifier');
    if Unknown.QueryInterface(IOTADebuggerServices, Output) = S_OK then
      Strings.Add('IOTADebuggerServices');
    if Unknown.QueryInterface(IOTAEditActions, Output) = S_OK then
      Strings.Add('IOTAEditActions');
    if Unknown.QueryInterface(IOTAEditBlock, Output) = S_OK then
      Strings.Add('IOTAEditBlock');
    if Unknown.QueryInterface(IOTAEditBuffer, Output) = S_OK then
      Strings.Add('IOTAEditBuffer');
    if Unknown.QueryInterface(IOTAEditBufferIterator, Output) = S_OK then
      Strings.Add('IOTAEditBufferIterator');
    if Unknown.QueryInterface(IOTAEditLineNotifier, Output) = S_OK then
      Strings.Add('IOTAEditLineNotifier');
    if Unknown.QueryInterface(IOTAEditLineTracker, Output) = S_OK then
      Strings.Add('IOTAEditLineTracker');
    if Unknown.QueryInterface(IOTAEditOptions, Output) = S_OK then
      Strings.Add('IOTAEditOptions');
    if Unknown.QueryInterface(IOTAEditor, Output) = S_OK then
      Strings.Add('IOTAEditor');
    if Unknown.QueryInterface(IOTAEditorNotifier, Output) = S_OK then
      Strings.Add('IOTAEditorNotifier');
    if Unknown.QueryInterface(IOTAEditorServices, Output) = S_OK then
      Strings.Add('IOTAEditorServices');
    if Unknown.QueryInterface(IOTAEditPosition, Output) = S_OK then
      Strings.Add('IOTAEditPosition');
    if Unknown.QueryInterface(IOTAEditReader, Output) = S_OK then
      Strings.Add('IOTAEditReader');
    if Unknown.QueryInterface(IOTAEditView, Output) = S_OK then
      Strings.Add('IOTAEditView');
    if Unknown.QueryInterface(IOTAEditView40, Output) = S_OK then
      Strings.Add('IOTAEditView40');
    if Unknown.QueryInterface(IOTAEditWriter, Output) = S_OK then
      Strings.Add('IOTAEditWriter');
    if Unknown.QueryInterface(IOTAEnvironmentOptions, Output) = S_OK then
      Strings.Add('IOTAEnvironmentOptions');
    if Unknown.QueryInterface(IOTAFile, Output) = S_OK then
      Strings.Add('IOTAFile');
    if Unknown.QueryInterface(IOTAFileSystem, Output) = S_OK then
      Strings.Add('IOTAFileSystem');
    if Unknown.QueryInterface(IOTAFormEditor, Output) = S_OK then
      Strings.Add('IOTAFormEditor');
    if Unknown.QueryInterface(IOTAFormNotifier, Output) = S_OK then
      Strings.Add('IOTAFormNotifier');
    if Unknown.QueryInterface(IOTAFormWizard, Output) = S_OK then
      Strings.Add('IOTAFormWizard');
    if Unknown.QueryInterface(IOTAIDENotifier, Output) = S_OK then
      Strings.Add('IOTAIDENotifier');
    if Unknown.QueryInterface(IOTAIDENotifier50, Output) = S_OK then
      Strings.Add('IOTAIDENotifier50');
    if Unknown.QueryInterface(IOTAKeyBindingServices, Output) = S_OK then
      Strings.Add('IOTAKeyBindingServices');
    if Unknown.QueryInterface(IOTAKeyboardBinding, Output) = S_OK then
      Strings.Add('IOTAKeyboardBinding');
    if Unknown.QueryInterface(IOTAKeyboardDiagnostics, Output) = S_OK then
      Strings.Add('IOTAKeyboardDiagnostics');
    if Unknown.QueryInterface(IOTAKeyboardServices, Output) = S_OK then
      Strings.Add('IOTAKeyboardServices');
    if Unknown.QueryInterface(IOTAKeyContext, Output) = S_OK then
      Strings.Add('IOTAKeyContext');
    if Unknown.QueryInterface(IOTAMenuWizard, Output) = S_OK then
      Strings.Add('IOTAMenuWizard');
    if Unknown.QueryInterface(IOTAMessageServices, Output) = S_OK then
      Strings.Add('IOTAMessageServices');
    if Unknown.QueryInterface(IOTAMessageServices40, Output) = S_OK then
      Strings.Add('IOTAMessageServices40');
    if Unknown.QueryInterface(IOTAModule, Output) = S_OK then
      Strings.Add('IOTAModule');
    if Unknown.QueryInterface(IOTAModule40, Output) = S_OK then
      Strings.Add('IOTAModule40');
    if Unknown.QueryInterface(IOTAModuleCreator, Output) = S_OK then
      Strings.Add('IOTAModuleCreator');
    if Unknown.QueryInterface(IOTAModuleInfo, Output) = S_OK then
      Strings.Add('IOTAModuleInfo');
    if Unknown.QueryInterface(IOTAModuleNotifier, Output) = S_OK then
      Strings.Add('IOTAModuleNotifier');
    if Unknown.QueryInterface(IOTAModuleServices, Output) = S_OK then
      Strings.Add('IOTAModuleServices');
    if Unknown.QueryInterface(IOTANotifier, Output) = S_OK then
      Strings.Add('IOTANotifier');
    if Unknown.QueryInterface(IOTAOptions, Output) = S_OK then
      Strings.Add('IOTAOptions');
    if Unknown.QueryInterface(IOTAPackageServices, Output) = S_OK then
      Strings.Add('IOTAPackageServices');
    if Unknown.QueryInterface(IOTAProcess, Output) = S_OK then
      Strings.Add('IOTAProcess');
    if Unknown.QueryInterface(IOTAProcessModNotifier, Output) = S_OK then
      Strings.Add('IOTAProcessModNotifier');
    if Unknown.QueryInterface(IOTAProcessModule, Output) = S_OK then
      Strings.Add('IOTAProcessModule');
    if Unknown.QueryInterface(IOTAProcessNotifier, Output) = S_OK then
      Strings.Add('IOTAProcessNotifier');
    if Unknown.QueryInterface(IOTAProject, Output) = S_OK then
      Strings.Add('IOTAProject');
    if Unknown.QueryInterface(IOTAProject40, Output) = S_OK then
      Strings.Add('IOTAProject40');
    if Unknown.QueryInterface(IOTAProjectBuilder, Output) = S_OK then
      Strings.Add('IOTAProjectBuilder');
    if Unknown.QueryInterface(IOTAProjectBuilder40, Output) = S_OK then
      Strings.Add('IOTAProjectBuilder40');
    if Unknown.QueryInterface(IOTAProjectCreator, Output) = S_OK then
      Strings.Add('IOTAProjectCreator');
    if Unknown.QueryInterface(IOTAProjectCreator50, Output) = S_OK then
      Strings.Add('IOTAProjectCreator50');
    if Unknown.QueryInterface(IOTAProjectGroup, Output) = S_OK then
      Strings.Add('IOTAProjectGroup');
    if Unknown.QueryInterface(IOTAProjectGroupCreator, Output) = S_OK then
      Strings.Add('IOTAProjectGroupCreator');
    if Unknown.QueryInterface(IOTAProjectOptions, Output) = S_OK then
      Strings.Add('IOTAProjectOptions');
    if Unknown.QueryInterface(IOTAProjectOptions40, Output) = S_OK then
      Strings.Add('IOTAProjectOptions40');
    if Unknown.QueryInterface(IOTAProjectResource, Output) = S_OK then
      Strings.Add('IOTAProjectResource');
    if Unknown.QueryInterface(IOTAProjectWizard, Output) = S_OK then
      Strings.Add('IOTAProjectWizard');
    if Unknown.QueryInterface(IOTARecord, Output) = S_OK then
      Strings.Add('IOTARecord');
    if Unknown.QueryInterface(IOTAReplaceOptions, Output) = S_OK then
      Strings.Add('IOTAReplaceOptions');
    if Unknown.QueryInterface(IOTARepositoryWizard, Output) = S_OK then
      Strings.Add('IOTARepositoryWizard');
    if Unknown.QueryInterface(IOTAResourceEntry, Output) = S_OK then
      Strings.Add('IOTAResourceEntry');
    if Unknown.QueryInterface(IOTASearchOptions, Output) = S_OK then
      Strings.Add('IOTASearchOptions');
    if Unknown.QueryInterface(IOTAServices, Output) = S_OK then
      Strings.Add('IOTAServices');
    if Unknown.QueryInterface(IOTASourceBreakpoint, Output) = S_OK then
      Strings.Add('IOTASourceBreakpoint');
    if Unknown.QueryInterface(IOTASourceEditor, Output) = S_OK then
      Strings.Add('IOTASourceEditor');
    if Unknown.QueryInterface(IOTASpeedSetting, Output) = S_OK then
      Strings.Add('IOTASpeedSetting');
    if Unknown.QueryInterface(IOTAThread, Output) = S_OK then
      Strings.Add('IOTAThread');
    if Unknown.QueryInterface(IOTAThreadNotifier, Output) = S_OK then
      Strings.Add('IOTAThreadNotifier');
    if Unknown.QueryInterface(IOTAToDoManager, Output) = S_OK then
      Strings.Add('IOTAToDoManager');
    if Unknown.QueryInterface(IOTAToDoServices, Output) = S_OK then
      Strings.Add('IOTAToDoServices');
    if Unknown.QueryInterface(IOTATypeLibEditor, Output) = S_OK then
      Strings.Add('IOTATypeLibEditor');
    if Unknown.QueryInterface(IOTATypeLibModule, Output) = S_OK then
      Strings.Add('IOTATypeLibModule');
    if Unknown.QueryInterface(IOTAWizard, Output) = S_OK then
      Strings.Add('IOTAWizard');
    if Unknown.QueryInterface(IOTAWizardServices, Output) = S_OK then
      Strings.Add('IOTAWizardServices');
  finally
    Strings.EndUpdate;
  end;
end;

end.
