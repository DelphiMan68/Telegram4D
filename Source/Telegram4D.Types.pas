// Telegram4D - Telegram Bot API library for Delphi and Free Pascal
// Copyright 2026 Shaahin Ashayeri (https://github.com/DelphiMan68)
// SPDX-License-Identifier: Apache-2.0

unit Telegram4D.Types;

{ Typed, read-only views over Bot API objects.

  Every class wraps a JSON object instead of copying it into fields. Consequences:
    * Nothing is lost: any field Telegram adds in a future Bot API release is reachable
      immediately through Raw / HasField / FieldAsString, before this unit is updated.
    * Optional sub-objects return nil when absent - check Assigned() first.
    * Child objects (Message.From, Message.Chat ...) are owned by their parent. Only the
      object you got from a TTelegramBot call (or a TTgList) has to be freed by you. }

{$I Telegram4D.inc}

interface

uses
  Classes, SysUtils, Contnrs, DateUtils, Telegram4D.JSON;

type
  TTgObject = class;
  TTgObjectClass = class of TTgObject;

  TTgObject = class
  private
    FJson: TJsonObject;
    FRoot: TJsonBaseObject;
    FChildren: TObjectList;
    FCache: TStringList;
  protected
    function Has(const AName: string): Boolean;
    function GetStr(const AName: string): string;
    function GetInt(const AName: string): Int64;
    function GetFloat(const AName: string): Double;
    function GetBool(const AName: string): Boolean;
    function GetDate(const AName: string): TDateTime;
    function GetSub(AClass: TTgObjectClass; const AName: string): TTgObject;
    function GetSubAt(AClass: TTgObjectClass; const AArray: string; AIndex: Integer): TTgObject;
    function ArrayCount(const AName: string): Integer;
  public
    /// ARoot (optional) is freed together with this object.
    constructor Create(AJson: TJsonObject; ARoot: TJsonBaseObject = nil); virtual;
    destructor Destroy; override;
    function HasField(const AName: string): Boolean;
    /// Scalar field converted to string ('' when absent).
    function FieldAsString(const AName: string): string;
    function ToJSON: string;
    property Raw: TJsonObject read FJson;
  end;

  TTgUser = class(TTgObject)
  private
    function GetFullName: string;
  public
    function Id: Int64;
    function IsBot: Boolean;
    function FirstName: string;
    function LastName: string;
    function Username: string;
    function LanguageCode: string;
    function IsPremium: Boolean;
    property FullName: string read GetFullName;
  end;

  TTgChat = class(TTgObject)
  private
    function GetDisplayName: string;
  public
    function Id: Int64;
    function ChatType: string;
    function Title: string;
    function Username: string;
    function FirstName: string;
    function LastName: string;
    function IsForum: Boolean;
    function IsPrivate: Boolean;
    function IsGroup: Boolean;       // group or supergroup
    function IsChannel: Boolean;
    property DisplayName: string read GetDisplayName;
  end;

  TTgMessageEntity = class(TTgObject)
  public
    function EntityType: string;     // mention, hashtag, bot_command, url, bold, ...
    function Offset: Integer;
    function Length: Integer;
    function Url: string;
    function Language: string;
    function CustomEmojiId: string;
    function User: TTgUser;
  end;

  /// photo size, document, audio, video, voice, animation, video note, sticker, getFile result
  TTgFileInfo = class(TTgObject)
  public
    function FileId: string;
    function FileUniqueId: string;
    function FileSize: Int64;
    function FileName: string;
    function FilePath: string;
    function MimeType: string;
    function Width: Integer;
    function Height: Integer;
    function Duration: Integer;
    function Title: string;
    function Performer: string;
    function Emoji: string;
  end;

  TTgLocation = class(TTgObject)
  public
    function Latitude: Double;
    function Longitude: Double;
  end;

  TTgContact = class(TTgObject)
  public
    function PhoneNumber: string;
    function FirstName: string;
    function LastName: string;
    function UserId: Int64;
  end;

  TTgSuccessfulPayment = class(TTgObject)
  public
    function Currency: string;
    function TotalAmount: Int64;
    function InvoicePayload: string;
    function TelegramPaymentChargeId: string;
    function ProviderPaymentChargeId: string;
  end;

  TTgMessage = class(TTgObject)
  private
    function GetCommand: string;
    function GetCommandArgs: string;
    function GetIsCommand: Boolean;
    function GetLargestPhoto: TTgFileInfo;
  public
    function MessageId: Int64;
    function MessageThreadId: Int64;
    function Date: TDateTime;          // UTC
    function From: TTgUser;            // nil for channel posts
    function SenderChat: TTgChat;
    function Chat: TTgChat;
    function ReplyToMessage: TTgMessage;
    function Text: string;
    function Caption: string;
    function HasText: Boolean;
    function MediaGroupId: string;
    function EntityCount: Integer;
    function Entity(AIndex: Integer): TTgMessageEntity;
    function PhotoCount: Integer;
    function Photo(AIndex: Integer): TTgFileInfo;
    function Document: TTgFileInfo;
    function Audio: TTgFileInfo;
    function Video: TTgFileInfo;
    function VideoNote: TTgFileInfo;
    function Voice: TTgFileInfo;
    function Animation: TTgFileInfo;
    function Sticker: TTgFileInfo;
    function Location: TTgLocation;
    function Contact: TTgContact;
    function SuccessfulPayment: TTgSuccessfulPayment;
    function NewChatMemberCount: Integer;
    function NewChatMember(AIndex: Integer): TTgUser;
    function LeftChatMember: TTgUser;
    /// "/start@MyBot arg1 arg2" -> Command = 'start', CommandArgs = 'arg1 arg2'
    property IsCommand: Boolean read GetIsCommand;
    property Command: string read GetCommand;
    property CommandArgs: string read GetCommandArgs;
    /// Biggest photo of the message, or nil.
    property LargestPhoto: TTgFileInfo read GetLargestPhoto;
  end;

  TTgCallbackQuery = class(TTgObject)
  public
    function Id: string;
    function From: TTgUser;
    function Message: TTgMessage;      // may be nil (inline messages)
    function InlineMessageId: string;
    function ChatInstance: string;
    function Data: string;
    function GameShortName: string;
  end;

  TTgInlineQuery = class(TTgObject)
  public
    function Id: string;
    function From: TTgUser;
    function Query: string;
    function Offset: string;
  end;

  TTgPreCheckoutQuery = class(TTgObject)
  public
    function Id: string;
    function From: TTgUser;
    function Currency: string;
    function TotalAmount: Int64;
    function InvoicePayload: string;
  end;

  TTgChatMember = class(TTgObject)
  public
    function Status: string;
    function User: TTgUser;
    function IsMember: Boolean;
  end;

  TTgChatMemberUpdated = class(TTgObject)
  public
    function Chat: TTgChat;
    function From: TTgUser;
    function Date: TDateTime;
    function OldChatMember: TTgChatMember;
    function NewChatMember: TTgChatMember;
  end;

  TTgWebhookInfo = class(TTgObject)
  public
    function Url: string;
    function PendingUpdateCount: Integer;
    function LastErrorDate: TDateTime;
    function LastErrorMessage: string;
    function MaxConnections: Integer;
    function IpAddress: string;
  end;

  TTgUpdateKind = (
    ukUnknown, ukMessage, ukEditedMessage, ukChannelPost, ukEditedChannelPost,
    ukBusinessConnection, ukBusinessMessage, ukEditedBusinessMessage,
    ukDeletedBusinessMessages, ukMessageReaction, ukMessageReactionCount,
    ukInlineQuery, ukChosenInlineResult, ukCallbackQuery, ukShippingQuery,
    ukPreCheckoutQuery, ukPurchasedPaidMedia, ukPoll, ukPollAnswer,
    ukMyChatMember, ukChatMember, ukChatJoinRequest, ukChatBoost, ukRemovedChatBoost);

  TTgUpdate = class(TTgObject)
  private
    function GetKind: TTgUpdateKind;
    function GetEffectiveMessage: TTgMessage;
    function GetEffectiveChat: TTgChat;
    function GetEffectiveUser: TTgUser;
  public
    function UpdateId: Int64;
    function Message: TTgMessage;
    function EditedMessage: TTgMessage;
    function ChannelPost: TTgMessage;
    function EditedChannelPost: TTgMessage;
    function CallbackQuery: TTgCallbackQuery;
    function InlineQuery: TTgInlineQuery;
    function PreCheckoutQuery: TTgPreCheckoutQuery;
    function MyChatMember: TTgChatMemberUpdated;
    function ChatMember: TTgChatMemberUpdated;
    /// JSON key of the payload ('message', 'callback_query', ... or a key newer than this unit).
    function UpdateKey: string;
    property Kind: TTgUpdateKind read GetKind;
    /// message / edited_message / channel_post / edited_channel_post / callback_query.message
    property EffectiveMessage: TTgMessage read GetEffectiveMessage;
    property EffectiveChat: TTgChat read GetEffectiveChat;
    property EffectiveUser: TTgUser read GetEffectiveUser;
  end;

  /// Owns the response root and exposes the "result" array as typed items.
  TTgList = class
  private
    FRoot: TJsonObject;
    FArray: TJsonArray;
    FClass: TTgObjectClass;
    FItems: TObjectList;
    function GetCount: Integer;
  protected
    function GetItem(AIndex: Integer): TTgObject;
  public
    constructor Create(ARoot: TJsonObject; AClass: TTgObjectClass);
    destructor Destroy; override;
    property Count: Integer read GetCount;
    property Items[AIndex: Integer]: TTgObject read GetItem;
  end;

  TTgUpdateList = class(TTgList)
  private
    function GetUpdate(AIndex: Integer): TTgUpdate;
  public
    constructor Create(ARoot: TJsonObject);
    property Updates[AIndex: Integer]: TTgUpdate read GetUpdate; default;
  end;

