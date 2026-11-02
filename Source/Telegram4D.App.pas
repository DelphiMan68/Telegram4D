// Telegram4D - Telegram Bot API library for Delphi and Free Pascal
// Copyright 2026 Shaahin Ashayeri (https://github.com/DelphiMan68)
// SPDX-License-Identifier: Apache-2.0

unit Telegram4D.App;

{ TTelegramApp = bot + router + long polling (or webhook entry point).

    App := TTelegramApp.Create('123:ABC');
    App.OnCommand('start', Self.HandleStart);      // procedure(Sender: TObject; Ctx: TTgContext) of object
    App.OnCallback('ok', Self.HandleOk);
    App.Start;                                     // long polling in a background thread
    ...
    App.Stop;

  Routing: routes are checked in registration order, the first match handles the update.
  Register specific routes (commands, callbacks) before generic ones (OnText, OnAnyUpdate).
  Delphi only: every On* registration also has an overload taking an anonymous method. }

{$I Telegram4D.inc}

interface

uses
  Classes, SysUtils, Contnrs, Telegram4D.Consts, Telegram4D.Errors, Telegram4D.JSON,
  Telegram4D.Markup, Telegram4D.Params, Telegram4D.Types, Telegram4D.Bot;

type
  TTelegramApp = class;

  /// Everything a handler needs about the current update.
  TTgContext = class
  private
    FApp: TTelegramApp;
    FUpdate: TTgUpdate;
    function GetBot: TTelegramBot;
    function GetMessage: TTgMessage;
    function GetChat: TTgChat;
    function GetUser: TTgUser;
    function GetChatId: Int64;
  public
    constructor Create(AApp: TTelegramApp; AUpdate: TTgUpdate);
    property App: TTelegramApp read FApp;
    property Bot: TTelegramBot read GetBot;
    property Update: TTgUpdate read FUpdate;
    /// Effective message (may be nil, e.g. for inline queries).
    property Message: TTgMessage read GetMessage;
    property Chat: TTgChat read GetChat;
    property User: TTgUser read GetUser;
    property ChatId: Int64 read GetChatId;
    function Text: string;
    /// Text after the command: "/echo hello world" -> 'hello world'.
    function Args: string;
    function CallbackData: string;
    /// Sends a message to the current chat.
    procedure Reply(const AText: string; const AMarkup: ITgReplyMarkup = nil;
      const AParseMode: string = '');
    procedure ReplyHtml(const AText: string; const AMarkup: ITgReplyMarkup = nil);
    /// Replies as a quote of the incoming message.
    procedure ReplyTo(const AText: string; const AMarkup: ITgReplyMarkup = nil);
    /// answerCallbackQuery for the current callback (stops the spinner on the button).
    procedure Answer(const AText: string = ''; AShowAlert: Boolean = False);
    /// Edits the message the pressed inline button belongs to.
    procedure EditText(const AText: string; const AMarkup: ITgReplyMarkup = nil;
      const AParseMode: string = '');
    procedure Typing;
  end;

  TTgHandler = procedure(Sender: TObject; Ctx: TTgContext) of object;
  TTgErrorEvent = procedure(Sender: TObject; E: Exception; AUpdate: TTgUpdate) of object;
{$IFNDEF FPC}
  TTgHandlerRef = reference to procedure(Ctx: TTgContext);
{$ENDIF}

  TTgRouteKind = (rkCommand, rkText, rkMessage, rkCallback, rkCallbackPrefix,
    rkInlineQuery, rkKind, rkAny);

  TTgRoute = class
  public
    Kind: TTgRouteKind;
    Pattern: string;
    UpdateKind: TTgUpdateKind;
    Handler: TTgHandler;
{$IFNDEF FPC}
    HandlerRef: TTgHandlerRef;
{$ENDIF}
  end;

  TTelegramApp = class
  private
    FBot: TTelegramBot;
    FRoutes: TObjectList;
    FPoller: TThread;
    FPollTimeoutSec: Integer;
    FAllowedUpdates: string;
    FSyncDispatch: Boolean;
    FDeleteWebhookOnStart: Boolean;
    FWebhookSecret: string;
    FOnError: TTgErrorEvent;
    function GetActive: Boolean;
    procedure AddRoute(AKind: TTgRouteKind; const APattern: string;
      AUpdateKind: TTgUpdateKind; AHandler: TTgHandler
      {$IFNDEF FPC}; const ARef: TTgHandlerRef{$ENDIF});
    function Matches(ARoute: TTgRoute; AUpdate: TTgUpdate): Boolean;
    procedure Invoke(ARoute: TTgRoute; ACtx: TTgContext);
  public
    constructor Create(const AToken: string; const AProxyHost: string = '';
      AProxyPort: Integer = 0);
    destructor Destroy; override;

    { ---- routes ---- }
    procedure OnCommand(const ACommand: string; AHandler: TTgHandler); overload;
    procedure OnText(AHandler: TTgHandler); overload;          // non-command text
    procedure OnMessage(AHandler: TTgHandler); overload;       // any message
    procedure OnCallback(const AData: string; AHandler: TTgHandler); overload;
    procedure OnCallbackPrefix(const APrefix: string; AHandler: TTgHandler); overload;
    procedure OnInlineQuery(AHandler: TTgHandler); overload;
    procedure OnUpdateKind(AKind: TTgUpdateKind; AHandler: TTgHandler); overload;
    procedure OnAnyUpdate(AHandler: TTgHandler); overload;
{$IFNDEF FPC}
    procedure OnCommand(const ACommand: string; const AHandler: TTgHandlerRef); overload;
    procedure OnText(const AHandler: TTgHandlerRef); overload;
    procedure OnMessage(const AHandler: TTgHandlerRef); overload;
    procedure OnCallback(const AData: string; const AHandler: TTgHandlerRef); overload;
    procedure OnCallbackPrefix(const APrefix: string; const AHandler: TTgHandlerRef); overload;
    procedure OnInlineQuery(const AHandler: TTgHandlerRef); overload;
    procedure OnUpdateKind(AKind: TTgUpdateKind; const AHandler: TTgHandlerRef); overload;
    procedure OnAnyUpdate(const AHandler: TTgHandlerRef); overload;
{$ENDIF}

    { ---- running ---- }
    /// Starts long polling in a background thread.
    procedure Start;
    /// Stops polling; may block up to PollTimeoutSec while the pending getUpdates returns.
    procedure Stop;
    /// Webhook mode: call this from your HTTP server with the raw request body and the value
    /// of the X-Telegram-Bot-Api-Secret-Token header. Raises ETelegram4D on a wrong secret.
    procedure HandleWebhook(const ABody: string; const ASecretHeader: string = '');
    /// Routes one update (used by the poller and HandleWebhook; handy for tests).
    procedure Dispatch(AUpdate: TTgUpdate);
    procedure ReportError(E: Exception; AUpdate: TTgUpdate);

    property Bot: TTelegramBot read FBot;
    property Active: Boolean read GetActive;
    /// Long polling timeout in seconds (default 25).
    property PollTimeoutSec: Integer read FPollTimeoutSec write FPollTimeoutSec;
    /// Comma separated, e.g. 'message,callback_query'. Empty = Telegram default.
    property AllowedUpdates: string read FAllowedUpdates write FAllowedUpdates;
    /// True: handlers run in the main thread (needed to touch VCL/FMX/LCL directly).
    /// Requires a message loop. Default False: handlers run in the polling thread.
    property SyncDispatch: Boolean read FSyncDispatch write FSyncDispatch;
    property DeleteWebhookOnStart: Boolean read FDeleteWebhookOnStart write FDeleteWebhookOnStart;
    /// Expected secret_token when you registered the webhook with one.
    property WebhookSecret: string read FWebhookSecret write FWebhookSecret;
    property OnError: TTgErrorEvent read FOnError write FOnError;
  end;

