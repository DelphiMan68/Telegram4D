// Telegram4D - Telegram Bot API library for Delphi and Free Pascal
// Copyright 2026 Shaahin Ashayeri (https://github.com/DelphiMan68)
// SPDX-License-Identifier: Apache-2.0

unit Telegram4D.Consts;

{$I Telegram4D.inc}

interface

const
  TELEGRAM4D_VERSION       = '0.1.0';
  TELEGRAM_BOT_API_VERSION = '10.3';   // latest Bot API this library was written against
  TELEGRAM_API_URL         = 'https://api.telegram.org';

  // parse_mode
  PARSE_HTML        = 'HTML';
  PARSE_MARKDOWN_V2 = 'MarkdownV2';

  // sendChatAction
  ACTION_TYPING          = 'typing';
  ACTION_UPLOAD_PHOTO    = 'upload_photo';
  ACTION_RECORD_VIDEO    = 'record_video';
  ACTION_UPLOAD_VIDEO    = 'upload_video';
  ACTION_RECORD_VOICE    = 'record_voice';
  ACTION_UPLOAD_VOICE    = 'upload_voice';
  ACTION_UPLOAD_DOCUMENT = 'upload_document';
  ACTION_FIND_LOCATION   = 'find_location';

  // chat types
  CHAT_PRIVATE    = 'private';
  CHAT_GROUP      = 'group';
  CHAT_SUPERGROUP = 'supergroup';
  CHAT_CHANNEL    = 'channel';

  // chat member statuses
  STATUS_CREATOR       = 'creator';
  STATUS_ADMINISTRATOR = 'administrator';
  STATUS_MEMBER        = 'member';
  STATUS_RESTRICTED    = 'restricted';
  STATUS_LEFT          = 'left';
  STATUS_KICKED        = 'kicked';

implementation

end.
