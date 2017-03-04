local KoreanChamps = {"Diana"}
if not table.contains(KoreanChamps, myHero.charName) then return end

local KoreanDiana = MenuElement({type = MENU, id = "KoreanDiana", name = "Korean Diana", leftIcon = "http://static.lolskill.net/img/champions/64/diana.png"})
KoreanDiana:MenuElement({type = MENU, id = "Combo", name = "Korean Combo Settings"})
KoreanDiana:MenuElement({type = MENU, id = "Harass", name = "Harass Settings"})
KoreanDiana:MenuElement({type = MENU, id = "KS", name = "KS Settings"})
KoreanDiana:MenuElement({type = MENU, id = "Misc", name = "Misc Settings"})
KoreanDiana:MenuElement({type = MENU, id = "Draw", name = "Drawing Settings"})

local function Ready(spell)
	return myHero:GetSpellData(spell).currentCd == 0 and myHero:GetSpellData(spell).level > 0 and myHero:GetSpellData(spell).mana <= myHero.mana
end

function CountAlliesInRange(point, range)
	if type(point) ~= "userdata" then error("{CountAlliesInRange}: bad argument #1 (vector expected, got "..type(point)..")") end
	local range = range == nil and math.huge or range 
	if type(range) ~= "number" then error("{CountAlliesInRange}: bad argument #2 (number expected, got "..type(range)..")") end
	local n = 0
	for i = 1, Game.HeroCount() do
		local unit = Game.Hero(i)
		if unit.isAlly and not unit.isMe and IsValidTarget(unit, range, false, point) then
			n = n + 1
		end
	end
	return n
end

local function CountEnemiesInRange(point, range)
	if type(point) ~= "userdata" then error("{CountEnemiesInRange}: bad argument #1 (vector expected, got "..type(point)..")") end
	local range = range == nil and math.huge or range 
	if type(range) ~= "number" then error("{CountEnemiesInRange}: bad argument #2 (number expected, got "..type(range)..")") end
	local n = 0
	for i = 1, Game.HeroCount() do
		local unit = Game.Hero(i)
		if IsValidTarget(unit, range, true, point) then
			n = n + 1
		end
	end
	return n
end

local _EnemyHeroes
function GetEnemyHeroes()
	if _EnemyHeroes then return _EnemyHeroes end
	_EnemyHeroes = {}
	for i = 1, Game.HeroCount() do
		local unit = Game.Hero(i)
		if unit.isEnemy then
			table.insert(_EnemyHeroes, unit)
		end
	end
	return _EnemyHeroes
end 

local _AllyHeroes
function GetAllyHeroes()
	if _AllyHeroes then return _AllyHeroes end
	_AllyHeroes = {}
	for i = 1, Game.HeroCount() do
		local unit = Game.Hero(i)
		if unit.isAlly then
			table.insert(_AllyHeroes, unit)
		end
	end
	return _AllyHeroes
end


function GetPercentHP(unit)
	if type(unit) ~= "userdata" then error("{GetPercentHP}: bad argument #1 (userdata expected, got "..type(unit)..")") end
	return 100*unit.health/unit.maxHealth
end

function GetPercentMP(unit)
	if type(unit) ~= "userdata" then error("{GetPercentMP}: bad argument #1 (userdata expected, got "..type(unit)..")") end
	return 100*unit.mana/unit.maxMana
end

function GetBuffData(unit, buffname)
	for i = 0, unit.buffCount do
		local buff = unit:GetBuff(i)
		if buff.name == buffname and buff.count > 0 then 
			return buff
		end
	end
	return {type = 0, name = "", startTime = 0, expireTime = 0, duration = 0, stacKS = 0, count = 0}--
end

local function GetBuffs(unit)
	local t = {}
	for i = 0, unit.buffCount do
		local buff = unit:GetBuff(i)
		if buff.count > 0 then
			table.insert(t, buff)
		end
	end
	return t
end

local function GetDistance(p1,p2)
	return  math.sqrt(math.pow((p2.x - p1.x),2) + math.pow((p2.y - p1.y),2) + math.pow((p2.z - p1.z),2))
