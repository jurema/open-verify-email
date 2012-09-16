# encoding: utf-8

require 'sinatra'
require 'net/smtp'
require 'resolv'
require 'sinatra/reloader' if development?

get '/' do
  erb :index
end

post '/verify' do
  response = []
  email = params[:email]

  if valid?(email)
    id, host = email.split('@')
    mx = Resolv::DNS.new.getresources(host, Resolv::DNS::Resource::IN::MX).map { |dns| dns.exchange.to_s }

    if mx.empty?
      response << "No MX records for host: #{host}"
    else
      smtp = Net::SMTP.start(mx[0], 25)
      response << smtp.helo('verify-email.io').string
      response << smtp.mailfrom('bot@verify-email.io').string
      begin
        response << smtp.rcptto(email).string
      rescue Net::SMTPFatalError => e
        response << e.message
      end
      smtp.finish
    end
  else
    response << "invalid email"
  end  

  erb :verify, :locals => { :response => response }
end

def valid?(email)
  /^[a-zA-Z0-9_.+\-]+@[a-zA-Z0-9\-]+\.[a-zA-Z0-9\-.]+$/ =~ email
end
