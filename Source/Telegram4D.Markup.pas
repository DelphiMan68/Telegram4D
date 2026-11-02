// Telegram4D - Telegram Bot API library for Delphi and Free Pascal
// Copyright 2026 Shaahin Ashayeri (https://github.com/DelphiMan68)
// SPDX-License-Identifier: Apache-2.0

unit Telegram4D.Markup;

{ Fluent builders for reply markups. All builders are interface based, so there is
  nothing to free:

    Bot.SendMessage(ChatId, 'Choose:',
      InlineKeyboard
        .Button('Yes', 'yes').Button('No', 'no')
        .Row
        .Url('Docs', 'https://core.telegram.org/bots/api'));
}

{$I Telegram4D.inc}

interface

uses
  Classes, SysUtils, Telegram4D.JSON;

type
  ITgReplyMarkup = interface
    ['{2F0C6B1E-4D0A-4A57-9B44-1B7C51D5A001}']
    function ToJSON: string;
  end;

  ITgInlineKeyboard = interface(ITgReplyMarkup)
    ['{2F0C6B1E-4D0A-4A57-9B44-1B7C51D5A002}']
    function Button(const AText, ACallbackData: string): ITgInlineKeyboard;
    function Url(const AText, AUrl: string): ITgInlineKeyboard;
    function WebApp(const AText, AUrl: string): ITgInlineKeyboard;
    function SwitchInline(const AText, AQuery: string; ACurrentChat: Boolean = False): ITgInlineKeyboard;
    /// Sets an extra field on the last button (forward compatibility with new Bot API fields).
    function Extra(const AName, AValue: string): ITgInlineKeyboard;
    /// Starts a new row.
    function Row: ITgInlineKeyboard;
  end;

  ITgReplyKeyboard = interface(ITgReplyMarkup)
    ['{2F0C6B1E-4D0A-4A57-9B44-1B7C51D5A003}']
    function Button(const AText: string): ITgReplyKeyboard;
    function RequestContact(const AText: string): ITgReplyKeyboard;
    function RequestLocation(const AText: string): ITgReplyKeyboard;
    function WebApp(const AText, AUrl: string): ITgReplyKeyboard;
    function Extra(const AName, AValue: string): ITgReplyKeyboard;
    function Row: ITgReplyKeyboard;
    function Resize(AValue: Boolean = True): ITgReplyKeyboard;
    function OneTime(AValue: Boolean = True): ITgReplyKeyboard;
    function Persistent(AValue: Boolean = True): ITgReplyKeyboard;
    function Placeholder(const AText: string): ITgReplyKeyboard;
    function Selective(AValue: Boolean = True): ITgReplyKeyboard;
  end;

function InlineKeyboard: ITgInlineKeyboard;
function ReplyKeyboard: ITgReplyKeyboard;
function RemoveKeyboard(ASelective: Boolean = False): ITgReplyMarkup;
function ForceReply(const APlaceholder: string = ''): ITgReplyMarkup;

implementation

type
  TTgKeyboardBase = class(TInterfacedObject, ITgReplyMarkup)
  protected
    FRoot: TJsonObject;
    FRows: TJsonArray;
    FRow: TJsonArray;
    FLast: TJsonObject;
    function AddButton(const AText: string): TJsonObject;
    procedure DoRow;
    procedure DoExtra(const AName, AValue: string);
  public
    constructor Create(const ARowsName: string);
    destructor Destroy; override;
    function ToJSON: string;
  end;

  TTgInlineKeyboardImpl = class(TTgKeyboardBase, ITgInlineKeyboard)
  public
    constructor Create;
    function Button(const AText, ACallbackData: string): ITgInlineKeyboard;
    function Url(const AText, AUrl: string): ITgInlineKeyboard;
    function WebApp(const AText, AUrl: string): ITgInlineKeyboard;
    function SwitchInline(const AText, AQuery: string; ACurrentChat: Boolean): ITgInlineKeyboard;
    function Extra(const AName, AValue: string): ITgInlineKeyboard;
    function Row: ITgInlineKeyboard;
  end;

  TTgReplyKeyboardImpl = class(TTgKeyboardBase, ITgReplyKeyboard)
  public
    constructor Create;
    function Button(const AText: string): ITgReplyKeyboard;
    function RequestContact(const AText: string): ITgReplyKeyboard;
    function RequestLocation(const AText: string): ITgReplyKeyboard;
    function WebApp(const AText, AUrl: string): ITgReplyKeyboard;
    function Extra(const AName, AValue: string): ITgReplyKeyboard;
    function Row: ITgReplyKeyboard;
    function Resize(AValue: Boolean): ITgReplyKeyboard;
    function OneTime(AValue: Boolean): ITgReplyKeyboard;
    function Persistent(AValue: Boolean): ITgReplyKeyboard;
    function Placeholder(const AText: string): ITgReplyKeyboard;
    function Selective(AValue: Boolean): ITgReplyKeyboard;
  end;

  TTgStaticMarkup = class(TInterfacedObject, ITgReplyMarkup)
  private
    FText: string;
  public
    constructor Create(const AText: string);
    function ToJSON: string;
  end;

{ TTgKeyboardBase }

constructor TTgKeyboardBase.Create(const ARowsName: string);
begin
  inherited Create;
  FRoot := TJsonObject.Create;
  FRows := FRoot.A[ARowsName];
end;

destructor TTgKeyboardBase.Destroy;
begin
  FRoot.Free;
  inherited;
end;

