require_relative '../lib/parser'
require_relative '../lib/tele_bot'
require 'telegram/bot'
require_relative '../env.rb'

OPENWEATHERMAP_API_KEY = 'ee0d92f2309953f56ed99eb09e4e1159'.freeze

class TeleBot
  def run_bot(token)
    Telegram::Bot::Client.run(token) do |bot|
      bot.listen do |message|
        user = BotUser.new(bot)
        MessageHandler.new(user, message).handle_message
      end
    end
  end
end

TeleBot.new.run_bot(TELEGRAM_API_TOKEN)
