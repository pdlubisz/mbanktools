#!/usr/bin/env ruby

require 'json'
require 'mechanize'
require 'securerandom'
require 'highline/import'
require 'nokogiri'

login_url = 'https://online.mbank.pl/pl/Login'

urls = {
	login: 'https://online.mbank.pl/pl/LoginMain/Account/JsonLogin',
	account_list: 'https://online.mbank.pl/pl/MyDesktop/Desktop/GetAccountsList',
	logout: 'https://online.mbank.pl/pl/LoginMain/Account/Logout',
	main: 'https://online.mbank.pl/pl',
	top: 'https://online.mbank.pl/csite/top.aspx',
        set_nav_data: 'https://online.mbank.pl/pl/MyDesktop/Desktop/SetNavigationDataForAccount',
        details_for_nav: 'https://online.mbank.pl/pl/Accounts/Accounts/DetailsForNav',
}

mechanize = Mechanize.new
mechanize.user_agent_alias = 'Mac Safari'
#To get cookies
page = mechanize.get(login_url)

# Login information:
login_details = {
	UserName: nil,
	Password: nil,
	Seed: SecureRandom.base64(16),
	Scenario: 'Default',
	UWAdditionalParams: {InOut: "", ReturnAddress: "", Source: ""},
	Lang: '',
}

login_details[:UserName] = ask("Enter username: "){ |q| q.echo = true}
login_details[:Password] = ask("Enter password: "){|q| q.echo = "*"}
#from FF debug
#{"UserName":"01234567","Password":"password","Seed":"cH-LnWl5iUSj9-COAZt8jw==","Scenario":"Default","UWAdditionalParams":{"InOut":"","ReturnAddress":"","Source":""},"Lang":""}
#json_login = '{"UserName":login_details[:name],"Password":login_details[:pass],"Seed":login_details[:seed],"Scenario":"Default","UWAdditionalParams":{"InOut":"","ReturnAddress":"","Source":""},"Lang":""}'

json_login = JSON.generate(login_details)

login_to_mbank = mechanize.post(urls[:login],json_login,{'Content-Type' => 'application/json; charset=utf-8'})
puts 'How did the login go?'
puts JSON.parse(login_to_mbank.body)["successful"]

main_page = mechanize.get(urls[:main])
page = Nokogiri::HTML(main_page.body, &:noblanks)
ajax_token = page.css("meta[name='__AjaxRequestVerificationToken']").attr("content")
puts "Retrieved AJAX token: '#{ajax_token}'"

top_page = mechanize.get(urls[:top])
puts top_page.body

account_list = mechanize.post(urls[:account_list],'{}',{
                                'X-Requested-With' => 'XMLHttpRequest',
                                'X-Request-Verification-Token' => ajax_token,
                                'X-Tab-Id' => mechanize.cookies.select { |c| c.name == 'mBank_tabId' }.shift.value
                              })

accounts = JSON.parse(account_list.body)

puts accounts

for account in accounts['accountDetailsList'] do
  type = account['ProductName']
  iban = account['AccountNumber']
  currency = account['Currency']
  balance = account['Balance']
  avail_balance = account['AvailableBalance']
  puts "Account type='#{type}' iban='#{iban}' balance='#{balance} #{currency} (avail #{avail_balance} #{currency})' "

  # Get teh account details
  nav_select = mechanize.post(urls[:set_nav_data], { 'accountNumber' => iban }, {
                                'X-Requested-With' => 'XMLHttpRequest',
                                'X-Request-Verification-Token' => ajax_token,
                                'X-Tab-Id' => mechanize.cookies.select { |c| c.name == 'mBank_tabId' }.shift.value
                              } )

  nav_details = mechanize.post(urls[:details_for_nav], '', {
                                'X-Requested-With' => 'XMLHttpRequest',
                                'X-Request-Verification-Token' => ajax_token,
                                'X-Tab-Id' => mechanize.cookies.select { |c| c.name == 'mBank_tabId' }.shift.value
                              } )
  puts JSON.parse(nav_details.body)
  puts ""
end

#logout
mechanize.get(urls[:logout])

