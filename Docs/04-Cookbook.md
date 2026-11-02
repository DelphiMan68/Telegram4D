# Cookbook

## Any Bot API method without a wrapper

```pascal
// A method Bot.* does not wrap: setChatTitle
Bot.CallBool('setChatTitle',
  NewParams.AddChat('chat_id', ChatId).Add('title', 'New title'));

// A method that returns an object: getChat
Chat := TTgChat(Bot.CallObject(TTgChat, 'getChat', NewParams.AddChat('chat_id', ChatId)));
try ... finally Chat.Free; end;

// Restricting a member with a nested object
Bot.CallBool('restrictChatMember',
  NewParams.AddChat('chat_id', ChatId).Add('user_id', UserId)
    .AddJson('permissions', '{"can_send_messages":false}'));
```

Take method and parameter names from the [official documentation](https://core.telegram.org/bots/api).

## Files

```pascal
// From a file_id or URL
Bot.SendPhoto(ChatId, 'https://example.com/a.jpg', 'Caption').Free;

// Local file
Bot.SendDocument(ChatId, TTgInputFile.FromPath('C:\Reports\a.pdf')).Free;

// From a stream (for example an image generated in memory)
Bot.SendPhoto(ChatId, TTgInputFile.FromStream(MS, 'chart.png')).Free;

// Download a file the user sent
Bot.DownloadFileTo(Msg.Document.FileId, 'C:\Downloads\' + Msg.Document.FileName);
```

## Escaping text (HTML / MarkdownV2)

Always escape user text, otherwise Telegram rejects the message with a 400 error:

```pascal
Ctx.ReplyHtml('Hello ' + HtmlEscape(Ctx.User.FullName));
Ctx.Reply(MarkdownV2Escape('Price: 1.5$ (discount!)'), nil, PARSE_MARKDOWN_V2);
```

For a default format: `Bot.DefaultParseMode := PARSE_HTML`.

## Replies, forum topics, silent messages

```pascal
Bot.SendMessage(ChatId, 'Text', nil, '', Msg.MessageId);          // reply
Bot.SendMessage(ChatId, 'Text', nil, '', 0, Msg.MessageThreadId); // same topic
```
For parameters without a wrapper argument (such as `disable_notification`) use `CallMessage('sendMessage', NewParams....)`.

## Inline queries

1. In BotFather: `/setinline`.
2. `App.OnInlineQuery(...)` and `AnswerInlineQuery(id, resultsJson)`. See `OnInline` in the showcase demo.

## Webhook

The library has no HTTP server; hand the request body to `HandleWebhook`. Example with Indy:

```pascal
procedure TMyServer.OnCommandPost(AContext: TIdContext;
  ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
var
  Body: string;
begin
  Body := ReadStringFromStream(ARequestInfo.PostStream, -1, IndyTextEncoding_UTF8);
  try
    App.HandleWebhook(Body, ARequestInfo.RawHeaders.Values['X-Telegram-Bot-Api-Secret-Token']);
    AResponseInfo.ResponseNo := 200;
  except
    AResponseInfo.ResponseNo := 403;
  end;
end;
```

Registering the webhook (once):

```pascal
App.WebhookSecret := 'a-random-string';
App.Bot.SetWebhook('https://example.com/telegram', App.WebhookSecret, True, 40,
  'message,callback_query');
```
- The URL must be **HTTPS** with a valid certificate (allowed ports: 443, 80, 88, 8443).
- Do not call `App.Start` in webhook mode. To go back to polling call `Bot.DeleteWebhook` (`Start` does this itself).
- Answer with 200 quickly and move heavy work to another thread, otherwise Telegram retries the request.

## Replacing the HTTP transport (for example RESTRequest4Delphi)

```pascal
type
  TMyHttp = class(TInterfacedObject, ITgHttpClient)
    function PostJson(const AUrl, ABody: string; ATimeoutMs: Integer): string;
    function PostMultipart(const AUrl: string; const AFields: TTgFormFields;
      const AUploads: TTgUploads; ATimeoutMs: Integer): string;
    procedure Download(const AUrl: string; ADest: TStream; ATimeoutMs: Integer);
  end;

Bot.HttpClient := TMyHttp.Create;
```
Contract: `PostJson` and `PostMultipart` return the response JSON text (even for 4xx errors) and raise `ETelegramNetworkError` only for network failures; `Download` raises for any status other than 200.

## Local Bot API server (`telegram-bot-api`)

```pascal
Bot.ApiUrl := 'http://localhost:8081';
```
With a local server the upload limit is 2000 MB; the `file_path` returned by `getFile` may be an absolute path on the server's disk (no HTTP download needed, and `DownloadFile` does not apply).

## Logging

```pascal
Bot.OnLog := MyLogMethod;   // procedure(Sender: TObject; const AMessage: string) of object
App.OnError := MyErrorMethod;
```
The library deliberately never logs the token, but the token is part of the request URL and some HTTP clients include the URL in their error messages, so do not publish logs.

## Troubleshooting

| Symptom | Cause and fix |
|---|---|
| `Telegram API error 401` | wrong token; polling stops automatically |
| `Telegram API error 409` | a webhook is active, or another instance of the bot is calling `getUpdates` |
| `Telegram API error 400: can't parse entities` | user text was not escaped (`HtmlEscape` / `MarkdownV2Escape`) |
| `Telegram API error 400: message is not modified` | `EditText` with identical content; ignore it (see `SafeEdit` in the demo) |
| `Telegram API error 403: bot was blocked by the user` | the user blocked the bot; check `E.IsForbidden` |
| `Telegram API error 429` | send rate limit; wait `RetryAfter` seconds (automatic retry is on) |
| `ETelegramNetworkError` with a timeout | network or filtering problem; try `SetProxy` and raise `TimeoutMs` |
| FPC: SSL / TLS error | install OpenSSL (`libssl` / `libcrypto`) next to the program or system wide |
| Non-ASCII text looks broken in the console | a console display issue, not the library; in FPC set `DefaultSystemCodePage := CP_UTF8` |
| Delphi turns non-ASCII literals into `?` | save the source file as **UTF-8 with BOM** (the shipped sources are plain ASCII) |
