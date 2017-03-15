local KoreanChamps = {"Ahri", "Blitzcrank", "Darius", "Diana", "KogMaw"}
if not table.contains(KoreanChamps, myHero.charName)  then print("" ..myHero.charName.. " Is Not (Yet) Supported") return end

local KoreanMechanics = MenuElement({type = MENU, id = "KoreanMechanics", name = "Korean Mechanics Reborn | " ..myHero.charName, leftIcon = "http://4.1m.yt/d5VbDBm.png"})
KoreanMechanics:MenuElement({type = MENU, id = "Combo", name = "Korean Combo Settings"})
KoreanMechanics:MenuElement({type = MENU, id = "Harass", name = "Harass Settings"})
KoreanMechanics:MenuElement({type = MENU, id = "Clear", name = "WaveClear Settings"})
KoreanMechanics:MenuElement({type = MENU, id = "KS", name = "Misc Settings"})
KoreanMechanics:MenuElement({type = MENU, id = "Draw", name = "Drawing Settings"})

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
	return {type = 0, name = "", startTime = 0, expireTime = 0, duration = 0, stacks = 0, count = 0}--
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

function GetItemSlot(unit, id)
  for i = ITEM_1, ITEM_7 do
    if unit:GetItemData(i).itemID == id then
      return i
    end
  end
  return 0 -- 
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

function GetEnemyMinions(range)
    EnemyMinions = {}
    for i = 1, Game.MinionCount() do
        local Minion = Game.Minion(i)
        if Minion.isEnemy and IsValidTarget(Minion, range, false, myHero) and not Minion.IsDead then
            table.insert(EnemyMinions, Minion)
        end
    end
    return EnemyMinions
end

function GetEnemyCount(range) --sofie <33
    local count = 0
    for i=1,Game.HeroCount() do
        local hero = Game.Hero(i)
        if hero.team ~= myHero.team then
            count = count + 1
        end
    end
    return count
end

function EnemysAround(pos, range, team)
	local Count = 0
	for i = 1, Game.HeroCount() do
		local e = Game.Hero(i)
		if e and e.team == team and not e.dead and GetDistance(pos, e.pos) <= range then
			Count = Count + 1
		end
	end
	return Count
end

function MinionsAround(pos, range, team)
	local Count = 0
	for i = 1, Game.MinionCount() do
		local m = Game.Minion(i)
		if m and m.team == team and not m.dead and GetDistance(pos, m.pos) <= range then
			Count = Count + 1
		end
	end
	return Count
end

function HaveDianaBuff(unit)
    for i = 0, unit.buffCount do
        local buff = unit:GetBuff(i)
        if buff and buff.name == "dianamoonlight" and buff.count > 0 then
            return true
        end
    end
    return false
end

function RStacks(unit)
	if not unit then print("nounit") return 0 end
	for i = 0, unit.buffCount do
		local buff = unit:GetBuff(i)
		local Counter = buff.count
		if buff.name == "DariusHemo" and  buff.count > 0 then
			return Counter
		end
	end
	return 0
end

function GetDariusRlvl()
local lvl = myHero:GetSpellData(_R).level
	if lvl >= 1 then
		return (lvl + 1)
elseif lvl == nil then return 1 
	end 
end

function GetDariusRdmg()
local target = _G.SDK.TargetSelector:GetTarget(1000)
	if target == nil then return end
	if target then
local AD = myHero.bonusDamage
local level = GetDariusRlvl()
	if level == nil then return 1 
	end
local AD = myHero.bonusDamage
local Stacks = (RStacks(target) + 1)
local basedmg = (({0, 100, 200, 300})[level] + (0.75 * AD))

local stacksdmg = (  (({0, 100, 200, 300})[level]) * ((({0, 0.2, 0.4, 0.6, 0.8, 1})[Stacks]) ) )
local Rdmg =  ((basedmg + stacksdmg) + ((({0, 35 * KoreanMechanics.KS.XX:Value(), 69 * KoreanMechanics.KS.XX:Value(), 123 * KoreanMechanics.KS.XX:Value()})[level]) * (({0, 0.2, 0.4, 0.6, 0.8, 1})[Stacks]))) --CalcPhysicalDamage(myHero, target, ((basedmg + stacksdmg)))
	return Rdmg
	end
end

function GetKogRlvl()
local lvl = myHero:GetSpellData(_R).level
	if lvl >= 1 then
		return (lvl + 1)
elseif lvl == nil then return 1
	end
end

function GetKogRange()
local level = GetKogRlvl()
	if level == nil then return 1
	end
local Range = (({0, 1200, 1500, 1800})[level])
	return Range 
end


require("DamageLib")

class "Ahri"

function Ahri:__init()
	print("Korean Mechanics Reborn | Ahri Loaded succesfully")

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
	KoreanMechanics.Combo:MenuElement({id = "Q", name = "Use Orb of Deception (Q)", value = true, leftIcon = "http://static.lolskill.net/img/abilities/64/Ahri_OrbofDeception.png"})
	KoreanMechanics.Combo:MenuElement({id = "W", name = "Use Fox-Fire (W)", value = true, leftIcon = "http://static.lolskill.net/img/abilities/64/Ahri_FoxFire.png"})
	KoreanMechanics.Combo:MenuElement({id = "E", name = "Use Charm (E)", value = true, leftIcon = "http://static.lolskill.net/img/abilities/64/Ahri_Charm.png"})
	KoreanMechanics.Combo:MenuElement({id = "R", name = "Use Spirit Rush (R) [?]", value = true, tooltip = "Uses Smart-R to mouse", leftIcon = "http://static.lolskill.net/img/abilities/64/Ahri_SpiritRush.png"})
	KoreanMechanics.Combo:MenuElement({id = "I", name = "Use Ignite in Combo (when Killable)", value = true, leftIcon = "http://static.lolskill.net/img/spells/32/14.png"})
	KoreanMechanics.Combo:MenuElement({id = "ION", name = "Enable ustom Ignite Settings", value = true})
	KoreanMechanics.Combo:MenuElement({id = "IFAST", name = "Uses Ignite when target hp%", value = 0.5, min = 0.1, max = 1, step = 0.01})


	KoreanMechanics.Harass:MenuElement({id = "Q", name = "Use Orb of Deception (Q)", value = true, leftIcon = "http://static.lolskill.net/img/abilities/64/Ahri_OrbofDeception.png"})
	KoreanMechanics.Harass:MenuElement({id = "W", name = "Use Fox-Fire (W)", value = true, leftIcon = "http://static.lolskill.net/img/abilities/64/Ahri_FoxFire.png"})
	KoreanMechanics.Harass:MenuElement({id = "E", name = "Use Charm (E)", value = true, leftIcon = "http://static.lolskill.net/img/abilities/64/Ahri_Charm.png"})
	KoreanMechanics.Harass:MenuElement({id = "Mana", name = "Min. Mana for Harass(%)", value = 40, min = 0, max = 100, step = 1})

 --	KoreanMechanics.KS:MenuElement({id = "AutoE", name = "Use auto Charm", value = true})
	KoreanMechanics.KS:MenuElement({id = "ON", name = "Enable KillSteal", value = true})
	KoreanMechanics.KS:MenuElement({id = "Q", name = "Use Q to KS", value = true})
	KoreanMechanics.KS:MenuElement({id = "W", name = "Use W to KS", value = true})
	KoreanMechanics.KS:MenuElement({id = "E", name = "Use E to KS", value = true})
	KoreanMechanics.KS:MenuElement({id = "R", name = "Use R to KS", value = true})
	KoreanMechanics.KS:MenuElement({id = "I", name = "Use Ignite to KS", value = true})
	KoreanMechanics.KS:MenuElement({id = "Mana", name = "Min. Mana to KillSteal(%)", value = 20, min = 0, max = 100, step = 1})

  	KoreanMechanics.Draw:MenuElement({id = "Enabled", name = "Enable Drawings", value = true})
	KoreanMechanics.Draw:MenuElement({id = "Q", name = "Draw Q", value = true})
	KoreanMechanics.Draw:MenuElement({id = "W", name = "Draw W", value = true})
	KoreanMechanics.Draw:MenuElement({id = "E", name = "Draw E", value = true})
	KoreanMechanics.Draw:MenuElement({id = "R", name = "Draw R", value = true})
end

function Ahri:Tick()
	if myHero.dead then return end

	local target = _G.SDK.TargetSelector:GetTarget(2000)

	if target and _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_COMBO] then
		self:Combo(target)
	elseif target and _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_HARASS] then
		self:Harass(target)
	end
	self:KS()
end

function Ahri:Combo(target)
local ComboQ = KoreanMechanics.Combo.Q:Value()
local ComboW = KoreanMechanics.Combo.W:Value()
local ComboE = KoreanMechanics.Combo.E:Value()
local ComboR = KoreanMechanics.Combo.R:Value() 
local ComboI = KoreanMechanics.Combo.I:Value()
local ComboION = KoreanMechanics.Combo.ION:Value()
local ComboIFAST = KoreanMechanics.Combo.IFAST:Value()
	if ComboE and Ready(_E) then
		if target.valid and Ready(_E) and target:GetCollision(self.Spells.E.width, self.Spells.E.speed, self.Spells.E.delay) == 0 and target.distance <= 1.1 * self.Spells.E.range then
  			 local Epos = target:GetPrediction(self.Spells.E.speed, self.Spells.E.delay)
      			if Epos and GetDistance(Epos,myHero.pos) < self.Spells.E.range then
        			 Control.CastSpell(HK_E, Epos)
     			end
		end
		if ComboQ and Ready(_Q) then
			if target.valid and Ready(_Q) and target.distance <= 1.1 * self.Spells.Q.range then
  			 	local Qpos = target:GetPrediction(self.Spells.Q.speed, self.Spells.Q.delay)
      			if Qpos and GetDistance(Qpos,myHero.pos) < self.Spells.Q.range then
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
		if target.valid and Ready(_Q) and target.distance <= 1.1 * self.Spells.Q.range then
  			 local Qpos = target:GetPrediction(self.Spells.Q.speed, self.Spells.Q.delay)
      			if Qpos and GetDistance(Qpos,myHero.pos) < self.Spells.Q.range then
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
	if ComboI and ComboION and myHero:GetSpellData(SUMMONER_1).name == "SummonerDot" and Ready(SUMMONER_1) then
		if IsValidTarget(target, 600, true, myHero) and target.health/target.maxHealth <= ComboIFAST then
			Control.CastSpell(HK_SUMMONER_1, target)
		end
	elseif ComboI and ComboION and myHero:GetSpellData(SUMMONER_2).name == "SummonerDot" and Ready(SUMMONER_2) then
		if IsValidTarget(target, 600, true, myHero) and target.health/target.maxHealth <= ComboIFAST then
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
local HarassQ = KoreanMechanics.Harass.Q:Value()
local HarassW = KoreanMechanics.Harass.W:Value()
local HarassE = KoreanMechanics.Harass.E:Value()
if (myHero.mana/myHero.maxMana >= KoreanMechanics.Harass.Mana:Value() / 100) then
	if HarassE and Ready(_E) then
		if target.valid and Ready(_E) and target:GetCollision(self.Spells.E.width, self.Spells.E.speed, self.Spells.E.delay) == 0 and target.distance <= 1.1 * self.Spells.E.range then
  			 local Epos = target:GetPrediction(self.Spells.E.speed, self.Spells.E.delay)
      			if Epos and GetDistance(Epos,myHero.pos) < self.Spells.E.range then
        			 Control.CastSpell(HK_E, Epos)
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
		if HarrasW and Ready(_W) then
			if IsValidTarget(target, self.Spells.W.range, true, myHero) and Ready(_W) then
				Control.CastSpell(HK_W, target)
			end 
		end
	elseif  HarassQ and Ready(_Q) then 
				if target.valid and Ready(_Q) and target.distance <= 1.1 * self.Spells.Q.range then
  			 		local Qpos = target:GetPrediction(self.Spells.Q.speed, self.Spells.Q.delay)
      				if Qpos and GetDistance(Qpos,myHero.pos) < self.Spells.Q.range then
        				 Control.CastSpell(HK_Q, Qpos)
     				end
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

function Ahri:KS()
local target = _G.SDK.TargetSelector:GetTarget(2000)
	if target == nil then return end
	if target then