end

function IsFacing(unit)
	-- make sure directions are facing opposite:
	local dotProduct = myHero.dir.x*target.dir.x + myHero.dir.z*target.dir.z
	if (dotProduct < 0) then
		-- also make sure you dont have your backs to each other:
		if (myHero.dir.x > 0 and myHero.dir.z > 0) then
			return ((target.pos.x - myHero.pos.x > 0) and (target.pos.z - myHero.pos.z > 0))
		elseif (myHero.dir.x < 0 and myHero.dir.z < 0) then
			return ((target.pos.x - myHero.pos.x < 0) and (target.pos.z - myHero.pos.z < 0))
		elseif (myHero.dir.x > 0 and myHero.dir.z < 0) then
			return ((target.pos.x - myHero.pos.x > 0) and (target.pos.z - myHero.pos.z < 0))
		elseif (myHero.dir.x < 0 and myHero.dir.z > 0) then
			return ((target.pos.x - myHero.pos.x < 0) and (target.pos.z - myHero.pos.z > 0))
		end
	end
	return 1
end

function IsImmune(unit)
	if type(unit) ~= "userdata" then error("{IsImmune}: bad argument #1 (userdata expected, got "..type(unit)..")") end
	for i, buff in pairs(GetBuffs(unit)) do
		if (buff.name == "KindredRNoDeathBuff" or buff.name == "UndyingRage") and GetPercentHP(unit) <= 10 then
			return true
		end
		if buff.name == "VladimirSanguinePool" or buff.name == "JudicatorIntervention" then 
			return true
		end
	end
	return false
end

function HasBuff(unit, buffname)
	if type(unit) ~= "userdata" then error("{HasBuff}: bad argument #1 (userdata expected, got "..type(unit)..")") end
	if type(buffname) ~= "string" then error("{HasBuff}: bad argument #2 (string expected, got "..type(buffname)..")") end
	for i, buff in pairs(GetBuffs(unit)) do
		if buff.name == buffname then 
			return true
		end
	end
	return false
end

function Orbwalker:GetEnemyTowers()
    if self._EnemyTowers then return self._EnemyTowers end    
      for i = 0,Game.ObjectCount() do
        local o = Game.Object(i)
        if o.isEnemy and (o.name:find("HQ_T") or o.name:find("Barracks_T")) then
          if self._EnemyTowers == nil then self._EnemyTowers = {} end
          table.insert(self._EnemyTowers, o)
        end
    end
    if self._EnemyTowers ~= nil then
        for i = 1, Game.TurretCount() do
            local turret = Game.Turret(i)
            if turret.isEnemy then
                table.insert(self._EnemyTowers, turret)
            end
        end
    end
  if self._EnemyTowers then return self._EnemyTowers end
  return {}
end

function IsImmobileTarget(unit)
	for i = 0, unit.buffCount do
		local buff = unit:GetBuff(i)
		if buff and (buff.type == 5 or buff.type == 11 or buff.type == 29 or buff.type == 24 or buff.name == "recall") and buff.count > 0 then
			return true
		end
	end
	return false	
end

function IsValidTarget(unit, range, checkTeam, from)
	local range = range == nil and math.huge or range
	if type(range) ~= "number" then error("{IsValidTarget}: bad argument #2 (number expected, got "..type(range)..")") end
	if type(checkTeam) ~= "nil" and type(checkTeam) ~= "boolean" then error("{IsValidTarget}: bad argument #3 (boolean or nil expected, got "..type(checkTeam)..")") end
	if type(from) ~= "nil" and type(from) ~= "userdata" then error("{IsValidTarget}: bad argument #4 (vector or nil expected, got "..type(from)..")") end
	if unit == nil or not unit.valid or not unit.visible or unit.dead or not unit.isTargetable or IsImmune(unit) or (checkTeam and unit.isAlly) then 
		return false 
	end 
	return unit.pos:DistanceTo(from.pos and from.pos or myHero.pos) < range 
