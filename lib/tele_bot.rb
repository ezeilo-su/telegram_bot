require 'time'
require 'net/http'
require 'country_lookup'

class BotUser
  def initialize(bot)
    @bot = bot
  end

  def send_welcome_message(message)
    text = "Hello, #{message.from.first_name}\r\n#{HelpMessage.new(user: self, message: message).help_msg}"
    @bot.api.send_message(chat_id: message.chat.id, text: text)
  end

  def reply_invalid_format(message)
    text = "Invalid input format. Try again!\r\n" + HelpMessage.new(user: self, message: message).help_msg
    @bot.api.send_message(chat_id: message.chat.id, text: text)
  end

  def send_goodbye(message)
    @bot.api.send_message(chat_id: message.chat.id, text: "Bye, #{message.from.first_name}!")
  end

  attr_reader :bot
end

class WeatherInfo
  def initialize(user:, message:)
    @message = message
    @bot = user.bot
  end

  def send_response
    city = @message.text.slice('/weather'.length, @message.text.length).strip
    if !city
      @bot.api.send_message(chat_id: @message.chat.id, text: 'City not provided. Try again!')
    else
      url = URI('http://api.openweathermap.org/data/2.5/weather?q=' + city + '&appid=' + OPENWEATHERMAP_API_KEY)
      weather_html = Net::HTTP.get(url)
      weather = Scraper.parse_json(weather_html)
      if weather['cod'] == '404' || weather['message'] == 'city not found'
        @bot.api.send_message(chat_id: @message.chat.id, text: 'City not found! Provide a valid city.')
      else
        @bot.api.send_message(chat_id: @message.chat.id, text: Format.output_message(weather))
      end
    end
  end
end

class HelpMessage
  def initialize(user:, message:)
    @bot = user.bot
    @message = message
  end

  def send_response
    @bot.api.send_message(chat_id: @message.chat.id, text: help_msg)
  end

  def help_msg
    "\r\nEnter /weather <city> or /weather <city>,<country code> to get weather info."\
    "\r\nSend /end to end the chat. Use /start to start again next time."
  end
end

class MessageHandler
  attr_reader :user, :message

  def initialize(user, message)
    @user = user
    @message = message
  end

  def handle_message
    case @message.text
    when '/start'
      @user.send_welcome_message(@message)
    when '/end'
      @user.send_goodbye(@message)
    when %r{\A/weather +\w+}
      WeatherInfo.new(user: @user, message: @message).send_response
    when '/help'
      HelpMessage.new(user: @user, message: @message).send_response
    else
      @user.reply_invalid_format(@message)
    end
  end
end
