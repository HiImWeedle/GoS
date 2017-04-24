local KoreanChamps = {"Ezreal", "Zed", "Ahri", "Blitzcrank", "Caitlyn", "Brand", "Ziggs", "Morgana", "Syndra", "KogMaw", "Lux", "Cassiopeia", "Karma", "Orianna", "Ryze", "Jhin", "Jayce", "Kennen", "Thresh", "Amumu", "Elise", "Zilean", "Corki"}
if not table.contains(KoreanChamps, myHero.charName)  then print("" ..myHero.charName.. " Is Not (Yet) Supported") return end

local function Ready(spell)
	return myHero:GetSpellData(spell).currentCd == 0 and myHero:GetSpellData(spell).level > 0 and myHero:GetSpellData(spell).mana <= myHero.mana
end

local KoreanMechanics = MenuElement({type = MENU, id = "KoreanMechanics", name = "WeedleAIO", leftIcon = "http://4.1m.yt/d5VbDBm.png"})
KoreanMechanics:MenuElement({type = MENU, id = "Spell", name = "Spell Settings"})
	KoreanMechanics.Spell:MenuElement({id = "Enabled", name = "Enabled", key = string.byte(" "), toggle = true})
KoreanMechanics:MenuElement({type = MENU, id = "Draw", name = "Draw Settings"})
	KoreanMechanics.Draw:MenuElement({id = "Enabled", name = "Enable all Drawings", value = true})
	KoreanMechanics.Draw:MenuElement({id = "OFFDRAW", name = "Draw text when Off", value = true})
KoreanMechanics:MenuElement({type = SPACE, name = "Version 0.1 by Weedle"})		


local _AllyHeroes
local function GetAllyHeroes()
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
local function GetEnemyHeroes()
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

local function GetPercentHP(unit)
	if type(unit) ~= "userdata" then error("{GetPercentHP}: bad argument #1 (userdata expected, got "..type(unit)..")") end
	return 100*unit.health/unit.maxHealth
end

local function GetPercentMP(unit)
	if type(unit) ~= "userdata" then error("{GetPercentMP}: bad argument #1 (userdata expected, got "..type(unit)..")") end
	return 100*unit.mana/unit.maxMana
end

local function GetBuffData(unit, buffname)
	for i = 0, unit.buffCount do
		local buff = unit:GetBuff(i)
		if buff.name == buffname and buff.count > 0 then 
			return buff
		end
	end
	return {type = 0, name = "", startTime = 0, expireTime = 0, duration = 0, stacks = 0, count = 0}--
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

local sqrt = math.sqrt 
local function GetDistance(p1,p2)
	return sqrt((p2.x - p1.x)*(p2.x - p1.x) + (p2.y - p1.y)*(p2.y - p1.y) + (p2.z - p1.z)*(p2.z - p1.z))
end

local function GetDistance2D(p1,p2)
	return sqrt((p2.x - p1.x)*(p2.x - p1.x) + (p2.y - p1.y)*(p2.y - p1.y))
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

local function GetPred(unit,speed,delay)
	if unit == nil then return end
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

local isCasting = 0 
function KoreanCast(pos, delay)
local Cursor = mousePos
    if pos == nil or isCasting == 1 then return end
    isCasting = 1
        Control.SetCursorPos(pos)
        DelayAction(function()
        Control.SetCursorPos(Cursor)
        DelayAction(function()
         isCasting = 0
        end, 0.002)
        end, (delay + Game.Latency()) / 1000)
end 


class "Ezreal"

function Ezreal:__init()
	print("Weedle's Ezreal Loaded")
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
	self:Menu()
end

function Ezreal:Menu()
	KoreanMechanics.Spell:MenuElement({id = "Q", name = "Q Key", key = string.byte("Q")})
	KoreanMechanics.Spell:MenuElement({id = "QR", name = "Q Range", value = 1150, min = 0, max = 1150, step = 10})
	KoreanMechanics.Spell:MenuElement({id = "W", name = "W Key", key = string.byte("W")})
	KoreanMechanics.Spell:MenuElement({id = "WR", name = "W Range", value = 1000, min = 0, max = 1000, step = 10})
	KoreanMechanics.Spell:MenuElement({id = "Q", name = "Q Key", key = string.byte("Q")})
	KoreanMechanics.Spell:MenuElement({id = "QR", name = "Q Range", value = 1250, min = 0, max = 1250, step = 10})
	KoreanMechanics.Spell:MenuElement({id = "E", name = "E Key", key = string.byte("E")})
	KoreanMechanics.Spell:MenuElement({id = "ER", name = "E Range", value = 750, min = 0, max = 750, step = 10})
	KoreanMechanics.Spell:MenuElement({id = "R", name = "R Key", key = string.byte("R")})

	KoreanMechanics.Draw:MenuElement({id = "QD", name = "Draw Q range", type = MENU})
    KoreanMechanics.Draw.QD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.QD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.QD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
    KoreanMechanics.Draw:MenuElement({id = "WD", name = "Draw W range", type = MENU})
    KoreanMechanics.Draw.WD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.WD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.WD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
end

function Ezreal:Tick()
	if KoreanMechanics.Spell.Enabled:Value() then
		if KoreanMechanics.Spell.Q:Value() then
			self:Q()
		end
		if KoreanMechanics.Spell.W:Value() then
			self:W()
		end
		if KoreanMechanics.Spell.R:Value() then
			self:R()
		end
	end
end

function Ezreal:Q()
local target =  _G.SDK.TargetSelector:GetTarget(1250)
if target == nil then return end 	
	local pos = GetPred(target, 1400, (0.25 + Game.Latency())/1000)
	KoreanCast(pos, 100)
end

function Ezreal:W()
local target =  _G.SDK.TargetSelector:GetTarget(1100)	
if target == nil then return end 		
	local pos = GetPred(target, 1200, 0.25 + Game.Latency()/1000)
	KoreanCast(pos, 100)
end

function Ezreal:R()	
local targety =  _G.SDK.TargetSelector:GetTarget(20000)
	if targety == nil then return end 	
	local pos = GetPred(targety, 2000, 0.25 + Game.Latency()/1000)
	KoreanCast(pos, 100)
end

function Ezreal:Draw()
	if not myHero.dead then
	   	if KoreanMechanics.Draw.Enabled:Value() then
	   		local textPos = myHero.pos:To2D()
	   		if KoreanMechanics.Spell.Enabled:Value() then
				Draw.Text("Aimbot ON", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000)) 		
			end
			if not KoreanMechanics.Spell.Enabled:Value() and KoreanMechanics.Draw.OFFDRAW:Value() then 
				Draw.Text("Aimbot OFF", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 000, 000)) 
			end 
			if KoreanMechanics.Draw.QD.Enabled:Value() then
	    	    Draw.Circle(myHero.pos, KoreanMechanics.Spell.QR:Value(), KoreanMechanics.Draw.QD.Width:Value(), KoreanMechanics.Draw.QD.Color:Value())
	    	end
	    	if KoreanMechanics.Draw.WD.Enabled:Value() then
	    	    Draw.Circle(myHero.pos, KoreanMechanics.Spell.WR:Value(), KoreanMechanics.Draw.WD.Width:Value(), KoreanMechanics.Draw.WD.Color:Value())
	    	end
	    end		
	end
end

class "Zed"

function Zed:__init()
	print("Weedle's Zed Loaded")
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
	self:Menu()
end

function Zed:Menu()
	KoreanMechanics.Spell:MenuElement({id = "Q", name = "Q Key", key = string.byte("Q")})
	KoreanMechanics.Spell:MenuElement({id = "QR", name = "Max Q Combo Range", value = 1600, min = 0, max = 1600, step = 25})
	KoreanMechanics.Spell:MenuElement({id = "R", name = "R Key", key = string.byte("R")})

	KoreanMechanics.Draw:MenuElement({id = "QD", name = "Draw Q range", type = MENU})
    KoreanMechanics.Draw.QD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.QD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.QD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
end

function Zed:Tick()
	if KoreanMechanics.Spell.Enabled:Value() then
		if KoreanMechanics.Spell.Q:Value() then
			self:Q()
		end
		if KoreanMechanics.Spell.R:Value() then
			self:R()
		end		
	end
end	

function Zed:Q()
local target =  _G.SDK.TargetSelector:GetTarget(1500)
if target == nil then return end 	
	local pos = GetPred(target, 1100, (0.25 + Game.Latency())/1000)
	KoreanCast(pos, 100)
end

function Zed:R()
local target =  _G.SDK.TargetSelector:GetTarget(850)
if target == nil then return end 	
	KoreanCast(target.pos, 100)
end	

function Zed:Draw()
	if not myHero.dead then
	   	if KoreanMechanics.Draw.Enabled:Value() then
	   		local textPos = myHero.pos:To2D()
	   		if KoreanMechanics.Spell.Enabled:Value() then
				Draw.Text("Aimbot ON", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000)) 		
			end
			if not KoreanMechanics.Spell.Enabled:Value() and KoreanMechanics.Draw.OFFDRAW:Value() then 
				Draw.Text("Aimbot OFF", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 000, 000)) 
			end 
			if KoreanMechanics.Draw.QD.Enabled:Value() then
	    	    Draw.Circle(myHero.pos, 900, KoreanMechanics.Draw.QD.Width:Value(), KoreanMechanics.Draw.QD.Color:Value())
	    	end
	    end		
	end
end

class "Ahri"

function Ahri:__init()
	print("Weedle's Ahri Loaded")
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
	self:Menu()
end

