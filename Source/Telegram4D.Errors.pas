// Telegram4D - Telegram Bot API library for Delphi and Free Pascal
// Copyright 2026 Shaahin Ashayeri (https://github.com/DelphiMan68)
// SPDX-License-Identifier: Apache-2.0

unit Telegram4D.Errors;

{$I Telegram4D.inc}

interface

uses
  SysUtils;

type
  ETelegram4D = class(Exception);

  /// Transport problem: no network, timeout, TLS failure, non-JSON answer...
  ETelegramNetworkError = class(ETelegram4D);

  /// The Bot API answered with ok=false.
  ETelegramApiError = class(ETelegram4D)
  private
    FErrorCode: Integer;
    FDescription: string;
    FRetryAfter: Integer;
    FMigrateToChatId: Int64;
  public
    constructor Create(AErrorCode: Integer; const ADescription: string;
      ARetryAfter: Integer = 0; AMigrateToChatId: Int64 = 0); reintroduce;
    function IsRateLimited: Boolean;   // 429, see RetryAfter (seconds)
    function IsUnauthorized: Boolean;  // 401, wrong token
    function IsForbidden: Boolean;     // 403, e.g. bot was blocked by the user
    function IsConflict: Boolean;      // 409, another getUpdates / webhook active
    property ErrorCode: Integer read FErrorCode;
    property Description: string read FDescription;
    property RetryAfter: Integer read FRetryAfter;
    property MigrateToChatId: Int64 read FMigrateToChatId;
  end;

implementation

constructor ETelegramApiError.Create(AErrorCode: Integer; const ADescription: string;
  ARetryAfter: Integer; AMigrateToChatId: Int64);
begin
  inherited CreateFmt('Telegram API error %d: %s', [AErrorCode, ADescription]);
  FErrorCode := AErrorCode;
  FDescription := ADescription;
  FRetryAfter := ARetryAfter;
  FMigrateToChatId := AMigrateToChatId;
end;

function ETelegramApiError.IsRateLimited: Boolean;
begin
  Result := FErrorCode = 429;
end;

function ETelegramApiError.IsUnauthorized: Boolean;
begin
  Result := FErrorCode = 401;
end;

function ETelegramApiError.IsForbidden: Boolean;
begin
  Result := FErrorCode = 403;
end;

function ETelegramApiError.IsConflict: Boolean;
begin
  Result := FErrorCode = 409;
end;

end.
