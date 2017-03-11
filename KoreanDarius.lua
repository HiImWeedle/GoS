local KoreanChamps = {"Darius"}
if not table.contains(KoreanChamps, myHero.charName) then print("" ..myHero.charName.. " Is Not Supported!") return end

local KoreanDarius = MenuElement({type = MENU, id = "KoreanDarius", name = "Korean Darius", leftIcon = "http://static.lolskill.net/img/champions/64/darius.png"})
KoreanDarius:MenuElement({type = MENU, id = "Combo", name = "Combo Settings"})
KoreanDarius:MenuElement({type = MENU, id = "Harass", name = "Harass Settings"})
KoreanDarius:MenuElement({type = MENU, id = "KS", name = "Free Elo Settings"})
KoreanDarius:MenuElement({type = MENU, id = "Draw", name = "Drawing Settings"})

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

function GetItemSlot(unit, id)
  for i = ITEM_1, ITEM_7 do
    if unit:GetItemData(i).itemID == id then
      return i
    end
  end
  return 0
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

function MinionsAround(pos, range, team)
	local Count = 0
	for i = 1, Game.MinionCount() do
		local Minion = Game.Minion(i)
		if Minion and Minion.team == team and not Minion.dead and GetDistance(pos, Minion.pos) <= range then
			Count = Count + 1
		end
	end
	return Count
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
local Rdmg =  ((basedmg + stacksdmg) + ((({0, 30 * KoreanDarius.KS.XX:Value(), 65 * KoreanDarius.KS.XX:Value(), 120 * KoreanDarius.KS.XX:Value()})[level]) * (({0, 0.2, 0.4, 0.6, 0.8, 1})[Stacks]))) --CalcPhysicalDamage(myHero, target, ((basedmg + stacksdmg)))
	return Rdmg
	end
end

require("DamageLib")



class "Darius"