local KSON = KoreanMechanics.KS.ON:Value()
local KSQ = KoreanMechanics.KS.Q:Value()
local KSW = KoreanMechanics.KS.W:Value()
local KSE = KoreanMechanics.KS.E:Value()
local KSR = KoreanMechanics.KS.R:Value()
local KSI = KoreanMechanics.KS.I:Value()
	for i = 1, Game.HeroCount() do
		if (myHero.mana/myHero.maxMana >= KoreanMechanics.KS.Mana:Value() / 100) then
			if KSON then 
				if KSE and target.valid and Ready(_E) and target:GetCollision(self.Spells.E.width, self.Spells.E.speed, self.Spells.E.delay) == 0 and target.distance <= 1.1 * self.Spells.E.range and target.isEnemy and not target.dead then
					if getdmg("E", target, myHero) > target.health and Ready(_E) then
  					local Epos = target:GetPrediction(self.Spells.E.speed, self.Spells.E.delay)
      					if Epos and GetDistance(Epos,myHero.pos) < self.Spells.E.range then
        				 	Control.CastSpell(HK_E, Epos)
     					end
     				end 
				end
				if KSQ and target.valid and Ready(_Q) and target.distance <= 1.1 * self.Spells.Q.range and target.isEnemy and not target.dead then
					if getdmg("Q", target, myHero)*2 > target.health and Ready(_Q) then
					local Qpos = target:GetPrediction(self.Spells.Q.speed, self.Spells.Q.delay)
						if Qpos and GetDistance(Qpos,myHero.pos) < self.Spells.Q.range then
							Control.CastSpell(HK_Q, Qpos)
						end
					end
				end
				if KSW and IsValidTarget(target, self.Spells.W.range, true, myHero) and Ready(_W) and target.isEnemy and not target.dead then
					if getdmg("W", target, myHero)*3 > target.health and Ready(_W) then
						Control.CastSpell(HK_W, target)
					end 
				end
				if KSR and IsValidTarget(target, self.Spells.R.range, true, myHero) and Ready(_R) then 
					if getdmg("R", target, myHero) > target.health and Ready(_R) and not Ready(_Q) and not Ready(_E) then
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
end


function Ahri:Draw()
	if not myHero.dead then
		if KoreanMechanics.Draw.Enabled:Value() then 
			if KoreanMechanics.Draw.Q:Value() then
			Draw.Circle(myHero.pos, self.Spells.Q.range, 1, Draw.Color(255, 52, 221, 221))
			end
			if KoreanMechanics.Draw.W:Value() then
			Draw.Circle(myHero.pos, self.Spells.W.range, 1, Draw.Color(255, 255, 255, 255))
			end
			if KoreanMechanics.Draw.E:Value() then
			Draw.Circle(myHero.pos, self.Spells.E.range, 1, Draw.Color(255, 255, 0, 128))
			end
			if KoreanMechanics.Draw.R:Value() then
			Draw.Circle(myHero.pos, self.Spells.R.range, 1, Draw.Color(255, 000, 255, 000))
		end
	end
end
end

class "Darius"

function Darius:__init()
	print("Korean Mechanics Reborn | Darius Loaded succesfully")
	self.Icons =  { Q = "http://static.lolskill.net/img/abilities/64/Darius_Icon_Decimate.png",
				  	W = "http://static.lolskill.net/img/abilities/64/Darius_Icon_Hamstring.png",
				  	E = "http://static.lolskill.net/img/abilities/64/Darius_Icon_Axe_Grab.png",
				  	R = "http://static.lolskill.net/img/abilities/64/Darius_Icon_Sudden_Death.png"}
	self.Spells = {
		Q = {range = 425, delay = 0.75, speed = 2200, width = 450},
		W = {range = 200, delay = 0.25, speed = math.huge}, --ITS OVER 9000!!!!
		E = {range = 535, delay = 0.32, speed = 2000, width = 125, collision = true},
		R = {range = 460, delay = 0.85, speed = 3200},
	}
	self:Menu()
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
end

function Darius:Menu()
	KoreanMechanics.Combo:MenuElement({id = "Q", name = "Use Decimate (Q)", value = true, leftIcon = self.Icons.Q})
	KoreanMechanics.Combo:MenuElement({id = "W", name = "Use Crippling Strike (W)", value = true, leftIcon = self.Icons.W})
	KoreanMechanics.Combo:MenuElement({id = "E", name = "Use Apprehend (E)", value = true, leftIcon = self.Icons.E})
	KoreanMechanics.Combo:MenuElement({id = "R", name = "Use Noxian Guillotine (R) [?]", value = true, tooltip = "Uses smart-R when Killable", leftIcon = self.Icons.R})
	KoreanMechanics.Combo:MenuElement({id = "I", name = "Use Ignite", value = true, leftIcon = "http://static.lolskill.net/img/spells/32/14.png"})
	KoreanMechanics.Combo:MenuElement({id = "ION", name = "Enable custom Ignite Settings", value = false})
	KoreanMechanics.Combo:MenuElement({id = "IFAST", name = "Use Ignite when target HP%", value = 50, min = 0, max = 100, step = 1})
	KoreanMechanics.Combo:MenuElement({type = MENU, id = "IT", name = "Items", leftIcon = "http://1.1m.yt/r1_D68r.png" })
	KoreanMechanics.Combo.IT:MenuElement({id = "YG", name = "Use Youmuu's Ghostblade", value = true, leftIcon = "http://static.lolskill.net/img/items/32/3142.png"})
	KoreanMechanics.Combo.IT:MenuElement({id = "YGR", name = "Use Ghostblade when target distance", value = 1500, min = 0, max = 2500, step = 100})
	KoreanMechanics.Combo.IT:MenuElement({id = "T", name = "Use Tiamat", value = true, leftIcon = "http://static.lolskill.net/img/items/32/3077.png"})
	KoreanMechanics.Combo.IT:MenuElement({id = "TH", name = "Use Titanic Hydra", value = true, leftIcon = "http://static.lolskill.net/img/items/32/3748.png"})
	KoreanMechanics.Combo.IT:MenuElement({id = "RH", name = "Use Ravenous Hydra", value = true, leftIcon = "http://static.lolskill.net/img/items/32/3074.png"})

	KoreanMechanics.Harass:MenuElement({id = "Q", name = "Use Decimate (Q)", value = true, leftIcon = self.Icons.Q})
	KoreanMechanics.Harass:MenuElement({id = "W", name = "Use Crippling Strike (W)", value = true, leftIcon = self.Icons.W})
	KoreanMechanics.Harass:MenuElement({id = "E", name = "Use Apprehend (E)", value = true, leftIcon = self.Icons.E})
	KoreanMechanics.Harass:MenuElement({type = MENU, id = "IT", name = "Items", leftIcon = "http://1.1m.yt/r1_D68r.png" })
	KoreanMechanics.Harass.IT:MenuElement({id = "T", name = "Use Tiamat", value = true, leftIcon = "http://static.lolskill.net/img/items/32/3077.png"})
	KoreanMechanics.Harass.IT:MenuElement({id = "TH", name = "Use Titanic Hydra", value = true, leftIcon = "http://static.lolskill.net/img/items/32/3748.png"})
	KoreanMechanics.Harass.IT:MenuElement({id = "RH", name = "Use Ravenous Hydra", value = true, leftIcon = "http://static.lolskill.net/img/items/32/3074.png"})
	KoreanMechanics.Harass:MenuElement({type = MENU, id = "MM", name = "Mana Manager"})
	KoreanMechanics.Harass.MM:MenuElement({id = "QMana", name = "Min Mana to Q in Harass(%)", value = 40, min = 0, max = 100, step = 1, leftIcon = self.Icons.Q})
	KoreanMechanics.Harass.MM:MenuElement({id = "WMana", name = "Min Mana to W in Harass(%)", value = 40, min = 0, max = 100, step = 1, leftIcon = self.Icons.W})
	KoreanMechanics.Harass.MM:MenuElement({id = "EMana", name = "Min Mana to E in Harass(%)", value = 40, min = 0, max = 100, step = 1, leftIcon = self.Icons.E})

	KoreanMechanics.Clear:MenuElement({id = "Q", name = "Use Decimate (Q)", value = true, leftIcon = self.Icons.Q})
	KoreanMechanics.Clear:MenuElement({id = "QC", name = "Min amount of minions to Q", value = 3, min = 1, max = 7, step = 1})
	KoreanMechanics.Clear:MenuElement({id = "W", name = "Use Crippling Strike (W)", value = false, leftIcon = self.Icons.W})
	KoreanMechanics.Clear:MenuElement({id = "Mana", name = "Min Mana to Clear (%)", value = 40, min = 0, max = 100, step = 1})

	KoreanMechanics.KS:MenuElement({id = "ON", name = "Enable Free Elo [?]", value = true, tooltip = "Enable Smart-R to Killsteal"})
	KoreanMechanics.KS:MenuElement({id = "XX", name = "Dmg Calculate Factor [?]", value = 1.5, min = 0, max = 2.0, step = 0.05, tooltip = "Turn down with 0.05 only if u miss ults"})

	KoreanMechanics.Draw:MenuElement({id = "Enabled", name = "Enable Drawings", value = true})
	KoreanMechanics.Draw:MenuElement({id = "Q", name = "Draw Q", value = true, leftIcon = self.Icons.Q})
	KoreanMechanics.Draw:MenuElement({id = "W", name = "Draw W", value = true, leftIcon = self.Icons.W})
	KoreanMechanics.Draw:MenuElement({id = "E", name = "Draw E", value = true, leftIcon = self.Icons.E})
	KoreanMechanics.Draw:MenuElement({id = "R", name = "Draw R", value = true, leftIcon = self.Icons.R})
	KoreanMechanics.Draw:MenuElement({id = "DMG", name = "Draw R-DMG", value = true})

end

function Darius:Tick()
	if myHero.dead then return end

	local target = _G.SDK.TargetSelector:GetTarget(1000)
	local Rdmg = GetDariusRdmg(target)
	if target and _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_COMBO] then
		self:Combo(target)
	elseif target and _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_HARASS]  then
		self:Harass(target)
	elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_LANECLEAR] then
		self:Clear()
	elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_JUNGLECLEAR] then
		self:Clear()
	end
 	self:KS()
end 

function Darius:Combo(target)
local target = _G.SDK.TargetSelector:GetTarget(1000)
	if target == nil then return end
	if target then