const
  UPDATE_KEYS: array[TTgUpdateKind] of string = (
    '', 'message', 'edited_message', 'channel_post', 'edited_channel_post',
    'business_connection', 'business_message', 'edited_business_message',
    'deleted_business_messages', 'message_reaction', 'message_reaction_count',
    'inline_query', 'chosen_inline_result', 'callback_query', 'shipping_query',
    'pre_checkout_query', 'purchased_paid_media', 'poll', 'poll_answer',
    'my_chat_member', 'chat_member', 'chat_join_request', 'chat_boost', 'removed_chat_boost');

implementation

{ TTgObject }

constructor TTgObject.Create(AJson: TJsonObject; ARoot: TJsonBaseObject);
begin
  inherited Create;
  FJson := AJson;
  FRoot := ARoot;
  FChildren := TObjectList.Create(True);
  FCache := TStringList.Create;
  FCache.CaseSensitive := True;
end;

destructor TTgObject.Destroy;
begin
  FCache.Free;
  FChildren.Free;
  FRoot.Free;
  inherited;
end;

function TTgObject.Has(const AName: string): Boolean;
begin
  Result := (FJson <> nil) and FJson.Contains(AName);
end;

function TTgObject.HasField(const AName: string): Boolean;
begin
  Result := Has(AName);
