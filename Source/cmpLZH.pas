unit cmpLZH;

{$R-}

interface

uses Sysutils, Classes;

type
  Int16 = SmallInt;
  
const
  //LZss parameters
  cStringBufferSize = 4096; //Size of string buffer
  cLookAheadSize = 60; //Size of look-ahead buffer
  cThreshHold = 2;
  cNull = cStringBufferSize; //End of the tree's node


  //Huffman parameters
  cNumChars = 256 - cThreshHold + cLookAheadSize;
  cTableSize = (cNumChars * 2) - 1;  //Size of table
  cRootPos = cTableSize - 1; //Root position
  cMaximumFreq = $8000; //Update when cummulative Freq hits this value

  //Tables FOR encoding/decoding upper 6 bits of sliding dictionary pointer
  //Encoder table
  cEncTableLen: array[0..63] of Byte = ($03, $04, $04, $04, $05, $05, $05, $05,
    $05, $05, $05, $05, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06,
    $06, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07,
    $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $08, $08, $08, $08, $08,
    $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08);

  cEncTableCode: array [0..63] of Byte = ($00, $20, $30, $40, $50, $58, $60,
    $68, $70, $78, $80, $88, $90, $94, $98, $9C, $A0, $A4, $A8, $AC, $B0, $B4,
    $B8, $BC, $C0, $C2, $C4, $C6, $C8, $CA, $CC, $CE, $D0, $D2, $D4, $D6, $D8,
    $DA, $DC, $DE, $E0, $E2, $E4, $E6, $E8, $EA, $EC, $EE, $F0, $F1, $F2, $F3,
    $F4, $F5, $F6, $F7, $F8, $F9, $FA, $FB, $FC, $FD, $FE, $FF);

  //Decoder table
  cDecTableLen: array[0..255] of Byte = ($03, $03, $03, $03, $03, $03, $03, $03,
    $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03,
    $03, $03, $03, $03, $03, $03, $03, $03, $03, $04, $04, $04, $04, $04, $04,
    $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04,
    $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04,
    $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $05, $05, $05,
    $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05,
    $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05,
    $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05,
    $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05,
    $05, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06,
    $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06,
    $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06,
    $06, $06, $06, $06, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07,
    $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07,
    $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07,
    $07, $07, $07, $07, $07, $07, $07, $08, $08, $08, $08, $08, $08, $08, $08,
    $08, $08, $08, $08, $08, $08, $08, $08);

  cDecTableCode: array [0..255] of Byte = ($00, $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $01, $01, $01, $01, $01,
    $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $02, $02, $02, $02,
    $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $03, $03, $03,
    $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $04, $04,
    $04, $04, $04, $04, $04, $04, $05, $05, $05, $05, $05, $05, $05, $05, $06,
    $06, $06, $06, $06, $06, $06, $06, $07, $07, $07, $07, $07, $07, $07, $07,
    $08, $08, $08, $08, $08, $08, $08, $08, $09, $09, $09, $09, $09, $09, $09,
    $09, $0A, $0A, $0A, $0A, $0A, $0A, $0A, $0A, $0B, $0B, $0B, $0B, $0B, $0B,
    $0B, $0B, $0C, $0C, $0C, $0C, $0D, $0D, $0D, $0D, $0E, $0E, $0E, $0E, $0F,
    $0F, $0F, $0F, $10, $10, $10, $10, $11, $11, $11, $11, $12, $12, $12, $12,
    $13, $13, $13, $13, $14, $14, $14, $14, $15, $15, $15, $15, $16, $16, $16,
    $16, $17, $17, $17, $17, $18, $18, $19, $19, $1A, $1A, $1B, $1B, $1C, $1C,
    $1D, $1D, $1E, $1E, $1F, $1F, $20, $20, $21, $21, $22, $22, $23, $23, $24,
    $24, $25, $25, $26, $26, $27, $27, $28, $28, $29, $29, $2A, $2A, $2B, $2B,
    $2C, $2C, $2D, $2D, $2E, $2E, $2F, $2F, $30, $31, $32, $33, $34, $35, $36,
    $37, $38, $39, $3A, $3B, $3C, $3D, $3E, $3F);