end

function HaveDianaBuff(unit)--I will suck all night long to Smart Sempai
    for i = 0, unit.buffCount do
        local buff = unit:GetBuff(i)
        if buff and buff.name == "dianamoonlight" and buff.count > 0 then--To get Buffname I will use PrintChat() Kappa btw I will suck him for real I swear to god.
            return true
        end
    end
    return false
end

require("DamageLib")

class "Diana"

function Diana:__init()
	print("Korean Diana [v0.5] Loaded succesfully ^^")
	self.Icons = { Q = "http://static.lolskill.net/img/abilities/64/Diana_Q_MoonsEdge.png",
				   W = "http://static.lolskill.net/img/abilities/64/Diana_W_LunarShower.png",
				   E = "http://static.lolskill.net/img/abilities/64/Diana_E_MoonFall.png",
				   R = "http://static.lolskill.net/img/abilities/64/Diana_R_FasterThanLight.png"}
	self.Spells = {
		Q = {range = 875, delay = 0.25, speed = 1500,  width = 130, type = "circular"},
		W = {range = 250, delay = 0.25, speed = math.huge}, --ITS OVER 9000!!!!
		E = {range = 250, delay = 0.25, speed = math.huge, width = 250},
		R = {range = 825, delay = 0}}
	self:Menu()
	
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
end

function Diana:Menu()
	KoreanDiana.Combo:MenuElement({id = "Q", name = "Use Crescent Strike (Q)", value = true, leftIcon = self.Icons.Q})
	KoreanDiana.Combo:MenuElement({id = "W", name = "Use Pale Cascade (W)", value = true, leftIcon = self.Icons.W})
	KoreanDiana.Combo:MenuElement({id = "E", name = "Use Moonfall (E)", value = true, leftIcon = self.Icons.E})
	KoreanDiana.Combo:MenuElement({id = "R", name = "Use Lunar Rush (R)", value = true, leftIcon = self.Icons.R})
	KoreanDiana.Combo:MenuElement({id = "DR", name = "Use Korean R in Combo [?]", value = true, tooltip = "Uses 2nd R in Combo and R when didn't hit Q", leftIcon = "http://2.1m.yt/NtPMS9.png"})
  --KoreanDiana.Combo:MenuElement({id = "NT", name = "Enable Towerdive [?]", value = false, tooltip = "Tip: Enable this for ganks/late-game etc"})
	KoreanDiana.Combo:MenuElement({id = "I", name = "Use Ignite in Combo when Killable", value = true, leftIcon = "http://static.lolskill.net/img/spells/32/14.png"})
	KoreanDiana.Combo:MenuElement({id = "ION", name = "Enable custom Ignite Settings", value = true})
	KoreanDiana.Combo:MenuElement({id = "IFAST", name = "Uses Ignite when target hp%", value = 0.5, min = 0.1, max = 1, step = 0.01})

	KoreanDiana.Harass:MenuElement({id = "Q", name = "Use Crescent Strike (Q)", value = true, leftIcon = self.Icons.Q})
	KoreanDiana.Harass:MenuElement({id = "W", name = "Use Pale Cascade (W)", value = true, leftIcon = self.Icons.W})
	KoreanDiana.Harass:MenuElement({id = "E", name = "Use Moonfall (E)", value = true, leftIcon = self.Icons.E})
	KoreanDiana.Harass:MenuElement({id = "Mana", name = "Min. Mana for Harass(%)", value = 40, min = 0, max = 100, step = 1})

	KoreanDiana.KS:MenuElement({id = "ON", name = "Enable KillSteal", value = true})
	KoreanDiana.KS:MenuElement({id = "Q", name = "Use Q to KS", value = true, leftIcon = self.Icons.Q})
	KoreanDiana.KS:MenuElement({id = "W", name = "Use W to KS", value = true, leftIcon = self.Icons.W})
	KoreanDiana.KS:MenuElement({id = "R", name = "Use R to KS", value = true, leftIcon = self.Icons.R})
	KoreanDiana.KS:MenuElement({id = "I", name = "Use Ignite to KS", value = true, leftIcon = "http://static.lolskill.net/img/spells/32/14.png"})
	KoreanDiana.KS:MenuElement({id = "Mana", name = "Min. Mana to KillSteal(%)", value = 20, min = 0, max = 100, step = 1})

	KoreanDiana.Misc:MenuElement({id = "WON", name = "Enable Auto shield", value = true})
	KoreanDiana.Misc:MenuElement({id = "W", name = "Use Auto shield when HP%", value = 0.2, min = 0.01, max = 1, step = 0.01, leftIcon = self.Icons.W})

	KoreanDiana.Draw:MenuElement({id = "Enabled", name = "Enable Drawings", value = true})
	KoreanDiana.Draw:MenuElement({id = "Q", name = "Draw Q", value = true, leftIcon = self.Icons.Q})
	KoreanDiana.Draw:MenuElement({id = "W", name = "Draw W", value = true, leftIcon = self.Icons.W})
	KoreanDiana.Draw:MenuElement({id = "E", name = "Draw E", value = true, leftIcon = self.Icons.E})
	KoreanDiana.Draw:MenuElement({id = "R", name = "Draw R", value = true, leftIcon = self.Icons.R})
