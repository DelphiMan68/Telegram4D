// Telegram4D - Telegram Bot API library for Delphi and Free Pascal
// Copyright 2026 Shaahin Ashayeri (https://github.com/DelphiMan68)
// SPDX-License-Identifier: Apache-2.0

unit Showcase.Handlers;

{ Telegram4D showcase bot.
  The same unit is used by the Delphi and the Free Pascal demo. It exercises:
  commands, inline keyboards (pagination, counter), reply keyboards (contact/location
  requests), editing and deleting messages, media by URL / stream / download, polls,
  dice, chat actions, formatting helpers, inline mode, chat member updates, error
  handling, raw JSON access and admin-only commands. }

{$IFDEF FPC}
  {$MODE DELPHI}
  {$H+}
  {$MODESWITCH UNICODESTRINGS}
{$ENDIF}

interface

uses
  Classes, SysUtils, DateUtils, StrUtils,
  Telegram4D.Consts, Telegram4D.Errors, Telegram4D.JSON, Telegram4D.Markup,
  Telegram4D.Params, Telegram4D.Types, Telegram4D.Utils, Telegram4D.Bot, Telegram4D.App;

type
  TShowcase = class
  private
    FApp: TTelegramApp;
    FAdminId: Int64;
    FShutdown: Boolean;
    FDownloadDir: string;

    { plumbing }
    procedure DoLog(Sender: TObject; const AMessage: string);
    procedure DoError(Sender: TObject; E: Exception; AUpdate: TTgUpdate);
    procedure SafeEdit(Ctx: TTgContext; const AText: string; const AMarkup: ITgReplyMarkup);
    procedure SaveIncomingFile(Ctx: TTgContext; AFile: TTgFileInfo; const AName: string);

    { keyboards / texts }
    function MainMenu: ITgReplyMarkup;
    function PageText(APage: Integer): string;
    function PageKeyboard(APage: Integer): ITgReplyMarkup;
    function CounterKeyboard(AValue: Integer): ITgReplyMarkup;

    { commands }
    procedure CmdStart(Sender: TObject; Ctx: TTgContext);
    procedure CmdHelp(Sender: TObject; Ctx: TTgContext);
    procedure CmdMenu(Sender: TObject; Ctx: TTgContext);
    procedure CmdCounter(Sender: TObject; Ctx: TTgContext);
    procedure CmdWhoAmI(Sender: TObject; Ctx: TTgContext);
    procedure CmdEcho(Sender: TObject; Ctx: TTgContext);
    procedure CmdFormat(Sender: TObject; Ctx: TTgContext);
    procedure CmdPhoto(Sender: TObject; Ctx: TTgContext);
    procedure CmdDocument(Sender: TObject; Ctx: TTgContext);
    procedure CmdLocation(Sender: TObject; Ctx: TTgContext);
    procedure CmdContact(Sender: TObject; Ctx: TTgContext);
    procedure CmdPoll(Sender: TObject; Ctx: TTgContext);
    procedure CmdDice(Sender: TObject; Ctx: TTgContext);
    procedure CmdTyping(Sender: TObject; Ctx: TTgContext);
    procedure CmdEdit(Sender: TObject; Ctx: TTgContext);
    procedure CmdSelfDestruct(Sender: TObject; Ctx: TTgContext);
    procedure CmdCopy(Sender: TObject; Ctx: TTgContext);
    procedure CmdMembers(Sender: TObject; Ctx: TTgContext);
    procedure CmdPing(Sender: TObject; Ctx: TTgContext);
    procedure CmdError(Sender: TObject; Ctx: TTgContext);
    procedure CmdRaw(Sender: TObject; Ctx: TTgContext);
    procedure CmdHide(Sender: TObject; Ctx: TTgContext);
    procedure CmdStop(Sender: TObject; Ctx: TTgContext);

    { callbacks }
    procedure CbPage(Sender: TObject; Ctx: TTgContext);
    procedure CbCounter(Sender: TObject; Ctx: TTgContext);
    procedure CbAbout(Sender: TObject; Ctx: TTgContext);
    procedure CbNoop(Sender: TObject; Ctx: TTgContext);

    { other update kinds }
    procedure OnInline(Sender: TObject; Ctx: TTgContext);
    procedure OnMyChatMember(Sender: TObject; Ctx: TTgContext);
    procedure OnPlainText(Sender: TObject; Ctx: TTgContext);
    procedure OnAnyMessage(Sender: TObject; Ctx: TTgContext);
  public
    constructor Create(AApp: TTelegramApp; AAdminId: Int64);
    /// Registers logging, error handling, the command menu and all routes.
    /// Order matters: the catch-all OnMessage route is registered last.
    procedure RegisterRoutes;
    property ShutdownRequested: Boolean read FShutdown;
  end;