type
  ElzhException = class(Exception);

  //====================
  PFrequency = ^TFrequency;
  TFrequency = array [0..cTableSize] of Word;

  PParent = ^TParent;
  TParent = array [0..pred(cTableSize + cNumChars)] of Int16;

  PChild = ^TChild;
  TChild = array [0..PRED(cTableSize)] of Int16;

  PTextBuffer = ^TTextBuffer;
  TTextBuffer = array [0..cStringBufferSize + cLookAheadSize - 2] of Byte;

  PLinkArray = ^TLinkArray;
  TLinkArray = array [0..cStringBufferSize] of Int16;

  PLinkBackArray = ^TLinkBackArray;
  TLinkBackArray = array [0..cStringBufferSize + 256] of Int16;

  TAbstractLZH = class
  private
    { Private declarations }
    Code,
    Len,
    PutBuf,
    GetBuf: Word;

    GetLen,
    PutLen: Byte;

    FBytesWritten,
    FBytesRead,
    OrigSize,
    CodeSize,
    PrintCount: Longint;

    MatchPos,
    MatchLen: Int16;


    TextBuff: PTextBuffer;

    LeftLeaf,
    ParentLeaf: PLinkArray;
    RightLeaf: PLinkBackArray;
    
    Freq: PFrequency;

    Parent: PParent;
    Child: PChild;

    //Initialize the tree
    procedure InitTree;

    //Insert a new node
    procedure InsertNode(r: Int16);

    //Delete a node from the tree
    procedure DeleteNode(p: Int16);

    //Get a bit from the stream
    function GetBit: Int16;

    //Get a byte from the stream
    function GetByte: Int16;

    //Update a char
    procedure update(c: Int16);

    //Start huffman encoding
    procedure StartHuff;

    //Output some results
    procedure Putcode(l: Int16; c: WORD);

    //Reconstruct frequency tree
    procedure Reconstruct;

    //Encode a character
    procedure EncodeChar(c: WORD);

    //Encode a string position in the tree
    procedure EncodePosition(c: WORD);

    //Output "endcode end" flag
    procedure EncodeEnd;

    //Decode a character
    function DecodeChar: Int16;

    //Decode a string from the tree
    function DecodePosition: Word;

    //Start LZH
    procedure InitLZH;

    //End LZH
    procedure EndLZH;
  protected
    procedure InternalRead(var Data; Size: Word; var BytesRead: Word);
    procedure InternalWrite(const Data; Size: Word; var BytesWritten: Word); 
    procedure ReadData(var Data; Size: Word; var BytesRead: Word); virtual; abstract;
    procedure WriteData(const Data; Size: Word; var BytesWritten: Word);
      virtual; abstract;
  public
    function Pack(OrigSize: Longint): Longint;
    function Unpack: Longint;
  end;

  TLZHStream = class(TAbstractLZH)
  private
    FSource,
    FDest: TStream;
  protected
    procedure ReadData(var Data; Size: Word; var BytesRead: Word); override;
    procedure WriteData(const Data; Size: Word; var BytesWritten: Word); override;
  public
    constructor Create(Source, Dest: TStream);
  end;



implementation


procedure TAbstractLZH.InitTree;
var
  I: Int16;
begin
  for I := cStringBufferSize + 1 to cStringBufferSize + 256 do
    RightLeaf[i] := cNull;  // ROOT !!

  for I := 0 to cStringBufferSize do
    ParentLeaf[i] := cNull; //NODE
end;

procedure TAbstractLZH.InsertNode(r: Int16);
var
  tmp, i, p, cmp: Int16;
  key: PTextBuffer;
  c: WORD;
