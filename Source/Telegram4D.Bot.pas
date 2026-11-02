// Telegram4D - Telegram Bot API library for Delphi and Free Pascal
// Copyright 2026 Shaahin Ashayeri (https://github.com/DelphiMan68)
// SPDX-License-Identifier: Apache-2.0

unit Telegram4D.Bot;

{ TTelegramBot - the Bot API client.

  Typed wrappers cover the common methods; Call / CallBool / CallMessage reach every
  other method (and every future one) without waiting for a library update:

    Bot.CallBool('setChatTitle', NewParams.AddChat('chat_id', ChatId).Add('title', 'New'));

  Ownership: objects returned by Send*/Get*/Call* (TTgMessage, TTgChat, TTgList ...)
  must be freed by the caller. SendText is the fire-and-forget shortcut (returns the
  message_id, nothing to free). }

{$I Telegram4D.inc}

interface

uses
  Classes, SysUtils, Telegram4D.Consts, Telegram4D.Errors, Telegram4D.JSON,
  Telegram4D.Http, Telegram4D.Markup, Telegram4D.Params, Telegram4D.Types;

type
  TTgLogEvent = procedure(Sender: TObject; const AMessage: string) of object;

  TTgBotCommand = record
    Command: string;
    Description: string;
  end;

  TTelegramBot = class(TComponent)
  private
    FToken: string;
    FApiUrl: string;
    FParseMode: string;
    FTimeoutMs: Integer;
    FRetryOnRateLimit: Boolean;
    FHttp: ITgHttpClient;
    FOnLog: TTgLogEvent;
    function GetHttp: ITgHttpClient;
    function MethodUrl(const AMethod: string): string;
    function FileUrl(const AFilePath: string): string;
    function DoCall(const AMethod: string; const AParams: ITgParams;
      ATimeoutMs: Integer): TJsonObject;
    function ParseModeOr(const AParseMode: string): string;
    procedure Decorate(const P: ITgParams; const AMarkup: ITgReplyMarkup;
      const AParseMode: string; AReplyTo, AThreadId: Int64);
    function SendMedia(const AMethod, AField: string; const AChatId: TTgChatId;
      const AMedia: TTgInputFile; const ACaption: string; const AMarkup: ITgReplyMarkup;
      const AParseMode: string; AReplyTo, AThreadId: Int64): TTgMessage;
  public
    procedure Log(const AText: string);
    constructor Create(AOwner: TComponent); override;
    class function New(const AToken: string; const AProxyHost: string = '';
      AProxyPort: Integer = 0): TTelegramBot;

    procedure SetProxy(const AHost: string; APort: Integer);

    { ---- generic access: works for every Bot API method ---- }
    /// Returns the whole response root (caller frees). Raises ETelegramApiError on ok=false.
    function Call(const AMethod: string; const AParams: ITgParams = nil): TJsonObject;
    function CallTimeout(const AMethod: string; const AParams: ITgParams;
      ATimeoutMs: Integer): TJsonObject;
    function CallBool(const AMethod: string; const AParams: ITgParams = nil): Boolean;
    function CallMessage(const AMethod: string; const AParams: ITgParams = nil): TTgMessage;
    function CallObject(AClass: TTgObjectClass; const AMethod: string;
      const AParams: ITgParams = nil): TTgObject;
    function CallList(AClass: TTgObjectClass; const AMethod: string;
      const AParams: ITgParams = nil): TTgList;

    { ---- bot / updates ---- }
    function GetMe: TTgUser;
    function LogOut: Boolean;
    function GetUpdates(AOffset: Int64 = 0; ALimit: Integer = 100; ATimeoutSec: Integer = 0;
      const AAllowedUpdates: string = ''): TTgUpdateList;
    function SetWebhook(const AUrl: string; const ASecretToken: string = '';
      ADropPendingUpdates: Boolean = False; AMaxConnections: Integer = 0;
      const AAllowedUpdates: string = ''): Boolean;
    function DeleteWebhook(ADropPendingUpdates: Boolean = False): Boolean;
    function GetWebhookInfo: TTgWebhookInfo;

    { ---- sending ---- }
    function SendMessage(const AChatId: TTgChatId; const AText: string;
      const AMarkup: ITgReplyMarkup = nil; const AParseMode: string = '';
      AReplyTo: Int64 = 0; AThreadId: Int64 = 0): TTgMessage;
    /// Fire and forget: returns message_id.
    function SendText(const AChatId: TTgChatId; const AText: string;
      const AMarkup: ITgReplyMarkup = nil; const AParseMode: string = ''): Int64;
    function SendPhoto(const AChatId: TTgChatId; const APhoto: TTgInputFile;
      const ACaption: string = ''; const AMarkup: ITgReplyMarkup = nil;
      const AParseMode: string = ''; AReplyTo: Int64 = 0; AThreadId: Int64 = 0): TTgMessage;
    function SendDocument(const AChatId: TTgChatId; const ADocument: TTgInputFile;
      const ACaption: string = ''; const AMarkup: ITgReplyMarkup = nil;
      const AParseMode: string = ''; AReplyTo: Int64 = 0; AThreadId: Int64 = 0): TTgMessage;
    function SendVideo(const AChatId: TTgChatId; const AVideo: TTgInputFile;
      const ACaption: string = ''; const AMarkup: ITgReplyMarkup = nil;
      const AParseMode: string = ''; AReplyTo: Int64 = 0; AThreadId: Int64 = 0): TTgMessage;
    function SendAudio(const AChatId: TTgChatId; const AAudio: TTgInputFile;
      const ACaption: string = ''; const AMarkup: ITgReplyMarkup = nil;
      const AParseMode: string = ''; AReplyTo: Int64 = 0; AThreadId: Int64 = 0): TTgMessage;
    function SendVoice(const AChatId: TTgChatId; const AVoice: TTgInputFile;
      const ACaption: string = ''; const AMarkup: ITgReplyMarkup = nil;
      const AParseMode: string = ''; AReplyTo: Int64 = 0; AThreadId: Int64 = 0): TTgMessage;
    function SendAnimation(const AChatId: TTgChatId; const AAnimation: TTgInputFile;
      const ACaption: string = ''; const AMarkup: ITgReplyMarkup = nil;
      const AParseMode: string = ''; AReplyTo: Int64 = 0; AThreadId: Int64 = 0): TTgMessage;
    function SendVideoNote(const AChatId: TTgChatId; const AVideoNote: TTgInputFile;
      const AMarkup: ITgReplyMarkup = nil; AReplyTo: Int64 = 0; AThreadId: Int64 = 0): TTgMessage;
    function SendSticker(const AChatId: TTgChatId; const ASticker: TTgInputFile;
      const AMarkup: ITgReplyMarkup = nil; AReplyTo: Int64 = 0; AThreadId: Int64 = 0): TTgMessage;
    function SendLocation(const AChatId: TTgChatId; ALatitude, ALongitude: Double;
      const AMarkup: ITgReplyMarkup = nil; AReplyTo: Int64 = 0): TTgMessage;
    function SendContact(const AChatId: TTgChatId; const APhone, AFirstName: string;
      const ALastName: string = ''; const AMarkup: ITgReplyMarkup = nil): TTgMessage;
    function SendPoll(const AChatId: TTgChatId; const AQuestion: string;
      const AOptions: array of string; AIsAnonymous: Boolean = True): TTgMessage;
    function SendDice(const AChatId: TTgChatId; const AEmoji: string = ''): TTgMessage;
    function SendChatAction(const AChatId: TTgChatId; const AAction: string = ACTION_TYPING): Boolean;
    function ForwardMessage(const AChatId, AFromChatId: TTgChatId; AMessageId: Int64): TTgMessage;
    /// copyMessage returns only the new message_id.
    function CopyMessage(const AChatId, AFromChatId: TTgChatId; AMessageId: Int64): Int64;

    { ---- editing / deleting ---- }
    function EditMessageText(const AChatId: TTgChatId; AMessageId: Int64; const AText: string;
      const AMarkup: ITgReplyMarkup = nil; const AParseMode: string = ''): TTgMessage;
    function EditInlineMessageText(const AInlineMessageId, AText: string;
      const AMarkup: ITgReplyMarkup = nil; const AParseMode: string = ''): Boolean;
    function EditMessageCaption(const AChatId: TTgChatId; AMessageId: Int64;
      const ACaption: string; const AMarkup: ITgReplyMarkup = nil;
      const AParseMode: string = ''): TTgMessage;
    function EditMessageReplyMarkup(const AChatId: TTgChatId; AMessageId: Int64;
      const AMarkup: ITgReplyMarkup): TTgMessage;
    function DeleteMessage(const AChatId: TTgChatId; AMessageId: Int64): Boolean;
    function PinChatMessage(const AChatId: TTgChatId; AMessageId: Int64;
      ANotify: Boolean = True): Boolean;
    function UnpinChatMessage(const AChatId: TTgChatId; AMessageId: Int64 = 0): Boolean;

    { ---- callbacks / inline / payments ---- }
    function AnswerCallbackQuery(const AId: string; const AText: string = '';
      AShowAlert: Boolean = False; const AUrl: string = ''; ACacheTime: Integer = 0): Boolean;
    /// AResultsJson is a JSON array of InlineQueryResult objects.
    function AnswerInlineQuery(const AId, AResultsJson: string; ACacheTime: Integer = 300;
      AIsPersonal: Boolean = False; const ANextOffset: string = ''): Boolean;
    function AnswerPreCheckoutQuery(const AId: string; AOk: Boolean;
      const AErrorMessage: string = ''): Boolean;

    { ---- chats ---- }
    function GetChat(const AChatId: TTgChatId): TTgChat;
    function GetChatMember(const AChatId: TTgChatId; AUserId: Int64): TTgChatMember;
    function GetChatMemberCount(const AChatId: TTgChatId): Int64;
    function GetChatAdministrators(const AChatId: TTgChatId): TTgList;
    function BanChatMember(const AChatId: TTgChatId; AUserId: Int64;
      AUntilUnixTime: Int64 = 0; ARevokeMessages: Boolean = False): Boolean;
    function UnbanChatMember(const AChatId: TTgChatId; AUserId: Int64;
      AOnlyIfBanned: Boolean = True): Boolean;
    function LeaveChat(const AChatId: TTgChatId): Boolean;
    function ApproveChatJoinRequest(const AChatId: TTgChatId; AUserId: Int64): Boolean;
    function DeclineChatJoinRequest(const AChatId: TTgChatId; AUserId: Int64): Boolean;

    { ---- commands ---- }
    function SetMyCommands(const ACommands: array of TTgBotCommand;
      const ALanguageCode: string = ''): Boolean;
    function DeleteMyCommands: Boolean;

    { ---- files ---- }
    function GetFile(const AFileId: string): TTgFileInfo;
    procedure DownloadFile(const AFileId: string; ADest: TStream);
    procedure DownloadFileTo(const AFileId, ALocalPath: string);

    /// Replace the transport (e.g. a RESTRequest4Delphi based ITgHttpClient).
    property HttpClient: ITgHttpClient read GetHttp write FHttp;
  published
    property Token: string read FToken write FToken;
    /// Change to use a local Bot API server or a reverse proxy.
    property ApiUrl: string read FApiUrl write FApiUrl;
    /// Used when a call does not pass its own parse mode (e.g. 'HTML').
    property DefaultParseMode: string read FParseMode write FParseMode;
    property TimeoutMs: Integer read FTimeoutMs write FTimeoutMs default 30000;
    /// Sleeps and retries (max 3 attempts) on HTTP 429 when retry_after <= 60 s.
    property RetryOnRateLimit: Boolean read FRetryOnRateLimit write FRetryOnRateLimit default True;
    property OnLog: TTgLogEvent read FOnLog write FOnLog;
  end;