implementation

const
  MAX_DOWNLOAD_BYTES = 20 * 1024 * 1024;   // getFile limit of the cloud Bot API

  // dice emoji written as UTF-16 code units so the source stays encoding safe
  EMOJI_DICE     = #$D83C#$DFB2;
  EMOJI_DART     = #$D83C#$DFAF;
  EMOJI_BASKET   = #$D83C#$DFC0;
  EMOJI_FOOTBALL = #$26BD;
  EMOJI_BOWLING  = #$D83C#$DFB3;
  EMOJI_SLOT     = #$D83C#$DFB0;

function MakeTextStream(const AText: string): TMemoryStream;
var
  B: TBytes;
begin
  Result := TMemoryStream.Create;
  B := TEncoding.UTF8.GetBytes(AText);
  if Length(B) > 0 then
    Result.WriteBuffer(B[0], Length(B));
end;

function SafeFileName(const AName: string): string;
var
  I: Integer;
begin
  Result := ExtractFileName(AName);
  for I := 1 to Length(Result) do
    if Pos(Result[I], '\/:*?"<>|') > 0 then
      Result[I] := '_';
  if Result = '' then
    Result := 'file.bin';
end;

{ TShowcase }

constructor TShowcase.Create(AApp: TTelegramApp; AAdminId: Int64);
begin
  inherited Create;
  FApp := AApp;
  FAdminId := AAdminId;
  FDownloadDir := ExtractFilePath(ParamStr(0)) + 'downloads';
end;

procedure TShowcase.RegisterRoutes;
begin
  FApp.Bot.OnLog := DoLog;
  FApp.OnError := DoError;
  FApp.Bot.DefaultParseMode := '';       // choose per call (Reply / ReplyHtml)
  FApp.AllowedUpdates := 'message,callback_query,inline_query,my_chat_member';

  FApp.Bot.SetMyCommands([
    BotCommand('start', 'Start and show the main menu'),
    BotCommand('help', 'Help'),
    BotCommand('menu', 'Paginated inline menu'),
    BotCommand('counter', 'Interactive counter'),
    BotCommand('whoami', 'Information about you and this chat'),
    BotCommand('echo', 'Repeat the text'),
    BotCommand('format', 'HTML and MarkdownV2 formatting samples'),
    BotCommand('photo', 'Send a photo by URL'),
    BotCommand('document', 'Send a file from a stream'),
    BotCommand('location', 'Send a location'),
    BotCommand('contact', 'Send a contact'),
    BotCommand('poll', 'Create a poll'),
    BotCommand('dice', 'Dice and dice games'),
    BotCommand('typing', 'Show the typing indicator'),
    BotCommand('edit', 'Edit a message'),
    BotCommand('selfdestruct', 'Self-destructing message'),
    BotCommand('copy', 'Copy the message you replied to'),
    BotCommand('members', 'Group members'),
    BotCommand('ping', 'Measure latency'),
    BotCommand('error', 'Show API error handling'),
    BotCommand('raw', 'Raw JSON of this update'),
    BotCommand('hide', 'Hide the keyboard')
  ]);

  // commands
  FApp.OnCommand('start', CmdStart);
  FApp.OnCommand('help', CmdHelp);
  FApp.OnCommand('menu', CmdMenu);
  FApp.OnCommand('counter', CmdCounter);
  FApp.OnCommand('whoami', CmdWhoAmI);
  FApp.OnCommand('echo', CmdEcho);
  FApp.OnCommand('format', CmdFormat);
  FApp.OnCommand('photo', CmdPhoto);
  FApp.OnCommand('document', CmdDocument);
  FApp.OnCommand('location', CmdLocation);
  FApp.OnCommand('contact', CmdContact);
  FApp.OnCommand('poll', CmdPoll);
  FApp.OnCommand('dice', CmdDice);
  FApp.OnCommand('typing', CmdTyping);
  FApp.OnCommand('edit', CmdEdit);
  FApp.OnCommand('selfdestruct', CmdSelfDestruct);
  FApp.OnCommand('copy', CmdCopy);
  FApp.OnCommand('members', CmdMembers);
  FApp.OnCommand('ping', CmdPing);
  FApp.OnCommand('error', CmdError);
  FApp.OnCommand('raw', CmdRaw);
  FApp.OnCommand('hide', CmdHide);
  FApp.OnCommand('stop', CmdStop);       // admin only, not listed in the menu

  // callbacks
  FApp.OnCallbackPrefix('page:', CbPage);
  FApp.OnCallbackPrefix('cnt:', CbCounter);
  FApp.OnCallback('about', CbAbout);
  FApp.OnCallback('noop', CbNoop);

  // other update kinds
  FApp.OnInlineQuery(OnInline);
  FApp.OnUpdateKind(ukMyChatMember, OnMyChatMember);

  // generic routes LAST: first match wins
  FApp.OnText(OnPlainText);
  FApp.OnMessage(OnAnyMessage);
