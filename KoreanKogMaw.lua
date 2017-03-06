local KoreanChamps = {"KogMaw"}
if not table.contains(KoreanChamps, myHero.charName) then return end

local KoreanKogMaw = MenuElement({type = MENU, id = "KoreanKogMaw", name = "Korean KogMaw", leftIcon = "http://static.lolskill.net/img/champions/64/kogmaw.png"})
KoreanKogMaw:MenuElement({type = MENU, id = "Combo", name = "Korean Combo Settings"})
KoreanKogMaw:MenuElement({type = MENU, id = "Harass", name = "Harass Settings"})
KoreanKogMaw:MenuElement({type = MENU, id = "Clear", name = "WaveClear Settings"})
--KoreanKogMaw:MenuElement({type = MENU, id = "KS", name = "KS Settings"})
KoreanKogMaw:MenuElement({type = MENU, id = "Misc", name = "More Coming soon!"})
KoreanKogMaw:MenuElement({type = MENU, id = "Draw", name = "Drawing Settings"})

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

require("DamageLib")

class "KogMaw"

function KogMaw:__init()
	print("Korean KogMaw [v0.5] Loaded succesfully ^^")
	self.Icons =  { Q = "http://static.lolskill.net/img/abilities/64/KogMaw_CausticSpittle.png",
				  	W = "http://static.lolskill.net/img/abilities/64/KogMaw_BioArcaneBarrage.png",
				  	E = "http://static.lolskill.net/img/abilities/64/KogMaw_VoidOoze.png",
				  	R = "http://static.lolskill.net/img/abilities/64/KogMaw_LivingArtillery.png"}
	self.Spells = {
		Q = {range = 1175, delay = 0.25, speed = 1600,  width = 80},
		W = {range = 700, delay = 0.25, speed = math.huge}, --ITS OVER 9000!!!!
		E = {range = 1200, delay = 0.25, speed = 1000, width = 65, collision = false},
		R = {range = {1200, 1500, 1800}, delay = 0.85, speed = math.huge},
		SummonerDot = {range = 600, dmg = 50+20*myHero.levelData.lvl}
	}
	self:Menu()
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
end

