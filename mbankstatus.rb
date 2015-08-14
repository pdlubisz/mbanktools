#!/usr/bin/env ruby

require 'json'
require 'nokogiri'
require 'open-uri'
require 'mechanize'
require 'securerandom'
require 'json'

login_url = 'https://online.mbank.pl/pl/Login'

urls = {
	login: 'https://online.mbank.pl/pl/LoginMain/Account/JsonLogin',
	account_list: 'https://online.mbank.pl/pl/MyDesktop/Desktop/GetAccountsList',
	logout: 'https://online.mbank.pl/pl/LoginMain/Account/Logout',
	main: 'https://online.mbank.pl/pl'
}

mechanize = Mechanize.new
mechanize.user_agent_alias = 'Mac Safari'
#To get cookies
page = mechanize.get(login_url)

# Login information:
login_details = {
	UserName: '01234567',
	Password: 'password',
	Seed: SecureRandom.base64(16),
	Scenario: 'Default',
	UWAdditionalParams: {InOut: "", ReturnAddress: "", Source: ""},
	Lang: '',
}
#from FF debug
#{"UserName":"01234567","Password":"password","Seed":"cH-LnWl5iUSj9-COAZt8jw==","Scenario":"Default","UWAdditionalParams":{"InOut":"","ReturnAddress":"","Source":""},"Lang":""}
#json_login = '{"UserName":login_details[:name],"Password":login_details[:pass],"Seed":login_details[:seed],"Scenario":"Default","UWAdditionalParams":{"InOut":"","ReturnAddress":"","Source":""},"Lang":""}'

json_login = JSON.generate(login_details)

login_to_mbank = mechanize.post(urls[:login],json_login,{'Content-Type' => 'application/json; charset=utf-8'})
puts json_login
puts 'How did the login go?'
puts login_to_mbank.body

main_page = mechanize.get(urls[:main])
puts main_page.body

#Doesn't work. Gives me server 500
#empty_json = JSON.generate({})
#account_list = mechanize.post(urls[:account_list],'{}',{'Content-Type' => 'application/json'})
#puts account_list.body

#logout
mechanize.get(urls[:logout])