end;

{ ---------------- plumbing ---------------- }

procedure TShowcase.DoLog(Sender: TObject; const AMessage: string);
begin
  Writeln('[', FormatDateTime('hh:nn:ss', Now), '] ', AMessage);
end;

procedure TShowcase.DoError(Sender: TObject; E: Exception; AUpdate: TTgUpdate);
begin
  if AUpdate <> nil then
    Writeln('[error] update ', AUpdate.UpdateId, ': ', E.ClassName, ': ', E.Message)
  else
    Writeln('[error] ', E.ClassName, ': ', E.Message);
end;

procedure TShowcase.SafeEdit(Ctx: TTgContext; const AText: string; const AMarkup: ITgReplyMarkup);
begin
  try
    Ctx.EditText(AText, AMarkup, PARSE_HTML);
  except
    on E: ETelegramApiError do
      // pressing a button that produces identical content is not an error for us
      if Pos('not modified', E.Description) = 0 then
        raise;
  end;
end;

procedure TShowcase.SaveIncomingFile(Ctx: TTgContext; AFile: TTgFileInfo; const AName: string);
var
  Path: string;
begin
  if (AFile.FileSize > 0) and (AFile.FileSize > MAX_DOWNLOAD_BYTES) then
  begin
    Ctx.Reply('The file is larger than 20 MB; the cloud Bot API does not allow downloading it.');
    Exit;
  end;
  ForceDirectories(FDownloadDir);
  Path := IncludeTrailingPathDelimiter(FDownloadDir) + SafeFileName(AName);
  Ctx.Typing;
  Ctx.Bot.DownloadFileTo(AFile.FileId, Path);
  Ctx.Reply('Saved: ' + SafeFileName(AName) + ' (' + IntToStr(AFile.FileSize) + ' bytes)');
end;

{ ---------------- keyboards / texts ---------------- }

function TShowcase.MainMenu: ITgReplyMarkup;
begin
  Result := ReplyKeyboard
    .Button('/menu').Button('/counter').Button('/poll')
    .Row
    .RequestContact('Share my phone number').RequestLocation('Share my location')
    .Row
    .Button('/help').Button('/hide')
    .Resize
    .Placeholder('Type a command or tap a button');
end;

function TShowcase.PageText(APage: Integer): string;
begin
  case APage of
    1: Result := '<b>Page 1: Updates</b>' + #10 +
         'Receive messages with long polling or a webhook. ' +
         'This demo uses long polling.';
    2: Result := '<b>Page 2: Context</b>' + #10 +
         'The <code>TTgContext</code> object has everything about the current update: ' +
         'Reply, Answer, EditText and more.';
  else
    Result := '<b>Page 3: Every method</b>' + #10 +
      'Every Bot API method is reachable through <code>Bot.Call</code>, even without a typed wrapper.';
  end;
end;

function TShowcase.PageKeyboard(APage: Integer): ITgReplyMarkup;
var
  K: ITgInlineKeyboard;
begin
  K := InlineKeyboard;
  if APage > 1 then
    K.Button('Previous', 'page:' + IntToStr(APage - 1));
  K.Button(IntToStr(APage) + ' / 3', 'noop');
  if APage < 3 then
    K.Button('Next', 'page:' + IntToStr(APage + 1));
  K.Row.Button('About', 'about').Url('Bot API docs', 'https://core.telegram.org/bots/api');
  Result := K;
end;