begin
  cmp := 1;
  key := @TextBuff[r];
  p := SUCC(cStringBufferSize) + key[0];
  RightLeaf[r] := cNull;
  LeftLeaf[r] := cNull;
  MatchLen := 0;
  while MatchLen < cLookAheadSize do 
  begin
    if (cmp >= 0) then 
    begin
      if (RightLeaf[p] <> cNull) then 
      begin
        p := RightLeaf[p]
      end 
      else 
      begin
        RightLeaf[p] := r;
        ParentLeaf[r] := p;
        exit;
      end;
    end 
    else 
    begin
      if (LeftLeaf[p] <> cNull) then 
      begin
        p := LeftLeaf[p]
      end 
      else 
      begin
        LeftLeaf[p] := r;
        ParentLeaf[r] := p;
        exit;
      end;
    end;

    i := 0;
    cmp := 0;
    while (i < cLookAheadSize) and (cmp = 0) do 
    begin
      inc(i);
      cmp := key[i] - TextBuff[p + i];
    end;

    if (i > cThreshHold) then 
    begin
      tmp := PRED((r - p) and PRED(cStringBufferSize));
      if (i > MatchLen) then 
      begin
        MatchPos := tmp;
        MatchLen := i;
      end;

      if (MatchLen < cLookAheadSize) and (i = MatchLen) then 
      begin
        c := tmp;
        if (Integer(c) < Integer(MatchPos)) then 
        begin
          MatchPos := c;
        end;
      end;
    end; { if i > threshold }
  end; { WHILE match_length < F }

  ParentLeaf[r] := ParentLeaf[p];
  LeftLeaf[r] := LeftLeaf[p];
  RightLeaf[r] := RightLeaf[p];
  ParentLeaf[LeftLeaf[p]] := r;
  ParentLeaf[RightLeaf[p]] := r;
  if (RightLeaf[ParentLeaf[p]] = p) then 
  begin
    RightLeaf[ParentLeaf[p]] := r;
  end 
  else
    LeftLeaf[ParentLeaf[p]] := r;

  ParentLeaf[p] := cNull;  { remove p }
end;

procedure TAbstractLZH.DeleteNode(p: Int16);
var
  q: Int16;
begin
  if (ParentLeaf[p] = cNull) then exit; //Unregistered node

  if RightLeaf[p] = cNull then
    q := LeftLeaf[p]
  else 
  begin
    if (LeftLeaf[p] = cNull) then
      q := RightLeaf[p]
    else 
    begin
      q := LeftLeaf[p];
      if (RightLeaf[q] <> cNull) then 
      begin
        repeat
          q := RightLeaf[q];
        until (RightLeaf[q] = cNull);

        RightLeaf[ParentLeaf[q]] := LeftLeaf[q];
        ParentLeaf[LeftLeaf[q]] := ParentLeaf[q];
        LeftLeaf[q] := LeftLeaf[p];
        ParentLeaf[LeftLeaf[p]] := q;
      end;

      RightLeaf[q] := RightLeaf[p];
      ParentLeaf[RightLeaf[p]] := q;
    end;
  end;
  ParentLeaf[q] := ParentLeaf[p];

  if (RightLeaf[ParentLeaf[p]] = p) then
    RightLeaf[ParentLeaf[p]] := q
  else
    LeftLeaf[ParentLeaf[p]] := q;

  ParentLeaf[p] := cNull;
end;


{ Huffman coding parameters }
function TAbstractLZH.GetBit: Int16;
var
  i: BYTE;
  i2: Int16;
  Wresult: Word;
begin
  while (getlen <= 8) do 
  begin
    InternalRead(i, 1, Wresult);
    if Wresult = 1 then
      i2 := i
    else
      i2 := 0;

    getbuf := getbuf or (i2 shl (8 - getlen));
    inc(getlen, 8);
  end;

  i2 := getbuf;
  getbuf := getbuf shl 1;
  dec(getlen);
  getbit := Int16((i2 < 0));
end;

function TAbstractLZH.GetByte: Int16;
var
  j: BYTE;
  i, Wresult: WORD;