function Ahri:Menu()
	KoreanMechanics.Spell:MenuElement({id = "Q", name = "Q Key", key = string.byte("Q")})
	KoreanMechanics.Spell:MenuElement({id = "QR", name = "Q Range", value = 875, min = 0, max = 875, step = 10})
	KoreanMechanics.Spell:MenuElement({id = "E", name = "E Key", key = string.byte("E")})
	KoreanMechanics.Spell:MenuElement({id = "ER", name = "E Range", value = 950, min = 0, max = 950, step = 10})

	KoreanMechanics.Draw:MenuElement({id = "QD", name = "Draw Q range", type = MENU})
    KoreanMechanics.Draw.QD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.QD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.QD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
    KoreanMechanics.Draw:MenuElement({id = "ED", name = "Draw E range", type = MENU})
    KoreanMechanics.Draw.ED:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.ED:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.ED:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
end

function Ahri:Tick()
	if KoreanMechanics.Spell.Enabled:Value() then
		if KoreanMechanics.Spell.Q:Value() then
			self:Q()
		end
		if KoreanMechanics.Spell.E:Value() then
			self:E()
		end
	end
end

function Ahri:Q()
local target =  _G.SDK.TargetSelector:GetTarget(1000)
if target == nil then return end 	
	local pos = GetPred(target, 1700, (0.25 + Game.Latency())/1000)
	KoreanCast(pos, 100)
end	

function Ahri:E()
local target =  _G.SDK.TargetSelector:GetTarget(1050)
if target == nil then return end 	
	local pos = GetPred(target, 1600, (0.25 + Game.Latency())/1000)
	KoreanCast(pos, 100)
end	

function Ahri:Draw()
	if not myHero.dead then
	   	if KoreanMechanics.Draw.Enabled:Value() then
	   		local textPos = myHero.pos:To2D()
	   		if KoreanMechanics.Spell.Enabled:Value() then
				Draw.Text("Aimbot ON", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000)) 		
			end
			if not KoreanMechanics.Spell.Enabled:Value() and KoreanMechanics.Draw.OFFDRAW:Value() then 
					Draw.Text("Aimbot OFF", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 000, 000)) 
			end 
			if KoreanMechanics.Draw.QD.Enabled:Value() then
	    	    Draw.Circle(myHero.pos, KoreanMechanics.Spell.QR:Value(), KoreanMechanics.Draw.QD.Width:Value(), KoreanMechanics.Draw.QD.Color:Value())
	    	end
	    	if KoreanMechanics.Draw.ED.Enabled:Value() then
	    	    Draw.Circle(myHero.pos, KoreanMechanics.Spell.ER:Value(), KoreanMechanics.Draw.ED.Width:Value(), KoreanMechanics.Draw.ED.Color:Value())
	    	end
	    end		
	end
end

class "Blitzcrank"

function Blitzcrank:__init()
	print("Weedle's Blitzcrank Loaded")
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
	self:Menu()
end

function Blitzcrank:Menu()
	KoreanMechanics.Spell:MenuElement({id = "Q", name = "Q Key", key = string.byte("Q")})
	KoreanMechanics.Spell:MenuElement({id = "QR", name = "Q Range", value = 925, min = 0, max = 925, step = 10})
	KoreanMechanics.Draw:MenuElement({id = "QD", name = "Draw Q range", type = MENU})

    KoreanMechanics.Draw.QD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.QD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.QD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})	
end 

function Blitzcrank:Tick()
	if KoreanMechanics.Spell.Enabled:Value() then
		if KoreanMechanics.Spell.Q:Value() then
			self:Q()
		end
	end
end	

function Blitzcrank:Q()
local target =  _G.SDK.TargetSelector:GetTarget(1025)
if target == nil then return end 	
	local pos = GetPred(target, 1800, (0.25 + Game.Latency())/1000)
	KoreanCast(pos, 100)
end

function Blitzcrank:Draw()
	if not myHero.dead then
	   	if KoreanMechanics.Draw.Enabled:Value() then
	   		local textPos = myHero.pos:To2D()
	   		if KoreanMechanics.Spell.Enabled:Value() then
				Draw.Text("Aimbot ON", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000)) 		
			end
			if not KoreanMechanics.Spell.Enabled:Value() and KoreanMechanics.Draw.OFFDRAW:Value() then 
				Draw.Text("Aimbot OFF", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 000, 000)) 
			end 
			if KoreanMechanics.Draw.QD.Enabled:Value() then
	    	    Draw.Circle(myHero.pos, KoreanMechanics.Spell.QR:Value(), KoreanMechanics.Draw.QD.Width:Value(), KoreanMechanics.Draw.QD.Color:Value())
	    	end
	    end		
	end
end		

class "Caitlyn"

function Caitlyn:__init()
	print("Weedle's Caitlyn Loaded")
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
	self:Menu()
end

function Caitlyn:Menu()
	KoreanMechanics.Spell:MenuElement({id = "Q", name = "Q Key", key = string.byte("Q")})
	KoreanMechanics.Spell:MenuElement({id = "QR", name = "Q Range", value = 1250, min = 0, max = 1250, step = 10})
	KoreanMechanics.Spell:MenuElement({id = "E", name = "E Key", key = string.byte("E")})
	KoreanMechanics.Spell:MenuElement({id = "ER", name = "E Range", value = 750, min = 0, max = 750, step = 10})
	KoreanMechanics.Spell:MenuElement({id = "R", name = "R Key", key = string.byte("R")})			

	KoreanMechanics.Draw:MenuElement({id = "QD", name = "Draw Q range", type = MENU})
    KoreanMechanics.Draw.QD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.QD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.QD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
    KoreanMechanics.Draw:MenuElement({id = "ED", name = "Draw E range", type = MENU})
    KoreanMechanics.Draw.ED:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.ED:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.ED:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
end

function Caitlyn:Tick()
	if KoreanMechanics.Spell.Enabled:Value() then
		if KoreanMechanics.Spell.Q:Value() then
			self:Q()
		end
		if KoreanMechanics.Spell.E:Value() then
			self:E()
		end
		if KoreanMechanics.Spell.R:Value() then
			self:R()
		end
	end
end

function Caitlyn:Q()
local target =  _G.SDK.TargetSelector:GetTarget(1350)
if target == nil then return end 	
	local pos = GetPred(target, 2200, (0.25 + Game.Latency())/1000)
	KoreanCast(pos, 100)
end	

function Caitlyn:E()
local target =  _G.SDK.TargetSelector:GetTarget(850)
if target == nil then return end 	
	local pos = GetPred(target, 2000, (0.25 + Game.Latency())/1000)
	KoreanCast(pos, 100)
end	

function Caitlyn:R()
local target =  _G.SDK.TargetSelector:GetTarget(3000)
if target == nil then return end 	
	KoreanCast(target.pos, 100)
end		

function Caitlyn:Draw()
	if not myHero.dead then
	   	if KoreanMechanics.Draw.Enabled:Value() then
	   		local textPos = myHero.pos:To2D()
	   		if KoreanMechanics.Spell.Enabled:Value() then
				Draw.Text("Aimbot ON", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000)) 		
			end
			if not KoreanMechanics.Spell.Enabled:Value() and KoreanMechanics.Draw.OFFDRAW:Value() then 
				Draw.Text("Aimbot OFF", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 000, 000)) 
			end 
			if KoreanMechanics.Draw.QD.Enabled:Value() then
	    	    Draw.Circle(myHero.pos, KoreanMechanics.Spell.QR:Value(), KoreanMechanics.Draw.QD.Width:Value(), KoreanMechanics.Draw.QD.Color:Value())
	    	end
	    	if KoreanMechanics.Draw.ED.Enabled:Value() then
	    	    Draw.Circle(myHero.pos, KoreanMechanics.Spell.ER:Value(), KoreanMechanics.Draw.ED.Width:Value(), KoreanMechanics.Draw.ED.Color:Value())
	    	end
	    end		
	end
end

class "Brand"

function Brand:__init()
	print("Weedle's Brand Loaded")
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
	self:Menu()
end

function Brand:Menu()
	KoreanMechanics.Spell:MenuElement({id = "Q", name = "Q Key", key = string.byte("Q")})
	KoreanMechanics.Spell:MenuElement({id = "QR", name = "Q Range", value = 1150, min = 0, max = 1150, step = 10})
	KoreanMechanics.Spell:MenuElement({id = "W", name = "W Key", key = string.byte("W")})
	KoreanMechanics.Spell:MenuElement({id = "WR", name = "W Range", value = 1000, min = 0, max = 1000, step = 10})
	KoreanMechanics.Spell:MenuElement({id = "E", name = "E Key", key = string.byte("E")})
	KoreanMechanics.Spell:MenuElement({id = "ER", name = "E Range", value = 750, min = 0, max = 750, step = 10})
	KoreanMechanics.Spell:MenuElement({id = "R", name = "R Key", key = string.byte("R")})			

	KoreanMechanics.Draw:MenuElement({id = "QD", name = "Draw Q range", type = MENU})
    KoreanMechanics.Draw.QD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.QD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.QD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
    KoreanMechanics.Draw:MenuElement({id = "WD", name = "Draw W range", type = MENU})
    KoreanMechanics.Draw.WD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.WD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.WD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
    KoreanMechanics.Draw:MenuElement({id = "ED", name = "Draw E range", type = MENU})
    KoreanMechanics.Draw.ED:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.ED:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.ED:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
end

function Brand:Tick()
	if KoreanMechanics.Spell.Enabled:Value() then
		if KoreanMechanics.Spell.Q:Value() then
			self:Q()
		end
		if KoreanMechanics.Spell.W:Value() then
			self:W()
		end
		if KoreanMechanics.Spell.E:Value() then
			self:E()
		end	
		if KoreanMechanics.Spell.R:Value() then
			self:R()
		end				
	end
end

function Brand:Q()
local target =  _G.SDK.TargetSelector:GetTarget(1150)
if target == nil then return end 	
	local pos = GetPred(target, 1400, (0.25 + Game.Latency())/1000)
	KoreanCast(pos, 100)
end		

function Brand:W()
local target =  _G.SDK.TargetSelector:GetTarget(1000)	
if target == nil then return end 		
	local pos = GetPred(target, math.huge, 0.625 + Game.Latency()/1000)
	KoreanCast(pos, 100)
