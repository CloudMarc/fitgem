require 'fitgem'
require 'omniauth-fitbit'
require "fitgem"
require "pp"
require "yaml"
 
# Load the existing yml config
config = begin
  Fitgem::Client.symbolize_keys(YAML.load(File.open(".fitgem.yml")))
rescue ArgumentError => e
  puts "Could not parse YAML: #{e.message}"
  exit
end
client = Fitgem::Client.new(config[:oauth])

if config[:oauth][:token] && config[:oauth][:secret]
  begin
    access_token = client.reconnect(config[:oauth][:token], config[:oauth][:secret])
  rescue Exception => e
    puts "Error: Could not reconnect Fitgem::Client due to invalid keys in .fitgem.yml"
    exit
  end
# Without the secret and token, initialize the Fitgem::Client
# and send the user to login and get a verifier token
else
  request_token = client.request_token
  token = request_token.token
  secret = request_token.secret
 
  puts "Go to http://www.fitbit.com/oauth/authorize?oauth_token=#{token} and then enter the verifier code below"
  verifier = gets.chomp
 
  begin
    access_token = client.authorize(token, secret, { :oauth_verifier => verifier })
  rescue Exception => e
    puts "Error: Could not authorize Fitgem::Client with supplied oauth verifier"
    exit
  end
 
  puts 'Verifier is: '+verifier
  puts "Token is:    "+access_token.token
  puts "Secret is:   "+access_token.secret
 
  user_id = client.user_info['user']['encodedId']
  puts "Current User is: "+user_id
 
  config[:oauth].merge!(:token => access_token.token, :secret => access_token.secret, :user_id => user_id)
 
  # Write the whole oauth token set back to the config file
  File.open(".fitgem.yml", "w") {|f| f.write(config.to_yaml) }
end
 
# ============================================================
# Add Fitgem API calls on the client object below this line

#dt = Time.now - 2.days
#dt = Time.now.ago(2.days)
#dt = Date.today 
dt = Date.today - 1
nsteps = 0
i = 0 
while dt > Date.today - 31
  x = client.activities_on_date  dt
#x = client.data_by_time_range("/body/weight", {:base_date => "2011-03-03", :end_date => "2011-07-27"})
  steps = x['summary']['steps'].to_i
  i = i + 1
  puts steps.inspect + " " + dt.inspect + " " + i.inspect
  nsteps = nsteps + x['summary']['steps'].to_i
  dt = dt - 1
end
targ1 = nsteps.to_f/30.0
targ2 = 1.1*targ1
targ3 = 1.25*targ1
puts "Targets:  " + targ1.round(1).inspect + " " + targ2.round(1).inspect + " " + targ3.round(1).inspect

today_x = client.activities_on_date 'today' 
pp today_x
today_steps = today_x['summary']['steps'].to_i
puts "Today's steps so far:  " + today_steps.inspect
dt1 = targ1 - today_steps
if dt1 > 0
  puts "Number of steps remaining:  " + dt1.round(1).inspect
end