end;

function TTgObject.GetStr(const AName: string): string;
begin
  if Has(AName) then
    Result := FJson.S[AName]
  else
    Result := '';
end;

function TTgObject.FieldAsString(const AName: string): string;
begin
  Result := GetStr(AName);
end;

function TTgObject.GetInt(const AName: string): Int64;
begin
  if Has(AName) then
    Result := FJson.L[AName]
  else
    Result := 0;
end;

function TTgObject.GetFloat(const AName: string): Double;
begin
  if Has(AName) then
    Result := FJson.F[AName]
  else
    Result := 0;
end;

function TTgObject.GetBool(const AName: string): Boolean;
begin
  if Has(AName) then
    Result := FJson.B[AName]
  else
    Result := False;
end;

function TTgObject.GetDate(const AName: string): TDateTime;
var
  U: Int64;
begin
  U := GetInt(AName);
  if U = 0 then
    Result := 0
  else
    Result := UnixToDateTime(U);
end;

function TTgObject.GetSub(AClass: TTgObjectClass; const AName: string): TTgObject;
var
  Idx: Integer;
  Obj: TJsonObject;
begin
  Result := nil;
  if not Has(AName) then
    Exit;
  Idx := FCache.IndexOf(AName);
  if Idx >= 0 then
  begin
    Result := TTgObject(FCache.Objects[Idx]);
    Exit;
  end;
  Obj := FJson.O[AName];
  if Obj = nil then
    Exit;
  Result := AClass.Create(Obj);
  FChildren.Add(Result);
  FCache.AddObject(AName, Result);
