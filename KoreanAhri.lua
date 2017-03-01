local KoreanChamps = {"Ahri"}
if not table.contains(KoreanChamps, myHero.charName) then return end

local KoreanAhri = MenuElement({type = MENU, id = "KoreanAhri", name = "Korean Ahri", leftIcon = "http://static.lolskill.net/img/champions/64/ahri.png"})
KoreanAhri:MenuElement({type = MENU, id = "Combo", name = "Korean Combo Settings"})
KoreanAhri:MenuElement({type = MENU, id = "Harass", name = "Harass Settings"})
KoreanAhri:MenuElement({type = MENU, id = "Misc", name = "Misc Settings"})
KoreanAhri:MenuElement({type = MENU, id = "Draw", name = "Drawing Settings"})

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
	return {type = 0, name = "", startTime = 0, expireTime = 0, duration = 0, stacMisc = 0, count = 0}--
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


require("DamageLib")

class "Ahri"

function Ahri:__init()
	print("Korean Ahri [v1.1] Loaded succesfully ^^")

	self.Spells = {
		Q = {range = 875, delay = 0.25, speed = 1700,  width = 100},
		W = {range = 700, delay = 0.25, speed = math.huge}, --ITS OVER 9000!!!!
		E = {range = 950, delay = 0.25, speed = 1600, width = 65, collision = true},
		R = {range = 850, delay = 0},
		SummonerDot = {range = 600, dmg = 50+20*myHero.levelData.lvl}
	}
	self:Menu()
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)

end

function Ahri:Menu()
	KoreanAhri.Combo:MenuElement({id = "Q", name = "Use Orb of Deception (Q)", value = true, leftIcon = "http://static.lolskill.net/img/abilities/64/Ahri_OrbofDeception.png"})
	KoreanAhri.Combo:MenuElement({id = "W", name = "Use Fox-Fire (W)", value = true, leftIcon = "http://static.lolskill.net/img/abilities/64/Ahri_FoxFire.png"})
	KoreanAhri.Combo:MenuElement({id = "E", name = "Use Charm (E)", value = true, leftIcon = "http://static.lolskill.net/img/abilities/64/Ahri_Charm.png"})
	KoreanAhri.Combo:MenuElement({id = "R", name = "Use Spirit Rush (R) [?]", value = true, tooltip = "Uses Smart-R to mouse", leftIcon = "http://static.lolskill.net/img/abilities/64/Ahri_SpiritRush.png"})
    KoreanAhri.Combo:MenuElement({id = "I", name = "Use Ignite", value = true, leftIcon = "http://static.lolskill.net/img/spells/32/14.png"})
    KoreanAhri.Combo:MenuElement({id = "AI", name = "Always use Ignite in Combo", value = false})

	KoreanAhri.Harass:MenuElement({id = "Q", name = "Use Orb of Deception (Q)", value = true, leftIcon = "http://static.lolskill.net/img/abilities/64/Ahri_OrbofDeception.png"})
	KoreanAhri.Harass:MenuElement({id = "W", name = "Use Fox-Fire (W)", value = true, leftIcon = "http://static.lolskill.net/img/abilities/64/Ahri_FoxFire.png"})
	KoreanAhri.Harass:MenuElement({id = "E", name = "Use Charm (E)", value = true, leftIcon = "http://static.lolskill.net/img/abilities/64/Ahri_Charm.png"})
	KoreanAhri.Harass:MenuElement({id = "Mana", name = "Min. Mana for Harass(%)", value = 40, min = 0, max = 100, step = 1})

 --	KoreanAhri.Misc:MenuElement({id = "AutoE", name = "Use auto Charm", value = true})
	KoreanAhri.Misc:MenuElement({id = "KS", name = "Enable KillSteal", value = true})
	KoreanAhri.Misc:MenuElement({id = "Q", name = "Use Q to KS", value = true})
	KoreanAhri.Misc:MenuElement({id = "W", name = "Use W to KS", value = true})
	KoreanAhri.Misc:MenuElement({id = "E", name = "Use E to KS", value = true})
	KoreanAhri.Misc:MenuElement({id = "R", name = "Use R to KS", value = true})
	KoreanAhri.Misc:MenuElement({id = "Mana", name = "Min. Mana to KillSteal(%)", value = 20, min = 0, max = 100, step = 1})

  	KoreanAhri.Draw:MenuElement({id = "Enabled", name = "Enable Drawings", value = true})
	KoreanAhri.Draw:MenuElement({id = "Q", name = "Draw Q", value = true})
	KoreanAhri.Draw:MenuElement({id = "W", name = "Draw W", value = true})
	KoreanAhri.Draw:MenuElement({id = "E", name = "Draw E", value = true})
	KoreanAhri.Draw:MenuElement({id = "R", name = "Draw R", value = true})