function KogMaw:Menu()
	KoreanKogMaw.Combo:MenuElement({id = "Q", name = "Use Caustic Spittle (Q)", value = true, leftIcon = self.Icons.Q})
	KoreanKogMaw.Combo:MenuElement({id = "W", name = "Use Bio-Arcane Barrage (W)", value = true, leftIcon = self.Icons.W})
	KoreanKogMaw.Combo:MenuElement({id = "E", name = "Use Void Ooze (E)", value = true, leftIcon = self.Icons.E})
	KoreanKogMaw.Combo:MenuElement({id = "R", name = "Use Living Artillery (R) [?]", value = true, tooltip = "Uses Smart-R when not in AA range", leftIcon = self.Icons.R})
	KoreanKogMaw.Combo:MenuElement({id = "RHP", name = "Max Enemy HP to R in Combo(%)", value = 40, min = 0, max = 100, step = 1})
	KoreanKogMaw.Combo:MenuElement({type = MENU, id = "IT", name = "Items", })
	KoreanKogMaw.Combo.IT:MenuElement({id = "YG", name = "Use Youmuu's Ghostblade", value = true, leftIcon = "http://static.lolskill.net/img/items/32/3142.png"})
	KoreanKogMaw.Combo.IT:MenuElement({id = "YGR", name = "Use Youmuu's Ghostblade when target distance", value = 1500, min = 0, max = 2500, step = 100})
	KoreanKogMaw.Combo.IT:MenuElement({id = "BC", name = "Use Bilgewater Cutlass", value = true, leftIcon = "http://static.lolskill.net/img/items/32/3144.png"})
	KoreanKogMaw.Combo.IT:MenuElement({id = "BCHP", name = "Max Enemy HP to BC in Combo(%)", value = 60, min = 0, max = 100, step = 1})
	KoreanKogMaw.Combo.IT:MenuElement({id = "BOTRK", name = "Use Blade Of the Ruined King", value = true, leftIcon = "http://static.lolskill.net/img/items/32/3153.png"})
	KoreanKogMaw.Combo.IT:MenuElement({id = "BOTRKHP", name = "Max Enemy HP to BOTRK in Combo(%)", value = 60, min = 0, max = 100, step = 1})
	KoreanKogMaw.Combo:MenuElement({type = MENU, id = "MM", name = "Mana Manager", leftIcon = "http://4.1m.yt/6cv8UEB.png"})
	KoreanKogMaw.Combo.MM:MenuElement({id = "QMana", name = "Min Mana to Q in Combo(%)", value = 10, min = 0, max = 100, step = 1, leftIcon = self.Icons.Q})
	KoreanKogMaw.Combo.MM:MenuElement({id = "WMana", name = "Min Mana to W in Combo(%)", value = 10, min = 0, max = 100, step = 1, leftIcon = self.Icons.W})
	KoreanKogMaw.Combo.MM:MenuElement({id = "EMana", name = "Min Mana to E in Combo(%)", value = 10, min = 0, max = 100, step = 1, leftIcon = self.Icons.E})
	KoreanKogMaw.Combo.MM:MenuElement({id = "RMana", name = "Min Mana to R in Combo(%)", value = 10, min = 0, max = 100, step = 1, leftIcon = self.Icons.R})

	KoreanKogMaw.Harass:MenuElement({id = "Q", name = "Use Caustic Spittle (Q)", value = true, leftIcon = self.Icons.Q})
	KoreanKogMaw.Harass:MenuElement({id = "W", name = "Use Bio-Arcane Barrage (W)", value = true, leftIcon = self.Icons.W})
	KoreanKogMaw.Harass:MenuElement({id = "E", name = "Use Void Ooze (E)", value = true, leftIcon = self.Icons.E})
	KoreanKogMaw.Harass:MenuElement({type = MENU, id = "MM", name = "Mana Manager", leftIcon = "http://4.1m.yt/6cv8UEB.png"})
	KoreanKogMaw.Harass.MM:MenuElement({id = "QMana", name = "Min Mana to Q in Harass(%)", value = 40, min = 0, max = 100, step = 1, leftIcon = self.Icons.Q})
	KoreanKogMaw.Harass.MM:MenuElement({id = "WMana", name = "Min Mana to W in Harass(%)", value = 40, min = 0, max = 100, step = 1, leftIcon = self.Icons.W})
	KoreanKogMaw.Harass.MM:MenuElement({id = "EMana", name = "Min Mana to E in Harass(%)", value = 40, min = 0, max = 100, step = 1, leftIcon = self.Icons.E})

	KoreanKogMaw.Clear:MenuElement({id = "W", name = "Use Bio-Arcane Barrage (W)", value = true, leftIcon = self.Icons.W})
	KoreanKogMaw.Clear:MenuElement({id = "WC", name = "Min amount of minions to W", value = 3, min = 1, max = 7, step = 1})
	KoreanKogMaw.Clear:MenuElement({id = "R", name = "Use Living Artillery (R) [beta]", value = false, leftIcon = self.Icons.R})
	KoreanKogMaw.Clear:MenuElement({id = "RC", name = "Min amount of minions to R", value = 3, min = 1, max = 7, step = 1})
	KoreanKogMaw.Clear:MenuElement({type = MENU, id = "MM", name = "Mana Manager", leftIcon = "http://4.1m.yt/6cv8UEB.png"})
	KoreanKogMaw.Clear.MM:MenuElement({id = "WMana", name = "Min Mana to W in Clear(%)", value = 40, min = 0, max = 100, step = 1, leftIcon = self.Icons.W})
	KoreanKogMaw.Clear.MM:MenuElement({id = "RMana", name = "Min Mana to R in Clear(%)", value = 40, min = 0, max = 100, step = 1, leftIcon = self.Icons.R})


	--KoreanKogMaw.KS:MenuElement({id = "ON", name = "Enable KillSteal", value = true})
	--KoreanKogMaw.KS:MenuElement({id = "Q", name = "Use Q to KS", value = true, leftIcon = self.Icons.Q})
    --KoreanKogMaw.KS:MenuElement({id = "W", name = "Use W to KS", value = true, leftIcon = self.Icons.W})
	--KoreanKogMaw.KS:MenuElement({id = "E", name = "Use E to KS", value = true, leftIcon = self.Icons.E})
	--KoreanKogMaw.KS:MenuElement({id = "R", name = "Use R to KS", value = true, leftIcon = self.Icons.R})
	--KoreanKogMaw.KS:MenuElement({id = "Mana", name = "Min. Mana to KillSteal(%)", value = 20, min = 0, max = 100, step = 1})

	KoreanKogMaw.Draw:MenuElement({id = "Enabled", name = "Enable Drawings", value = true})
	KoreanKogMaw.Draw:MenuElement({id = "Q", name = "Draw Q", value = true, leftIcon = self.Icons.Q})
	KoreanKogMaw.Draw:MenuElement({id = "W", name = "Draw W", value = true, leftIcon = self.Icons.W})
	KoreanKogMaw.Draw:MenuElement({id = "E", name = "Draw E", value = true, leftIcon = self.Icons.E})
	KoreanKogMaw.Draw:MenuElement({type = MENU, id = "RD", name = "Draw R", leftIcon = self.Icons.R})
	KoreanKogMaw.Draw.RD:MenuElement({id = "R", name = "Draw R at level", value = 2, min = 1, max = 3, step = 1})
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
  --self:KS()
