# encoding: utf-8

require 'sinatra'
require 'net/smtp'
require 'resolv'
require 'sinatra/reloader' if development?

get '/' do
  erb :index
end

post '/verify' do
  erb :verify, :locals => { :response => verify }
end

def valid?(email)
  /^[a-zA-Z0-9_.+\-]+@[a-zA-Z0-9\-]+\.[a-zA-Z0-9\-.]+$/ =~ email
end

def verify
  email = params[:email]

  return "Invalid email" unless valid?(email)

  id, host = email.split('@')
  mx = Resolv::DNS.new.getresources(host, Resolv::DNS::Resource::IN::MX).map { |dns| dns.exchange.to_s }

  return "No MX records were found for host: #{host}" if mx.empty?

  begin
    smtp = Net::SMTP.start(mx[0], 25)
    smtp.helo('verify-email.io').string
    smtp.mailfrom('bot@verify-email.io').string
    status = smtp.rcptto(email).status
    res = case status.to_s
            when "500" then "Sorry, email doesn't exist"
            when "250" then "Success! Email exists"
          end
    smtp.finish
  rescue Net::SMTPFatalError
    res = $!.to_s
  end
  res
end