function Darius:__init()
	print("Korean Darius [v1.0] Loaded succesfully ^^")
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
	KoreanDarius.Combo:MenuElement({id = "Q", name = "Use Decimate (Q)", value = true, leftIcon = self.Icons.Q})
	KoreanDarius.Combo:MenuElement({id = "W", name = "Use Crippling Strike (W)", value = true, leftIcon = self.Icons.W})
	KoreanDarius.Combo:MenuElement({id = "E", name = "Use Apprehend (E)", value = true, leftIcon = self.Icons.E})
	KoreanDarius.Combo:MenuElement({id = "R", name = "Use Noxian Guillotine (R) [?]", value = true, tooltip = "Uses smart-R when Killable", leftIcon = self.Icons.R})
	KoreanDarius.Combo:MenuElement({id = "I", name = "Use Ignite", value = true, leftIcon = "http://static.lolskill.net/img/spells/32/14.png"})
	KoreanDarius.Combo:MenuElement({id = "ION", name = "Enable custom Ignite Settings", value = false})
	KoreanDarius.Combo:MenuElement({id = "IFAST", name = "Use Ignite when target HP%", value = 50, min = 0, max = 100, step = 1})
	KoreanDarius.Combo:MenuElement({type = MENU, id = "IT", name = "Items", leftIcon = "http://1.1m.yt/r1_D68r.png" })
	KoreanDarius.Combo.IT:MenuElement({id = "YG", name = "Use Youmuu's Ghostblade", value = true, leftIcon = "http://static.lolskill.net/img/items/32/3142.png"})
	KoreanDarius.Combo.IT:MenuElement({id = "YGR", name = "Use Ghostblade when target distance", value = 1500, min = 0, max = 2500, step = 100})
	KoreanDarius.Combo.IT:MenuElement({id = "T", name = "Use Tiamat", value = true, leftIcon = "http://static.lolskill.net/img/items/32/3077.png"})
	KoreanDarius.Combo.IT:MenuElement({id = "TH", name = "Use Titanic Hydra", value = true, leftIcon = "http://static.lolskill.net/img/items/32/3748.png"})
	KoreanDarius.Combo.IT:MenuElement({id = "RH", name = "Use Ravenous Hydra", value = true, leftIcon = "http://static.lolskill.net/img/items/32/3074.png"})

	KoreanDarius.Harass:MenuElement({id = "Q", name = "Use Decimate (Q)", value = true, leftIcon = self.Icons.Q})
	KoreanDarius.Harass:MenuElement({id = "W", name = "Use Crippling Strike (W)", value = true, leftIcon = self.Icons.W})
	KoreanDarius.Harass:MenuElement({id = "E", name = "Use Apprehend (E)", value = true, leftIcon = self.Icons.E})
	KoreanDarius.Harass:MenuElement({type = MENU, id = "IT", name = "Items", leftIcon = "http://1.1m.yt/r1_D68r.png" })
	KoreanDarius.Harass.IT:MenuElement({id = "T", name = "Use Tiamat", value = true, leftIcon = "http://static.lolskill.net/img/items/32/3077.png"})
	KoreanDarius.Harass.IT:MenuElement({id = "TH", name = "Use Titanic Hydra", value = true, leftIcon = "http://static.lolskill.net/img/items/32/3748.png"})
	KoreanDarius.Harass.IT:MenuElement({id = "RH", name = "Use Ravenous Hydra", value = true, leftIcon = "http://static.lolskill.net/img/items/32/3074.png"})
	KoreanDarius.Harass:MenuElement({type = MENU, id = "MM", name = "Mana Manager"})
	KoreanDarius.Harass.MM:MenuElement({id = "QMana", name = "Min Mana to Q in Harass(%)", value = 40, min = 0, max = 100, step = 1, leftIcon = self.Icons.Q})
	KoreanDarius.Harass.MM:MenuElement({id = "WMana", name = "Min Mana to W in Harass(%)", value = 40, min = 0, max = 100, step = 1, leftIcon = self.Icons.W})
	KoreanDarius.Harass.MM:MenuElement({id = "EMana", name = "Min Mana to E in Harass(%)", value = 40, min = 0, max = 100, step = 1, leftIcon = self.Icons.E})

--	KoreanDarius.Clear:MenuElement({id = "Q", name = "Use Decimate (Q)", value = true, leftIcon = self.Icons.Q})
--	KoreanDarius.Clear:MenuElement({id = "QC", name = "Min amount of minions to Q", value = 3, min = 1, max = 7, step = 1})
--	KoreanDarius.Clear:MenuElement({id = "W", name = "Use Crippling Strike (W)", value = false, leftIcon = self.Icons.W})
--	KoreanDarius.Clear:MenuElement({id = "Mana", name = "Min Mana to Clear (%)", value = 40, min = 0, max = 100, step = 1})

	KoreanDarius.KS:MenuElement({id = "ON", name = "Enable Free Elo [?]", value = true, tooltip = "Enable Smart-R to Killsteal"})
	KoreanDarius.KS:MenuElement({id = "XX", name = "Dmg Calculate Factor [?]", value = 1.0, min = 0, max = 1.5, step = 0.1, tooltip = "Turn down if u miss ults"})

	KoreanDarius.Draw:MenuElement({id = "Enabled", name = "Enable Drawings", value = true})
	KoreanDarius.Draw:MenuElement({id = "Q", name = "Draw Q", value = true, leftIcon = self.Icons.Q})
	KoreanDarius.Draw:MenuElement({id = "W", name = "Draw W", value = true, leftIcon = self.Icons.W})
	KoreanDarius.Draw:MenuElement({id = "E", name = "Draw E", value = true, leftIcon = self.Icons.E})
	KoreanDarius.Draw:MenuElement({id = "R", name = "Draw R", value = true, leftIcon = self.Icons.R})
	KoreanDarius.Draw:MenuElement({id = "DMG", name = "Draw R-DMG", value = true})

