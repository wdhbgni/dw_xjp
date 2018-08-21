local Lkby_Scene = class("Lkby_Scene",function()
	local scene = display.extend("CCSceneExtend",cc.Scene:createWithPhysics())
	return scene
end,IEventListener)

local TAG_ENUM = 
{
  Tag_Fish = 200
}

local module_pre = "src.games.likuibuyu"    
local scheduler = cc.Director:getInstance():getScheduler()
local ExternalFun = require("src.games.likuibuyu.content.ExternalFun")
local g_var = ExternalFun.req_var
local cmd = module_pre..".content.CMD_LKGame"
local CannonLayer = module_pre..".ui.CannonLayer"
local Fish = module_pre..".ui.Fish"
function Lkby_Scene:ctor(room)
	self:super("ctor")
	self.room = room

	self.m_infoList = {}
	self.m_scheduleUpdate = nil
	self.m_secondCountSchedule = nil
	self._scene = room
	self.m_bScene = false
	self.m_bSynchronous = false
	self.m_nSecondCount = 60
	self.m_catchFishCount = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
	  -- self._gameFrame = frameEngine
	  -- self._gameFrame:setKindInfo(cmd.KIND_ID,cmd.VERSION)
	  -- self._roomRule = self._gameFrame._dwServerRule

	local gameView = require("src.games.likuibuyu.ui.LikuibuyuSceneUiPanel").new(self)
	self:addChild(gameView)
	self._gameView = gameView


	self._dataModel = require("src.games.likuibuyu.content.GameFrame").getInstance()
	self._dataModel:setRoom(room)
	self._dataModel.m_secene.curscene = self
		--设置场景引力
    self:getPhysicsWorld():setGravity(cc.p(0,-100))



   	-- self:initUi()
   	-- self:initData()
	-- SoundsManager.playMusic("qznn_bgm",true)
    self.m_pUserItem = {
    	wTableID = 1,
    	wChairID = 1,
    	dwUserID = Player.id,
    	lScore   = Player.gold,
    	szNickName = Player.name

	}
	
  -- self.m_pUserItem = self._gameFrame:GetMeUserItem()
  self.m_nTableID  = self.m_pUserItem.wTableID
  self.m_nChairID  = self.m_pUserItem.wChairID  

  	self:setReversal()

  	--鱼层
	  self.m_fishLayer = cc.Layer:create()
	  self._gameView:addChild(self.m_fishLayer, 5)
    
    if self._dataModel.m_reversal then
	    self.m_fishLayer:setRotation(180)
	end


  --自己信息
  self._gameView:initUserInfo()

   --创建定时器
  self:onCreateSchedule()

  --60秒未开炮倒计时
  self:createSecoundSchedule()

   --注册事件
  ExternalFun.registerTouchEvent(self,true)

  --注册通知
  self:addEvent()



	require("src.ui.item.TalkControl").show(room,self)
	local quitebtn = require("src.ui.QuitButton").new()
	self:addChild(Coord.ingap(self,quitebtn,"LL",0,"TT",0),109)

end


-- 场景信息

