	local function Ready()
		local W = myHero:GetSpellData(_W)
		return W.currentCd == 0 and W.level > 0 and W.mana <= myHero.mana and W.name == "PickACard"
	end	

	function HasBuff()
		for i = 1, myHero.buffCount do 
		local Buff = myHero:GetBuff(i)
			if Buff.name == "Gate" and Buff.count > 0 and Game.Timer() < Buff.expireTime then
				return true
			end
		end
		return false
	end	

	class "TF"

	local Menu = MenuElement({id = "TF", name = "Secret Twisted Fate", type = MENU, leftIcon = "https://raw.githubusercontent.com/HiImWeedle/GoS/master/Icons/TFIcon1.png"})
	Menu:MenuElement({id = "C", name = "Cards", type = MENU})
	Menu:MenuElement({id = "D", name = "Drawings", type = MENU})
	
	function TF:__init() 
		self.Icons = {
			G = "https://raw.githubusercontent.com/HiImWeedle/GoS/master/Icons/TFG.png",
			B = "https://raw.githubusercontent.com/HiImWeedle/GoS/master/Icons/TFB.png",
			R = "https://raw.githubusercontent.com/HiImWeedle/GoS/master/Icons/TFR.png"}	
		self:Menu()
		Callback.Add("Tick", function() self:Tick() end)
		Callback.Add("Draw", function() 
			if myHero.dead == false and Menu.D.Q:Value() then
				local h = myHero.pos 
				Draw.Circle(h, 1450, Menu.D.W:Value(), Menu.D.C:Value())
			end
		end)	
	end

	function TF:Menu() 
		Menu.C:MenuElement({id = "G", name = "Gold Key", key = string.byte("W"), leftIcon = self.Icons.G})
		Menu.C:MenuElement({id = "B", name = "Blue Key", key = string.byte(" "), leftIcon = self.Icons.B})
		Menu.C:MenuElement({id = "R", name = "Red Key", key = string.byte("E"), leftIcon = self.Icons.R})

		Menu.D:MenuElement({id = "Q", name = "Draw Q", value = true})
		Menu.D:MenuElement({id = "W", name = "Width", value = 5, min = 1, max = 5, step = 1})
		Menu.D:MenuElement({id = "C", name = "Color", color = Draw.Color(255, 144, 000, 144)})
	end

	local LastW = "", Game.Timer()
	function TF:Tick() 
		if myHero.dead == false and Game.IsChatOpen() == false then	
			local t = Game.Timer()
			if Ready() then 
				if Menu.C.G:Value() then 
					C = "GoldCardLock"
					if Ready() and t > LastW + 0.33 then 
						Control.CastSpell(HK_W)
						LastW = t 
					end 
				end
				if Menu.C.B:Value() then 
					C = "BlueCardLock"
					if Ready() and t > LastW + 0.33 then 
						LastW = t
						Control.CastSpell(HK_W)
					end
				end
				if Menu.C.R:Value() then 
					C = "RedCardLock"
					if Ready() and t > LastW + 0.33 then 
						LastW = t
						Control.CastSpell(HK_W)
					end
				end
				if HasBuff() then 
					C = "GoldCardLock"
					if Ready() and t > LastW + 0.33 then 
						LastW = t
						Control.CastSpell(HK_W)
					end
				end				
			end
			local n = myHero:GetSpellData(_W).name
			if n == C then 
				C = ""
				Control.CastSpell(HK_W)
			end
		end
	end

	function OnLoad() TF() end  

