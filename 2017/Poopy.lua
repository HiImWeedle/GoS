	if myHero.charName ~= "Poppy" then return end 

	local Version, Author = 666, "Weedle"
	local Icons = { 
		P = "https://raw.githubusercontent.com/HiImWeedle/GoS/master/Icons/PoppyIcon2.png",
		Q = "https://raw.githubusercontent.com/HiImWeedle/GoS/master/Icons/PoppyQ.png",
		W = "https://raw.githubusercontent.com/HiImWeedle/GoS/master/Icons/PoppyW.png",
		E = "https://raw.githubusercontent.com/HiImWeedle/GoS/master/Icons/PoppyE.png",
		Skin = "https://raw.githubusercontent.com/HiImWeedle/GoS/master/Icons/PoppySkin1.png"}
	local TEAM_ALLY = myHero.team
	local TEAM_JUNGLE = 300
	local TEAM_ENEMY = 300 - TEAM_ALLY
	local huge = math.huge 	
	local sqrt = math.sqrt  
	require "2DGeometry"
	require "MapPositionGOS"		

	local Menu = MenuElement({id = "Poopy", name = "Poopy", type = MENU, leftIcon = Icons.P})
		Menu:MenuElement({name = " ", drop = {"--------------------Spell Settings--------------------"}})
		Menu:MenuElement({id = "Q", name = "Use Q in Combo", value = true, leftIcon = Icons.Q})
		Menu:MenuElement({id = "W", name = "W Mode", drop = {"Auto", "Combo", "Off"}, leftIcon = Icons.W})
		Menu:MenuElement({id = "E", name = "Use E in Combo", value = true, leftIcon = Icons.E})
		Menu:MenuElement({name = " ", drop = {"---------------------Misc Settings--------------------"}})
		Menu:MenuElement({id = "Combo", name = "Combo Key", key = string.byte(" ")})
		Menu:MenuElement({id = "Drawings", name = "Drawings", type = MENU})
		Menu.Drawings:MenuElement({id = "TS", name = "Force Target Color", color = Draw.Color(255, 255, 000, 100)})
		Menu.Drawings:MenuElement({id = "W", name = "Enable W Drawings", value = true})
		Menu.Drawings:MenuElement({id = "E", name = "Enable E Drawings", value = false})
		Menu:MenuElement({id = "SkinHack", name = "Amazing Premium Skinhack", value = false, leftIcon = Icons.Skin})
		Menu:MenuElement({name = " ", drop = {"-----------------------Script Info----------------------"}})
		Menu:MenuElement({name = "Script Version", drop = {Version}})
		Menu:MenuElement({name = "Author", drop = {Author}})

	local function GetDistanceSqr(p1, p2)
	    local dx, dz = p1.x - p2.x, p1.z - p2.z 
	    return dx * dx + dz * dz
	end

	local function GetDistance(p1, p2)
		return sqrt(GetDistanceSqr(p1, p2))
	end

	local function Ready(spell)
		local spellData = myHero:GetSpellData(spell)
		return spellData.currentCd == 0 and spellData.level > 0 and spellData.mana <= myHero.mana
	end	

	local SkinHack = Sprite("MenuElement\\PoppySkin1.png", 0.3)	

	class "Poopy"

	function Poopy:__init()
		self.ForceTarget = nil	
		self.Ecast = false		
		self.CanCast = false
		self.Q = {range = 430, range2 = 184900, delay = 0.25}
		self.W = {range = 400, range2 = 160000}
		self.E = {range = 475, range2 = 225625, speed = 1800}
		Callback.Add("WndMsg", function(msg,wParam) self:WndMsg(msg,wParam) end)			
		Callback.Add("Tick", function() self:Tick() end)
		Callback.Add("Draw", function() self:Draw() end)
		print("Poopy v"..Version.." | Loaded!")
	end

	function Poopy:WndMsg(msg,wParam)
		if msg == 513 and wParam == 0 then 
			self.ForceTarget = nil 			
			for i = 1, Game.HeroCount() do 
				local Hero = Game.Hero(i)
				if Hero.team == TEAM_ENEMY and Hero.dead == false and mousePos:DistanceTo(Hero.pos) < 125 then 
					self.ForceTarget = Hero 
				end
			end
		end
	end	

	function Poopy:Tick()
		if myHero.dead == false and Game.IsChatOpen() == false then
			self.Ecast = false  
			local path = myHero.pathing 
			if path.hasMovePath then 
				for i = path.pathIndex, path.pathCount do 
					if path.isDashing and path.dashSpeed == 1800 then 
						self.Ecast = true 
						break 
					end
				end
			end
			local WMode = Menu.W:Value()
			if WMode == 1 then 
				self:WLogics()
			end			
			if Menu.Combo:Value() then 
				self:Combo(WMode)
			end
		end
		if self.ForceTarget and self.ForceTarget.dead then 
			self.ForceTarget = nil 
		end
	end

	function Poopy:GetTarget(range)
		if self.ForceTarget and self.ForceTarget.dead == false and GetDistance(self.ForceTarget.pos, myHero.pos) < range then return self.ForceTarget end	
		return GOS:GetTarget(range)
	end

	function Poopy:Combo(WMode)		
    	local target = self:GetTarget(555)
    	if target == nil then return end	
       	if WMode == 2 then 
    		self:WLogics()
    	end 	
       	if Menu.E:Value() and Ready(_E) then 
    		self:CastE(target)
    	end 	
    	if Menu.Q:Value() and Ready(_Q) then 
    		self:CastQ(target)
    	end
    end

    function Poopy:WLogics() 
    	if Ready(_W) and self.Ecast == false then 
    		for i = 1, Game.HeroCount() do 
    		local Hero = Game.Hero(i)
    			if Hero.dead == false and Hero.team == TEAM_ENEMY and Hero.visible and GetDistanceSqr(Hero.pos, myHero.pos) < self.W.range2 then 
    				local path = Hero.pathing
    				if path.hasMovePath then 
    					for i = path.pathIndex, path.pathCount do 
    						if path.isDashing then 
    							self.CanCast = true
    							break
    						end
    					end
    				end
    			end
    		end
    	end
    	if self.CanCast then 
    		Control.CastSpell(HK_W)
    		self.CanCast = false 
    	end
    end

    function Poopy:CastQ(target)
   	 	local PredPos = target:GetPrediction(huge, self.Q.delay + Game.Latency()/2000)
    	if GetDistanceSqr(PredPos, myHero.pos) < self.Q.range2 then 
    		Control.CastSpell(HK_Q, PredPos)
    	end
    end

    function Poopy:CastE(target)
    	local heroPos = myHero.pos
    	local targetPos = target.pos
    	local distance = GetDistance(heroPos, targetPos)
    	if distance < self.E.range then
    		local EndPoint = heroPos + (targetPos - heroPos):Normalized() * (distance + 310 + target.boundingRadius*0.5)
    		local EndLine = LineSegment(Point(targetPos), Point(EndPoint))
    		--EndLine:__draw(5, Draw.Color(255, 50, 000, 205))
    		local Check = MapPosition:intersectsWall(EndLine)
    		if Check then 
    			self.Etime = Game.Timer() + GetDistance(heroPos, EndPoint)/self.E.speed
    			Control.CastSpell(HK_E, target)
    		end
    	end
    end

    function Poopy:Draw()
    	if myHero.dead == false then 
    		local heroPos = myHero.pos
    		local ForceTarget = self.ForceTarget
    		if ForceTarget and ForceTarget.visible then 
    			Draw.Circle(ForceTarget.pos, ForceTarget.boundingRadius*2 , 5, Menu.Drawings.TS:Value())
    		end
    		if Menu.Drawings.W:Value() then 
    			if Ready(_W) then 
    				Draw.Circle(heroPos, self.W.range, 5, Draw.Color(255, 000, 205, 50))
    			else 
    				Draw.Circle(heroPos, self.W.range, 5, Draw.Color(80, 000, 205, 50))
    			end
    		end
    		if Menu.Drawings.E:Value() then 
    			if Ready(_E) then 
    				Draw.Circle(heroPos, self.E.range, 5, Draw.Color(255, 50, 000, 205))
    			else
    				Draw.Circle(heroPos, self.E.range, 5, Draw.Color(80, 50, 000, 205))
    			end
    		end
    		if Menu.SkinHack:Value() then 
    			local pos = myHero.pos:To2D()
    			SkinHack:Draw(pos.x - 90, pos.y - 115)
    		end
    	end
    end

    function OnLoad() Poopy() end 