function TTgKeyboardBase.AddButton(const AText: string): TJsonObject;
begin
  if FRow = nil then
    FRow := FRows.AddArray;
  FLast := FRow.AddObject;
  FLast.S['text'] := AText;
  Result := FLast;
end;

procedure TTgKeyboardBase.DoRow;
begin
  FRow := nil;
end;

procedure TTgKeyboardBase.DoExtra(const AName, AValue: string);
begin
  if FLast <> nil then
    FLast.S[AName] := AValue;
end;

function TTgKeyboardBase.ToJSON: string;
begin
  Result := FRoot.ToJSON(True);
end;

{ TTgInlineKeyboardImpl }

constructor TTgInlineKeyboardImpl.Create;
begin
  inherited Create('inline_keyboard');
end;

function TTgInlineKeyboardImpl.Button(const AText, ACallbackData: string): ITgInlineKeyboard;
begin
  AddButton(AText).S['callback_data'] := ACallbackData;
  Result := Self;
end;

function TTgInlineKeyboardImpl.Url(const AText, AUrl: string): ITgInlineKeyboard;
begin
  AddButton(AText).S['url'] := AUrl;
  Result := Self;
end;

function TTgInlineKeyboardImpl.WebApp(const AText, AUrl: string): ITgInlineKeyboard;
begin
  AddButton(AText).O['web_app'].S['url'] := AUrl;
  Result := Self;
end;

function TTgInlineKeyboardImpl.SwitchInline(const AText, AQuery: string;
  ACurrentChat: Boolean): ITgInlineKeyboard;
begin
  if ACurrentChat then
    AddButton(AText).S['switch_inline_query_current_chat'] := AQuery
  else
    AddButton(AText).S['switch_inline_query'] := AQuery;
  Result := Self;
end;

function TTgInlineKeyboardImpl.Extra(const AName, AValue: string): ITgInlineKeyboard;
begin
  DoExtra(AName, AValue);
  Result := Self;
end;

function TTgInlineKeyboardImpl.Row: ITgInlineKeyboard;
begin
  DoRow;
  Result := Self;
end;

{ TTgReplyKeyboardImpl }

constructor TTgReplyKeyboardImpl.Create;
begin
  inherited Create('keyboard');
end;

function TTgReplyKeyboardImpl.Button(const AText: string): ITgReplyKeyboard;
begin
  AddButton(AText);
  Result := Self;
end;

function TTgReplyKeyboardImpl.RequestContact(const AText: string): ITgReplyKeyboard;
begin
  AddButton(AText).B['request_contact'] := True;
  Result := Self;
end;

function TTgReplyKeyboardImpl.RequestLocation(const AText: string): ITgReplyKeyboard;
begin
  AddButton(AText).B['request_location'] := True;
  Result := Self;
end;

function TTgReplyKeyboardImpl.WebApp(const AText, AUrl: string): ITgReplyKeyboard;
begin
  AddButton(AText).O['web_app'].S['url'] := AUrl;
  Result := Self;
end;

function TTgReplyKeyboardImpl.Extra(const AName, AValue: string): ITgReplyKeyboard;
begin
  DoExtra(AName, AValue);
  Result := Self;
end;

function TTgReplyKeyboardImpl.Row: ITgReplyKeyboard;
begin
  DoRow;
  Result := Self;
end;

function TTgReplyKeyboardImpl.Resize(AValue: Boolean): ITgReplyKeyboard;
begin
  FRoot.B['resize_keyboard'] := AValue;
  Result := Self;
end;

function TTgReplyKeyboardImpl.OneTime(AValue: Boolean): ITgReplyKeyboard;
begin
  FRoot.B['one_time_keyboard'] := AValue;
  Result := Self;
end;

function TTgReplyKeyboardImpl.Persistent(AValue: Boolean): ITgReplyKeyboard;
begin
  FRoot.B['is_persistent'] := AValue;
  Result := Self;
end;

function TTgReplyKeyboardImpl.Placeholder(const AText: string): ITgReplyKeyboard;
begin
  FRoot.S['input_field_placeholder'] := AText;
  Result := Self;
end;

function TTgReplyKeyboardImpl.Selective(AValue: Boolean): ITgReplyKeyboard;
begin
  FRoot.B['selective'] := AValue;
  Result := Self;
end;

{ TTgStaticMarkup }

constructor TTgStaticMarkup.Create(const AText: string);
begin
  inherited Create;
  FText := AText;
end;

function TTgStaticMarkup.ToJSON: string;
begin
  Result := FText;
end;

{ factories }

function InlineKeyboard: ITgInlineKeyboard;
begin
  Result := TTgInlineKeyboardImpl.Create;
end;

function ReplyKeyboard: ITgReplyKeyboard;
begin
  Result := TTgReplyKeyboardImpl.Create;
end;

function RemoveKeyboard(ASelective: Boolean): ITgReplyMarkup;
begin
  if ASelective then
    Result := TTgStaticMarkup.Create('{"remove_keyboard":true,"selective":true}')
  else
    Result := TTgStaticMarkup.Create('{"remove_keyboard":true}');
end;

function ForceReply(const APlaceholder: string): ITgReplyMarkup;
var
  O: TJsonObject;
begin
  O := TJsonObject.Create;
  try
    O.B['force_reply'] := True;
    if APlaceholder <> '' then
      O.S['input_field_placeholder'] := APlaceholder;
    Result := TTgStaticMarkup.Create(O.ToJSON(True));
  finally
    O.Free;
  end;
end;

end.