function BotCommand(const ACommand, ADescription: string): TTgBotCommand;

implementation

function BotCommand(const ACommand, ADescription: string): TTgBotCommand;
begin
  Result.Command := ACommand;
  Result.Description := ADescription;
end;

{ TTelegramBot }

constructor TTelegramBot.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FApiUrl := TELEGRAM_API_URL;
  FTimeoutMs := 30000;
  FRetryOnRateLimit := True;
end;

class function TTelegramBot.New(const AToken, AProxyHost: string; AProxyPort: Integer): TTelegramBot;
begin
  Result := TTelegramBot.Create(nil);
  Result.Token := AToken;
  if AProxyHost <> '' then
    Result.SetProxy(AProxyHost, AProxyPort);
end;

procedure TTelegramBot.SetProxy(const AHost: string; APort: Integer);
begin
  FHttp := CreateDefaultHttpClient(AHost, APort);
end;

function TTelegramBot.GetHttp: ITgHttpClient;
begin
  if FHttp = nil then
    FHttp := CreateDefaultHttpClient;
  Result := FHttp;
end;

procedure TTelegramBot.Log(const AText: string);
begin
  if Assigned(FOnLog) then
    FOnLog(Self, AText);
end;

function TTelegramBot.MethodUrl(const AMethod: string): string;
begin
  Result := FApiUrl + '/bot' + FToken + '/' + AMethod;