end

function Diana:Tick()
	if myHero.dead then return end

	local target =  _G.SDK.TargetSelector:GetTarget(2000)
	if target and _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_COMBO] then
		self:Combo(target)
	elseif target and _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_HARASS] then
		self:Harass(target)
	end
	self:KS()
	self:Misc()
end

function Diana:Combo(target) 
local ComboQ = KoreanDiana.Combo.Q:Value()
local ComboW = KoreanDiana.Combo.W:Value()
local ComboE = KoreanDiana.Combo.E:Value()
local ComboR = KoreanDiana.Combo.R:Value() 
local ComboDR = KoreanDiana.Combo.DR:Value() 
--local ComboET = KoreanDiana.Combo.ET:Value()
local ComboI = KoreanDiana.Combo.I:Value()
local ComboION = KoreanDiana.Combo.ION:Value()
local ComboIFAST = KoreanDiana.Combo.IFAST:Value()
		if ComboW and Ready(_W) then
			if IsValidTarget(target, self.Spells.W.range, true, myHero) and Ready(_W) then
				Control.CastSpell(HK_W, target)
			end
			if ComboQ and Ready(_Q) then
				if target.valid and Ready(_Q) and target.distance <= 1.1 * self.Spells.Q.range then
  				local Qpos = target:GetPrediction(self.Spells.Q.speed, self.Spells.Q.delay)
      				if Qpos and GetDistance(Qpos,myHero.pos) < self.Spells.Q.range then
        				Control.CastSpell(HK_Q, Qpos)
     				end
     			end
     		end
     		if ComboE and Ready(_E) then 
     			if IsValidTarget(target, self.Spells.E.range, true, myHero) and Ready(_E) then
				Control.CastSpell(HK_E, target)
				end
			end
	elseif ComboQ and Ready(_Q) then
			if target.valid and Ready(_Q) and target.distance <= 1.1 * self.Spells.Q.range then
  			local Qpos = target:GetPrediction(self.Spells.Q.speed, self.Spells.Q.delay)
      			if Qpos and GetDistance(Qpos,myHero.pos) < self.Spells.Q.range then
        			Control.CastSpell(HK_Q, Qpos)
     			end
     		end
     		if ComboE and Ready(_E) then
     			if IsValidTarget(target, self.Spells.E.range, true, myHero) and Ready(_E) then
				Control.CastSpell(HK_E, target)
				end
			end
	else
		if ComboE and Ready(E) then
			if IsValidTarget(target, self.Spells.E.range, true, myHero) and Ready(_E) then
				Control.CastSpell(HK_E, target)
			end
		end 
    end
    if ComboR and Ready(_R) then
    	if IsValidTarget(target, self.Spells.R.range, true, myHero) and HaveDianaBuff(target) and Ready(_R) then
    		Control.CastSpell(HK_R, target)
    	end
    	if ComboR and ComboDR  and Ready(_R) then
    		if IsValidTarget(target, self.Spells.R.range, true, myHero) and Ready(_R) then
    			Control.CastSpell(HK_R, target)
    		end
    	end 
    else
    	if ComboR and ComboDR and not Ready(_Q) and Ready(_R) then
    		if IsValidTarget(target, self.Spells.R.range, true, myHero) and Ready(_R) then
    		Control.CastSpell(HK_R, target)
    		end
    	end
    end 
    if ComboI and ComboION and myHero:GetSpellData(SUMMONER_1).name == "SummonerDot" and Ready(SUMMONER_1) then
		if IsValidTarget(target, 600, true, myHero) and target.health/target.maxHealth <= ComboIFAST then
			Control.CastSpell(HK_SUMMONER_1, target)
		end
	elseif ComboI and ComboION and myHero:GetSpellData(SUMMONER_2).name == "SummonerDot" and Ready(SUMMONER_2) then
		if IsValidTarget(target, 600, true, myHero) and target.health/target.maxHealth <= ComboIFAST then
			Control.CastSpell(HK_SUMMONER_2, target)
		end
	elseif ComboI and myHero:GetSpellData(SUMMONER_1).name == "SummonerDot" and Ready(SUMMONER_1) and not Ready(_Q)   and not Ready(_R) then
		if IsValidTarget(target, 600, true, myHero) and 50+20*myHero.levelData.lvl > target.health then
			Control.CastSpell(HK_SUMMONER_1, target)
		end
	elseif ComboI and myHero:GetSpellData(SUMMONER_2).name == "SummonerDot" and Ready(SUMMONER_2) and not Ready(_Q)  and not Ready(_R)  then
		if IsValidTarget(target, 600, true, myHero) and 50+20*myHero.levelData.lvl > target.health then
			Control.CastSpell(HK_SUMMONER_2, target)
		end
	end
