unit ce_compilers;

{$I ce_defines.inc}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, EditBtn,
  StdCtrls,
  ce_dcd, ce_common, ce_interfaces, ce_observer, ce_writableComponent,
  ce_dialogs;

type

  TCompilersPaths = class(TWritableLfmTextComponent)
  strict private
    fDefaultCompiler: DCompiler;
    fDmdExeName: string;
    fDmdRuntimePath: string;
    fDmdPhobosPath: string;
    fGdcExeName: string;
    fGdcRuntimePath: string;
    fGdcPhobosPath: string;
    fLdcExeName: string;
    fLdcRuntimePath: string;
    fLdcPhobosPath: string;
    fUser1ExeName: string;
    fUser1RuntimePath: string;
    fUser1PhobosPath: string;
    fUser2ExeName: string;
    fUser2RuntimePath: string;
    fUser2PhobosPath: string;
    fModified: boolean;
    fWouldNeedRestart: boolean;
    procedure setDefaultCompiler(value: DCompiler);
    procedure setDmdExeName(const value: string);
    procedure setDmdRuntimePath(const value: string);
    procedure setDmdPhobosPath(const value: string);
    procedure setGdcExeName(const value: string);
    procedure setGdcRuntimePath(const value: string);
    procedure setGdcPhobosPath(const value: string);
    procedure setLdcExeName(const value: string);
    procedure setLdcRuntimePath(const value: string);
    procedure setLdcPhobosPath(const value: string);
    procedure setUser1ExeName(const value: string);
    procedure setUser1RuntimePath(const value: string);
    procedure setUser1PhobosPath(const value: string);
    procedure setUser2ExeName(const value: string);
    procedure setUser2RuntimePath(const value: string);
    procedure setUser2PhobosPath(const value: string);
  protected
    procedure afterLoad; override;
  published
    property defaultCompiler: DCompiler read fDefaultCompiler write setDefaultCompiler;
    property DmdExeName: string read fDmdExeName write setDmdExeName;
    property DmdRuntimePath: string read fDmdRuntimePath write setDmdRuntimePath;
    property DmdPhobosPath: string read fDmdPhobosPath write setDmdPhobosPath;
    property GdcExeName: string read fGdcExeName write setGdcExeName;
    property GdcRuntimePath: string read fGdcRuntimePath write setGdcRuntimePath;
    property GdcPhobosPath: string read fGdcPhobosPath write setGdcPhobosPath;
    property LdcExeName: string read fLdcExeName write setLdcExeName;
    property LdcRuntimePath: string read fLdcRuntimePath write setLdcRuntimePath;
    property LdcPhobosPath: string read fLdcPhobosPath write setLdcPhobosPath;
    property User1ExeName: string read fUser1ExeName write setUser1ExeName;
    property User1RuntimePath: string read fUser1RuntimePath write setUser1RuntimePath;
    property User1PhobosPath: string read fUser1PhobosPath write setUser1PhobosPath;
    property User2ExeName: string read fUser2ExeName write setUser2ExeName;
    property User2RuntimePath: string read fUser2RuntimePath write setUser2RuntimePath;
    property User2PhobosPath: string read fUser2PhobosPath write setUser2PhobosPath;
  public
    procedure assign(source: TPersistent); override;
    property wouldNeedRestart: boolean read fWouldNeedRestart write fWouldNeedRestart;
    property modified: boolean read fModified write fModified;
  end;

  TCompilersPathsEditor = class(TForm, ICEEditableOptions, ICECompilerSelector, ICEProjectObserver)
    selDefault: TComboBox;
    selDMDrt: TDirectoryEdit;
    selUSER2std: TDirectoryEdit;
    selDMDstd: TDirectoryEdit;
    selGDCrt: TDirectoryEdit;
    selGDCstd: TDirectoryEdit;
    selLDCrt: TDirectoryEdit;
    selLDCstd: TDirectoryEdit;
    selUSER1rt: TDirectoryEdit;
    selUSER1std: TDirectoryEdit;
    selUSER2rt: TDirectoryEdit;
    selDMDexe: TFileNameEdit;
    selGDCexe: TFileNameEdit;
    selLDCexe: TFileNameEdit;
    selUSER1exe: TFileNameEdit;
    selUSER2exe: TFileNameEdit;
    grpDMD: TGroupBox;
    grpGDC: TGroupBox;
    grpLDC: TGroupBox;
    grpUSER1: TGroupBox;
    grpUSER2: TGroupBox;
    GroupBox6: TGroupBox;
    ScrollBox1: TScrollBox;
    StaticText1: TStaticText;
    StaticText10: TStaticText;
    StaticText11: TStaticText;
    StaticText12: TStaticText;
    StaticText13: TStaticText;
    StaticText14: TStaticText;
    StaticText15: TStaticText;
    StaticText2: TStaticText;
    StaticText3: TStaticText;
    StaticText4: TStaticText;
    StaticText5: TStaticText;
    StaticText6: TStaticText;
    StaticText7: TStaticText;
    StaticText8: TStaticText;
    StaticText9: TStaticText;
    procedure dialogOpen(sender: TObject);
  strict private
    fPaths: TCompilersPaths;
    fPathsBackup: TCompilersPaths;
    fProj: ICECommonProject;
    procedure selectedExe(sender: TObject; var value: string);
    procedure selectedRt(sender: TObject; var value: string);
    procedure selectedStd(sender: TObject; var value: string);
    procedure selectedDefault(sender: TObject);
    procedure autoDetectDMD;
    procedure autoDetectGDC;
    procedure autoDetectLDC;
    procedure dataToGui;
    //
    function optionedWantCategory(): string;
    function optionedWantEditorKind: TOptionEditorKind;
    function optionedWantContainer: TPersistent;
    procedure optionedEvent(event: TOptionEditorEvent);
    function optionedOptionsModified: boolean;
    //
    function singleServiceName: string;
    function isCompilerValid(value: DCompiler): boolean;
    function getCompilerPath(value: DCompiler): string;
    procedure getCompilerImports(value: DCompiler; paths: TStrings);
    //
    procedure projNew(project: ICECommonProject);
    procedure projChanged(project: ICECommonProject);
    procedure projClosing(project: ICECommonProject);
    procedure projFocused(project: ICECommonProject);
    procedure projCompiling(project: ICECommonProject);
    procedure projCompiled(project: ICECommonProject; success: boolean);
    procedure updateDCD;
  public
    constructor create(aOwner: TComponent); override;
    destructor destroy; override;
  end;