end;

function TTelegramBot.FileUrl(const AFilePath: string): string;
begin
  Result := FApiUrl + '/file/bot' + FToken + '/' + AFilePath;
end;

function TTelegramBot.ParseModeOr(const AParseMode: string): string;
begin
  if AParseMode <> '' then
    Result := AParseMode
  else
    Result := FParseMode;
end;

procedure TTelegramBot.Decorate(const P: ITgParams; const AMarkup: ITgReplyMarkup;
  const AParseMode: string; AReplyTo, AThreadId: Int64);
begin
  P.AddOpt('parse_mode', ParseModeOr(AParseMode));
  P.AddMarkup(AMarkup);
  P.AddOptInt('message_thread_id', AThreadId);
  if AReplyTo <> 0 then
    P.AddJson('reply_parameters',
      Format('{"message_id":%d,"allow_sending_without_reply":true}', [AReplyTo]));
end;

{ ---- core call ---- }

function TTelegramBot.DoCall(const AMethod: string; const AParams: ITgParams;
  ATimeoutMs: Integer): TJsonObject;
var
  Url, Resp: string;
  RetryAfter: Integer;
  Migrate: Int64;
begin
  if FToken = '' then
    raise ETelegram4D.Create('Telegram4D: Token is empty');
  Url := MethodUrl(AMethod);
  if AParams = nil then
    Resp := GetHttp.PostJson(Url, '{}', ATimeoutMs)
  else if Length(AParams.Uploads) > 0 then
    Resp := GetHttp.PostMultipart(Url, AParams.Fields, AParams.Uploads, ATimeoutMs)
  else
    Resp := GetHttp.PostJson(Url, AParams.Json.ToJSON(True), ATimeoutMs);

  Result := ParseJsonObject(Resp);
  if not Result.B['ok'] then
  begin
    try
      RetryAfter := 0;
      Migrate := 0;
      if Result.Contains('parameters') then
      begin
        RetryAfter := Result.O['parameters'].L['retry_after'];
        Migrate := Result.O['parameters'].L['migrate_to_chat_id'];
      end;
      raise ETelegramApiError.Create(Result.L['error_code'], Result.S['description'],
        RetryAfter, Migrate);
    finally
      Result.Free;
    end;
  end;
