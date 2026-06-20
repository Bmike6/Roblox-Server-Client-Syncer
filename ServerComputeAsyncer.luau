--strict
--[[
		
	Made By Bmike -- 6/19/26
	
	ServerComputeAsync is a module for the server to compute data for integrity.
	
	
]]

type state = {
	stateID:string, -- state name
	stateCompletionTime:number|()->number, -- state completion time
	onCompletionState:()->(), -- optinal callback when state executes allows for more control over the state machine	
	statePosition:number, -- position in our state machine
	

}

type ServerComputeAsync = {
	__index:ServerComputeAsync,
	
	className:string,
	stateMachineOrder:{state},
	repeating:boolean,
	isRunning:boolean,
	currentState:state,
	
	create:(classInformation:{
		className:string, 
		stateMachineOrder: {state},
				
		
	}  )->ServerComputeAsync
	
	
}

local ServerComputeAsync = {}
ServerComputeAsync.__index = ServerComputeAsync
ServerComputeAsync.__tostring = function(self)	
	
	return `{self.className}: {self.currentState.stateID}\n\t\t\t\tCompletion: {self.completionOfCurrentState}` 
end


ServerComputeAsync.create = function(classInformation)
	local self = {}
	
	self.className=classInformation.className
	self.stateMachineOrder=classInformation.stateMachineOrder::{state}
	self.lastLoadedSnapshot = tick()
	
	
	self.totalTimeRunning=0
	self.currentState=self.stateMachineOrder[1]
	self.isRunning = false -- is this async running looking
	self.repeating = false -- will state machine re iterate once completion of an cycle
	
	self.completionOfCurrentState=0
	
	if not self.stateMachineOrder or #self.stateMachineOrder<1 then
		error(`state machine returned empty got : {self.stateMachineOrder}`)
	end
	
	return setmetatable(self, ServerComputeAsync)
end


function ServerComputeAsync:computeAsync(newUpdateStamp:number) : number -- how many times we sucesfully completed a loop
	if not self.isRunning then return 0 end
	local secondsUpdated = newUpdateStamp - self.lastLoadedSnapshot::number
	local cycleCompletionTime=ServerComputeAsync.getTimeForCompletionCycle(self.stateMachineOrder::{state})
	local cyclesCompleted = math.floor( (self.totalTimeRunning::number + secondsUpdated) / cycleCompletionTime ) -- gets us cycles completed since last updated if any
	local leftoverTimeForCompletion = secondsUpdated%cycleCompletionTime 
	self.lastLoadedSnapshot = newUpdateStamp
	self.totalTimeRunning+=secondsUpdated
	

	
	if cyclesCompleted>=1 then
		
		
		if self.stateMachineOrder[#self.stateMachineOrder].onCompletionState then
			self.stateMachineOrder[#self.stateMachineOrder].onCompletionState()
		end
		
		self.completionOfCurrentState = 0
		self.currentState = self.stateMachineOrder[1] :: state
		self.totalTimeRunning=0
		
		if not self.repeating then
			self.isRunning = false
		end
		return 1 
	end

	for i=self.currentState.statePosition::number, #self.stateMachineOrder :: {state} do
		local stateReference = self.stateMachineOrder[self.currentState.statePosition] :: state
		local completionTime = (typeof(stateReference.stateCompletionTime)~="function" and  stateReference.stateCompletionTime  or  stateReference.stateCompletionTime())-- added dynamic state flow change 
		
		if self.completionOfCurrentState + leftoverTimeForCompletion - completionTime <= 0 then
			self.completionOfCurrentState = self.completionOfCurrentState :: number + leftoverTimeForCompletion
			break
		else
			leftoverTimeForCompletion -= completionTime-self.completionOfCurrentState
			self.completionOfCurrentState = 0
			self.currentState=self.stateMachineOrder[i+1] -- can never error because we always know that this statement can never be reached on last iter
			
			
			
			if self.currentState and self.currentState.onCompletionState then
				self.currentState.onCompletionState()
			end
		end
	end	
	
	return cyclesCompleted
end


function ServerComputeAsync:stop()
	self.isRunning = false
end


function ServerComputeAsync:start()
	self.lastLoadedSnapshot = tick()
	self.isRunning = true
end


function ServerComputeAsync:updateComputeAsync(updateValues : {[number]:{statePosition:number, newCompletionTime:number}} ) -- state->number update
	
	--[[ updates states computation values so we can update ]]
	for i=1, #updateValues do
		local updateStateReference=updateValues[i]
		if updateStateReference.statePosition == self.currentState.statePosition then -- run percentage math to scale progress
			local percentage = self.completionOfCurrentState::number / self.stateMachineOrder[updateStateReference.statePosition::number].stateCompletionTime::number
			self.completionOfCurrentState=updateStateReference.newCompletionTime * percentage
		end
		self.stateMachineOrder[updateStateReference.statePosition].stateCompletionTime=updateStateReference.newCompletionTime
	end
end


-- // HELPER METHODS -- //

ServerComputeAsync.getTimeForCompletionCycle = function(stateMachineOrder:{state}):number
	local time=0
	for i=1, #stateMachineOrder do
		time += (typeof(stateMachineOrder[i].stateCompletionTime)~="function" and  stateMachineOrder[i].stateCompletionTime  or  stateMachineOrder[i].stateCompletionTime())
	end
	
	return time
end

ServerComputeAsync.createState = function(stateID:string, completionTime:number|()->(), statePosition:number, completionCallback:()->() )
	return {
		stateID = stateID,
		stateCompletionTime = completionTime,
		statePosition=statePosition,
		onCompletionState = completionCallback,
	}::state
end





return ServerComputeAsync