end

function Ahri:Tick()
	if myHero.dead then return end

	local target = _G.SDK.TargetSelector:GetTarget(2000)

	if target and _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_COMBO] then
		self:Combo(target)
	elseif target and _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_HARASS] then
		self:Harass(target)
	end
	self:Misc()
end

function Ahri:Combo(target)
local ComboQ = KoreanAhri.Combo.Q:Value()
local ComboW = KoreanAhri.Combo.W:Value()
local ComboE = KoreanAhri.Combo.E:Value()
local ComboR = KoreanAhri.Combo.R:Value()
local ComboI = KoreanAhri.Combo.I:Value()
local ComboAI = KoreanAhri.Combo.AI:Value()
	if ComboE and Ready(_E) then
		if IsValidTarget(target, self.Spells.E.range, true, myHero) and Ready(_E) then
			if target:GetCollision(self.Spells.E.width, self.Spells.E.speed, self.Spells.E.delay) == 0 then
			local Epos = target:GetPrediction(self.Spells.E.speed, self.Spells.E.delay)
				if Epos then
					Control.CastSpell(HK_E, Epos)
				end
			end
		end
		if ComboQ and Ready(_Q) then
			if IsValidTarget(target, self.Spells.Q.range, true, myHero) and Ready(_Q) then
			local Qpos = target:GetPrediction(self.Spells.Q.speed, self.Spells.Q.delay)
				if Qpos then 
				Control.CastSpell(HK_Q, Qpos)
				end
			end
		end
		if ComboW and Ready(_W) then
			if IsValidTarget(target, self.Spells.W.range, true, myHero) and Ready(_W) then
				Control.CastSpell(HK_W, target)
			end 
		end
	elseif ComboQ and Ready(_Q) then
		if IsValidTarget(target, self.Spells.E.range, true, myHero) and Ready(_Q) then
		local Qpos = target:GetPrediction(self.Spells.Q.speed, self.Spells.Q.delay)
			if Qpos then 
				Control.CastSpell(HK_Q, Qpos)
			end
		end
		if ComboW and Ready(_W) then
			if IsValidTarget(target, self.Spells.W.range, true, myHero) and Ready(_W) then
				Control.CastSpell(HK_W, target)
			end 
		end
	else
		if ComboW and Ready(_W) then
			if IsValidTarget(target, self.Spells.W.range, true, myHero) and Ready(_W) then
				Control.CastSpell(HK_W, target)
			end 
		end 
	end
	if ComboR and Ready(_R) then 
		if IsValidTarget(target, self.Spells.R.range, true, myHero) and Ready(_R) then
			Control.CastSpell(HK_R, mousePos)
			Control.CastSpell(HK_R, mousePos)
			Control.CastSpell(HK_R, MousePos)
		end 
	end
	if ComboI and ComboAI and myHero:GetSpellData(SUMMONER_1).name == "SummonerDot" and Ready(SUMMONER_1) then
		if IsValidTarget(target, 600, true, myHero) and Ready(SUMMONER_1) then
			Control.CastSpell(HK_SUMMONER_1, target)
		end
	elseif ComboI and ComboAI and myHero:GetSpellData(SUMMONER_2).name == "SummonerDot" and Ready(SUMMONER_2) then
		if IsValidTarget(target, 600, true, myHero) and Ready(SUMMOMER_2) then
			Control.CastSpell(HK_SUMMONER_2, target)
		end
	elseif ComboI and myHero:GetSpellData(SUMMONER_1).name == "SummonerDot" and Ready(SUMMONER_1) and not Ready(_Q) and not Ready(_W) and not Ready(_E) and not Ready(_R) then
		if IsValidTarget(target, 600, true, myHero) and 50+20*myHero.levelData.lvl > target.health then
			Control.CastSpell(HK_SUMMONER_1, target)
		end
	elseif ComboI and myHero:GetSpellData(SUMMONER_2).name == "SummonerDot" and Ready(SUMMONER_2) and not Ready(_Q) and not Ready(_W) and not Ready(_E) and not Ready(_R)  then
		if IsValidTarget(target, 600, true, myHero) and 50+20*myHero.levelData.lvl > target.health then
			Control.CastSpell(HK_SUMMONER_2, target)
		end
	end
end

