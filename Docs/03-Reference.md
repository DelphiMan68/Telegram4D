# Reference

Library version `0.1.0`, Bot API `10.3` (constants `TELEGRAM4D_VERSION` and `TELEGRAM_BOT_API_VERSION` in `Telegram4D.Consts`).

## Telegram4D.Consts

`PARSE_HTML`, `PARSE_MARKDOWN_V2`, the `ACTION_*` types for `sendChatAction`, `CHAT_*` chat types and `STATUS_*` member statuses.

## Telegram4D.Errors

`ETelegram4D` <- `ETelegramNetworkError`, `ETelegramApiError` (`ErrorCode`, `Description`, `RetryAfter`, `MigrateToChatId`, `IsRateLimited`, `IsUnauthorized`, `IsForbidden`, `IsConflict`).

## Telegram4D.Utils

| Function | Purpose |
|---|---|
| `HtmlEscape(s)` | escapes `&`, `<`, `>` (mandatory for user text in HTML mode) |
| `MarkdownV2Escape(s)` | escapes every reserved MarkdownV2 character |
| `MentionHtml(id, name)` | a `tg://user?id=` mention link |

## Telegram4D.Params

### `TTgChatId`
A record built implicitly from `Int64` or `string`: `Bot.SendText(123456, ...)` or `Bot.SendText('@channel', ...)`.

### `TTgInputFile`
| Constructor | Meaning |
|---|---|
| `'AgACAg...'` (plain string), `TTgInputFile.FromId` / `FromUrl` | existing `file_id` or URL |
| `TTgInputFile.FromPath('C:\a.jpg')` | upload a local file (the internal stream is closed automatically) |
| `TTgInputFile.FromStream(Stream, 'name.ext')` | upload from a stream (you own the stream; keep it alive until the call returns) |

> Uploads are buffered in memory (the multipart body is built in a `TMemoryStream`). Cloud Bot API limits: 50 MB upload, 20 MB download.

### `ITgParams` (`NewParams`)
| Method | Purpose |
|---|---|
| `Add(name, string / Int64 / Boolean)` | add a parameter |
| `AddFloat(name, Double)` | floating point value (always uses a dot, locale independent) |
| `AddOpt(name, s)` / `AddOptInt(name, n)` | only when not empty / not zero |
| `AddChat(name, TTgChatId)` | a chat identifier |
| `AddJson(name, jsonText)` | a nested value (object or array) |
| `AddMarkup(markup)` | `reply_markup` (ignored when `nil`) |
| `AddInput(name, TTgInputFile)` | a file: reference or upload |
| `AddStrings(name, ['a','b'])` | an array of strings |

When an upload is present the request automatically becomes `multipart/form-data`, otherwise JSON.

## Telegram4D.Markup

All builders are interfaces: nothing to free, and calls chain.

**`InlineKeyboard`**: `Button(text, callbackData)`, `Url(text, url)`, `WebApp(text, url)`, `SwitchInline(text, query, currentChat)`, `Extra(name, value)` (arbitrary field on the last button), `Row` (start a new row).

**`ReplyKeyboard`**: `Button(text)`, `RequestContact(text)`, `RequestLocation(text)`, `WebApp(text, url)`, `Extra`, `Row`, `Resize`, `OneTime`, `Persistent`, `Placeholder(text)`, `Selective`.

**Others:** `RemoveKeyboard(selective)`, `ForceReply(placeholder)`.

```pascal
Bot.SendText(ChatId, 'Choose one',
  InlineKeyboard
    .Button('Yes', 'yes').Button('No', 'no')
    .Row
    .Url('Website', 'https://example.com'));
```

> `Extra` lets you use new button fields from newer Bot API versions without waiting for a library update; pass the name and value exactly as the official documentation describes them.

## Telegram4D.Types

All classes inherit `TTgObject`: `Raw`, `HasField`, `FieldAsString`, `ToJSON`.

| Class | Main members |
|---|---|
| `TTgUser` | `Id`, `IsBot`, `FirstName`, `LastName`, `FullName`, `Username`, `LanguageCode`, `IsPremium` |
| `TTgChat` | `Id`, `ChatType`, `Title`, `Username`, `DisplayName`, `IsPrivate`, `IsGroup`, `IsChannel`, `IsForum` |
| `TTgMessage` | `MessageId`, `MessageThreadId`, `Date` (UTC), `From`, `SenderChat`, `Chat`, `ReplyToMessage`, `Text`, `Caption`, `HasText`, `IsCommand`, `Command`, `CommandArgs`, `EntityCount`/`Entity(i)`, `PhotoCount`/`Photo(i)`/`LargestPhoto`, `Document`, `Audio`, `Video`, `VideoNote`, `Voice`, `Animation`, `Sticker`, `Location`, `Contact`, `SuccessfulPayment`, `NewChatMemberCount`/`NewChatMember(i)`, `LeftChatMember`, `MediaGroupId` |
| `TTgMessageEntity` | `EntityType`, `Offset`, `Length`, `Url`, `Language`, `CustomEmojiId`, `User` |
| `TTgFileInfo` | `FileId`, `FileUniqueId`, `FileSize`, `FileName`, `FilePath`, `MimeType`, `Width`, `Height`, `Duration`, `Title`, `Performer`, `Emoji` |
| `TTgCallbackQuery` | `Id`, `From`, `Message`, `InlineMessageId`, `ChatInstance`, `Data` |
| `TTgInlineQuery` | `Id`, `From`, `Query`, `Offset` |
| `TTgPreCheckoutQuery` | `Id`, `From`, `Currency`, `TotalAmount`, `InvoicePayload` |
| `TTgChatMember` / `TTgChatMemberUpdated` | `Status`, `User` / `Chat`, `From`, `Date`, `OldChatMember`, `NewChatMember` |
| `TTgWebhookInfo` | `Url`, `PendingUpdateCount`, `LastErrorDate`, `LastErrorMessage`, `MaxConnections`, `IpAddress` |
| `TTgUpdate` | `UpdateId`, `Kind`, `UpdateKey`, `Message`, `EditedMessage`, `ChannelPost`, `EditedChannelPost`, `CallbackQuery`, `InlineQuery`, `PreCheckoutQuery`, `MyChatMember`, `ChatMember`, `EffectiveMessage`, `EffectiveChat`, `EffectiveUser` |
| `TTgList` / `TTgUpdateList` | `Count`, `Items[i]` / `Updates[i]`; keeps the response root alive |