end;

function TTgObject.ArrayCount(const AName: string): Integer;
begin
  if Has(AName) then
    Result := FJson.A[AName].Count
  else
    Result := 0;
end;

function TTgObject.GetSubAt(AClass: TTgObjectClass; const AArray: string;
  AIndex: Integer): TTgObject;
var
  Key: string;
  Idx: Integer;
begin
  Result := nil;
  if (AIndex < 0) or (AIndex >= ArrayCount(AArray)) then
    Exit;
  Key := AArray + '#' + IntToStr(AIndex);
  Idx := FCache.IndexOf(Key);
  if Idx >= 0 then
  begin
    Result := TTgObject(FCache.Objects[Idx]);
    Exit;
  end;
  Result := AClass.Create(FJson.A[AArray].O[AIndex]);
  FChildren.Add(Result);
  FCache.AddObject(Key, Result);
end;

function TTgObject.ToJSON: string;
begin
  if FJson = nil then
    Result := 'null'
  else
    Result := FJson.ToJSON(True);
end;

{ TTgUser }

function TTgUser.Id: Int64;
begin
  Result := GetInt('id');
end;

function TTgUser.IsBot: Boolean;
begin
  Result := GetBool('is_bot');
end;

function TTgUser.FirstName: string;
begin
  Result := GetStr('first_name');
end;

function TTgUser.LastName: string;
begin
  Result := GetStr('last_name');
end;

function TTgUser.Username: string;
begin
  Result := GetStr('username');
end;

function TTgUser.LanguageCode: string;
begin
  Result := GetStr('language_code');
end;

function TTgUser.IsPremium: Boolean;
begin
  Result := GetBool('is_premium');
end;

function TTgUser.GetFullName: string;
begin
  Result := Trim(FirstName + ' ' + LastName);
end;

{ TTgChat }

function TTgChat.Id: Int64;
begin
  Result := GetInt('id');
end;

function TTgChat.ChatType: string;
begin
  Result := GetStr('type');
end;

function TTgChat.Title: string;
begin
  Result := GetStr('title');
end;

function TTgChat.Username: string;
begin
  Result := GetStr('username');
end;

function TTgChat.FirstName: string;
begin
  Result := GetStr('first_name');
end;

function TTgChat.LastName: string;
begin
  Result := GetStr('last_name');
end;

function TTgChat.IsForum: Boolean;
begin
  Result := GetBool('is_forum');
end;

function TTgChat.IsPrivate: Boolean;
begin
  Result := ChatType = 'private';
end;

function TTgChat.IsGroup: Boolean;
begin
  Result := (ChatType = 'group') or (ChatType = 'supergroup');
end;

function TTgChat.IsChannel: Boolean;
begin
  Result := ChatType = 'channel';
end;

function TTgChat.GetDisplayName: string;
begin
  Result := Title;
  if Result = '' then
    Result := Trim(FirstName + ' ' + LastName);
  if Result = '' then
    Result := Username;
end;

{ TTgMessageEntity }

function TTgMessageEntity.EntityType: string;
begin
  Result := GetStr('type');
end;

function TTgMessageEntity.Offset: Integer;
begin
  Result := GetInt('offset');
end;

function TTgMessageEntity.Length: Integer;
begin
  Result := GetInt('length');
end;

function TTgMessageEntity.Url: string;
begin
  Result := GetStr('url');
end;

function TTgMessageEntity.Language: string;
begin
  Result := GetStr('language');
end;

function TTgMessageEntity.CustomEmojiId: string;
begin
  Result := GetStr('custom_emoji_id');
end;

function TTgMessageEntity.User: TTgUser;
begin
  Result := TTgUser(GetSub(TTgUser, 'user'));
