(********************************************************)
(*                                                      *)
(*      Object Modeler Class Library                    *)
(*                                                      *)
(*      Open Source Released 2000                       *)
(*      http://objectmodeler.com                        *)
(********************************************************)


unit DIBStrConst;

interface

resourcestring
  SRangeIndexError = 'Index outside of range bounds';
  SLauncherFileError = 'Cannot launch specified filename';
  SLauncherTerminateError = 'Cannot terminate application';
  SInvalidMode = 'Pipe does not support this operation';
  SNoStorageSpecified = 'No storage specified in call to open stream';
  SNotConnected = 'Pipe not connected';
  SStorageNotOpen = 'Storage not open';
  SStreamNotOpen = 'Stream not open';
  SMutexCreateError = 'Unable to create mutex';
  SMapppingCreateError = 'Unable to create file mapping';
  SViewMapError = 'Cannot map view of file';
  SFileOpenError = 'Cannot open file';
  SNotLocked = 'Data not locked';
  SElapsedTime = 'Cannot get elapsed time';
  STimerError = 'Cannot %s timer';
  SCannotFocusSprite = 'Cannot focus a disabled or invisible sprite';
  SNameNotUnique = 'Name "%s" is not unique';
  SSocketCreateError = 'Error creating socket';
  SWinSocketError = 'Windows socket error: %s (%d), on API ''%s''';
  SInvalidPropertyKind = 'Invalid property kind';
  SInvalidPropertyValue = 'Invalid property value';
  SUnexpectedToken = 'Unexpected token at position %d';
  SOpenFailed = 'Unable to open com port';
  SWriteFailed = 'WriteFile function failed';
  SReadFailed = 'ReadFile function failed';
  SInvalidAsync = 'Invalid Async parameter';
  SPurgeFailed = 'PurgeComm function failed';
  SAsyncCheck = 'Unable to get async status';
  SSetStateFailed = 'SetCommState function failed';
  STimeoutsFailed = 'SetCommTimeouts failed';
  SSetupComFailed = 'SetupComm function failed';
  SClearComFailed = 'ClearCommError function failed';
  SModemStatFailed = 'GetCommModemStatus function failed';
  SEscapeComFailed = 'EscapeCommFunction function failed';
  STransmitFailed = 'TransmitCommChar function failed';
  SSyncMeth = 'Cannot set SyncMethod while connected';
  SEnumPortsFailed = 'EnumPorts function failed';
  SStoreFailed = 'Failed to store settings';
  SLoadFailed = 'Failed to load settings';
  SRegFailed = 'Terminal link (un)registration failed';
  SLedStateFailed = 'Cannot change led state if com port is selected';
  SNoParentStructure = 'No parent structure available';
  SInvalidStructureName = '"%s" is not a valid structure name';
  SDuplicateName = 'Duplicate names not allowed';
  SNoOpenStructure = 'Cannot open structure';
  SCannotPerformOperation = 'Cannot perform operation';
  SWhitespaceClass = 'wCls';
  SCommentClass = 'cCls';
  SReservedWordClass = 'rCls';
  SIdentifierClass = 'iCls';
  SSymbolClass = 'yCls';
  SStringClass = 'sCls';
  SNumberClass = 'nCls';
  SAssemblerClass = 'aCls';

implementation

end.
