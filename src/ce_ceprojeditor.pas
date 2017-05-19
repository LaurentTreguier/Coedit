unit ce_ceprojeditor;

{$I ce_defines.inc}

interface

uses
  Classes, SysUtils, FileUtil, RTTIGrids, RTTICtrls, Forms, Controls, Graphics,
  Dialogs, ExtCtrls, ComCtrls, StdCtrls, Menus, Buttons, rttiutils, typinfo,
  PropEdits, ObjectInspector, ce_dmdwrap, ce_ceproject, ce_widget,
  ce_interfaces, ce_observer, ce_sharedres, ce_common, ce_dsgncontrols;

type

  { TCEProjectConfigurationWidget }

  TCEProjectConfigurationWidget = class(TCEWidget, ICEProjectObserver)
    btnAddConf: TCEToolButton;
    btnCloneConf: TCEToolButton;
    btnDelConf: TCEToolButton;
    btnSyncEdit: TCEToolButton;
    imgList: TImageList;
    Panel2: TPanel;
    selConf: TComboBox;
    Splitter1: TSplitter;
    inspector: TTIPropertyGrid;
    Tree: TTreeView;
    procedure btnAddConfClick(Sender: TObject);
    procedure btnDelConfClick(Sender: TObject);
    procedure btnCloneCurrClick(Sender: TObject);
    procedure btnSyncEditClick(Sender: TObject);
    procedure inspectorModified(Sender: TObject);
    procedure inspectorModified2(Sender: TObject; PropName: ShortString);
    procedure selConfChange(Sender: TObject);
    procedure TreeChange(Sender: TObject; Node: TTreeNode);
    procedure GridFilter(Sender: TObject; aEditor: TPropertyEditor;var aShow: boolean);
  private
    fProj: TCENativeProject;
    fSyncroMode: boolean;
    fSynchroItem: TStringList;
    fSynchroValue: TStringList;
    function getGridTarget: TPersistent;
    procedure setSyncroMode(value: boolean);
    function syncroSetPropAsString(const section, Item, def: string): string;
    procedure syncroGetPropAsString(const section, Item, value: string);
    property syncroMode: boolean read fSyncroMode write setSyncroMode;
    //
    procedure projNew(project: ICECommonProject);
    procedure projClosing(project: ICECommonProject);
    procedure projChanged(project: ICECommonProject);
    procedure projFocused(project: ICECommonProject);
    procedure projCompiling(project: ICECommonProject);
    procedure projCompiled(project: ICECommonProject; success: boolean);
  protected
    procedure updateImperative; override;
    procedure SetVisible(value: boolean); override;
  public
    constructor create(aOwner: TComponent); override;
    destructor destroy; override;
  end;

implementation
{$R *.lfm}

{$REGION Standard Comp/Obj------------------------------------------------------}
constructor TCEProjectConfigurationWidget.create(aOwner: TComponent);
begin
  inherited;
  //
  fSynchroItem := TStringList.Create;
  fSynchroValue := TStringList.Create;
  Tree.Selected := Tree.Items.GetLastNode;
  inspector.OnEditorFilter := @GridFilter;
  inspector.CheckboxForBoolean := true;
  inspector.PropertyEditorHook.AddHandlerModified(@inspectorModified2);
  //
  EntitiesConnector.addObserver(self);
end;

destructor TCEProjectConfigurationWidget.destroy;
begin
  fSynchroItem.Free;
  fSynchroValue.Free;
  EntitiesConnector.removeObserver(self);
  inherited;
end;

procedure TCEProjectConfigurationWidget.SetVisible(value: boolean);
begin
  inherited;
  if Visible then updateImperative;
end;
{$ENDREGION --------------------------------------------------------------------}

{$REGION ICEProjectObserver ----------------------------------------------------}
procedure TCEProjectConfigurationWidget.projNew(project: ICECommonProject);
begin
  fProj := nil;
  enabled := false;
  if project.getFormat <> pfCE then
    exit;
  enabled := true;
  //
  fProj := TCENativeProject(project.getProject);
  if Visible then updateImperative;
  syncroMode := false;
end;

procedure TCEProjectConfigurationWidget.projClosing(project: ICECommonProject);
begin
  if fProj.isNil then exit;
  if fProj <> project.getProject then
    exit;
  inspector.TIObject := nil;
  inspector.ItemIndex := -1;
  selConf.Clear;
  syncroMode := false;
  enabled := false;
  fProj := nil;
end;

procedure TCEProjectConfigurationWidget.projChanged(project: ICECommonProject);
begin
  if fProj.isNil then exit;
  if fProj <> project.getProject then
    exit;
  if Visible then updateImperative;
end;

procedure TCEProjectConfigurationWidget.projFocused(project: ICECommonProject);
begin
  fProj := nil;
  enabled := false;
  if project.getFormat <> pfCE then
    exit;
  enabled := true;
  //
  fProj := TCENativeProject(project.getProject);
  if Visible then updateImperative;
end;