end;

{ TTgFileInfo }

function TTgFileInfo.FileId: string;
begin
  Result := GetStr('file_id');
end;

function TTgFileInfo.FileUniqueId: string;
begin
  Result := GetStr('file_unique_id');
end;

function TTgFileInfo.FileSize: Int64;
begin
  Result := GetInt('file_size');
end;

function TTgFileInfo.FileName: string;
begin
  Result := GetStr('file_name');
end;

function TTgFileInfo.FilePath: string;
begin
  Result := GetStr('file_path');
end;

function TTgFileInfo.MimeType: string;
begin
  Result := GetStr('mime_type');
end;

function TTgFileInfo.Width: Integer;
begin
  Result := GetInt('width');
end;

function TTgFileInfo.Height: Integer;
begin
  Result := GetInt('height');
end;

function TTgFileInfo.Duration: Integer;
begin
  Result := GetInt('duration');
end;

function TTgFileInfo.Title: string;
begin
  Result := GetStr('title');
end;

function TTgFileInfo.Performer: string;
begin
  Result := GetStr('performer');
end;

function TTgFileInfo.Emoji: string;
begin
  Result := GetStr('emoji');
end;

{ TTgLocation / TTgContact / TTgSuccessfulPayment }

function TTgLocation.Latitude: Double;
begin
  Result := GetFloat('latitude');
end;

function TTgLocation.Longitude: Double;
begin
  Result := GetFloat('longitude');
end;

function TTgContact.PhoneNumber: string;
begin
  Result := GetStr('phone_number');
end;

function TTgContact.FirstName: string;
begin
  Result := GetStr('first_name');
end;

function TTgContact.LastName: string;
begin
  Result := GetStr('last_name');
end;

function TTgContact.UserId: Int64;
begin
  Result := GetInt('user_id');
end;

function TTgSuccessfulPayment.Currency: string;
begin
  Result := GetStr('currency');
end;

function TTgSuccessfulPayment.TotalAmount: Int64;
begin
  Result := GetInt('total_amount');
end;

function TTgSuccessfulPayment.InvoicePayload: string;
begin
  Result := GetStr('invoice_payload');
end;

function TTgSuccessfulPayment.TelegramPaymentChargeId: string;
begin
  Result := GetStr('telegram_payment_charge_id');
end;

function TTgSuccessfulPayment.ProviderPaymentChargeId: string;
begin
  Result := GetStr('provider_payment_charge_id');
end;

{ TTgMessage }

function TTgMessage.MessageId: Int64;
begin
  Result := GetInt('message_id');
end;

function TTgMessage.MessageThreadId: Int64;
begin
  Result := GetInt('message_thread_id');
end;

function TTgMessage.Date: TDateTime;
begin
  Result := GetDate('date');
end;

function TTgMessage.From: TTgUser;
begin
  Result := TTgUser(GetSub(TTgUser, 'from'));
end;

function TTgMessage.SenderChat: TTgChat;
begin
  Result := TTgChat(GetSub(TTgChat, 'sender_chat'));
end;

function TTgMessage.Chat: TTgChat;
begin
  Result := TTgChat(GetSub(TTgChat, 'chat'));
end;

function TTgMessage.ReplyToMessage: TTgMessage;
begin
  Result := TTgMessage(GetSub(TTgMessage, 'reply_to_message'));
end;

function TTgMessage.Text: string;
begin
  Result := GetStr('text');
end;

function TTgMessage.Caption: string;
begin
  Result := GetStr('caption');
end;

function TTgMessage.HasText: Boolean;
begin
  Result := Has('text');
end;

function TTgMessage.MediaGroupId: string;
begin
  Result := GetStr('media_group_id');
end;

function TTgMessage.EntityCount: Integer;
begin
  Result := ArrayCount('entities');
end;

function TTgMessage.Entity(AIndex: Integer): TTgMessageEntity;
begin
  Result := TTgMessageEntity(GetSubAt(TTgMessageEntity, 'entities', AIndex));
end;

function TTgMessage.PhotoCount: Integer;
begin
  Result := ArrayCount('photo');
end;