local ComboQ = KoreanMechanics.Combo.Q:Value()
local ComboW = KoreanMechanics.Combo.W:Value()
local ComboE = KoreanMechanics.Combo.E:Value()
local ComboR = KoreanMechanics.Combo.R:Value()
local ComboI = KoreanMechanics.Combo.I:Value()
local ComboION = KoreanMechanics.Combo.ION:Value()
local ComboIFAST = KoreanMechanics.Combo.IFAST:Value()
local ComboYG = KoreanMechanics.Combo.IT.YG:Value()
local ComboYGR = KoreanMechanics.Combo.IT.YGR:Value()
local ComboT = KoreanMechanics.Combo.IT.T:Value()
local ComboTH = KoreanMechanics.Combo.IT.TH:Value()
local ComboRH = KoreanMechanics.Combo.IT.RH:Value()
local Rdmg = GetDariusRdmg(target)
	-- yg - E - AA - tiamat if possible - W reset Aa - R 
	if ComboR and Ready(_R) then
		if IsValidTarget(target, self.Spells.R.range, true, myHero) and Ready(_R) and Rdmg > target.health and not target.isImmortal and not target.isDead then 
			Control.CastSpell(HK_R, target)
		end
	end
	if ComboYG and target.distance <= ComboYGR and GetItemSlot(myHero, 3142) > 0  then
		if myHero:GetItemData(ITEM_1).itemID == 3142 and Ready(ITEM_1) then
			Control.CastSpell(HK_ITEM_1)
	elseif myHero:GetItemData(ITEM_2).itemID == 3142 and Ready(ITEM_2) then
			Control.CastSpell(HK_ITEM_2)
	elseif myHero:GetItemData(ITEM_3).itemID == 3142 and Ready(ITEM_3) then
			Control.CastSpell(HK_ITEM_3)
	elseif myHero:GetItemData(ITEM_4).itemID == 3142 and Ready(ITEM_4) then
			Control.CastSpell(HK_ITEM_4)
	elseif myHero:GetItemData(ITEM_5).itemID == 3142 and Ready(ITEM_5) then
			Control.CastSpell(HK_ITEM_5)
	elseif myHero:GetItemData(ITEM_6).itemID == 3142 and Ready(ITEM_6) then
			Control.CastSpell(HK_ITEM_6)
		end	
	end
		if ComboE and Ready(_E) then 
			if target.valid and Ready(_E) and target.distance <= 1.025 * self.Spells.E.range then 
			local Epos = target:GetPrediction(self.Spells.E.speed, self.Spells.E.delay)
				if Epos and GetDistance(Epos, myHero.pos) < self.Spells.E.range  then 
					Control.CastSpell(HK_E, Epos)
				end
			end
			if ComboT and GetItemSlot(myHero, 3077) > 0 and target.distance < 350 and Rdmg < target.health then
				if myHero:GetItemData(ITEM_1).itemID == 3077 and Ready(ITEM_1) then
					Control.CastSpell(HK_ITEM_1, target)
			elseif myHero:GetItemData(ITEM_2).itemID == 3077 and Ready(ITEM_2) then
					Control.CastSpell(HK_ITEM_2, target)
			elseif myHero:GetItemData(ITEM_3).itemID == 3077 and Ready(ITEM_3) then
					Control.CastSpell(HK_ITEM_3, target)
			elseif myHero:GetItemData(ITEM_4).itemID == 3077 and Ready(ITEM_4) then
					Control.CastSpell(HK_ITEM_4, target)
			elseif myHero:GetItemData(ITEM_5).itemID == 3077 and Ready(ITEM_5) then
					Control.CastSpell(HK_ITEM_5, target)
			elseif myHero:GetItemData(ITEM_6).itemID == 3077 and Ready(ITEM_6) then
					Control.CastSpell(HK_ITEM_6, target)
				end	
			end
			if ComboTH and GetItemSlot(myHero, 3748) > 0  and target.distance < 650 and Rdmg < target.health then
				if myHero:GetItemData(ITEM_1).itemID == 3748 and Ready(ITEM_1) then
					Control.CastSpell(HK_ITEM_1, target)
			elseif myHero:GetItemData(ITEM_2).itemID == 3748 and Ready(ITEM_2) then
					Control.CastSpell(HK_ITEM_2, target)
			elseif myHero:GetItemData(ITEM_3).itemID == 3748 and Ready(ITEM_3) then
					Control.CastSpell(HK_ITEM_3, target)
			elseif myHero:GetItemData(ITEM_4).itemID == 3748 and Ready(ITEM_4) then
					Control.CastSpell(HK_ITEM_4, target)
			elseif myHero:GetItemData(ITEM_5).itemID == 3748 and Ready(ITEM_5) then
					Control.CastSpell(HK_ITEM_5, target)
			elseif myHero:GetItemData(ITEM_6).itemID == 3748 and Ready(ITEM_6) then
					Control.CastSpell(HK_ITEM_6, target)
				end	
			end
			if ComboRH and GetItemSlot(myHero, 3074) > 0 and target.distance < 350 and Rdmg < target.health then
				if myHero:GetItemData(ITEM_1).itemID == 3074 and Ready(ITEM_1) then
					Control.CastSpell(HK_ITEM_1, target)
			elseif myHero:GetItemData(ITEM_2).itemID == 3074 and Ready(ITEM_2) then
					Control.CastSpell(HK_ITEM_2, target)
			elseif myHero:GetItemData(ITEM_3).itemID == 3074 and Ready(ITEM_3) then
					Control.CastSpell(HK_ITEM_3, target)
			elseif myHero:GetItemData(ITEM_4).itemID == 3074 and Ready(ITEM_4) then
					Control.CastSpell(HK_ITEM_4, target)
			elseif myHero:GetItemData(ITEM_5).itemID == 3074 and Ready(ITEM_5) then
					Control.CastSpell(HK_ITEM_5, target)
			elseif myHero:GetItemData(ITEM_6).itemID == 3074 and Ready(ITEM_6) then
					Control.CastSpell(HK_ITEM_6, target)
				end	
			end
			if ComboW and Ready(_W) then 
				if target.valid and target.distance <= 300 and Ready(_W) and Rdmg < target.health then 
					Control.CastSpell(HK_W, target)
				end
			end
			if ComboQ and Ready(_Q) then 
				if target.valid and target.distance <= 1.1 * self.Spells.Q.range and target.distance > 150 and Ready(_Q) then
					Control.CastSpell(HK_Q, target)
				end
			end
			if ComboR and Ready(_R) then
				if IsValidTarget(target, self.Spells.R.range, true, myHero) and Ready(_R) and Rdmg > target.health and not target.isImmortal and not target.isDead then 
					Control.CastSpell(HK_R, target)
				end
			end
	elseif ComboW and Ready(_W)  then 
			if target.valid and target.distance <= 300 and Ready(_W) then 
				Control.CastSpell(HK_W, target)
			end
			if ComboQ and Ready(_Q) then 
				if target.valid and target.distance <= 1.1 * self.Spells.Q.range and target.distance > 150 and Ready(_Q) then
					Control.CastSpell(HK_Q, target)
				end
			end
			if ComboR and Ready(_R) then
				if IsValidTarget(target, self.Spells.R.range, true, myHero) and Ready(_R) and Rdmg > target.health and not target.isImmortal and not target.isDead then 
					Control.CastSpell(HK_R, target)
				end
			end
	else
		if ComboQ and Ready(_Q) and Rdmg < target.health  then 
			if target.valid and target.distance <= 1.05 * self.Spells.Q.range and target.distance > 150 and Ready(_Q) then
				Control.CastSpell(HK_Q, target)
			end
		end
		if ComboR and Ready(_R) then
			if IsValidTarget(target, self.Spells.R.range, true, myHero) and Ready(_R) and Rdmg > target.health and not target.isImmortal and not target.isDead then 
				Control.CastSpell(HK_R, target)
			end
		end
	end
	if  ComboT and GetItemSlot(myHero, 3077) > 0 and target.distance < 350 then
		if myHero:GetItemData(ITEM_1).itemID == 3077 and Ready(ITEM_1) then
			Control.CastSpell(HK_ITEM_1, target)
	elseif myHero:GetItemData(ITEM_2).itemID == 3077 and Ready(ITEM_2) then
			Control.CastSpell(HK_ITEM_2, target)
	elseif myHero:GetItemData(ITEM_3).itemID == 3077 and Ready(ITEM_3) then
			Control.CastSpell(HK_ITEM_3, target)
	elseif myHero:GetItemData(ITEM_4).itemID == 3077 and Ready(ITEM_4) then
			Control.CastSpell(HK_ITEM_4, target)
	elseif myHero:GetItemData(ITEM_5).itemID == 3077 and Ready(ITEM_5) then
			Control.CastSpell(HK_ITEM_5, target)
	elseif myHero:GetItemData(ITEM_6).itemID == 3077 and Ready(ITEM_6) then
			Control.CastSpell(HK_ITEM_6, target)
		end	
	end
	if ComboTH and GetItemSlot(myHero, 3748) > 0 and target.distance <650 then
		if myHero:GetItemData(ITEM_1).itemID == 3748 and Ready(ITEM_1) then
			Control.CastSpell(HK_ITEM_1, target)
	elseif myHero:GetItemData(ITEM_2).itemID == 3748 and Ready(ITEM_2) then
			Control.CastSpell(HK_ITEM_2, target)
	elseif myHero:GetItemData(ITEM_3).itemID == 3748 and Ready(ITEM_3) then
			Control.CastSpell(HK_ITEM_3, target)
	elseif myHero:GetItemData(ITEM_4).itemID == 3748 and Ready(ITEM_4) then
			Control.CastSpell(HK_ITEM_4, target)
	elseif myHero:GetItemData(ITEM_5).itemID == 3748 and Ready(ITEM_5) then
			Control.CastSpell(HK_ITEM_5, target)
	elseif myHero:GetItemData(ITEM_6).itemID == 3748 and Ready(ITEM_6) then
			Control.CastSpell(HK_ITEM_6, target)
		end	
	end
	if ComboRH and GetItemSlot(myHero, 3074) > 0 and target.distance < 350 then
		if myHero:GetItemData(ITEM_1).itemID == 3074 and Ready(ITEM_1) then
			Control.CastSpell(HK_ITEM_1, target)
	elseif myHero:GetItemData(ITEM_2).itemID == 3074 and Ready(ITEM_2) then
			Control.CastSpell(HK_ITEM_2, target)
	elseif myHero:GetItemData(ITEM_3).itemID == 3074 and Ready(ITEM_3) then
			Control.CastSpell(HK_ITEM_3, target)
	elseif myHero:GetItemData(ITEM_4).itemID == 3074 and Ready(ITEM_4) then
			Control.CastSpell(HK_ITEM_4, target)
	elseif myHero:GetItemData(ITEM_5).itemID == 3074 and Ready(ITEM_5) then
			Control.CastSpell(HK_ITEM_5, target)
	elseif myHero:GetItemData(ITEM_6).itemID == 3074 and Ready(ITEM_6) then
			Control.CastSpell(HK_ITEM_6, target)
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
		if IsValidTarget(target, 600, true, myHero) and 50+20*myHero.levelData.lvl > target.health*1.1 then
			Control.CastSpell(HK_SUMMONER_1, target)
		end
elseif ComboI and myHero:GetSpellData(SUMMONER_2).name == "SummonerDot" and Ready(SUMMONER_2) and not Ready(_Q)  and not Ready(_R)  then
		if IsValidTarget(target, 600, true, myHero) and 50+20*myHero.levelData.lvl > target.health*1.1 then
			Control.CastSpell(HK_SUMMONER_2, target)
		end
	end
end
end

function Darius:Harass(target)
local target = _G.SDK.TargetSelector:GetTarget(1000)
	if target == nil then return end
	if target then
