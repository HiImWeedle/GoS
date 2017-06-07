	local function GetDistanceSqr(p1, p2)
	    local dx = p1.x - p2.x
	    local dz = p1.z - p2.z
	    return (dx * dx + dz * dz)
	end

	local sqrt = math.sqrt  
	local function GetDistance(p1, p2)
		return sqrt(GetDistanceSqr(p1, p2))
	end

	local function GetDistance2D(p1,p2)
		return sqrt((p2.x - p1.x)*(p2.x - p1.x) + (p2.y - p1.y)*(p2.y - p1.y))
	end

	local function Ready(spell)
		return myHero:GetSpellData(spell).currentCd == 0 and myHero:GetSpellData(spell).level > 0 and myHero:GetSpellData(spell).mana <= myHero.mana
	end

	local Orb = 3
	local TEAM_ALLY = myHero.team
	local TEAM_JUNGLE = 300
	local TEAM_ENEMY = 300 - TEAM_ALLY

	local function GetTarget(range) --temp version
	local target = nil 
		if Orb == 1 then
			target = EOW:GetTarget(range)
		elseif Orb == 2 then 
			target = _G.SDK.TargetSelector:GetTarget(range)
		elseif Orb == 3 then
			target = GOS:GetTarget(range)
		end
		return target 
	end

	local _EnemyHeroes
	local function GetEnemyHeroes()
		if _EnemyHeroes then return _EnemyHeroes end
		_EnemyHeroes = {}
		for i = 1, Game.HeroCount() do
			local unit = Game.Hero(i)
			if unit.team == TEAM_ENEMY then
				table.insert(_EnemyHeroes, unit)
			end
		end
		return _EnemyHeroes
	end 

 	local function RStacks()
		for i = 1, 63 do 
		local Buff = myHero:GetBuff(i)
			if Buff.name:lower() == "kogmawlivingartillerycost" and Game.Timer() < Buff.expireTime then
				return Buff.count
			end
		end
		return 0
	end

	local abs = math.abs 
	local deg = math.deg 
	local acos = math.acos 
	local function IsFacing(unit)
	    local V = Vector((unit.pos - myHero.pos))
	    local D = Vector(unit.dir)
	    local Angle = 180 - deg(acos(V*D/(V:Len()*D:Len())))
	    if abs(Angle) < 80 then 
	        return true  
	    end
	    return false
	end

	local intToMode = {
   		[0] = "",
   		[1] = "Combo",
   		[2] = "Harass",
   		[3] = "LastHit",
   		[4] = "Clear"
	}

	function GetMode()
		if Orb == 1 then
			return intToMode[EOW.CurrentMode]
		elseif Orb == 2 then
			if _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_COMBO] then
				return "Combo"
			elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_HARASS] then
				return "Harass"	
			elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_LANECLEAR] or _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_JUNGLECLEAR] then
				return "Clear"
			elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_LASTHIT] then
				return "LastHit"
			elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_FLEE] then
				return "Flee"
			end
		else
			return GOS.GetMode()
		end
	end

	local ItemHotKey = {
    [ITEM_1] = HK_ITEM_1,
    [ITEM_2] = HK_ITEM_2,
    [ITEM_3] = HK_ITEM_3,
    [ITEM_4] = HK_ITEM_4,
    [ITEM_5] = HK_ITEM_5,
    [ITEM_6] = HK_ITEM_6,
	}

	local function GetItemSlot(unit, id)
	  for i = ITEM_1, ITEM_7 do
	    if unit:GetItemData(i).itemID == id then
	      return i
	    end
	  end
	  return 0 
	end

	local function GetMinionCount(range, pos)
		local pos = pos.pos
    	local count = 0
    	for i = 1,Game.MinionCount() do
    	    local hero = Game.Minion(i)
    	    local Range = range * range
    	    if hero.team ~= TEAM_ALLY and hero.dead == false and GetDistanceSqr(pos, hero.pos) < Range then
    	        count = count + 1
    	    end
    	end
    	return count
	end

	local function EnemyAround()
		for i = 1, Game.HeroCount() do 
		local Hero = Game.Hero(i) 
			if Hero.dead == false and Hero.team == TEAM_ENEMY and GetDistanceSqr(myHero.pos, Hero.pos) < 360000 then
				return true
			end
		end
		return false
	end

	local function IsValidTarget(unit, range)
    	return unit and unit.team == TEAM_ENEMY and unit.dead == false and GetDistanceSqr(myHero.pos, unit.pos) <= (range + myHero.boundingRadius + unit.boundingRadius)^2 and unit.isTargetable and unit.isTargetableToTeam and unit.isImmortal == false and unit.visible
	end

	local function IsValidCreep(unit, range)
    	return unit and unit.team ~= TEAM_ALLY and unit.dead == false and GetDistanceSqr(myHero.pos, unit.pos) <= (range + myHero.boundingRadius + unit.boundingRadius)^2 and unit.isTargetable and unit.isTargetableToTeam and unit.isImmortal == false and unit.visible
	end

	local function IsImmobileTarget(unit)
		for i = 0, unit.buffCount do
			local buff = unit:GetBuff(i)
			if buff and (buff.type == 5 or buff.type == 11 or buff.type == 29 or buff.type == 24 or buff.name == "recall") and buff.count > 0 then
				return true
			end
		end
		return false	
	end

	local _OnVision = {}
	function OnVision(unit)
		if _OnVision[unit.networkID] == nil then _OnVision[unit.networkID] = {state = unit.visible , tick = GetTickCount(), pos = unit.pos} end
		if _OnVision[unit.networkID].state == true and not unit.visible then _OnVision[unit.networkID].state = false _OnVision[unit.networkID].tick = GetTickCount() end
		if _OnVision[unit.networkID].state == false and unit.visible then _OnVision[unit.networkID].state = true _OnVision[unit.networkID].tick = GetTickCount() end
		return _OnVision[unit.networkID]
	end
	Callback.Add("Tick", function() OnVisionF() end)
	local visionTick = GetTickCount()
	function OnVisionF()
		if GetTickCount() - visionTick > 100 then
			for i,v in pairs(GetEnemyHeroes()) do
				OnVision(v)
			end
		end
	end

	local _OnWaypoint = {}
	function OnWaypoint(unit)
		if _OnWaypoint[unit.networkID] == nil then _OnWaypoint[unit.networkID] = {pos = unit.posTo , speed = unit.ms, time = Game.Timer()} end
		if _OnWaypoint[unit.networkID].pos ~= unit.posTo then 
			-- print("OnWayPoint:"..unit.charName.." | "..math.floor(Game.Timer()))
			_OnWaypoint[unit.networkID] = {startPos = unit.pos, pos = unit.posTo , speed = unit.ms, time = Game.Timer()}
				DelayAction(function()
					local time = (Game.Timer() - _OnWaypoint[unit.networkID].time)
					local speed = GetDistance2D(_OnWaypoint[unit.networkID].startPos,unit.pos)/(Game.Timer() - _OnWaypoint[unit.networkID].time)
					if speed > 1250 and time > 0 and unit.posTo == _OnWaypoint[unit.networkID].pos and GetDistance(unit.pos,_OnWaypoint[unit.networkID].pos) > 200 then
						_OnWaypoint[unit.networkID].speed = GetDistance2D(_OnWaypoint[unit.networkID].startPos,unit.pos)/(Game.Timer() - _OnWaypoint[unit.networkID].time)
						-- print("OnDash: "..unit.charName)
					end
				end,0.05)
		end
		return _OnWaypoint[unit.networkID]
	end

	local function GetPred(unit,speed,delay) --still Noddys pred
		local speed = speed or math.huge
		local delay = delay or 0.25
		local unitSpeed = unit.ms
		if OnWaypoint(unit).speed > unitSpeed then unitSpeed = OnWaypoint(unit).speed end
		if OnVision(unit).state == false then
			local unitPos = unit.pos + Vector(unit.pos,unit.posTo):Normalized() * ((GetTickCount() - OnVision(unit).tick)/1000 * unitSpeed)
			local predPos = unitPos + Vector(unit.pos,unit.posTo):Normalized() * (unitSpeed * (delay + (GetDistance(myHero.pos,unitPos)/speed)))
			if GetDistance(unit.pos,predPos) > GetDistance(unit.pos,unit.posTo) then predPos = unit.posTo end
			return predPos
		else
			if unitSpeed > unit.ms then
				local predPos = unit.pos + Vector(OnWaypoint(unit).startPos,unit.posTo):Normalized() * (unitSpeed * (delay + (GetDistance(myHero.pos,unit.pos)/speed)))
				if GetDistance(unit.pos,predPos) > GetDistance(unit.pos,unit.posTo) then predPos = unit.posTo end
				return predPos
			elseif IsImmobileTarget(unit) then
				return unit.pos
			else
				return unit:GetPrediction(speed,delay)
			end
		end	
	end

	require "2DGeometry"
	require "DamageLib"
	require "Collision"
	require "Eternal Prediction"

	class "KogMaw" 

	local Kog = MenuElement({type = MENU, id = "Kog", name = "Weedle | KogMaw"})
	local QColl = Collision:SetSpell(1175, 1600, 0.25, 80, true)
	local QRange = 1175 * 1175
	local WRange = 800 * 800
	local ERange = 1200 * 1200
	local QD = {speed = 1600, delay = 0.25, range = 1175, width = 80}
	local QS = Prediction:SetSpell(QD, TYPE_LINE, true)
	local ED = {speed = 1000, delay = 0.25, range = 1200}
	local ES = Prediction:SetSpell(ED, TYPE_LINE, true)
	local RD = {speed = math.huge, delay = 1.2, range = 1800}
	local RS = Prediction:SetSpell(RD, TYPE_CIRCULAR, true)

	function KogMaw:__init()
		if myHero.charName ~= "KogMaw" then return end
		Callback.Add("Tick", function() self:Tick() end)
		Callback.Add("Draw", function() self:Draw() end)
	  	self:Menu()
	  	if _G.EOWLoaded then
			Orb = 1
		elseif _G.SDK and _G.SDK.Orbwalker then
			Orb = 2
		end
	  	print("Weedle | KogMaw | Loaded")
	end	

	function KogMaw:Menu() 
		Kog:MenuElement({name = " ", drop = {"General Settings"}})
		Kog:MenuElement({type = MENU, id = "c", name = "Combo"})
		Kog.c:MenuElement({id = "Q", name = "Use Q", value = true})
		Kog.c:MenuElement({id = "W", name = "Use W", value = true})
		Kog.c:MenuElement({id = "E", name = "Use E", value = true})
		Kog.c:MenuElement({id = "R", name = "Use R", value = true})
		Kog.c:MenuElement({id = "Max", name = "Max R Stacks", value = 3, min = 1, max = 10, step = 1})
		Kog.c:MenuElement({id = "D", name = "Min Distance to R", value = 700, min = 300, max = 1500, step = 100})
		Kog:MenuElement({type = MENU, id = "h", name = "Harass"})
		Kog.h:MenuElement({id = "Q", name = "Use Q", value = true})
		Kog.h:MenuElement({id = "W", name = "Use W", value = true})
		Kog.h:MenuElement({id = "E", name = "Use E", value = true})	
		Kog:MenuElement({type = MENU, id = "w", name = "Clear"})
		Kog.w:MenuElement({id = "W", name = "Use W", value = true})
		Kog.w:MenuElement({id = "WC", name = "Min Amount to W", value = 4, min = 1, max = 7, step = 1})
		Kog.w:MenuElement({id = "R", name = "Use R", value = true})
		Kog.w:MenuElement({id = "RC", name = "Min Amount to R", value = 4, min = 1, max = 7, step = 1})	
		Kog:MenuElement({type = MENU, id = "m", name = "Mana Manager"})
		Kog.m:MenuElement({name = " ", drop = {"Combo, Harass [%]"}})
		Kog.m:MenuElement({id = "Q", name = "Q Mana", value = 10, min = 0, max = 100, step = 1})
		Kog.m:MenuElement({id = "W", name = "W Mana", value = 10, min = 0, max = 100, step = 1})
		Kog.m:MenuElement({id = "E", name = "E Mana", value = 10, min = 0, max = 100, step = 1})
		Kog.m:MenuElement({id = "R", name = "R Mana", value = 10, min = 0, max = 100, step = 1})		
		Kog.m:MenuElement({name = " ", drop = {"Clear [%]"}})
		Kog.m:MenuElement({id = "WW", name = "W Mana", value = 10, min = 0, max = 100, step = 1})
		Kog.m:MenuElement({id = "RW", name = "R Mana", value = 10, min = 0, max = 100, step = 1})
		Kog:MenuElement({name = " ", drop = {"Advanced Settings"}})
		Kog:MenuElement({type = MENU, id = "p", name = "Prediction"})
		Kog.p:MenuElement({id = "Mode", name = "Prediction Method", drop = {"Eternal", "Build In"}})	
		Kog.p:MenuElement({id = "Q", name = "Min Q Hitchance", value = 0.2, min = 0, max = 1, step = 0.01})
		Kog.p:MenuElement({id = "E", name = "Min E Hitchance", value = 0.2, min = 0, max = 1, step = 0.01})	
		Kog.p:MenuElement({id = "R", name = "Min R Hitchance", value = 0.15, min = 0, max = 1, step = 0.01})
		Kog.p:MenuElement({type = SPACE, name = "Recommended values between 0 and 0.25"})	
		Kog:MenuElement({type = MENU, id = "a", name = "Activator"})
		Kog.a:MenuElement({type = MENU, id = "YG", name = "Youmuu's Ghostblade"})
		Kog.a.YG:MenuElement({id = "ON", name = "Enabled in Combo", value = true})
		Kog.a.YG:MenuElement({id = "Dist", name = "Target distance", value = 1500, min = 0, max = 2000, step = 100})
		Kog.a:MenuElement({type = MENU, id = "BC", name = "Bilgewater Cutlass"})
		Kog.a.BC:MenuElement({id = "ON", name = "Enabled in Combo", value = true})
		Kog.a.BC:MenuElement({id = "HP", name = "Min HP%", value = 80, min = 0, max = 100, step = 1})
		Kog.a:MenuElement({type = MENU, id = "BOTRK", name = "Blade of the Ruined King"})
		Kog.a.BOTRK:MenuElement({id = "ON", name = "Enabled in Combo", value = true})
		Kog.a.BOTRK:MenuElement({id = "HP", name = "Min HP%", value = 80, min = 0, max = 100, step = 1})
		Kog:MenuElement({type = MENU, id = "d", name = "Drawings"})
		Kog.d:MenuElement({id = "ON", name = "Enable Drawings", value = true})
		Kog.d:MenuElement({id = "Lines", name = "Draw Lines", value = false})
		Kog.d:MenuElement({type = MENU, id = "Q", name = "Q"})
		Kog.d.Q:MenuElement({id = "ON", name = "Enabled", value = true})       
		Kog.d.Q:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
		Kog.d.Q:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
		Kog.d:MenuElement({type = MENU, id = "W", name = "W"})
		Kog.d.W:MenuElement({id = "ON", name = "Enabled", value = false})       
		Kog.d.W:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
		Kog.d.W:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
		Kog.d:MenuElement({type = MENU, id = "E", name = "E"})
		Kog.d.E:MenuElement({id = "ON", name = "Enabled", value = true})       
		Kog.d.E:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
		Kog.d.E:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
		Kog.d:MenuElement({type = MENU, id = "R", name = "R"})
		Kog.d.R:MenuElement({id = "ON", name = "Enabled", value = true})       
		Kog.d.R:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
		Kog.d.R:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})				
		Kog:MenuElement({name = " ", drop = {"Script Information"}})
		Kog:MenuElement({name = "Script Version", drop = {"1.1"}})
		Kog:MenuElement({name = "League Version", drop = {"7.11"}})
		Kog:MenuElement({name = "Author", drop = {"Weedle"}})
	end

	function KogMaw:Pred(spell,unit,D) 
		if Kog.p.Mode:Value()  == 1 then 
			if spell == 1 then 
			local Q = Kog.p.Q:Value()
			local Pos = QS:GetPrediction(unit, myHero.pos)
				if Pos and Pos.hitChance >= Q and Pos:mCollision() == 0 then 
					return Pos.castPos
				end
			elseif spell == 3 then
			local E = Kog.p.E:Value()
			local Pos = ES:GetPrediction(unit, myHero.pos)
				if Pos and Pos.hitChance >= E then 
					return Pos.castPos
				end
			elseif spell == 4 then 
			local R = Kog.p.R:Value()
			local Pos = RS:GetPrediction(unit, myHero.pos)
			local RRange = 900 + 300 * myHero:GetSpellData(_R).level
				if Pos and Pos.hitChance >= R and unit.distance < RRange then
					return Pos.castPos
				end
			end
		else
		local F = IsFacing(unit)
			if spell == 1 then
			local Pos = GetPred(unit, 1600, 0.25 + Game.Latency()/1000)
				if Pos and not QColl:__GetCollision(myHero, unit, 5) then
					if F and D < QRange then	
						return Pos
					elseif D < QRange - 30625 then 
						return Pos
					end
				end
			elseif spell == 3 then
			local Pos = GetPred(unit, 1000, 0.25 + Game.Latency()/1000)
					if F and D < ERange then	
						return Pos
					elseif D < ERange - 40000 then 
						return Pos
					end
			elseif spell == 4 then 
			local Pos = GetPred(unit, 20000, 1 + Game.Latency()/1000)
			local RRange = (900 + 300 * myHero:GetSpellData(_R).level)^2
					if D < RRange then
						return Pos
					end
			end 
		end
	end

	function KogMaw:Tick()
		if myHero.dead == false and Game.IsChatOpen() == false then
		local Mode = GetMode()
			if Mode == "Combo" then
				self:Combo()
			elseif Mode == "Harass" then 
				self:Harass()
			elseif Mode == "Clear" then
				self:Clear()
			end
		end
	end

	function KogMaw:RLogic()
	local RPos = nil
	local Most = 0 
		for i = 1, Game.MinionCount() do 
		local Minion = Game.Minion(i)
			if IsValidCreep(Minion, 1200) then 
				local Count = GetMinionCount(375, Minion)
				if Count > Most then 
					Most = Count
					RPos = Minion.pos
				end
			end
		end 
		return RPos, Most
	end 

	function KogMaw:Combo()
		local activeSpell = myHero.activeSpell
    	if activeSpell.valid and activeSpell.spellWasCast == false then 
    		return 
    	end 
    	local target = GetTarget(2000)
    	if target == nil then 
    		return
    	end
    	local D = GetDistanceSqr(target.pos, myHero.pos)
    	local d = target.distance
    	local HP = target.health/target.maxHealth
    	local MP = myHero.mana/myHero.maxMana
    	if Kog.a.YG.ON:Value() then 
    	local YG = GetItemSlot(myHero, 3142)
    		if YG >= 1 and Ready(YG) and d <= Kog.a.YG.Dist:Value() then
    			Control.CastSpell(ItemHotKey[YG])
    		end
    	end
    	if Kog.a.BC.ON:Value() then
    	local BC = GetItemSlot(myHero, 3144) 
    		if BC >= 1 and Ready(BC) and HP < Kog.a.BC.HP:Value() and d < 550 then
    			Control.CastSpell(ItemHotKey[BC], target)
    		end
    	end
    	if Kog.a.BOTRK.ON:Value() then
    	local BOTRK = GetItemSlot(myHero, 3153)
    		if BOTRK >= 1 and Ready(BOTRK) and HP < Kog.a.BOTRK.HP:Value() and d < 550 then
    			Control.CastSpell(ItemHotKey[BOTRK], target)
    		end
    	end
    	if Kog.c.Q:Value() and Ready(_Q) and MP > Kog.m.Q:Value()/100 then
    		local Pos = self:Pred(1, target, D)
    		if Pos then	
	    		Control.CastSpell(HK_Q, Pos)
    		end
    	end
    	if Kog.c.W:Value() and Ready(_W) and MP > Kog.m.W:Value()/100 then
    		if D < WRange then 
    			Control.CastSpell(HK_W)
    		end
    	end
    	if Kog.c.E:Value() and Ready(_E) and MP > Kog.m.E:Value()/100 then 
    		local Pos = self:Pred(3, target, D)
    		if Pos then
    			Control.CastSpell(HK_E, Pos)
    		end
    	end
    	if Kog.c.R:Value() and Ready(_R) and RStacks() <= Kog.c.Max:Value() and MP > Kog.m.R:Value()/100 then
    		local Pos = self:Pred(4, target, D)
    		if Pos and d > Kog.c.D:Value() then
    			Control.CastSpell(HK_R, Pos)
    		end
    	end
    end 

    function KogMaw:Harass()
    	local activeSpell = myHero.activeSpell
    	if activeSpell.valid and activeSpell.spellWasCast == false then 
    		return 
    	end 
    	local target = GetTarget(2000)
    	if target == nil then 
    		return
    	end
    	local D = GetDistanceSqr(target.pos, myHero.pos)
    	local HP = target.health/target.maxHealth
    	local MP = myHero.mana/myHero.maxMana
    	if Kog.h.Q:Value() and Ready(_Q) and MP > Kog.m.Q:Value()/100 then
			local Pos = self:Pred(1, target, D)
			if Pos then	
				Control.CastSpell(HK_Q, Pos)
			end
		end
		if Kog.h.W:Value() and Ready(_W) and MP > Kog.m.W:Value()/100 then
			if D < WRange then 
				Control.CastSpell(HK_W)
			end
		end
		if Kog.h.E:Value() and Ready(_E) and MP > Kog.m.E:Value()/100 then 
			local Pos = self:Pred(3, target, D)
			if Pos then
				Control.CastSpell(HK_E, Pos)
			end
		end
	end

	function KogMaw:Clear() 
	    local activeSpell = myHero.activeSpell
    	if activeSpell.valid and activeSpell.spellWasCast == false then 
    		return 
    	end
    	local MP = myHero.mana/myHero.maxMana
    	if Kog.w.W:Value() and Ready(_W) and MP > Kog.m.WW:Value()/100 then 
    		local Count = GetMinionCount(700, myHero)
    		local C = Kog.w.WC:Value()
    		if Count >= C then 
    			Control.CastSpell(HK_W)
    		end
    	end
    	if Kog.w.R:Value() and Ready(_R) and RStacks() <= Kog.c.Max:Value() and MP > Kog.m.RW:Value()/100 then
    		local RPos, Count = self:RLogic()
    		if RPos == nil then return end
    		if Count >= Kog.w.RC:Value() then 
    			Control.CastSpell(HK_R, RPos)
    		end
    	end
    end

	local Radius =  myHero.boundingRadius
	local Radius2 = Radius - 3 
	function KogMaw:Draw()
		if myHero.dead == false and Kog.d.ON:Value() then
			if Kog.d.Lines:Value() then 
			local C1 = Circle(Point(myHero), Radius)
			local C2 = Circle(Point(myHero), Radius2)
				for i = 1, Game.HeroCount() do 
				local h = Game.Hero(i)
					if h and h.team == TEAM_ENEMY and h.dead == false and h.pos:To2D().onScreen then 
						C1:__draw(3, Draw.Color(255, 000, 255, 000))
						C2:__draw(3, Draw.Color(255, 000, 000, 000))
						local mpos = myHero.pos
						local hpos = h.pos
						local V = mpos + (hpos - mpos):Normalized() * Radius
						local T = hpos + (mpos - hpos):Normalized() * Radius
						local LSS = Circle(Point(h), Radius)
						local LSS2 = Circle(Point(h), Radius2)
						LSS:__draw(4, Draw.Color(255, 255, 000, 000))
						LSS2:__draw(3, Draw.Color(255, 000, 000, 000))
						local LS = LineSegment(Point(V), Point(T))
						local target = GetTarget(2000)
						if target == nil then return end
						if target == h then 
							LS:__draw(3, Draw.Color(255, 000, 255, 000))
						end
					end
				end
			end
			if Kog.d.Q.ON:Value() then
				Draw.Circle(myHero.pos, 1175, Kog.d.Q.Width:Value(), Kog.d.Q.Color:Value())
			end
			if Kog.d.W.ON:Value() then
				Draw.Circle(myHero.pos, 700, Kog.d.W.Width:Value(), Kog.d.W.Color:Value())
			end
			if Kog.d.E.ON:Value() then
				Draw.Circle(myHero.pos, 1200, Kog.d.E.Width:Value(), Kog.d.E.Color:Value())
			end	
			if Kog.d.R.ON:Value() then
			local lvl = myHero:GetSpellData(_R).level
				if lvl >= 1 then
					Draw.Circle(myHero.pos, 900 + 300 * lvl, Kog.d.E.Width:Value(), Kog.d.E.Color:Value())
				end
			end		
		end
	end

	function OnLoad()
 		if _G[myHero.charName] and myHero.charName == "KogMaw" then 
 			_G[myHero.charName]()
 			print("Welcome back " .. myHero.name .. ", have a nice day!")
		end
	end