implementation
{$R *.lfm}

uses
  ce_libman;

var
  CompilersPathsEditor: TCompilersPathsEditor;

const
  optFname = 'compilerspaths.txt';

{$REGION Standard Object/Components things -------------------------------------}
constructor TCompilersPathsEditor.create(aOwner: TComponent);
var
  fname: string;
begin
  inherited;
  fPaths:= TCompilersPaths.Create(self);
  fPathsBackup:= TCompilersPaths.Create(self);

  fname := getCoeditDocPath + optFname;
  if fname.fileExists then
    fPaths.loadFromFile(fname);
  if not isCompilerValid(dmd) then
    autoDetectDMD;
  if not isCompilerValid(gdc) then
    autoDetectGDC;
  if not isCompilerValid(ldc) then
    autoDetectLDC;
  fPathsBackup.Assign(fPaths);
  dataToGui;

  updateDCD;

  selDMDexe.OnAcceptFileName:= @selectedExe;
  selGDCexe.OnAcceptFileName:= @selectedExe;
  selLDCexe.OnAcceptFileName:= @selectedExe;
  selUSER1exe.OnAcceptFileName:= @selectedExe;
  selUSER2exe.OnAcceptFileName:= @selectedExe;

  selDMDrt.OnAcceptDirectory:= @selectedRt;
  selGDCrt.OnAcceptDirectory:= @selectedRt;
  selLDCrt.OnAcceptDirectory:= @selectedRt;
  selUSER1rt.OnAcceptDirectory:= @selectedRt;
  selUSER2rt.OnAcceptDirectory:= @selectedRt;

  selDMDstd.OnAcceptDirectory:= @selectedStd;
  selGDCstd.OnAcceptDirectory:= @selectedStd;
  selLDCstd.OnAcceptDirectory:= @selectedStd;
  selUSER1std.OnAcceptDirectory:= @selectedStd;
  selUSER2std.OnAcceptDirectory:= @selectedStd;

  selDefault.OnSelect:= @selectedDefault;

  EntitiesConnector.addSingleService(self);
  EntitiesConnector.addObserver(self);
