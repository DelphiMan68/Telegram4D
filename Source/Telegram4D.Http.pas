// Telegram4D - Telegram Bot API library for Delphi and Free Pascal
// Copyright 2026 Shaahin Ashayeri (https://github.com/DelphiMan68)
// SPDX-License-Identifier: Apache-2.0

unit Telegram4D.Http;

{ HTTP transport abstraction.
  Telegram4D talks to ITgHttpClient only. The default implementation uses
  System.Net.HttpClient on Delphi and fphttpclient (+ opensslsockets) on Free Pascal.
  To use another stack (RESTRequest4Delphi, Indy, Synapse...) implement ITgHttpClient
  and assign it to TTelegramBot.HttpClient. }

{$I Telegram4D.inc}

interface

uses
  Classes, SysUtils;

type
  TTgFormField = record
    Name: string;
    Value: string;
  end;
  TTgFormFields = array of TTgFormField;

  TTgUpload = record
    Field: string;
    FileName: string;
    ContentType: string;
    Stream: TStream;   // not owned
  end;
  TTgUploads = array of TTgUpload;

  ITgHttpClient = interface
    ['{7B1A2C54-31E5-4C7B-9A0D-5C9E7F0A1B11}']
    function PostJson(const AUrl, ABody: string; ATimeoutMs: Integer): string;
    function PostMultipart(const AUrl: string; const AFields: TTgFormFields;
      const AUploads: TTgUploads; ATimeoutMs: Integer): string;
    procedure Download(const AUrl: string; ADest: TStream; ATimeoutMs: Integer);
  end;

  TTgDefaultHttpClient = class(TInterfacedObject, ITgHttpClient)
  private
    FProxyHost: string;
    FProxyPort: Integer;
    function Execute(const AMethod, AUrl: string; ABody, AResponse: TStream;
      const AContentType: string; ATimeoutMs: Integer): Integer;
  public
    constructor Create(const AProxyHost: string = ''; AProxyPort: Integer = 0);
    function PostJson(const AUrl, ABody: string; ATimeoutMs: Integer): string;
    function PostMultipart(const AUrl: string; const AFields: TTgFormFields;
      const AUploads: TTgUploads; ATimeoutMs: Integer): string;
    procedure Download(const AUrl: string; ADest: TStream; ATimeoutMs: Integer);
  end;

function CreateDefaultHttpClient(const AProxyHost: string = '';
  AProxyPort: Integer = 0): ITgHttpClient;

implementation

uses
{$IFDEF FPC}
  fphttpclient, opensslsockets,
{$ELSE}
  System.Net.HttpClient, System.Net.URLClient,
{$ENDIF}
  Telegram4D.Consts, Telegram4D.Errors;

procedure WriteUtf8(AStream: TStream; const AText: string);
var
  B: TBytes;
begin
  B := TEncoding.UTF8.GetBytes(AText);
  if Length(B) > 0 then
    AStream.WriteBuffer(B[0], Length(B));
end;

function StreamToUtf8(AStream: TStream): string;
var
  B: TBytes;
begin
  SetLength(B, AStream.Size);
  if Length(B) > 0 then
  begin
    AStream.Position := 0;
    AStream.ReadBuffer(B[0], Length(B));
  end;
  Result := TEncoding.UTF8.GetString(B);
end;

function BuildMultipart(const AFields: TTgFormFields; const AUploads: TTgUploads;
  out ABoundary: string): TMemoryStream;
var
  I: Integer;
  CT: string;
