// Telegram4D - Telegram Bot API library for Delphi and Free Pascal
// Copyright 2026 Shaahin Ashayeri (https://github.com/DelphiMan68)
// SPDX-License-Identifier: Apache-2.0

unit Telegram4D.Utils;

{ Small helpers for building message text. }

{$I Telegram4D.inc}

interface

uses
  SysUtils;

/// Escapes & < > for parse_mode = HTML. Always use it for user supplied text.
function HtmlEscape(const AText: string): string;

/// Escapes every reserved character for parse_mode = MarkdownV2.
function MarkdownV2Escape(const AText: string): string;

/// <a href="tg://user?id=...">name</a> - a clickable mention (parse_mode = HTML).
function MentionHtml(AUserId: Int64; const AName: string): string;

implementation

function HtmlEscape(const AText: string): string;
begin
  Result := StringReplace(AText, '&', '&amp;', [rfReplaceAll]);
  Result := StringReplace(Result, '<', '&lt;', [rfReplaceAll]);
  Result := StringReplace(Result, '>', '&gt;', [rfReplaceAll]);
end;

function MarkdownV2Escape(const AText: string): string;
const
  SPECIAL = '_*[]()~`>#+-=|{}.!\';
var
  I: Integer;
begin
  Result := '';
  for I := 1 to Length(AText) do
    if Pos(AText[I], SPECIAL) > 0 then
      Result := Result + '\' + AText[I]
    else
      Result := Result + AText[I];
end;

function MentionHtml(AUserId: Int64; const AName: string): string;
begin
  Result := '<a href="tg://user?id=' + IntToStr(AUserId) + '">' + HtmlEscape(AName) + '</a>';
end;

end.