function Lkby_Scene:onEventGameScene(dataBuffer)

  print("场景数据")

   if self.m_bScene then
      self:dismissPopWait()
      return
    end

    self.m_bScene = true
  	local systime = os.time()
    self._dataModel.m_enterTime = systime

    -- self._dataModel.m_secene = ExternalFun.read_netdata(g_var(cmd).GameScene,dataBuffer)
  
   self._dataModel.m_secene.cbBackIndex = dataBuffer:readByte()
    self._dataModel.m_secene.lPlayScore = dataBuffer:readLong()
    self._dataModel.m_secene.lPalyCurScore = {}
    for i=1,6 do
    	table.insert(self._dataModel.m_secene.lPalyCurScore,dataBuffer:readLong())
    end
    self._dataModel.m_secene.lPlayStartScore = {}
    for i=1,6 do
    	table.insert(self._dataModel.m_secene.lPlayStartScore,dataBuffer:readLong())
    end
    
    self._dataModel.m_secene.lCellScore = dataBuffer:readInt()
    self._dataModel.m_secene.nBulletVelocity = dataBuffer:readInt()
    self._dataModel.m_secene.nBulletCoolingTime = dataBuffer:readInt()
    mlog("场景返回nBulletCoolingTime：",self._dataModel.m_secene.nBulletCoolingTime)
    self._dataModel.m_secene.nFishMultiple = {}
    for i=1,26 do
      -- table.insert(self._dataModel.m_secene.nFishMultiple,dataBuffer:readInt())
      table.insert(self._dataModel.m_secene.nFishMultiple, 0)
    end
    self._dataModel.m_secene.nMaxTipsCount = dataBuffer:readInt()
    self._dataModel.m_secene.lBulletConsume = {}
    for i=1,6 do
    	table.insert(self._dataModel.m_secene.lBulletConsume,dataBuffer:readLong())
    end
    self._dataModel.m_secene.lPlayFishCount = {}
    for i=1,26 do
      -- table.insert(self._dataModel.m_secene.lPlayFishCount,dataBuffer:readInt())
      table.insert(self._dataModel.m_secene.lPlayFishCount, 0)
    end
    self._dataModel.m_secene.nMultipleValue = {{0,0,0,0,0,0}}
    for i=1,6 do
    	self._dataModel.m_secene.nMultipleValue[1][i] = dataBuffer:readInt()
    end

    self._dataModel.m_secene.nMultipleIndex = {{0,0,0,0,0,0}}
    for i=1,6 do
    	self._dataModel.m_secene.nMultipleIndex[1][i] = dataBuffer:readInt()
    end
    self._dataModel.m_secene.bUnlimitedRebound = dataBuffer:readBoolean()
    self._dataModel.m_secene.server_time = dataBuffer:readLong()
    -- self._dataModel.m_secene.szBrowseUrl = dataBuffer:readString()

    if self._dataModel.m_secene.cbBackIndex ~= 0 then
     	  self._gameView:updteBackGround(self._dataModel.m_secene.cbBackIndex)
    end

    self._gameView:updateMultiple(self._dataModel.m_secene.nMultipleValue[1][1])

    self:setUserMultiple(self._dataModel.m_secene.nMultipleValue[1][1])
      
    self:dismissPopWait()
end


function Lkby_Scene:setUserMultiple()

    if not self.m_cannonLayer then
      return
    end

  --设置炮台倍数
     for i=1,6 do
       local cannon = self.m_cannonLayer:getCannoByPos(i)
       local pos = i
       if nil ~= cannon then

          if self._dataModel.m_reversal then 
            pos = 6+1-i
          end

          if not  self._dataModel.m_secene.nMultipleIndex then
            return
          end
          mlog(pos,"pos")
          for i,v in ipairs(self._dataModel.m_secene.nMultipleIndex[1]) do
          	mlog(i,v)
          end
          mlog(self._dataModel.m_secene.nMultipleIndex[1][pos],"self._dataModel.m_secene.nMultipleIndex[1][pos]")

          cannon:setMultiple(self._dataModel.m_secene.nMultipleIndex[1][pos])
       end
     end
end


--关闭等待
function Lkby_Scene:dismissPopWait()
    if self._scene and self._scene.dismissPopWait then
        self._scene:dismissPopWait()
    end
end

function Lkby_Scene:addEvent()

	ConnectMgr.registorJBackPort(ConnectMgr.getMainSocket(),Port.PORT_JBACK_LIKUIBUYU ,require("src.games.likuibuyu.content.Likuibuyu_Port").extend())

		--初始化房间数据
	ConnectMgr.connect("src.games.likuibuyu.content.Likuibuyu_EntryRoomConnect")

     --添加炮台层
    self.m_cannonLayer = g_var(CannonLayer).new(self)
    self._gameView:addChild(self.m_cannonLayer, 6)

   --通知监听
  -- local function eventListener(event)


  --   --初始化界面
  --   -- self._gameView:initView()

  --    --添加炮台层
  --   self.m_cannonLayer = g_var(CannonLayer):create(self)
  --   self._gameView:addChild(self.m_cannonLayer, 6)

  --   --查询本桌其他用户
  --   -- self._gameFrame:QueryUserInfo( self.m_nTableID,D_SIZE.INVALID_CHAIR)


  --      --播放背景音乐
  --   -- AudioEngine.playMusic(cc.FileUtils:getInstance():fullPathForFilename(g_var(cmd).Music_Back_1),true)

  --   -- if not GlobalUserItem.bVoiceAble then
        
  --   --     AudioEngine.setMusicVolume(0)
  --   --     AudioEngine.pauseMusic() -- 暂停音乐
  --   -- end

  -- end

  -- local listener = cc.EventListenerCustom:create(g_var(cmd).Event_LoadingFinish, eventListener)
  -- cc.Director:getInstance():getEventDispatcher():addEventListenerWithFixedPriority(listener, 1)