implementation

type
  TTgPollerThread = class(TThread)
  private
    FApp: TTelegramApp;
    FCurrent: TTgUpdate;
    procedure DoDispatch;
    procedure Pause(AMs: Integer);
  protected
    procedure Execute; override;
  public
    constructor Create(AApp: TTelegramApp);
  end;

{ TTgContext }

constructor TTgContext.Create(AApp: TTelegramApp; AUpdate: TTgUpdate);
begin
  inherited Create;
  FApp := AApp;
  FUpdate := AUpdate;
end;

function TTgContext.GetBot: TTelegramBot;
begin
  Result := FApp.Bot;
end;

function TTgContext.GetMessage: TTgMessage;
begin
  Result := FUpdate.EffectiveMessage;
end;

function TTgContext.GetChat: TTgChat;
begin
  Result := FUpdate.EffectiveChat;
end;

function TTgContext.GetUser: TTgUser;
begin
  Result := FUpdate.EffectiveUser;
end;

function TTgContext.GetChatId: Int64;
begin
  if Chat <> nil then
    Result := Chat.Id
  else
    Result := 0;
end;

function TTgContext.Text: string;
begin
  if (Message <> nil) and Message.HasText then
    Result := Message.Text
  else
    Result := '';
end;

function TTgContext.Args: string;
begin
  if Message <> nil then
    Result := Message.CommandArgs
  else
    Result := '';