function TTgMessage.Photo(AIndex: Integer): TTgFileInfo;
begin
  Result := TTgFileInfo(GetSubAt(TTgFileInfo, 'photo', AIndex));
end;

function TTgMessage.GetLargestPhoto: TTgFileInfo;
var
  I: Integer;
  P: TTgFileInfo;
begin
  Result := nil;
  for I := 0 to PhotoCount - 1 do
  begin
    P := Photo(I);
    if (Result = nil) or (Int64(P.Width) * P.Height > Int64(Result.Width) * Result.Height) then
      Result := P;
  end;
end;

function TTgMessage.Document: TTgFileInfo;
begin
  Result := TTgFileInfo(GetSub(TTgFileInfo, 'document'));
end;

function TTgMessage.Audio: TTgFileInfo;
begin
  Result := TTgFileInfo(GetSub(TTgFileInfo, 'audio'));
end;

function TTgMessage.Video: TTgFileInfo;
begin
  Result := TTgFileInfo(GetSub(TTgFileInfo, 'video'));
end;

function TTgMessage.VideoNote: TTgFileInfo;
begin
  Result := TTgFileInfo(GetSub(TTgFileInfo, 'video_note'));
end;

function TTgMessage.Voice: TTgFileInfo;
begin
  Result := TTgFileInfo(GetSub(TTgFileInfo, 'voice'));
end;

function TTgMessage.Animation: TTgFileInfo;
begin
  Result := TTgFileInfo(GetSub(TTgFileInfo, 'animation'));
end;

function TTgMessage.Sticker: TTgFileInfo;
begin
  Result := TTgFileInfo(GetSub(TTgFileInfo, 'sticker'));
end;

function TTgMessage.Location: TTgLocation;
begin
  Result := TTgLocation(GetSub(TTgLocation, 'location'));
end;

function TTgMessage.Contact: TTgContact;
begin
  Result := TTgContact(GetSub(TTgContact, 'contact'));
end;

function TTgMessage.SuccessfulPayment: TTgSuccessfulPayment;
begin
  Result := TTgSuccessfulPayment(GetSub(TTgSuccessfulPayment, 'successful_payment'));
end;

function TTgMessage.NewChatMemberCount: Integer;
begin
  Result := ArrayCount('new_chat_members');
end;

function TTgMessage.NewChatMember(AIndex: Integer): TTgUser;
begin
  Result := TTgUser(GetSubAt(TTgUser, 'new_chat_members', AIndex));
end;

function TTgMessage.LeftChatMember: TTgUser;
begin
  Result := TTgUser(GetSub(TTgUser, 'left_chat_member'));
end;

function TTgMessage.GetIsCommand: Boolean;
var
  T: string;
begin
  T := Text;
  Result := (Length(T) > 1) and (T[1] = '/');
end;

function TTgMessage.GetCommand: string;
var
  T: string;
  P: Integer;