end;

destructor TCompilersPathsEditor.destroy;
begin
  fPaths.saveToFile(getCoeditDocPath + optFname);
  EntitiesConnector.removeObserver(self);
  inherited;
end;

procedure TCompilersPaths.assign(source: TPersistent);
var
  src: TCompilersPaths;
begin
  if source is TCompilersPaths then
  begin
    src := TCompilersPaths(source);
    DefaultCompiler  := src.fDefaultCompiler;
    DmdExeName       := src.fDmdExeName;
    DmdRuntimePath   := src.fDmdRuntimePath;
    DmdPhobosPath    := src.fDmdPhobosPath;
    GdcExeName       := src.fGdcExeName;
    GdcRuntimePath   := src.fGdcRuntimePath;
    GdcPhobosPath    := src.fGdcPhobosPath;
    LdcExeName       := src.fLdcExeName;
    LdcRuntimePath   := src.fLdcRuntimePath;
    LdcPhobosPath    := src.fLdcPhobosPath;
    User1ExeName     := src.fUser1ExeName;
    User1RuntimePath := src.fUser1RuntimePath;
    User1PhobosPath  := src.fUser1PhobosPath;
    User2ExeName     := src.fUser2ExeName;
    User2RuntimePath := src.fUser2RuntimePath;
    User2PhobosPath  := src.fUser2PhobosPath;
  end
  else inherited;
end;

procedure TCompilersPaths.setDefaultCompiler(value: Dcompiler);
begin
  if fDefaultCompiler = value then
    exit;
  fDefaultCompiler:=value;
  fWouldNeedRestart := true;
  fModified:=true;
end;

procedure TCompilersPaths.setDmdExeName(const value: string);
begin
  if fDmdExeName = value then
    exit;
  fDmdExeName:=value;
  fModified:=true;
end;

procedure TCompilersPaths.setDmdRuntimePath(const value: string);
begin
  if fDmdRuntimePath = value then
    exit;
  fDmdRuntimePath:=value;
  fModified:=true;
  if fDefaultCompiler = dmd then
    fWouldNeedRestart := true;
end;

procedure TCompilersPaths.setDmdPhobosPath(const value: string);
begin
  if fDmdPhobosPath = value then
    exit;
  fDmdPhobosPath:=value;
  fModified:=true;
  if fDefaultCompiler = dmd then
    fWouldNeedRestart := true;
end;

procedure TCompilersPaths.setGdcExeName(const value: string);
begin
  if fGdcExeName = value then
    exit;
  fGdcExeName:=value;
  fModified:=true;
end;

procedure TCompilersPaths.setGdcRuntimePath(const value: string);
begin
  if fGdcRuntimePath = value then
    exit;
  fGdcRuntimePath:=value;
  fModified:=true;
  if fDefaultCompiler in [gdc,gdmd] then
    fWouldNeedRestart := true;
end;

procedure TCompilersPaths.setGdcPhobosPath(const value: string);
begin
  if fGdcPhobosPath = value then
    exit;
  fGdcPhobosPath:=value;
  fModified:=true;
  if fDefaultCompiler in [gdc,gdmd] then
    fWouldNeedRestart := true;
end;

procedure TCompilersPaths.setLdcExeName(const value: string);
begin
  if fLdcExeName = value then
    exit;
  fLdcExeName:=value;
  fModified:=true;
end;

procedure TCompilersPaths.setLdcRuntimePath(const value: string);
begin
  if fLdcRuntimePath = value then
    exit;
  fLdcRuntimePath:=value;
  fModified:=true;
  if fDefaultCompiler in [ldc,ldmd] then
    fWouldNeedRestart := true;
end;

procedure TCompilersPaths.setLdcPhobosPath(const value: string);
begin
  if fLdcPhobosPath = value then
    exit;
  fLdcPhobosPath:=value;
  fModified:=true;
  if fDefaultCompiler in [ldc,ldmd] then
    fWouldNeedRestart := true;
end;

procedure TCompilersPaths.setUser1ExeName(const value: string);
begin
  if fUser1ExeName = value then
    exit;
  fUser1ExeName:=value;
  fModified:=true;
end;

procedure TCompilersPaths.setUser1RuntimePath(const value: string);
begin
  if fUser1RuntimePath = value then
    exit;
  fUser1RuntimePath:=value;
  fModified:=true;
  if fDefaultCompiler = user1 then
    fWouldNeedRestart := true;