function TShowcase.CounterKeyboard(AValue: Integer): ITgReplyMarkup;
begin
  Result := InlineKeyboard
    .Button('-1', 'cnt:' + IntToStr(AValue - 1))
    .Button('+1', 'cnt:' + IntToStr(AValue + 1))
    .Row
    .Button('Reset', 'cnt:0');
end;

{ ---------------- commands ---------------- }

procedure TShowcase.CmdStart(Sender: TObject; Ctx: TTgContext);
var
  Name: string;
begin
  Name := 'friend';
  if Ctx.User <> nil then
    Name := Ctx.User.FullName;
  Ctx.ReplyHtml('Hello <b>' + HtmlEscape(Name) + '</b>!' + #10 +
    'This bot is the complete showcase of the <b>Telegram4D</b> library. ' +
    'Send /help for the list of features.', MainMenu);
end;

procedure TShowcase.CmdHelp(Sender: TObject; Ctx: TTgContext);
begin
  Ctx.ReplyHtml(
    '<b>Commands</b>' + #10 +
    '/menu - paginated inline menu' + #10 +
    '/counter - interactive counter' + #10 +
    '/whoami - information about you and the chat' + #10 +
    '/echo text - repeat the text' + #10 +
    '/format - HTML and MarkdownV2 formatting' + #10 +
    '/photo /document /location /contact - send different kinds of content' + #10 +
    '/poll /dice - poll and dice (for example <code>/dice dart</code>)' + #10 +
    '/typing /edit /selfdestruct - message behaviors' + #10 +
    '/copy - reply to a message first' + #10 +
    '/members - groups only' + #10 +
    '/ping /error /raw - diagnostics' + #10 + #10 +
    'Also: send a file or photo to have it downloaded; in any chat type ' +
    '<code>@your_bot text</code> (inline mode must be enabled in BotFather).');
end;

procedure TShowcase.CmdMenu(Sender: TObject; Ctx: TTgContext);
begin
  Ctx.ReplyHtml(PageText(1), PageKeyboard(1));
end;

procedure TShowcase.CmdCounter(Sender: TObject; Ctx: TTgContext);
begin
  Ctx.ReplyHtml('Value: <b>0</b>', CounterKeyboard(0));
end;

procedure TShowcase.CmdWhoAmI(Sender: TObject; Ctx: TTgContext);
var
  S: string;
begin
  S := '<b>You</b>' + #10;
  if Ctx.User <> nil then
  begin
    S := S + 'Name: ' + HtmlEscape(Ctx.User.FullName) + #10 +
      'ID: <code>' + IntToStr(Ctx.User.Id) + '</code>' + #10;
    if Ctx.User.Username <> '' then
      S := S + 'Username: @' + HtmlEscape(Ctx.User.Username) + #10;
    if Ctx.User.LanguageCode <> '' then
      S := S + 'Language: ' + HtmlEscape(Ctx.User.LanguageCode) + #10;
    if Ctx.User.IsPremium then
      S := S + 'Premium account' + #10;
  end;
  if Ctx.Chat <> nil then
  begin
    S := S + #10 + '<b>Chat</b>' + #10 +
      'ID: <code>' + IntToStr(Ctx.Chat.Id) + '</code>' + #10 +
      'Type: ' + HtmlEscape(Ctx.Chat.ChatType) + #10 +
      'Title: ' + HtmlEscape(Ctx.Chat.DisplayName) + #10;
  end;
  if Ctx.Message <> nil then
    S := S + #10 + 'Message time: ' + FormatDateTime('yyyy-mm-dd hh:nn:ss', Ctx.Message.Date) + ' UTC';
  Ctx.ReplyHtml(S);
end;

procedure TShowcase.CmdEcho(Sender: TObject; Ctx: TTgContext);
begin
  if Ctx.Args = '' then
    Ctx.Reply('Write some text after the command. Example: /echo hello')
  else
    Ctx.ReplyTo(Ctx.Args);
end;

procedure TShowcase.CmdFormat(Sender: TObject; Ctx: TTgContext);
var
  Mention: string;