end;

function TTelegramBot.CallTimeout(const AMethod: string; const AParams: ITgParams;
  ATimeoutMs: Integer): TJsonObject;
var
  Attempt: Integer;
begin
  Attempt := 0;
  while True do
  begin
    Inc(Attempt);
    try
      Result := DoCall(AMethod, AParams, ATimeoutMs);
      Exit;
    except
      on E: ETelegramApiError do
        if FRetryOnRateLimit and E.IsRateLimited and (Attempt < 3) and
           (E.RetryAfter > 0) and (E.RetryAfter <= 60) then
        begin
          Log(Format('%s: rate limited, waiting %d s', [AMethod, E.RetryAfter]));
          Sleep(E.RetryAfter * 1000);
        end
        else
          raise;
    end;
  end;
end;

function TTelegramBot.Call(const AMethod: string; const AParams: ITgParams): TJsonObject;
begin
  Result := CallTimeout(AMethod, AParams, FTimeoutMs);
end;

function TTelegramBot.CallBool(const AMethod: string; const AParams: ITgParams): Boolean;
var
  Root: TJsonObject;
begin
  Root := Call(AMethod, AParams);
  try
    Result := Root.B['result'];
  finally
    Root.Free;
  end;
end;

function TTelegramBot.CallObject(AClass: TTgObjectClass; const AMethod: string;
  const AParams: ITgParams): TTgObject;
var
  Root: TJsonObject;
begin
  Root := Call(AMethod, AParams);
  try
    Result := AClass.Create(Root.O['result'], Root);
  except
    Root.Free;
    raise;
  end;
end;

function TTelegramBot.CallMessage(const AMethod: string; const AParams: ITgParams): TTgMessage;
begin
  Result := TTgMessage(CallObject(TTgMessage, AMethod, AParams));
end;

function TTelegramBot.CallList(AClass: TTgObjectClass; const AMethod: string;
  const AParams: ITgParams): TTgList;
var
  Root: TJsonObject;
begin
  Root := Call(AMethod, AParams);
  try
    Result := TTgList.Create(Root, AClass);
  except
    Root.Free;
    raise;
  end;
end;

{ ---- bot / updates ---- }

function TTelegramBot.GetMe: TTgUser;
begin
  Result := TTgUser(CallObject(TTgUser, 'getMe'));
end;

function TTelegramBot.LogOut: Boolean;
begin
  Result := CallBool('logOut');
end;

function TTelegramBot.GetUpdates(AOffset: Int64; ALimit, ATimeoutSec: Integer;
  const AAllowedUpdates: string): TTgUpdateList;
var
  P: ITgParams;
  Root: TJsonObject;
