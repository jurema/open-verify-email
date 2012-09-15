# encoding: utf-8
require 'sinatra'
require 'net/smtp'
require 'resolv'

get '/' do
  '<form action="/verify" method="post"><input type="text" name="email" /><input type="submit"/></form>'
end

post '/verify' do
  response = []
  email = params[:email]

  if valid?(email)
    id, host = email.split('@')
    mx = Resolv::DNS.new.getresources(host, Resolv::DNS::Resource::IN::MX).map { |dns| dns.exchange.to_s }

    smtp = Net::SMTP.start(mx[0], 25)
    response << smtp.helo('verify-email.io').string
    response << smtp.mailfrom('bot@verify-email.io').string
    begin
      response << smtp.rcptto(email).string
    rescue Net::SMTPFatalError => e
      response << e.message
    end
    smtp.finish
  else
    response << "invalid email"
  end  

  response.each do |response|
    response
  end

  erb :verify, :locals => { :response => response }
end

def valid?(email)
  /^[a-zA-Z0-9_.+\-]+@[a-zA-Z0-9\-]+\.[a-zA-Z0-9\-.]+$/ =~ email
end
