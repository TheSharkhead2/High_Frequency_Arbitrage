""" 
Second file to try and implement simulated annealing to find a good strategy
for game. 

"""

using Random
using Statistics
using ProgressMeter
using Distributions


function run_simulation(P_A, P_B, maxTime)
    """ 
    Run simulation of the game to time maxTime with probabilities of selling
    on own market as P_A and P_B for each player

    Parameters
    ----------

    P_A : float 
        Between 0 and 1. Probability player 1 sells on their market 
    
    P_B : float
        Between 0 and 1. Probability player 2 sells on their market

    maxTime : int
        Total time for simulation 

    Returns
    -------

    m : int
        Count for number of positive m payoffs 

    M : int 
        Count for number of negative M payoffs

    """
    
    #make empty variables for simulation
    global_history = ((true, []), (true, []), (true, []), (false, []), (false, []), (false, []))
    global_queue = ((true, []), (true, []), (true, []), (false, []), (false, []), (false, []))
    m = 0
    M = 0

    @showprogress 1 "Running round... " for time in 0:maxTime

        #pick markets
        if rand() < P_A #if in probability player 1 sells on their market 
            player1Market = false #player 1 sells in their market 
        else 
            player1Market = true #otherwise other market
        end 
        
        if rand() < P_B #if in probability player 2 sells on their market 
            player2Market = true #player 2 sells in their market 
        else 
            player2Market = false #otherwise other market 
        end

        #pick stocks (random)
        if player1Market #if market 2 
            player1Stock = rand(1:3)
        else 
            player1Stock = rand(4:6) #otherwise market 1
        end

        if player2Market #if market 2 
            player2Stock = rand(1:3)
        else 
            player2Stock = rand(4:6) #otherwise market 1
        end

        #get delays
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
                M += 1

            else #if they are different (only other option), then each player gets positive m payoff increase 
                m += 1

            end
        end

        #look at market 2, if has 2 sales then evaluate outcome for each player (can ignore 1 sale as this is 0 payoff)
        if length(market2Sales) == 2 
            if market2Sales[1][2] == market2Sales[2][2] #if they are both the same stock, then increase negative M payoff
                M += 1

            else #if they are different (only other option), then each player gets positive m payoff increase 
                m += 1

            end
        end

    end

    return (m, M)
end

function get_neighbor(stepStdev, P_A, P_B)
    """
    Gets random neighbor to probability pair for the purposes of
    simulated annealing

    Parameters
    ----------

    stepStdev : float
        Standard deviation for normal distribution 

    P_A : float
        current P_A

    P_B : float 
        current P_B

    Returns
    -------

    newP_A : float
        New P_A that represents, with the new P_B, a neighbor to the previous
        pair 

    newP_B : float
        New P_B which with the new P_A represents a neighbor to state before

    """

    #simply generate a new P_A and P_B within a standard deviation. This is hopefully accounting for all times when A or B stay the same, decrease, increase
    newP_A = rand(Normal(P_A, stepStdev)) # get new random P_A within normal distribution of previous P_A 
    newP_B = rand(Normal(P_B, stepStdev)) #get new random P_B within normal distribution of previous P_B

    if newP_A > 1 #if the probability is higher than 100 percent, cap it 
        newP_A = 1 
    elseif newP_A < 0 #if it is less than 0, set it to 0 
        newP_A = 0 
    end

    #same as above for P_B
    if newP_B > 1  
        newP_B = 1 
    elseif newP_B < 0
        newP_B = 0 
    end


    (newP_A, newP_B)

end

function run_sim_vals(m, M, maxTime, P_A, P_B)
    """ 
    Run a simulation but return an integer value for a specified m and M

    Parameters
    ----------

    m : int 
        Payoff value for m 

    M : int
        Payoff value for M 

    maxTime : int
        Total ticks in simulation

    P_A : float 
        Between 0 and 1. Probability player 1 sells on their market 
    
    P_B : float
        Between 0 and 1. Probability player 2 sells on their market

    """
    
    mTotal, MTotal = run_simulation(P_A, P_B, maxTime)

    m * mTotal - M * MTotal #return total payoff

end


function sim_anneal(maxTime, iTemp, fTemp, m, M, stepStdev, beta)
    """ 
    Function to run simulated annealing on this game to find the best
    strategy. 

    Parameters
    ----------

    maxTime : int 
        Number of tics for each game to play when changing probabilities 
    
    iTemp : float
        Initial temperature for environment 
    
    fTemp : float 
        Final temperature for environment (when sim will stop)

    m : int
        Value for m in game

    M : int 
        Value for M in game

    stepStdev : float 
        stDev for taking a step away from a given position 
    
    beta : float
        Arbitrary constant for temperature decrement

    """

    currentTemp = iTemp #set current temp to initial temp

    #get two random initial probabilities for A and B
    initialP_A = rand()
    initialP_B = rand()

    #initialize current probability values
    P_A = initialP_A
    P_B = initialP_B

    currentScore = run_sim_vals(m, M, maxTime, P_A, P_B) # get score of P_A and P_B
    
    while currentTemp > fTemp #loop until temperature is below the final temperature
        neighbor = get_neighbor(stepStdev, P_A, P_B) #get random neighbor 

        neighborScore = run_sim_vals(m, M, maxTime, neighbor[1], neighbor[2]) #get score for neighbor 

        costDiff = currentScore - neighborScore #get difference between neighbor score and current position score 

        if costDiff < 0 #if the neighbor is better, accept it
            P_A, P_B = neighbor #update current position 

            currentScore = run_sim_vals(m, M, maxTime, P_A, P_B) # update score of P_A and P_B

            println("taking better P_A = $P_A and P_B = $P_B with a score $currentScore")

        else
            if rand() < exp(costDiff / currentTemp) #have a chance of accepting the bad solution
                P_A, P_B = neighbor #update current position 

                currentScore = run_sim_vals(m, M, maxTime, P_A, P_B) # update score of P_A and P_B

                println("taking worse P_A = $P_A and P_B = $P_B with a score $currentScore")

            end
        end

        #decrement the temperature 
        currentTemp = currentTemp/(1+beta*currentTemp) #smaller the beta, the slower the decreases
    
        println("Temperature is now $currentTemp")

    end

    (P_A, P_B)

end


sim_anneal(400, 1000, 0.1, 3, 4, 0.01, 0.0001 )