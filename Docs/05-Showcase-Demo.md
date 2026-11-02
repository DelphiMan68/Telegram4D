# Complete Demo (Showcase)

A console bot that demonstrates almost every feature of the library. The code lives in two folders, and both use the same `Showcase.Handlers` unit:

```
Demo/
  Delphi/
    Showcase.dpr            Delphi program (includes an anonymous handler example)
    Showcase.Handlers.pas   all handlers
  FreePascal/
    Showcase.lpr            Free Pascal / Lazarus program
    Showcase.Handlers.pas   the same unit (copy)
```

## Running it

1. Create a bot with BotFather and copy the token. To try inline mode also send `/setinline`.
2. Environment variables:
   - `TELEGRAM_BOT_TOKEN` (required)
   - `TELEGRAM_ADMIN_ID` your numeric id (optional; enables `/stop`; `/whoami` shows your id)
3. Add `..\..\Source` and the JsonDataObjects folder to the project search path.
   - **Delphi:** open `Showcase.dpr` as a console project, build and run.
   - **Lazarus:** *Project > New Project from File*, choose `Showcase.lpr`, and set the paths in *Project Options > Compiler Options > Paths > Other unit files*.
   - **FPC command line:** `fpc -MDelphi -Fu../../Source -Fu<JsonDataObjects path> Showcase.lpr`
4. If Telegram is blocked on your network: `Showcase --proxy=127.0.0.1:10809`.
5. Send `/start` to your bot in Telegram.

> Downloaded files go to a `downloads` folder next to the executable.

## Features and where they are implemented

| Command / event | Demonstrates | Method in `Showcase.Handlers` |
|---|---|---|
| `/start` | reply keyboard (contact/location requests, `Resize`, `Placeholder`) and `ReplyHtml` | `CmdStart`, `MainMenu` |
| `/help` | HTML text | `CmdHelp` |
| `/menu` | paginated inline keyboard, editing a message in place, URL button, `OnCallbackPrefix` | `CmdMenu`, `CbPage`, `PageKeyboard` |
| `/counter` | state kept in callback data; ignoring "message is not modified" | `CmdCounter`, `CbCounter`, `SafeEdit` |
| the "About" button | `Answer` with an alert | `CbAbout` |
| `/whoami` | `Ctx.User`, `Ctx.Chat`, message time (UTC) | `CmdWhoAmI` |
| `/echo text` | `Ctx.Args`, `ReplyTo` (reply) | `CmdEcho` |
| `/format` | HTML, MarkdownV2, `HtmlEscape`, `MarkdownV2Escape`, `MentionHtml` | `CmdFormat` |
| `/photo` | sending a photo by URL, `ACTION_UPLOAD_PHOTO` | `CmdPhoto` |
| `/document` | uploading from a `TMemoryStream` with `TTgInputFile.FromStream` | `CmdDocument` |
| `/location`, `/contact` | `SendLocation`, `SendContact` | `CmdLocation`, `CmdContact` |
| `/poll` | `SendPoll` with `array of string` | `CmdPoll` |
| `/dice [dart\|basket\|football\|bowling\|slot]` | `SendDice` with an emoji | `CmdDice` |
| `/typing` | `SendChatAction` | `CmdTyping` |
| `/edit` | `SendMessage` then `EditMessageText` | `CmdEdit` |
| `/selfdestruct` | `SendText` then `DeleteMessage` | `CmdSelfDestruct` |
| `/copy` (reply to a message) | `ReplyToMessage`, `CopyMessage` | `CmdCopy` |
| `/members` (groups only) | `GetChatMemberCount`, `GetChatAdministrators` and `TTgList` | `CmdMembers` |
| `/ping` | `GetMe` and latency measurement | `CmdPing` |
| `/error` | catching `ETelegramApiError` | `CmdError` |
| `/raw` | `Update.ToJSON` (raw JSON access) | `CmdRaw` |
| `/hide` | `RemoveKeyboard` | `CmdHide` |
| `/stop` | admin-only command; safe shutdown from the main thread | `CmdStop` |
| `@bot text` | inline query (`AnswerInlineQuery`) | `OnInline` |
| sending a photo or file | download with `DownloadFileTo` (20 MB limit) | `OnAnyMessage`, `SaveIncomingFile` |
| sending a contact, location, voice, sticker | reading the types | `OnAnyMessage` |
| new member joins a group | `NewChatMember(i)` and a mention | `OnAnyMessage` |
| bot blocked/unblocked or added to a group | the `my_chat_member` update | `OnMyChatMember` |
| plain text | character count and link extraction from `Entity(i)` | `OnPlainText` |
| `/hello` | anonymous handler (Delphi demo only) | `Showcase.dpr` |

## Design points the demo follows

- **Route order:** commands and callbacks first, `OnText` and `OnMessage` last (`RegisterRoutes`).
- **Safe shutdown:** `/stop` only sets the `ShutdownRequested` flag; the main program calls `App.Stop`.
- **Errors:** an exception in any handler reaches `OnError` and polling continues.
- **Memory:** every returned `TTgMessage` is freed; `SendText` and `Ctx.*` return nothing to free.
- **State in callback data:** the counter keeps its value in `callback_data`, so the bot needs no session storage (`callback_data` is limited to 64 bytes).
- **Long work:** the `Sleep` calls in `/typing`, `/edit` and `/selfdestruct` are for demonstration only; in a real bot move long work to a separate thread.

## Extending the demo

1. Write a new method `procedure CmdXyz(Sender: TObject; Ctx: TTgContext)`.
2. Register it in `RegisterRoutes` before `OnText`/`OnMessage` with `FApp.OnCommand('xyz', CmdXyz)`.
3. Add it to `SetMyCommands` if you want it in Telegram's command menu.