end;

function TTgContext.CallbackData: string;
begin
  if FUpdate.CallbackQuery <> nil then
    Result := FUpdate.CallbackQuery.Data
  else
    Result := '';
end;

procedure TTgContext.Reply(const AText: string; const AMarkup: ITgReplyMarkup;
  const AParseMode: string);
begin
  if Chat = nil then
    raise ETelegram4D.Create('Telegram4D: this update has no chat to reply to');
  Bot.SendText(Chat.Id, AText, AMarkup, AParseMode);
end;

procedure TTgContext.ReplyHtml(const AText: string; const AMarkup: ITgReplyMarkup);
begin
  Reply(AText, AMarkup, PARSE_HTML);
end;

procedure TTgContext.ReplyTo(const AText: string; const AMarkup: ITgReplyMarkup);
var
  M: TTgMessage;
begin
  if (Chat = nil) or (Message = nil) then
    raise ETelegram4D.Create('Telegram4D: nothing to reply to');
  M := Bot.SendMessage(Chat.Id, AText, AMarkup, '', Message.MessageId);
  M.Free;
end;

procedure TTgContext.Answer(const AText: string; AShowAlert: Boolean);
begin
  if FUpdate.CallbackQuery <> nil then
    Bot.AnswerCallbackQuery(FUpdate.CallbackQuery.Id, AText, AShowAlert);
end;

procedure TTgContext.EditText(const AText: string; const AMarkup: ITgReplyMarkup;
  const AParseMode: string);
var
  CB: TTgCallbackQuery;
  M: TTgMessage;
begin
  CB := FUpdate.CallbackQuery;
  if CB = nil then
    raise ETelegram4D.Create('Telegram4D: EditText needs a callback query update');
  if CB.InlineMessageId <> '' then
    Bot.EditInlineMessageText(CB.InlineMessageId, AText, AMarkup, AParseMode)
  else if (CB.Message <> nil) and (CB.Message.Chat <> nil) then
  begin
    M := Bot.EditMessageText(CB.Message.Chat.Id, CB.Message.MessageId, AText, AMarkup, AParseMode);
    M.Free;
  end;
end;

procedure TTgContext.Typing;
begin
  if Chat <> nil then
    Bot.SendChatAction(Chat.Id, ACTION_TYPING);
end;

{ TTelegramApp }

constructor TTelegramApp.Create(const AToken, AProxyHost: string; AProxyPort: Integer);
begin
  inherited Create;
  FBot := TTelegramBot.New(AToken, AProxyHost, AProxyPort);
  FRoutes := TObjectList.Create(True);
  FPollTimeoutSec := 25;
  FDeleteWebhookOnStart := True;
end;

destructor TTelegramApp.Destroy;
begin
  Stop;
  FRoutes.Free;
  FBot.Free;
  inherited;
end;

function TTelegramApp.GetActive: Boolean;
begin
  Result := FPoller <> nil;
end;

procedure TTelegramApp.AddRoute(AKind: TTgRouteKind; const APattern: string;
  AUpdateKind: TTgUpdateKind; AHandler: TTgHandler
  {$IFNDEF FPC}; const ARef: TTgHandlerRef{$ENDIF});
var
  R: TTgRoute;
begin
  R := TTgRoute.Create;
  R.Kind := AKind;
  R.Pattern := APattern;
  R.UpdateKind := AUpdateKind;
  R.Handler := AHandler;
{$IFNDEF FPC}
  R.HandlerRef := ARef;
{$ENDIF}
  FRoutes.Add(R);
end;

