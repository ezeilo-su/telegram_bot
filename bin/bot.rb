require 'telegram/bot'
require 'nokogiri'
# require 'open-uri'
require 'httparty'
require '../lib/scraper.rb'
require '../lib/api_keys.rb'
require 'country_lookup'
require 'time'

def scraper(html)
  JSON.parse(html)
end

def format_time(t_raw, timezone)
  Time.at(t_raw, in: timezone).strftime("%I:%M %p\r\n%A, %d/%m/%Y\r\n")
end

def format_message(weather)
  city = weather['name']
  cloud_cond = weather['weather'].first['description'].split(' ').map(&:capitalize).join(' ')
  temp_cel = (weather['main']['temp'] - 272.15).round
  temp_fah = ((weather['main']['temp'] - 272.15) * 1.8 + 32).round
  pressure = weather['main']['pressure']
  humidity = weather['main']['humidity']
  wind_speed = weather['wind']['speed']
  local_time = format_time(weather['dt'], weather['timezone'])
  country = Country.with_postal_code[weather['sys']['country']]

  "#{city}, #{country}"\
  "\r\nLocal Time: #{local_time}"\
  "\r\nWeather:"\
  "\r\nTemperature: #{temp_cel}°C | #{temp_fah}°F"\
  "\r\nCloud Condition: #{cloud_cond}"\
  "\r\nPressure: #{pressure} hPa"\
  "\r\nHumidity: #{humidity}%"\
  "\r\nWind Speed: #{wind_speed} m/s"
end

def welcome_message
  "\r\nEnter /weather <city> or /weather <city>,<country code> to get weather info."\
  "\r\nSend /end to end the chat. Use /start to start again next time."
end

chat_id_log = {}

Telegram::Bot::Client.run(YOUR_TELEGRAM_API_TOKEN) do |bot|
  bot.listen do |message|
    if message.text == '/start'
      unless chat_id_log[message.chat.id.to_s]
        chat_id_log[message.chat.id.to_s] = message.chat.id
        text = welcome_message
        bot.api.send_message(chat_id: message.chat.id, text: "Hello, #{message.from.first_name}#{text}")
      end
    elsif message.text == '/end'
      chat_id_log.delete(message.chat.id.to_s)
      bot.api.send_message(chat_id: message.chat.id, text: "Bye, #{message.from.first_name}!")
    elsif message.text.match(%r{\A/weather +\w+}) # matches weather plus one or more spaces at the start of a string, then one or more characters that follows
      city = message.text.slice('/weather'.length, message.text.length).lstrip
      if !city
        bot.api.send_message(chat_id: message.chat.id, text: 'City not provided. Try again!')
      else
        url = 'http://api.openweathermap.org/data/2.5/weather?q=' + city + '&appid=' + YOUR_OPENWEATHERMAP_API_KEY
        weather_html = HTTParty.get(url).to_s
        weather = scraper(weather_html)
        if weather['cod'] == '404' || weather['message'] == 'city not found'
          bot.api.send_message(chat_id: message.chat.id, text: 'City not found! Provide a valid city.')
        else
          chat_id = message.chat.id
          text = format_message(weather)
          bot.api.send_message(chat_id: chat_id, text: text)
        end
      end
    else
      bot.api.send_message(chat_id: message.chat.id, text: "Invalid input format. Try again!\r\nEnter /weather <city> or /weather <city>,<country code> to get weather info")
    end
  end
end