end


--60开炮倒计时
function Lkby_Scene:setSecondCount(dt)
     self.m_nSecondCount = dt

     if dt == 60 then
       local tipBG = self._gameView:getChildByTag(10000)
       if nil ~= tipBG then
          tipBG:removeFromParent()
       end
     end
end

function Lkby_Scene:onEnter( )
	
  mlog("onEnter of Lkby_Scene")

end

function Lkby_Scene:onEnterTransitionFinish(  )
 
  mlog("onEnterTransitionFinish of Lkby_Scene")

  --AudioEngine.playMusic(g_var(cmd).Music_Back_1,true)

--碰撞监听
  self:addContact()

end



--触摸事件
function Lkby_Scene:onTouchBegan(touch, event)

	return true
end

function Lkby_Scene:onTouchMoved(touch, event)

end

function Lkby_Scene:onTouchEnded(touch, event )
	
end

--添加碰撞
function Lkby_Scene:addContact()

    local function onContactBegin(contact)
    
        local a = contact:getShapeA():getBody():getNode()
        local b = contact:getShapeB():getBody():getNode()
       
        local bullet = nil

        if a and b then
          if a:getTag() == g_var(cmd).Tag_Bullet then
            bullet = a
          end

          if b:getTag() == g_var(cmd).Tag_Bullet then
            bullet = b
          end

        end
        if nil ~= bullet then
           bullet:fallingNet()
           bullet:removeFromParent()
        end

        return true
    end

    local dispatcher = self:getEventDispatcher()
    self.contactListener = cc.EventListenerPhysicsContact:create()
    self.contactListener:registerScriptHandler(onContactBegin, cc.Handler.EVENT_PHYSICS_CONTACT_BEGIN)
    dispatcher:addEventListenerWithSceneGraphPriority(self.contactListener, self)

end


function Lkby_Scene:onSubSupply(databuffer )
  
  if not self.m_cannonLayer then
    return
  end

  local supply =  ExternalFun.read_netdata(g_var(cmd).CMD_S_Supply,databuffer)

  local cannonPos = supply.wChairID
  if self._dataModel.m_reversal then 
       cannonPos = 5 - cannonPos
  end

  local cannon = self.m_cannonLayer:getCannoByPos(cannonPos + 1)
  if not  cannon then
     return
  end
  cannon:ShowSupply(supply)

  local tipStr = nil

   local cannonPos = supply.wChairID
   if self._dataModel.m_reversal then 
     cannonPos = 5 - cannonPos
   end

   local cannon = self.m_cannonLayer:getCannoByPos(cannonPos + 1)
   local userid = self.m_cannonLayer:getUserIDByCannon(cannonPos+1)
   -- local userItem = self._gameFrame._UserList[userid]
   local userItem = {}
   userItem.szNickName = " xxx测试"
 

  if supply.nSupplyType == g_var(cmd).SupplyType.EST_Laser then
     if supply.wChairID == self.m_nChairID then
       tipStr = self.m_pUserItem.szNickName.."击中补给箱打出了激光！秒杀利器！赶快使用！"
    else
       tipStr = userItem.szNickName .." 击中补给箱打出了激光！秒杀利器!"
    end

  elseif supply.nSupplyType == g_var(cmd).SupplyType.EST_Laser then
    
      tipStr = userItem.szNickName.." 击中补给箱打出了加速！所有子弹速度翻倍！"
  elseif supply.nSupplyType == g_var(cmd).SupplyType.EST_Null then
   
      tipStr = "很遗憾！补给箱里面什么都没有！"

      self._dataModel:playEffect(g_var(cmd).SmashFail)

  end

  if nil ~= tipStr then 
    self._gameView:Showtips(tipStr)
  end

end

function Lkby_Scene:onSubMultiple( databuffer )

    local mutiple = ExternalFun.read_netdata(g_var(cmd).CMD_S_Multiple,databuffer)
    local cannonPos = mutiple.wChairID
    if self._dataModel.m_reversal then 
         cannonPos = 5 - cannonPos
    end
 
   if nil ~= self.m_cannonLayer then
      local cannon = self.m_cannonLayer:getCannoByPos(cannonPos + 1)

      if nil == cannon then
        return
      end

      cannon:setMultiple(mutiple.nMultipleIndex)
   end
 
    self._dataModel.m_secene.nMultipleIndex[1][mutiple.wChairID + 1] = mutiple.nMultipleIndex

    if mutiple.wChairID == self.m_nChairID then 
      self._gameView:updateMultiple(self._dataModel.m_secene.nMultipleValue[1][mutiple.nMultipleIndex+1])
    end