end	

function Brand:E()
local target =  _G.SDK.TargetSelector:GetTarget(750)	
if target == nil then return end 		
	KoreanCast(target.pos, 100)
end	

function Brand:R()
local target =  _G.SDK.TargetSelector:GetTarget(850)
if target == nil then return end 	
	KoreanCast(target.pos, 100)
end		

function Brand:Draw()
	if not myHero.dead then
	   	if KoreanMechanics.Draw.Enabled:Value() then
	   		local textPos = myHero.pos:To2D()
	   		if KoreanMechanics.Spell.Enabled:Value() then
				Draw.Text("Aimbot ON", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000)) 		
			end
			if not KoreanMechanics.Spell.Enabled:Value() and KoreanMechanics.Draw.OFFDRAW:Value() then 
				Draw.Text("Aimbot OFF", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 000, 000)) 
			end 
			if KoreanMechanics.Draw.QD.Enabled:Value() then
	    	    Draw.Circle(myHero.pos, KoreanMechanics.Spell.QR:Value(), KoreanMechanics.Draw.QD.Width:Value(), KoreanMechanics.Draw.QD.Color:Value())
	    	end
	    	if KoreanMechanics.Draw.WD.Enabled:Value() then
	    	    Draw.Circle(myHero.pos, KoreanMechanics.Spell.WR:Value(), KoreanMechanics.Draw.WD.Width:Value(), KoreanMechanics.Draw.WD.Color:Value())
	    	end
	    	if KoreanMechanics.Draw.ED.Enabled:Value() then
	    	    Draw.Circle(myHero.pos, KoreanMechanics.Spell.ER:Value(), KoreanMechanics.Draw.ED.Width:Value(), KoreanMechanics.Draw.ED.Color:Value())
	    	end	    	
	    end		
	end
end

class "Ziggs"

function Ziggs:__init()
	print("Weedle's Ziggs Loaded")
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
	self:Menu()
end	

function Ziggs:Menu()
	KoreanMechanics.Spell:MenuElement({id = "Q", name = "Q Key", key = string.byte("Q")})
	KoreanMechanics.Spell:MenuElement({id = "QR", name = "Q Range", value = 850, min = 0, max = 850, step = 10})
	KoreanMechanics.Spell:MenuElement({id = "W", name = "W Key", key = string.byte("W")})
	KoreanMechanics.Spell:MenuElement({id = "WR", name = "W Range", value = 1000, min = 0, max = 1000, step = 10})	
	KoreanMechanics.Spell:MenuElement({id = "E", name = "E Key", key = string.byte("E")})
	KoreanMechanics.Spell:MenuElement({id = "ER", name = "E Range", value = 900, min = 0, max = 900, step = 10})
	KoreanMechanics.Spell:MenuElement({id = "R", name = "R Key", key = string.byte("R")})	

	KoreanMechanics.Draw:MenuElement({id = "QD", name = "Draw Q range", type = MENU})
    KoreanMechanics.Draw.QD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.QD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.QD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
    KoreanMechanics.Draw:MenuElement({id = "WD", name = "Draw W range", type = MENU})
    KoreanMechanics.Draw.WD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.WD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.WD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
    KoreanMechanics.Draw:MenuElement({id = "ED", name = "Draw E range", type = MENU})
    KoreanMechanics.Draw.ED:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.ED:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.ED:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
end

function Ziggs:Tick()
	if KoreanMechanics.Spell.Enabled:Value() then
		if KoreanMechanics.Spell.Q:Value() then
			self:Q()
		end
		if KoreanMechanics.Spell.W:Value() then
			self:W()
		end
		if KoreanMechanics.Spell.E:Value() then
			self:E()
		end	
		if KoreanMechanics.Spell.R:Value() then
			self:R()
		end	
	end
end

function Ziggs:Q()
local target =  _G.SDK.TargetSelector:GetTarget(1500)
if target == nil then return end 	
	local pos = GetPred(target, 1750, (0.25 + Game.Latency())/1000)
	KoreanCast(pos, 100)
end	

function Ziggs:W()
local target =  _G.SDK.TargetSelector:GetTarget(1500)
if target == nil then return end 	
	local pos = GetPred(target, 1750, (0.25 + Game.Latency())/1000)
	KoreanCast(pos, 100)
end	

function Ziggs:E()
local target =  _G.SDK.TargetSelector:GetTarget(1500)
if target == nil then return end 	
	local pos = GetPred(target, 1750, (0.25 + Game.Latency())/1000)
	KoreanCast(pos, 100)
end	

function Ziggs:R()
local targety =  _G.SDK.TargetSelector:GetTarget(20000)
	if targety == nil then return end 	
	local pos = GetPred(targety, 1750, 0.25 + Game.Latency()/1000)
	KoreanCast(pos, 100)
end

function Ziggs:Draw()
	if not myHero.dead then
	   	if KoreanMechanics.Draw.Enabled:Value() then
	   		local textPos = myHero.pos:To2D()
	   		if KoreanMechanics.Spell.Enabled:Value() then
				Draw.Text("Aimbot ON", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000)) 		
			end
			if not KoreanMechanics.Spell.Enabled:Value() and KoreanMechanics.Draw.OFFDRAW:Value() then 
				Draw.Text("Aimbot OFF", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 000, 000)) 
			end 
			if KoreanMechanics.Draw.QD.Enabled:Value() then
	    	    Draw.Circle(myHero.pos, KoreanMechanics.Spell.QR:Value(), KoreanMechanics.Draw.QD.Width:Value(), KoreanMechanics.Draw.QD.Color:Value())
	    	end
	    	if KoreanMechanics.Draw.WD.Enabled:Value() then
	    	    Draw.Circle(myHero.pos, KoreanMechanics.Spell.WR:Value(), KoreanMechanics.Draw.WD.Width:Value(), KoreanMechanics.Draw.WD.Color:Value())
	    	end
	    	if KoreanMechanics.Draw.ED.Enabled:Value() then
	    	    Draw.Circle(myHero.pos, KoreanMechanics.Spell.ER:Value(), KoreanMechanics.Draw.ED.Width:Value(), KoreanMechanics.Draw.ED.Color:Value())
	    	end	    	
	    end		
	end
end

class "Morgana"

function Morgana:__init()
	print("Weedle's Morgana Loaded")
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
	self:Menu()
end	

function Morgana:Menu()
	KoreanMechanics.Spell:MenuElement({id = "Q", name = "Q Key", key = string.byte("Q")})
	KoreanMechanics.Spell:MenuElement({id = "QR", name = "Q Range", value = 1300, min = 0, max = 1300, step = 10})
	KoreanMechanics.Spell:MenuElement({id = "W", name = "W Key", key = string.byte("W")})
	KoreanMechanics.Spell:MenuElement({id = "WR", name = "W Range", value = 900, min = 0, max = 900, step = 10})	

	KoreanMechanics.Draw:MenuElement({id = "QD", name = "Draw Q range", type = MENU})
    KoreanMechanics.Draw.QD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.QD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.QD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
    KoreanMechanics.Draw:MenuElement({id = "WD", name = "Draw W range", type = MENU})
    KoreanMechanics.Draw.WD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.WD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.WD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
end

function Morgana:Tick()
	if KoreanMechanics.Spell.Enabled:Value() then
		if KoreanMechanics.Spell.Q:Value() then
			self:Q()
		end
		if KoreanMechanics.Spell.W:Value() then
			self:W()
		end
	end
end

function Morgana:Q()
local target =  _G.SDK.TargetSelector:GetTarget(1400)
if target == nil then return end 	
	local pos = GetPred(target, 1200, (0.25 + Game.Latency())/1000)
	KoreanCast(pos, 100)
end	

function Morgana:W()
local target =  _G.SDK.TargetSelector:GetTarget(1000)
if target == nil then return end 	
	local pos = GetPred(target, math.huge, (0.25 + Game.Latency())/1000)
	KoreanCast(pos, 100)
end	

function Morgana:Draw()
	if not myHero.dead then
	   	if KoreanMechanics.Draw.Enabled:Value() then
	   		local textPos = myHero.pos:To2D()
	   		if KoreanMechanics.Spell.Enabled:Value() then
				Draw.Text("Aimbot ON", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000)) 		
			end
			if not KoreanMechanics.Spell.Enabled:Value() and KoreanMechanics.Draw.OFFDRAW:Value() then 
				Draw.Text("Aimbot OFF", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 000, 000)) 
			end 
			if KoreanMechanics.Draw.QD.Enabled:Value() then
	    	    Draw.Circle(myHero.pos, KoreanMechanics.Spell.QR:Value(), KoreanMechanics.Draw.QD.Width:Value(), KoreanMechanics.Draw.QD.Color:Value())
	    	end
	    	if KoreanMechanics.Draw.WD.Enabled:Value() then
	    	    Draw.Circle(myHero.pos, KoreanMechanics.Spell.WR:Value(), KoreanMechanics.Draw.WD.Width:Value(), KoreanMechanics.Draw.WD.Color:Value())
	    	end
	    end		
	end
end

class "Syndra"

function Syndra:__init()
	print("Weedle's Syndra Loaded")
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
	self:Menu()
end	

