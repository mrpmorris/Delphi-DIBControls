unit DIBAnimContainerEditor;

{-----------------------------------------------------------------------------
The contents of this file are subject to the Mozilla Public License
Version 1.1 (the "License"); you may not use this file except in compliance
with the License. You may obtain a copy of the License at
http://www.mozilla.org/MPL/MPL-1.1.html

Software distributed under the License is distributed on an "AS IS" basis,
WITHOUT WARRANTY OF ANY KIND, either expressed or implied. See the License for
the specific language governing rights and limitations under the License.

The Original Code is: DIBAnimContainerEditor.PAS, released September 04, 2000.

The Initial Developer of the Original Code is Peter Morris (support@droopyeyes.com),
Portions created by Peter Morris are Copyright (C) 2000 Peter Morris.
All Rights Reserved.

Contributor(s):
None as yet


Last Modified: September 04, 2000

You may retrieve the latest version of this file from my home page
located at  http://www.droopyeyes.com


Known Issues: 
-----------------------------------------------------------------------------}

interface
{$i ..\OpenSource\dfs.inc}

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  {$IFDEF DFS_NO_DSGNINTF}
  DesignEditors, DesignIntf,
  {$ELSE}
  DsgnIntf,
  {$ENDIF}
  cDIBAnimContainer, StdCtrls;

type
  TfmSnapshotEditor = class(TForm)
    lbSnapshots: TListBox;
    btnRename: TButton;
    btnDelete: TButton;
    btnGoTo: TButton;
    btnUpdate: TButton;
    procedure btnRenameClick(Sender: TObject);
    procedure btnGoToClick(Sender: TObject);
    procedure btnDeleteClick(Sender: TObject);
    procedure btnUpdateClick(Sender: TObject);
  private
    { Private declarations }
    Snapshots: TDIBContainerSnapshots;
  public
    { Public declarations }
    procedure Edit(const ASnapShots: TDIBContainerSnapShots);
  end;

  TDIBAnimContainerEditor = class(TComponentEditor)
  public
    {$IFDEF DFS_NO_DSGNINTF}
    constructor Create(AComponent: TComponent; ADesigner: IDesigner); override;
    {$ELSE}
    constructor Create(AComponent: TComponent; ADesigner: IFormDesigner); override;
    {$ENDIF}
    procedure Edit; override;
    procedure ExecuteVerb(Index: Integer); override;
    function GetVerb(Index: Integer): string; override;
    function GetVerbCount: Integer; override;
  end;

implementation

{$i ..\OpenSource\dfs.inc}

{$R *.DFM}

uses
  DIBOpenTools;

{ TfmSnapshotEditor }

procedure TfmSnapshotEditor.Edit(const ASnapShots: TDIBContainerSnapShots);
var
  I: Integer;
begin
  SnapShots := ASnapShots;
  with lbSnapshots.Items do
  begin
    Clear;
    for I := 0 to SnapShots.Count - 1 do
      Add(SnapShots[I].DisplayName);
    if Count > 0 then lbSnapShots.ItemIndex := 0;
  end;
  ShowModal;
end;

procedure TfmSnapshotEditor.btnRenameClick(Sender: TObject);
var
  NewName: string;
begin
  with lbSnapShots do if ItemIndex >= 0 then
    begin
      NewName := InputBox('Enter new display name', 'Name', SnapShots[ItemIndex].DisplayName);
      SnapShots[ItemIndex].DisplayName := NewName;
      Items[ItemIndex] := NewName;
    end;
end;

procedure TfmSnapshotEditor.btnGoToClick(Sender: TObject);
begin
  with lbSnapShots do if ItemIndex >= 0 then
    begin
      SnapShots[ItemIndex].MorphTo(SnapShots[ItemIndex], 255, nil);
      Close;
    end;
end;

procedure TfmSnapshotEditor.btnDeleteClick(Sender: TObject);
begin
  with lbSnapShots do if ItemIndex >= 0 then
      if MessageDlg('Are you sure you want to delete this snapshot ?',
        mtConfirmation, [mbYes, mbNo], 0) = mrYes then
      begin
        SnapShots[ItemIndex].Free;
        Items.Delete(ItemIndex);
      end;
end;

{ TDIBAnimContainerEditor }

{$IFDEF DFS_NO_DSGNINTF}
constructor TDIBAnimContainerEditor.Create(AComponent: TComponent;
  ADesigner: IDesigner);
  {$ELSE}
  constructor TDIBAnimContainerEditor.Create(AComponent: TComponent;
    ADesigner: IFormDesigner);
    {$ENDIF}
  var
    I: Integer;
    Units: TStringList;
  begin
    inherited;
    Units := TStringList.Create;
    try
      cDIBAnimContainer.RequiredUnits(Units);
      for I := 0 to Units.Count - 1 do
        {$IFDEF DFS_NO_DSGNINTF}
        AddUnit(ADesigner.GetRoot as TCustomForm, Units[I]);
      {$ELSE}
      AddUnit(ADesigner.Form, Units[I]);
      {$ENDIF}
    finally
      Units.Free;
    end;
  end;

  procedure TDIBAnimContainerEditor.Edit;
  begin
    ExecuteVerb(1);
  end;

  procedure TDIBAnimContainerEditor.ExecuteVerb(Index: Integer);
  var
    NewName: string;
  begin
    case Index of
      0:
        begin
          NewName := InputBox('Enter snapshot name', 'Name', '');
          if NewName <> '' then
            with (Component as TCustomDIBAnimContainer).SnapShots.Add do
            begin
              DisplayName := NewName;
              MakeSnapShot;
            end;
        end;
      1:
        with TfmSnapshotEditor.Create(Application) do
          try
            Edit((Component as TCustomDIBAnimContainer).Snapshots);
            Self.Designer.Modified;
          finally
            Release;
          end;
    end;
  end;

  function TDIBAnimContainerEditor.GetVerb(Index: Integer): string;
  begin
    case Index of
      0: Result := 'Take snapshot';
      1: Result := 'Manage snapshots';
    end;
  end;

  function TDIBAnimContainerEditor.GetVerbCount: Integer;
  begin
    Result := 2;
  end;

  procedure TfmSnapshotEditor.btnUpdateClick(Sender: TObject);
  begin
    with lbSnapShots do if ItemIndex >= 0 then
        SnapShots[ItemIndex].MakeSnapShot;
  end;

  end.
