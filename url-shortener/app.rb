# app.rb
require 'sinatra'
require 'redis'
require 'uri'
require 'securerandom'

# Connect to Redis database
redis = Redis.new

URL_EXPIRATION_TIME = 24 * 60 * 60

get '/' do
  erb :index
end

post '/shorten' do
  long_url = params[:long_url]

  if valid_url?(long_url)
    short_url = generate_short_url

    redis.setex(short_url, URL_EXPIRATION_TIME, long_url)

    erb :result, locals: { short_url: short_url }
  else
    erb :invalid_url
  end
end

get '/:short_url' do |short_url|
  long_url = redis.get(short_url)

  if long_url
    redis.expire(short_url, URL_EXPIRATION_TIME)

    redirect long_url
  else
    erb :not_found
  end
end

def generate_short_url
  loop do
    short_url = SecureRandom.urlsafe_base64(6)
    break short_url unless redis.exists(short_url)
  end
end

def valid_url?(url)
  uri = URI.parse(url)
  uri.is_a?(URI::HTTP) && !uri.host.nil?
rescue URI::InvalidURIError
  false
end