begin
  while (getlen <= 8) do 
  begin
    InternalRead(j, 1, Wresult);
    if Wresult = 1 then
      i := j
    else
      i := 0;

    getbuf := getbuf or (i shl (8 - getlen));
    inc(getlen, 8);
  end;

  i := getbuf;
  getbuf := getbuf shl 8;
  dec(getlen, 8);
  getbyte := Int16(i shr 8);
end;

procedure TAbstractLZH.Putcode(l: Int16; c: WORD);
var
  Temp: Byte;
  Got: Word;
begin
  putbuf := putbuf or (c shr putlen);
  inc(putlen, l);

  if (putlen >= 8) then 
  begin
    Temp := putbuf shr 8;
    InternalWrite(Temp, 1, Got);
    dec(putlen, 8);
    if (putlen >= 8) then 
    begin
      Temp := Lo(PutBuf);
      InternalWrite(Temp, 1, Got);
      inc(codesize, 2);
      dec(putlen, 8);
      putbuf := c shl (l - putlen);
    end 
    else 
    begin
      putbuf := putbuf shl 8;
      inc(codesize);
    end;
  end;
end;

procedure TAbstractLZH.StartHuff;
var
  i, j: Int16;
begin
  //Initialize frquency tree
  for i := 0 to PRED(cNumChars) do 
  begin
    freq[i] := 1;
    Child[i] := i + cTableSize;
    Parent[i + cTableSize] := i;
  end;

  i := 0;
  j := cNumChars;
  while (j <= cRootPos) do 
  begin
    freq[j] := freq[i] + freq[i + 1];
    Child[j] := i;
    Parent[i] := j;
    Parent[i + 1] := j;
    inc(i, 2);
    inc(j);
  end;

  freq[cTableSize] := $ffff;
  Parent[cRootPos] := 0;
end;

procedure TAbstractLZH.Reconstruct;
var
  i, j, k, tmp: Int16;
  f, l: Word;
begin
  //Half the existing values
  j := 0;
  for i := 0 to PRED(cTableSize) do 
  begin
    if (Child[i] >= cTableSize) then 
    begin
      freq[j] := SUCC(freq[i]) div 2;    {@@ Bug Fix MOD -> DIV @@}
      Child[j] := Child[i];
      inc(j);
    end;
  end;

  //Make a tree : first, connect children nodes
  i := 0;
  j := cNumChars;
  while (j < cTableSize) do 
  begin
    k := SUCC(i);
    f := freq[i] + freq[k];
    freq[j] := f;
    k := PRED(j);

    while f < freq[k] do dec(K);

    inc(k);
    l := (j - k) shl 1;
    tmp := SUCC(k);
    move(freq[k], freq[tmp], l);
    freq[k] := f;
    move(Child[k], Child[tmp], l);
    Child[k] := i;
    inc(i, 2);
    inc(j);
  end;

  //Connect parent nodes
  for i := 0 to PRED(cTableSize) do 
  begin
    k := Child[i];
    if (k >= cTableSize) then
      Parent[k] := i
    else 
    begin
      Parent[k] := i;
      Parent[SUCC(k)] := i;
    end;
  end;
end;


procedure TAbstractLZH.update(c: Int16);
var
  i, j, k, l: Int16;
begin
  if (freq[cRootPos] = cMaximumFreq) then Reconstruct;

  c := Parent[c + cTableSize];
  repeat
    inc(freq[c]);
    k := freq[c];

    //Wwap nodes to keep the tree freq-ordered
    l := SUCC(C);
    if (Integer(k) > Integer(freq[l])) then 
    begin
      while (Integer(k) > Integer(freq[l])) do
        inc(l);

      dec(l);
      freq[c] := freq[l];
      freq[l] := k;

      i := Child[c];
      Parent[i] := l;
      if (i < cTableSize) then Parent[SUCC(i)] := l;

      j := Child[l];
      Child[l] := i;

      Parent[j] := c;
      if (j < cTableSize) then Parent[SUCC(j)] := c;
      Child[c] := j;

      c := l;
    end;
    c := Parent[c];
  until (c = 0); //Repeat until root has been reached