begin
  Mention := 'no user';
  if Ctx.User <> nil then
    Mention := MentionHtml(Ctx.User.Id, 'mention');
  Ctx.ReplyHtml(
    '<b>bold</b> <i>italic</i> <u>underline</u> <s>strike</s> <code>code</code> ' +
    '<tg-spoiler>spoiler</tg-spoiler>' + #10 +
    '<a href="https://core.telegram.org/bots/api#formatting-options">link</a> | ' +
    Mention + #10 +
    '<pre>pre block' + #10 + 'second line</pre>' + #10 +
    '<blockquote>quote</blockquote>' + #10 +
    'User text with special characters: ' + HtmlEscape('1 < 2 & 3 > 2'));
  Ctx.Reply(
    '*bold* _italic_ __underline__ ~strike~ `code` ||spoiler||' + #10 +
    MarkdownV2Escape('MarkdownV2: 1+1=2 (escaped with MarkdownV2Escape)!'),
    nil, PARSE_MARKDOWN_V2);
end;

procedure TShowcase.CmdPhoto(Sender: TObject; Ctx: TTgContext);
var
  M: TTgMessage;
begin
  Ctx.Bot.SendChatAction(Ctx.ChatId, ACTION_UPLOAD_PHOTO);
  // a plain string converts to TTgInputFile: file_id or URL (Telegram downloads the URL)
  M := Ctx.Bot.SendPhoto(Ctx.ChatId, 'https://telegram.org/img/t_logo.png',
    'Photo sent by URL');
  M.Free;
end;

procedure TShowcase.CmdDocument(Sender: TObject; Ctx: TTgContext);
var
  S: TMemoryStream;
  M: TTgMessage;
  Txt: string;
begin
  Txt := 'Telegram4D ' + TELEGRAM4D_VERSION + #13#10 +
    'Bot API ' + TELEGRAM_BOT_API_VERSION + #13#10 +
    'Generated: ' + FormatDateTime('yyyy-mm-dd hh:nn:ss', Now) + #13#10;
  S := MakeTextStream(Txt);
  try
    M := Ctx.Bot.SendDocument(Ctx.ChatId, TTgInputFile.FromStream(S, 'report.txt'),
      'File created in memory and uploaded from a stream');
    M.Free;
  finally
    S.Free;
  end;
end;

procedure TShowcase.CmdLocation(Sender: TObject; Ctx: TTgContext);
var
  M: TTgMessage;
begin
  M := Ctx.Bot.SendLocation(Ctx.ChatId, 35.6997, 51.3380);
  M.Free;
end;

procedure TShowcase.CmdContact(Sender: TObject; Ctx: TTgContext);
var
  M: TTgMessage;
begin
  M := Ctx.Bot.SendContact(Ctx.ChatId, '+15555550100', 'Telegram4D', 'Demo');
  M.Free;
end;

procedure TShowcase.CmdPoll(Sender: TObject; Ctx: TTgContext);
var
  M: TTgMessage;
begin
  M := Ctx.Bot.SendPoll(Ctx.ChatId, 'Which do you like more?',
    ['Delphi', 'Free Pascal', 'Both'], False);
  M.Free;
end;

procedure TShowcase.CmdDice(Sender: TObject; Ctx: TTgContext);
var
  Emoji, A: string;
  M: TTgMessage;
begin
  A := LowerCase(Ctx.Args);
  if A = 'dart' then Emoji := EMOJI_DART
  else if A = 'basket' then Emoji := EMOJI_BASKET
  else if A = 'football' then Emoji := EMOJI_FOOTBALL
  else if A = 'bowling' then Emoji := EMOJI_BOWLING
  else if A = 'slot' then Emoji := EMOJI_SLOT
  else Emoji := EMOJI_DICE;
  M := Ctx.Bot.SendDice(Ctx.ChatId, Emoji);
  M.Free;
end;

procedure TShowcase.CmdTyping(Sender: TObject; Ctx: TTgContext);
begin
  Ctx.Typing;
  Sleep(2500);   // handlers run sequentially in the polling thread: keep them short
  Ctx.Reply('Done typing.');
end;

procedure TShowcase.CmdEdit(Sender: TObject; Ctx: TTgContext);
var
  M, M2: TTgMessage;
begin
  M := Ctx.Bot.SendMessage(Ctx.ChatId, 'Processing ...');
  try
    Sleep(1500);
    M2 := Ctx.Bot.EditMessageText(Ctx.ChatId, M.MessageId, 'Processing finished.');
    M2.Free;
  finally
    M.Free;
  end;
end;

procedure TShowcase.CmdSelfDestruct(Sender: TObject; Ctx: TTgContext);
var
  Id: Int64;
begin
  Id := Ctx.Bot.SendText(Ctx.ChatId, 'This message will be deleted in 3 seconds.');
  Sleep(3000);
  Ctx.Bot.DeleteMessage(Ctx.ChatId, Id);