begin
  Result := '';
  if not GetIsCommand then
    Exit;
  T := Text;
  P := 2;
  while (P <= Length(T)) and not CharInSet(T[P], [' ', #9, #10, #13, '@']) do
    Inc(P);
  Result := LowerCase(Copy(T, 2, P - 2));
end;

function TTgMessage.GetCommandArgs: string;
var
  T: string;
  P: Integer;
begin
  Result := '';
  if not GetIsCommand then
    Exit;
  T := Text;
  P := 2;
  while (P <= Length(T)) and not CharInSet(T[P], [' ', #9, #10, #13]) do
    Inc(P);
  Result := Trim(Copy(T, P + 1, MaxInt));
end;

{ TTgCallbackQuery }

function TTgCallbackQuery.Id: string;
begin
  Result := GetStr('id');
end;

function TTgCallbackQuery.From: TTgUser;
begin
  Result := TTgUser(GetSub(TTgUser, 'from'));
end;

function TTgCallbackQuery.Message: TTgMessage;
begin
  Result := TTgMessage(GetSub(TTgMessage, 'message'));
end;

function TTgCallbackQuery.InlineMessageId: string;
begin
  Result := GetStr('inline_message_id');
end;

function TTgCallbackQuery.ChatInstance: string;
begin
  Result := GetStr('chat_instance');
end;

function TTgCallbackQuery.Data: string;
begin
  Result := GetStr('data');
end;

function TTgCallbackQuery.GameShortName: string;
begin
  Result := GetStr('game_short_name');
end;

{ TTgInlineQuery }

function TTgInlineQuery.Id: string;
begin
  Result := GetStr('id');
end;

function TTgInlineQuery.From: TTgUser;
begin
  Result := TTgUser(GetSub(TTgUser, 'from'));
end;

function TTgInlineQuery.Query: string;
begin
  Result := GetStr('query');
end;

function TTgInlineQuery.Offset: string;
begin
  Result := GetStr('offset');
end;

{ TTgPreCheckoutQuery }

function TTgPreCheckoutQuery.Id: string;
begin
  Result := GetStr('id');
end;

function TTgPreCheckoutQuery.From: TTgUser;
begin
  Result := TTgUser(GetSub(TTgUser, 'from'));
end;

function TTgPreCheckoutQuery.Currency: string;
begin
  Result := GetStr('currency');
end;

function TTgPreCheckoutQuery.TotalAmount: Int64;
begin
  Result := GetInt('total_amount');
end;

function TTgPreCheckoutQuery.InvoicePayload: string;
begin
  Result := GetStr('invoice_payload');
end;

{ TTgChatMember / TTgChatMemberUpdated / TTgWebhookInfo }

function TTgChatMember.Status: string;
begin
  Result := GetStr('status');
end;

function TTgChatMember.User: TTgUser;
begin
  Result := TTgUser(GetSub(TTgUser, 'user'));
end;

function TTgChatMember.IsMember: Boolean;
begin
  Result := GetBool('is_member');
end;

function TTgChatMemberUpdated.Chat: TTgChat;
begin
  Result := TTgChat(GetSub(TTgChat, 'chat'));
end;

function TTgChatMemberUpdated.From: TTgUser;
begin
  Result := TTgUser(GetSub(TTgUser, 'from'));
end;

function TTgChatMemberUpdated.Date: TDateTime;
begin
  Result := GetDate('date');
end;

function TTgChatMemberUpdated.OldChatMember: TTgChatMember;
begin
  Result := TTgChatMember(GetSub(TTgChatMember, 'old_chat_member'));
end;

function TTgChatMemberUpdated.NewChatMember: TTgChatMember;
begin
  Result := TTgChatMember(GetSub(TTgChatMember, 'new_chat_member'));
end;

function TTgWebhookInfo.Url: string;
begin
  Result := GetStr('url');
end;

function TTgWebhookInfo.PendingUpdateCount: Integer;
begin
  Result := GetInt('pending_update_count');
end;

function TTgWebhookInfo.LastErrorDate: TDateTime;
begin
  Result := GetDate('last_error_date');
end;

function TTgWebhookInfo.LastErrorMessage: string;
begin
  Result := GetStr('last_error_message');
end;

function TTgWebhookInfo.MaxConnections: Integer;
begin
  Result := GetInt('max_connections');
end;

function TTgWebhookInfo.IpAddress: string;
begin
  Result := GetStr('ip_address');
end;

{ TTgUpdate }

function TTgUpdate.UpdateId: Int64;
begin
  Result := GetInt('update_id');
end;

function TTgUpdate.Message: TTgMessage;
begin
  Result := TTgMessage(GetSub(TTgMessage, 'message'));
end;

function TTgUpdate.EditedMessage: TTgMessage;
begin
  Result := TTgMessage(GetSub(TTgMessage, 'edited_message'));
end;

function TTgUpdate.ChannelPost: TTgMessage;
begin
  Result := TTgMessage(GetSub(TTgMessage, 'channel_post'));
end;

function TTgUpdate.EditedChannelPost: TTgMessage;
begin
  Result := TTgMessage(GetSub(TTgMessage, 'edited_channel_post'));
end;

function TTgUpdate.CallbackQuery: TTgCallbackQuery;
begin
  Result := TTgCallbackQuery(GetSub(TTgCallbackQuery, 'callback_query'));
end;

function TTgUpdate.InlineQuery: TTgInlineQuery;
begin
  Result := TTgInlineQuery(GetSub(TTgInlineQuery, 'inline_query'));
end;

function TTgUpdate.PreCheckoutQuery: TTgPreCheckoutQuery;
begin
  Result := TTgPreCheckoutQuery(GetSub(TTgPreCheckoutQuery, 'pre_checkout_query'));
end;

function TTgUpdate.MyChatMember: TTgChatMemberUpdated;
begin
  Result := TTgChatMemberUpdated(GetSub(TTgChatMemberUpdated, 'my_chat_member'));
end;

function TTgUpdate.ChatMember: TTgChatMemberUpdated;
begin
  Result := TTgChatMemberUpdated(GetSub(TTgChatMemberUpdated, 'chat_member'));
end;

function TTgUpdate.GetKind: TTgUpdateKind;
var
  K: TTgUpdateKind;
begin
  Result := ukUnknown;
  for K := Succ(ukUnknown) to High(TTgUpdateKind) do
    if Has(UPDATE_KEYS[K]) then
    begin
      Result := K;
      Exit;
    end;
end;

function TTgUpdate.UpdateKey: string;
var
  I: Integer;
begin
  Result := '';
  if Raw = nil then
    Exit;
  for I := 0 to Raw.Count - 1 do
    if Raw.Names[I] <> 'update_id' then
    begin
      Result := Raw.Names[I];
      Exit;
    end;
end;

function TTgUpdate.GetEffectiveMessage: TTgMessage;
var
  CB: TTgCallbackQuery;
begin
  Result := Message;
  if Result = nil then Result := EditedMessage;
  if Result = nil then Result := ChannelPost;
  if Result = nil then Result := EditedChannelPost;
  if Result = nil then
  begin
    CB := CallbackQuery;
    if CB <> nil then
      Result := CB.Message;
  end;
end;

function TTgUpdate.GetEffectiveChat: TTgChat;
var
  M: TTgMessage;
  CM: TTgChatMemberUpdated;
begin
  Result := nil;
  M := EffectiveMessage;
  if M <> nil then
    Result := M.Chat;
  if Result = nil then
  begin
    CM := MyChatMember;
    if CM = nil then
      CM := ChatMember;
    if CM <> nil then
      Result := CM.Chat;
  end;
end;

function TTgUpdate.GetEffectiveUser: TTgUser;
var
  M: TTgMessage;
  CM: TTgChatMemberUpdated;
begin
  Result := nil;
  if CallbackQuery <> nil then
    Result := CallbackQuery.From
  else if InlineQuery <> nil then
    Result := InlineQuery.From
  else if PreCheckoutQuery <> nil then
    Result := PreCheckoutQuery.From;
  if Result = nil then
  begin
    CM := MyChatMember;
    if CM = nil then
      CM := ChatMember;
    if CM <> nil then
      Result := CM.From;
  end;
  if Result = nil then
  begin
    M := Message;
    if M = nil then M := EditedMessage;
    if M = nil then M := ChannelPost;
    if M <> nil then
      Result := M.From;
  end;
end;

{ TTgList }

constructor TTgList.Create(ARoot: TJsonObject; AClass: TTgObjectClass);
begin
  inherited Create;
  FRoot := ARoot;
  FClass := AClass;
  FArray := FRoot.A['result'];
  FItems := TObjectList.Create(True);
  FItems.Count := FArray.Count;
end;

destructor TTgList.Destroy;
begin
  FItems.Free;
  FRoot.Free;
  inherited;
end;

function TTgList.GetCount: Integer;
begin
  Result := FArray.Count;
end;

function TTgList.GetItem(AIndex: Integer): TTgObject;
begin
  if FItems[AIndex] = nil then
    FItems[AIndex] := FClass.Create(FArray.O[AIndex]);
  Result := TTgObject(FItems[AIndex]);
end;

{ TTgUpdateList }

constructor TTgUpdateList.Create(ARoot: TJsonObject);
begin
  inherited Create(ARoot, TTgUpdate);
end;

function TTgUpdateList.GetUpdate(AIndex: Integer): TTgUpdate;
begin
  Result := TTgUpdate(GetItem(AIndex));
end;

end.