local HarassQ = KoreanMechanics.Harass.Q:Value()
local HarassW = KoreanMechanics.Harass.W:Value()
local HarassE = KoreanMechanics.Harass.E:Value()
local HarassT = KoreanMechanics.Harass.IT.T:Value()
local HarassTH = KoreanMechanics.Harass.IT.TH:Value()
local HarassRH = KoreanMechanics.Harass.IT.RH:Value()
local HarassQMana = KoreanMechanics.Harass.MM.QMana:Value()
local HarassWMana = KoreanMechanics.Harass.MM.WMana:Value()
local HarassEMana = KoreanMechanics.Harass.MM.EMana:Value()
		if HarassE and Ready(_E) then
			if target.valid and Ready(_E) and target.distance <= 1.1* self.Spells.E.range then 
			local Epos = target:GetPrediction(self.Spells.E.speed, self.Spells.E.delay)
				if Epos and GetDistance(Epos, myHero.pos) < self.Spells.E.range then 
					Control.CastSpell(HK_E, Epos)
				end
			end
			if  HarassT and GetItemSlot(myHero, 3077) > 0 and target.distance < 350 then
				if myHero:GetItemData(ITEM_1).itemID == 3077 and Ready(ITEM_1) then
					Control.CastSpell(HK_ITEM_1, target)
			elseif myHero:GetItemData(ITEM_2).itemID == 3077 and Ready(ITEM_2) then
					Control.CastSpell(HK_ITEM_2, target)
			elseif myHero:GetItemData(ITEM_3).itemID == 3077 and Ready(ITEM_3) then
					Control.CastSpell(HK_ITEM_3, target)
			elseif myHero:GetItemData(ITEM_4).itemID == 3077 and Ready(ITEM_4) then
					Control.CastSpell(HK_ITEM_4, target)
			elseif myHero:GetItemData(ITEM_5).itemID == 3077 and Ready(ITEM_5) then
					Control.CastSpell(HK_ITEM_5, target)
			elseif myHero:GetItemData(ITEM_6).itemID == 3077 and Ready(ITEM_6) then
					Control.CastSpell(HK_ITEM_6, target)
				end	
			end
			if HarassTH and GetItemSlot(myHero, 3748) > 0 and target.distance < 650 then
				if myHero:GetItemData(ITEM_1).itemID == 3748 and Ready(ITEM_1) then
					Control.CastSpell(HK_ITEM_1, target)
			elseif myHero:GetItemData(ITEM_2).itemID == 3748 and Ready(ITEM_2) then
					Control.CastSpell(HK_ITEM_2, target)
			elseif myHero:GetItemData(ITEM_3).itemID == 3748 and Ready(ITEM_3) then
					Control.CastSpell(HK_ITEM_3, target)
			elseif myHero:GetItemData(ITEM_4).itemID == 3748 and Ready(ITEM_4) then
					Control.CastSpell(HK_ITEM_4, target)
			elseif myHero:GetItemData(ITEM_5).itemID == 3748 and Ready(ITEM_5) then
					Control.CastSpell(HK_ITEM_5, target)
			elseif myHero:GetItemData(ITEM_6).itemID == 3748 and Ready(ITEM_6) then
					Control.CastSpell(HK_ITEM_6, target)
				end	
			end
			if HarassRH and GetItemSlot(myHero, 3074) > 0 and target.distance < 350 then
				if myHero:GetItemData(ITEM_1).itemID == 3074 and Ready(ITEM_1) then
					Control.CastSpell(HK_ITEM_1, target)
			elseif myHero:GetItemData(ITEM_2).itemID == 3074 and Ready(ITEM_2) then
					Control.CastSpell(HK_ITEM_2, target)
			elseif myHero:GetItemData(ITEM_3).itemID == 3074 and Ready(ITEM_3) then
					Control.CastSpell(HK_ITEM_3, target)
			elseif myHero:GetItemData(ITEM_4).itemID == 3074 and Ready(ITEM_4) then
					Control.CastSpell(HK_ITEM_4, target)
			elseif myHero:GetItemData(ITEM_5).itemID == 3074 and Ready(ITEM_5) then
					Control.CastSpell(HK_ITEM_5, target)
			elseif myHero:GetItemData(ITEM_6).itemID == 3074 and Ready(ITEM_6) then
					Control.CastSpell(HK_ITEM_6, target)
				end	
			end
			if HarassW and Ready(_W) then 
				if target.valid and target.distance <= 300 and Ready(_W) then 
					Control.CastSpell(HK_W)
				end
			end
			if ComboQ and Ready(_Q) and not Ready(_E) and target.distance > 150 then 
				if target.valid and target.distance <= 1.1 * self.Spells.Q.range and Ready(_Q) then
					Control.CastSpell(HK_Q)
				end
			end
	elseif HarassW and Ready(_W) then 
			if target.valid and target.distance <= 300 and Ready(_W) then 
				Control.CastSpell(HK_W, target)
			end
			if HarassQ and Ready(_Q) and target.distance > 150 then 
				if target.valid and target.distance <= 1.1 * self.Spells.Q.range and Ready(_Q) then
					Control.CastSpell(HK_Q)
				end
			end
	else
		if HarassQ and Ready(_Q) and target.distance > 150 then 
			if target.valid and target.distance <= 1.05 * self.Spells.Q.range and Ready(_Q) then
				Control.CastSpell(HK_Q)
			end
		end
	end
	if  HarassT and GetItemSlot(myHero, 3077) > 0 and target.distance < 350 then
		if myHero:GetItemData(ITEM_1).itemID == 3077 and Ready(ITEM_1) then
			Control.CastSpell(HK_ITEM_1, target)
	elseif myHero:GetItemData(ITEM_2).itemID == 3077 and Ready(ITEM_2) then
			Control.CastSpell(HK_ITEM_2, target)
	elseif myHero:GetItemData(ITEM_3).itemID == 3077 and Ready(ITEM_3) then
			Control.CastSpell(HK_ITEM_3, target)
	elseif myHero:GetItemData(ITEM_4).itemID == 3077 and Ready(ITEM_4) then
			Control.CastSpell(HK_ITEM_4, target)
	elseif myHero:GetItemData(ITEM_5).itemID == 3077 and Ready(ITEM_5) then
			Control.CastSpell(HK_ITEM_5, target)
	elseif myHero:GetItemData(ITEM_6).itemID == 3077 and Ready(ITEM_6) then
			Control.CastSpell(HK_ITEM_6, target)
			end	
	end
	if HarassTH and GetItemSlot(myHero, 3748) > 0 and target.distance < 650 then
		if myHero:GetItemData(ITEM_1).itemID == 3748 and Ready(ITEM_1) then
			Control.CastSpell(HK_ITEM_1, target)
	elseif myHero:GetItemData(ITEM_2).itemID == 3748 and Ready(ITEM_2) then
			Control.CastSpell(HK_ITEM_2, target)
	elseif myHero:GetItemData(ITEM_3).itemID == 3748 and Ready(ITEM_3) then
			Control.CastSpell(HK_ITEM_3, target)
	elseif myHero:GetItemData(ITEM_4).itemID == 3748 and Ready(ITEM_4) then
			Control.CastSpell(HK_ITEM_4, target)
	elseif myHero:GetItemData(ITEM_5).itemID == 3748 and Ready(ITEM_5) then
			Control.CastSpell(HK_ITEM_5, target)
	elseif myHero:GetItemData(ITEM_6).itemID == 3748 and Ready(ITEM_6) then
			Control.CastSpell(HK_ITEM_6, target)
		end	
	end
	if HarassRH and GetItemSlot(myHero, 3074) > 0 and target.distance < 350 then
		if myHero:GetItemData(ITEM_1).itemID == 3074 and Ready(ITEM_1) then
			Control.CastSpell(HK_ITEM_1, target)
	elseif myHero:GetItemData(ITEM_2).itemID == 3074 and Ready(ITEM_2) then
			Control.CastSpell(HK_ITEM_2, target)
	elseif myHero:GetItemData(ITEM_3).itemID == 3074 and Ready(ITEM_3) then
			Control.CastSpell(HK_ITEM_3, target)
	elseif myHero:GetItemData(ITEM_4).itemID == 3074 and Ready(ITEM_4) then
			Control.CastSpell(HK_ITEM_4, target)
	elseif myHero:GetItemData(ITEM_5).itemID == 3074 and Ready(ITEM_5) then
			Control.CastSpell(HK_ITEM_5, target)
	elseif myHero:GetItemData(ITEM_6).itemID == 3074 and Ready(ITEM_6) then
			Control.CastSpell(HK_ITEM_6, target)
		end	
	end	 	
end
end

function Darius:Clear()
local ClearQ = KoreanMechanics.Clear.Q:Value()
local ClearQC = KoreanMechanics.Clear.QC:Value()
local ClearW = KoreanMechanics.Clear.W:Value()
local ClearMana = KoreanMechanics.Clear.Mana:Value()
local GetEnemyMinions = GetEnemyMinions()
local Minions = nil
	for i = 1, #GetEnemyMinions do
	local Minions = GetEnemyMinions[i]
	local Count = MinionsAround(Minions.pos, 300, Minions.team)
	if (myHero.mana/myHero.maxMana >= ClearMana / 100) then
		if ClearQ and Ready(_Q) then 
			if Count >= ClearQC and Minions.distance < self.Spells.Q.range and getdmg("Q", Minions, myHero) > Minions.health then 
				Control.CastSpell(HK_Q, target)
			end
		end
		if ClearW and Ready(_W) then
			if Minions.distance < 300 and getdmg("E", Minions, myHero) > Minions.health then
				Control.CastSpell(HK_W, target)
			end
		end 
	end
end
end 

function Darius:KS(target)
local target = _G.SDK.TargetSelector:GetTarget(1000)
if target == nil then return end
if target then
local KSON = KoreanMechanics.KS.ON:Value()
	for i = 1, Game.HeroCount() do
		local target = Game.Hero(i)
		local Rdmg = (GetDariusRdmg(target))
		if KSON and IsValidTarget(target, self.Spells.R.range, true, myHero) and Ready(_R) and Rdmg > target.health and not target.isImmortal and not target.isDead then 
			Control.CastSpell(HK_R, target)
		end

	end
end
end 


function Darius:Draw()
	if not myHero.dead then
		if KoreanMechanics.Draw.Enabled:Value() then 
			local textPos = myHero.pos:To2D()
			if KoreanMechanics.Draw.Q:Value() then
			Draw.Circle(myHero.pos, self.Spells.Q.range, 1, Draw.Color(255, 52, 221, 221))
			end
			if KoreanMechanics.Draw.W:Value() then
			Draw.Circle(myHero.pos, self.Spells.W.range, 1, Draw.Color(255, 255, 255, 255))
			end
			if KoreanMechanics.Draw.E:Value() then
			Draw.Circle(myHero.pos, self.Spells.E.range, 1, Draw.Color(255, 255, 0, 128))
			end
			if KoreanMechanics.Draw.R:Value() then
			Draw.Circle(myHero.pos, self.Spells.R.range, 1, Draw.Color(255, 000, 255, 000))
			end
			if KoreanMechanics.Draw.DMG:Value() then
			local target = _G.SDK.TargetSelector:GetTarget(1000)
				if target == nil then return end
				if target then
					if  GetDariusRdmg(target) ~= nil and Ready(_R) then 
						Draw.Text("R DMG " .. tostring(math.floor(GetDariusRdmg(target))), 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 0, 0)) 
					end
				end
			end
		end
	end
end

class "Diana"

function Diana:__init()
	print("Korean Mechanics Reborn | Diana Loaded succesfully")
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
	KoreanMechanics.Combo:MenuElement({id = "Q", name = "Use Crescent Strike (Q)", value = true, leftIcon = self.Icons.Q})
	KoreanMechanics.Combo:MenuElement({id = "W", name = "Use Pale Cascade (W)", value = true, leftIcon = self.Icons.W})	
	KoreanMechanics.Combo:MenuElement({id = "E", name = "Use Moonfall (E)", value = true, leftIcon = self.Icons.E})
	KoreanMechanics.Combo:MenuElement({id = "R", name = "Use Lunar Rush (R)", value = true, leftIcon = self.Icons.R})
	KoreanMechanics.Combo:MenuElement({id = "Mode", name = "ComboMode [?]", drop = {"Normal", "Korean", "Misaya [Coming Soon]"}, tooltip = "Korean Combo Uses fast R"})
	KoreanMechanics.Combo:MenuElement({id = "I", name = "Use Ignite in Combo when Killable", value = true, leftIcon = "http://static.lolskill.net/img/spells/32/14.png"})
	KoreanMechanics.Combo:MenuElement({id = "ION", name = "Enable custom Ignite Settings", value = true})
	KoreanMechanics.Combo:MenuElement({id = "IFAST", name = "Uses Ignite when target hp%", value = 0.5, min = 0.1, max = 1, step = 0.01})

	KoreanMechanics.Harass:MenuElement({id = "Q", name = "Use Crescent Strike (Q)", value = true, leftIcon = self.Icons.Q})
	KoreanMechanics.Harass:MenuElement({id = "W", name = "Use Pale Cascade (W)", value = true, leftIcon = self.Icons.W})
	KoreanMechanics.Harass:MenuElement({id = "E", name = "Use Moonfall (E)", value = true, leftIcon = self.Icons.E})
	KoreanMechanics.Harass:MenuElement({id = "Mana", name = "Min. Mana for Harass(%)", value = 40, min = 0, max = 100, step = 1})

	KoreanMechanics.KS:MenuElement({id = "ON", name = "Enable KillSteal", value = true})
	KoreanMechanics.KS:MenuElement({id = "Q", name = "Use Q to KS", value = true, leftIcon = self.Icons.Q})
	KoreanMechanics.KS:MenuElement({id = "W", name = "Use W to KS", value = true, leftIcon = self.Icons.W})
	KoreanMechanics.KS:MenuElement({id = "R", name = "Use R to KS", value = true, leftIcon = self.Icons.R})
	KoreanMechanics.KS:MenuElement({id = "I", name = "Use Ignite to KS", value = true, leftIcon = "http://static.lolskill.net/img/spells/32/14.png"})
	KoreanMechanics.KS:MenuElement({id = "Mana", name = "Min. Mana to KillSteal(%)", value = 20, min = 0, max = 100, step = 1})

	KoreanMechanics.Draw:MenuElement({id = "Enabled", name = "Enable Drawings", value = true})
	KoreanMechanics.Draw:MenuElement({id = "Q", name = "Draw Q", value = true, leftIcon = self.Icons.Q})
	KoreanMechanics.Draw:MenuElement({id = "W", name = "Draw W", value = true, leftIcon = self.Icons.W})
	KoreanMechanics.Draw:MenuElement({id = "E", name = "Draw E", value = true, leftIcon = self.Icons.E})
	KoreanMechanics.Draw:MenuElement({id = "R", name = "Draw R", value = true, leftIcon = self.Icons.R})
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
end

