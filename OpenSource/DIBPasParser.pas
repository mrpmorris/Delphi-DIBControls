unit DIBPasParser;

(********************************************************)
(*                                                      *)
(*      Object Modeler Class Library                    *)
(*                                                      *)
(*      Open Source Released 2000                       *)
(*      http://objectmodeler.com                        *)
(********************************************************)
//Warning, exe files on the above mentioned site are known
//to have had trojans etc written into them in order to
//scan your hard drive and extract your personal files !!  (Pete)

interface

uses
  Classes, SysUtils;

const
  CR = #13;
  LF = #10;
  CRLF = [CR, LF];
  ASCII = [#0..#255];
  Whitespace = [#0..#32];
  Alpha = ['A'..'Z', 'a'..'z', '_'];
  Numeric = ['0'..'9'];
  AlphaNumeric = Alpha + Numeric;
  Space = ASCII - AlphaNumeric;

type
  TTextBufferArray = array of PChar;

  TTextLines = class
  private
    FLines: TTextBufferArray;
    FCount: Integer;
    function GetLine(Index: Integer): string;
    function GetOrigin(Index: Integer): PChar;
  protected
    procedure Add(Buffer: PChar);
    function LineFromOrigin(Buffer: PChar): Integer;
  public
    property Count: Integer read FCount;
    property Line[Index: Integer]: string read GetLine; default;
    property Origin[Index: Integer]: PChar read GetOrigin;
  end;

{ The following parsed token kinds are not reserved words:

  TypeKind                     Example
  -----------------------      -------------------------
  tkIdentifier                 TForm1
  tkNumber                     1234
  tkText                       'Hello World'
  tkComma                      ,
  tkPoint                      .
  tkEqual                      =
  tkLessThan                   <
  tkLessThanOrEqual            <=
  tkGreaterThan                >
  tkGreaterThanOrEqual         >=
  tkGets                       :=
  tkColon                      :
  tkSemiColon                  ;
  tkOperator                   + - / *
  tkAddressOf                  @
  tkPointerTo                  ^
  tkLeftParenthesis            (
  tkRightParenthesis           )
  tkLeftBracket                [ (.
  tkRightBracket               ] .)
  tkRange                      ..
  tkSpecialSymbol              # $
  tkAnsiComment                //
  tkCComment                   (*
  tkPascalComment              {
  tkGarbage                    ~ \ % ! | `
  tkNull                       End of buffer }

  TPascalTokenKind = (tkAnd, tkArray, tkAs, tkAsm, tkBegin, tkCase, tkClass, tkConst,
    tkConstructor, tkDestructor, tkDispinterface, tkDiv, tkDo, tkDownto, tkElse,
    tkEnd, tkExcept, tkExports, tkFile, tkFinalization, tkFinally, tkFor,
    tkFunction, tkGoto, tkIf, tkImplementation, tkIn, tkInherited,
    tkInitialization, tkInline, tkInterface, tkIs, tkLabel, tkLibrary, tkMod,
    tkNil, tkNot, tkObject, tkOf, tkOr, tkOut, tkPacked, tkProcedure, tkProgram,
    tkProperty, tkRaise, tkRecord, tkRepeat, tkResourcestring, tkSet, tkShl,
    tkShr, tkString, tkThen, tkThreadvar, tkTo, tkTry, tkType, tkUnit, tkUntil,
    tkUses, tkVar, tkWhile, tkWith, tkXor, tkIdentifier, tkNumber, tkText,
    tkComma, tkPoint, tkEqual, tkLessThan, tkLessThanOrEqual, tkGreaterThan,
    tkGreaterThanOrEqual, tkGets, tkColon, tkSemiColon, tkOperator, tkAddressOf,
    tkPointerTo, tkLeftParenthesis, tkRightParenthesis, tkLeftBracket,
    tkRightBracket, tkRange, tkSpecialSymbol, tkAnsiComment, tkCComment,
    tkPascalComment, tkDirective, tkGarbage, tkNull);

  TPascalTokenKinds = set of TPascalTokenKind;

  { forward class declarations }

  TPascalParser = class;

  { TBasePascalToken class }

  TPascalToken = class
  private
    FOwner: TPascalParser;
    FPosition: Integer;
    FLength: Integer;
    FKind: TPascalTokenKind;
    function GetCol: Integer;
    function GetRow: Integer;
    function GetText: string;
    function GetFirst: Boolean;
    function GetLast: Boolean;
  protected
    property Owner: TPascalParser read FOwner;
  public
    constructor Create(AOwner: TPascalParser);
    procedure Copy(Token: TPascalToken);
    property Position: Integer read FPosition;
    property Length: Integer read FLength write FLength;
    property Text: string read GetText;
    property Col: Integer read GetCol;
    property Row: Integer read GetRow;
    property Kind: TPascalTokenKind read FKind;
    property First: Boolean read GetFirst;
    property Last: Boolean read GetLast;
  end;

  { EPascalTokenError exception }

  EPascalTokenError = class(Exception)
  private
    FToken: TPascalToken;
  public
    constructor CreateFromToken(AToken: TPascalToken);
    property Token: TPascalToken read FToken;
  end;

  { TPascalParser class }

  TPascalParser = class
  private
    FBuffer: PChar;
    FEndOfBuffer: PChar;
    FOrigin: PChar;
    FToken: TPascalToken;
    FScratchToken: TPascalToken;
    FLines: TTextLines;
    function GetPosition: Integer;
    procedure SetPosition(Value: Integer);
    procedure SetToken(Value: TPascalToken);
  public
    constructor Create(Buffer: PChar; Size: Integer);
    destructor Destroy; override;
    procedure Initialize(Buffer: PChar; Size: Integer);
    function Next: TPascalTokenKind;
    function Skip(const SkipKinds: TPascalTokenKinds): TPascalTokenKind;
    function Scan(ScanKinds: TPascalTokenKinds): TPascalTokenKind;
    function Peek(const SkipKinds: TPascalTokenKinds = []): TPascalTokenKind;
    property Origin: PChar read FOrigin write FOrigin;
    property Position: Integer read GetPosition write SetPosition;
    property Token: TPascalToken read FToken write SetToken;
    property Lines: TTextLines read FLines;
  end;

const
  ReservedPascalTokens = [tkAnd, tkArray, tkAs, tkAsm, tkBegin, tkCase,
    tkClass, tkConst, tkConstructor, tkDestructor, tkDispinterface, tkDiv, tkDo,
    tkDownto, tkElse, tkEnd, tkExcept, tkExports, tkFile, tkFinalization,
    tkFinally, tkFor, tkFunction, tkGoto, tkIf, tkImplementation, tkIn,
    tkInherited, tkInitialization, tkInline, tkInterface, tkIs, tkLabel,
    tkLibrary, tkMod, tkNil, tkNot, tkObject, tkOf, tkOr, tkOut, tkPacked,
    tkProcedure, tkProgram, tkProperty, tkRaise, tkRecord, tkRepeat,
    tkResourcestring, tkSet, tkShl, tkShr, tkString, tkThen, tkThreadvar,
    tkTo, tkTry, tkType, tkUnit, tkUntil, tkUses, tkVar, tkWhile, tkWith, tkXor];

{$IFDEF UNICODE}
  function SeekToken(P: PAnsiChar): PAnsiChar;
  function SeekWhiteSpace(P: PAnsiChar): PAnsiChar;
{$ELSE}
  function SeekToken(P: PChar): PChar;
  function SeekWhiteSpace(P: PChar): PChar;
{$ENDIF}
function StrToTokenKind(const Value: string): TPascalTokenKind;

implementation

uses
  DIBStrConst;

{$IFDEF UNICODE}
  function SeekToken(P: PAnsiChar): PAnsiChar;
  begin
    while IsLeadChar(P^) or SysUtils.CharInSet(P^, [#1..#9, #11, #12, #14..#32]) do
      Inc(P);
    Result := P;
  end;
{$ELSE}
  function SeekToken(P: PChar): PChar;
  begin
    while P^ in [#1..#9, #11, #12, #14..#32] do
      Inc(P);
    Result := P;
  end;
{$ENDIF}

{$IFDEF UNICODE}
  function SeekWhiteSpace(P: PAnsiChar): PAnsiChar;
  begin
    while IsLeadChar(P^) or SysUtils.CharInSet(P^, [#33..#255]) do
      Inc(P);
    Result := P;
  end;
{$ELSE}
  function SeekWhiteSpace(P: PChar): PChar;
  begin
    while P^ in [#33..#255] do
      Inc(P);
    Result := P;
  end;
{$ENDIF}

{$IFNDEF UNICODE}
  function CharInSet(P: PChar; Values: array of char): Boolean;
  var
    C: PChar;
    I: Integer;
  begin
    Result := True;
    for I := 0 to Length(Values) do
      if Values[I] = P then
        Exit;
    Result := False;
  end;
{$ENDIF}

function StrToTokenKind(const Value: string): TPascalTokenKind;

  function Hash(const Token: string): Integer;
  var
    j: Integer;
  begin
    Result := 0;
    for j := 1 to Length(Token) do
      Inc(Result, Ord(Token[j]));
  end;
var
  Token: string;
  j: Integer;
begin
  Result := tkGarbage;
  Token := UpperCase(Value);
  case Hash(Token) of
    143: if Token = 'IF' then Result := tkIf;
    147: if Token = 'DO' then Result := tkDo;
    148: if Token = 'AS' then Result := tkAs;
    149: if Token = 'OF' then Result := tkOf;
    151: if Token = 'IN' then Result := tkIn;
    156: if Token = 'IS' then Result := tkIs;
    161: if Token = 'OR' then Result := tkOr;
    163: if Token = 'TO' then Result := tkTo;
    211: if Token = 'AND' then Result := tkAnd;
    215: if Token = 'END' then Result := tkEnd;
    224: if Token = 'MOD' then Result := tkMod;
    225: if Token = 'ASM' then Result := tkAsm;
    227: if Token = 'DIV' then Result := tkDiv
      else if Token = 'NIL' then Result := tkNil;
      231: if Token = 'FOR' then Result := tkFor
      else if Token = 'SHL' then Result := tkShl;
      233: if Token = 'VAR' then Result := tkVar;
    236: if Token = 'SET' then Result := tkSet;
    237: if Token = 'SHR' then Result := tkShr;
    241: if Token = 'NOT' then Result := tkNot;
    248: if Token = 'OUT' then Result := tkOut;
    249: if Token = 'XOR' then Result := tkXor;
    255: if Token = 'TRY' then Result := tkTry;
    284: if Token = 'CASE' then Result := tkCase;
    288: if Token = 'FILE' then Result := tkFile;
    297: if Token = 'ELSE' then Result := tkElse;
    303: if Token = 'THEN' then Result := tkThen;
    313: if Token = 'GOTO' then Result := tkGoto;
    316: if Token = 'WITH' then Result := tkWith;
    320: if Token = 'UNIT' then Result := tkUnit
      else if Token = 'USES' then Result := tkUses;
      322: if Token = 'TYPE' then Result := tkType;
    352: if Token = 'LABEL' then Result := tkLabel;
    357: if Token = 'BEGIN' then Result := tkBegin;
    372: if Token = 'RAISE' then Result := tkRaise;
    374: if Token = 'CLASS' then Result := tkClass;
    377: if Token = 'WHILE' then Result := tkWhile;
    383: if Token = 'ARRAY' then Result := tkArray;
    391: if Token = 'CONST' then Result := tkConst;
    396: if Token = 'UNTIL' then Result := tkUntil;
    424: if Token = 'PACKED' then Result := tkPacked;
    439: if Token = 'OBJECT' then Result := tkObject;
    447: if Token = 'INLINE' then Result := tkInline
      else if Token = 'RECORD' then Result := tkRecord;
      449: if Token = 'REPEAT' then Result := tkRepeat;
    457: if Token = 'EXCEPT' then Result := tkExcept;
    471: if Token = 'STRING' then Result := tkString;
    475: if Token = 'DOWNTO' then Result := tkDownto;
    527: if Token = 'FINALLY' then Result := tkFinally;
    533: if Token = 'LIBRARY' then Result := tkLibrary;
    536: if Token = 'PROGRAM' then Result := tkProgram;
    565: if Token = 'EXPORTS' then Result := tkExports;
    614: if Token = 'FUNCTION' then Result := tkFunction;
    645: if Token = 'PROPERTY' then Result := tkProperty;
    657: if Token = 'INTERFACE' then Result := tkInterface;
    668: if Token = 'INHERITED' then Result := tkInherited;
    673: if Token = 'THREADVAR' then Result := tkThreadvar;
    681: if Token = 'PROCEDURE' then Result := tkProcedure;
    783: if Token = 'DESTRUCTOR' then Result := tkDestructor;
    870: if Token = 'CONSTRUCTOR' then Result := tkConstructor;
    904: if Token = 'FINALIZATION' then Result := tkFinalization;
    961: if Token = 'DISPINTERFACE' then Result := tkDispinterface;
    1062: if Token = 'IMPLEMENTATION' then Result := tkImplementation;
    1064: if Token = 'INITIALIZATION' then Result := tkInitialization;
    1087: if Token = 'RESOURCESTRING' then Result := tkResourcestring;
  end;
  if Result = tkGarbage then
    { is valid identifier }
    if CharInSet(Token[1], Alpha) then
    begin
      Result := tkIdentifier;
      for j := 2 to Length(Token) do
        if not CharInSet(Token[j], AlphaNumeric) then
        begin
          Result := tkGarbage;
          Exit;
        end;
    end
    else
      { is valid number }
      for j := 1 to Length(Token) do
      begin
        if not CharInSet(Token[j], Numeric) then
          Exit;
        Result := tkNumber;
      end;
end;

{ TTextLines }

procedure TTextLines.Add(Buffer: PChar);
const
  Delta = 10;
begin
  if (FCount > 0) and (Buffer <= FLines[FCount - 1]) then
    Exit;
  if FCount mod Delta = 0 then
    SetLength(FLines, FCount + 10);
  FLines[FCount] := Buffer;
  Inc(FCount);
end;

function TTextLines.LineFromOrigin(Buffer: PChar): Integer;
var
  I: Integer;
begin
  Result := -1;
  if FCount = 0 then
    Exit;
  for I := 0 to FCount - 1 do
  begin
    Inc(Result);
    if FLines[Result] > Buffer then
      Break;
  end;
end;

function TTextLines.GetLine(Index: Integer): string;
var
  P, Start: PChar;
begin
  Result := '';
  P := GetOrigin(Index);
  if P = nil then
    Exit;
  Start := P;
  while (not CharInSet(P^, CRLF)) or IsLeadChar(P^) or (P^ > #0) do
    Inc(P);
  SetString(Result, Start, P - Start);
end;

function TTextLines.GetOrigin(Index: Integer): PChar;
begin
  Result := nil;
  if (Index < 0) or (Index > FCount - 1) then
    Exit;
  Result := FLines[Index];
end;

{ TPascalToken }

constructor TPascalToken.Create(AOwner: TPascalParser);
begin
  FOwner := AOwner;
end;

procedure TPascalToken.Copy(Token: TPascalToken);
begin
  FOwner := Token.FOwner;
  FPosition := Token.FPosition;
  FLength := Token.FLength;
  FKind := Token.FKind;
end;

function TPascalToken.GetCol: Integer;
var
  P: PChar;
begin
  P := FOwner.FBuffer;
  Inc(P, FPosition);
  Result := FOwner.Lines.LineFromOrigin(P);
  if Result > -1 then
    Result := Integer(P - FOwner.Lines.Origin[Result])
  else
    Result := Integer(P - FOwner.FBuffer);
end;

function TPascalToken.GetRow: Integer;
var
  P: PChar;
begin
  P := FOwner.FBuffer;
  Inc(P, FPosition);
  Result := FOwner.Lines.LineFromOrigin(P);
  if Result = -1 then
    Result := 0;
end;

function TPascalToken.GetText: string;
var
  PrevPosition: Integer;
begin
  PrevPosition := FOwner.Position;
  FOwner.Position := FPosition;
  SetString(Result, FOwner.Origin, Length);
  FOwner.Position := PrevPosition;
end;

function TPascalToken.GetFirst: Boolean;
var
  P: PChar;
begin
  P := FOwner.FBuffer;
  Inc(P, FPosition);
  while P > FOwner.FBuffer do
    if CharInSet(P^, [#10, #13, #33..#255]) then
      Break
  else
    Inc(P);
  Result := (P = FOwner.FBuffer) or CharInSet(P^, CRLF);
end;

function TPascalToken.GetLast: Boolean;
var
  P: PChar;
begin
  P := FOwner.FBuffer;
  Inc(P, FPosition + FLength);
  while P^ > #0 do
    if CharInSet(P^, [#10, #13, #33..#255]) then
      Break
  else
    Inc(P);
  Result := CharInSet(P^, [#0, #10, #13]);
end;

{ EPascalTokenError }

constructor EPascalTokenError.CreateFromToken(AToken: TPascalToken);
begin
  FToken := AToken;
  inherited CreateFmt(SUnexpectedToken, [FToken.Position]);
end;

{ TPascalParser }

constructor TPascalParser.Create(Buffer: PChar; Size: Integer);
begin
  inherited Create;
  Initialize(Buffer, Size);
end;

destructor TPascalParser.Destroy;
begin
  FLines.Free;
  FToken.Free;
  FScratchToken.Free;
  inherited Destroy;
end;

procedure TPascalParser.Initialize(Buffer: PChar; Size: Integer);
begin
  FreeAndNil(FLines);
  FreeAndNil(FToken);
  FreeAndNil(FScratchToken);
  FLines := TTextLines.Create;
  FLines.Add(Buffer);
  FToken := TPascalToken.Create(Self);
  FScratchToken := TPascalToken.Create(Self);
  FBuffer := Buffer;
  FEndOfBuffer := Buffer;
  FOrigin := Buffer;
  Inc(FEndOfBuffer, Size);
end;

function TPascalParser.GetPosition: Integer;
begin
  Result := FOrigin - FBuffer;
end;

procedure TPascalParser.SetToken(Value: TPascalToken);
begin
  if Value.FOwner = Self then
    with FToken do
    begin
      Copy(Value);
      Self.Position := Position + Length;
    end
  else
    raise EPascalTokenError.Create(SInvalidPropertyValue);
end;

procedure TPascalParser.SetPosition(Value: Integer);
begin
  if Value <> Position then
  begin
    FOrigin := FBuffer;
    Inc(FOrigin, Value)
  end;
end;

function TPascalParser.Next: TPascalTokenKind;

  function GetCommentLength: Integer;
  var
    P: PChar;
  begin
    P := FOrigin;
    case FToken.Kind of
      tkAnsiComment:
        repeat
          Inc(P)
        until (P = FEndOfBuffer) or CharInSet(P[0], CRLF);
      tkCComment:
        begin
          Inc(P);
          if @P[1] < FEndOfBuffer then
          begin
            repeat
              Inc(P);
            until (@P[1] = FEndOfBuffer) or ((P[0] = '*') and (P[1] = ')'));
            if @P[1] < FEndOfBuffer then
              Inc(P, 2)
            else
              Inc(P);
          end;
        end;
      tkPascalComment:
        begin
          repeat
            Inc(P);
          until (P = FEndOfBuffer) or (P[0] = '}');
          if P < FEndOfBuffer then
            Inc(P);
        end;
    end;
    Result := P - FOrigin;
  end;
var
  P: PChar;
  S: string;
begin
  while (FOrigin < FEndOfBuffer) and CharInSet(FOrigin[0], Whitespace) do
    if (FOrigin[0] = #13) and (FOrigin[1] = #10) then
    begin
      Inc(FOrigin, 2);
      FLines.Add(FOrigin);
    end
  else
    Inc(FOrigin);
  if FOrigin < FEndOfBuffer then
    case FOrigin[0] of
      { tkText }
      '''':
        begin
          P := FOrigin;
          FToken.FKind := tkText;
          repeat
            Inc(P);
            while (P < FEndOfBuffer) and (P[0] = '''') and (P[1] = '''') do
              Inc(P, 2);
          until (P = FEndOfBuffer) or (P[0] = '''') or CharInSet(P[0], CRLF);
          if (P < FEndOfBuffer) and (P[0] = '''') then
            Inc(P)
          else
            FToken.FKind := tkGarbage;
          FToken.FLength := P - FOrigin;
        end;
      { tkComma }
      ',':
        begin
          FToken.FKind := tkComma;
          FToken.FLength := 1;
        end;
      { tkPoint, tkRightBracket, tkRange }
      '.':
        if @FOrigin[1] < FEndOfBuffer then
          case FOrigin[1] of
            ')':
              begin
                FToken.FKind := tkRightBracket;
                FToken.FLength := 2;
              end;
            '.':
              begin
                FToken.FKind := tkRange;
                FToken.FLength := 2;
              end;
            else
              begin
                FToken.FKind := tkPoint;
                FToken.FLength := 1;
              end;
          end
        else
          begin
            FToken.FKind := tkPoint;
            FToken.FLength := 1;
          end;
        { tkEqual }
        '=':
        begin
          FToken.FKind := tkEqual;
          FToken.FLength := 1;
        end;
      { tkLessThan, tkLessThanOrEqual }
      '<':
        if (@FOrigin[1] < FEndOfBuffer) and (Origin[1] = '=') then
        begin
          FToken.FKind := tkLessThanOrEqual;
          FToken.FLength := 2;
        end
        else
          begin
            FToken.FKind := tkLessThan;
            FToken.FLength := 1;
          end;
        { tkGreaterThan, tkGreaterThanOrEqual }
        '>':
        if (@FOrigin[1] < FEndOfBuffer) and (Origin[1] = '=') then
        begin
          FToken.FKind := tkGreaterThanOrEqual;
          FToken.FLength := 2;
        end
        else
          begin
            FToken.FKind := tkGreaterThan;
            FToken.FLength := 1;
          end;
        { tkGets, tkColon }
        ':':
        if (@FOrigin[1] < FEndOfBuffer) and (Origin[1] = '=') then
        begin
          FToken.FKind := tkGets;
          FToken.FLength := 2;
        end
        else
          begin
            FToken.FKind := tkColon;
            FToken.FLength := 1;
          end;
        { tkSemiColon }
        ';':
        begin
          FToken.FKind := tkSemiColon;
          FToken.FLength := 1;
        end;
      { tkAnsiComment, tkOperator }
      '+', '-', '/', '*':
        if (@FOrigin[1] < FEndOfBuffer) and (Origin[0] = '/') and (Origin[1] = '/') then
        begin
          FToken.FKind := tkAnsiComment;
          FToken.FLength := GetCommentLength;
        end
        else
          begin
            FToken.FKind := tkOperator;
            FToken.FLength := 1;
          end;
        { tkAddressOf }
        '@':
        begin
          FToken.FKind := tkAddressOf;
          FToken.FLength := 1;
        end;
      { tkPointerTo }
      '^':
        begin
          FToken.FKind := tkPointerTo;
          FToken.FLength := 1;
        end;
      { tkLeftBracket, tkCComment, tkLeftParenthesis }
      '(':
        if @FOrigin[1] < FEndOfBuffer then
          case FOrigin[1] of
            '.':
              begin
                FToken.FKind := tkLeftBracket;
                FToken.FLength := 2;
              end;
            '*':
              begin
                FToken.FKind := tkCComment;
                if FOrigin[2] = '$' then
                begin
                  FToken.FLength := GetCommentLength;
                  FToken.FKind := tkDirective;
                end
                else
                  FToken.FLength := GetCommentLength;
              end;
            else
              begin
                FToken.FKind := tkLeftParenthesis;
                FToken.FLength := 1;
              end;
          end
        else
          begin
            FToken.FKind := tkLeftParenthesis;
            FToken.FLength := 1;
          end;
        { tkRightParenthesis }
        ')':
        begin
          FToken.FKind := tkRightParenthesis;
          FToken.FLength := 1;
        end;
      { tkLeftBracket }
      '[':
        begin
          FToken.FKind := tkLeftBracket;
          FToken.FLength := 1;
        end;
      { tkRightBracket }
      ']':
        begin
          FToken.FKind := tkRightBracket;
          FToken.FLength := 1;
        end;
      { tkSpecialSymbol }
      '#', '$':
        begin
          FToken.FKind := tkSpecialSymbol;
          FToken.FLength := 1;
        end;
      { tkPascalComment }
      '{':
        begin
          FToken.FKind := tkPascalComment;
          if FOrigin[1] = '$' then
          begin
            FToken.FLength := GetCommentLength;
            FToken.FKind := tkDirective;
          end
          else
            FToken.FLength := GetCommentLength;
        end;
      { token in the range of tkAnd..tkNumber, tkGarbage }
      else
        begin
          P := FOrigin;
          repeat
            Inc(P);
          until (P = FEndOfBuffer) or CharInSet(P[0], Space);
          SetString(S, FOrigin, P - FOrigin);
          FToken.FKind := StrToTokenKind(S);
          FToken.FLength := Length(S);
        end;
    end
    { token is tkNull }
  else
  begin
    FOrigin := FEndOfBuffer;
    FToken.FKind := tkNull;
    FToken.FLength := 0;
  end;
  FToken.FPosition := Position;
  Inc(FOrigin, FToken.FLength);
  Result := FToken.FKind;
end;

function TPascalParser.Skip(const SkipKinds: TPascalTokenKinds): TPascalTokenKind;
begin
  repeat
    Result := Next;
  until (not (Result in SkipKinds)) or (Result = tkNull);
end;

function TPascalParser.Scan(ScanKinds: TPascalTokenKinds): TPascalTokenKind;
begin
  repeat
    Result := Next;
  until (Result in ScanKinds) or (Result = tkNull);
end;

function TPascalParser.Peek(const SkipKinds: TPascalTokenKinds = []): TPascalTokenKind;
var
  P: PChar;
begin
  P := FOrigin;
  FScratchToken.Copy(Token);
  repeat
    Result := Next;
  until (Result = tkNull) or (not (Result in SkipKinds));
  FToken.Copy(FScratchToken);
  FOrigin := P;
end;

end.