begin
  ABoundary := '----Telegram4D' + IntToHex(Random($7FFFFFFF), 8) + IntToHex(Random($7FFFFFFF), 8);
  Result := TMemoryStream.Create;
  try
    for I := 0 to High(AFields) do
    begin
      WriteUtf8(Result, '--' + ABoundary + #13#10 +
        'Content-Disposition: form-data; name="' + AFields[I].Name + '"' + #13#10#13#10 +
        AFields[I].Value + #13#10);
    end;
    for I := 0 to High(AUploads) do
    begin
      CT := AUploads[I].ContentType;
      if CT = '' then
        CT := 'application/octet-stream';
      WriteUtf8(Result, '--' + ABoundary + #13#10 +
        'Content-Disposition: form-data; name="' + AUploads[I].Field +
        '"; filename="' + StringReplace(AUploads[I].FileName, '"', '%22', [rfReplaceAll]) + '"' + #13#10 +
        'Content-Type: ' + CT + #13#10#13#10);
      Result.CopyFrom(AUploads[I].Stream, 0);
      WriteUtf8(Result, #13#10);
    end;
    WriteUtf8(Result, '--' + ABoundary + '--' + #13#10);
    Result.Position := 0;
  except
    Result.Free;
    raise;
  end;
end;

{ TTgDefaultHttpClient }

constructor TTgDefaultHttpClient.Create(const AProxyHost: string; AProxyPort: Integer);
begin
  inherited Create;
  FProxyHost := AProxyHost;
  FProxyPort := AProxyPort;
end;

function TTgDefaultHttpClient.Execute(const AMethod, AUrl: string; ABody, AResponse: TStream;
  const AContentType: string; ATimeoutMs: Integer): Integer;
{$IFDEF FPC}
const
  OK_CODES: array[0..11] of Integer = (200, 201, 400, 401, 403, 404, 409, 420, 429, 500, 502, 503);
var
  C: TFPHTTPClient;
begin
  Result := 0;
  try
    C := TFPHTTPClient.Create(nil);
    try
      C.ConnectTimeout := 20000;
      C.IOTimeout := ATimeoutMs;
      C.AllowRedirect := True;
      C.AddHeader('User-Agent', 'Telegram4D/' + TELEGRAM4D_VERSION);
      if FProxyHost <> '' then
      begin
        C.Proxy.Host := FProxyHost;
        C.Proxy.Port := FProxyPort;
      end;
      if ABody <> nil then
      begin
        C.AddHeader('Content-Type', AContentType);
        ABody.Position := 0;
        C.RequestBody := ABody;
      end;
      try
        C.HTTPMethod(AMethod, AUrl, AResponse, OK_CODES);
      finally
        C.RequestBody := nil;
      end;
      Result := C.ResponseStatusCode;
    finally
      C.Free;
    end;
  except
    on E: Exception do
      raise ETelegramNetworkError.Create(E.Message);
  end;
end;
{$ELSE}
var
  C: THTTPClient;
  R: IHTTPResponse;
begin
  try
    C := THTTPClient.Create;
    try
      C.ConnectionTimeout := 20000;
      C.ResponseTimeout := ATimeoutMs;
      C.UserAgent := 'Telegram4D/' + TELEGRAM4D_VERSION;
      if FProxyHost <> '' then
        C.ProxySettings := TProxySettings.Create(FProxyHost, FProxyPort);
      if ABody <> nil then
      begin
        C.ContentType := AContentType;
        ABody.Position := 0;
        R := C.Post(AUrl, ABody, AResponse);
      end
      else
        R := C.Get(AUrl, AResponse);
      Result := R.StatusCode;
    finally
      C.Free;
    end;
  except
    on E: Exception do
      raise ETelegramNetworkError.Create(E.Message);
  end;
end;
{$ENDIF}

function TTgDefaultHttpClient.PostJson(const AUrl, ABody: string; ATimeoutMs: Integer): string;
var
  Req, Resp: TMemoryStream;
begin
  Req := TMemoryStream.Create;
  Resp := TMemoryStream.Create;
  try
    WriteUtf8(Req, ABody);
    Execute('POST', AUrl, Req, Resp, 'application/json', ATimeoutMs);
    Result := StreamToUtf8(Resp);
  finally
    Resp.Free;
    Req.Free;
  end;
end;

function TTgDefaultHttpClient.PostMultipart(const AUrl: string; const AFields: TTgFormFields;
  const AUploads: TTgUploads; ATimeoutMs: Integer): string;
var
  Req, Resp: TMemoryStream;
  Boundary: string;
begin
  Req := BuildMultipart(AFields, AUploads, Boundary);
  Resp := TMemoryStream.Create;
  try
    Execute('POST', AUrl, Req, Resp, 'multipart/form-data; boundary=' + Boundary, ATimeoutMs);
    Result := StreamToUtf8(Resp);
  finally
    Resp.Free;
    Req.Free;
  end;
end;

procedure TTgDefaultHttpClient.Download(const AUrl: string; ADest: TStream; ATimeoutMs: Integer);
var
  Code: Integer;
begin
  Code := Execute('GET', AUrl, nil, ADest, '', ATimeoutMs);
  if Code <> 200 then
    raise ETelegramNetworkError.CreateFmt('Download failed, HTTP status %d', [Code]);
end;

function CreateDefaultHttpClient(const AProxyHost: string; AProxyPort: Integer): ITgHttpClient;
begin
  Result := TTgDefaultHttpClient.Create(AProxyHost, AProxyPort);
end;

initialization
  Randomize;

end.