end;

procedure TShowcase.CmdCopy(Sender: TObject; Ctx: TTgContext);
var
  R: TTgMessage;
begin
  R := Ctx.Message.ReplyToMessage;
  if R = nil then
    Ctx.Reply('Reply to a message and send /copy.')
  else
    Ctx.Bot.CopyMessage(Ctx.ChatId, Ctx.ChatId, R.MessageId);
end;

procedure TShowcase.CmdMembers(Sender: TObject; Ctx: TTgContext);
var
  Cnt: Int64;
  L: TTgList;
  I: Integer;
  CM: TTgChatMember;
  S: string;
begin
  if (Ctx.Chat = nil) or Ctx.Chat.IsPrivate then
  begin
    Ctx.Reply('This command only works in groups.');
    Exit;
  end;
  Cnt := Ctx.Bot.GetChatMemberCount(Ctx.ChatId);
  S := 'Members: <b>' + IntToStr(Cnt) + '</b>' + #10 + #10 + '<b>Administrators</b>';
  L := Ctx.Bot.GetChatAdministrators(Ctx.ChatId);
  try
    for I := 0 to L.Count - 1 do
    begin
      CM := TTgChatMember(L.Items[I]);
      if CM.User <> nil then
        S := S + #10 + HtmlEscape(CM.User.FullName) + ' (' + CM.Status + ')';
    end;
  finally
    L.Free;
  end;
  Ctx.ReplyHtml(S);
end;

procedure TShowcase.CmdPing(Sender: TObject; Ctx: TTgContext);
var
  T0: TDateTime;
  Me: TTgUser;
begin
  T0 := Now;
  Me := Ctx.Bot.GetMe;
  Me.Free;
  Ctx.Reply('Pong! getMe: ' + IntToStr(MilliSecondsBetween(Now, T0)) + ' ms');
end;

procedure TShowcase.CmdError(Sender: TObject; Ctx: TTgContext);
begin
  try
    // "text" is missing on purpose -> Telegram answers 400
    Ctx.Bot.CallBool('sendMessage', NewParams.Add('chat_id', Ctx.ChatId));
  except
    on E: ETelegramApiError do
      Ctx.ReplyHtml('API error with code <code>' + IntToStr(E.ErrorCode) + '</code>:' + #10 +
        HtmlEscape(E.Description));
  end;
end;

procedure TShowcase.CmdRaw(Sender: TObject; Ctx: TTgContext);
var
  S: string;
begin
  S := Ctx.Update.ToJSON;
  if Length(S) > 3500 then
    S := Copy(S, 1, 3500) + ' ...';
  Ctx.ReplyHtml('<pre>' + HtmlEscape(S) + '</pre>');
end;

procedure TShowcase.CmdHide(Sender: TObject; Ctx: TTgContext);
begin
  Ctx.Reply('Keyboard hidden. Send /start to show it again.', RemoveKeyboard);
end;

procedure TShowcase.CmdStop(Sender: TObject; Ctx: TTgContext);
begin
  if (FAdminId <> 0) and (Ctx.User <> nil) and (Ctx.User.Id = FAdminId) then
  begin
    Ctx.Reply('The bot is shutting down.');
    FShutdown := True;     // the main thread calls App.Stop (never call Stop from a handler)
  end
  else
    Ctx.Reply('You are not allowed to do that.');
end;

{ ---------------- callbacks ---------------- }

procedure TShowcase.CbPage(Sender: TObject; Ctx: TTgContext);
var
  N: Integer;
begin
  N := StrToIntDef(Copy(Ctx.CallbackData, 6, MaxInt), 1);
  if N < 1 then N := 1;
  if N > 3 then N := 3;
  Ctx.Answer;
  SafeEdit(Ctx, PageText(N), PageKeyboard(N));
end;

procedure TShowcase.CbCounter(Sender: TObject; Ctx: TTgContext);
var
  V: Integer;
begin
  V := StrToIntDef(Copy(Ctx.CallbackData, 5, MaxInt), 0);
  Ctx.Answer;
  SafeEdit(Ctx, 'Value: <b>' + IntToStr(V) + '</b>', CounterKeyboard(V));
end;

procedure TShowcase.CbAbout(Sender: TObject; Ctx: TTgContext);
begin
  Ctx.Answer('Telegram4D ' + TELEGRAM4D_VERSION + ' / Bot API ' + TELEGRAM_BOT_API_VERSION, True);
