unit ce_toolseditor;

{$I ce_defines.inc}

interface

uses
  Classes, SysUtils, FileUtil, RTTIGrids, Forms, Controls, Graphics, Dialogs,
  ExtCtrls, Menus, Buttons, StdCtrls, ce_widget, ce_tools, ce_sharedres,
  ce_dsgncontrols;

type

  { TCEToolsEditorWidget }
  TCEToolsEditorWidget = class(TCEWidget)
    btnAddTool: TCEToolButton;
    btnClone: TCEToolButton;
    btnEdit: TCEToolButton;
    btnMoveDown: TCEToolButton;
    btnMoveUp: TCEToolButton;
    btnRemTool: TCEToolButton;
    btnRun: TCEToolButton;
    lstTools: TListBox;
    Panel2: TPanel;
    Splitter1: TSplitter;
    propsEd: TTIPropertyGrid;
    procedure BtnAddToolClick(Sender: TObject);
    procedure btnCloneClick(Sender: TObject);
    procedure btnEditClick(Sender: TObject);
    procedure btnRemToolClick(Sender: TObject);
    procedure btnMoveUpClick(Sender: TObject);
    procedure btnMoveDownClick(Sender: TObject);
    procedure btnRunClick(Sender: TObject);
    procedure lstToolsDblClick(Sender: TObject);
    procedure lstToolsSelectionChange(Sender: TObject; User: boolean);
    procedure propsEdModified(Sender: TObject; value: shortstring);
  private
    procedure setReadOnly(value: boolean);
    procedure executeSelectedTool;
    procedure clearInspector;
    procedure rebuildToolList;
    procedure updateToolList;
  public
    constructor create(aOwner: TComponent); override;
  end;

implementation
{$R *.lfm}

constructor TCEToolsEditorWidget.create(aOwner: TComponent);
begin
  inherited;
  propsEd.CheckboxForBoolean := true;
  propsEd.PropertyEditorHook.AddHandlerModified(@propsEdModified);
  rebuildToolList;
  setReadOnly(CustomTools.readOnly);
end;

procedure TCEToolsEditorWidget.clearInspector;
begin
  propsEd.TIObject := nil;
  propsEd.ItemIndex := -1;
end;

procedure TCEToolsEditorWidget.rebuildToolList;
var
  i: integer;
begin
  clearInspector;
  lstTools.Clear;

  for i := 0 to CustomTools.tools.Count-1 do
    lstTools.AddItem(CustomTools[i].toolAlias, nil);
  if lstTools.Count > 0 then
    lstTools.ItemIndex := 0;
  CustomTools.updateMenu;
end;

procedure TCEToolsEditorWidget.updateToolList;
var
  i: Integer;
begin
  for i := 0 to CustomTools.tools.Count-1 do
    lstTools.Items[i] := CustomTools[i].toolAlias;
  CustomTools.updateMenu;
end;

procedure TCEToolsEditorWidget.lstToolsSelectionChange(Sender: TObject;
  User: boolean);
begin
  if lstTools.ItemIndex = -1 then
    exit;
  propsEd.TIObject := CustomTools[lstTools.ItemIndex];
end;

procedure TCEToolsEditorWidget.propsEdModified(Sender: TObject; value: shortstring);
begin
  if propsEd.ItemIndex = -1 then
    exit;

  if (propsEd.Rows[propsEd.ItemIndex].Name = 'toolAlias')
  or (propsEd.Rows[propsEd.ItemIndex].Name = 'shortcut') then
    updateToolList;
end;

procedure TCEToolsEditorWidget.BtnAddToolClick(Sender: TObject);
begin
  CustomTools.addTool;
  rebuildToolList;
end;

procedure TCEToolsEditorWidget.btnCloneClick(Sender: TObject);
var
  itm: TCEToolItem;
begin
  if lstTools.ItemIndex = -1 then
    exit;

  itm := CustomTools.addTool;
  itm.Assign(CustomTools[lstTools.ItemIndex]);
  itm.toolAlias := itm.toolAlias + ' (copy)';
  rebuildToolList;
end;

procedure TCEToolsEditorWidget.setReadOnly(value: boolean);
begin
  if value then
  begin
    CustomTools.readOnly:= true;
    lstTools.Align:= alClient;
    PropsEd.Visible := false;
    Splitter1.Visible := false;
  end
  else
  begin
    CustomTools.readOnly:= false;
    lstTools.Align:= alLeft;
    PropsEd.Visible := true;
    Splitter1.Visible := true;
  end;
end;

procedure TCEToolsEditorWidget.btnEditClick(Sender: TObject);
begin
  setReadOnly(not CustomTools.readOnly);
end;

procedure TCEToolsEditorWidget.btnRemToolClick(Sender: TObject);
begin
  if lstTools.ItemIndex = -1 then
    exit;

  clearInspector;
  CustomTools.tools.Delete(lstTools.ItemIndex);
  rebuildToolList;
end;

procedure TCEToolsEditorWidget.btnMoveUpClick(Sender: TObject);
begin
  if lstTools.ItemIndex < 1 then
    exit;

  CustomTools.tools.Exchange(lstTools.ItemIndex, lstTools.ItemIndex - 1);
  lstTools.ItemIndex := lstTools.ItemIndex - 1;
  updateToolList;
end;

procedure TCEToolsEditorWidget.btnMoveDownClick(Sender: TObject);
begin
  if (lstTools.ItemIndex = -1) or (lstTools.ItemIndex = lstTools.Items.Count-1) then
    exit;

  CustomTools.tools.Exchange(lstTools.ItemIndex, lstTools.ItemIndex + 1);
  lstTools.ItemIndex := lstTools.ItemIndex + 1;
  updateToolList;
end;

procedure TCEToolsEditorWidget.executeSelectedTool;
begin
  if lstTools.ItemIndex = -1 then
    exit;

  CustomTools.executeTool(lstTools.ItemIndex);
end;

procedure TCEToolsEditorWidget.btnRunClick(Sender: TObject);
begin
  executeSelectedTool;
end;

procedure TCEToolsEditorWidget.lstToolsDblClick(Sender: TObject);
begin
  executeSelectedTool;
end;

end.

