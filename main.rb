require 'rubygems'
require 'sinatra'

set :sessions, true

get '/' do
	if session[:name]
		redirect '/game'
	else
		redirect '/new_player'
	end
end

get '/new_player' do
	erb :new_player
end

post '/new_player' do 
	session[:name] = params['name']
	redirect '/game'
end

get '/game' do
	# create a deck and put it in session
	ranks = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A']
	suits = ['♦', '♣', '♥', '♠']
	session[:deck] = ranks.product(suits).shuffle!

	# deal cards
	session[:dealer_cards] = []
	session[:player_cards] = []
	session[:dealer_cards] << session[:deck].pop
	session[:player_cards] << session[:deck].pop
	session[:dealer_cards] << session[:deck].pop
	session[:player_cards] << session[:deck].pop

	erb :game
end

#----------------EXAMPLE: NESTED TEMPLATE------------------------------------
#get '/nested_template' do #nested template example
#	erb :'/users/profile'
#end