function Syndra:Menu()
	KoreanMechanics.Spell:MenuElement({id = "Q", name = "Q Key", key = string.byte("Q")})
	KoreanMechanics.Spell:MenuElement({id = "QR", name = "Q Range", value = 800, min = 0, max = 800, step = 10})
	KoreanMechanics.Spell:MenuElement({id = "W", name = "W Key", key = string.byte("W")})
	KoreanMechanics.Spell:MenuElement({id = "WR", name = "W Range", value = 925, min = 0, max = 925, step = 10})	
	KoreanMechanics.Spell:MenuElement({id = "E", name = "E Key", key = string.byte("E")})
	KoreanMechanics.Spell:MenuElement({id = "ER", name = "E Range", value = 650, min = 0, max = 650, step = 10})
	KoreanMechanics.Spell:MenuElement({id = "R", name = "R Key", key = string.byte("R")})			

	KoreanMechanics.Draw:MenuElement({id = "QD", name = "Draw Q range", type = MENU})
    KoreanMechanics.Draw.QD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.QD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.QD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
    KoreanMechanics.Draw:MenuElement({id = "WD", name = "Draw W range", type = MENU})
    KoreanMechanics.Draw.WD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.WD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.WD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
    KoreanMechanics.Draw:MenuElement({id = "ED", name = "Draw E range", type = MENU})
    KoreanMechanics.Draw.ED:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.ED:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.ED:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)}) 
end

function Syndra:Tick()
	if KoreanMechanics.Spell.Enabled:Value() then 
		if KoreanMechanics.Spell.Q:Value() then
			self:Q()
		end
		if KoreanMechanics.Spell.W:Value() and myHero:GetSpellData(_W).name == "SyndraWCast" then
			self:W()
		end
		if KoreanMechanics.Spell.E:Value() then
			self:E()
		end
		if KoreanMechanics.Spell.R:Value() then
			self:R()
		end		
	end
end

function Syndra:Q()
local target =  _G.SDK.TargetSelector:GetTarget(900)
if target == nil then return end 	
	local pos = GetPred(target, 1750, (0.25 + Game.Latency())/1000)
	KoreanCast(pos, 100)
end	

function Syndra:W()
local target =  _G.SDK.TargetSelector:GetTarget(1025)
if target == nil then return end 	
	local pos = GetPred(target, 1450, (0.25 + Game.Latency())/1000)
	KoreanCast(pos, 100)
end		

function Syndra:E()
local target =  _G.SDK.TargetSelector:GetTarget(900)
if target == nil then return end 	
	local pos = GetPred(target, 902, (0.25 + Game.Latency())/1000)
	KoreanCast(pos, 100)
end	

function Syndra:R()
local target =  _G.SDK.TargetSelector:GetTarget(845)
if target == nil then return end 	
	KoreanCast(target.pos, 100)
end		

function Syndra:Draw()
	if not myHero.dead then
	   	if KoreanMechanics.Draw.Enabled:Value() then
	   		local textPos = myHero.pos:To2D()
	   		if KoreanMechanics.Spell.Enabled:Value() then
				Draw.Text("Aimbot ON", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000)) 		
			end
			if not KoreanMechanics.Spell.Enabled:Value() and KoreanMechanics.Draw.OFFDRAW:Value() then 
				Draw.Text("Aimbot OFF", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 000, 000)) 
			end 
			if KoreanMechanics.Draw.QD.Enabled:Value() then
	    	    Draw.Circle(myHero.pos, KoreanMechanics.Spell.QR:Value(), KoreanMechanics.Draw.QD.Width:Value(), KoreanMechanics.Draw.QD.Color:Value())
	    	end
	    	if KoreanMechanics.Draw.WD.Enabled:Value() then
	    	    Draw.Circle(myHero.pos, KoreanMechanics.Spell.WR:Value(), KoreanMechanics.Draw.WD.Width:Value(), KoreanMechanics.Draw.WD.Color:Value())
	    	end
	    	if KoreanMechanics.Draw.ED.Enabled:Value() then
	    	    Draw.Circle(myHero.pos, KoreanMechanics.Spell.ER:Value(), KoreanMechanics.Draw.ED.Width:Value(), KoreanMechanics.Draw.ED.Color:Value())
	    	end
	    end		
	end
end

class "KogMaw"

function KogMaw:__init()
	print("Weedle's Kog'Maw Loaded")
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
	self:Menu()
end	

function KogMaw:Menu()
	KoreanMechanics.Spell:MenuElement({id = "Q", name = "Q Key", key = string.byte("Q")})
	KoreanMechanics.Spell:MenuElement({id = "QR", name = "Q Range", value = 1175, min = 0, max = 1175, step = 25})
	KoreanMechanics.Spell:MenuElement({id = "E", name = "E Key", key = string.byte("E")})
	KoreanMechanics.Spell:MenuElement({id = "ER", name = "E Range", value = 1200, min = 0, max = 1200, step = 10})	
	KoreanMechanics.Spell:MenuElement({id = "R", name = "R Key", key = string.byte("R")})	

	KoreanMechanics.Draw:MenuElement({id = "QD", name = "Draw Q range", type = MENU})
    KoreanMechanics.Draw.QD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.QD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.QD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
    KoreanMechanics.Draw:MenuElement({id = "ED", name = "Draw E range", type = MENU})
    KoreanMechanics.Draw.ED:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.ED:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.ED:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)}) 
    KoreanMechanics.Draw:MenuElement({id = "RD", name = "Draw R range", type = MENU})
    KoreanMechanics.Draw.RD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.RD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.RD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})     
end

function KogMaw:Tick()
	if KoreanMechanics.Spell.Enabled:Value() then 
		if KoreanMechanics.Spell.Q:Value() then
			self:Q()
		end
		if KoreanMechanics.Spell.E:Value() then
			self:E()
		end
		if KoreanMechanics.Spell.R:Value() then
			self:R()
		end
	end
end

function KogMaw:Q()
local target =  _G.SDK.TargetSelector:GetTarget(1500)
if target == nil then return end 	
	local pos = GetPred(target, 1600, (0.25 + Game.Latency())/1000)
	KoreanCast(pos, 100)
end	

function KogMaw:E()
local target =  _G.SDK.TargetSelector:GetTarget(1500)
if target == nil then return end 	
	local pos = GetPred(target, 100, (0.33 + Game.Latency())/1000)
	KoreanCast(pos, 100)
end	

function KogMaw:R()
local target =  _G.SDK.TargetSelector:GetTarget(1900)
if target == nil then return end 	
	local pos = GetPred(target, math.huge, 1 + (Game.Latency()/1000))
	KoreanCast(pos, 100)
end	

local function GetRlvl()
local lvl = myHero:GetSpellData(_R).level
	if lvl >= 1 then
		return (lvl + 1)
elseif lvl == nil then return 1
	end
end

function KogMaw:GetKogRange()
local level = GetRlvl()
	if level == nil then return 1
	end
local Range = (({0, 1200, 1500, 1800})[level])
	return Range 
end

function KogMaw:Draw()
	if not myHero.dead then
	   	if KoreanMechanics.Draw.Enabled:Value() then
	   		local textPos = myHero.pos:To2D()
	   		if KoreanMechanics.Spell.Enabled:Value() then
				Draw.Text("Aimbot ON", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000)) 		
			end
			if not KoreanMechanics.Spell.Enabled:Value() and KoreanMechanics.Draw.OFFDRAW:Value() then 
				Draw.Text("Aimbot OFF", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 000, 000)) 
			end 
			if KoreanMechanics.Draw.QD.Enabled:Value() then
	    	    Draw.Circle(myHero.pos, KoreanMechanics.Spell.QR:Value(), KoreanMechanics.Draw.QD.Width:Value(), KoreanMechanics.Draw.QD.Color:Value())
	    	end
	    	if KoreanMechanics.Draw.ED.Enabled:Value() then
	    	    Draw.Circle(myHero.pos, KoreanMechanics.Spell.ER:Value(), KoreanMechanics.Draw.ED.Width:Value(), KoreanMechanics.Draw.ED.Color:Value())
	    	end
	    	if KoreanMechanics.Draw.RD.Enabled:Value() then
	    	    Draw.Circle(myHero.pos, KogMaw:GetKogRange() , KoreanMechanics.Draw.RD.Width:Value(), KoreanMechanics.Draw.RD.Color:Value())
	    	end	    	
	    end		
	end
end

class "Lux"

function Lux:__init()
	print("Weedle's Lux Loaded")
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
	self:Menu()
end	

function Lux:Menu()
	KoreanMechanics.Spell:MenuElement({id = "Q", name = "Q Key", key = string.byte("Q")})
	KoreanMechanics.Spell:MenuElement({id = "QR", name = "Q Range", value = 1175, min = 0, max = 1175, step = 10})
	KoreanMechanics.Spell:MenuElement({id = "E", name = "E Key", key = string.byte("E")})
	KoreanMechanics.Spell:MenuElement({id = "ER", name = "E Range", value = 1200, min = 0, max = 1200, step = 10})	
	KoreanMechanics.Spell:MenuElement({id = "R", name = "R Key", key = string.byte("R")})

	KoreanMechanics.Draw:MenuElement({id = "QD", name = "Draw Q range", type = MENU})
    KoreanMechanics.Draw.QD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.QD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.QD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
    KoreanMechanics.Draw:MenuElement({id = "ED", name = "Draw E range", type = MENU})
    KoreanMechanics.Draw.ED:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.ED:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.ED:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)}) 
    KoreanMechanics.Draw:MenuElement({id = "RD", name = "Draw R range", type = MENU})
    KoreanMechanics.Draw.RD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.RD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.RD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})     
end

function Lux:Tick()
	if KoreanMechanics.Spell.Enabled:Value() then 
		if KoreanMechanics.Spell.Q:Value() then
			self:Q()
		end
		if KoreanMechanics.Spell.E:Value() and myHero:GetSpellData(_E).name == "LuxLightStrikeKugel" then
			self:E()
		end
		if KoreanMechanics.Spell.R:Value() then
			self:R()
		end
	end
end

function Lux:Q()
local target =  _G.SDK.TargetSelector:GetTarget(1500)
if target == nil then return end 	
	local pos = GetPred(target, 1200, (0.25 + Game.Latency())/1000)
	KoreanCast(pos, 100)
end	

function Lux:E()
local target =  _G.SDK.TargetSelector:GetTarget(1500)
if target == nil then return end 	
	local pos = GetPred(target, 1300, (0.25 + Game.Latency())/1000)
	KoreanCast(pos, 100)
