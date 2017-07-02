	--[[
	___________.__                                __         .__  .__          __    .____                  
	\_   _____/|  |   ____   _____   ____   _____/  |______  |  | |__| _______/  |_  |    |    __ _____  ___
	 |    __)_ |  | _/ __ \ /     \_/ __ \ /    \   __\__  \ |  | |  |/  ___/\   __\ |    |   |  |  \  \/  /
	 |        \|  |_\  ___/|  Y Y  \  ___/|   |  \  |  / __ \|  |_|  |\___ \  |  |   |    |___|  |  />    < 
	/_______  /|____/\___  >__|_|  /\___  >___|  /__| (____  /____/__/____  > |__|   |_______ \____//__/\_ \
	        \/           \/      \/     \/     \/          \/             \/                 \/           \/
	--]]


	if myHero.charName ~= "Lux" then return end

	math.randomseed(os.clock()*100000000) 
	local Sversion, Lversion, N = 1.00, 7.13, math.random(1,10)
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

	local Menu = MenuElement({id = "ElementalistLux", name = "Weedle | Elementalist Lux", type = MENU, leftIcon = "https://raw.githubusercontent.com/HiImWeedle/GoS/master/Icons/LuxIcon"..N..".png"})
		Menu:MenuElement({name = " ", drop = {"General Settings"}})
		Menu:MenuElement({id = "C", name = "Combo", type = MENU})		
		Menu:MenuElement({id = "H", name = "Harass", type = MENU})
		Menu:MenuElement({id = "W", name = "Clear", type = MENU})
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
		if Menu.O.Clear:Value() then return 3 end 
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
		for K, Buff in pairs(GetBuffs(unit)) do
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

	local function MCollision(hpos,cpos,width)
		local Count = 0
		for i = 1, Game.MinionCount() do
			local m = Game.Minion(i)
			if m and m.team ~= TEAM_ALLY and m.dead == false and m.isTargetable then
				local pointSegment, pointLine, isOnSegment = VectorPointProjectionOnLineSegment(hpos, cpos, m.pos)
				local w = width + m.boundingRadius
				local pos = m.pos
				if isOnSegment and GetDistanceSqr(pointSegment, pos) < w * w and GetDistanceSqr(hpos, cpos) > GetDistanceSqr(hpos, pos) then
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
			if sTar then return GetPred(sTar,s,d), 0 end 
			return 
		end

		for i = 1, #lst do 
			local org = GetPred(lst[i],s,d)
			average.x = average.x + org.x 
			average.y = average.y + org.y 
			average.z = average.z + org.z 
			average.count = average.count + 1
		end 

		if sTar then 
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
			if GetDistanceSqr(average, lst[i].pos) < r then 
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

	class "ElementalistLux"

	function ElementalistLux:__init()
		self.Icons = {
				Q = "https://raw.githubusercontent.com/HiImWeedle/GoS/master/Icons/LuxQ.png",
				W = "https://raw.githubusercontent.com/HiImWeedle/GoS/master/Icons/LuxW.png",
				E = "https://raw.githubusercontent.com/HiImWeedle/GoS/master/Icons/LuxE.png",
				R = "https://raw.githubusercontent.com/HiImWeedle/GoS/master/Icons/LuxR.png"}
		self.range = 360000
		self.Q = {speed = 1200, speed2 = 1440000, delay = 0.25, range = 1175, range2 = 1380625, width = 80}
		self.W = {speed = 1200, speed2 = 1440000, delay = 0.25, range = 1075, range2 = 1155625, width = 150}
		self.E = {speed = 1300, speed2 = 1690000, delay = 0.25, range = 1100, mrange = 1450, range2 = 1210000, mrange2 = 2102500,width = 350, width2 = 122500}
		self.R = {speed = huge, delay = 1, range = 3340, range2 = 11155600}
		self:Menu()
		Callback.Add("Tick", function() self:Tick() end)
		Callback.Add("Draw", function() self:Draw() end)
		print("Weedle | Elementalist Lux v"..Sversion.." | Loaded")
	end	

	function ElementalistLux:Menu()
		Menu.C:MenuElement({id = "Q", name = "Use Q", value = true, leftIcon = self.Icons.Q})
		Menu.C:MenuElement({id = "W", name = "Use W", value = true, leftIcon = self.Icons.W})
		Menu.C:MenuElement({id = "E", name = "Use E", value = true, leftIcon = self.Icons.E})
		Menu.C:MenuElement({id = "R", name = "Use R", value = true, leftIcon = self.Icons.R})
		Menu.C:MenuElement({id = "Min", name = "Min Distance to R", value = 800, min = 0, max = 1500, step = 100})
		Menu.C:MenuElement({id = "T", name = "Burst Mode Toggle", key = 84, value = false, toggle = true})

		Menu.H:MenuElement({id = "Q", name = "Use Q", value = true, leftIcon = self.Icons.Q})
		Menu.H:MenuElement({id = "W", name = "Use W", value = true, leftIcon = self.Icons.W})
		Menu.H:MenuElement({id = "E", name = "Use E", value = true, leftIcon = self.Icons.E})

		Menu.W:MenuElement({id = "E", name = "Use E", value = true, leftIcon = self.Icons.E})
		Menu.W:MenuElement({id = "Min", name = "Min amount to E", value = 4, min = 1, max = 7, step = 1})

		Menu.A:MenuElement({id = "ON", name = "Aimbot Toggle key", key = 77, toggle = true})
		Menu.A:MenuElement({id = "AE", name = "Auto E2", value = false})
		Menu.A:MenuElement({id = "Q", name = "Q key", key = 49})
		Menu.A:MenuElement({id = "W", name = "W key", key = 50})
		Menu.A:MenuElement({id = "E", name = "E key", key = 51})
		Menu.A:MenuElement({id = "R", name = "R key", key = 52})

		Menu.M:MenuElement({name = " ", drop = {"Combo, Harass [%]"}})
		Menu.M:MenuElement({id = "Q", name = "Q", value = 10, min = 0, max = 100, step = 1})
		Menu.M:MenuElement({id = "W", name = "W", value = 10, min = 0, max = 100, step = 1})
		Menu.M:MenuElement({id = "E", name = "E", value = 10, min = 0, max = 100, step = 1})
		Menu.M:MenuElement({id = "R", name = "R", value = 10, min = 0, max = 100, step = 1})
		Menu.M:MenuElement({name = " ", drop = {"Clear [%]"}})	
		Menu.M:MenuElement({id = "EC", name = "W", value = 10, min = 0, max = 100, step = 1})

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

   	function ElementalistLux:Rdmg(u)
		return CalcMagicalDamage(myHero, u, 200 + 100*myHero:GetSpellData(_R).level + 0.75*myHero.ap)
	end

	local ECast, Etime = false, 0 
	function ElementalistLux:Tick() 
		if myHero.dead == false and Game.IsChatOpen() == false then
			local t = Game.Timer() 
			local n = myHero:GetSpellData(_E).name 
			if t > Etime and ECast then 
   				Control.CastSpell(HK_E)
   				if Ready(_E) == false then 
   					ECast = false
   				end
   			end
   			local Mode = GetMode()
   			if Mode == 1 then 
   				self:Combo(t,n)
   			elseif Mode == 2 then 
   				self:Harass(t,n)
   			elseif Mode == 3 then 
   				self:Clear(t,n)
   			end
   			self:Aimbot(t,n)
   		end
   	end

	function ElementalistLux:GetWHero(h)
		local Lowest = nil 
		for i = 1, Game.HeroCount() do 
			local Hero = Game.Hero(i) 
			if Hero ~= myHero and Hero.team == TEAM_ALLY and GetDistanceSqr(h, Hero.pos) < self.W.range2 then 
			local hp = Hero.health
				if Lowest then 
					if hp < Lowest.health then 
						Lowest = Hero 
					end
				else 
					Lowest = Hero 
				end
			end
		end
		return Lowest
	end

	function ElementalistLux:Shield(h)
		if myHero.health/myHero.maxHealth < 0.75 then 
			local Pos = nil
			local target = nil
			local close = false
			for i = 1, Game.HeroCount() do 
				local Hero = Game.Hero(i)
				if Hero.team == TEAM_ENEMY and GetDistanceSqr(Hero.pos,h) < self.W.range2 then
					close = true 
					Pos = Hero.activeSpell.placementPos 
					break
				end
			end
			if (Pos and (GetDistanceSqr(Pos, h) < 22500)) or (close and Pos == nil) then 
				local Ally = self:GetWHero(h)
				if Ally then 
					local WPos = GetPred(Ally, self.W.speed, self.W.delay + Game.Latency()/1000) 
					Control.CastSpell(HK_W, WPos) 
				else
					Control.CastSpell(HK_W) 
				end
			end
		end
	end	

	function ElementalistLux:Combo(t,n)
		local h = myHero.pos	
		local target = GetTarget(1300) 
    	if target == nil then 
    		return 
    	end
     	local spell = myHero.activeSpell
		if spell.valid and spell.spellWasCast == false then
   			return
   		end		   	
    	local MP = myHero.mana/myHero.maxMana*100
    	local D = GetDistanceSqr(target.pos, h)
        local F = IsFacing(target)		
    	local bR = target.boundingRadius	
    	local QC = Menu.C.Q:Value() and MP > Menu.M.Q:Value()
    	local EC = Menu.C.E:Value() and MP > Menu.M.E:Value() 
    	if QC and Ready(_Q) then 
    		local Pos = GetPred(target, self.Q.speed, self.Q.delay + Game.Latency()/1000)
    		local Dist = GetDistanceSqr(Pos, h) - bR * bR 
    		local QColl = MCollision(h, Pos, self.Q.width)
    		if QColl <= 1 then 
    			if F and Dist < self.Q.range2 then 
    				Control.CastSpell(HK_Q, Pos)
    			elseif Dist < 0.97*self.Q.range2 then 
    				Control.CastSpell(HK_Q, Pos)
    			end
    		end
    	end
    	if EC and Ready(_E) and n == "LuxLightStrikeKugel" and myHero.activeSpell.name ~= "LuxLightStrikeKugel" and (Ready(_Q) == false or QC == false or MCollision(h, target.pos, self.Q.width) >= 2 or (D > self.Q.range2 and F == false)) then 
    		local list = GetHeroesInRange(self.E.range2,h)
    		local Pos = GetBestCircularCastPos(self.E.width2,list,self.E.speed,self.E.delay,target)
    		local Dist = GetDistanceSqr(Pos, h) - bR * bR
    		if F and Dist < self.E.mrange2 then
    			if Dist > self.E.range2 then 
    				Pos = h + (Pos - h):Normalized()*self.E.range
    			end
    			Etime = t + self.E.delay + D/self.E.speed2 
    			Control.CastSpell(HK_E, Pos)
    			ECast = true
    		elseif Dist < 0.95*self.E.mrange2 then 
    			if Dist > self.E.range2 then 
    				Pos = h + (Pos - h):Normalized()*self.E.range
    			end
    			Etime = t + self.E.delay + D/self.E.speed2 
    			Control.CastSpell(HK_E, Pos)
    			ECast = true
    		end
    	end
    	if Menu.C.R:Value() and Ready(_R) and MP > Menu.M.R:Value() then 
    		local Rtarget = GetTarget(self.R.range)
    		local Im = IsImmobileTarget(Rtarget)
    		if (Menu.C.T:Value() and Im and ECast) or (self:Rdmg(Rtarget) > Rtarget.health and (Ready(_E) == false or EC == false) and (Ready(_Q) == false or QC == false)) and GetDistance(Rtarget.pos, h) > Menu.C.Min:Value() then 
    			local Pos = GetPred(Rtarget, self.Q.speed, self.Q.delay + Game.Latency()/1000)
    			if Im then Pos = Rtarget.pos end 
    			if Pos:To2D().onScreen then 
    				Control.CastSpell(HK_R, Pos)
    			else
    				Control.CastSpell(HK_R, Pos:ToMM())
    			end
    		end
    	end
    	if Menu.C.W:Value() and Ready(_W) and MP > Menu.M.W:Value() then 
    		self:Shield(h)
    	end
    end

    function ElementalistLux:Harass(t,n)
    	local h = myHero.pos	
		local target = GetTarget(1300) 
    	if target == nil then 
    		return 
    	end
     	local spell = myHero.activeSpell
		if spell.valid and spell.spellWasCast == false then
   			return
   		end		   	
    	local MP = myHero.mana/myHero.maxMana*100
    	local D = GetDistanceSqr(target.pos, h)
        local F = IsFacing(target)		
    	local bR = target.boundingRadius	
    	local QC = Menu.H.Q:Value() and MP > Menu.M.Q:Value()
    	local EC = Menu.H.E:Value() and MP > Menu.M.E:Value()
    	if QC and Ready(_Q) then 
    		local Pos = GetPred(target, self.Q.speed, self.Q.delay + Game.Latency()/1000)
    		local Dist = GetDistanceSqr(Pos, h) - bR * bR 
    		local QColl = MCollision(h, Pos, self.Q.width)
    		if QColl <= 1 then 
    			if F and Dist < self.Q.range2 then 
    				Control.CastSpell(HK_Q, Pos)
    			elseif Dist < 0.96*self.Q.range2 then 
    				Control.CastSpell(HK_Q, Pos)
    			end
    		end
    	end
    	if EC and Ready(_E) and n == "LuxLightStrikeKugel" and myHero.activeSpell.name ~= "LuxLightStrikeKugel" and (Ready(_Q) == false or QC == false or MCollision(h, target.pos, self.Q.width) >= 2 or (D > self.Q.range2 and F == false)) then 
    		local list = GetHeroesInRange(self.E.range2,h)
    		local Pos = GetBestCircularCastPos(self.E.width2,list,self.E.speed,self.E.delay,target)
    		local Dist = GetDistanceSqr(Pos, h) - bR * bR
    		if F and Dist < self.E.mrange2 then
    			if Dist > self.E.range2 then 
    				Pos = h + (Pos - h):Normalized()*self.E.range
    			end
    			Etime = t + self.E.delay + D/self.E.speed2 
    			Control.CastSpell(HK_E, Pos)
    			ECast = true
    		elseif Dist < 0.95*self.E.mrange2 then 
    			if Dist > self.E.range2 then 
    				Pos = h + (Pos - h):Normalized()*self.E.range
    			end
    			Etime = t + self.E.delay + D/self.E.speed2 
    			Control.CastSpell(HK_E, Pos)
    			ECast = true
    		end
    	end
        if Menu.C.W:Value() and Ready(_W) and MP > Menu.M.W:Value() then 
    		self:Shield(h)
    	end	
    end

    function ElementalistLux:Clear(t,n)
    	local h = myHero.pos
    	local sTar = nil 
      	local spell = myHero.activeSpell
		if spell.valid and spell.spellWasCast == false then
   			return
   		end		  	
    	if Menu.W.E:Value() and Ready(_E) and n == "LuxLightStrikeKugel" and myHero.activeSpell.name ~= "LuxLightStrikeKugel" and myHero.mana/myHero.maxMana*100 > Menu.M.EC:Value() then 
    		local target = GetTarget(1100)
    		if target then sTar = target end 
    		local list = GetMinionsInRange(self.E.range2, h)
    		local Pos, Count = GetBestCircularCastPos(self.E.width2,list,self.E.speed,self.E.delay,sTar)
    		if Pos and Pos:To2D().onScreen and Count >= Menu.W.Min:Value() then 
    			Etime = t + self.E.delay + GetDistanceSqr(Pos, h)/self.E.speed2
    			Control.CastSpell(HK_E, Pos)
    			ECast = true
    		end
    	end
    end

    function ElementalistLux:Aimbot(t,n)
    	local ON = Menu.A.ON:Value() 
    	if Menu.A.Q:Value() and Ready(_Q) then 
    		local target = GetTarget(1500)
    		local Pos = mousePos 	
    		if target and ON then 
    			Pos = GetPred(target, self.Q.speed,self.Q.delay + Game.Latency()/1000)
    		end
    		Control.CastSpell(HK_Q, Pos) 
    	end 
    	if Menu.A.W:Value() and Ready(_W) then 
    	    local h = myHero.pos 
    		local Ally = self:GetWHero(h)
    		if Ally and ON then 
    			Control.CastSpell(HK_W, Ally)
    		else 
    			Control.CastSpell(HK_W)
    		end
    	end
    	if Menu.A.E:Value() and Ready(_E) and (n == "LuxLightStrikeKugel" and myHero.activeSpell.name ~= "LuxLightStrikeKugel" or Menu.A.AE:Value() == false) then 
    		local h = myHero.pos 
    		local target = GetTarget(1500)
    		local Pos = mousePos 
    		if target and ON then 
    			local list = GetHeroesInRange(self.E.range2,h)
    			Pos = GetBestCircularCastPos(self.E.width2,list,self.E.speed,self.E.delay,target)
    		end
    		Control.CastSpell(HK_E, Pos)
    		if Menu.A.AE:Value() then 
    			Etime = t + self.E.delay + GetDistanceSqr(Pos, h)/self.E.speed2
    			ECast = true
    		end
    	end
    	if Menu.A.R:Value() and Ready(_R) then 
    		local Pos = mousePos 	
    		local Rtarget = GetTarget(self.R.range)
    		local Im = IsImmobileTarget(Rtarget)
    		if Im and ON then 
    			Pos = Rtarget.pos
    		elseif Rtarget then 
    			Pos = GetPred(Rtarget, self.R.speed, self.R.delay + Game.Latency()/1000)
    		end
    		Control.CastSpell(HK_R, Pos)
    	end
    end


 	function ElementalistLux:Draw()
    	if myHero.dead == false and Menu.D.ON:Value() then 
    	local h = myHero.pos
    		if Menu.D.T:Value() then
    		  	local tpos = h:To2D()	
				if Menu.C.T:Value() then 
    				Draw.Text("Burst Mode ON", 20, tpos.x - 80, tpos.y + 40, Draw.Color(255, 000, 255, 000))
    			else
    				Draw.Text("Burst Mode OFF", 20, tpos.x - 80, tpos.y + 40, Draw.Color(255, 255, 000, 000))
    			end
    			if Menu.A.ON:Value() then 
    				Draw.Text("Aimbot ON", 20, tpos.x - 80, tpos.y + 60, Draw.Color(255, 000, 255, 100))
    			end
    		end
        	if Menu.D.Q.ON:Value() then 
    			Draw.Circle(h, self.Q.range, Menu.D.Q.Width:Value(), Menu.D.Q.Color:Value())
    		end
    		if Menu.D.W.ON:Value() then 
    			Draw.Circle(h, self.W.range, Menu.D.W.Width:Value(), Menu.D.W.Color:Value())
    		end
    		if Menu.D.E.ON:Value() then 
    			Draw.Circle(h, self.E.range, Menu.D.E.Width:Value(), Menu.D.E.Color:Value())
    		end
    		if Menu.D.R.ON:Value() then 
    			Draw.CircleMinimap(h, self.R.range, Menu.D.R.Width:Value(), Menu.D.R.Color:Value())
    		end
    	end
    end

    function OnLoad() ElementalistLux() end