procedure TCEProjectConfigurationWidget.projCompiling(project: ICECommonProject);
begin
end;

procedure TCEProjectConfigurationWidget.projCompiled(project: ICECommonProject; success: boolean);
begin
end;
{$ENDREGION --------------------------------------------------------------------}

{$REGION config. things --------------------------------------------------------}
procedure TCEProjectConfigurationWidget.selConfChange(Sender: TObject);
begin
  if fProj.isNil then exit;
  if Updating then exit;
  if selConf.ItemIndex = -1 then exit;
  //
  beginImperativeUpdate;
  fProj.ConfigurationIndex := selConf.ItemIndex;
  endImperativeUpdate;
end;

procedure TCEProjectConfigurationWidget.TreeChange(Sender: TObject;
  Node: TTreeNode);
begin
  inspector.TIObject := getGridTarget;
  selconf.Enabled := (inspector.TIObject <> fProj) and fProj.isNotNil;
end;

procedure TCEProjectConfigurationWidget.setSyncroMode(value: boolean);
begin
  if fSyncroMode = value then
    exit;
  fSyncroMode := value;
  if fSyncroMode then
    btnSyncEdit.resourceName := 'LINK'
  else
    btnSyncEdit.resourceName := 'LINK_BREAK';
end;

function TCEProjectConfigurationWidget.syncroSetPropAsString(const section, Item, def: string): string;
var
  i: Integer;
begin
  i := fSynchroItem.IndexOf(Item);
  if i = -1 then exit('');
  result := fSynchroValue[i];
end;

procedure TCEProjectConfigurationWidget.syncroGetPropAsString(const section, Item, value: string);
begin
  fSynchroItem.Add(Item);
  fSynchroValue.Add(value);
end;

procedure TCEProjectConfigurationWidget.inspectorModified2(Sender: TObject; PropName: ShortString);
begin
  inspectorModified(sender);
end;

procedure TCEProjectConfigurationWidget.inspectorModified(Sender: TObject);
var
  propstr: string;
  src_list, trg_list: rttiutils.TPropInfoList;
  src_prop, trg_prop: PPropInfo;
  storage: rttiutils.TPropsStorage;
  trg_obj: TPersistent;
  i: Integer;
begin
  if fProj.isNil then exit;
  if not fSyncroMode then exit;
  if inspector.TIObject.isNil then exit;
  if inspector.ItemIndex = -1 then exit;
  //
  storage := nil;
  src_prop:= nil;
  trg_prop:= nil;
  trg_obj := nil;
  propstr := inspector.PropertyPath(inspector.ItemIndex);
  storage := rttiutils.TPropsStorage.Create;
  storage.OnReadString := @syncroSetPropAsString;
  storage.OnWriteString := @syncroGetPropAsString;
  src_list:= rttiutils.TPropInfoList.Create(getGridTarget, tkAny);
  fProj.beginUpdate;
  try
    src_prop := src_list.Find(propstr);
    if src_prop = nil then exit;
    storage.AObject := getGridTarget;
    storage.StoreAnyProperty(src_prop);
    for i:= 0 to fProj.OptionsCollection.Count-1 do
    begin
      // skip current config
      if i = fProj.ConfigurationIndex then continue;
      // find target persistent
      if inspector.TIObject = fProj.currentConfiguration.messagesOptions then
        trg_obj := fProj.configuration[i].messagesOptions else
      if inspector.TIObject = fProj.currentConfiguration.debugingOptions then
        trg_obj := fProj.configuration[i].debugingOptions else
      if inspector.TIObject = fProj.currentConfiguration.documentationOptions then
        trg_obj := fProj.configuration[i].documentationOptions else
      if inspector.TIObject = fProj.currentConfiguration.outputOptions then
        trg_obj := fProj.configuration[i].outputOptions else
      if inspector.TIObject = fProj.currentConfiguration.otherOptions then
        trg_obj := fProj.configuration[i].otherOptions else
      if inspector.TIObject = fProj.currentConfiguration.pathsOptions then
         trg_obj := fProj.configuration[i].pathsOptions else
      if inspector.TIObject = fProj.currentConfiguration.preBuildProcess then
        trg_obj := fProj.configuration[i].preBuildProcess else
      if inspector.TIObject = fProj.currentConfiguration.postBuildProcess then
        trg_obj := fProj.configuration[i].postBuildProcess else
      if inspector.TIObject = fProj.currentConfiguration.runOptions then
         trg_obj := fProj.configuration[i].runOptions
      else continue;
      // find target property
      storage.AObject := trg_obj;
      trg_list := rttiutils.TPropInfoList.Create(trg_obj, tkAny);
      try
        trg_prop := trg_list.Find(propstr);
        if trg_prop <> nil then
          storage.LoadAnyProperty(trg_prop);
      finally
        trg_list.Free;
        trg_prop := nil;
      end;
    end;
  finally
    storage.free;
    src_list.free;
    fProj.endUpdate;
    fSynchroItem.Clear;
    fSynchroValue.Clear;
  end;
end;

