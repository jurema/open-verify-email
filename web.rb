# encoding: utf-8

require 'sinatra'
require 'net/smtp'
require 'resolv'
require 'sinatra/reloader' if development?

get '/' do
  erb :index
end

post '/verify' do
  email = params[:email]

  response = verify(email)

  erb :verify, :locals => { :response => response }
end

def valid?(email)
  /^[a-zA-Z0-9_.+\-]+@[a-zA-Z0-9\-]+\.[a-zA-Z0-9\-.]+$/ =~ email
end

def verify(email)
  return "Invalid email" unless valid?(email)

  id, host = email.split('@')
  mx = Resolv::DNS.new.getresources(host, Resolv::DNS::Resource::IN::MX).map { |dns| dns.exchange.to_s }

  return "No MX records were found for host: #{host}" if mx.empty?

  begin
    smtp = Net::SMTP.start(mx[0], 25)
    smtp.helo('verify-email.io').string
    smtp.mailfrom('bot@verify-email.io').string
    response = smtp.rcptto(email).string
    smtp.finish
  rescue Net::SMTPFatalError
    response = $!.to_s
  end
  response
end