end


function Lkby_Scene:onSubSupplyTip(databuffer)

    if not self.m_cannonLayer then
      return
    end
   
     local tip = ExternalFun.read_netdata(g_var(cmd).CMD_S_SupplyTip,databuffer)

     local tipStr = ""
     if tip.wChairID == self.m_nChairID then
       tipStr = "获得一个补给箱！击中可能获得大量奖励哟！赶快击杀！"
      else
         local cannonPos = tip.wChairID
         if self._dataModel.m_reversal then 
           cannonPos = 5 - cannonPos
         end

         local cannon = self.m_cannonLayer:getCannoByPos(cannonPos + 1)
         local userid = self.m_cannonLayer:getUserIDByCannon(cannonPos+1)
         -- local userItem = self._gameFrame._UserList[userid]
         local userItem = {}
         userItem.szNickName = "xxx测试"
         if not userItem then
            return
         end
         tipStr = userItem.szNickName .." 获得了一个补给箱！羡慕吧，继续努力，你也可能得到！"
     end

     self._gameView:Showtips(tipStr)
end


--同步时间
function Lkby_Scene:onSubSynchronous( databuffer )
	  print("同步时间")
    self.m_bSynchronous = true
	  local synchronous = ExternalFun.read_netdata(g_var(cmd).CMD_S_FishFinish,databuffer)
	  if 0 ~= synchronous.nOffSetTime then
       print("同步时间1")
	  	 local offtime = synchronous.nOffSetTime
	  	 self._dataModel.m_enterTime = self._dataModel.m_enterTime - offtime
	  end

end

function Lkby_Scene:onSubStayFish( databuffer )

  local stay = ExternalFun.read_netdata(g_var(cmd).CMD_S_StayFish,databuffer)

  local fish = self._dataModel.m_fishList[stay.nFishKey]
  if nil ~= fish then
      fish:Stay(stay.nStayTime)
  end

  
end


function Lkby_Scene:onSubFire(databuffer)
  
  if not self.m_cannonLayer  then
    return
  end

  local fire =  ExternalFun.read_netdata(g_var(cmd).CMD_S_Fire,databuffer)
  if fire.wChairID == self.m_nChairID then
    return
  end
 
 local cannonPos = fire.wChairID
 if self._dataModel.m_reversal then 
   cannonPos = 5 - cannonPos
 end

 local cannon = self.m_cannonLayer:getCannoByPos(cannonPos + 1)
 if nil ~= cannon then
    cannon:othershoot(fire)
 end
end


--切换场景
function Lkby_Scene:onSubExchangeScene( dataBuffer )

    print("场景切换")

    self._dataModel:playEffect(g_var(cmd).Change_Scene)
    local systime = os.time()
    self._dataModel.m_enterTime = systime

    self._dataModel._exchangeSceneing = true

    local exchangeScene = ExternalFun.read_netdata(g_var(cmd).CMD_S_ChangeSecene,dataBuffer)
    self._gameView:updteBackGround(exchangeScene.cbBackIndex)

    local callfunc = cc.CallFunc:create(function()
        self._dataModel._exchangeSceneing = false
    end)

    self:runAction(cc.Sequence:create(cc.DelayTime:create(8.0),callfunc))

end