function Diana:Combo(target) 
local level = myHero.levelData.lvl
local ComboQ = KoreanMechanics.Combo.Q:Value()
local ComboW = KoreanMechanics.Combo.W:Value()
local ComboE = KoreanMechanics.Combo.E:Value()
local ComboR = KoreanMechanics.Combo.R:Value() 
local ComboMode = KoreanMechanics.Combo.Mode:Value()
local ComboI = KoreanMechanics.Combo.I:Value()
local ComboION = KoreanMechanics.Combo.ION:Value()
local ComboIFAST = KoreanMechanics.Combo.IFAST:Value()
			if ComboMode == 1 or ComboMode == 2 then
				if ComboW and Ready(_W) then
					if IsValidTarget(target, self.Spells.W.range, true, myHero) and Ready(_W) then
						Control.CastSpell(HK_W, target)
					end
					if ComboE and Ready(_E) then 
     					if IsValidTarget(target, self.Spells.E.range, true, myHero) and Ready(_E) then
							Control.CastSpell(HK_E, target)
						end
					end
					if ComboQ and Ready(_Q) then
						if target.valid and Ready(_Q) and target.distance <= 1.1 * self.Spells.Q.range then
  						local Qpos = target:GetPrediction(self.Spells.Q.speed, self.Spells.Q.delay)
      						if Qpos and GetDistance(Qpos,myHero.pos) < self.Spells.Q.range then
        						Control.CastSpell(HK_Q, Qpos)
     						end
     					end
     				end
			elseif ComboE and Ready(_E) then
     				if IsValidTarget(target, self.Spells.E.range, true, myHero) and Ready(_E) then
						Control.CastSpell(HK_E, target)
						end
					end
					if ComboQ and Ready(_Q) then
						if target.valid and Ready(_Q) and target.distance <= 1.1 * self.Spells.Q.range then
  						local Qpos = target:GetPrediction(self.Spells.Q.speed, self.Spells.Q.delay)
      						if Qpos and GetDistance(Qpos,myHero.pos) < self.Spells.Q.range then
        						Control.CastSpell(HK_Q, Qpos)
     						end
     					end
     				end
			else
				if ComboQ and Ready(_Q) then
					if target.valid and Ready(_Q) and target.distance <= 1.1 * self.Spells.Q.range then
  					local Qpos = target:GetPrediction(self.Spells.Q.speed, self.Spells.Q.delay)
      					if Qpos and GetDistance(Qpos,myHero.pos) < self.Spells.Q.range then
        					Control.CastSpell(HK_Q, Qpos)
     					end
     				end
     			end
    		end
    			if ComboR and Ready(_R) then
    				if IsValidTarget(target, self.Spells.R.range, true, myHero) and target.isEnemy and HaveDianaBuff(target) and Ready(_R) then
    					Control.CastSpell(HK_R, target)
    				end
    			end
    			if ComboMode == 2  then
    				if ComboR and Ready(_R) then
    					if IsValidTarget(target, self.Spells.R.range, true, myHero) and target.isEnemy and HaveDianaBuff(target) and Ready(_R) then
    						Control.CastSpell(HK_R, target)
    					end
    				end
    				if ComboR and Ready(_R) then
    					if IsValidTarget(target, self.Spells.R.range, true, myHero) and target.isEnemy and Ready(_R) then
    						Control.CastSpell(HK_R, target)
    					end
    			elseif ComboR and Ready(_R) then
    					if IsValidTarget(target, self.Spells.R.range, true, myHero) and target.isEnemy and Ready(_R) then
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
					if IsValidTarget(target, 600, true, myHero) and 50+20*myHero.levelData.lvl > target.health*1.1 then
						Control.CastSpell(HK_SUMMONER_1, target)
					end
				elseif ComboI and myHero:GetSpellData(SUMMONER_2).name == "SummonerDot" and Ready(SUMMONER_2) and not Ready(_Q)  and not Ready(_R)  then
					if IsValidTarget(target, 600, true, myHero) and 50+20*myHero.levelData.lvl > target.health*1.1 then
					Control.CastSpell(HK_SUMMONER_2, target)
					end
				end

end


function Diana:Harass(target)
local HarassQ = KoreanMechanics.Harass.Q:Value()
local HarassW = KoreanMechanics.Harass.W:Value()
local HarassE = KoreanMechanics.Harass.E:Value() 
if (myHero.mana/myHero.maxMana >= KoreanMechanics.Harass.Mana:Value() / 100) then
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


function Diana:KS(target)
local target = _G.SDK.TargetSelector:GetTarget(2000)
	if target == nil then return end
	if target then
local KSON = KoreanMechanics.KS.ON:Value()
local KSQ = KoreanMechanics.KS.Q:Value()
local KSW = KoreanMechanics.KS.W:Value()
local KSR = KoreanMechanics.KS.R:Value()
local KSI = KoreanMechanics.KS.I:Value()
	for i = 1, Game.HeroCount() do
		if (myHero.mana/myHero.maxMana >= KoreanMechanics.KS.Mana:Value() / 100) then
			if KSON then
				if KSW and Ready(_W) then
					if IsValidTarget(target, self.Spells.W.range, true, myHero) and not target.isDead and Ready(_W) and target.isTargetable then
						if getdmg("W", target, myHero)*4 > target.health and Ready(_W) then
							Control.CastSpell(HK_W, target)
						end
					end
				end
				if KSQ and Ready(_Q) then
					if target.valid and target.isEnemy and Ready(_Q) and target.distance <= 1.1 * self.Spells.Q.range and not target.isDead and target.isTargetable then
  					local Qpos = target:GetPrediction(self.Spells.Q.speed, self.Spells.Q.delay)
      					if Qpos and GetDistance(Qpos,myHero.pos) < self.Spells.Q.range and getdmg("Q", target, myHero) > target.health then
        					Control.CastSpell(HK_Q, Qpos)
     					end
     				end
     			end
     			if KSR and Ready(_R) and not Ready(_Q) then 
     				if IsValidTarget(target, self.Spells.R.range, true, myHero) and getdmg("Q", target, myHero) > target.health and target.distance >= 300 and not target.isDead and Ready(_R) and target.isTargetable then
    					Control.CastSpell(HK_R, target)
    				end
    			end
    			if KSI and myHero:GetSpellData(SUMMONER_1).name == "SummonerDot" and Ready(SUMMONER_1) and not Ready(_Q) and not Ready(_W)  and not Ready(_R)  then
					if IsValidTarget(target, 600, true, myHero) and 50+20*myHero.levelData.lvl > target.health*1.1 then
						Control.CastSpell(HK_SUMMONER_1, target)
					end
				end
				if KSI and myHero:GetSpellData(SUMMONER_2).name == "SummonerDot" and Ready(SUMMONER_2) and not Ready(_Q) and not Ready(_W)  and not Ready(_R)  then
					if IsValidTarget(target, 600, true, myHero) and 50+20*myHero.levelData.lvl > target.health*1.1 then
						Control.CastSpell(HK_SUMMONER_2, target)
					end
				end
			end
		end
	end
	end
end

function Diana:Draw()
	if not myHero.dead then
		if KoreanMechanics.Draw.Enabled:Value() then 
			if KoreanMechanics.Draw.Q:Value() then
			Draw.Circle(myHero.pos, self.Spells.Q.range, 1, Draw.Color(255, 52, 221, 221))
			end
			if KoreanMechanics.Draw.W:Value() then
			Draw.Circle(myHero.pos, self.Spells.W.range, 1, Draw.Color(255, 255, 255, 255))
			end
			if KoreanMechanics.Draw.E:Value() then
			Draw.Circle(myHero.pos, self.Spells.E.range, 1, Draw.Color(255, 255, 0, 128))
			end
			if KoreanMechanics.Draw.R:Value() then
			Draw.Circle(myHero.pos, self.Spells.R.range, 1, Draw.Color(255, 000, 255, 000))
		end
	end
end
end

class "KogMaw"

function KogMaw:__init()
	print("Korean Mechanics Reborn | Kog'Maw Loaded succesfully")
	self.Icons =  { Q = "http://static.lolskill.net/img/abilities/64/KogMaw_CausticSpittle.png",
				  	W = "http://static.lolskill.net/img/abilities/64/KogMaw_BioArcaneBarrage.png",
				  	E = "http://static.lolskill.net/img/abilities/64/KogMaw_VoidOoze.png",
				  	R = "http://static.lolskill.net/img/abilities/64/KogMaw_LivingArtillery.png"}
	self.Spells = {
		Q = {range = 1175, delay = 0.25, speed = 1600,  width = 80},
		W = {range = 700, delay = 0.25, speed = math.huge}, --ITS OVER 9000!!!!
		E = {range = 1200, delay = 0.25, speed = 1000, width = 65, collision = false},
		R = {range = GetKogRange(), delay = 0.85, speed = math.huge},
		SummonerDot = {range = 600, dmg = 50+20*myHero.levelData.lvl}
	}
	self:Menu()
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
end

function KogMaw:Menu()
	KoreanMechanics.Combo:MenuElement({id = "Q", name = "Use Caustic Spittle (Q)", value = true, leftIcon = self.Icons.Q})
	KoreanMechanics.Combo:MenuElement({id = "W", name = "Use Bio-Arcane Barrage (W)", value = true, leftIcon = self.Icons.W})
	KoreanMechanics.Combo:MenuElement({id = "E", name = "Use Void Ooze (E)", value = true, leftIcon = self.Icons.E})
	KoreanMechanics.Combo:MenuElement({id = "R", name = "Use Living Artillery (R) [?]", value = true, tooltip = "Uses Smart-R when not in AA range", leftIcon = self.Icons.R})
	KoreanMechanics.Combo:MenuElement({id = "RHP", name = "Max Enemy HP to R in Combo(%)", value = 40, min = 0, max = 100, step = 1})
	KoreanMechanics.Combo:MenuElement({id = "Mode", name = "Combo Mode", drop = {"AP Combo", "AD Combo"}})
	KoreanMechanics.Combo:MenuElement({type = MENU, id = "IT", name = "Items" })
	KoreanMechanics.Combo.IT:MenuElement({id = "YG", name = "Use Youmuu's Ghostblade", value = true, leftIcon = "http://static.lolskill.net/img/items/32/3142.png"})
	KoreanMechanics.Combo.IT:MenuElement({id = "YGR", name = "Use Youmuu's Ghostblade when target distance", value = 1500, min = 0, max = 2500, step = 100})
	KoreanMechanics.Combo.IT:MenuElement({id = "BC", name = "Use Bilgewater Cutlass", value = true, leftIcon = "http://static.lolskill.net/img/items/32/3144.png"})
	KoreanMechanics.Combo.IT:MenuElement({id = "BCHP", name = "Max Enemy HP to BC in Combo(%)", value = 60, min = 0, max = 100, step = 1})
	KoreanMechanics.Combo.IT:MenuElement({id = "BOTRK", name = "Use Blade Of the Ruined King", value = true, leftIcon = "http://static.lolskill.net/img/items/32/3153.png"})
	KoreanMechanics.Combo.IT:MenuElement({id = "BOTRKHP", name = "Max Enemy HP to BOTRK in Combo(%)", value = 60, min = 0, max = 100, step = 1})
	KoreanMechanics.Combo:MenuElement({type = MENU, id = "MM", name = "Mana Manager"})
	KoreanMechanics.Combo.MM:MenuElement({id = "QMana", name = "Min Mana to Q in Combo(%)", value = 10, min = 0, max = 100, step = 1, leftIcon = self.Icons.Q})
	KoreanMechanics.Combo.MM:MenuElement({id = "WMana", name = "Min Mana to W in Combo(%)", value = 10, min = 0, max = 100, step = 1, leftIcon = self.Icons.W})
	KoreanMechanics.Combo.MM:MenuElement({id = "EMana", name = "Min Mana to E in Combo(%)", value = 10, min = 0, max = 100, step = 1, leftIcon = self.Icons.E})
	KoreanMechanics.Combo.MM:MenuElement({id = "RMana", name = "Min Mana to R in Combo(%)", value = 10, min = 0, max = 100, step = 1, leftIcon = self.Icons.R})

	KoreanMechanics.Harass:MenuElement({id = "Q", name = "Use Caustic Spittle (Q)", value = true, leftIcon = self.Icons.Q})
	KoreanMechanics.Harass:MenuElement({id = "W", name = "Use Bio-Arcane Barrage (W)", value = true, leftIcon = self.Icons.W})
	KoreanMechanics.Harass:MenuElement({id = "E", name = "Use Void Ooze (E)", value = true, leftIcon = self.Icons.E})
	KoreanMechanics.Harass:MenuElement({type = MENU, id = "MM", name = "Mana Manager"})
	KoreanMechanics.Harass.MM:MenuElement({id = "QMana", name = "Min Mana to Q in Harass(%)", value = 40, min = 0, max = 100, step = 1, leftIcon = self.Icons.Q})
	KoreanMechanics.Harass.MM:MenuElement({id = "WMana", name = "Min Mana to W in Harass(%)", value = 40, min = 0, max = 100, step = 1, leftIcon = self.Icons.W})
	KoreanMechanics.Harass.MM:MenuElement({id = "EMana", name = "Min Mana to E in Harass(%)", value = 40, min = 0, max = 100, step = 1, leftIcon = self.Icons.E})

	KoreanMechanics.Clear:MenuElement({id = "W", name = "Use Bio-Arcane Barrage (W)", value = true, leftIcon = self.Icons.W})
	KoreanMechanics.Clear:MenuElement({id = "WC", name = "Min amount of minions to W", value = 3, min = 1, max = 7, step = 1})
	KoreanMechanics.Clear:MenuElement({id = "R", name = "Use Living Artillery (R) [beta]", value = false, leftIcon = self.Icons.R})
	KoreanMechanics.Clear:MenuElement({id = "RC", name = "Min amount of minions to R", value = 3, min = 1, max = 7, step = 1})
	KoreanMechanics.Clear:MenuElement({type = MENU, id = "MM", name = "Mana Manager"})
	KoreanMechanics.Clear.MM:MenuElement({id = "WMana", name = "Min Mana to W in Clear(%)", value = 40, min = 0, max = 100, step = 1, leftIcon = self.Icons.W})
	KoreanMechanics.Clear.MM:MenuElement({id = "RMana", name = "Min Mana to R in Clear(%)", value = 40, min = 0, max = 100, step = 1, leftIcon = self.Icons.R})