end

function Diana:Harass(target)
local HarassQ = KoreanDiana.Harass.Q:Value()
local HarassW = KoreanDiana.Harass.W:Value()
local HarassE = KoreanDiana.Harass.E:Value() 
if (myHero.mana/myHero.maxMana >= KoreanDiana.Harass.Mana:Value() / 100) then
	if HarassW and Ready(_W) then
		if IsValidTarget(target, self.Spells.W.range, true, myHero) and Ready(_W) then
			Control.CastSpell(HK_W, target)
		end
		if HarassE and Ready(_E) then 
			if IsValidTarget(target, self.Spells.E.range, true, myHero) and Ready(_E) then
				Control.CastSpell(HK_E, target)
			end
		end
		if HarassQ and Ready(_Q) then
			if target.valid and Ready(_Q) and target.distance <= 1.1 * self.Spells.Q.range then
  			local Qpos = target:GetPrediction(self.Spells.Q.speed, self.Spells.Q.delay)
      			if Qpos and GetDistance(Qpos,myHero.pos) < self.Spells.Q.range then
        			Control.CastSpell(HK_Q, Qpos)
     			end
     		end
     	end
    elseif HarassE and Ready(_E) then
    		if IsValidTarget(target, self.Spells.E.range, true, myHero) and Ready(_E) then
				Control.CastSpell(HK_E, target)
			end
		end
		if HarassQ and Ready(_Q) then
			if target.valid and Ready(_Q) and target.distance <= 1.1 * self.Spells.Q.range then
  			local Qpos = target:GetPrediction(self.Spells.Q.speed, self.Spells.Q.delay)
      			if Qpos and GetDistance(Qpos,myHero.pos) < self.Spells.Q.range then
        			Control.CastSpell(HK_Q, Qpos)
     			end
     		end
     	end
    else
    	if HarassQ and Ready(_Q) then
    		if target.valid and Ready(_Q) and target.distance <= 1.1 * self.Spells.Q.range then
  			local Qpos = target:GetPrediction(self.Spells.Q.speed, self.Spells.Q.delay)
      			if Qpos and GetDistance(Qpos,myHero.pos) < self.Spells.Q.range then
        			Control.CastSpell(HK_Q, Qpos)
     			end
     		end
     	end
    end