end;

procedure TCompilersPaths.setUser1PhobosPath(const value: string);
begin
  if fUser1PhobosPath = value then
    exit;
  fUser1PhobosPath:=value;
  fModified:=true;
  if fDefaultCompiler = user1 then
    fWouldNeedRestart := true;
end;

procedure TCompilersPaths.setUser2ExeName(const value: string);
begin
  if fUser2ExeName = value then
    exit;
  fUser2ExeName:=value;
  fModified:=true;
end;

procedure TCompilersPaths.setUser2RuntimePath(const value: string);
begin
  if fUser2RuntimePath = value then
    exit;
  fUser2RuntimePath:=value;
  fModified:=true;
  if fDefaultCompiler = user2 then
    fWouldNeedRestart := true;
end;

procedure TCompilersPaths.setUser2PhobosPath(const value: string);
begin
  if fUser2PhobosPath = value then
    exit;
  fUser2PhobosPath:=value;
  fModified:=true;
  if fDefaultCompiler = user2 then
    fWouldNeedRestart := true;
end;

procedure TCompilersPaths.afterLoad;
begin
  inherited;
  fModified:=false;
  fWouldNeedRestart:=false;
end;
{$ENDREGION}

{$REGION ICEProjectObserver ----------------------------------------------------}
procedure TCompilersPathsEditor.projNew(project: ICECommonProject);
begin
end;

procedure TCompilersPathsEditor.projChanged(project: ICECommonProject);
begin
end;

procedure TCompilersPathsEditor.projClosing(project: ICECommonProject);
begin
  if fProj = project then
    fProj := nil;
end;

procedure TCompilersPathsEditor.projFocused(project: ICECommonProject);
begin
  fProj := project;
end;

procedure TCompilersPathsEditor.projCompiling(project: ICECommonProject);
begin
end;

procedure TCompilersPathsEditor.projCompiled(project: ICECommonProject; success: boolean);
begin
end;
{$ENDREGION}

{$REGION ICEEditableOptions ----------------------------------------------------}
function TCompilersPathsEditor.optionedWantCategory(): string;
begin
  exit('Compilers paths');
end;

function TCompilersPathsEditor.optionedWantEditorKind: TOptionEditorKind;
begin
  exit(oekForm);
end;

function TCompilersPathsEditor.optionedWantContainer: TPersistent;
begin
  fPathsBackup.assign(fPaths);
  exit(self);
end;

procedure TCompilersPathsEditor.optionedEvent(event: TOptionEditorEvent);
begin
  case event of
    oeeAccept:
    begin
      fPathsBackup.assign(fPaths);
      if fPaths.wouldNeedRestart and fPaths.modified then
      begin
        if not DCDWrapper.launchedByCe then
          dlgOkInfo('Coedit and DCD must be restarted manually in order to cache'
            + ' the right runtime and the standard library versions.')
        else
        begin
          DCDWrapper.relaunch;
          updateDCD;
          LibMan.updateDCD;
          if assigned(fProj) then
            fProj.activate;
        end;
      end;
      fPaths.modified:=false;
      fPaths.wouldNeedRestart:=false;
    end;
    oeeCancel:
    begin
      fPaths.assign(fPathsBackup);
      fPaths.modified:=false;
      fPaths.wouldNeedRestart:=false;
    end;
  end;
end;

function TCompilersPathsEditor.optionedOptionsModified: boolean;
begin
  exit(fPaths.modified);
end;
{$ENDREGION}

{$REGION ICECompilerSelector ---------------------------------------------------}
function TCompilersPathsEditor.singleServiceName: string;
begin
  exit('ICECompilerSelector');
end;

function TCompilersPathsEditor.isCompilerValid(value: DCompiler): boolean;
begin
  result := false;
  with fPaths do case value of
    DCompiler.dmd: exit(DmdExeName.fileExists);
    DCompiler.gdc: exit(GdcExeName.fileExists);
    DCompiler.gdmd: exit(exeFullName('gdmd' + exeExt).fileExists);
    DCompiler.ldc: exit(LdcExeName.fileExists);
    DCompiler.ldmd: exit(exeFullName('ldmd2' + exeExt).fileExists);
    DCompiler.user1: exit(User1ExeName.fileExists);
    DCompiler.user2: exit(User2ExeName.fileExists);
  end;