function Ahri:Harass(target)
local HarassQ = KoreanAhri.Harass.Q:Value()
local HarassW = KoreanAhri.Harass.W:Value()
local HarassE = KoreanAhri.Harass.E:Value()
if (myHero.mana/myHero.maxMana >= KoreanAhri.Harass.Mana:Value() / 100) then
	if HarassE and Ready(_E) then
		if IsValidTarget(target, self.Spells.E.range, true, myHero) and Ready(_E) then
			if target:GetCollision(self.Spells.E.width, self.Spells.E.speed, self.Spells.E.delay) == 0 then
			local Epos = target:GetPrediction(self.Spells.E.speed, self.Spells.E.delay)
				if Epos then
					Control.CastSpell(HK_E, Epos)
				end
			end
		end 
		if HarassQ and Ready(_Q) then 
			if IsValidTarget(target, self.Spells.Q.range, true, myHero) and Ready(_Q) then
			local Qpos = target:GetPrediction(self.Spells.Q.speed, self.Spells.Q.delay)
				if Qpos then 
					Control.CastSpell(HK_Q, Qpos)
				end
			end
		end
		if HarrasW and Ready(_W) then
			if IsValidTarget(target, self.Spells.W.range, true, myHero) and Ready(_W) then
				Control.CastSpell(HK_W, target)
			end 
		end
	elseif  HarassQ and Ready(_Q) then 
			if IsValidTarget(target, self.Spells.Q.range, true, myHero) and Ready(_Q) then
			local Qpos = target:GetPrediction(self.Spells.Q.speed, self.Spells.Q.delay)
				if Qpos then 
					Control.CastSpell(HK_Q, Qpos)
				end
			end 
		if HarassW and Ready(_W) then
			if IsValidTarget(target, self.Spells.W.range, true, myHero) and Ready(_W) then
				Control.CastSpell(HK_W, target)
			end 
		end
	else 
		if HarassW and Ready(_W) then
			if IsValidTarget(target, self.Spells.W.range, true, myHero) and Ready(_W) then
				Control.CastSpell(HK_W, target)
			end 
		end
	end
end
end

function Ahri:Misc()
local KSON = KoreanAhri.Misc.KS:Value()
local KSQ = KoreanAhri.Misc.Q:Value()
local KSW = KoreanAhri.Misc.W:Value()
local KSE = KoreanAhri.Misc.E:Value()
local KSR = KoreanAhri.Misc.E:Value()
	for i = 1, Game.HeroCount() do
		local target = Game.Hero(i)
		if (myHero.mana/myHero.maxMana >= KoreanAhri.Misc.Mana:Value() / 100) then
			if KSON then 
				if KSE and IsValidTarget(target, self.Spells.E.range, true, myHero) and Ready(_E) then
					if getdmg("E", target, myHero) > target.health and Ready(_E) then
						if target:GetCollision(self.Spells.E.width, self.Spells.E.speed, self.Spells.Q.delay) == 0 then
						local Epos = target:GetPrediction(self.Spells.E.speed, self.Spells.E.delay)
							if Epos then
								Control.CastSpell(HK_E, Epos)
							end
						end
					end
				end
				if KSQ and IsValidTarget(target, self.Spells.Q.range, true, myHero) and Ready(_Q) then
					if getdmg("Q", target, myHero) > target.health and Ready(_Q) then
					local Qpos = target:GetPrediction(self.Spells.Q.speed, self.Spells.Q.delay)
						if Qpos then
							Control.CastSpell(HK_Q, Qpos)
						end
					end
				end
				if KSW and IsValidTarget(target, self.Spells.W.range, true, myHero) and Ready(_W) then
					if getdmg("W", target, myHero)*3 > target.health and Ready(_W) then
						Control.CastSpell(HK_W, target)
					end 
				end
				if KSR and IsValidTarget(target, self.Spells.R.range, true, myHero) and Ready(_R) then 
					if getdmg("R", target, myHero) > target.health and Ready(_R) then
						Control.CastSpell(HK_R, target)
					end 
				end 
			end 
		end
	end
end


function Ahri:Draw()
	if not myHero.dead then
		if KoreanAhri.Draw.Enabled:Value() then 
			if KoreanAhri.Draw.Q:Value() then
			Draw.Circle(myHero.pos, self.Spells.Q.range, 1, Draw.Color(255, 52, 221, 221))
			end
			if KoreanAhri.Draw.W:Value() then
			Draw.Circle(myHero.pos, self.Spells.W.range, 1, Draw.Color(255, 255, 255, 255))
			end
			if KoreanAhri.Draw.E:Value() then
			Draw.Circle(myHero.pos, self.Spells.E.range, 1, Draw.Color(255, 255, 0, 128))
			end
			if KoreanAhri.Draw.R:Value() then
			Draw.Circle(myHero.pos, self.Spells.R.range, 1, Draw.Color(255, 000, 255, 000))
		end
	end
end
end

if _G[myHero.charName]() then print("Welcome back " ..myHero.name.. ", Have a nice day my friend! <3 ") end