end 

function Diana:Misc()
local MiscWON = KoreanDiana.Misc.WON:Value()
	if MiscWON then
		if (myHero.health/myHero.maxHealth <= KoreanDiana.Misc.W:Value() / 1) then
			if Ready(_W)  then 
				Control.CastSpell(HK_W)
				DelayAction(1000)
			end
		end
	end
end


function Diana:KS(target)
local KSON = KoreanDiana.KS.ON:Value()
local KSQ = KoreanDiana.KS.Q:Value()
local KSW = KoreanDiana.KS.W:Value()
local KSR = KoreanDiana.KS.R:Value()
local KSI = KoreanDiana.KS.I:Value()
	for i = 1, Game.HeroCount() do
		local target = Game.Hero(i)
		if (myHero.mana/myHero.maxMana >= KoreanDiana.KS.Mana:Value() / 100) then
			if KSON then
				if KSW and Ready(_W) then
					if IsValidTarget(target, self.Spells.W.range, true, myHero) and Ready(_W) then
						if getdmg("W", target, myHero)*4 > target.health and Ready(_W) then
							Control.CastSpell(HK_W, target)
						end
					end
				end
				if KSQ and Ready(_Q) then
					if target.valid and Ready(_Q) and target.distance <= 1.1 * self.Spells.Q.range then
  					local Qpos = target:GetPrediction(self.Spells.Q.speed, self.Spells.Q.delay)
      					if Qpos and GetDistance(Qpos,myHero.pos) < self.Spells.Q.range and getdmg("Q", target, myHero) > target.health then
        					Control.CastSpell(HK_Q, Qpos)
     					end
     				end
     			end
     			if KSR and Ready(_R) and not Ready(_Q) then 
     				if IsValidTarget(target, self.Spells.R.range, true, myHero) and getdmg("Q", target, myHero) > target.health and target.distance >= 300 and Ready(_R) then
    					Control.CastSpell(HK_R, target)
    				end
    			end
    			if KSI and myHero:GetSpellData(SUMMONER_1).name == "SummonerDot" and Ready(SUMMONER_1) and not Ready(_Q) and not Ready(_W) and not Ready(_E) and not Ready(_R) then
					if IsValidTarget(target, 600, true, myHero) and 50+20*myHero.levelData.lvl > target.health then
						Control.CastSpell(HK_SUMMONER_1, target)
					end
				end
				if KSI and myHero:GetSpellData(SUMMONER_2).name == "SummonerDot" and Ready(SUMMONER_2) and not Ready(_Q) and not Ready(_W) and not Ready(_E) and not Ready(_R)  then
					if IsValidTarget(target, 600, true, myHero) and 50+20*myHero.levelData.lvl > target.health then
						Control.CastSpell(HK_SUMMONER_2, target)
					end
				end
			end
		end
	end
end

function Diana:Draw()
	if not myHero.dead then
		if KoreanDiana.Draw.Enabled:Value() then 
			if KoreanDiana.Draw.Q:Value() then
			Draw.Circle(myHero.pos, self.Spells.Q.range, 1, Draw.Color(255, 52, 221, 221))
			end
			if KoreanDiana.Draw.W:Value() then
			Draw.Circle(myHero.pos, self.Spells.W.range, 1, Draw.Color(255, 255, 255, 255))
			end
			if KoreanDiana.Draw.E:Value() then
			Draw.Circle(myHero.pos, self.Spells.E.range, 1, Draw.Color(255, 255, 0, 128))
			end
			if KoreanDiana.Draw.R:Value() then
			Draw.Circle(myHero.pos, self.Spells.R.range, 1, Draw.Color(255, 000, 255, 000))
		end
	end
end
end

if _G[myHero.charName]() then print("Welcome back " ..myHero.name.. ", Have a nice day my friend! <3 ") end