end;

function TCompilersPathsEditor.getCompilerPath(value: DCompiler): string;
begin
  result := '';
  with fPaths do case value of
    DCompiler.dmd: exit(DmdExeName);
    DCompiler.gdc: exit(GdcExeName);
    DCompiler.gdmd: exit(exeFullName('gdmd' + exeExt));
    DCompiler.ldc: exit(LdcExeName);
    DCompiler.ldmd: exit(exeFullName('ldmd2' + exeExt));
    DCompiler.user1: exit(User1ExeName);
    DCompiler.user2: exit(User2ExeName);
  end;
end;

procedure TCompilersPathsEditor.getCompilerImports(value: DCompiler; paths: TStrings);
  procedure tryAdd(const pth: string);
  begin
    if pth.isNotEmpty then
      paths.Add(pth);
  end;
begin
  with fPaths do case value of
    DCompiler.dmd: begin tryAdd(DmdRuntimePath); tryAdd(DmdPhobosPath); end;
    DCompiler.gdc, DCompiler.gdmd:
      begin tryAdd(GdcRuntimePath); tryAdd(GdcPhobosPath); end;
    DCompiler.ldc, DCompiler.ldmd:
      begin tryAdd(LdcRuntimePath); tryAdd(LdcPhobosPath); end;
    DCompiler.user1:
      begin tryAdd(User1RuntimePath); tryAdd(User1PhobosPath); end;
    DCompiler.user2:
      begin tryAdd(User2RuntimePath); tryAdd(User2PhobosPath); end;
  end;
end;
{$ENDREGION}

{$REGION Compilers paths things ------------------------------------------------}
procedure TCompilersPathsEditor.updateDCD;
var
  imprt: TStringList;
begin
  imprt := TStringList.Create;
  try
    getCompilerImports(fPaths.defaultCompiler, imprt);
    DcdWrapper.addImportFolders(imprt);
  finally
    imprt.free;
  end;
end;

procedure TCompilersPathsEditor.dataToGui;
begin
  with fPaths do
  begin
    selDMDexe.FileName  := DmdExeName;
    selDMDrt.Directory  := DmdRuntimePath;
    selDMDstd.Directory := DmdPhobosPath;

    selGDCexe.FileName  := GdcExeName;
    selGDCrt.Directory  := GdcRuntimePath;
    selGDCstd.Directory := GdcPhobosPath;

    selLDCexe.FileName  := LdcExeName;
    selLDCrt.Directory  := LdcRuntimePath;
    selLDCstd.Directory := LdcPhobosPath;

    selUSER1exe.FileName  := User1ExeName;
    selUSER1rt.Directory  := User1RuntimePath;
    selUSER1std.Directory := User1PhobosPath;

    selUSER2exe.FileName  := User2ExeName;
    selUSER2rt.Directory  := User2RuntimePath;
    selUSER2std.Directory := User2PhobosPath;

    selDefault.ItemIndex := integer(defaultCompiler);
  end;
end;

procedure TCompilersPathsEditor.dialogOpen(sender: TObject);
var
  fne: TFileNameEdit;
  dre: TDirectoryEdit;
begin
  if sender is TFileNameEdit then
  begin
    fne := TFileNameEdit(sender);
    fne.InitialDir:=fne.FileName.extractFileDir;
    fne.DialogTitle:='Select a D compiler';
  end
  else
  begin
    dre := TDirectoryEdit(sender);
    dre.RootDir:=dre.Directory;
    dre.ShowHidden:=true;
    dre.DialogTitle:='Select a library path';
  end;
end;

procedure TCompilersPathsEditor.selectedExe(sender: TObject; var value: string);
var
  ctrl: TWinControl;
begin
  ctrl := TWinControl(sender);
  if ctrl.Parent = grpDMD then
    fPaths.DmdExeName:=value
  else if ctrl.Parent = grpGDC then
    fPaths.GDCExeName:=value
  else if ctrl.Parent = grpLDC then
    fPaths.LdcExeName:=value
  else if ctrl.Parent = grpUSER1 then
    fPaths.User1ExeName:=value
  else if ctrl.Parent = grpUSER2 then
    fPaths.User2ExeName:=value;
