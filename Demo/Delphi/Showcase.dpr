// Telegram4D - Telegram Bot API library for Delphi and Free Pascal
// Copyright 2026 Shaahin Ashayeri (https://github.com/DelphiMan68)
// SPDX-License-Identifier: Apache-2.0

program Showcase;

{ Telegram4D showcase bot - Delphi.

  Environment variables:
    TELEGRAM_BOT_TOKEN   token from @BotFather (required)
    TELEGRAM_ADMIN_ID    your numeric Telegram id, enables /stop (optional)
  Command line:
    --proxy=host:port    route all traffic through an HTTP proxy (optional)

  Search path: ..\..\Source and the JsonDataObjects folder. }

{$APPTYPE CONSOLE}

uses
  SysUtils,
  Telegram4D.Types,
  Telegram4D.Bot,
  Telegram4D.App,
  Showcase.Handlers in 'Showcase.Handlers.pas';

function CmdLineValue(const AName: string): string;
var
  I: Integer;
  Prefix: string;
begin
  Result := '';
  Prefix := '--' + AName + '=';
  for I := 1 to ParamCount do
    if SameText(Copy(ParamStr(I), 1, Length(Prefix)), Prefix) then
      Exit(Copy(ParamStr(I), Length(Prefix) + 1, MaxInt));
end;

var
  App: TTelegramApp;
  Demo: TShowcase;
  Token, Proxy, ProxyHost: string;
  ProxyPort, P: Integer;
begin
  Token := GetEnvironmentVariable('TELEGRAM_BOT_TOKEN');
  if Token = '' then
  begin
    Writeln('Set the TELEGRAM_BOT_TOKEN environment variable first.');
    Halt(1);
  end;

  ProxyHost := '';
  ProxyPort := 0;
  Proxy := CmdLineValue('proxy');
  P := Pos(':', Proxy);
  if P > 0 then
  begin
    ProxyHost := Copy(Proxy, 1, P - 1);
    ProxyPort := StrToIntDef(Copy(Proxy, P + 1, MaxInt), 0);
  end;

  App := TTelegramApp.Create(Token, ProxyHost, ProxyPort);
  Demo := TShowcase.Create(App, StrToInt64Def(GetEnvironmentVariable('TELEGRAM_ADMIN_ID'), 0));
  try
    // Delphi only: anonymous handlers. Register BEFORE Demo.RegisterRoutes, because
    // the catch-all OnMessage route registered there would swallow later commands.
    App.OnCommand('hello',
      procedure(Ctx: TTgContext)
      begin
        Ctx.Reply('Hello from an anonymous method!');
      end);

    Demo.RegisterRoutes;
    App.Start;
    Writeln('Showcase bot is running. Send /start to your bot. Press Ctrl+C to quit.');
    while not Demo.ShutdownRequested do
      Sleep(200);
    App.Stop;
    Writeln('Stopped.');
  finally
    Demo.Free;
    App.Free;
  end;
end.