end	

function Lux:R()
local target =  _G.SDK.TargetSelector:GetTarget(3440)
if target == nil then return end 	
	local pos = GetPred(target, 3000, 1 + (Game.Latency()/1000))
	KoreanCast(pos, 100)
end	

function Lux:Draw()
	if not myHero.dead then
	   	if KoreanMechanics.Draw.Enabled:Value() then
	   		local textPos = myHero.pos:To2D()
	   		if KoreanMechanics.Spell.Enabled:Value() then
				Draw.Text("Aimbot ON", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000)) 		
			end
			if not KoreanMechanics.Spell.Enabled:Value() and KoreanMechanics.Draw.OFFDRAW:Value() then 
				Draw.Text("Aimbot OFF", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 000, 000)) 
			end 
			if KoreanMechanics.Draw.QD.Enabled:Value() then
	    	    Draw.Circle(myHero.pos, KoreanMechanics.Spell.QR:Value(), KoreanMechanics.Draw.QD.Width:Value(), KoreanMechanics.Draw.QD.Color:Value())
	    	end
	    	if KoreanMechanics.Draw.ED.Enabled:Value() then
	    	    Draw.Circle(myHero.pos, KoreanMechanics.Spell.ER:Value(), KoreanMechanics.Draw.ED.Width:Value(), KoreanMechanics.Draw.ED.Color:Value())
	    	end
	    	if KoreanMechanics.Draw.RD.Enabled:Value() then
	    	    Draw.CircleMinimap(myHero.pos, 3340 , KoreanMechanics.Draw.RD.Width:Value(), KoreanMechanics.Draw.RD.Color:Value())
	    	end	    	
	    end		
	end
end

class "Cassiopeia"

function Cassiopeia:__init()
	print("Weedle's Cassiopeia Loaded")
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
	self:Menu()
end	

function Cassiopeia:Menu()
	KoreanMechanics.Spell:MenuElement({id = "Q", name = "Q Key", key = string.byte("Q")})
	KoreanMechanics.Spell:MenuElement({id = "QR", name = "Q Range", value = 850, min = 0, max = 850, step = 10})
	KoreanMechanics.Spell:MenuElement({id = "W", name = "W Key", key = string.byte("W")})
	KoreanMechanics.Spell:MenuElement({id = "WR", name = "W Range", value = 800, min = 0, max = 800, step = 10})	
	KoreanMechanics.Spell:MenuElement({id = "E", name = "E Usage", key = string.byte("E")})	
	KoreanMechanics.Spell:MenuElement({id = "R", name = "R Key", key = string.byte("R")})

	KoreanMechanics.Draw:MenuElement({id = "QD", name = "Draw Q range", type = MENU})
    KoreanMechanics.Draw.QD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.QD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.QD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
    KoreanMechanics.Draw:MenuElement({id = "WD", name = "Draw W range", type = MENU})
    KoreanMechanics.Draw.WD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.WD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.WD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)}) 
    KoreanMechanics.Draw:MenuElement({id = "RD", name = "Draw R range", type = MENU})
    KoreanMechanics.Draw.RD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.RD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.RD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})     
end

function Cassiopeia:Tick()
	if KoreanMechanics.Spell.Enabled:Value() then 
		if KoreanMechanics.Spell.Q:Value() then
			self:Q()
		end
		if KoreanMechanics.Spell.W:Value() then
			self:W()
		end
		if KoreanMechanics.Spell.E:Value() then
			self:E()
		end		
		if KoreanMechanics.Spell.R:Value() then
			self:R()
		end
	end
end

function Cassiopeia:Q()
local target =  _G.SDK.TargetSelector:GetTarget(950)
if target == nil then return end 	
	local pos = GetPred(target, math.huge, 0.41 + (Game.Latency()/1000))
	KoreanCast(pos, 100)
end	

function Cassiopeia:W()
local target =  _G.SDK.TargetSelector:GetTarget(900)
if target == nil then return end 	
	local pos = GetPred(target, 1500, (0.25 + Game.Latency())/1000)
	KoreanCast(pos, 100)
end		

function Cassiopeia:E()
local target =  _G.SDK.TargetSelector:GetTarget(800)
if target == nil then return end 	
	KoreanCast(target.pos, 100)
end		

function Cassiopeia:R()
local target =  _G.SDK.TargetSelector:GetTarget(925)
if target == nil then return end 	
	local pos = GetPred(target, 1500, (0.25 + Game.Latency())/1000)
	KoreanCast(pos, 100)
end			

function Cassiopeia:Draw()
	if not myHero.dead then
	   	if KoreanMechanics.Draw.Enabled:Value() then
	   		local textPos = myHero.pos:To2D()
	   		if KoreanMechanics.Spell.Enabled:Value() then
				Draw.Text("Aimbot ON", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000)) 		
			end
			if not KoreanMechanics.Spell.Enabled:Value() and KoreanMechanics.Draw.OFFDRAW:Value() then 
				Draw.Text("Aimbot OFF", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 000, 000)) 
			end 
			if KoreanMechanics.Draw.QD.Enabled:Value() then
	    	    Draw.Circle(myHero.pos, KoreanMechanics.Spell.QR:Value(), KoreanMechanics.Draw.QD.Width:Value(), KoreanMechanics.Draw.QD.Color:Value())
	    	end
	    	if KoreanMechanics.Draw.WD.Enabled:Value() then
	    	    Draw.Circle(myHero.pos, KoreanMechanics.Spell.WR:Value(), KoreanMechanics.Draw.WD.Width:Value(), KoreanMechanics.Draw.WD.Color:Value())
	    	end
	    	if KoreanMechanics.Draw.RD.Enabled:Value() then
	    	    Draw.Circle(myHero.pos, 825 , KoreanMechanics.Draw.RD.Width:Value(), KoreanMechanics.Draw.RD.Color:Value())
	    	end	    	
	    end		
	end
end

class "Karma"

function Karma:__init()
	print("Weedle's Karma Loaded")
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
	self:Menu()
end	

function Karma:Menu()
	KoreanMechanics.Spell:MenuElement({id = "Q", name = "Q Key", key = string.byte("Q")})
	KoreanMechanics.Spell:MenuElement({id = "QR", name = "Q Range", value = 950, min = 0, max = 950, step = 10})

	KoreanMechanics.Draw:MenuElement({id = "QD", name = "Draw Q range", type = MENU})
    KoreanMechanics.Draw.QD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.QD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.QD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
end

function Karma:Tick()
	if KoreanMechanics.Spell.Enabled:Value() then 
		if KoreanMechanics.Spell.Q:Value() then
			self:Q()
		end
	end
end

function Karma:Q()
local target =  _G.SDK.TargetSelector:GetTarget(1050)
if target == nil then return end 	
	local pos = GetPred(target, math.huge, (0.25 + Game.Latency())/1000)
	KoreanCast(pos, 100)
end	

function Karma:Draw()
	if not myHero.dead then
		if KoreanMechanics.Draw.Enabled:Value() then
			local textPos = myHero.pos:To2D()
			if KoreanMechanics.Spell.Enabled:Value() then
				Draw.Text("Aimbot ON", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000)) 		
			end
			if not KoreanMechanics.Spell.Enabled:Value() and KoreanMechanics.Draw.OFFDRAW:Value() then 
				Draw.Text("Aimbot OFF", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 000, 000)) 
			end 
			if KoreanMechanics.Draw.QD.Enabled:Value() then
			    Draw.Circle(myHero.pos, KoreanMechanics.Spell.QR:Value(), KoreanMechanics.Draw.QD.Width:Value(), KoreanMechanics.Draw.QD.Color:Value())
			end
		end
	end
end

class "Orianna"

function Orianna:__init()
	print("Weedle's Orianna Loaded")
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
	self:Menu()
end	

function Orianna:Menu()
	KoreanMechanics.Spell:MenuElement({id = "Q", name = "Q Key", key = string.byte("Q")})
	KoreanMechanics.Spell:MenuElement({id = "QR", name = "Q Range", value = 1225, min = 0, max = 1225, step = 25})

	KoreanMechanics.Draw:MenuElement({id = "QD", name = "Draw Max Q range", type = MENU})
    KoreanMechanics.Draw.QD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.QD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.QD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
end

function Orianna:Tick()
	if KoreanMechanics.Spell.Enabled:Value() then 
		if KoreanMechanics.Spell.Q:Value() then
			self:Q()
		end
	end
end

function Orianna:Q()
local target =  _G.SDK.TargetSelector:GetTarget(1225)
if target == nil then return end 	
	local pos = GetPred(target, 1200, (0.25 + Game.Latency())/1000)
	KoreanCast(pos, 100)
end	

function Orianna:Draw()
	if not myHero.dead then
		if KoreanMechanics.Draw.Enabled:Value() then
			local textPos = myHero.pos:To2D()
			if KoreanMechanics.Spell.Enabled:Value() then
				Draw.Text("Aimbot ON", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000)) 		
			end
			if not KoreanMechanics.Spell.Enabled:Value() and KoreanMechanics.Draw.OFFDRAW:Value() then 
				Draw.Text("Aimbot OFF", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 000, 000)) 
			end 
			if KoreanMechanics.Draw.QD.Enabled:Value() then
			    Draw.Circle(myHero.pos, KoreanMechanics.Spell.QR:Value(), KoreanMechanics.Draw.QD.Width:Value(), KoreanMechanics.Draw.QD.Color:Value())
			end
		end
	end
end

class "Ryze"

function Ryze:__init()
	print("Weedle's Ryze Loaded")
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
	self:Menu()
end	