- For `/Start@MyBot arg`, `Command` is `start` (lower case, without the bot name) and `CommandArgs` is `arg`.
- `TTgMessageEntity.Offset/Length` are in UTF-16 code units; with Delphi/FPC (Unicode) strings they work directly in `Copy(Text, Offset + 1, Length)`.
- An update kind missing from `TTgUpdateKind` becomes `ukUnknown`; `UpdateKey` gives its key name and `Raw` its data.

## Telegram4D.Bot - `TTelegramBot`

### Properties
`Token`, `ApiUrl` (local Bot API server or reverse proxy), `DefaultParseMode`, `TimeoutMs` (30000), `RetryOnRateLimit` (True), `OnLog`, `HttpClient` (replace the transport).

### Constructor and proxy
`TTelegramBot.New(token, proxyHost, proxyPort)`, `SetProxy(host, port)`.

### Generic access (any Bot API method)
| Method | Returns |
|---|---|
| `Call(method, params)` | the response root (`TJsonObject`, you free it) |
| `CallBool` | the boolean `result` |
| `CallMessage` | a `TTgMessage` |
| `CallObject(TTgXxx, method, params)` | any type you choose |
| `CallList(TTgXxx, method, params)` | a `TTgList` over the `result` array |
| `CallTimeout(method, params, ms)` | like `Call` with a custom timeout |

### Typed methods
- **Bot and updates:** `GetMe`, `LogOut`, `GetUpdates`, `SetWebhook`, `DeleteWebhook`, `GetWebhookInfo`
- **Sending:** `SendMessage`, `SendText`, `SendPhoto`, `SendDocument`, `SendVideo`, `SendAudio`, `SendVoice`, `SendAnimation`, `SendVideoNote`, `SendSticker`, `SendLocation`, `SendContact`, `SendPoll`, `SendDice`, `SendChatAction`, `ForwardMessage`, `CopyMessage`
- **Editing and deleting:** `EditMessageText`, `EditInlineMessageText`, `EditMessageCaption`, `EditMessageReplyMarkup`, `DeleteMessage`, `PinChatMessage`, `UnpinChatMessage`
- **Callbacks, inline, payments:** `AnswerCallbackQuery`, `AnswerInlineQuery`, `AnswerPreCheckoutQuery`
- **Chats:** `GetChat`, `GetChatMember`, `GetChatMemberCount`, `GetChatAdministrators`, `BanChatMember`, `UnbanChatMember`, `LeaveChat`, `ApproveChatJoinRequest`, `DeclineChatJoinRequest`
- **Commands:** `SetMyCommands`, `DeleteMyCommands`
- **Files:** `GetFile`, `DownloadFile`, `DownloadFileTo`

Most sending methods have the optional parameters `Markup`, `ParseMode`, `ReplyTo` (id of the message being replied to) and `ThreadId` (forum topic).

## Telegram4D.App - `TTelegramApp`

| Member | Description |
|---|---|
| `Create(token, proxyHost, proxyPort)` | creates the internal bot (`App.Bot`) |
| `OnCommand`, `OnText`, `OnMessage`, `OnCallback`, `OnCallbackPrefix`, `OnInlineQuery`, `OnUpdateKind`, `OnAnyUpdate` | register routes; in Delphi each also has an anonymous-method overload |
| `Start` / `Stop` / `Active` | control long polling |
| `HandleWebhook(body, secretHeader)` | webhook entry point |
| `Dispatch(update)` | route a single update (useful for tests) |
| `PollTimeoutSec` | default 25 |
| `AllowedUpdates` | for example `'message,callback_query'` |
| `SyncDispatch` | run handlers in the main thread |
| `DeleteWebhookOnStart` | default True (avoids the 409 error) |
| `WebhookSecret` | expected value of `X-Telegram-Bot-Api-Secret-Token` |
| `OnError` | `procedure(Sender; E: Exception; AUpdate: TTgUpdate) of object` |

### `TTgContext`
`App`, `Bot`, `Update`, `Message`, `Chat`, `User`, `ChatId`, `Text`, `Args`, `CallbackData`; methods `Reply`, `ReplyHtml`, `ReplyTo`, `Answer`, `EditText`, `Typing`.

## Telegram4D.Http

The `ITgHttpClient` interface has three methods: `PostJson`, `PostMultipart`, `Download`. The default implementation is `TTgDefaultHttpClient` (`CreateDefaultHttpClient(proxyHost, proxyPort)`). See `04-Cookbook.md` for how to replace it.