end;

procedure TCompilersPathsEditor.selectedRt(sender: TObject; var value: string);
var
  ctrl: TWinControl;
begin
  ctrl := TWinControl(sender);
  if ctrl.Parent = grpDMD then
    fPaths.DmdRuntimePath:=value
  else if ctrl.Parent = grpGDC then
    fPaths.GDCRuntimePath:=value
  else if ctrl.Parent = grpLDC then
    fPaths.LdcRuntimePath:=value
  else if ctrl.Parent = grpUSER1 then
    fPaths.User1RuntimePath:=value
  else if ctrl.Parent = grpUSER2 then
    fPaths.User2RuntimePath:=value;
end;

procedure TCompilersPathsEditor.selectedStd(sender: TObject; var value: string);
var
  ctrl: TWinControl;
begin
  ctrl := TWinControl(sender);
  if ctrl.Parent = grpDMD then
    fPaths.DmdPhobosPath:=value
  else if ctrl.Parent = grpGDC then
    fPaths.GDCPhobosPath:=value
  else if ctrl.Parent = grpLDC then
    fPaths.LdcPhobosPath:=value
  else if ctrl.Parent = grpUSER1 then
    fPaths.User1PhobosPath:=value
  else if ctrl.Parent = grpUSER2 then
    fPaths.User2PhobosPath:=value;
end;

procedure TCompilersPathsEditor.selectedDefault(sender: TObject);
begin
  fPaths.defaultCompiler:= DCompiler(selDefault.ItemIndex);
end;

procedure TCompilersPathsEditor.autoDetectDMD;
{$IFDEF WINDOWS}
var
  path: string;
{$ENDIF}
begin
  {$IFDEF WINDOWS}
  path := exeFullName('dmd' + exeExt);
  if path.fileExists then
  begin
    fPaths.DmdExeName:= path;
    path := path.extractFileDir.extractFileDir.extractFileDir;
    if (path + '\src\druntime\import').dirExists then
      fPaths.DmdRuntimePath := path + '\src\druntime\import';
    if (path + '\src\phobos').dirExists then
      fPaths.DmdPhobosPath := path + '\src\phobos';
  end;
  {$ENDIF}
  {$IFDEF LINUX}
  if '/usr/bin/dmd'.fileExists then
    fPaths.DmdExeName:='/usr/bin/dmd';
  if '/usr/include/dmd/druntime/import'.dirExists then
    fPaths.DmdRuntimePath:='/usr/include/dmd/druntime/import';
  if '/usr/include/dmd/phobos'.dirExists then
    fPaths.DmdPhobosPath:='/usr/include/dmd/phobos';
  {$ENDIF}
  {$IFDEF DARWIN}
  if '/usr/local/bin/dmd'.fileExists then
    fPaths.DmdExeName:='/usr/local/bin/dmd';
  if '/Library/D/dmd/src/druntime/import' then
    fPaths.DmdRuntimePath:='/Library/D/dmd/src/druntime/import';
  if '/Library/D/dmd/src/phobos'.dirExists then
    fPaths.DmdPhobosPath:='/Library/D/dmd/src/phobos';
  {$ENDIF}
end;

procedure TCompilersPathsEditor.autoDetectGDC;
var
  path: string;
  str: TStringList;
begin
  path := exeFullName('gdc' + exeExt);
  if path.fileExists then
  begin
    fPaths.GdcExeName:= path;
    str := TStringList.Create;
    try
      path := path.extractFileDir.extractFilePath;
      FindAllDirectories(str, path, true);
      for path in str do
        if pos('include' + DirectorySeparator + 'd', path) > 0 then
      begin
        fPaths.GdcRuntimePath:= path;
        break;
      end;
    finally
      str.Free;
    end;
  end;
end;

procedure TCompilersPathsEditor.autoDetectLDC;
var
  path: string;
begin
  path := exeFullName('ldc2' + exeExt);
  if path.fileExists then
  begin
    fPaths.LdcExeName:= path;
    path := path.extractFilePath.extractFilePath + DirectorySeparator + 'import';
    if path.dirExists then
      fPaths.LdcRuntimePath:=path;
  end;
end;
{$ENDREGION}

initialization
  CompilersPathsEditor := TCompilersPathsEditor.create(nil);
finalization
  CompilersPathsEditor.free;
end.