function Ryze:Menu()
	KoreanMechanics.Spell:MenuElement({id = "Q", name = "Q Key", key = string.byte("Q")})
	KoreanMechanics.Spell:MenuElement({id = "QR", name = "Q Range", value = 1000, min = 0, max = 1000, step = 10})
	KoreanMechanics.Spell:MenuElement({id = "W", name = "W Key", key = string.byte("W")})
	KoreanMechanics.Spell:MenuElement({id = "WR", name = "W Range", value = 615, min = 0, max = 615, step = 10})	
	KoreanMechanics.Spell:MenuElement({id = "E", name = "E Usage", key = string.byte("E")})	
	KoreanMechanics.Spell:MenuElement({id = "ER", name = "E Range", value = 615, min = 0, max = 615, step = 10})

	KoreanMechanics.Draw:MenuElement({id = "QD", name = "Draw Q range", type = MENU})
    KoreanMechanics.Draw.QD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.QD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.QD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
    KoreanMechanics.Draw:MenuElement({id = "WD", name = "Draw W range", type = MENU})
    KoreanMechanics.Draw.WD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.WD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.WD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)}) 
    KoreanMechanics.Draw:MenuElement({id = "ED", name = "Draw E range", type = MENU})
    KoreanMechanics.Draw.ED:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.ED:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.ED:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})  
end

function Ryze:Tick()
	if KoreanMechanics.Spell.Enabled:Value() then 
		if KoreanMechanics.Spell.Q:Value() then
			self:Q()
		end
		if KoreanMechanics.Spell.W:Value() then
			self:W()
		end
		if KoreanMechanics.Spell.E:Value() then
			self:E()
		end	
	end
end

function Ryze:Q()
local target =  _G.SDK.TargetSelector:GetTarget(1100)
if target == nil then return end 	
	local pos = GetPred(target, 1700, (0.25 + Game.Latency())/1000)
	KoreanCast(pos, 100)
end	

function Ryze:W()
local target =  _G.SDK.TargetSelector:GetTarget(800)
if target == nil then return end 	
	KoreanCast(target.pos, 100)
end	

function Ryze:E()
local target =  _G.SDK.TargetSelector:GetTarget(800)
if target == nil then return end 	
	KoreanCast(target.pos, 100)
end	

function Ryze:Draw()
	if not myHero.dead then
	   	if KoreanMechanics.Draw.Enabled:Value() then
	   		local textPos = myHero.pos:To2D()
	   		if KoreanMechanics.Spell.Enabled:Value() then
				Draw.Text("Aimbot ON", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000)) 		
			end
			if not KoreanMechanics.Spell.Enabled:Value() and KoreanMechanics.Draw.OFFDRAW:Value() then 
				Draw.Text("Aimbot OFF", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 000, 000)) 
			end 
			if KoreanMechanics.Draw.QD.Enabled:Value() then
	    	    Draw.Circle(myHero.pos, KoreanMechanics.Spell.QR:Value(), KoreanMechanics.Draw.QD.Width:Value(), KoreanMechanics.Draw.QD.Color:Value())
	    	end
	    	if KoreanMechanics.Draw.WD.Enabled:Value() then
	    	    Draw.Circle(myHero.pos, KoreanMechanics.Spell.WR:Value(), KoreanMechanics.Draw.WD.Width:Value(), KoreanMechanics.Draw.WD.Color:Value())
	    	end
	    	if KoreanMechanics.Draw.ED.Enabled:Value() then
	    	    Draw.Circle(myHero.pos, KoreanMechanics.Spell.ER:Value(), KoreanMechanics.Draw.ED.Width:Value(), KoreanMechanics.Draw.ED.Color:Value())
	    	end	    	
	    end		
	end
end

class "Jhin"

function Jhin:__init()
	print("Weedle's Jhin Loaded")
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
	self:Menu()
end	

function Jhin:Menu()
	KoreanMechanics.Spell:MenuElement({id = "Q", name = "Q Key", key = string.byte("Q")})
	KoreanMechanics.Spell:MenuElement({id = "W", name = "W Key", key = string.byte("W")})
	KoreanMechanics.Spell:MenuElement({id = "WR", name = "W Range", value = 2500, min = 0, max = 600, step = 10})		
	KoreanMechanics.Spell:MenuElement({id = "R", name = "R Key", key = string.byte("R")})

	KoreanMechanics.Draw:MenuElement({id = "QD", name = "Draw Q range", type = MENU})
    KoreanMechanics.Draw.QD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.QD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.QD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
    KoreanMechanics.Draw:MenuElement({id = "WD", name = "Draw W range", type = MENU})
    KoreanMechanics.Draw.WD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.WD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.WD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})   
    KoreanMechanics.Draw:MenuElement({id = "RD", name = "Draw R range", type = MENU})
    KoreanMechanics.Draw.RD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.RD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.RD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})   
end

function Jhin:Tick()
	if KoreanMechanics.Spell.Enabled:Value() then 
		if KoreanMechanics.Spell.Q:Value() then
			self:Q()
		end
		if KoreanMechanics.Spell.W:Value() then
			self:W()
		end
		if KoreanMechanics.Spell.R:Value() then
			self:R()
		end				
	end
end

function Jhin:Q()
local target =  _G.SDK.TargetSelector:GetTarget(800)
if target == nil then return end 	
	KoreanCast(target.pos, 100)
end		

function Jhin:W()
local target =  _G.SDK.TargetSelector:GetTarget(2600)
if target == nil then return end 	
	local pos = GetPred(target, 5000, 0.25 + (Game.Latency()/1000))
	KoreanCast(pos, 100)
end	

function Jhin:R()
local target =  _G.SDK.TargetSelector:GetTarget(3100)
if target == nil then return end 	
	local pos = GetPred(target, 1200, 1 + (Game.Latency()/1000))
	KoreanCast(pos, 100)
end	

function Jhin:Draw()
	if not myHero.dead then
	   	if KoreanMechanics.Draw.Enabled:Value() then
	   		local textPos = myHero.pos:To2D()
	   		if KoreanMechanics.Spell.Enabled:Value() then
				Draw.Text("Aimbot ON", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000)) 		
			end
			if not KoreanMechanics.Spell.Enabled:Value() and KoreanMechanics.Draw.OFFDRAW:Value() then 
				Draw.Text("Aimbot OFF", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 000, 000)) 
			end 
			if KoreanMechanics.Draw.QD.Enabled:Value() then
	    	    Draw.Circle(myHero.pos, 600, KoreanMechanics.Draw.QD.Width:Value(), KoreanMechanics.Draw.QD.Color:Value())
	    	end
	    	if KoreanMechanics.Draw.WD.Enabled:Value() then
	    	    Draw.Circle(myHero.pos, KoreanMechanics.Spell.WR:Value(), KoreanMechanics.Draw.WD.Width:Value(), KoreanMechanics.Draw.WD.Color:Value())
	    	end
	    	if KoreanMechanics.Draw.RD.Enabled:Value() then
	    	    Draw.Circleminimap(myHero.pos, 3000 , KoreanMechanics.Draw.RD.Width:Value(), KoreanMechanics.Draw.RD.Color:Value())
	    	end	   	    	   	
	    end		
	end
end

class "Jayce"

function Jayce:__init()
	print("Weedle's Jayce Loaded")
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
	self:Menu()
end	

function Jayce:Menu()
	KoreanMechanics.Spell:MenuElement({id = "Q", name = "Q Key", key = string.byte("Q")})
	KoreanMechanics.Spell:MenuElement({id = "QR", name = "Q Max Range", value = 1600, min = 0, max = 1600, step = 10})

	KoreanMechanics.Draw:MenuElement({id = "QD", name = "Draw Q range", type = MENU})
    KoreanMechanics.Draw.QD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.QD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.QD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
end

function Jayce:Tick()
	if KoreanMechanics.Spell.Enabled:Value() then 
		if KoreanMechanics.Spell.Q:Value() and myHero:GetSpellData(_Q).name == "JayceShockBlast" then
			self:Q()
		end
	end
end

function Jayce:Q()
local target =  _G.SDK.TargetSelector:GetTarget(1600)
if target == nil then return end 	
	local pos = GetPred(target, 1382, (0.25 + Game.Latency())/1000)
	KoreanCast(pos, 100)
end	

function Jayce:Draw()
	if not myHero.dead then
		if KoreanMechanics.Draw.Enabled:Value() then
			local textPos = myHero.pos:To2D()
			if KoreanMechanics.Spell.Enabled:Value() then
				Draw.Text("Aimbot ON", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000)) 		
			end
			if not KoreanMechanics.Spell.Enabled:Value() and KoreanMechanics.Draw.OFFDRAW:Value() then 
				Draw.Text("Aimbot OFF", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 000, 000)) 
			end 
			if KoreanMechanics.Draw.QD.Enabled:Value() then
			    Draw.Circle(myHero.pos, KoreanMechanics.Spell.QR:Value(), KoreanMechanics.Draw.QD.Width:Value(), KoreanMechanics.Draw.QD.Color:Value())
			end
		end
	end
end

class "Kennen"

function Kennen:__init()
	print("Weedle's Kennen Loaded")
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
	self:Menu()
end	

function Kennen:Menu()
	KoreanMechanics.Spell:MenuElement({id = "Q", name = "Q Key", key = string.byte("Q")})
	KoreanMechanics.Spell:MenuElement({id = "QR", name = "Q Range", value = 950, min = 0, max = 950, step = 10})

	KoreanMechanics.Draw:MenuElement({id = "QD", name = "Draw Q range", type = MENU})
    KoreanMechanics.Draw.QD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.QD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.QD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
end

function Kennen:Tick()
	if KoreanMechanics.Spell.Enabled:Value() then 
		if KoreanMechanics.Spell.Q:Value() then
			self:Q()
		end
	end
end

function Kennen:Q()
local target =  _G.SDK.TargetSelector:GetTarget(1050)
if target == nil then return end 	
	local pos = GetPred(target, 1700, (0.25 + Game.Latency())/1000)
	KoreanCast(pos, 100)
end	

