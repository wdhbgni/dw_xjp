--[[
*	百家乐推送端口
* 
*	@author：lqh
]]
local Bjl_JbackPort = {}
function Bjl_JbackPort.extend(data)
	local player = Player
	local gamemgr = require("src.games.baijiale.data.Bjl_GameMgr").getInstance()
	
	local handler = function(data)
		local tp = data:readUnsignedShort()
		mlog(string.format("<Bjl_JbackPort> receive JBack message , type = %s",tp))
		if tp == 1 then
			--下注开始
			gamemgr:beganBytesRead(data)
		elseif tp == 2 then
			--下注
			gamemgr:betBytesRead(data)
		elseif tp == 3 then
			--结果
			gamemgr:resultBytesRead(data)
		end
	end
	return handler
end
return Bjl_JbackPort
