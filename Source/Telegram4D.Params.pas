// Telegram4D - Telegram Bot API library for Delphi and Free Pascal
// Copyright 2026 Shaahin Ashayeri (https://github.com/DelphiMan68)
// SPDX-License-Identifier: Apache-2.0

unit Telegram4D.Params;

{ Request parameter builder + small value types used by the Bot API wrappers.

    Bot.Call('sendMessage', NewParams.AddChat('chat_id', 123).Add('text', 'Hi'));

  ITgParams keeps the parameters twice: as a JSON object (used for plain requests) and
  as form fields (used automatically when a file is uploaded). }

{$I Telegram4D.inc}

interface

uses
  Classes, SysUtils, Contnrs, Telegram4D.JSON, Telegram4D.Http, Telegram4D.Markup;

type
  /// Numeric chat id or "@channelusername". Converts implicitly from Int64 and string.
  TTgChatId = record
    IsNumeric: Boolean;
    Id: Int64;
    Name: string;
    class operator Implicit(AId: Int64): TTgChatId;
    class operator Implicit(const AName: string): TTgChatId;
  end;

  TTgInputKind = (ikReference, ikFile, ikStream);

  /// A file argument: existing file_id / URL (plain string converts implicitly),
  /// a local file, or a stream.
  TTgInputFile = record
    Kind: TTgInputKind;
    Value: string;      // file_id, URL, path, or file name (streams)
    Stream: TStream;    // streams only, not owned
    class function FromId(const AFileId: string): TTgInputFile; static;
    class function FromUrl(const AUrl: string): TTgInputFile; static;
    class function FromPath(const APath: string): TTgInputFile; static;
    class function FromStream(AStream: TStream; const AFileName: string): TTgInputFile; static;
    class operator Implicit(const AValue: string): TTgInputFile;
  end;

  ITgParams = interface
    ['{5E9D4C3A-0B7E-4E4B-8A2F-3C1D6A9B7E01}']
    function Add(const AName, AValue: string): ITgParams; overload;
    function Add(const AName: string; AValue: Int64): ITgParams; overload;
    function Add(const AName: string; AValue: Boolean): ITgParams; overload;
    function AddFloat(const AName: string; AValue: Double): ITgParams;
    /// Adds AValue only when it is not empty.
    function AddOpt(const AName, AValue: string): ITgParams;
    /// Adds AValue only when it is <> 0.
    function AddOptInt(const AName: string; AValue: Int64): ITgParams;
    function AddChat(const AName: string; const AId: TTgChatId): ITgParams;
    /// Adds a nested JSON value (object or array given as text).
    function AddJson(const AName, AJson: string): ITgParams;
    function AddMarkup(const AMarkup: ITgReplyMarkup): ITgParams;
    function AddInput(const AName: string; const AInput: TTgInputFile): ITgParams;
    function AddStrings(const AName: string; const AValues: array of string): ITgParams;
    function Json: TJsonObject;
    function Fields: TTgFormFields;
    function Uploads: TTgUploads;
  end;

function NewParams: ITgParams;

implementation

type
  TTgParams = class(TInterfacedObject, ITgParams)
  private
    FJson: TJsonObject;
    FFields: TTgFormFields;
    FUploads: TTgUploads;
    FOwned: TObjectList;
    procedure AddField(const AName, AValue: string);
    procedure AddUpload(const AField, AFileName: string; AStream: TStream);
  public
    constructor Create;
    destructor Destroy; override;
    function Add(const AName, AValue: string): ITgParams; overload;
    function Add(const AName: string; AValue: Int64): ITgParams; overload;
    function Add(const AName: string; AValue: Boolean): ITgParams; overload;
    function AddFloat(const AName: string; AValue: Double): ITgParams;
    function AddOpt(const AName, AValue: string): ITgParams;
    function AddOptInt(const AName: string; AValue: Int64): ITgParams;
    function AddChat(const AName: string; const AId: TTgChatId): ITgParams;
    function AddJson(const AName, AJson: string): ITgParams;
    function AddMarkup(const AMarkup: ITgReplyMarkup): ITgParams;
    function AddInput(const AName: string; const AInput: TTgInputFile): ITgParams;
    function AddStrings(const AName: string; const AValues: array of string): ITgParams;
    function Json: TJsonObject;
    function Fields: TTgFormFields;
    function Uploads: TTgUploads;
  end;

{ TTgChatId }

class operator TTgChatId.Implicit(AId: Int64): TTgChatId;
begin
  Result.IsNumeric := True;
  Result.Id := AId;
  Result.Name := '';
end;

class operator TTgChatId.Implicit(const AName: string): TTgChatId;
begin
  Result.IsNumeric := False;
  Result.Id := 0;
  Result.Name := AName;
end;

{ TTgInputFile }

class function TTgInputFile.FromId(const AFileId: string): TTgInputFile;
begin
  Result.Kind := ikReference;
  Result.Value := AFileId;
  Result.Stream := nil;
end;

class function TTgInputFile.FromUrl(const AUrl: string): TTgInputFile;
begin
  Result := FromId(AUrl);