end;


procedure TAbstractLZH.EncodeChar(c: WORD);
var
  i: Word;
  j, k: Int16;
begin
  i := 0;
  j := 0;
  k := Parent[c + cTableSize];

  //Search connections from leaf node to the root
  repeat
    i := i shr 1;
    //IF node's address is odd, output 1, otherwise 0

    if Boolean(k and 1) then inc(i, $8000);
    inc(j);
    k := Parent[k];
  until (k = cRootPos);

  Putcode(j, i);
  code := i;
  len := j;
  update(c);
end;



procedure TAbstractLZH.EncodePosition(c: WORD);
var
  i, j: WORD;
begin
  //Output upper 6 bits with encoding
  i := c shr 6;
  j := cEncTableCode[i];
  Putcode(cEncTableLen[i], j shl 8);

  //Output lower 6 bits directly
  Putcode(6, (c and $3f) shl 10);
end;

procedure TAbstractLZH.EncodeEnd;
var
  Temp: Byte;
  Got: Word;
begin
  if Boolean(putlen) then 
  begin
    Temp := Lo(putbuf shr 8);
    InternalWrite(Temp, 1, Got);
    inc(codesize);
  end;
end;

function TAbstractLZH.DecodeChar: Int16;
var
  c: WORD;
begin
  c := Child[cRootPos];
  //Start searching tree from the root to leaves.
  //choose node #(son[]) IF input bit = 0
  //ELSE choose #(son[]+1) (input bit = 1)
  while (c < cTableSize) do 
  begin
    c := c + GetBit;
    c := Child[c];
  end;

  c := c - cTableSize;
  update(c);
  Decodechar := Int16(c);
end;

function TAbstractLZH.DecodePosition: Word;
var
  i, j, c: Word;
begin
  //Decode upper 6 bits from given table
  i := GetByte;
  c := WORD(cDecTableCode[i] shl 6);
  j := cDecTableLen[i];

  //Input lower 6 bits directly
  dec(j, 2);
  while j <> 0 do 
  begin
    i := (i shl 1) + GetBit;
    DEC(J);
  end;

  Result := c or i and $3f;
end;


procedure TAbstractLZH.InitLZH;
begin
  getbuf := 0;
  getlen := 0;
  putlen := 0;
  putbuf := 0;
  OrigSize := 0;
  codesize := 0;
  printcount := 0;
  MatchPos := 0;
  MatchLen := 0;
  FBytesWritten := 0;
  FBytesRead := 0;
  try
    New(LeftLeaf);
    New(ParentLeaf);
    New(RightLeaf);
    New(TextBuff);
    New(freq);
    New(Parent);
    New(Child);
  except
    raise ElzhException.Create('LZH : Cannot get memory for dictionary tables');
  end;
end;


procedure TAbstractLZH.EndLZH;
begin
  try
    Dispose(Child);
    Dispose(Parent);
    Dispose(freq);
    Dispose(TextBuff);
    Dispose(RightLeaf);
    Dispose(ParentLeaf);
    Dispose(LeftLeaf);
  except
    raise ElzhException.Create('LZH : Error freeing memory for dictionary tables');
  end;
end;


function TAbstractLZH.Pack(OrigSize: Longint): Longint;
var
  ct: BYTE;
  i, len, r, s, last_match_length: Int16;
  Got: WORD;
