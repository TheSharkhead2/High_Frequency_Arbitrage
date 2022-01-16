using Random
using Statistics

function prune_hist(location)
    """
    Looks at all history and determines what a specific player can see
    based on their location. 

    """

    #declare global history variables
    global global_history
    global time

    history = ((true, []), (true, []), (true, []), (false, []), (false, []), (false, [])) #blank tuple for history. 6 entries (lists), one for each markey

    stockCounter = 1 #counter to keep track of which stock loop is on 
    for stock in global_history #look at global history 
        for transaction in stock[2] #look at all transactions 
            if (stock[1] == location && transaction[2] <= time) || (stock[1] != location && transaction[2] <= (time + 8)) || transaction[1] == location #if it is in the same location and before or at the current time or different location and the current time plus the delay (8 ticks) or is transaction from player (location variable is current location and player)
                pushfirst!(history[stockCounter][2], transaction) 
            end
        end
        stockCounter += 1 #increment counter
    end

    history
end

function playerMove(location)
    """
    Function to determine strategy of either player. 

    Parameters
    ----------

    location : bool 
        true for one location false for section location. Each player
        is at different location (two locations)

    """

    stockPick = rand(1:6)

end

# empty lists to include transaction history (tuple includes market id for each stock)
global_history = ((true, []), (true, []), (true, []), (false, []), (false, []), (false, []))

#empty lists for queues of stock sales
global_queue = ((true, []), (true, []), (true, []), (false, []), (false, []), (false, []))

#Running counts of payoffs. Lose M is selling same stock, gain m if selling diff. stocks in same market where 0 < m < M. 
m_p1 = 0
M_p1 = 0

m_p2 = 0 
M_p2 = 0

endTime = 800 #number of ticks in one "round"
nSimulation = 100 #number of simulations/rounds that will run

running = true #to keep while loop running 

time = 0 #keep track of current time to affect visability 

#lists to save history of m and M for multiple rounds 
m_p1_hist = []
M_p1_hist = []
m_p2_hist = []
M_p2_hist = []

for nSim in 1:nSimulation #run specified number of simulations
    global time 
    global running
    global endTime
    global global_history
    global global_queue
    global m_p1 
    global m_p2 
    global M_p1 
    global M_p2
    global m_p1_hist
    global M_p1_hist
    global m_p2_hist
    global M_p2_hist

    #reset global variables
    global_history = ((true, []), (true, []), (true, []), (false, []), (false, []), (false, []))
    global_queue = ((true, []), (true, []), (true, []), (false, []), (false, []), (false, []))
    m_p1 = 0
    M_p1 = 0
    m_p2 = 0 
    M_p2 = 0
    running = true
    time = 0 

    while running == true

        player1Stock = playerMove(false) #run stock pick logic for player1 
        player2Stock = playerMove(true) #run stock pick logic for player2 

        if global_queue[player1Stock][1] == false #if p1 stock pick in same location as p1, delay is 1 tick 
            p1Delay = 1 
        else #otherwise delay is 8 ticks
            p1Delay = 8 
        end

        if global_queue[player2Stock][1] == true #if p2 stock pick in same location as p2, delay is 1 tick 
            p2Delay = 1 
        else #otherwise delay is 8 ticks
            p2Delay = 8 
        end

        push!(global_queue[player1Stock][2], (false, time+p1Delay)) #add p1 stock pick to queue. Stock sale looks like: (player who sold stock, when it will be sold)
        push!(global_queue[player2Stock][2], (true, time+p2Delay)) #add p2 stock pick to queue. Stock sale looks like: (player who sold stock, when it will be sold)

        market1Sales = [] #false market sales. All sales this round in this market 
        market2Sales = [] #true market sales. All sales this round in this market 

        stockCounter = 1 #counter variable to keep track of current stock in loop
        for stock in global_queue #loop through all stocks
            transactionCounter = 1 #counter var for transaction id
            for transaction in stock[2] #loop through all transactions 
                if transaction[2] == time #if the current time is the transaction time, remove from queue and add to history 
                    deleteat!(global_queue[stockCounter][2], transactionCounter) #remove transaction from queue 
                    pushfirst!(global_history[stockCounter][2], transaction) #add transaction to history

                    if stock[1] == true #if it is in market 2, add it to sales 
                        push!(market2Sales, (transaction[1], stockCounter)) #this is a tuple with the form: (player, stock id)
                    else #otherwise add it to market 1 
                        push!(market1Sales, (transaction[1], stockCounter))
                    end

                end
                transactionCounter += 1 #increment counter 
            end
            stockCounter += 1 #increment counter 
        end

        #look at market 1, if has 2 sales then evaluate outcome for each player (can ignore 1 sale as this is 0 payoff)
        if length(market1Sales) == 2 
            if market1Sales[1][2] == market1Sales[2][2] #if they are both the same stock, then increase negative M payoff
                M_p1 += 1
                M_p2 += 1 
            else #if they are different (only other option), then each player gets positive m payoff increase 
                m_p1 += 1
                m_p2 += 1 
            end
        end

        #look at market 2, if has 2 sales then evaluate outcome for each player (can ignore 1 sale as this is 0 payoff)
        if length(market2Sales) == 2 
            if market2Sales[1][2] == market2Sales[2][2] #if they are both the same stock, then increase negative M payoff
                M_p1 += 1
                M_p2 += 1 
            else #if they are different (only other option), then each player gets positive m payoff increase 
                m_p1 += 1
                m_p2 += 1 
            end
        end

        # println("Current time is $time. Player1 has $m_p1 m - $M_p1 M and player2 has $m_p2 m - $M_p2 M. History:")
        # println(global_history)

        time += 1 #increment time

        if endTime <= time #stop loop if after endtime 
            running = false
        end
    end

    #save all payoffs per round
    push!(m_p1_hist, m_p1)
    push!(M_p1_hist, M_p1)
    push!(m_p2_hist, m_p2)
    push!(M_p2_hist, M_p2)

end

#average all payoffs
m_p1_avg = mean(m_p1_hist)
M_p1_avg = mean(M_p1_hist)
m_p2_avg = mean(m_p2_hist)
M_p2_avg = mean(M_p2_hist)

println("With $endTime ticks per game and $nSimulation games played, player 1 averaged a payoff of: $m_p1_avg m - $M_p1_avg M and player 2 averaged a payoff of: $m_p2_avg m - $M_p2_avg M")