begin
  P := NewParams.AddOptInt('offset', AOffset).Add('limit', ALimit).AddOptInt('timeout', ATimeoutSec);
  if AAllowedUpdates <> '' then
    P.AddJson('allowed_updates',
      '["' + StringReplace(StringReplace(AAllowedUpdates, ' ', '', [rfReplaceAll]),
        ',', '","', [rfReplaceAll]) + '"]');
  Root := CallTimeout('getUpdates', P, FTimeoutMs + (ATimeoutSec + 10) * 1000);
  try
    Result := TTgUpdateList.Create(Root);
  except
    Root.Free;
    raise;
  end;
end;

function TTelegramBot.SetWebhook(const AUrl, ASecretToken: string; ADropPendingUpdates: Boolean;
  AMaxConnections: Integer; const AAllowedUpdates: string): Boolean;
var
  P: ITgParams;
begin
  P := NewParams.Add('url', AUrl).AddOpt('secret_token', ASecretToken);
  if ADropPendingUpdates then
    P.Add('drop_pending_updates', True);
  P.AddOptInt('max_connections', AMaxConnections);
  if AAllowedUpdates <> '' then
    P.AddJson('allowed_updates',
      '["' + StringReplace(StringReplace(AAllowedUpdates, ' ', '', [rfReplaceAll]),
        ',', '","', [rfReplaceAll]) + '"]');
  Result := CallBool('setWebhook', P);
end;

function TTelegramBot.DeleteWebhook(ADropPendingUpdates: Boolean): Boolean;
begin
  Result := CallBool('deleteWebhook', NewParams.Add('drop_pending_updates', ADropPendingUpdates));
end;

function TTelegramBot.GetWebhookInfo: TTgWebhookInfo;
begin
  Result := TTgWebhookInfo(CallObject(TTgWebhookInfo, 'getWebhookInfo'));
end;

{ ---- sending ---- }

function TTelegramBot.SendMessage(const AChatId: TTgChatId; const AText: string;
  const AMarkup: ITgReplyMarkup; const AParseMode: string; AReplyTo, AThreadId: Int64): TTgMessage;
var
  P: ITgParams;
begin
  P := NewParams.AddChat('chat_id', AChatId).Add('text', AText);
  Decorate(P, AMarkup, AParseMode, AReplyTo, AThreadId);
  Result := CallMessage('sendMessage', P);
end;

function TTelegramBot.SendText(const AChatId: TTgChatId; const AText: string;
  const AMarkup: ITgReplyMarkup; const AParseMode: string): Int64;
var
  M: TTgMessage;
begin
  M := SendMessage(AChatId, AText, AMarkup, AParseMode);
  try
    Result := M.MessageId;
  finally
    M.Free;
  end;
end;

function TTelegramBot.SendMedia(const AMethod, AField: string; const AChatId: TTgChatId;
  const AMedia: TTgInputFile; const ACaption: string; const AMarkup: ITgReplyMarkup;
  const AParseMode: string; AReplyTo, AThreadId: Int64): TTgMessage;
var
  P: ITgParams;
begin
  P := NewParams.AddChat('chat_id', AChatId).AddInput(AField, AMedia).AddOpt('caption', ACaption);
  Decorate(P, AMarkup, AParseMode, AReplyTo, AThreadId);
  Result := CallMessage(AMethod, P);
end;

function TTelegramBot.SendPhoto(const AChatId: TTgChatId; const APhoto: TTgInputFile;
  const ACaption: string; const AMarkup: ITgReplyMarkup; const AParseMode: string;
  AReplyTo, AThreadId: Int64): TTgMessage;
begin
  Result := SendMedia('sendPhoto', 'photo', AChatId, APhoto, ACaption, AMarkup, AParseMode, AReplyTo, AThreadId);
end;

function TTelegramBot.SendDocument(const AChatId: TTgChatId; const ADocument: TTgInputFile;
  const ACaption: string; const AMarkup: ITgReplyMarkup; const AParseMode: string;
  AReplyTo, AThreadId: Int64): TTgMessage;
begin
  Result := SendMedia('sendDocument', 'document', AChatId, ADocument, ACaption, AMarkup, AParseMode, AReplyTo, AThreadId);
end;

function TTelegramBot.SendVideo(const AChatId: TTgChatId; const AVideo: TTgInputFile;
  const ACaption: string; const AMarkup: ITgReplyMarkup; const AParseMode: string;
  AReplyTo, AThreadId: Int64): TTgMessage;
begin
  Result := SendMedia('sendVideo', 'video', AChatId, AVideo, ACaption, AMarkup, AParseMode, AReplyTo, AThreadId);
end;