procedure TTelegramApp.OnCommand(const ACommand: string; AHandler: TTgHandler);
begin
  AddRoute(rkCommand, LowerCase(ACommand), ukUnknown, AHandler{$IFNDEF FPC}, nil{$ENDIF});
end;

procedure TTelegramApp.OnText(AHandler: TTgHandler);
begin
  AddRoute(rkText, '', ukUnknown, AHandler{$IFNDEF FPC}, nil{$ENDIF});
end;

procedure TTelegramApp.OnMessage(AHandler: TTgHandler);
begin
  AddRoute(rkMessage, '', ukUnknown, AHandler{$IFNDEF FPC}, nil{$ENDIF});
end;

procedure TTelegramApp.OnCallback(const AData: string; AHandler: TTgHandler);
begin
  AddRoute(rkCallback, AData, ukUnknown, AHandler{$IFNDEF FPC}, nil{$ENDIF});
end;

procedure TTelegramApp.OnCallbackPrefix(const APrefix: string; AHandler: TTgHandler);
begin
  AddRoute(rkCallbackPrefix, APrefix, ukUnknown, AHandler{$IFNDEF FPC}, nil{$ENDIF});
end;

procedure TTelegramApp.OnInlineQuery(AHandler: TTgHandler);
begin
  AddRoute(rkInlineQuery, '', ukUnknown, AHandler{$IFNDEF FPC}, nil{$ENDIF});
end;

procedure TTelegramApp.OnUpdateKind(AKind: TTgUpdateKind; AHandler: TTgHandler);
begin
  AddRoute(rkKind, '', AKind, AHandler{$IFNDEF FPC}, nil{$ENDIF});
end;

procedure TTelegramApp.OnAnyUpdate(AHandler: TTgHandler);
begin
  AddRoute(rkAny, '', ukUnknown, AHandler{$IFNDEF FPC}, nil{$ENDIF});
end;

{$IFNDEF FPC}
procedure TTelegramApp.OnCommand(const ACommand: string; const AHandler: TTgHandlerRef);
begin
  AddRoute(rkCommand, LowerCase(ACommand), ukUnknown, nil, AHandler);
end;

procedure TTelegramApp.OnText(const AHandler: TTgHandlerRef);
begin
  AddRoute(rkText, '', ukUnknown, nil, AHandler);
end;

procedure TTelegramApp.OnMessage(const AHandler: TTgHandlerRef);
begin
  AddRoute(rkMessage, '', ukUnknown, nil, AHandler);
end;

procedure TTelegramApp.OnCallback(const AData: string; const AHandler: TTgHandlerRef);
begin
  AddRoute(rkCallback, AData, ukUnknown, nil, AHandler);
end;

procedure TTelegramApp.OnCallbackPrefix(const APrefix: string; const AHandler: TTgHandlerRef);
begin
  AddRoute(rkCallbackPrefix, APrefix, ukUnknown, nil, AHandler);
end;

procedure TTelegramApp.OnInlineQuery(const AHandler: TTgHandlerRef);
begin
  AddRoute(rkInlineQuery, '', ukUnknown, nil, AHandler);
end;

procedure TTelegramApp.OnUpdateKind(AKind: TTgUpdateKind; const AHandler: TTgHandlerRef);
begin
  AddRoute(rkKind, '', AKind, nil, AHandler);
end;

procedure TTelegramApp.OnAnyUpdate(const AHandler: TTgHandlerRef);
begin
  AddRoute(rkAny, '', ukUnknown, nil, AHandler);
end;
{$ENDIF}

function TTelegramApp.Matches(ARoute: TTgRoute; AUpdate: TTgUpdate): Boolean;
var
  M: TTgMessage;
  CB: TTgCallbackQuery;
begin
  Result := False;
  M := AUpdate.Message;
  CB := AUpdate.CallbackQuery;
  case ARoute.Kind of
    rkCommand:
      Result := (M <> nil) and M.IsCommand and (M.Command = ARoute.Pattern);
    rkText:
      Result := (M <> nil) and M.HasText and not M.IsCommand;
    rkMessage:
      Result := M <> nil;
    rkCallback:
      Result := (CB <> nil) and (CB.Data = ARoute.Pattern);
    rkCallbackPrefix:
      Result := (CB <> nil) and (Copy(CB.Data, 1, Length(ARoute.Pattern)) = ARoute.Pattern);
    rkInlineQuery:
      Result := AUpdate.InlineQuery <> nil;
    rkKind:
      Result := AUpdate.Kind = ARoute.UpdateKind;
    rkAny:
      Result := True;
  end;