--创建鱼
function Lkby_Scene:onSubFishCreate( databuffer )
  	 print("鱼创建")

    -- local fishNum = math.floor(dataBuffer:getlen()/577)
    local fishNum = databuffer:readInt()
    	mlog(fishNum,"FishCreate.fishNum")

    if fishNum >= 1 then
    	for i=1,fishNum do
       
    	  -- local FishCreate =   ExternalFun.read_netdata(g_var(cmd).CMD_S_FishFinishhCreate,dataBuffer)
    	local FishCreate = {}
    	FishCreate.nFishKey = databuffer:readInt()
    	FishCreate.unCreateTime = databuffer:readInt()
    	FishCreate.wHitChair = databuffer:readShort()
    	FishCreate.nFishType = databuffer:readByte()
    	FishCreate.nFishState = databuffer:readInt()
    	FishCreate.bRepeatCreate = databuffer:readBoolean()
    	FishCreate.bFlockKill = databuffer:readBoolean()
    	FishCreate.fRotateAngle = databuffer:readFloat()
    	FishCreate.PointOffSet = {}
    	FishCreate.PointOffSet.x = databuffer:readShort()
    	FishCreate.PointOffSet.y = databuffer:readShort()

    	FishCreate.fInitalAngle = databuffer:readFloat()
    	FishCreate.nBezierCount = databuffer:readInt()
    	FishCreate.TBzierPoint = {}

    	-- mlog(FishCreate.nFishKey,"FishCreate.nFishKey")
    	-- mlog(FishCreate.unCreateTime,"FishCreate.unCreateTime")
    	-- mlog(FishCreate.wHitChair,"FishCreate.wHitChair")
    	-- mlog(FishCreate.nFishType,"FishCreate.nFishType")
    	-- mlog(FishCreate.nFishState,"FishCreate.nFishState")
    	-- mlog(FishCreate.bRepeatCreate,"FishCreate.bRepeatCreate")
    	-- mlog(FishCreate.bFlockKill,"FishCreate.bFlockKill")
    	-- if(FishCreate.bRepeatCreate)then
    	-- 	mlog("bRepeatCreate",FishCreate.bRepeatCreate)
    	-- 	mlog("bRepeatCreate返回true")
    	-- else
    	-- 	mlog("bRepeatCreate",FishCreate.bRepeatCreate)
    	-- 	mlog("bRepeatCreate返回false")
    		
    	-- end
    	-- if(FishCreate.bFlockKill)then
    	-- 	mlog("bFlockKill",FishCreate.bFlockKill)
    	-- 	mlog("bFlockKill返回true")
    	-- else
    	-- 	mlog("bFlockKill",FishCreate.bFlockKill)
    	-- 	mlog("bFlockKill返回false")
    		
    	-- end
    	-- mlog(FishCreate.fRotateAngle,"FishCreate.fRotateAngle")
    	-- mlog(FishCreate.PointOffSet.x,"FishCreate.PointOffSet.x")
    	-- mlog(FishCreate.PointOffSet.y,"FishCreate.PointOffSet.y")
    	-- mlog(FishCreate.fInitalAngle,"FishCreate.fInitalAngle")
    	-- mlog(FishCreate.nBezierCount,"FishCreate.nBezierCount")
    	for i=1,FishCreate.nBezierCount do
    		local tagBezierPoint = {}
    		tagBezierPoint.BeginPoint = {}
    		tagBezierPoint.EndPoint = {}
    		tagBezierPoint.KeyOne = {}
    		tagBezierPoint.KeyTwo = {}
    		tagBezierPoint.BeginPoint.x = databuffer:readShort()
    		tagBezierPoint.BeginPoint.y = databuffer:readShort()
    		tagBezierPoint.EndPoint.x = databuffer:readShort()
    		tagBezierPoint.EndPoint.y = databuffer:readShort()
    		tagBezierPoint.KeyOne.x = databuffer:readShort()
    		tagBezierPoint.KeyOne.y = databuffer:readShort()
    		-- tagBezierPoint.KeyTwo.x = databuffer:readShort()
    		-- tagBezierPoint.KeyTwo.y = databuffer:readShort()
    		tagBezierPoint.Time  =  databuffer:readShort()

    		FishCreate.TBzierPoint[1][i] = {tagBezierPoint}
    		
    	end

         local function dealproducttime ()
            local entertime = self._dataModel.m_enterTime
            local productTime = FishCreate.unCreateTime + (self._dataModel.m_secene.server_time - entertime)
            return productTime 
         end

         FishCreate.nProductTime = dealproducttime()

         table.insert(self._dataModel.m_fishCreateList, FishCreate)

         if FishCreate.nFishType == g_var(cmd).FishType.FishType_ShuangTouQiEn or FishCreate.nFishType == g_var(cmd).FishType.FishType_JinLong or FishCreate.nFishType == g_var(cmd).FishType.FishType_LiKui then
            local tips 

            if FishCreate.nFishType == g_var(cmd).FishType.FishType_ShuangTouQiEn then
                tips = "双头企鹅"
            elseif FishCreate.nFishType == g_var(cmd).FishType.FishType_JinLong then
                tips = "金龙"
            else
                tips = "李逵"
            end

            tips = tips.."即将出现,请玩家做好准备!!!"

            self._gameView:Showtips(tips)
         end
    	end
    	mlog("#self._dataModel.m_fishCreateList==========",self._dataModel.m_fishCreateList)
    end