function TTelegramBot.SendAudio(const AChatId: TTgChatId; const AAudio: TTgInputFile;
  const ACaption: string; const AMarkup: ITgReplyMarkup; const AParseMode: string;
  AReplyTo, AThreadId: Int64): TTgMessage;
begin
  Result := SendMedia('sendAudio', 'audio', AChatId, AAudio, ACaption, AMarkup, AParseMode, AReplyTo, AThreadId);
end;

function TTelegramBot.SendVoice(const AChatId: TTgChatId; const AVoice: TTgInputFile;
  const ACaption: string; const AMarkup: ITgReplyMarkup; const AParseMode: string;
  AReplyTo, AThreadId: Int64): TTgMessage;
begin
  Result := SendMedia('sendVoice', 'voice', AChatId, AVoice, ACaption, AMarkup, AParseMode, AReplyTo, AThreadId);
end;

function TTelegramBot.SendAnimation(const AChatId: TTgChatId; const AAnimation: TTgInputFile;
  const ACaption: string; const AMarkup: ITgReplyMarkup; const AParseMode: string;
  AReplyTo, AThreadId: Int64): TTgMessage;
begin
  Result := SendMedia('sendAnimation', 'animation', AChatId, AAnimation, ACaption, AMarkup, AParseMode, AReplyTo, AThreadId);
end;

function TTelegramBot.SendVideoNote(const AChatId: TTgChatId; const AVideoNote: TTgInputFile;
  const AMarkup: ITgReplyMarkup; AReplyTo, AThreadId: Int64): TTgMessage;
begin
  Result := SendMedia('sendVideoNote', 'video_note', AChatId, AVideoNote, '', AMarkup, '', AReplyTo, AThreadId);
end;

function TTelegramBot.SendSticker(const AChatId: TTgChatId; const ASticker: TTgInputFile;
  const AMarkup: ITgReplyMarkup; AReplyTo, AThreadId: Int64): TTgMessage;
begin
  Result := SendMedia('sendSticker', 'sticker', AChatId, ASticker, '', AMarkup, '', AReplyTo, AThreadId);
end;

function TTelegramBot.SendLocation(const AChatId: TTgChatId; ALatitude, ALongitude: Double;
  const AMarkup: ITgReplyMarkup; AReplyTo: Int64): TTgMessage;
var
  P: ITgParams;
begin
  P := NewParams.AddChat('chat_id', AChatId).AddFloat('latitude', ALatitude).AddFloat('longitude', ALongitude);
  Decorate(P, AMarkup, '', AReplyTo, 0);
  Result := CallMessage('sendLocation', P);
end;

function TTelegramBot.SendContact(const AChatId: TTgChatId; const APhone, AFirstName, ALastName: string;
  const AMarkup: ITgReplyMarkup): TTgMessage;
var
  P: ITgParams;
begin
  P := NewParams.AddChat('chat_id', AChatId).Add('phone_number', APhone).Add('first_name', AFirstName)
    .AddOpt('last_name', ALastName).AddMarkup(AMarkup);
  Result := CallMessage('sendContact', P);
end;

function TTelegramBot.SendPoll(const AChatId: TTgChatId; const AQuestion: string;
  const AOptions: array of string; AIsAnonymous: Boolean): TTgMessage;
var
  Arr: TJsonArray;
  I: Integer;
  P: ITgParams;
begin
  // Bot API 7.3+: options are InputPollOption objects
  Arr := TJsonArray.Create;
  try
    for I := 0 to High(AOptions) do
      Arr.AddObject.S['text'] := AOptions[I];
    P := NewParams.AddChat('chat_id', AChatId).Add('question', AQuestion)
      .AddJson('options', Arr.ToJSON(True)).Add('is_anonymous', AIsAnonymous);
  finally
    Arr.Free;
  end;
  Result := CallMessage('sendPoll', P);
end;

function TTelegramBot.SendDice(const AChatId: TTgChatId; const AEmoji: string): TTgMessage;
begin
  Result := CallMessage('sendDice', NewParams.AddChat('chat_id', AChatId).AddOpt('emoji', AEmoji));
end;

function TTelegramBot.SendChatAction(const AChatId: TTgChatId; const AAction: string): Boolean;
begin
  Result := CallBool('sendChatAction', NewParams.AddChat('chat_id', AChatId).Add('action', AAction));
end;

function TTelegramBot.ForwardMessage(const AChatId, AFromChatId: TTgChatId; AMessageId: Int64): TTgMessage;
begin
  Result := CallMessage('forwardMessage', NewParams.AddChat('chat_id', AChatId)
    .AddChat('from_chat_id', AFromChatId).Add('message_id', AMessageId));