begin
  InternalWrite(OrigSize, Sizeof(Longint), Got);
  
  InitLZH;
  try
    OrigSize := 0;      { rewind and rescan }

    StartHuff;
    InitTree;

    s := 0;
    r := cStringBufferSize - cLookAheadSize;
    FillChar(TextBuff[0], r, ' ');
    len := 0;
    Got := 1;
    while (len < cLookAheadSize) and (Got <> 0) do 
    begin
      InternalRead(ct, 1, Got);
      if Got <> 0 then 
      begin
        TextBuff[r + len] := ct;
        inc(len);
      end;
    end;

    OrigSize := len;
    for i := 1 to cLookAheadSize do InsertNode(r - i);

    InsertNode(r);

    repeat
      if (MatchLen > len) then MatchLen := len;

      if (MatchLen <= cThreshHold) then 
      begin
        MatchLen := 1;
        EncodeChar(TextBuff[r]);
      end 
      else 
      begin
        EncodeChar(255 - cThreshHold + MatchLen);
        EncodePosition(MatchPos);
      end;

      last_match_length := MatchLen;
      i := 0;
      Got := 1;

      while (i < last_match_length) and (Got <> 0) do 
      begin
        InternalRead(ct, 1, Got);
        if Got <> 0 then 
        begin
          DeleteNode(s);
          TextBuff[s] := ct;
          if (s < PRED(cLookAheadSize)) then 
          begin
            TextBuff[s + cStringBufferSize] := ct;
          end;
          s := SUCC(s) and PRED(cStringBufferSize);
          r := SUCC(r) and PRED(cStringBufferSize);
          InsertNode(r);
          inc(i);
        end
      end;
      inc(OrigSize, i);

      while (i < last_match_length) do 
      begin
        inc(i);
        DeleteNode(s);
        s := SUCC(s) and PRED(cStringBufferSize);
        r := SUCC(r) and PRED(cStringBufferSize);
        dec(len);
        if Boolean(len) then InsertNode(r);
      end;
    until (len <= 0);

    EncodeEnd;
  finally
    Result := FBytesWritten;
    EndLZH;
  end;
end;

function TAbstractLZH.Unpack: Longint;
var
  c, i, j, k, r: Int16;
  c2: Byte;
  Count: Longint;
  Put: Word;
begin
  InitLZH;
  try
    StartHuff;
    r := cStringBufferSize - cLookAheadSize;
    FillChar(TextBuff[0], r, ' ');

    Count := 0;
    InternalRead(OrigSize, Sizeof(Longint), Put);
    while Count < OrigSize do 
    begin
      c := DecodeChar;
      if (c < 256) then 
      begin
        c2 := Lo(c);
        InternalWrite(c2, 1, Put);
        TextBuff[r] := c;
        INC(r);
        r := r and PRED(cStringBufferSize);
        inc(Count);
      end 
      else 
      begin //c >= 256
        i := (r - SUCC(DecodePosition)) and PRED(cStringBufferSize);
        j := c - 255 + cThreshHold;
        for k := 0 to PRED(j) do 
        begin
          c := TextBuff[(i + k) and PRED(cStringBufferSize)];
          c2 := Lo(c);
          InternalWrite(c2, 1, Put);
          TextBuff[r] := c;
          inc(r);
          r := r and PRED(cStringBufferSize);
          INC(Count);
        end;
      end;
    end;
  finally
    ENDLZH;
    Result := FBytesWritten;
  end;
end;

procedure TAbstractLZH.InternalRead(var Data; Size: Word;
  var BytesRead: Word);
begin
  ReadData(Data, Size, BytesRead);
  Inc(FBytesRead, BytesRead);
end;

procedure TAbstractLZH.InternalWrite(const Data; Size: Word;
  var BytesWritten: Word);
begin
  WriteData(Data, Size, BytesWritten);
  Inc(FBytesWritten, BytesWritten);
end;


{ TLZHStream }

constructor TLZHStream.Create(Source, Dest: TStream);
begin
  inherited Create;
  FSource := Source;
  FDest := Dest;
end;

procedure TLZHStream.ReadData(var Data; Size: Word; var BytesRead: Word);
begin
  BytesRead := FSource.Read(Data, Size);
end;

procedure TLZHStream.WriteData(const Data; Size: Word; var BytesWritten: Word);
begin
  BytesWritten := FDest.Write(Data, Size);
end;


end.