--	KoreanMechanics.KS:MenuElement({id = "Q", name = "Use Q to KS", value = true, leftIcon = self.Icons.Q})
--  KoreanMechanics.KS:MenuElement({id = "W", name = "Use W to KS", value = true, leftIcon = self.Icons.W})
--	KoreanMechanics.KS:MenuElement({id = "E", name = "Use E to KS", value = true, leftIcon = self.Icons.E})
--	KoreanMechanics.KS:MenuElement({id = "R", name = "Use R to KS", value = true, leftIcon = self.Icons.R})
--	KoreanMechanics.KS:MenuElement({id = "Mana", name = "Min. Mana to KillSteal(%)", value = 20, min = 0, max = 100, step = 1})

	KoreanMechanics.Draw:MenuElement({id = "Enabled", name = "Enable Drawings", value = true})
	KoreanMechanics.Draw:MenuElement({id = "Q", name = "Draw Q", value = true, leftIcon = self.Icons.Q})
	KoreanMechanics.Draw:MenuElement({id = "W", name = "Draw W", value = true, leftIcon = self.Icons.W})
	KoreanMechanics.Draw:MenuElement({id = "E", name = "Draw E", value = true, leftIcon = self.Icons.E})
	KoreanMechanics.Draw:MenuElement({id = "R", name = "Draw R", value = true, leftIcon = self.Icons.R})

end

function KogMaw:Tick()
	if myHero.dead then return end

	local target = _G.SDK.TargetSelector:GetTarget(2000)
	if target and _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_COMBO] then
		self:Combo(target)
	elseif target and _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_HARASS] then
		self:Harass(target)
	elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_LANECLEAR] then
		self:Clear()
	elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_JUNGLECLEAR] then
		self:Clear()
	end
--	self:KS(target)
end

function KogMaw:Combo(target)
local ComboQ = KoreanMechanics.Combo.Q:Value()
local ComboW = KoreanMechanics.Combo.W:Value()
local ComboE = KoreanMechanics.Combo.E:Value()
local ComboR = KoreanMechanics.Combo.R:Value()
local ComboMode = KoreanMechanics.Combo.Mode:Value()
local ComboRHP = KoreanMechanics.Combo.RHP:Value()
local ComboYG = KoreanMechanics.Combo.IT.YG:Value()
local ComboYGR = KoreanMechanics.Combo.IT.YGR:Value()
local ComboBC = KoreanMechanics.Combo.IT.BC:Value()
local ComboBCHP = KoreanMechanics.Combo.IT.BCHP:Value()
local ComboBOTRK = KoreanMechanics.Combo.IT.BOTRK:Value()
local ComboBOTRKHP = KoreanMechanics.Combo.IT.BOTRKHP:Value()
local ComboQMana = KoreanMechanics.Combo.MM.QMana:Value()
local ComboWMana = KoreanMechanics.Combo.MM.WMana:Value()
local ComboEMana = KoreanMechanics.Combo.MM.EMana:Value()
local ComboRMana = KoreanMechanics.Combo.MM.RMana:Value()
	if ComboR and Ready(_R) and (myHero.mana/myHero.maxMana >= ComboRMana / 100) then
		if target.valid and target.distance < 1.1*GetKogRange() and target.distance >= 670 and (target.health/target.maxHealth) <= (ComboRHP/100) and Ready(_R) then
		local Rpos = target:GetPrediction(self.Spells.R.speed, self.Spells.R.delay)
			if Rpos and Rpos.onScreen and GetDistance(Rpos,myHero.pos) < GetKogRange() and Ready(_R) then
				Control.CastSpell(HK_R, Rpos)
			end
		end
	end
	if ComboYG and target.distance <= ComboYGR and GetItemSlot(myHero, 3142) > 0  then
		if myHero:GetItemData(ITEM_1).itemID == 3142 and Ready(ITEM_1) then
			Control.CastSpell(HK_ITEM_1)
	elseif myHero:GetItemData(ITEM_2).itemID == 3142 and Ready(ITEM_2) then
			Control.CastSpell(HK_ITEM_2)
	elseif myHero:GetItemData(ITEM_3).itemID == 3142 and Ready(ITEM_3) then
			Control.CastSpell(HK_ITEM_3)
	elseif myHero:GetItemData(ITEM_4).itemID == 3142 and Ready(ITEM_4) then
			Control.CastSpell(HK_ITEM_4)
	elseif myHero:GetItemData(ITEM_5).itemID == 3142 and Ready(ITEM_5) then
			Control.CastSpell(HK_ITEM_5)
	elseif myHero:GetItemData(ITEM_6).itemID == 3142 and Ready(ITEM_6) then
			Control.CastSpell(HK_ITEM_6)
		end	
	end
	if ComboBC and GetItemSlot(myHero, 3144) > 0 and (target.health/target.maxHealth) <= (ComboBCHP/100) and target.distance < 550 then
		if myHero:GetItemData(ITEM_1).itemID == 3144 and Ready(ITEM_1) then
			Control.CastSpell(HK_ITEM_1, target)
	elseif myHero:GetItemData(ITEM_2).itemID == 3144 and Ready(ITEM_2) then
			Control.CastSpell(HK_ITEM_2, target)
	elseif myHero:GetItemData(ITEM_3).itemID == 3144 and Ready(ITEM_3) then
			Control.CastSpell(HK_ITEM_3, target)
	elseif myHero:GetItemData(ITEM_4).itemID == 3144 and Ready(ITEM_4) then
			Control.CastSpell(HK_ITEM_4, target)
	elseif myHero:GetItemData(ITEM_5).itemID == 3144 and Ready(ITEM_5) then
			Control.CastSpell(HK_ITEM_5, target)
	elseif myHero:GetItemData(ITEM_6).itemID == 3144 and Ready(ITEM_6) then
			Control.CastSpell(HK_ITEM_6, target)
		end	
	end
	if ComboBOTRK and GetItemSlot(myHero, 3153) > 0 and (target.health/target.maxHealth) <= (ComboBOTRKHP/100) and target.distance < 550 then
		if myHero:GetItemData(ITEM_1).itemID == 3153 and Ready(ITEM_1) then
			Control.CastSpell(HK_ITEM_1, target)
	elseif myHero:GetItemData(ITEM_2).itemID == 3153 and Ready(ITEM_2) then
			Control.CastSpell(HK_ITEM_2, target)
	elseif myHero:GetItemData(ITEM_3).itemID == 3153 and Ready(ITEM_3) then
			Control.CastSpell(HK_ITEM_3, target)
	elseif myHero:GetItemData(ITEM_4).itemID == 3153 and Ready(ITEM_4) then
			Control.CastSpell(HK_ITEM_4, target)
	elseif myHero:GetItemData(ITEM_5).itemID == 3153 and Ready(ITEM_5) then
			Control.CastSpell(HK_ITEM_5, target)
	elseif myHero:GetItemData(ITEM_6).itemID == 3153 and Ready(ITEM_6) then
			Control.CastSpell(HK_ITEM_6, target)
		end	
	end
	if ComboMode == 1 then
		if ComboR and Ready(_R) and (myHero.mana/myHero.maxMana >= ComboRMana / 100) then
			if target.valid and target.distance < 1.1*GetKogRange() and target.distance >= 670 and (target.health/target.maxHealth) <= (ComboRHP/100) and Ready(_R) then
			local Rpos = target:GetPrediction(self.Spells.R.speed, self.Spells.R.delay)
				if Rpos and GetDistance(Rpos,myHero.pos) < GetKogRange() and Ready(_R) then
					Control.CastSpell(HK_R, Rpos)
				end
			end
			if ComboE and Ready(_E) then
				if target.valid and Ready(_E) and target.distance <= 1.05 * self.Spells.E.range and (myHero.mana/myHero.maxMana >= ComboEMana / 100) then
  				local Epos = target:GetPrediction(self.Spells.E.speed, self.Spells.E.delay)
	      			if Epos and GetDistance(Epos,myHero.pos) < self.Spells.E.range then
	        			Control.CastSpell(HK_E, Epos)
	     			end
				end
			end
			if ComboQ and Ready(_Q) then
				if target.valid and Ready(_Q) and target:GetCollision(self.Spells.Q.width, self.Spells.Q.speed, self.Spells.Q.delay) == 0 and target.distance <= 1.1 * self.Spells.Q.range and (myHero.mana/myHero.maxMana >= ComboQMana / 100) then
	  			local Qpos = target:GetPrediction(self.Spells.Q.speed, self.Spells.Q.delay)
	      			if Qpos and GetDistance(Qpos,myHero.pos) < self.Spells.Q.range then
	        			Control.CastSpell(HK_Q, Qpos)
	     			end
				end
			end
			if ComboW and Ready(_W) then
				if target.valid and Ready(_W) and target.distance <= 710 and (myHero.mana/myHero.maxMana >= ComboWMana / 100) then
					Control.CastSpell(HK_W, target)
				end 
			end
	elseif ComboE and Ready(_E) then
			if target.valid and Ready(_E) and target.distance <= 1.05 * self.Spells.E.range and (myHero.mana/myHero.maxMana >= ComboEMana / 100) then
  			local Epos = target:GetPrediction(self.Spells.E.speed, self.Spells.E.delay)
	      		if Epos and GetDistance(Epos,myHero.pos) < self.Spells.E.range then
	        		Control.CastSpell(HK_E, Epos)
	     		end
			end
			if ComboQ and Ready(_Q) then
				if target.valid and Ready(_Q) and target:GetCollision(self.Spells.Q.width, self.Spells.Q.speed, self.Spells.Q.delay) == 0 and target.distance <= 1.1 * self.Spells.Q.range and (myHero.mana/myHero.maxMana >= ComboQMana / 100) then
  				local Qpos = target:GetPrediction(self.Spells.Q.speed, self.Spells.Q.delay)
	      			if Qpos and GetDistance(Qpos,myHero.pos) < self.Spells.Q.range then
	        			 Control.CastSpell(HK_Q, Qpos)
	     			end
				end
			end
			if ComboW and Ready(_W) then
				if target.valid and Ready(_W) and target.distance <= 710 and (myHero.mana/myHero.maxMana >= ComboWMana / 100) then
					Control.CastSpell(HK_W, target)
				end 
			end
	elseif  ComboQ and Ready(_Q) then
			if target.valid and Ready(_Q) and target:GetCollision(self.Spells.Q.width, self.Spells.Q.speed, self.Spells.Q.delay) == 0 and target.distance <= 1.1 * self.Spells.Q.range and (myHero.mana/myHero.maxMana >= ComboQMana / 100) then
  			local Qpos = target:GetPrediction(self.Spells.Q.speed, self.Spells.Q.delay)
	      		if Qpos and GetDistance(Qpos,myHero.pos) < self.Spells.Q.range then
	        		Control.CastSpell(HK_Q, Qpos)
	     		end
			end
			if ComboW and Ready(_W) then
				if target.valid and Ready(_W) and target.distance <= 710 and (myHero.mana/myHero.maxMana >= ComboWMana / 100) then
					Control.CastSpell(HK_W, target)
				end 
			end
	else
		if ComboW and Ready(_W) then
			if target.valid and Ready(_W) and target.distance <= 710 and (myHero.mana/myHero.maxMana >= ComboWMana / 100)  then
				Control.CastSpell(HK_W, target)
			end 
		end
	end 
