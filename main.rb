require 'rubygems'
require 'sinatra'

set :sessions, true

BLACKJACK_AMT  = 21
DEALER_MIN_HIT = 17
INITIAL_POT    = 500

helpers do

	def card_image(card)
		rank = card[0]
		suit = case card[1]
			when 'B' then 'balloons'
			when 'A' then 'apples'
			when 'F' then 'flutters'
			when 'G' then 'gems'
		end
	
		"<img src='/images/cards/#{rank} of #{suit}.png' class='card_image'>"
	end

	def calculate_total(cards)
		card_ranks = cards.map {|card| card[0]}
		total = 0

		card_ranks.each do |value|
			if value == 'A'
				total += 11
			elsif value.to_i == 0
				total += 10
			else
				total += value.to_i
			end
		end
	
		card_ranks.select {|card| card == 'A'}.count.times do
			break if total <= BLACKJACK_AMT
			total -= 10
		end

		total
	end

	def winner!(msg)
		@play_again = true
		@show_hit_or_stay_buttons = false
		session[:player_pot] = session[:player_pot] + session[:player_bet]
		@success = "Congratulations #{session[:player_name]}, #{msg} You win!"
	end

	def loser!(msg)
		@play_again = true
		@show_hit_or_stay_buttons = false
		session[:player_pot] = session[:player_pot] - session[:player_bet]
		@error = "Sorry #{session[:player_name]}, #{msg} You lose."
	end

	def tie!(msg)
		@play_again = true
		@show_hit_or_stay_buttons = false
		@error = "you and the dealer both ended with #{msg} It's a push."
	end

end

before do
	@show_hit_or_stay_buttons = true
end

get '/' do
	if session[:player_name]
		redirect '/game'
	else
		redirect '/new_player'
	end
end

get '/new_player' do
	session[:player_pot] = INITIAL_POT
	erb :new_player
end

post '/new_player' do
	if params[:player_name].empty? || params[:player_name].nil?
		@error = "Name is required, please enter a name."
		halt erb(:new_player)
	else
	  session[:player_name] = params['name']
	  redirect '/bet'
  end
end

get '/bet' do
	session[:player_bet] = nil
	erb :bet
end

post '/bet' do
	if params[:bet_amount].nil? || params[:bet_amount].to_i == 0
		@error = 'You must place a bet.'
		halt erb(:bet)
	elsif params[:bet_amount].to_i > session[:player_pot]
		@error = "Bet amount cannot be greater than the amount in your pot. ($#{session[:player_pot]})"
		halt erb(:bet)
	else
		session[:player_bet] = params[:bet_amount].to_i
		redirect '/game'
	end
end


get '/game' do
	session[:turn] = session[:player_name]

	ranks = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A']
	suits = ['B', 'A', 'F', 'G']
	session[:deck] = ranks.product(suits).shuffle!

	session[:dealer_cards] = []
	session[:player_cards] = []
	session[:dealer_cards] << session[:deck].pop
	session[:player_cards] << session[:deck].pop
	session[:dealer_cards] << session[:deck].pop
	session[:player_cards] << session[:deck].pop
	
	dealer_total = calculate_total(session[:dealer_cards])
	player_total = calculate_total(session[:player_cards])

	if player_total == BLACKJACK_AMT || dealer_total == BLACKJACK_AMT
		@show_hit_or_stay_buttons = false
		redirect '/determine_winner'
	end
	erb :game
end

post '/hit' do
	session[:player_cards] << session[:deck].pop
	player_total = calculate_total(session[:player_cards])

	if player_total == BLACKJACK_AMT || player_total > BLACKJACK_AMT
		redirect '/determine_winner'
	end
	erb :game
end

post '/stay' do
	@show_hit_or_stay_buttons = false
	@success = "#{session[:player_name]}, you have chosen to stay."
	redirect '/dealer_turn'
end

get '/dealer_turn' do
	session[:turn] = 'dealer'
	@show_hit_or_stay_buttons = false
	
	dealer_total = calculate_total(session[:dealer_cards])

	if dealer_total > DEALER_MIN_HIT
		redirect '/determine_winner'
	else
		@show_dealer_hit_button = true
	end

	erb :game
end

post '/dealer_hit' do
	session[:dealer_cards] << session[:deck].pop
	redirect '/dealer_turn'
end

get '/determine_winner' do
	@show_hit_or_stay_buttons = false
	dealer_total = calculate_total(session[:dealer_cards])
	player_total = calculate_total(session[:player_cards])

	if player_total == BLACKJACK_AMT && dealer_total == BLACKJACK_AMT
		tie!("blackjack.")
	elsif player_total == BLACKJACK_AMT
		winner!("you got Blackjack!")
	elsif dealer_total == BLACKJACK_AMT
		loser!("the dealer got Blackjack.")
	elsif dealer_total > BLACKJACK_AMT
		winner!("dealer busted!")
	elsif player_total > BLACKJACK_AMT
		loser!("you went over #{BLACKJACK_AMT.to_s}.")
	elsif player_total > dealer_total
		winner!("your #{player_total.to_s} beats dealers #{dealer_total.to_s}.")
	elsif player_total < dealer_total
		loser!("dealers #{dealer_total.to_s} beats your #{player_total.to_s}.")
	else
		tie!("#{player_total.to_s}.")
	end
	@play_again = true
	erb :game
end

get '/game_over' do
	erb :game_over
end
