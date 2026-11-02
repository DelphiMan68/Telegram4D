// Telegram4D - Telegram Bot API library for Delphi and Free Pascal
// Copyright 2026 Shaahin Ashayeri (https://github.com/DelphiMan68)
// SPDX-License-Identifier: Apache-2.0

unit Telegram4D.JSON;

{ Thin indirection over JsonDataObjects (https://github.com/ahausladen/JsonDataObjects).
  Every other Telegram4D unit takes its JSON types from here, so the JSON backend
  lives in exactly one place. }

{$I Telegram4D.inc}

interface

uses
  JsonDataObjects;

type
  TJsonBaseObject = JsonDataObjects.TJsonBaseObject;
  TJsonObject     = JsonDataObjects.TJsonObject;
  TJsonArray      = JsonDataObjects.TJsonArray;

/// Parses AText and returns the root object (caller owns it). Raises ETelegramNetworkError
/// if the text is not a JSON object.
function ParseJsonObject(const AText: string): TJsonObject;

implementation

uses
  SysUtils, Telegram4D.Errors;

function ParseJsonObject(const AText: string): TJsonObject;
var
  B: TJsonBaseObject;
begin
  try
    B := TJsonBaseObject.Parse(AText);
  except
    on E: Exception do
      raise ETelegramNetworkError.Create('Invalid JSON received: ' + E.Message);
  end;
  if B is TJsonObject then
    Result := TJsonObject(B)
  else
  begin
    B.Free;
    raise ETelegramNetworkError.Create('JSON object expected');
  end;
end;

end.
