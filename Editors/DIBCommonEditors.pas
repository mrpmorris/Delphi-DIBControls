unit DIBCommonEditors;


interface

{$i ..\OpenSource\dfs.inc}
uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  {$IFDEF DFS_NO_DSGNINTF}
  DesignEditors, DesignIntf,
  {$ELSE}
  DsgnIntf,
  {$ENDIF}
  TypInfo, DIBCommon;

implementation


end.