end;

procedure TShowcase.CbNoop(Sender: TObject; Ctx: TTgContext);
begin
  Ctx.Answer;
end;

{ ---------------- other update kinds ---------------- }

procedure TShowcase.OnInline(Sender: TObject; Ctx: TTgContext);
var
  Q: string;
  Arr: TJsonArray;
  O: TJsonObject;
begin
  Q := Ctx.Update.InlineQuery.Query;
  Arr := TJsonArray.Create;
  try
    if Q <> '' then
    begin
      O := Arr.AddObject;
      O.S['type'] := 'article';
      O.S['id'] := '1';
      O.S['title'] := 'UPPER: ' + UpperCase(Q);
      O.O['input_message_content'].S['message_text'] := UpperCase(Q);

      O := Arr.AddObject;
      O.S['type'] := 'article';
      O.S['id'] := '2';
      O.S['title'] := 'lower: ' + LowerCase(Q);
      O.O['input_message_content'].S['message_text'] := LowerCase(Q);
    end;
    Ctx.Bot.AnswerInlineQuery(Ctx.Update.InlineQuery.Id, Arr.ToJSON(True), 5, True);
  finally
    Arr.Free;
  end;
end;

procedure TShowcase.OnMyChatMember(Sender: TObject; Ctx: TTgContext);
var
  CM: TTgChatMemberUpdated;
begin
  CM := Ctx.Update.MyChatMember;
  if (CM <> nil) and (CM.Chat <> nil) and (CM.OldChatMember <> nil) and (CM.NewChatMember <> nil) then
    DoLog(Self, Format('my_chat_member in chat %d: %s -> %s',
      [CM.Chat.Id, CM.OldChatMember.Status, CM.NewChatMember.Status]));
end;

procedure TShowcase.OnPlainText(Sender: TObject; Ctx: TTgContext);
var
  Msg: TTgMessage;
  I: Integer;
  Ent: TTgMessageEntity;
  Links: string;
begin
  Msg := Ctx.Message;
  Links := '';
  for I := 0 to Msg.EntityCount - 1 do
  begin
    Ent := Msg.Entity(I);
    if Ent.EntityType = 'url' then
      Links := Links + #10 + Copy(Msg.Text, Ent.Offset + 1, Ent.Length)
    else if Ent.EntityType = 'text_link' then
      Links := Links + #10 + Ent.Url;
  end;
  Ctx.ReplyTo('Your text has ' + IntToStr(Length(Msg.Text)) + ' characters.' +
    IfThen(Links <> '', #10 + 'Links:' + Links, '') + #10 + #10 + 'Help: /help');
end;

procedure TShowcase.OnAnyMessage(Sender: TObject; Ctx: TTgContext);
var
  Msg: TTgMessage;
  I: Integer;
  S: string;
  Photo: TTgFileInfo;
begin
  Msg := Ctx.Message;
  if Msg = nil then
    Exit;

  if Msg.IsCommand then
    Ctx.Reply('Unknown command. Send /help.')
  else if Msg.NewChatMemberCount > 0 then
  begin
    S := '';
    for I := 0 to Msg.NewChatMemberCount - 1 do
      S := S + MentionHtml(Msg.NewChatMember(I).Id, Msg.NewChatMember(I).FullName) + ' ';
    Ctx.ReplyHtml('Welcome ' + S + '!');
  end
  else if Msg.Contact <> nil then
    Ctx.Reply('Contact received: ' + Msg.Contact.FirstName + ' ' + Msg.Contact.PhoneNumber)
  else if Msg.Location <> nil then
    Ctx.Reply(Format('Location received: %.5f, %.5f', [Msg.Location.Latitude, Msg.Location.Longitude]))
  else
  begin
    Photo := Msg.LargestPhoto;
    if Photo <> nil then
      SaveIncomingFile(Ctx, Photo, Photo.FileUniqueId + '.jpg')
    else if Msg.Document <> nil then
      SaveIncomingFile(Ctx, Msg.Document, Msg.Document.FileName)
    else if Msg.Voice <> nil then
      Ctx.Reply('Voice message of ' + IntToStr(Msg.Voice.Duration) + ' seconds received.')
    else if Msg.Sticker <> nil then
      Ctx.Reply('Sticker received: ' + Msg.Sticker.Emoji)
    else
      Ctx.Reply('This message type is not handled by the demo; use /raw to see its structure.');
  end;
end;

end.
