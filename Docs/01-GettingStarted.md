# Getting Started

## 1. Requirements

| Item | Delphi | Free Pascal |
|---|---|---|
| Compiler | Delphi 10.3 or newer | FPC 3.2 or newer (Delphi mode) |
| HTTP | `System.Net.HttpClient` (built in) | `fphttpclient` + `opensslsockets` (built in), OpenSSL installed |
| JSON | [JsonDataObjects](https://github.com/ahausladen/JsonDataObjects) | a JsonDataObjects version that compiles with FPC |

> The original JsonDataObjects targets Delphi only. All Telegram4D code reaches JSON exclusively through the `Telegram4D.JSON` unit, so swapping the JSON backend for FPC means changing that one unit.

## 2. Installation

1. Add the `Source` folder and the JsonDataObjects folder to the project **search path** (Lazarus: *Other unit files*).
2. On Unix with FPC, `cthreads` must be the first unit in the program's `uses` clause (the FreePascal demo already does this).
3. No package (`.dpk` / `.lpk`) is required; just add the units.

## 3. Getting a token

Talk to **@BotFather** in Telegram, send `/newbot` and copy the token. Do not hard-code the token; read it from an environment variable or a settings file.

## 4. Your first bot

```pascal
program FirstBot;
{$APPTYPE CONSOLE}
uses
  SysUtils, Telegram4D.Types, Telegram4D.App;
var
  App: TTelegramApp;
begin
  App := TTelegramApp.Create(GetEnvironmentVariable('TELEGRAM_BOT_TOKEN'));
  try
    App.OnCommand('start',
      procedure(Ctx: TTgContext)
      begin
        Ctx.Reply('Hello!');
      end);
    App.OnText(
      procedure(Ctx: TTgContext)
      begin
        Ctx.ReplyTo('You said: ' + Ctx.Text);
      end);
    App.Start;            // long polling in a background thread
    Readln;
    App.Stop;
  finally
    App.Free;
  end;
end.
```

In **Free Pascal** (and in Delphi too) a handler is a method:

```pascal
type
  THandlers = class
    procedure Start(Sender: TObject; Ctx: TTgContext);
  end;

procedure THandlers.Start(Sender: TObject; Ctx: TTgContext);
begin
  Ctx.Reply('Hello!');
end;

// ...
App.OnCommand('start', H.Start);
```

## 5. Sending without the router

```pascal
Bot := TTelegramBot.New(Token);
try
  Bot.SendText(123456789, 'Hello');          // numeric chat id
  Bot.SendText('@mychannel', 'New post');    // channel
finally
  Bot.Free;
end;
```

## 6. Telegram blocked on your network?

```pascal
App := TTelegramApp.Create(Token, '127.0.0.1', 10809);   // HTTP proxy
// or
Bot.SetProxy('127.0.0.1', 10809);
```

## 7. Next steps

- Structure and memory ownership rules: `02-Architecture.md`
- Classes and methods: `03-Reference.md`
- Ready-made recipes (webhook, payments, files, ...): `04-Cookbook.md`
- Walkthrough of the complete demo: `05-Showcase-Demo.md`