end


function Lkby_Scene:onSubFishCatch( databuffer )
  
  --print("捕捉鱼...........................................")

    if not self.m_cannonLayer  then
      return
    end

    local catchNum = math.floor(databuffer:getlen()/18)

    if catchNum >= 1 then
        for i=1,catchNum do
           local catchData = ExternalFun.read_netdata(g_var(cmd).CMD_S_CatchFish,databuffer)
           local fish = self._dataModel.m_fishList[catchData.nFishIndex]

           if nil ~= fish then

             if fish.m_data.nFishType == g_var(cmd).FishType.FishType_ShuiHuZhuan then
                
                if #self._dataModel.m_fishCreateList > 0 then

                  for k,v in pairs(self._dataModel.m_fishCreateList) do
                    local fishdata = v
                    fishdata.nProductTime = fishdata.nProductTime + 5000
                  end

                end
                
                 if #self._dataModel.m_waitList > 0 then

                    for k,v in pairs(self._dataModel.m_waitList) do
                      local fishdata = v
                      fishdata.nProductTime = fishdata.nProductTime + 5000
                    end

                 end
             end

             if fish.m_data.nFishType == g_var(cmd).FishType.FishType_BaoXiang then
                local nFishKey = fish.m_data.nFishKey
                fish:removeFromParent()
                self._dataModel.m_fishList[nFishKey] = nil

                return
  
             end

             local random = math.random(5)
             local smallSound = string.format("sound_res/samll_%d.wav", random)  
             local bigSound = string.format("sound_res/big_%d.wav", fish.m_data.nFishType)

             if fish.m_data.nFishType <  g_var(cmd).FISH_KING_MAX then
                self._dataModel:playEffect(smallSound)
             else
                self._dataModel:playEffect(bigSound)
             end

             local fishPos = cc.p(fish:getPositionX(),fish:getPositionY())
  
             if self._dataModel.m_reversal then 
               fishPos = cc.p(D_SIZE.width-fishPos.x,D_SIZE.height-fishPos.y)
             end
  
  
             if fish.m_data.nFishType > g_var(cmd).FishType.FishType_JianYu then
               self._dataModel:playEffect(g_var(cmd).CoinLightMove)
               local praticle = cc.ParticleSystemQuad:create("game_res/particles_test2.plist")
               praticle:setPosition(fishPos)
               praticle:setPositionType(cc.POSITION_TYPE_GROUPED)
               self:addChild(praticle,3)
             end

             local fishtype = fish.m_data.nFishType

             --鱼死亡处理
             fish:deadDeal()

             --金币动画
             local call = cc.CallFunc:create(function(  )
               self._gameView:ShowCoin(catchData.lScoreCount, catchData.wChairID, fishPos, fishtype)
             end)

             self:runAction(cc.Sequence:create(cc.DelayTime:create(1.0),call))

             --获取炮台视图位置
             local cannonPos = catchData.wChairID
             if self._dataModel.m_reversal then 
                cannonPos = 5 - cannonPos
             end

             if catchData.wChairID == self.m_nChairID then   --自己

                 GlobalUserItem.lUserScore = GlobalUserItem.lUserScore + catchData.lScoreCount
         
                  --更新用户分数
                  self.m_cannonLayer:updateUserScore( GlobalUserItem.lUserScore,cannonPos+1 )

                  --捕获鱼收获
                  self._dataModel.m_getFishScore = self._dataModel.m_getFishScore + catchData.lScoreCount
                
                  --捕鱼数量
                  if fishtype <= 21 then 
                    self.m_catchFishCount[fishtype+1] = self.m_catchFishCount[fishtype+1] + 1
                  end
              else    --其他玩家
                
                  --获取用户
                  local userid = self.m_cannonLayer:getUserIDByCannon(cannonPos+1)

                  for k,v in pairs(self.m_cannonLayer._userList) do
                    local item = v
                    if item.dwUserID == userid  then
                        item.lScore = item.lScore + catchData.lScoreCount

                        --更新用户分数
                         self.m_cannonLayer:updateUserScore( item.lScore,cannonPos+1 )

                        break
                    end
                  end
             end
           end
        end
      end