elseif ComboMode == 2 then 
		if  ComboR and Ready(_R) and (myHero.mana/myHero.maxMana >= ComboRMana / 100) then
			if target.valid and target.distance < 1.1*GetKogRange() and target.distance >= 670 and (target.health/target.maxHealth) <= (ComboRHP/100) and Ready(_R) then
			local Rpos = target:GetPrediction(self.Spells.R.speed, self.Spells.R.delay)
				if Rpos and GetDistance(Rpos,myHero.pos) < GetKogRange() and Ready(_R) then
					Control.CastSpell(HK_R, Rpos)
				end
			end
			if  ComboQ and Ready(_Q) then
				if target.valid and Ready(_Q) and target:GetCollision(self.Spells.Q.width, self.Spells.Q.speed, self.Spells.Q.delay) == 0 and target.distance <= 1.1 * self.Spells.Q.range and (myHero.mana/myHero.maxMana >= ComboQMana / 100) then
	  			local Qpos = target:GetPrediction(self.Spells.Q.speed, self.Spells.Q.delay)
	      			if Qpos and GetDistance(Qpos,myHero.pos) < self.Spells.Q.range then
	        			Control.CastSpell(HK_Q, Qpos)
	     			end
				end
			end
			if ComboW and Ready(_W) then
				if target.valid and Ready(_W) and target.distance <= 750 and (myHero.mana/myHero.maxMana >= ComboWMana / 100)  then
					Control.CastSpell(HK_W, target)
				end 
			end
			if ComboE and Ready(_E) then
				if target.valid and Ready(_E) and target.distance <= 1.05 * self.Spells.E.range and (myHero.mana/myHero.maxMana >= ComboEMana / 100) then
	  			local Epos = target:GetPrediction(self.Spells.E.speed, self.Spells.E.delay)
	      			if Epos and GetDistance(Epos,myHero.pos) < self.Spells.E.range then
	        			Control.CastSpell(HK_E, Epos)
	     			end
				end
			end
	elseif ComboQ and Ready(_Q) then
			if target.valid and Ready(_Q) and target:GetCollision(self.Spells.Q.width, self.Spells.Q.speed, self.Spells.Q.delay) == 0 and target.distance <= 1.1 * self.Spells.Q.range and (myHero.mana/myHero.maxMana >= ComboQMana / 100) then
	  		local Qpos = target:GetPrediction(self.Spells.Q.speed, self.Spells.Q.delay)
	      		if Qpos and GetDistance(Qpos,myHero.pos) < self.Spells.Q.range then
	        		Control.CastSpell(HK_Q, Qpos)
	     		end
			end
			if ComboW and Ready(_W) then
				if target.valid and Ready(_W) and target.distance <= 750 and (myHero.mana/myHero.maxMana >= ComboWMana / 100)  then
					Control.CastSpell(HK_W, target)
				end 
			end
			if ComboE and Ready(_E) then
				if target.valid and Ready(_E) and target.distance <= 1.05 * self.Spells.E.range and (myHero.mana/myHero.maxMana >= ComboEMana / 100) then
	  			local Epos = target:GetPrediction(self.Spells.E.speed, self.Spells.E.delay)
	      			if Epos and GetDistance(Epos,myHero.pos) < self.Spells.E.range then
	        			Control.CastSpell(HK_E, Epos)
	     			end
				end
			end
	elseif ComboW and Ready(_W) then
			if target.valid and Ready(_W) and target.distance <= 750 and (myHero.mana/myHero.maxMana >= ComboWMana / 100)  then
				Control.CastSpell(HK_W, target)
			end 
			if ComboE and Ready(_E) then
				if target.valid and Ready(_E) and target.distance <= 1.05 * self.Spells.E.range and (myHero.mana/myHero.maxMana >= ComboEMana / 100) then
	  			local Epos = target:GetPrediction(self.Spells.E.speed, self.Spells.E.delay)
	      			if Epos and GetDistance(Epos,myHero.pos) < self.Spells.E.range then
	        			Control.CastSpell(HK_E, Epos)
	     			end
				end
			end
	else
		if ComboE and Ready(_E) then
			if target.valid and Ready(_E) and target.distance <= 1.05 * self.Spells.E.range and (myHero.mana/myHero.maxMana >= ComboEMana / 100) and not Ready(_Q) then
	  		local Epos = target:GetPrediction(self.Spells.E.speed, self.Spells.E.delay)
	      		if Epos and GetDistance(Epos,myHero.pos) < self.Spells.E.range then
	        		Control.CastSpell(HK_E, Epos)
	     		end
			end
		end
	end
end
end




function KogMaw:Harass(target)
local HarassQ = KoreanMechanics.Harass.Q:Value()
local HarassW = KoreanMechanics.Harass.W:Value()
local HarassE = KoreanMechanics.Harass.E:Value()
local HarassQMana = KoreanMechanics.Harass.MM.QMana:Value()
local HarassWMana = KoreanMechanics.Harass.MM.WMana:Value()
local HarassEMana = KoreanMechanics.Harass.MM.EMana:Value()
	if HarassE then 
		if Ready(_E) and (myHero.mana/myHero.maxMana >= HarassEMana / 100) then
			if target.valid and Ready(_E) and target.distance <= 1.1 * self.Spells.E.range then
  			local Epos = target:GetPrediction(self.Spells.E.speed, self.Spells.E.delay)
      			if Epos and GetDistance(Epos,myHero.pos) < self.Spells.E.range then
        			Control.CastSpell(HK_E, Epos)
     			end
			end
		if HarassQ and Ready(_Q) and (myHero.mana/myHero.maxMana >= HarassQMana / 100) then
			if target.valid and Ready(_Q) and target:GetCollision(self.Spells.Q.width, self.Spells.Q.speed, self.Spells.Q.delay) == 0 and target.distance <= 1.1 * self.Spells.Q.range then
  			local Qpos = target:GetPrediction(self.Spells.Q.speed, self.Spells.Q.delay)
      			if Qpos and GetDistance(Qpos,myHero.pos) < self.Spells.Q.range then
        			Control.CastSpell(HK_Q, Qpos)
     			end
			end
		end
		if HarassW and Ready(_W) and (myHero.mana/myHero.maxMana >= HarassWMana / 100) then
			if target.valid and Ready(_W) and target.distance <= 710 then
				Control.CastSpell(HK_W, target)
			end 
		end
	elseif HarassQ and Ready(_Q) and (myHero.mana/myHero.maxMana >= HarassQMana / 100) then
			if target.valid and Ready(_Q) and target:GetCollision(self.Spells.Q.width, self.Spells.Q.speed, self.Spells.Q.delay) == 0 and target.distance <= 1.1 * self.Spells.Q.range then
  			local Qpos = target:GetPrediction(self.Spells.Q.speed, self.Spells.Q.delay)
      			if Qpos and GetDistance(Qpos,myHero.pos) < self.Spells.Q.range then
        			Control.CastSpell(HK_Q, Qpos)
     			end
			end
		end
		if HarassW and Ready(_W) and (myHero.mana/myHero.maxMana >= HarassWMana / 100) then
			if target.valid and Ready(_W) and target.distance <= 710 then
				Control.CastSpell(HK_W, target)
			end 
		end
	else
		if HarassW and Ready(_W) and (myHero.mana/myHero.maxMana >= HarassWMana / 100) then
			if target.valid and Ready(_W) and target.distance <= 710 then
				Control.CastSpell(HK_W, target)
			end 
		end
	end
end 


function KogMaw:Clear()
local ClearW = KoreanMechanics.Clear.W:Value()
local ClearWMana = KoreanMechanics.Clear.MM.WMana:Value()
local ClearWC = KoreanMechanics.Clear.WC:Value()
local ClearR = KoreanMechanics.Clear.R:Value()
local ClearRMana = KoreanMechanics.Clear.MM.RMana:Value()
local ClearRC = KoreanMechanics.Clear.RC:Value()
local GetEnemyMinions = GetEnemyMinions()
local Minions = nil
	for i = 1, #GetEnemyMinions do
	local Minions = GetEnemyMinions[i]
	local Count = MinionsAround(Minions.pos, 300, Minions.team)
		if ClearW and Ready(_W) and (myHero.mana/myHero.maxMana >= ClearWMana / 100) and Minions.distance <= 750 then	
			if Count >= ClearWC  then
				Control.CastSpell(HK_W)
			end
		end
		if ClearR and Ready(_R) and (myHero.mana/myHero.maxMana >= ClearRMana / 100) and Minions.distance >= 750 then
			if Count >= ClearRC then
			local Rpos = Minions:GetPrediction(self.Spells.R.speed, self.Spells.R.delay)
				if Rpos and Ready(_R) then
					Control.CastSpell(HK_R, Rpos)
				end
			end
		end
	end
end

function KogMaw:KS(target)
local target = _G.SDK.TargetSelector:GetTarget(2000)
	if target == nil then return end
	if target then
local KSON = KoreanMechanics.KS.ON:Value()
local KSQ = KoreanMechanics.KS.Q:Value()
--local KSW = KoreanMechanics.KS.W:Value()
local KSE = KoreanMechanics.KS.E:Value()
local KSR = KoreanMechanics.KS.R:Value()
local KSMana = KoreanMechanics.KS.Mana:Value()
	for i = 1, Game.HeroCount() do
		if (myHero.mana/myHero.maxMana >= KSMana / 100) then
			if KSON then
				if KSR and Ready(_R) then
					if target.valid and target.distance < 1.1*GetKogRange() and target.distance >= 670 and getdmg("R", target, myHero)*1.1 > target.health and Ready(_R) then
					local Rpos = target:GetPrediction(self.Spells.R.speed, self.Spells.R.delay)
						if Rpos and GetDistance(Rpos,myHero.pos) < GetKogRange() and Ready(_R) then
							Control.CastSpell(HK_R, Rpos)
						end
					end
				end
				if KSE and Ready(_E) then
					if target.valid and Ready(_E) and target.distance <= 1.1 * self.Spells.E.range and getdmg("E", target, myHero) > target.health then
  					local Epos = target:GetPrediction(self.Spells.E.speed, self.Spells.E.delay)
      					if Epos and GetDistance(Epos,myHero.pos) < self.Spells.E.range then
        					Control.CastSpell(HK_E, Epos)
     					end
					end
				end
				if KSQ and Ready(_Q) then
					if target.valid and Ready(_Q) and target:GetCollision(self.Spells.Q.width, self.Spells.Q.speed, self.Spells.Q.delay) == 0 and target.distance <= 1.1 * self.Spells.Q.range and getdmg("Q", target, myHero) > target.health then
  					local Qpos = target:GetPrediction(self.Spells.Q.speed, self.Spells.Q.delay)
      					if Qpos and GetDistance(Qpos,myHero.pos) < self.Spells.Q.range then
        					Control.CastSpell(HK_Q, Qpos)
     					end
					end
				end
			end
		end
	end
	end
end


function KogMaw:Draw()
	if not myHero.dead then
		if KoreanMechanics.Draw.Enabled:Value() then 
			if KoreanMechanics.Draw.Q:Value() then
			Draw.Circle(myHero.pos, self.Spells.Q.range, 1, Draw.Color(255, 52, 221, 221))
			end
			if KoreanMechanics.Draw.W:Value() then
			Draw.Circle(myHero.pos, self.Spells.W.range, 1, Draw.Color(255, 255, 255, 255))
			end
			if KoreanMechanics.Draw.E:Value() then
			Draw.Circle(myHero.pos, self.Spells.E.range, 1, Draw.Color(255, 255, 0, 128))
			end
			if KoreanMechanics.Draw.R:Value() then
				if GetKogRange() > 1 then
					Draw.Circle(myHero.pos, GetKogRange(), 1, Draw.Color(255, 000, 255, 000))	
				end
			end
		end
	end
end

class "Blitzcrank"

function Blitzcrank:__init()
	print("Korean Mechanics Reborn | Blitzcrank by Calsum and Weedle Loaded succesfully")
	self.Icons =  { Q = "http://static.lolskill.net/img/abilities/64/Blitzcrank_RocketGrab.png",
				  	W = "http://static.lolskill.net/img/abilities/64/Blitzcrank_Overdrive.png",
				  	E = "http://static.lolskill.net/img/abilities/64/Blitzcrank_PowerFist.png",
				  	R = "http://static.lolskill.net/img/abilities/64/Blitzcrank_StaticField.png"}
	self.Spells = {
		Q = {range = 925, delay = 0.25, speed = 1800,  width = 100},
		W = {delay = 0.25, speed = math.huge}, 
		E = {range = 300, delay = 0.25, speed = math.huge},
		R = {range = 600, delay = 0.25, speed = math.huge},
		
	} 
	self:Menu() 
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
end