function Kennen:Draw()
	if not myHero.dead then
		if KoreanMechanics.Draw.Enabled:Value() then
			local textPos = myHero.pos:To2D()
			if KoreanMechanics.Spell.Enabled:Value() then
				Draw.Text("Aimbot ON", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000)) 		
			end
			if not KoreanMechanics.Spell.Enabled:Value() and KoreanMechanics.Draw.OFFDRAW:Value() then 
				Draw.Text("Aimbot OFF", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 000, 000)) 
			end 
			if KoreanMechanics.Draw.QD.Enabled:Value() then
			    Draw.Circle(myHero.pos, KoreanMechanics.Spell.QR:Value(), KoreanMechanics.Draw.QD.Width:Value(), KoreanMechanics.Draw.QD.Color:Value())
			end
		end
	end
end

class "Thresh"

function Thresh:__init()
	print("Weedle's Thresh Loaded")
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
	self:Menu()
end	

function Thresh:Menu()
	KoreanMechanics.Spell:MenuElement({id = "Q", name = "Q Key", key = string.byte("Q")})
	KoreanMechanics.Spell:MenuElement({id = "QR", name = "Q Range", value = 1050, min = 0, max = 1050, step = 10})
	KoreanMechanics.Spell:MenuElement({id = "E", name = "E Key", key = string.byte("E")})	
	KoreanMechanics.Spell:MenuElement({id = "EMode", name = "E Pull Toggle", key = string.byte("T"), toggle = true})	

	KoreanMechanics.Draw:MenuElement({id = "QD", name = "Draw Q range", type = MENU})
    KoreanMechanics.Draw.QD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.QD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.QD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
end

function Thresh:Tick()
	if KoreanMechanics.Spell.Enabled:Value() then 
		if KoreanMechanics.Spell.Q:Value() and myHero:GetSpellData(_Q).name == "ThreshQ" then
			self:Q()
		end
		if KoreanMechanics.Spell.E:Value() then
			self:E()
		end		
	end
end

function Thresh:Q()
local target =  _G.SDK.TargetSelector:GetTarget(1500)
if target == nil then return end 	
	local pos = GetPred(target, 1900, 0.5 + (Game.Latency()/1000))
	KoreanCast(pos, 100)
end	

function Thresh:E()
local target =  _G.SDK.TargetSelector:GetTarget(600)
if target == nil then return end 
	local pos = GetPred(target, 2000, 0.25 + (0.25 + Game.Latency())/1000)
	if KoreanMechanics.Spell.EMode:Value() then
		local pos2 = Vector(myHero.pos) + (Vector(myHero.pos) - Vector(pos)):Normalized()*400
		KoreanCast(pos2, 100)
	end
	KoreanCast(pos, 100)
end

function Thresh:Draw()
	if not myHero.dead then
		if KoreanMechanics.Draw.Enabled:Value() then
			local textPos = myHero.pos:To2D()
			if KoreanMechanics.Spell.Enabled:Value() then
				Draw.Text("Aimbot ON", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000)) 		
			end
			if not KoreanMechanics.Spell.Enabled:Value() and KoreanMechanics.Draw.OFFDRAW:Value() then 
				Draw.Text("Aimbot OFF", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 000, 000)) 
			end
			if KoreanMechanics.Spell.EMode:Value() then
				Draw.Text("E Pull Mode ON", 20, textPos.x - 80, textPos.y + 60, Draw.Color(255, 000, 255, 000)) 		
			end
			if not KoreanMechanics.Spell.EMode:Value()  then 
				Draw.Text("U Pull Mode OFF", 20, textPos.x - 80, textPos.y + 60, Draw.Color(255, 255, 000, 000)) 
			end 			 
			if KoreanMechanics.Draw.QD.Enabled:Value() then
			    Draw.Circle(myHero.pos, KoreanMechanics.Spell.QR:Value(), KoreanMechanics.Draw.QD.Width:Value(), KoreanMechanics.Draw.QD.Color:Value())
			end
		end
	end
end

class "Amumu"

function Amumu:__init()
	print("Weedle's Amumu Loaded")
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
	self:Menu()
end	

function Amumu:Menu()
	KoreanMechanics.Spell:MenuElement({id = "Q", name = "Q Key", key = string.byte("Q")})
	KoreanMechanics.Spell:MenuElement({id = "QR", name = "Q Range", value = 1100, min = 0, max = 1100, step = 10})

	KoreanMechanics.Draw:MenuElement({id = "QD", name = "Draw Q range", type = MENU})
    KoreanMechanics.Draw.QD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.QD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.QD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
end

function Amumu:Tick()
	if KoreanMechanics.Spell.Enabled:Value() then 
		if KoreanMechanics.Spell.Q:Value() then
			self:Q()
		end
	end
end

function Amumu:Q()
local target =  _G.SDK.TargetSelector:GetTarget(1200)
if target == nil then return end 	
	local pos = GetPred(target, 2000, 0.15 + (Game.Latency()/1000))
	KoreanCast(pos, 100)
end	

function Amumu:Draw()
	if not myHero.dead then
		if KoreanMechanics.Draw.Enabled:Value() then
			local textPos = myHero.pos:To2D()
			if KoreanMechanics.Spell.Enabled:Value() then
				Draw.Text("Aimbot ON", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000)) 		
			end
			if not KoreanMechanics.Spell.Enabled:Value() and KoreanMechanics.Draw.OFFDRAW:Value() then 
				Draw.Text("Aimbot OFF", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 000, 000)) 
			end 
			if KoreanMechanics.Draw.QD.Enabled:Value() then
			    Draw.Circle(myHero.pos, KoreanMechanics.Spell.QR:Value(), KoreanMechanics.Draw.QD.Width:Value(), KoreanMechanics.Draw.QD.Color:Value())
			end
		end
	end
end

class "Elise"

function Elise:__init()
	print("Weedle's Elise Loaded")
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
	self:Menu()
end	

function Elise:Menu()
	KoreanMechanics.Spell:MenuElement({id = "Q", name = "Q Key", key = string.byte("Q")})
	KoreanMechanics.Spell:MenuElement({id = "QR", name = "max Q Range", value = 625, min = 0, max = 625, step = 10})
	KoreanMechanics.Spell:MenuElement({id = "W", name = "W Key", key = string.byte("W")})
	KoreanMechanics.Spell:MenuElement({id = "WR", name = "W Range", value = 950, min = 0, max = 950, step = 10})		
	KoreanMechanics.Spell:MenuElement({id = "E", name = "E Usage", key = string.byte("E")})	
	KoreanMechanics.Spell:MenuElement({id = "ER", name = "E Range", value = 1075, min = 0, max = 1075, step = 10})
	KoreanMechanics.Spell:MenuElement({id = "EMode", name = "Spider E on Enemy Toggle", key = string.byte("T"), toggle = true})		

	KoreanMechanics.Draw:MenuElement({id = "QD", name = "Draw Q range", type = MENU})
    KoreanMechanics.Draw.QD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.QD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.QD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
    KoreanMechanics.Draw:MenuElement({id = "WD", name = "Draw W range", type = MENU})
    KoreanMechanics.Draw.WD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.WD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.WD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)}) 
    KoreanMechanics.Draw:MenuElement({id = "ED", name = "Draw E range", type = MENU})
    KoreanMechanics.Draw.ED:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.ED:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.ED:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})  
end

function Elise:Tick()
	if KoreanMechanics.Spell.Enabled:Value() then 
		if KoreanMechanics.Spell.Q:Value() then
			self:Q()
		end
		if KoreanMechanics.Spell.W:Value() and myHero:GetSpellData(_W).name == "EliseHumanW" then
			self:W()
		end
		if KoreanMechanics.Spell.E:Value() then
			self:E()
		end	
	end
end

function Elise:Q()
local target =  _G.SDK.TargetSelector:GetTarget(725)
if target == nil then return end 	
	KoreanCast(target.pos, 100)
end	

function Elise:W()
local target =  _G.SDK.TargetSelector:GetTarget(1050)
if target == nil then return end 	
	local pos = GetPred(target, 2000, 0.25 + (Game.Latency()/1000))
	KoreanCast(pos, 100)
end	

function Elise:E()
local target =  _G.SDK.TargetSelector:GetTarget(1175)
if target == nil then return end
	local pos = GetPred(target, 1600, 0.25 + (Game.Latency()/1000))
	if myHero:GetSpellData(_E).name == "EliseHumanE" then
		KoreanCast(pos, 100)
	end
	if myHero:GetSpellData(_E).name == "EliseSpiderEInitial" and KoreanMechanics.Spell.EMode:Value() then
		KoreanCast(target.pos, 100)
	end
	KoreanCast(mousePos, 100)
end