procedure TCEProjectConfigurationWidget.btnAddConfClick(Sender: TObject);
var
  nme: string;
  cfg: TCompilerConfiguration;
begin
  if fProj.isNil then exit;
  //
  nme := '';
  beginImperativeUpdate;
  cfg := fProj.addConfiguration;
  // note: Cancel is actually related to the conf. name not to the add operation.
  if InputQuery('Configuration name', '', nme) then cfg.name := nme;
  fProj.ConfigurationIndex := cfg.Index;
  endImperativeUpdate;
end;

procedure TCEProjectConfigurationWidget.btnDelConfClick(Sender: TObject);
begin
  if fProj.isNil then exit;
  if fProj.OptionsCollection.Count = 1 then exit;
  //
  beginImperativeUpdate;
  inspector.TIObject := nil;
  inspector.Clear;
  Invalidate;
  fProj.OptionsCollection.Delete(selConf.ItemIndex);
  fProj.ConfigurationIndex := 0;
  endImperativeUpdate;
end;

procedure TCEProjectConfigurationWidget.btnCloneCurrClick(Sender: TObject);
var
  nme: string;
  trg, src: TCompilerConfiguration;
begin
  if fProj.isNil then exit;
  //
  nme := '';
  beginImperativeUpdate;
  fProj.beginUpdate;
  src := fProj.currentConfiguration;
  trg := fProj.addConfiguration;
  trg.assign(src);
  if InputQuery('Configuration name', '', nme) then trg.name := nme;
  fProj.ConfigurationIndex := trg.Index;
  fProj.endUpdate;
  endImperativeUpdate;
end;

procedure TCEProjectConfigurationWidget.btnSyncEditClick(Sender: TObject);
begin
  fSynchroValue.Clear;
  fSynchroItem.Clear;
  if fProj.isNil then exit;
  syncroMode := not syncroMode;
end;

procedure TCEProjectConfigurationWidget.GridFilter(Sender: TObject; aEditor: TPropertyEditor;
  var aShow: boolean);
begin
  if fProj.isNil then exit;

  // filter TComponent things.
  if getGridTarget = fProj then
  begin
    if aEditor.GetName = 'Name' then
      aShow := false
    else if aEditor.GetName = 'Tag' then
      aShow := false
    else  if aEditor.ClassType = TCollectionPropertyEditor then
      aShow := false;
  end;
  // deprecated field
  if getGridTarget = fProj.currentConfiguration.pathsOptions  then
  begin
    if aEditor.GetName = 'Sources' then
      aShow := false
    else if aEditor.GetName = 'includes' then
      aShow := false
    else if aEditor.GetName = 'imports' then
      aShow := false;
  end;
  if getGridTarget = fProj.currentConfiguration.outputOptions  then
  begin
    if aEditor.GetName = 'noBoundsCheck' then
      aShow := false
    else if aEditor.GetName = 'generateAllTmpCode' then
      aShow := false;
  end;
  if getGridTarget = fProj.currentConfiguration.debugingOptions then
  begin
    if aEditor.GetName = 'addCInformations' then
      aShow := false
    else if aEditor.GetName = 'addDInformations' then
      aShow := false;
  end;
  if getGridTarget = fProj.currentConfiguration.messagesOptions then
    if aEditor.GetName = 'additionalWarnings' then
      aShow := false;
end;

function TCEProjectConfigurationWidget.getGridTarget: TPersistent;
begin
  if fProj.isNil then exit(nil);
  if fProj.ConfigurationIndex = -1 then exit(nil);
  if Tree.Selected.isNil then exit(nil);
  // Warning: TTreeNode.StateIndex is usually made for the images...it's not a tag
  case Tree.Selected.StateIndex of
    1: exit( fProj );
    2: exit( fProj.currentConfiguration.messagesOptions );
    3: exit( fProj.currentConfiguration.debugingOptions );
    4: exit( fProj.currentConfiguration.documentationOptions );
    5: exit( fProj.currentConfiguration.outputOptions );
    6: exit( fProj.currentConfiguration.otherOptions );
    7: exit( fProj.currentConfiguration.pathsOptions );
    8: exit( fProj.currentConfiguration.preBuildProcess );
    9: exit( fProj.currentConfiguration.postBuildProcess );
    10:exit( fProj.currentConfiguration.runOptions );
    11:exit( fProj.currentConfiguration );
    else result := nil;
  end;
end;

procedure TCEProjectConfigurationWidget.updateImperative;
var
  i: NativeInt;
begin
  selConf.ItemIndex:= -1;
  selConf.Clear;
  selconf.Enabled := (inspector.TIObject <> fProj) and fProj.isNotNil;
  if fProj.isNil then exit;
  //
  for i:= 0 to fProj.OptionsCollection.Count-1 do
    selConf.Items.Add(fProj.configuration[i].name);
  selConf.ItemIndex := fProj.ConfigurationIndex;
  inspector.TIObject := getGridTarget;
end;
{$ENDREGION --------------------------------------------------------------------}

end.
