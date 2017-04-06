require 'rubygems'
require 'mechanize'
require 'fileutils'
require 'watir-webdriver'
require 'net/http'
require 'open-uri'
require 'progressbar'

URL = "http://startupstockphotos.com/"
count = 0
destination_directory = File.expand_path('~')+"/Downloads/stock_photos"
FileUtils::mkdir_p destination_directory
FILE_LOAD_TIME = 5


browser = Watir::Browser.new :firefox
browser.goto URL

parsed_images = Array.new
loop do
  data = Nokogiri::HTML(browser.html)
  images = data.css('a.post__img-container')

  images.each do |image|
    file_url = URI(image.attr('href'))
    next if parsed_images.include?(file_url)
    parsed_images << file_url
    count+=1
    filename = image.attr('href').split('/').last
    p "#{count}:  Downloading #{file_url} as #{filename}"
    Net::HTTP.start(file_url.host,file_url.port , :use_ssl => true) do |http|
      response = http.request_head(file_url)
      pbr = ProgressBar.create(title: filename ,starting_at: 0,:total => response['content-length'].to_i, progress_mark: "=", format: "%w")
      counter = 0
      File.open("#{destination_directory}/#{filename}","w") do |f|
        http.get(file_url) do |str|
          f.write str
          counter += str.length
          pbr.progress += str.length
        end
      end
    end
    # IO.copy_stream(open(file_url), )
  end
  break if browser.link(:text => "LOAD MORE").nil?
  browser.link(:text => "LOAD MORE").when_present.click
  sleep FILE_LOAD_TIME
end
