local Elevator = {}
local InfiniteMath = require(game.ReplicatedStorage.Modules.InfiniteMath)
local ServerComputeAsync = require(script.Parent.ServerComputeAsync)

local MAX_LOAD_SPEED = 1.5

Elevator.__index = Elevator


Elevator.new = function(data:{})
	local self = {}
	self.maxLoadCapacity=data.maxCapacity
	self.storage=InfiniteMath.new(0)
	self.shaftTraverseSpeed = data.traverseSpeed  -- time it takes to traverse between each shaft 
	self.shaftHandlerServer=data.shaftHandlerServer
	
	self.ServerComputeAsync = ServerComputeAsync.create({
		className = "Elevator",
		stateMachineOrder = {
				{stateID="Idle", statePosition = 1, completionTime = 0}
			}
		}
	)	
	return setmetatable(self, Elevator)
end

function Elevator:start()
	self.ServerComputeAsync.isRunning = true
end


function Elevator:update(stamp)
	local completedCycles = self.ServerComputeAsync:computeAsync(stamp)
	if completedCycles>=1 then
		
		return 1
	end	
end




function Elevator:updateStateMachine(shafts)
	table.clear(self.ServerComputeAsync.stateMachineOrder)
	self.ServerComputeAsync.stateMachineOrder[1]=self.ServerComputeAsync.createState("Idle", 0, 1) -- always begin at the idle state
	
	for i=1, #shafts do		
		local getCollectTime = function()
			local currentLoad =
				tonumber(tostring(self.storage))
				+ tonumber(tostring(shafts[i].storage))

			local maxLoad =
				tonumber(tostring(self.maxLoadCapacity))

			local ratio = math.clamp(currentLoad / maxLoad, 0, 1)
			return math.max(0, ratio * MAX_LOAD_SPEED)+.5
		end
		
		
		self.ServerComputeAsync.stateMachineOrder[#self.ServerComputeAsync.stateMachineOrder+1]=self.ServerComputeAsync.createState("MoveDown", self.shaftTraverseSpeed, #self.ServerComputeAsync.stateMachineOrder+1)
		self.ServerComputeAsync.stateMachineOrder[#self.ServerComputeAsync.stateMachineOrder+1]=self.ServerComputeAsync.createState("Collecting", getCollectTime, #self.ServerComputeAsync.stateMachineOrder+1, function()
			self.storage=InfiniteMath.clamp(self.storage+shafts[i].storage, 0, self.maxLoadCapacity)
		end)
	end
	for i=1, #shafts do
		self.ServerComputeAsync.stateMachineOrder[#self.ServerComputeAsync.stateMachineOrder+1]=self.ServerComputeAsync.createState("MoveUp", self.shaftTraverseSpeed, #self.ServerComputeAsync.stateMachineOrder+1)
	end
	self.ServerComputeAsync.stateMachineOrder[#self.ServerComputeAsync.stateMachineOrder+1]=self.ServerComputeAsync.createState("Deposit", 0, #self.ServerComputeAsync.stateMachineOrder+1, function()
		print(`Deposited: {tostring(self.storage)}`)
		self.storage = 0
	end)
	
end





return Elevator
