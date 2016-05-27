# encoding: utf-8
require 'rest-client'
require 'json'
require 'date'
require 'csv'
require 'yaml'

CONFIG = YAML.load_file('./secrets/secrets.yml')

date = Date.today-2

file_date = date.strftime("%Y%m")
csv_file_name = "reviews_#{ENV["PKGNAME"]}_#{file_date}.csv"

system "BOTO_PATH=./secrets/.boto gsutil/gsutil cp -r gs://#{CONFIG["app_repo"]}/reviews/#{csv_file_name} . > log.log 2>&1"

class Telegram
  def self.notify(message)
   message.collect do |t|
   telegram_chat_id = "#{CONFIG["telegram_chat_id"]}"
    RestClient.post CONFIG["telegram_url"],
      { chat_id: telegram_chat_id, "parse_mode": "HTML", text: t }.to_json,
    content_type: :json,
    accept: :json
   end 
  end
end

class Review
  def self.collection
    @collection ||= []
  end

  def self.send_reviews_from_date(date)
    message = collection.select do |r| r.submitted_at > date && (r.title || r.text) end.sort_by do |r| r.submitted_at end.map do |r| r.build_message end
    
    if message != ""
      Telegram.notify(message)
    else
      print "No new reviews\n"
    end
  end

  attr_accessor :text, :title, :submitted_at, :original_subitted_at, :rate, :device, :url, :version, :edited, :pkgname

  def initialize data = {}
    @text = data[:text] ? data[:text].to_s.encode("utf-8") : nil
    @title = data[:title] ? "<b>#{data[:title].to_s.encode("utf-8")}</b>\n" : nil

    @submitted_at = DateTime.parse(data[:submitted_at].encode("utf-8"))
    @original_subitted_at = DateTime.parse(data[:original_subitted_at].encode("utf-8"))

    @rate = data[:rate].encode("utf-8").to_i
    @device = data[:device] ? data[:device].to_s.encode("utf-8") : nil
    @url = data[:url].to_s.encode("utf-8")
    @version = data[:version] ? "[#{data[:version].to_s.encode("utf-8")}]" : nil
    @pkgname = data[:pkgname].to_s.encode("utf-8")
    @edited = data[:edited]
  end

  def build_message
    date = if edited
             "размещено: #{original_subitted_at.strftime("%d.%m.%Y at %I:%M%p")}, изменено: #{submitted_at.strftime("%d.%m.%Y at %I:%M%p")}"
           else
             "размещено: #{submitted_at.strftime("%d.%m.%Y at %I:%M%p")}"
           end

    stars = rate.times.map{"★"}.join + (5 - rate).times.map{"☆"}.join

    [
      "\n\n#{stars}",
      "App: #{pkgname}#{version} | #{date}",
      "#{[title, text].join}",
      "<a href=\"#{url}\">Ответить в Google play</a>"
    ].join("\n")
  end
end

CSV.foreach(csv_file_name, encoding: 'bom|utf-16le', headers: true) do |row|
  Review.collection << Review.new({
    text: row[11],
    title: row[10],
    submitted_at: row[7],
    edited: (row[5] != row[7]),
    original_subitted_at: row[5],
    rate: row[9],
    device: row[4],
    url: row[15],
    version: row[1],
    pkgname: row[0],
  })
end

Review.send_reviews_from_date(date)