end

function Lkby_Scene:createSecoundSchedule() 

	local function setSecondTips() --提示

		if nil == self._gameView:getChildByTag(10000) then 

		  local tipBG = cc.Sprite:create("game/likuibuyu/secondTip.png")
		  tipBG:setPosition(680, 382.5)
		  tipBG:setTag(10000)
		  self._gameView:addChild(tipBG,100)


		  local watch = cc.Sprite:createWithSpriteFrameName("watch_0.png")
		  watch:setPosition(60, 45)
		  tipBG:addChild(watch)

		  local animation = cc.AnimationCache:getInstance():getAnimation("watchAnim")
		  if nil ~= animation then
		     watch:runAction(cc.RepeatForever:create(cc.Animate:create(animation)))
		  end

		--排名文本
		-- local labeltxt = display.newText(index,26,Color.danrubaise)
		-- layout:addChild(Coord.ingap(layout,labeltxt,"LL",20,"CC",0))
		  local time = display.newText(string.format("%d秒",self.m_nSecondCount), 26,Color.danrubaise)
		  time:setTextColor(cc.YELLOW)
		  time:setAnchorPoint(0.0,0.5)
		  time:setPosition(117, 55)
		  time:setTag(1)
		  tipBG:addChild(time)

		  local buttomTip = display.newText("60秒未开炮,即将退出游戏", 20,Color.danrubaise)
		  buttomTip:setAnchorPoint(0.0,0.5)
		  buttomTip:setPosition(117, 30)
		  tipBG:addChild(buttomTip)

		else

		     local tipBG = self._gameView:getChildByTag(10000)
		     local time = tipBG:getChildByTag(1)
		     time:setString(string.format("%d秒",self.m_nSecondCount))      
		end

	end

  local function removeTip()

    local tipBG = self._gameView:getChildByTag(10000)
    if nil ~= tipBG then
      tipBG:removeFromParent()
    end

  end


  local function update(dt)

    if self.m_nSecondCount == 0 then --发送起立
      removeTip()
      self:onKeyBack()
      return
    end

    if self.m_nSecondCount - 1 >= 0 then 
      self.m_nSecondCount = self.m_nSecondCount - 1
    end

    if self.m_nSecondCount <= 10 then
       setSecondTips()
    end

  end

  if nil == self.m_secondCountSchedule then
    self.m_secondCountSchedule = scheduler:scheduleScriptFunc(update, 1.0, false)
  end

end

function  Lkby_Scene:onKeyBack()
	self:onCleanup()
    return true
end

--创建定时器
function Lkby_Scene:onCreateSchedule()
  local isBreak0 = false
  local isBreak1 = true