end

function KogMaw:Combo(target)
local ComboQ = KoreanKogMaw.Combo.Q:Value()
local ComboW = KoreanKogMaw.Combo.W:Value()
local ComboE = KoreanKogMaw.Combo.E:Value()
local ComboR = KoreanKogMaw.Combo.R:Value()
local ComboRHP = KoreanKogMaw.Combo.RHP:Value()
local ComboYG = KoreanKogMaw.Combo.IT.YG:Value()
local ComboYGR = KoreanKogMaw.Combo.IT.YGR:Value()
local ComboBC = KoreanKogMaw.Combo.IT.BC:Value()
local ComboBCHP = KoreanKogMaw.Combo.IT.BCHP:Value()
local ComboBOTRK = KoreanKogMaw.Combo.IT.BOTRK:Value()
local ComboBOTRKHP = KoreanKogMaw.Combo.IT.BOTRKHP:Value()
local ComboQMana = KoreanKogMaw.Combo.MM.QMana:Value()
local ComboWMana = KoreanKogMaw.Combo.MM.WMana:Value()
local ComboEMana = KoreanKogMaw.Combo.MM.EMana:Value()
local ComboRMana = KoreanKogMaw.Combo.MM.RMana:Value()
	if ComboR and Ready(_R) and (myHero.mana/myHero.maxMana >= ComboRMana / 100) then
		if IsValidTarget(target, 1350, true, myHero) and target.distance >= 670 and (target.health/target.maxHealth) <= (ComboRHP/100) and Ready(_R) then
			local Rpos = target:GetPrediction(self.Spells.R.speed, self.Spells.R.delay)
				if Rpos and GetDistance(Rpos,myHero.pos) < 1310 and Ready(_R) then
					Control.CastSpell(HK_R, Rpos)
				end
			end
	elseif  IsValidTarget(target, 1650, true, myHero) and target.distance >= 710 and (target.health/target.maxHealth) <= (ComboRHP/100) and Ready(_R) then
			local Rpos = target:GetPrediction(self.Spells.R.speed, self.Spells.R.delay)
				if Rpos and GetDistance(Rpos,myHero.pos) < 1610 and Ready(_R) then
					Control.CastSpell(HK_R, Rpos)
				end
	elseif IsValidTarget(target, 1950 , true, myHero) and target.distance >= 710 and (target.health/target.maxHealth) <= (ComboRHP/100) and Ready(_R) then
		local Rpos = target:GetPrediction(self.Spells.R.speed, self.Spells.R.delay)
			if Rpos and GetDistance(Rpos,myHero.pos) < 1910 and Ready(_R) then
				Control.CastSpell(HK_R, Rpos)
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
	if ComboBC and GetItemSlot(myHero, 3144) > 0 and (target.health/target.maxHealth) <= (ComboBCHP/100) then
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
	if ComboBOTRK and GetItemSlot(myHero, 3153) > 0 and (target.health/target.maxHealth) <= (ComboBOTRKHP/100) then
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
	if ComboE and Ready(_E) then
		if target.valid and Ready(_E) and target.distance <= 1.1 * self.Spells.E.range and (myHero.mana/myHero.maxMana >= ComboEMana / 100) then
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
	elseif ComboQ and Ready(_Q) then
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
end