end;

class function TTgInputFile.FromPath(const APath: string): TTgInputFile;
begin
  Result.Kind := ikFile;
  Result.Value := APath;
  Result.Stream := nil;
end;

class function TTgInputFile.FromStream(AStream: TStream; const AFileName: string): TTgInputFile;
begin
  Result.Kind := ikStream;
  Result.Value := AFileName;
  Result.Stream := AStream;
end;

class operator TTgInputFile.Implicit(const AValue: string): TTgInputFile;
begin
  Result := FromId(AValue);
end;

{ TTgParams }

constructor TTgParams.Create;
begin
  inherited Create;
  FJson := TJsonObject.Create;
  FOwned := TObjectList.Create(True);
end;

destructor TTgParams.Destroy;
begin
  FOwned.Free;
  FJson.Free;
  inherited;
end;

procedure TTgParams.AddField(const AName, AValue: string);
var
  N: Integer;
begin
  N := Length(FFields);
  SetLength(FFields, N + 1);
  FFields[N].Name := AName;
  FFields[N].Value := AValue;
end;

procedure TTgParams.AddUpload(const AField, AFileName: string; AStream: TStream);
var
  N: Integer;
begin
  N := Length(FUploads);
  SetLength(FUploads, N + 1);
  FUploads[N].Field := AField;
  FUploads[N].FileName := AFileName;
  FUploads[N].ContentType := 'application/octet-stream';
  FUploads[N].Stream := AStream;
end;

function TTgParams.Add(const AName, AValue: string): ITgParams;
begin
  FJson.S[AName] := AValue;
  AddField(AName, AValue);
  Result := Self;
end;

function TTgParams.Add(const AName: string; AValue: Int64): ITgParams;
begin
  FJson.L[AName] := AValue;
  AddField(AName, IntToStr(AValue));
  Result := Self;
end;

function TTgParams.Add(const AName: string; AValue: Boolean): ITgParams;
begin
  FJson.B[AName] := AValue;
  if AValue then
    AddField(AName, 'true')
  else
    AddField(AName, 'false');
  Result := Self;
end;

function TTgParams.AddFloat(const AName: string; AValue: Double): ITgParams;
var
  FS: TFormatSettings;
begin
  FS := FormatSettings;
  FS.DecimalSeparator := '.';
  FJson.F[AName] := AValue;
  AddField(AName, FloatToStr(AValue, FS));
  Result := Self;
end;

function TTgParams.AddOpt(const AName, AValue: string): ITgParams;
begin
  if AValue <> '' then
    Add(AName, AValue);
  Result := Self;
end;

function TTgParams.AddOptInt(const AName: string; AValue: Int64): ITgParams;
begin
  if AValue <> 0 then
    Add(AName, AValue);
  Result := Self;
end;

function TTgParams.AddChat(const AName: string; const AId: TTgChatId): ITgParams;
begin
  if AId.IsNumeric then
    Add(AName, AId.Id)
  else
    Add(AName, AId.Name);
  Result := Self;
end;

function TTgParams.AddJson(const AName, AJson: string): ITgParams;
var
  B: TJsonBaseObject;
begin
  B := TJsonBaseObject.Parse(AJson);
  if B is TJsonObject then
    FJson.O[AName] := TJsonObject(B)      // ownership moves to FJson
  else if B is TJsonArray then
    FJson.A[AName] := TJsonArray(B)
  else
  begin
    B.Free;
    raise Exception.Create('Telegram4D: AddJson expects a JSON object or array');
  end;
  AddField(AName, AJson);
  Result := Self;
end;

function TTgParams.AddMarkup(const AMarkup: ITgReplyMarkup): ITgParams;
begin
  if AMarkup <> nil then
    AddJson('reply_markup', AMarkup.ToJSON);
  Result := Self;
end;

function TTgParams.AddInput(const AName: string; const AInput: TTgInputFile): ITgParams;
var
  FS: TFileStream;
begin
  case AInput.Kind of
    ikReference:
      Add(AName, AInput.Value);
    ikFile:
      begin
        FS := TFileStream.Create(AInput.Value, fmOpenRead or fmShareDenyWrite);
        FOwned.Add(FS);
        AddUpload(AName, ExtractFileName(AInput.Value), FS);
      end;
    ikStream:
      AddUpload(AName, AInput.Value, AInput.Stream);
  end;
  Result := Self;
end;

function TTgParams.AddStrings(const AName: string; const AValues: array of string): ITgParams;
var
  Arr: TJsonArray;
  I: Integer;
begin
  Arr := FJson.A[AName];
  for I := 0 to High(AValues) do
    Arr.Add(AValues[I]);
  AddField(AName, Arr.ToJSON(True));
  Result := Self;
end;

function TTgParams.Json: TJsonObject;
begin
  Result := FJson;
end;

function TTgParams.Fields: TTgFormFields;
begin
  Result := FFields;
end;

function TTgParams.Uploads: TTgUploads;
begin
  Result := FUploads;
end;

function NewParams: ITgParams;
begin
  Result := TTgParams.Create;
end;

end.
