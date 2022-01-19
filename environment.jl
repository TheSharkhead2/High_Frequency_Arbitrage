using ReinforcementLearning

#for this environment, I followed the guide here: https://juliareinforcementlearning.org/docs/How_to_write_a_customized_environment/

Base.@kwdef mutable struct ArbitrageEnv <: AbstractEnv
    reward::Int = 0 
end

RLBase.action_space(env::ArbitrageEnv) = (:Market1, :Market2) #define the action space for the model. Can either buy on market 1 or market 2

RLBase.reward(env::ArbitrageEnv) = env.reward

RLBase.state(env::ArbitrageEnv) = !isnothing(env.reward) # ?? 

RLBase.state_space(env::ArbitrageEnv) = [false, true] # ??

RLBase.is_terminated(env::ArbitrageEnv) = !isnothing(env.reward) # ??

RLBase.reset!(env::ArbitrageEnv) = env.reward = 0