end;

function TTelegramBot.CopyMessage(const AChatId, AFromChatId: TTgChatId; AMessageId: Int64): Int64;
var
  Root: TJsonObject;
begin
  Root := Call('copyMessage', NewParams.AddChat('chat_id', AChatId)
    .AddChat('from_chat_id', AFromChatId).Add('message_id', AMessageId));
  try
    Result := Root.O['result'].L['message_id'];
  finally
    Root.Free;
  end;
end;

{ ---- editing / deleting ---- }

function TTelegramBot.EditMessageText(const AChatId: TTgChatId; AMessageId: Int64;
  const AText: string; const AMarkup: ITgReplyMarkup; const AParseMode: string): TTgMessage;
var
  P: ITgParams;
begin
  P := NewParams.AddChat('chat_id', AChatId).Add('message_id', AMessageId).Add('text', AText);
  Decorate(P, AMarkup, AParseMode, 0, 0);
  Result := CallMessage('editMessageText', P);
end;

function TTelegramBot.EditInlineMessageText(const AInlineMessageId, AText: string;
  const AMarkup: ITgReplyMarkup; const AParseMode: string): Boolean;
var
  P: ITgParams;
begin
  P := NewParams.Add('inline_message_id', AInlineMessageId).Add('text', AText);
  Decorate(P, AMarkup, AParseMode, 0, 0);
  Result := CallBool('editMessageText', P);
end;

function TTelegramBot.EditMessageCaption(const AChatId: TTgChatId; AMessageId: Int64;
  const ACaption: string; const AMarkup: ITgReplyMarkup; const AParseMode: string): TTgMessage;
var
  P: ITgParams;
begin
  P := NewParams.AddChat('chat_id', AChatId).Add('message_id', AMessageId).Add('caption', ACaption);
  Decorate(P, AMarkup, AParseMode, 0, 0);
  Result := CallMessage('editMessageCaption', P);
end;

function TTelegramBot.EditMessageReplyMarkup(const AChatId: TTgChatId; AMessageId: Int64;
  const AMarkup: ITgReplyMarkup): TTgMessage;
begin
  Result := CallMessage('editMessageReplyMarkup', NewParams.AddChat('chat_id', AChatId)
    .Add('message_id', AMessageId).AddMarkup(AMarkup));
end;

function TTelegramBot.DeleteMessage(const AChatId: TTgChatId; AMessageId: Int64): Boolean;
begin
  Result := CallBool('deleteMessage', NewParams.AddChat('chat_id', AChatId).Add('message_id', AMessageId));
end;

function TTelegramBot.PinChatMessage(const AChatId: TTgChatId; AMessageId: Int64; ANotify: Boolean): Boolean;
begin
  Result := CallBool('pinChatMessage', NewParams.AddChat('chat_id', AChatId)
    .Add('message_id', AMessageId).Add('disable_notification', not ANotify));
end;

function TTelegramBot.UnpinChatMessage(const AChatId: TTgChatId; AMessageId: Int64): Boolean;
begin
  Result := CallBool('unpinChatMessage', NewParams.AddChat('chat_id', AChatId).AddOptInt('message_id', AMessageId));
end;

{ ---- callbacks / inline / payments ---- }

function TTelegramBot.AnswerCallbackQuery(const AId, AText: string; AShowAlert: Boolean;
  const AUrl: string; ACacheTime: Integer): Boolean;
var
  P: ITgParams;
begin
  P := NewParams.Add('callback_query_id', AId).AddOpt('text', AText).AddOpt('url', AUrl)
    .AddOptInt('cache_time', ACacheTime);
  if AShowAlert then
    P.Add('show_alert', True);
  Result := CallBool('answerCallbackQuery', P);
end;

function TTelegramBot.AnswerInlineQuery(const AId, AResultsJson: string; ACacheTime: Integer;
  AIsPersonal: Boolean; const ANextOffset: string): Boolean;
begin
  Result := CallBool('answerInlineQuery', NewParams.Add('inline_query_id', AId)
    .AddJson('results', AResultsJson).Add('cache_time', ACacheTime)
    .Add('is_personal', AIsPersonal).AddOpt('next_offset', ANextOffset));
end;

function TTelegramBot.AnswerPreCheckoutQuery(const AId: string; AOk: Boolean;
  const AErrorMessage: string): Boolean;
begin
  Result := CallBool('answerPreCheckoutQuery', NewParams.Add('pre_checkout_query_id', AId)
    .Add('ok', AOk).AddOpt('error_message', AErrorMessage));