--鱼队列
	  local function dealCanAddFish()
  		-- mlog("isBreak0",isBreak0)
  		-- mlog("isBreak1",isBreak1)

	    if isBreak0 then
	       isBreak1 = false
	      return
	    end
	    mlog("#self._dataModel.m_waitList",#self._dataModel.m_waitList)
	     if #self._dataModel.m_waitList >=5 then
	       isBreak0 = true
	       isBreak1 = false
	       return
	    end

	    table.sort( self._dataModel.m_fishCreateList, function ( a ,b )
	      return a.nProductTime < b.nProductTime
	    end )

	    local function isCanAddtoScene(data)

	    
	      local iscanadd = false

	      local time = os.time()
	      if data.nProductTime <= time and data.nProductTime ~= 0  then

	          iscanadd = true
	          return iscanadd
	      end

	       return iscanadd
	    end

	    local texture = cc.Director:getInstance():getTextureCache():getTextureForKey("game/likuibuyu/fish_move1.png")
	    local texture1 = cc.Director:getInstance():getTextureCache():getTextureForKey("game/likuibuyu/fish_move2.png")
	    local anim = cc.AnimationCache:getInstance():getAnimation("animation_fish_move26")
	    -- mlog("texture",texture)
	    -- mlog("texture1",texture1)
	    -- mlog("anim",anim)
	    if not texture or not texture1 or not anim then
	       return
	    end
	    mlog("#self._dataModel.m_fishCreateList",#self._dataModel.m_fishCreateList)
	    if 0 ~= #self._dataModel.m_fishCreateList  then
	      local fishdata = self._dataModel.m_fishCreateList[1]
	      table.remove(self._dataModel.m_fishCreateList,1)
	      local iscanadd = isCanAddtoScene(fishdata)
	      mlog("iscanadd",iscanadd)
	      if iscanadd then
	          local fish =  g_var(Fish).new(fishdata,self)
	          fish:initAnim()
	          fish:setTag(g_var(cmd).Tag_Fish)
	          fish:initWithState()
	          fish:initPhysicsBody()
	          self.m_fishLayer:addChild(fish, fish.m_data.nFishType + 1)
	          self._dataModel.m_fishList[fish.m_data.nFishKey] = fish
	        else
	          table.insert(self._dataModel.m_waitList, fishdata)
	      end
	    end 
	  end

--等待队列
	  local function dealWaitList( )

	      if isBreak1 then
	        isBreak0 = false
	        return
	      end

	      if  #self._dataModel.m_waitList == 0 then
	         
	          isBreak0 = false
	          isBreak1 = true
	          return
	      end

	      if  #self._dataModel.m_waitList ~= 0 then
	       
	          for i=1, #self._dataModel.m_waitList do
	             local fishdata = self._dataModel.m_waitList[i]
	             table.insert(self._dataModel.m_fishCreateList,1,fishdata)
	          end

	         self._dataModel.m_waitList = {}
	      end
	  end

--定位大鱼
	local function selectMaxFish()

	     --自动锁定
	      if self._dataModel.m_autolock  then

	           local fish = self._dataModel.m_fishList[self._dataModel.m_fishIndex]

	           if nil == fish then
	              self._dataModel.m_fishIndex = self._dataModel:selectMaxFish()
	              return
	           end

	           local rect = cc.rect(0,0,D_SIZE.width,D_SIZE.height)
	           local pos = cc.p(fish:getPositionX(),fish:getPositionY()) 
	          
	           if  not cc.rectContainsPoint(rect,pos) then
	               self._dataModel.m_fishIndex = self._dataModel:selectMaxFish()
	      
	           end
	         
	      end
	end


	local function update(dt)

	--筛选大鱼
	  selectMaxFish()

	--能加入显示的鱼群
	  dealCanAddFish()

	--需等待的鱼群
	  dealWaitList()

	end

--游戏定时器
	if nil == self.m_scheduleUpdate then
		self.m_scheduleUpdate = scheduler:scheduleScriptFunc(update, 0, false)
	end

end


--判断自己位置 是否需翻转
function Lkby_Scene:setReversal( )
   
  -- if self.m_pUserItem then
  --   if self.m_pUserItem.wChairID < 3 then
  --       self._dataModel.m_reversal = true
  --   end
  -- end

  -- return self._dataModel.m_reversal

end

--初始化UI
function Lkby_Scene:initUi()

	--自己信息
  	-- self._gameView:initUserInfo()
end

--初始化数据
function Lkby_Scene:initData()
end

function Lkby_Scene:Quit()
	ConnectMgr.connect("gamehall.QuitRoomConnect")
	display.enterScene("src.ui.scene.MainScene")
end

function Lkby_Scene:onExit()

  mlog("Lkby_Scene onExit()....")

  --移除碰撞监听
	cc.Director:getInstance():getEventDispatcher():removeEventListener(self.contactListener)

  -- cc.Director:getInstance():getEventDispatcher():removeCustomEventListeners(g_var(cmd).Event_LoadingFinish)

 		--移除推送端口
	ConnectMgr.unRegistorJBackPort(ConnectMgr.getMainSocket(),Port.PORT_LIKUIBUYU)
	
  --释放游戏所有定时器
  self:unSchedule()

end

function Lkby_Scene:unSchedule( )

--游戏定时器
	if nil ~= self.m_scheduleUpdate then
		scheduler:unscheduleScriptEntry(self.m_scheduleUpdate)
		self.m_scheduleUpdate = nil
	end

  --60秒倒计时定时器
  if nil ~= self.m_secondCountSchedule then 
      scheduler:unscheduleScriptEntry(self.m_secondCountSchedule)
      self.m_secondCountSchedule = nil
  end
end

--@override
function Lkby_Scene:onCleanup()
	mlog("关闭面板。。。。。")
	self:removeAllEvent()
	-- self:removeFromParent(true)
	SoundsManager.stopAllMusic()
	-- require("src.games.qiangzhuangniuniu.data.Qznn_GameMgr").getInstance():destory(self.noNeedClearRes)
	self:Quit()

end

return Lkby_Scene