end;

procedure TTelegramApp.Invoke(ARoute: TTgRoute; ACtx: TTgContext);
begin
{$IFNDEF FPC}
  if Assigned(ARoute.HandlerRef) then
    ARoute.HandlerRef(ACtx)
  else
{$ENDIF}
  if Assigned(ARoute.Handler) then
    ARoute.Handler(Self, ACtx);
end;

procedure TTelegramApp.Dispatch(AUpdate: TTgUpdate);
var
  Ctx: TTgContext;
  I: Integer;
  R: TTgRoute;
begin
  Ctx := TTgContext.Create(Self, AUpdate);
  try
    try
      for I := 0 to FRoutes.Count - 1 do
      begin
        R := TTgRoute(FRoutes[I]);
        if Matches(R, AUpdate) then
        begin
          Invoke(R, Ctx);
          Break;
        end;
      end;
    except
      on E: Exception do
        ReportError(E, AUpdate);
    end;
  finally
    Ctx.Free;
  end;
end;

procedure TTelegramApp.ReportError(E: Exception; AUpdate: TTgUpdate);
begin
  FBot.Log(E.ClassName + ': ' + E.Message);
  if Assigned(FOnError) then
    FOnError(Self, E, AUpdate);
end;

procedure TTelegramApp.HandleWebhook(const ABody, ASecretHeader: string);
var
  Root: TJsonObject;
  U: TTgUpdate;
begin
  if (FWebhookSecret <> '') and (ASecretHeader <> FWebhookSecret) then
    raise ETelegram4D.Create('Telegram4D: webhook secret token mismatch');
  Root := ParseJsonObject(ABody);
  U := TTgUpdate.Create(Root, Root);   // U owns Root
  try
    Dispatch(U);
  finally
    U.Free;
  end;
end;

procedure TTelegramApp.Start;
begin
  if FPoller <> nil then
    Exit;
  if FDeleteWebhookOnStart then
    FBot.DeleteWebhook(False);   // getUpdates fails with 409 while a webhook is set
  FPoller := TTgPollerThread.Create(Self);
end;

procedure TTelegramApp.Stop;
begin
  if FPoller = nil then
    Exit;
  FPoller.Terminate;
  FPoller.WaitFor;
  FreeAndNil(FPoller);
end;

{ TTgPollerThread }

constructor TTgPollerThread.Create(AApp: TTelegramApp);
begin
  FApp := AApp;
  inherited Create(False);
end;

procedure TTgPollerThread.DoDispatch;
begin
  FApp.Dispatch(FCurrent);
end;

procedure TTgPollerThread.Pause(AMs: Integer);
var
  Waited: Integer;
begin
  Waited := 0;
  while (Waited < AMs) and not Terminated do
  begin
    Sleep(100);
    Inc(Waited, 100);
  end;
end;

procedure TTgPollerThread.Execute;
var
  Offset: Int64;
  List: TTgUpdateList;
  I, Delay: Integer;
begin
  Offset := 0;
  Delay := 1000;
  while not Terminated do
  begin
    try
      List := FApp.Bot.GetUpdates(Offset, 100, FApp.PollTimeoutSec, FApp.AllowedUpdates);
      try
        Delay := 1000;
        for I := 0 to List.Count - 1 do
        begin
          FCurrent := List.Updates[I];
          Offset := FCurrent.UpdateId + 1;
          if FApp.SyncDispatch then
            Synchronize(DoDispatch)
          else
            DoDispatch;
          if Terminated then
            Break;
        end;
      finally
        FCurrent := nil;
        List.Free;
      end;
    except
      on E: ETelegramApiError do
      begin
        FApp.ReportError(E, nil);
        if E.IsUnauthorized then
          Terminate                                  // wrong token: retrying is pointless
        else if E.IsRateLimited and (E.RetryAfter > 0) then
          Pause(E.RetryAfter * 1000)
        else
          Pause(Delay);
      end;
      on E: Exception do
      begin
        FApp.ReportError(E, nil);
        Pause(Delay);
        if Delay < 30000 then
          Delay := Delay * 2;
      end;
    end;
  end;
end;

end.