end

function Darius:Tick()
	if myHero.dead then return end

	local target = _G.SDK.TargetSelector:GetTarget(1000)
	local Rdmg = GetDariusRdmg(target)
	if target and _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_COMBO] then
		self:Combo(target)
	elseif target and _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_HARASS]  then
		self:Harass(target)
--	elseif Orbwalker.GetMode() == "Clear" then
--		self:Clear()
	end
 	self:KS()
end 

function Darius:Combo(target)
local target = _G.SDK.TargetSelector:GetTarget(1000)
	if target == nil then return end
	if target then
local ComboQ = KoreanDarius.Combo.Q:Value()
local ComboW = KoreanDarius.Combo.W:Value()
local ComboE = KoreanDarius.Combo.E:Value()
local ComboR = KoreanDarius.Combo.R:Value()
local ComboI = KoreanDarius.Combo.I:Value()
local ComboION = KoreanDarius.Combo.ION:Value()
local ComboIFAST = KoreanDarius.Combo.IFAST:Value()
local ComboYG = KoreanDarius.Combo.IT.YG:Value()
local ComboYGR = KoreanDarius.Combo.IT.YGR:Value()
local ComboT = KoreanDarius.Combo.IT.T:Value()
local ComboTH = KoreanDarius.Combo.IT.TH:Value()
local ComboRH = KoreanDarius.Combo.IT.RH:Value()
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
local HarassQ = KoreanDarius.Harass.Q:Value()
local HarassW = KoreanDarius.Harass.W:Value()
local HarassE = KoreanDarius.Harass.E:Value()
local HarassT = KoreanDarius.Harass.IT.T:Value()
local HarassTH = KoreanDarius.Harass.IT.TH:Value()
local HarassRH = KoreanDarius.Harass.IT.RH:Value()
local HarassQMana = KoreanDarius.Harass.MM.QMana:Value()
local HarassWMana = KoreanDarius.Harass.MM.WMana:Value()
local HarassEMana = KoreanDarius.Harass.MM.EMana:Value()
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
local ClearQ = KoreanDarius.Clear.Q:Value()
local ClearQC = KoreanDarius.Clear.QC:Value()
local ClearW = KoreanDarius.Clear.W:Value()
local ClearMana = KoreanDarius.Clear.Mana:Value()
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
local KSON = KoreanDarius.KS.ON:Value()
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
		if KoreanDarius.Draw.Enabled:Value() then 
			local textPos = myHero.pos:To2D()
			if KoreanDarius.Draw.Q:Value() then
			Draw.Circle(myHero.pos, self.Spells.Q.range, 1, Draw.Color(255, 52, 221, 221))
			end
			if KoreanDarius.Draw.W:Value() then
			Draw.Circle(myHero.pos, self.Spells.W.range, 1, Draw.Color(255, 255, 255, 255))
			end
			if KoreanDarius.Draw.E:Value() then
			Draw.Circle(myHero.pos, self.Spells.E.range, 1, Draw.Color(255, 255, 0, 128))
			end
			if KoreanDarius.Draw.R:Value() then
			Draw.Circle(myHero.pos, self.Spells.R.range, 1, Draw.Color(255, 000, 255, 000))
			end
			if KoreanDarius.Draw.DMG:Value() then 
				if GetDariusRdmg(target) ~= nil then 
				Draw.Text("R DMG " .. tostring(math.floor(GetDariusRdmg(target))), 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 0, 0)) --	Draw.Text("E DMG " .. tostring(0.1*math.floor(1000 * math.min(1, SmartTwitch:GetEDamage(hero) / hero.health))) .. "%", 15, textPos.x - 20, textPos.y + 60, Draw.Color(255, 255, 0, 0))
				end
			end
		end
	end
end

if _G[myHero.charName]() then print("Thanks " ..myHero.name.. " for using Korean Darius, remember post your suggestions and feedback.") end