end;

{ ---- chats ---- }

function TTelegramBot.GetChat(const AChatId: TTgChatId): TTgChat;
begin
  Result := TTgChat(CallObject(TTgChat, 'getChat', NewParams.AddChat('chat_id', AChatId)));
end;

function TTelegramBot.GetChatMember(const AChatId: TTgChatId; AUserId: Int64): TTgChatMember;
begin
  Result := TTgChatMember(CallObject(TTgChatMember, 'getChatMember',
    NewParams.AddChat('chat_id', AChatId).Add('user_id', AUserId)));
end;

function TTelegramBot.GetChatMemberCount(const AChatId: TTgChatId): Int64;
var
  Root: TJsonObject;
begin
  Root := Call('getChatMemberCount', NewParams.AddChat('chat_id', AChatId));
  try
    Result := Root.L['result'];
  finally
    Root.Free;
  end;
end;

function TTelegramBot.GetChatAdministrators(const AChatId: TTgChatId): TTgList;
begin
  Result := CallList(TTgChatMember, 'getChatAdministrators', NewParams.AddChat('chat_id', AChatId));
end;

function TTelegramBot.BanChatMember(const AChatId: TTgChatId; AUserId, AUntilUnixTime: Int64;
  ARevokeMessages: Boolean): Boolean;
var
  P: ITgParams;
begin
  P := NewParams.AddChat('chat_id', AChatId).Add('user_id', AUserId).AddOptInt('until_date', AUntilUnixTime);
  if ARevokeMessages then
    P.Add('revoke_messages', True);
  Result := CallBool('banChatMember', P);
end;

function TTelegramBot.UnbanChatMember(const AChatId: TTgChatId; AUserId: Int64;
  AOnlyIfBanned: Boolean): Boolean;
begin
  Result := CallBool('unbanChatMember', NewParams.AddChat('chat_id', AChatId)
    .Add('user_id', AUserId).Add('only_if_banned', AOnlyIfBanned));
end;

function TTelegramBot.LeaveChat(const AChatId: TTgChatId): Boolean;
begin
  Result := CallBool('leaveChat', NewParams.AddChat('chat_id', AChatId));
end;

function TTelegramBot.ApproveChatJoinRequest(const AChatId: TTgChatId; AUserId: Int64): Boolean;
begin
  Result := CallBool('approveChatJoinRequest', NewParams.AddChat('chat_id', AChatId).Add('user_id', AUserId));
end;

function TTelegramBot.DeclineChatJoinRequest(const AChatId: TTgChatId; AUserId: Int64): Boolean;
begin
  Result := CallBool('declineChatJoinRequest', NewParams.AddChat('chat_id', AChatId).Add('user_id', AUserId));
end;

{ ---- commands ---- }

function TTelegramBot.SetMyCommands(const ACommands: array of TTgBotCommand;
  const ALanguageCode: string): Boolean;
var
  Arr: TJsonArray;
  O: TJsonObject;
  I: Integer;
  P: ITgParams;
begin
  Arr := TJsonArray.Create;
  try
    for I := 0 to High(ACommands) do
    begin
      O := Arr.AddObject;
      O.S['command'] := ACommands[I].Command;
      O.S['description'] := ACommands[I].Description;
    end;
    P := NewParams.AddJson('commands', Arr.ToJSON(True)).AddOpt('language_code', ALanguageCode);
  finally
    Arr.Free;
  end;
  Result := CallBool('setMyCommands', P);
end;

function TTelegramBot.DeleteMyCommands: Boolean;
begin
  Result := CallBool('deleteMyCommands');
end;

{ ---- files ---- }

function TTelegramBot.GetFile(const AFileId: string): TTgFileInfo;
begin
  Result := TTgFileInfo(CallObject(TTgFileInfo, 'getFile', NewParams.Add('file_id', AFileId)));
end;

procedure TTelegramBot.DownloadFile(const AFileId: string; ADest: TStream);
var
  F: TTgFileInfo;
begin
  F := GetFile(AFileId);
  try
    if F.FilePath = '' then
      raise ETelegram4D.Create('Telegram4D: file_path missing (file too big for the cloud Bot API?)');
    GetHttp.Download(FileUrl(F.FilePath), ADest, FTimeoutMs);
  finally
    F.Free;
  end;
end;

procedure TTelegramBot.DownloadFileTo(const AFileId, ALocalPath: string);
var
  FS: TFileStream;
begin
  FS := TFileStream.Create(ALocalPath, fmCreate);
  try
    DownloadFile(AFileId, FS);
  finally
    FS.Free;
  end;
end;

end.
