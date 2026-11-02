# Architecture

## Layers

```
TTelegramApp  (Telegram4D.App)       router, long polling, webhook entry, TTgContext
      |
TTelegramBot  (Telegram4D.Bot)       Bot API methods  +  Call / CallBool / CallMessage / CallList
      |
ITgParams, TTgChatId, TTgInputFile   (Telegram4D.Params)     building requests
ITgReplyMarkup ...                   (Telegram4D.Markup)     keyboards
TTgUpdate, TTgMessage ...            (Telegram4D.Types)      read-only views of responses
      |
ITgHttpClient (Telegram4D.Http)      HTTP transport; replaceable
      |
TJsonObject   (Telegram4D.JSON)      JsonDataObjects
```

Each layer depends only on the layer below it. `Telegram4D.Consts`, `Telegram4D.Errors` and `Telegram4D.Utils` are shared units.

## Why are the types "views" and not copies?

The classes in `Telegram4D.Types` do not copy fields. Each one sits on top of the JSON object and reads a field when you ask for it. Consequences:

- **Forward compatibility:** when Telegram adds a field or an update type, it is available immediately through `Raw`, `HasField('x')` and `FieldAsString('x')`; you do not wait for a library update.
- **No conversion cost:** only the fields you read are processed.
- **Optional field = `nil`:** an absent sub-object returns `nil` (`Message.From`, `Message.ReplyToMessage`, ...). Always check `Assigned`.

## Memory ownership

| Object | Who frees it |
|---|---|
| Result of `Send*`, `Get*`, `Call*` (`TTgMessage`, `TTgChat`, `TTgUser`, `TTgFileInfo`, `TTgList` ...) | **You** |
| Sub-objects (`Msg.From`, `Msg.Chat`, `Msg.Photo(i)`, `List.Items[i]`) | Their parent (do not free) |
| `TTgUpdate` inside a handler, and `TTgContext` | The library |
| `ITgParams`, `ITgReplyMarkup` and keyboards | Reference counted (interfaces), no Free needed |
| `SendText`, `Ctx.Reply`, `Ctx.Answer`, `Ctx.EditText` | Nothing is returned |

Standard pattern:

```pascal
M := Bot.SendMessage(ChatId, 'Hello');
try
  Writeln(M.MessageId);
finally
  M.Free;
end;
```

## Threading

- `TTelegramApp.Start` creates a thread that loops on `getUpdates`. Updates are processed **one after another** (not in parallel), so do not put long `Sleep` calls in handlers.
- Default: handlers run in that background thread. If a handler touches VCL/FMX/LCL controls, set `App.SyncDispatch := True` (requires a message loop).
- **Never call `App.Stop` from inside a handler** (the thread would wait for itself). Set a flag and let the main thread call `Stop`; the demo does exactly that.
- The default HTTP implementation creates a fresh client for every request, so `TTelegramBot` methods can be called from several threads; just do not change properties (`Token`, `ApiUrl`, proxy ...) while requests are in flight.
- `Stop` may block up to `PollTimeoutSec` seconds (default 25) while the pending `getUpdates` returns.

## Router

Routes are checked in registration order and the **first match** handles the update.

| Registration | Matches |
|---|---|
| `OnCommand('start', ...)` | a `/start` or `/start@BotName args` message |
| `OnCallback('data', ...)` | `callback_query.data` exactly equal |
| `OnCallbackPrefix('page:', ...)` | `data` starts with the prefix |
| `OnInlineQuery(...)` | any `inline_query` |
| `OnUpdateKind(ukMyChatMember, ...)` | any chosen update kind |
| `OnText(...)` | a text message that is not a command |
| `OnMessage(...)` | **any** message (commands included) |
| `OnAnyUpdate(...)` | anything |

> Consequence of "first match wins": register the generic routes (`OnText`, `OnMessage`, `OnAnyUpdate`) **last**, otherwise commands registered after them never run.

## Error handling

| Exception | Meaning |
|---|---|
| `ETelegramApiError` | Telegram answered `ok=false`. Has `ErrorCode`, `Description`, `RetryAfter`, `MigrateToChatId`, and `IsRateLimited` / `IsUnauthorized` / `IsForbidden` / `IsConflict` |
| `ETelegramNetworkError` | network failure, timeout, TLS problem, or a non-JSON answer |
| `ETelegram4D` | API misuse (for example an empty token) |

- An exception inside a handler is caught and delivered to `App.OnError` (and `Bot.OnLog`); the polling loop keeps running.
- HTTP 429 (rate limit) is retried automatically up to 3 times, waiting `retry_after` seconds (`Bot.RetryOnRateLimit`).
- In the polling loop: a wrong token (401) stops polling; network errors are retried with a growing delay (1 to 30 seconds).