function Elise:Draw()
	if not myHero.dead then
	   	if KoreanMechanics.Draw.Enabled:Value() then
	   		local textPos = myHero.pos:To2D()
	   		if KoreanMechanics.Spell.Enabled:Value() then
				Draw.Text("Aimbot ON", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000)) 		
			end
			if not KoreanMechanics.Spell.Enabled:Value() and KoreanMechanics.Draw.OFFDRAW:Value() then 
				Draw.Text("Aimbot OFF", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 000, 000)) 
			end
			if KoreanMechanics.Spell.EMode:Value() then
				Draw.Text("Spider E on Enemies ON", 20, textPos.x - 80, textPos.y + 60, Draw.Color(255, 000, 255, 000)) 		
			end
			if not KoreanMechanics.Spell.EMode:Value()  then 
				Draw.Text("Spider E on Enemies OFF", 20, textPos.x - 80, textPos.y + 60, Draw.Color(255, 255, 000, 000)) 
			end 	
			if KoreanMechanics.Draw.QD.Enabled:Value() and myHero:GetSpellData(_Q).name == "EliseHumanQ"  then
	    	    Draw.Circle(myHero.pos, KoreanMechanics.Spell.QR:Value(), KoreanMechanics.Draw.QD.Width:Value(), KoreanMechanics.Draw.QD.Color:Value())
	    	end
	    	if KoreanMechanics.Draw.QD.Enabled:Value() and myHero:GetSpellData(_Q).name ~= "EliseHumanQ" then
	    		 Draw.Circle(myHero.pos, 475, KoreanMechanics.Draw.QD.Width:Value(), KoreanMechanics.Draw.QD.Color:Value())
	    	end	 
	    	if KoreanMechanics.Draw.WD.Enabled:Value() then
	    	    Draw.Circle(myHero.pos, KoreanMechanics.Spell.WR:Value(), KoreanMechanics.Draw.WD.Width:Value(), KoreanMechanics.Draw.WD.Color:Value())
	    	end
	    	if KoreanMechanics.Draw.ED.Enabled:Value() and myHero:GetSpellData(_E).name == "EliseHumanE" then
	    	    Draw.Circle(myHero.pos, KoreanMechanics.Spell.ER:Value(), KoreanMechanics.Draw.ED.Width:Value(), KoreanMechanics.Draw.ED.Color:Value())
	    	end
	    	if KoreanMechanics.Draw.ED.Enabled:Value() and myHero:GetSpellData(_E).name ~= "EliseHumanE" then
	    	    Draw.Circle(myHero.pos, 800, KoreanMechanics.Draw.ED.Width:Value(), KoreanMechanics.Draw.ED.Color:Value())
	    	end		    		    	
	    end		
	end
end

class "Zilean"

function Zilean:__init()
	print("Weedle's Zilean Loaded")
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
	self:Menu()
end	

function Zilean:Menu()
	KoreanMechanics:MenuElement({id = "Speed", name = "Q Pred Speed", value = 1500, min = 500, max = 2000, step = 50})
	KoreanMechanics.Spell:MenuElement({id = "Q", name = "Q Key", key = string.byte("Q")})
	KoreanMechanics.Spell:MenuElement({id = "QR", name = "max Q Range", value = 900, min = 0, max = 900, step = 10})
	KoreanMechanics.Spell:MenuElement({id = "E", name = "E Usage", key = string.byte("E")})	
	KoreanMechanics.Spell:MenuElement({id = "ER", name = "E Range", value = 750, min = 0, max = 750, step = 10})
	KoreanMechanics.Spell:MenuElement({id = "EMode", name = "Auto target E Toggle", key = string.byte("T"), toggle = true})	
	KoreanMechanics.Spell:MenuElement({id = "RS", name = "R Settings", type = MENU})
	KoreanMechanics.Spell.RS:MenuElement({id = "R", name = "R Usage", value = true})				
	KoreanMechanics.Spell.RS:MenuElement({id = "RHP", name = "Smart R when HP% [?]", value = 10, min = 0, max = 100, step = 1})	

	KoreanMechanics.Draw:MenuElement({id = "QD", name = "Draw Q range", type = MENU})
    KoreanMechanics.Draw.QD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.QD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.QD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
    KoreanMechanics.Draw:MenuElement({id = "ED", name = "Draw E range", type = MENU})
    KoreanMechanics.Draw.ED:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.ED:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.ED:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})     
    KoreanMechanics.Draw:MenuElement({id = "RD", name = "Draw R range", type = MENU})
    KoreanMechanics.Draw.RD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.RD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.RD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})  
end

function Zilean:Tick()
	if KoreanMechanics.Spell.Enabled:Value() then 
		if KoreanMechanics.Spell.Q:Value() then
			self:Q()
		end
		if KoreanMechanics.Spell.E:Value() then
			self:E()
		end
		if KoreanMechanics.Spell.RS.R:Value() then
			self:R()
		end
	end
end

function Zilean:Q()
local target =  _G.SDK.TargetSelector:GetTarget(1000)
if target == nil then return end 	
	local pos = GetPred(target, KoreanMechanics.Speed:Value(), 0.25 + (Game.Latency()/1000))
	KoreanCast(pos, 100)
end	

function Zilean:E()
local target =  _G.SDK.TargetSelector:GetTarget(850)
	if KoreanMechanics.Spell.EMode:Value() then 
		if target == nil then KoreanCast(myHero.pos, 100) end
		if target then
			KoreanCast(target.pos, 100)
		end
	end
	if not KoreanMechanics.Spell.EMode:Value() then 
		if target == nil then return end
	KoreanCast(mousePos, 100)
	end
end

function Zilean:R()
local Heroes = nil
	if KoreanMechanics.Spell.RS.R:Value() and Ready(_R) then
		local target =  _G.SDK.TargetSelector:GetTarget(1500)
		if target == nil then return end
		if target then
			for i = 1, Game.HeroCount() do
			local Heroes = Game.Hero(i)
				if Heroes.distance < 900 and Heroes.isAlly and not Heroes.dead and Heroes.distance < 900 and (Heroes.health/Heroes.maxHealth) < (KoreanMechanics.Spell.RS.RHP:Value()/100) then
					Control.CastSpell(HK_R, Heroes)
				end
			end
			if (myHero.health/myHero.maxHealth) < (KoreanMechanics.Spell.RS.RHP:Value()/100) then
				Control.CastSpell(HK_R, myHero)
			end
		end
	end
end

function Zilean:Draw()
	if not myHero.dead then
		if KoreanMechanics.Draw.Enabled:Value() then
			local textPos = myHero.pos:To2D()
			if KoreanMechanics.Spell.Enabled:Value() then
				Draw.Text("Aimbot ON", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000)) 		
			end
			if not KoreanMechanics.Spell.Enabled:Value() and KoreanMechanics.Draw.OFFDRAW:Value() then 
				Draw.Text("Aimbot OFF", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 000, 000)) 
			end
			if KoreanMechanics.Spell.EMode:Value() then
				Draw.Text("Smart E ON", 20, textPos.x - 80, textPos.y + 60, Draw.Color(255, 000, 255, 000)) 		
			end
			if not KoreanMechanics.Spell.EMode:Value()  then 
				Draw.Text("Smart E OFF", 20, textPos.x - 80, textPos.y + 60, Draw.Color(255, 255, 000, 000)) 
			end 			 
			if KoreanMechanics.Draw.QD.Enabled:Value() then
			    Draw.Circle(myHero.pos, KoreanMechanics.Spell.QR:Value(), KoreanMechanics.Draw.QD.Width:Value(), KoreanMechanics.Draw.QD.Color:Value())
			end
	    	if KoreanMechanics.Draw.ED.Enabled:Value() then
	    	    Draw.Circle(myHero.pos, KoreanMechanics.Spell.ER:Value(), KoreanMechanics.Draw.ED.Width:Value(), KoreanMechanics.Draw.ED.Color:Value())
	    	end	
	    	if KoreanMechanics.Draw.RD.Enabled:Value() then
	    	    Draw.Circle(myHero.pos, 900 , KoreanMechanics.Draw.RD.Width:Value(), KoreanMechanics.Draw.RD.Color:Value())
	    	end	 	    	    			
		end
	end
end
	
class "Corki"

function Corki:__init()
	print("Weedle's Corki Loaded")
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
	self:Menu()
end	

function Corki:Menu()
	KoreanMechanics.Spell:MenuElement({id = "Q", name = "Q Key", key = string.byte("Q")})
	KoreanMechanics.Spell:MenuElement({id = "QR", name = "Q Range", value = 825, min = 0, max = 825, step = 25})
	KoreanMechanics.Spell:MenuElement({id = "R", name = "R Key", key = string.byte("R")})
	KoreanMechanics.Spell:MenuElement({id = "RR", name = "R Range", value = 1300, min = 0, max = 1300, step = 25})

	KoreanMechanics.Draw:MenuElement({id = "QD", name = "Draw Q range", type = MENU})
    KoreanMechanics.Draw.QD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.QD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.QD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
    KoreanMechanics.Draw:MenuElement({id = "RD", name = "Draw R range", type = MENU})
    KoreanMechanics.Draw.RD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.RD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.RD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})  
end

function Corki:Tick()
	if KoreanMechanics.Spell.Enabled:Value() then
		if KoreanMechanics.Spell.Q:Value() then
			self:Q()
		end
		if KoreanMechanics.Spell.R:Value() then
			self:R()
		end		
	end
end	

function Corki:Q()
local target =  _G.SDK.TargetSelector:GetTarget(925)
if target == nil then return end 	
	local pos = GetPred(target, 1125, (0.25 + Game.Latency())/1000)
	KoreanCast(pos, 100)
end

function Corki:R()
local target =  _G.SDK.TargetSelector:GetTarget(1400)
if target == nil then return end 	
	local pos = GetPred(target, 2000, (0.25 + Game.Latency())/1000)
	KoreanCast(pos, 100)
end	

function Corki:Draw()
	if not myHero.dead then
	   	if KoreanMechanics.Draw.Enabled:Value() then
	   		local textPos = myHero.pos:To2D()
	   		if KoreanMechanics.Spell.Enabled:Value() then
				Draw.Text("Aimbot ON", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000)) 		
			end
			if not KoreanMechanics.Spell.Enabled:Value() and KoreanMechanics.Draw.OFFDRAW:Value() then 
				Draw.Text("Aimbot OFF", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 000, 000)) 
			end 
			if KoreanMechanics.Draw.QD.Enabled:Value() then
	    	    Draw.Circle(myHero.pos, KoreanMechanics.Spell.QR:Value(), KoreanMechanics.Draw.QD.Width:Value(), KoreanMechanics.Draw.QD.Color:Value())
	    	end
	    	if KoreanMechanics.Draw.RD.Enabled:Value() then
	    	    Draw.Circle(myHero.pos, KoreanMechanics.Spell.RR:Value(), KoreanMechanics.Draw.RD.Width:Value(), KoreanMechanics.Draw.RD.Color:Value())
	    	end	 	    	
	    end		
	end
end

if _G[myHero.charName]() then print("Welcome back " ..myHero.name..", thank you for using my Scripts ^^") end