function Blitzcrank:Menu()

	KoreanMechanics.Combo:MenuElement({id = "Q", name = "Use Rocket Grab (Q)", value = true, leftIcon = self.Icons.Q})
	KoreanMechanics.Combo:MenuElement({id = "WA", name = "Use Overdrive (W)", value = true, leftIcon = self.Icons.W})
	KoreanMechanics.Combo:MenuElement({id = "WR", name = "W when target distance", value = 1500, min = 0, max = 2500, step = 100})
	KoreanMechanics.Combo:MenuElement({id = "E", name = "Use Power Fist (E)", value = true, leftIcon = self.Icons.E})
	KoreanMechanics.Combo:MenuElement({id = "R", name = "Use Static Field (R)", value = true, leftIcon = self.Icons.R})
	KoreanMechanics.Combo:MenuElement({id = "RE", name = "Min Amount of Enemy's to R", value = 2, min = 1, max = 5, step = 1})
	KoreanMechanics.Combo:MenuElement({type = MENU, id = "MM", name = "Mana Manager"}) 
	KoreanMechanics.Combo.MM:MenuElement({id = "QMana", name = "Min Mana to Q in Combo(%)", value = 10, min = 0, max = 100, step = 1, leftIcon = self.Icons.Q})
	KoreanMechanics.Combo.MM:MenuElement({id = "WMana", name = "Min Mana to W in Combo(%)", value = 10, min = 0, max = 100, step = 1, leftIcon = self.Icons.W})
	KoreanMechanics.Combo.MM:MenuElement({id = "EMana", name = "Min Mana to E in Combo(%)", value = 10, min = 0, max = 100, step = 1, leftIcon = self.Icons.E})
	KoreanMechanics.Combo.MM:MenuElement({id = "RMana", name = "Min Mana to R in Combo(%)", value = 10, min = 0, max = 100, step = 1, leftIcon = self.Icons.R})
	KoreanMechanics.Combo:MenuElement({type = MENU, id = "W", name = "Q Grab Settings"})
	for K, Enemy in pairs(GetEnemyHeroes()) do
	KoreanMechanics.Combo.W:MenuElement({id = Enemy.charName, name = Enemy.charName, value = true})
	end


	KoreanMechanics.Harass:MenuElement({id = "Q", name = "Use Rocket Grab (Q)", value = true, leftIcon = self.Icons.Q})
	KoreanMechanics.Harass:MenuElement({id = "WE", name = "Use Overdrive (W)", value = true, leftIcon = self.Icons.W})
	KoreanMechanics.Harass:MenuElement({id = "WR", name = "W when target distance", value = 1500, min = 0, max = 2500, step = 100})
	KoreanMechanics.Harass:MenuElement({id = "E", name = "Use Power Fist (E)", value = true, leftIcon = self.Icons.E})
	KoreanMechanics.Harass:MenuElement({id = "Mana", name = "Min. Mana for Harass(%)", value = 40, min = 0, max = 100, step = 1})
	KoreanMechanics.Harass:MenuElement({type = MENU, id = "W", name = "Q Grab Settings"})
	for K, Enemy in pairs(GetEnemyHeroes()) do
	KoreanMechanics.Harass.W:MenuElement({id = Enemy.charName, name = Enemy.charName, value = true})
	end

	KoreanMechanics.Clear:MenuElement({id = "R", name = "Use Static Field (R)", value = true, leftIcon = self.Icons.R})
	KoreanMechanics.Clear:MenuElement({id = "RM", name = "Min Amount of Minion's to R", value = 3, min = 1, max = 7, step = 1})
	KoreanMechanics.Clear:MenuElement({id = "Mana", name = "Min. Mana to WaveClear (%)", value = 40, min = 0, max = 100, step = 1})

	KoreanMechanics.KS:MenuElement({id = "ON", name = "Enable KillSteal", value = true})
	KoreanMechanics.KS:MenuElement({id = "Q", name = "Use Q to KS", value = true})
	KoreanMechanics.KS:MenuElement({id = "E", name = "Use E to KS", value = true})
	KoreanMechanics.KS:MenuElement({id = "R", name = "Use R to KS", value = true})
	KoreanMechanics.KS:MenuElement({id = "Mana", name = "Min. Mana to KillSteal(%)", value = 20, min = 0, max = 100, step = 1})

	KoreanMechanics.Draw:MenuElement({id = "Enabled", name = "Enable Drawings", value = true})
	KoreanMechanics.Draw:MenuElement({id = "Q", name = "Draw Q", value = true, leftIcon = self.Icons.Q})
	KoreanMechanics.Draw:MenuElement({id = "W", name = "Draw W", value = true, leftIcon = self.Icons.W})
	KoreanMechanics.Draw:MenuElement({id = "E", name = "Draw E", value = true, leftIcon = self.Icons.E})
	KoreanMechanics.Draw:MenuElement({id = "R", name = "Draw R", value = true, leftIcon = self.Icons.R})

end 

function Blitzcrank:Tick()
	if myHero.dead then return end

	local target = _G.SDK.TargetSelector:GetTarget(1000)
	if target and _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_COMBO] then
		self:Combo(target)
	elseif target and _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_HARASS]  then
		self:Harass(target)
	elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_LANECLEAR] then
		self:Clear()
	elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_JUNGLECLEAR] then
		self:Clear()
	end
	self:KS()
end 

function Blitzcrank:Combo(target)
local target = _G.SDK.TargetSelector:GetTarget(1000)
	if target == nil then return end
	if target then
local ComboQ = KoreanMechanics.Combo.Q:Value()
local ComboWA = KoreanMechanics.Combo.WA:Value()
local ComboWR = KoreanMechanics.Combo.WR:Value()
local ComboE = KoreanMechanics.Combo.E:Value()
local ComboR = KoreanMechanics.Combo.R:Value() 
local ComboRE = KoreanMechanics.Combo.RE:Value()
local ComboQMana = KoreanMechanics.Combo.MM.QMana:Value()
local ComboWMana = KoreanMechanics.Combo.MM.WMana:Value()
local ComboEMana = KoreanMechanics.Combo.MM.EMana:Value()
local ComboRMana = KoreanMechanics.Combo.MM.RMana:Value()
	if ComboQ and Ready(_Q) and (myHero.mana/myHero.maxMana >= ComboQMana / 100) then
		if target.valid and Ready(_Q) and target:GetCollision(self.Spells.Q.width, self.Spells.Q.speed, self.Spells.Q.delay) == 0 and target.distance <= 1.1 * self.Spells.Q.range and KoreanMechanics.Combo.W[target.charName]:Value() then
		local Qpos = target:GetPrediction(self.Spells.Q.speed, self.Spells.Q.delay)
			if Qpos and GetDistance(Qpos,myHero.pos) <  self.Spells.Q.range then
        		Control.CastSpell(HK_Q, Qpos)
     		end
		end
	end
	if ComboWA and Ready(_W) and (myHero.mana/myHero.maxMana >= ComboWMana / 100) then
		if target.valid and ComboWA and Ready(_W) and target.distance <= ComboWR and target:GetCollision(self.Spells.Q.width, self.Spells.Q.speed, self.Spells.Q.delay) == 1  or not Ready(_Q)   then
			Control.CastSpell(HK_W, mousePos)
		end
		if ComboE and Ready(_E) and (myHero.mana/myHero.maxMana >= ComboEMana / 100) then
			if target.valid and ComboE and Ready(_E) and target.distance <= self.Spells.E.range then
				Control.CastSpell(HK_E, mousePos)
			end
		end
		if ComboR and Ready(_R) and (myHero.mana/myHero.maxMana >= ComboRMana / 100) and GetEnemyCount(600) >= ComboRE and target:GetCollision(self.Spells.Q.width, self.Spells.Q.speed, self.Spells.Q.delay) == 1 or not Ready(_Q) then
			if target.valid and ComboR and Ready(_R) and target.distance <= self.Spells.R.range then 
			Control.CastSpell(HK_R)
			end
		end
elseif ComboE and Ready(_E) and (myHero.mana/myHero.maxMana >= ComboEMana / 100) then
			if target.valid and ComboE and Ready(_E) and target.distance <= self.Spells.E.range then
				Control.CastSpell(HK_E, mousePos)
			end
		end
		if ComboR and Ready(_R) and (myHero.mana/myHero.maxMana >= ComboRMana / 100) and GetEnemyCount(600) >= ComboRE and target:GetCollision(self.Spells.Q.width, self.Spells.Q.speed, self.Spells.Q.delay) == 1 or not Ready(_Q) then
			if target.valid and ComboR and Ready(_R) and target.distance <= self.Spells.R.range then 
				Control.CastSpell(HK_R)
			end
		end
else
	if ComboR and Ready(_R) and (myHero.mana/myHero.maxMana >= ComboRMana / 100) and GetEnemyCount(600) >= ComboRE and target:GetCollision(self.Spells.Q.width, self.Spells.Q.speed, self.Spells.Q.delay) == 1 or not Ready(_Q) then
		if Ready(_E) and ComboE then
			if target.distance >= 350  then
				if target.valid and ComboR and Ready(_R) and target.distance <= self.Spells.R.range then 
					Control.CastSpell(HK_R)
				end
			end
	elseif not Ready(_E) or not ComboE then
			if target.valid and ComboR and Ready(_R) and target.distance <= self.Spells.R.range then 
				Control.CastSpell(HK_R)
			end
		end
	end
	end
end

function Blitzcrank:Harass(target)
local target = _G.SDK.TargetSelector:GetTarget(1000)
	if target == nil then return end
	if target then
local HarassQ = KoreanMechanics.Harass.Q:Value()
local HarassWE = KoreanMechanics.Harass.WE:Value()
local HarassWR = KoreanMechanics.Harass.WR:Value()
local HarassE = KoreanMechanics.Harass.E:Value()
local HarassMana = KoreanMechanics.Harass.Mana:Value()	
	if HarassQ and Ready(_Q) and (myHero.mana/myHero.maxMana >= HarassMana / 100) then
		if target.valid  and Ready(_Q) and target:GetCollision(self.Spells.Q.width, self.Spells.Q.speed, self.Spells.Q.delay) == 0 and target.distance <= 1.1 * self.Spells.Q.range and KoreanMechanics.Harass.W[target.charName]:Value() then
		local Qpos = target:GetPrediction(self.Spells.Q.speed, self.Spells.Q.delay)
			if Qpos and GetDistance(Qpos,myHero.pos) <  self.Spells.Q.range then
        		Control.CastSpell(HK_Q, Qpos)
     		end
		end
	end
	if HarassWE and Ready(_W) and (myHero.mana/myHero.maxMana >= HarassMana / 100) then
		if target.valid and HarassWE and Ready(_W) and target.distance <= HarassWR and target:GetCollision(self.Spells.Q.width, self.Spells.Q.speed, self.Spells.Q.delay) == 1  or not Ready(_Q)   then
			Control.CastSpell(HK_W, mousePos)
		end
		if HarassE and Ready(_E) and (myHero.mana/myHero.maxMana >= HarassMana / 100) then
			if target.valid and HarassE and Ready(_E) and target.distance <= self.Spells.E.range then
				Control.CastSpell(HK_E, mousePos)
			end
		end
elseif HarassE and Ready(_E) and (myHero.mana/myHero.maxMana >= HarassMana / 100) then
		if target.valid and HarassE and Ready(_E) and target.distance <= self.Spells.E.range then
			Control.CastSpell(HK_E, mousePos)
		end
	end
	end
end

function Blitzcrank:Clear()
local ClearR = KoreanMechanics.Clear.R:Value()
local ClearRM = KoreanMechanics.Clear.RM:Value()
local ClearMana = KoreanMechanics.Clear.Mana:Value()
local GetEnemyMinions = GetEnemyMinions()
local Minions = nil	
	for i = 1, #GetEnemyMinions do
	local Minions = GetEnemyMinions[i]
	local Count = MinionsAround(Minions.pos, 600, Minions.team)
		if ClearR and Ready(_R) and (myHero.mana/myHero.maxMana >= ClearMana / 100) and Minions.distance <= 600 then
			if Count >= ClearRM and getdmg("R", Minions, myHero) > Minions.health then
				Control.CastSpell(HK_R)
			end
		end
	end
end 

function Blitzcrank:KS(target)
local target = _G.SDK.TargetSelector:GetTarget(1000)
	if target == nil then return end
	if target then
local KSON = KoreanMechanics.KS.ON:Value()
local KSQ = KoreanMechanics.KS.Q:Value()
local KSE = KoreanMechanics.KS.E:Value()
local KSR = KoreanMechanics.KS.R:Value()
local KSMana = KoreanMechanics.KS.Mana:Value()
	for i = 1, Game.HeroCount() do
		if (myHero.mana/myHero.maxMana >= KSMana / 100) then
			if KSON then
				if KSQ and target.isEnemy and not target.isDead and target.valid and getdmg("Q", target, myHero) > target.health and Ready(_Q) and target:GetCollision(self.Spells.Q.width, self.Spells.Q.speed, self.Spells.Q.delay) == 0 and target.distance <= 1.1 * self.Spells.Q.range then
				local Qpos = target:GetPrediction(self.Spells.Q.speed, self.Spells.Q.delay)
					if Qpos and GetDistance(Qpos,myHero.pos) <  self.Spells.Q.range then
        				Control.CastSpell(HK_Q, Qpos)
     				end
				end
				if KSE and target.isEnemy and not target.isDead and target.valid and getdmg("E", target, myHero)*2 > target.health and Ready(_E) and target.distance <= self.Spells.E.range then 
					Control.CastSpell(HK_E, target)	
				end
				if KSR and target.isEnemy and not target.isDead and target.valid and getdmg("R", target, myHero) > target.health and Ready(_R) and target.distance <= self.Spells.R.range then
					Control.CastSpell(HK_R)
				end
			end
		end
	end
	end
end 


function Blitzcrank:Draw()
	if not myHero.dead then
		if KoreanMechanics.Draw.Enabled:Value() then 
			if KoreanMechanics.Draw.Q:Value() then
			Draw.Circle(myHero.pos, self.Spells.Q.range, 1, Draw.Color(255, 52, 221, 221))
			end
			if KoreanMechanics.Draw.W:Value() then
			Draw.Circle(myHero.pos, self.Spells.W.range, 1, Draw.Color(255, 255, 255, 255))
			end
			if KoreanMechanics.Draw.E:Value() then
			Draw.Circle(myHero.pos, self.Spells.E.range, 1, Draw.Color(255, 255, 0, 128))
			end
			if KoreanMechanics.Draw.R:Value() then
			Draw.Circle(myHero.pos, self.Spells.R.range, 1, Draw.Color(255, 000, 255, 000))
		end
	end
end
end

if _G[myHero.charName]() then print("Welcome back " ..myHero.name.. ", Thank you for using Korean Mechanics ^^") end