function KogMaw:Harass(target)
local HarassQ = KoreanKogMaw.Harass.Q:Value()
local HarassW = KoreanKogMaw.Harass.W:Value()
local HarassE = KoreanKogMaw.Harass.E:Value()
local HarassQMana = KoreanKogMaw.Harass.MM.QMana:Value()
local HarassWMana = KoreanKogMaw.Harass.MM.WMana:Value()
local HarassEMana = KoreanKogMaw.Harass.MM.EMana:Value()
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
local ClearW = KoreanKogMaw.Clear.W:Value()
local ClearWMana = KoreanKogMaw.Clear.MM.WMana:Value()
local ClearWC = KoreanKogMaw.Clear.WC:Value()
local ClearR = KoreanKogMaw.Clear.R:Value()
local ClearRMana = KoreanKogMaw.Clear.MM.RMana:Value()
local ClearRC = KoreanKogMaw.Clear.RC:Value()
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
local KSON = KoreanKogMaw.KS.ON:Value()
local KSQ = KoreanKogMaw.KS.Q:Value()
--local KSW = KoreanKogMaw.KS.W:Value()
local KSE = KoreanKogMaw.KS.E:Value()
local KSR = KoreanKogMaw.KS.R:Value()
local KSMana = KoreanKogMaw.KS.Mana:Value()
	for i = 1, Game.HeroCount() do
		local target = Game.Hero(i)
		if (myHero.mana/myHero.maxMana >= KSMana / 100) then
			if KSON then
				if KSR and Ready(_R) then
					if IsValidTarget(target, 1350, true, myHero) and target.distance >= 670 and getdmg("R", target, myHero) > target.health and Ready(_R) then
					local Rpos = target:GetPrediction(self.Spells.R.speed, self.Spells.R.delay)
						if Rpos and GetDistance(Rpos,myHero.pos) < 1310 and Ready(_R) then
							Control.CastSpell(HK_R, Rpos)
						end
					end
			elseif 	IsValidTarget(target, 1650, true, myHero) and target.distance >= 710 and getdmg("R", target, myHero) > target.health and Ready(_R) then
					local Rpos = target:GetPrediction(self.Spells.R.speed, self.Spells.R.delay)
						if Rpos and GetDistance(Rpos,myHero.pos) < 1610 and Ready(_R) then
							Control.CastSpell(HK_R, Rpos)
						end
				end
			else
				if IsValidTarget(target, 1950 , true, myHero) and target.distance >= 710 and getdmg("R", target, myHero) > target.health and Ready(_R) then
				local Rpos = target:GetPrediction(self.Spells.R.speed, self.Spells.R.delay)
					if Rpos and GetDistance(Rpos,myHero.pos) < 1910 and Ready(_R) then
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


function KogMaw:Draw()
	if not myHero.dead then
		if KoreanKogMaw.Draw.Enabled:Value() then 
			if KoreanKogMaw.Draw.Q:Value() then
			Draw.Circle(myHero.pos, self.Spells.Q.range, 1, Draw.Color(255, 52, 221, 221))
			end
			if KoreanKogMaw.Draw.W:Value() then
			Draw.Circle(myHero.pos, self.Spells.W.range, 1, Draw.Color(255, 255, 255, 255))
			end
			if KoreanKogMaw.Draw.E:Value() then
			Draw.Circle(myHero.pos, self.Spells.E.range, 1, Draw.Color(255, 255, 0, 128))
			end
			if KoreanKogMaw.Draw.RD.R:Value() == 1 then
			Draw.Circle(myHero.pos, 1200, 1, Draw.Color(255, 000, 255, 000))
			end
			if KoreanKogMaw.Draw.RD.R:Value() == 2 then
			Draw.Circle(myHero.pos, 1500, 1, Draw.Color(255, 000, 255, 000))
			end
			if KoreanKogMaw.Draw.RD.R:Value() == 3 then
			Draw.Circle(myHero.pos, 1800, 1, Draw.Color(255, 000, 255, 000))
			end
		end
	end
end


if _G[myHero.charName]() then print("Welcome back " ..myHero.name.. ", Have a nice day my friend! <3 ") end
