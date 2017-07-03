	--[[
	________                __      _________ __                 ________        .__                             
	\______ \ _____ _______|  | __ /   _____//  |______ _______  \_____  \_______|__|____    ____   ____ _____   
	 |    |  \\__  \\_  __ \  |/ / \_____  \\   __\__  \\_  __ \  /   |   \_  __ \  \__  \  /    \ /    \\__  \  
	 |    `   \/ __ \|  | \/    <  /        \|  |  / __ \|  | \/ /    |    \  | \/  |/ __ \|   |  \   |  \/ __ \_
	/_______  (____  /__|  |__|_ \/_______  /|__| (____  /__|    \_______  /__|  |__(____  /___|  /___|  (____  /
	        \/     \/           \/        \/           \/                \/              \/     \/     \/     \/ 
	]]

		if myHero.charName ~= "Orianna" then return end

	local Sversion, Lversion = 1.04, 7.13
	local TEAM_ALLY = myHero.team
	local TEAM_JUNGLE = 300
	local TEAM_ENEMY = 300 - TEAM_ALLY
	local huge = math.huge 	
	local sqrt = math.sqrt  	
	local abs = math.abs 
	local deg = math.deg 
	local acos = math.acos 	
	local insert = table.insert 
	require "2DGeometry"
	require "DamageLib"		

	local Menu = MenuElement({id = "DarkStarOrianna", name = "Weedle | Dark Star Orianna", type = MENU, leftIcon = "https://raw.githubusercontent.com/HiImWeedle/GoS/master/Icons/OriannaIcon1.png"})
		Menu:MenuElement({name = " ", drop = {"General Settings"}})
		Menu:MenuElement({id = "C", name = "Combo", type = MENU})		
		Menu:MenuElement({id = "H", name = "Harass", type = MENU})
		Menu:MenuElement({name = " ", drop = {"Advanced Settings"}})
		Menu:MenuElement({id = "A", name = "Aimbot", type = MENU})
		Menu:MenuElement({id = "M", name = "Mana Manager", type = MENU})
		Menu:MenuElement({id = "O", name = "Orbwalker Keys", type = MENU})
		Menu.O:MenuElement({id = "Combo", name = "Combo", key = string.byte(" ")})
		Menu.O:MenuElement({id = "Harass", name = "Harass", key = string.byte("C")})
		Menu.O:MenuElement({id = "Clear", name = "Clear", key = string.byte("V")})
		Menu.O:MenuElement({id = "LastHit", name = "LastHit", key = string.byte("X")})	
		Menu:MenuElement({id = "D", name = "Drawings", type = MENU})		
		Menu:MenuElement({name = " ", drop = {"Script Info"}})
		Menu:MenuElement({name = "Script Version", drop = {Sversion}})
		Menu:MenuElement({name = "League Version", drop = {Lversion}})
		Menu:MenuElement({name = "Author", drop = {"Weedle"}})

	---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	

	local function GetMode()
		if Menu.O.Combo:Value() then return 1 end 
		if Menu.O.Harass:Value() then return 2 end 
		return 0 
	end 

	local function GetDistanceSqr(p1, p2)
	    local dx, dz = p1.x - p2.x, p1.z - p2.z 
	    return dx * dx + dz * dz
	end

	local function GetDistance(p1, p2)
		return sqrt(GetDistanceSqr(p1, p2))
	end

	local function GetDistance2D(p1,p2)
		return sqrt((p2.x - p1.x)*(p2.x - p1.x) + (p2.y - p1.y)*(p2.y - p1.y))
	end

	local function VectorPointProjectionOnLineSegment(v1, v2, v)
		local cx, cy, ax, ay, bx, by = v.x, v.z, v1.x, v1.z, v2.x, v2.z
	    local rL = ((cx - ax) * (bx - ax) + (cy - ay) * (by - ay)) / ((bx - ax) * (bx - ax) + (by - ay) * (by - ay))
	    local pointLine = { x = ax + rL * (bx - ax), z = ay + rL * (by - ay) }
	    local rS = rL < 0 and 0 or (rL > 1 and 1 or rL)
	    local isOnSegment = rS == rL
	    local pointSegment = isOnSegment and pointLine or {x = ax + rS * (bx - ax), z = ay + rS * (by - ay)}
		return pointSegment, pointLine, isOnSegment
	end	

	local function Ready(spell)
		return myHero:GetSpellData(spell).currentCd == 0 and myHero:GetSpellData(spell).level > 0 and myHero:GetSpellData(spell).mana <= myHero.mana
	end

	local _EnemyHeroes
	local function GetEnemyHeroes()
		if _EnemyHeroes then return _EnemyHeroes end
		_EnemyHeroes = {}
		for i = 1, Game.HeroCount() do
			local unit = Game.Hero(i)
			if unit.team == TEAM_ENEMY then
				insert(_EnemyHeroes, unit)
			end
		end
		return _EnemyHeroes
	end 

	local function IsFacing(unit)
	    local V = Vector((unit.pos - myHero.pos))
	    local D = Vector(unit.dir)
	    local Angle = 180 - deg(acos(V*D/(V:Len()*D:Len())))
	    if abs(Angle) < 80 then 
	        return true  
	    end
	    return false
	end

	local function HasBuff(unit, buffname,D,s)
		local D = D or 1 
		local s = s or 1 
		for i = 1, unit.buffCount do 
		local Buff = unit:GetBuff(i)
			if Buff.name == buffname and Buff.count > 0 and Game.Timer() + D/s < Buff.expireTime then
				return true
			end
		end
		return false
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

	local function IsValidTarget(unit, range)
    	return unit and unit.team == TEAM_ENEMY and unit.dead == false and GetDistanceSqr(myHero.pos, unit.pos) <= (range + myHero.boundingRadius + unit.boundingRadius)^2 and unit.isTargetable and unit.isTargetableToTeam and unit.isImmortal == false and unit.visible
	end

	local function IsValidCreep(unit, range)
    	return unit and unit.team ~= TEAM_ALLY and unit.dead == false and GetDistanceSqr(myHero.pos, unit.pos) <= (range + myHero.boundingRadius + unit.boundingRadius)^2 and unit.isTargetable and unit.isTargetableToTeam and unit.isImmortal == false and unit.visible
	end

	local function IsImmobileTarget(unit)
		if unit == nil then return false end
		for i = 0, unit.buffCount do
			local buff = unit:GetBuff(i)
			if buff and (buff.type == 5 or buff.type == 11 or buff.type == 29 or buff.type == 24 or buff.name == "recall") and buff.count > 0 and Game.Timer() < buff.expireTime - 0.5 then
				return true
			end
		end
		return false	
	end

	local function GetHeroesInRange(r,h)
		local Heroes = {}
		for i = 1, Game.HeroCount() do 
			local Hero = Game.Hero(i)
			local bR = Hero.boundingRadius
			if Hero.team == TEAM_ENEMY and Hero.dead == false and Hero.isTargetable and GetDistanceSqr(Hero.pos, h) - bR * bR < r then 
				Heroes[#Heroes + 1] = Hero 
			end
		end
		return Heroes
	end

	local function GetMinionsInRange(r,h)
		local Minions = {}
		for i = 1, Game.MinionCount() do 
			local Minion = Game.Minion(i)
			local bR = Minion.boundingRadius
			if Minion.team ~= TEAM_ALLY and Minion.dead == false and Minion.isTargetable and GetDistanceSqr(Minion.pos, h) - bR * bR < r then 
				Minions[#Minions + 1] = Minion 
			end
		end
		return Minions
	end

	local function HCollision(hpos,cpos,width)
		local Count = 0
		for i = 1, Game.HeroCount() do
			local m = Game.Hero(i)
			if m and m.team == TEAM_ENEMY and m.dead == false and m.isTargetable then
				local pointSegment, pointLine, isOnSegment = VectorPointProjectionOnLineSegment(hpos, cpos, m.pos)
				local bR = m.boundingRadius
				local w = width + bR
				local pos = m.pos
				if isOnSegment and GetDistanceSqr(pointSegment, pos) < w * w and GetDistanceSqr(hpos, pos) - bR * bR <= GetDistanceSqr(hpos, cpos) then
					Count = Count + 1
				end
			end
		end
		return Count
	end	

	--Noddy
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

	local function Priority(charName)
	  local p1 = {"Alistar", "Amumu", "Blitzcrank", "Braum", "Cho'Gath", "Dr. Mundo", "Garen", "Gnar", "Maokai", "Hecarim", "Jarvan IV", "Leona", "Lulu", "Malphite", "Nasus", "Nautilus", "Nunu", "Olaf", "Rammus", "Renekton", "Sejuani", "Shen", "Shyvana", "Singed", "Sion", "Skarner", "Taric", "TahmKench", "Thresh", "Volibear", "Warwick", "MonkeyKing", "Yorick", "Zac", "Poppy"}
	  local p2 = {"Aatrox", "Darius", "Elise", "Evelynn", "Galio", "Gragas", "Irelia", "Jax", "Lee Sin", "Morgana", "Janna", "Nocturne", "Pantheon", "Rengar", "Rumble", "Swain", "Trundle", "Tryndamere", "Udyr", "Urgot", "Vi", "XinZhao", "RekSai", "Bard", "Nami", "Sona", "Camille", "Rakan", "Kayn"}
	  local p3 = {"Akali", "Diana", "Ekko", "FiddleSticks", "Fiora", "Gangplank", "Fizz", "Heimerdinger", "Jayce", "Kassadin", "Kayle", "Kha'Zix", "Lissandra", "Mordekaiser", "Nidalee", "Riven", "Shaco", "Vladimir", "Yasuo", "Zilean", "Zyra", "Ryze"}
	  local p4 = {"Ahri", "Anivia", "Annie", "Ashe", "Azir", "Brand", "Caitlyn", "Cassiopeia", "Corki", "Draven", "Ezreal", "Graves", "Jinx", "Kalista", "Karma", "Karthus", "Katarina", "Kennen", "KogMaw", "Kindred", "Leblanc", "Lucian", "Lux", "Malzahar", "MasterYi", "MissFortune", "Orianna", "Quinn", "Sivir", "Syndra", "Talon", "Teemo", "Tristana", "TwistedFate", "Twitch", "Varus", "Vayne", "Veigar", "Velkoz", "Viktor", "Xerath", "Zed", "Ziggs", "Jhin", "Soraka", "Xayah"}
	  if table.contains(p1, charName) then return 1 end
	  if table.contains(p2, charName) then return 1.25 end
	  if table.contains(p3, charName) then return 1.75 end
	  return table.contains(p4, charName) and 2.25 or 1
	end
	
	local function GetTarget(range,t,pos)
	local t = t or "AD"
	local pos = pos or myHero.pos
	local target = {}
		for i = 1, Game.HeroCount() do
			local hero = Game.Hero(i)
			if hero.team == TEAM_ENEMY and hero.dead == false then
				OnVision(hero)
			end
			if hero.team == TEAM_ENEMY and hero.valid and hero.dead == false and (OnVision(hero).state == true or (OnVision(hero).state == false and GetTickCount() - OnVision(hero).tick < 650)) and hero.isTargetable then
				local heroPos = hero.pos
				if OnVision(hero).state == false then heroPos = hero.pos + Vector(hero.pos,hero.posTo):Normalized() * ((GetTickCount() - OnVision(hero).tick)/1000 * hero.ms) end
				if GetDistance(pos,heroPos) <= range then
					if t == "AD" then
						target[(CalcPhysicalDamage(myHero,hero,100) / hero.health)*Priority(hero.charName)] = hero
					elseif t == "AP" then
						target[(CalcMagicalDamage(myHero,hero,100) / hero.health)*Priority(hero.charName)] = hero
					elseif t == "HYB" then
						target[((CalcMagicalDamage(myHero,hero,50) + CalcPhysicalDamage(myHero,hero,50))/ hero.health)*Priority(hero.charName)] = hero
					end
				end
			end
		end
		local bT = 0
		for d,v in pairs(target) do
			if d > bT then
				bT = d
			end
		end
		if bT ~= 0 then return target[bT] end
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

	local function GetPred(unit,speed,delay) 
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
	--

	local function ExcludeFurthest(average,lst,sTar)
		local removeID = 1 
		for i = 2, #lst do 
			if GetDistanceSqr(average, lst[i].pos) > GetDistanceSqr(average, lst[removeID].pos) then 
				removeID = i 
			end 
		end 

		local Newlst = {}
		for i = 1, #lst do 
			if (sTar and lst[i].networkID == sTar.networkID) or i ~= removeID then 
				Newlst[#Newlst + 1] = lst[i]
			end
		end
		return Newlst 
	end

	local function GetBestCircularCastPos(r,lst,s,d,sTar)
		local average = {x = 0, y = 0, z = 0, count = 0}
		local point = nil 
		if #lst == 0 then 
			if sTar then return GetPred(sTar,s,d) end 
			return 
		end

		for i = 1, #lst do 
			local org = GetPred(lst[i],s,d)
			average.x = average.x + org.x 
			average.y = average.y + org.y 
			average.z = average.z + org.z 
			average.count = average.count + 1
		end 
 
		if sTar and sTar.type ~= lst[1].type then 
			local org = GetPred(sTar,s,d)
			average.x = average.x + org.x 
			average.y = average.y + org.y 
			average.z = average.z + org.z 
			average.count = average.count + 1
		end

		average.x = average.x/average.count 
		average.y = average.y/average.count 
		average.z = average.z/average.count 

		local InRange = 0 
		for i = 1, #lst do 
			local bR = lst[i].boundingRadius
			if GetDistanceSqr(average, lst[i].pos) - bR * bR < r then 
				InRange = InRange + 1 
			end
		end

		local point = Vector(average.x, average.y, average.z)	

		if InRange == #lst then 
			return point, InRange
		else 
			return GetBestCircularCastPos(r, ExcludeFurthest(average, lst),s,d,sTar)
		end
	end		

	---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	

	class "DarkStarOrianna"

	function DarkStarOrianna:__init()
		self.Icons = {
			Q = "https://raw.githubusercontent.com/HiImWeedle/GoS/master/Icons/OriannaQ.png",
			W = "https://raw.githubusercontent.com/HiImWeedle/GoS/master/Icons/OriannaW.png",
			E = "https://raw.githubusercontent.com/HiImWeedle/GoS/master/Icons/OriannaE.png",
			R = "https://raw.githubusercontent.com/HiImWeedle/GoS/master/Icons/OriannaR.png"}
		self.range = 1265625
		self.Q = {speed = 1200, speed2 = 1440000, delay = 0.25, range = 825, range2 = 680625, mrange = 960, mrange2 = 1102500, width = 140}
		self.W = {speed = huge, speed2 = huge, delay = 0.25, width = 230, width2 = 52900}
		self.E = {speed = 1800, speed2 = 3240000, delay = 0.25, range = 1100, width = 140, width2 = 19600}
		self.R = {speed = huge, delay = 1, width = 360 ,dwidth = 380, width2 = 122500}
		self:Menu()
		Callback.Add("Tick", function() self:Tick() end)
		Callback.Add("Draw", function() self:Draw() end)
		print("Weedle | Dark Star Orianna v"..Sversion.." | Loaded")
	end		

	function DarkStarOrianna:Menu()
		Menu.C:MenuElement({id = "Q", name = "Use Q", value = true, leftIcon = self.Icons.Q})
		Menu.C:MenuElement({id = "W", name = "Use W", value = true, leftIcon = self.Icons.W})
		Menu.C:MenuElement({id = "E", name = "Use E", value = true, leftIcon = self.Icons.E})
		Menu.C:MenuElement({id = "R", name = "Use R", value = true, leftIcon = self.Icons.R})
		Menu.C:MenuElement({id = "Count", name = "Min Count to R", value = 3, min = 1, max = 5, step = 1})
		Menu.C:MenuElement({id = "F", name = "Force R Toggle Key [?]", key = 84, toggle = true, tooltip = "Overwrites the Min Count"})	

		Menu.H:MenuElement({id = "Q", name = "Use Q", value = true, leftIcon = self.Icons.Q})
		Menu.H:MenuElement({id = "W", name = "Use W", value = true, leftIcon = self.Icons.W})
		Menu.H:MenuElement({id = "E", name = "Use E", value = true, leftIcon = self.Icons.E})

		Menu.A:MenuElement({id = "ON", name = "Aimbot Toggle key", key = 77, toggle = true})
		Menu.A:MenuElement({id = "Q", name = "Q key", key = string.byte("Q")})		

		Menu.M:MenuElement({name = " ", drop = {"Combo [%]"}})
		Menu.M:MenuElement({id = "Q", name = "Q", value = 10, min = 0, max = 100, step = 1})
		Menu.M:MenuElement({id = "W", name = "W", value = 10, min = 0, max = 100, step = 1})
		Menu.M:MenuElement({id = "E", name = "E", value = 10, min = 0, max = 100, step = 1})
		Menu.M:MenuElement({id = "R", name = "R", value = 10, min = 0, max = 100, step = 1})
		Menu.M:MenuElement({name = " ", drop = {"Harass [%]"}})
		Menu.M:MenuElement({id = "HQ", name = "Q", value = 10, min = 0, max = 100, step = 1})
		Menu.M:MenuElement({id = "HW", name = "W", value = 10, min = 0, max = 100, step = 1})
		Menu.M:MenuElement({id = "HE", name = "E", value = 10, min = 0, max = 100, step = 1})	

		Menu.D:MenuElement({id = "ON", name = "Enable Drawings", value = true})
		Menu.D:MenuElement({id = "T", name = "Enable Text", value = true})
		Menu.D:MenuElement({id = "Q", name = "Q", type = MENU})
		Menu.D.Q:MenuElement({id = "ON", name = "Enabled", value = true, leftIcon = self.Icons.Q})       
		Menu.D.Q:MenuElement({id = "Width", name = "Width", value = 5, min = 1, max = 5, step = 1})
		Menu.D.Q:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
		Menu.D:MenuElement({id = "W", name = "W", type = MENU})
		Menu.D.W:MenuElement({id = "ON", name = "Enabled", value = false, leftIcon = self.Icons.W})       
		Menu.D.W:MenuElement({id = "Width", name = "Width", value = 5, min = 1, max = 5, step = 1})
		Menu.D.W:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
		Menu.D:MenuElement({id = "E", name = "E", type = MENU})
		Menu.D.E:MenuElement({id = "ON", name = "Enabled", value = true, leftIcon = self.Icons.E})       
		Menu.D.E:MenuElement({id = "Width", name = "Width", value = 5, min = 1, max = 5, step = 1})
		Menu.D.E:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
		Menu.D:MenuElement({id = "R", name = "R", type = MENU})
		Menu.D.R:MenuElement({id = "ON", name = "Enabled", value = true, leftIcon = self.Icons.R})       
		Menu.D.R:MenuElement({id = "Width", name = "Width", value = 2, min = 1, max = 5, step = 1})
		Menu.D.R:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
	end


	function DarkStarOrianna:Tick()		
		if myHero.dead == false and Game.IsChatOpen() == false then	
			local h = myHero.pos
			local t = Game.Timer()
			self:Ball(h,t)
			local Mode = GetMode()
			if Mode == 1 then 
				self:Combo(h,t)
			elseif Mode == 2 then 
				self:Harass(h,t)
			end
			self:Aimbot(h)
		end
	end

	local Bpos = myHero.pos
	local WCast, Wtime, Wpos = false, 0 ,Bpos 
	function DarkStarOrianna:Ball(h,t) 
		if t > Wtime and WCast then 
			Bpos = Wpos
			WCast = false 
		end
		for i = 1, Game.ParticleCount() do 
			local p = Game.Particle(i)
			if p.name == "Orianna_Base_Q_yomu_ring_green.troy" then 
				Bpos = p.pos 
				break
			end
		end	
		if HasBuff(myHero, "orianaghostself") then 
			Bpos = h
		else
			for i = 1, Game.HeroCount() do
				local Hero = Game.Hero(i)
				if HasBuff(Hero, "orianaghost") then 
					Bpos = Hero.pos 
					break
				end
			end
		end
	end	

	function DarkStarOrianna:Combo(h,t)
		local target = GetTarget(1325)
		if target == nil then 
			return 
		end	
		local MP = myHero.mana/myHero.maxMana*100 
		local D = GetDistanceSqr(target.pos, h)	
    	local F = IsFacing(target)		
    	local bR = target.boundingRadius
       	local EC = Menu.C.E:Value() and Ready(_E) and MP > Menu.M.E:Value()
        local WC = Menu.C.W:Value() and Ready(_W) and MP > Menu.M.W:Value()
        local RC = Menu.C.R:Value() and Ready(_R) and MP > Menu.M.R:Value()
    	if Menu.C.W:Value() and Ready(_W) and MP > Menu.M.W:Value() then 
    		local Pos = GetPred(target, huge, self.W.delay + Game.Latency()/1000)
    		local Dist = GetDistanceSqr(Bpos, target.pos) - bR * bR 
    		if Dist < self.W.width2 then 
    			Control.CastSpell(HK_W)
    		end
    	end 
      	if RC and (Ready(_Q) == false or Menu.C.Q:Value() == false) then 
    		local Count = 0 
    		for i = 1, Game.HeroCount() do 
    			local H = Game.Hero(i)
    			if H.team == TEAM_ENEMY and H.dead == false and H.isTargetable then 
    				local Pos = GetPred(H, self.R.speed, self.R.delay + Game.Latency()/1000)
    				if GetDistanceSqr(Pos, Bpos) < self.R.width2 then 
    					Count = Count + 1 
    				end
    			end
    		end
    		if Count >= Menu.C.Count:Value() or (Menu.C.F:Value() and Count >= 1) then 
    			Control.CastSpell(HK_R)
    		end
    	end  	       
        if Menu.C.Q:Value() and Ready(_Q) and MP > Menu.M.Q:Value() then 
        	local Pos = GetPred(target, self.Q.speed, Game.Latency()/1000)
        	if Menu.C.W:Value() and myHero:GetSpellData(_W).currentCd <= 0.6 and MP > Menu.M.W:Value() then 
        		local list = GetHeroesInRange(self.Q.mrange2,h)
        		Pos = GetBestCircularCastPos(self.W.width2, list, self.Q.speed, Game.Latency()/1000,target)
        	end
            local Dist = GetDistanceSqr(Pos, h) - bR * bR	
            local Dis = GetDistanceSqr(Bpos, target.pos)
        	if EC then 
    			local Ehero = myHero 
    			local Closest = GetDistanceSqr(h, Pos)
    			for i = 1, Game.HeroCount() do 
    				local Hero = Game.Hero(i) 
    				if Hero.team == TEAM_ALLY and Hero.dead == false and Hero.isTargetable then 
    					local Dis = GetDistanceSqr(Hero.pos, Pos)
    					if Dis < Closest then 
    						Ehero = Hero 
    						Closest = Dis
    					end
    				end
    			end
    			if GetDistanceSqr(Bpos, Ehero.pos)/self.E.speed2 + GetDistanceSqr(Ehero.pos, Pos)/self.Q.speed2 < GetDistanceSqr(Bpos, Pos)/self.Q.speed2 and (HasBuff(Ehero, "orianaghostself") == false and HasBuff(Ehero, "orianaghost") == false) and Dist < self.Q.range2 then
    				Control.CastSpell(HK_E, Ehero)
    			else 
    				Pos = h + (Pos - h):Normalized()*(GetDistance(Pos, h) + 0.5*bR)
    				if Dist > self.Q.range2 then 
    					Pos = h + (Pos - h):Normalized()*self.Q.range
    				end
    				if F and Dist < self.Q.mrange2 then 
    					Wtime = t + Dis/self.Q.speed2	
    				    WCast = true
    					Wpos = Pos  
    					Control.CastSpell(HK_Q, Pos)
    				elseif Dist < 0.97*self.Q.mrange2 then 
    					Wtime = t + Dis/self.Q.speed2	
    				    WCast = true
    					Wpos = Pos  
    					Control.CastSpell(HK_Q, Pos)
    				end
    			end
    		else
    		    if Dist > self.Q.range2 then 
    				Pos = h + (Pos - h):Normalized()*self.Q.range
    			end 
     			if F and Dist < self.Q.mrange2 then 
     				Wtime = t + Dis/self.Q.speed2	
    				WCast = true
    				Wpos = Pos  
    				Control.CastSpell(HK_Q, Pos)
    			elseif Dist < 0.97*self.Q.mrange2 then 
    				Wtime = t + Dis/self.Q.speed2	
    				WCast = true
    				Wpos = Pos  
    				Control.CastSpell(HK_Q, Pos)
    			end
    		end
    	end
    	if EC and Ready(_Q) == false and myHero.activeSpell.name ~= "OrianaDetonateCommand" then 
    		local EColl = HCollision(h, Bpos, self.E.width)
    		if EColl >= 1 then 
    			Control.CastSpell(HK_E, myHero)
    		end
    	end
    end

	function DarkStarOrianna:Harass(h,t)
		local target = GetTarget(1325)
		if target == nil then 
			return 
		end	
		local MP = myHero.mana/myHero.maxMana*100 
		local D = GetDistanceSqr(target.pos, h)
    	local F = IsFacing(target)		
    	local bR = target.boundingRadius
    	local EC = Menu.H.E:Value() and Ready(_E) and MP > Menu.M.HE:Value() 
    	if Menu.H.Q:Value() and Ready(_Q) and MP > Menu.M.HQ:Value() then
    		local Pos = GetPred(target, self.Q.speed, Game.Latency()/1000) 
    		local Dist = GetDistanceSqr(Pos, h) - bR * bR
    		local Dis = GetDistanceSqr(Bpos, target.pos)
    		if EC then 
    			local Ehero = myHero 
    			local Closest = GetDistanceSqr(h, Pos)
    			for i = 1, Game.HeroCount() do 
    				local Hero = Game.Hero(i) 
    				if Hero.team == TEAM_ALLY and Hero.dead == false and Hero.isTargetable then 
    					local Dis = GetDistanceSqr(Hero.pos, Pos)
    					if Dis < Closest then 
    						Ehero = Hero 
    						Closest = Dis
    					end
    				end
    			end
    			if GetDistanceSqr(Bpos, Ehero.pos)/self.E.speed2 + GetDistanceSqr(Ehero.pos, Pos)/self.Q.speed2 < GetDistanceSqr(Bpos, Pos)/self.Q.speed2 and HasBuff(Ehero, "orianaghostself") == false and Dist < self.Q.range2 then
    				Control.CastSpell(HK_E, Ehero)
    			else 
    				Pos = h + (Pos - h):Normalized()*(GetDistance(Pos, h) + 0.5*bR)
					if Dist > self.Q.range2 then 
    					Pos = h + (Pos - h):Normalized()*self.Q.range
    				end   				
    				if F and Dist < self.Q.mrange2 then 
    					Wtime = t + Dis/self.Q.speed2	
    				    WCast = true
    					Wpos = Pos  
    					Control.CastSpell(HK_Q, Pos)
    				elseif Dist < 0.97*self.Q.mrange2 then 
    					Wtime = t + Dis/self.Q.speed2	
    				    WCast = true
    					Wpos = Pos  
    					Control.CastSpell(HK_Q, Pos)
    				end
    			end
    		else 
    			if Dist > self.Q.range2 then 
    				Pos = h + (Pos - h):Normalized()*self.Q.range
    			end 
    			if F and Dist < self.Q.mrange2 then 
    				Wtime = t + Dis/self.Q.speed2	
    				WCast = true
    				Wpos = Pos  
    				Control.CastSpell(HK_Q, Pos)
    			elseif Dist < 0.97*self.Q.mrange2 then 
    				Wtime = t + Dis/self.Q.speed2	
    				WCast = true
    				Wpos = Pos  
    				Control.CastSpell(HK_Q, Pos)
    			end
    		end
    	end
    	if Menu.H.W:Value() and Ready(_W) and MP > Menu.M.HW:Value() then 
    		local Pos = GetPred(target, huge, self.W.delay + Game.Latency()/1000)
    		local Dist = GetDistanceSqr(Bpos, Pos) - bR * bR 
    		if Dist < self.W.width2 then 
    			Control.CastSpell(HK_W)
    		end
    	end
    	if EC and Ready(_Q) == false then 
    		local EColl = HCollision(h, Bpos, self.E.width)
    		if EColl >= 1 then 
    			Control.CastSpell(HK_E, myHero)
    		end
    	end
    end

    function DarkStarOrianna:Aimbot(h)
    	if Menu.A.Q:Value() and Ready(_Q) then 
    	local target = GetTarget(1325)
    	local Pos = mousePos 	
    		if target and Menu.A.ON:Value() then 
    			Pos = GetPred(target, self.Q.speed, self.Q.delay + Game.Latency()/1000)
    		end
    		if GetDistanceSqr(Pos,h) > self.Q.range2 then 
    			Pos = h + (Pos - h):Normalized()*self.Q.range
    		end
    		Control.CastSpell(HK_Q, Pos)
    	end
    end

    function DarkStarOrianna:Draw()
    	if myHero.dead == false and Menu.D.ON:Value() then
			local h = myHero.pos
		    if Menu.D.T:Value() then
    		  	local tpos = h:To2D()
    		  	if Menu.C.F:Value() then 
    		  		Draw.Text("Force R ON", 20, tpos.x - 80, tpos.y + 40, Draw.Color(255, 000, 255, 000))
    		  	end
    			if Menu.A.ON:Value() then 
    				Draw.Text("Aimbot ON", 20, tpos.x - 80, tpos.y + 60, Draw.Color(255, 000, 255, 100))
    			end	
    		end
			if Menu.D.Q.ON:Value() then 
    			Draw.Circle(h, self.Q.range, Menu.D.Q.Width:Value(), Menu.D.Q.Color:Value())
    		end
    		if Menu.D.W.ON:Value() then 
    			Draw.Circle(Bpos, self.W.width, Menu.D.W.Width:Value(), Menu.D.W.Color:Value())
    		end
    		if Menu.D.E.ON:Value() then 
    			Draw.Circle(h, self.E.range, Menu.D.E.Width:Value(), Menu.D.E.Color:Value())
    		end
    		if Menu.D.R.ON:Value() then 
    			Draw.Circle(Bpos, self.R.dwidth, Menu.D.R.Width:Value(), Menu.D.R.Color:Value())
    		end
    	end
    end
 
  	function OnLoad() DarkStarOrianna() end  	
