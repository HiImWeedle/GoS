
	--[[
		WeedleTwitch.lua
		Actual script can be found in Common/RATIRL.lua
	--]]

	local id              = myHero.networkID
	local common      	  = COMMON_PATH
	local save       	  = "ExtW.save"
	local ratirl     	  = "RATIRL.lua"
	local ratirl_url 	  = "https://raw.githubusercontent.com/HiImWeedle/_GOS/master/_twitch/R4TIRL.lua"

	local function DownloadFile(url, dir)
		DownloadFileAsync(url, dir, function() end)
		print("Updating | RATIRL.lua")
		repeat until FileExist(dir)
	end

	local function UpdateSave()
		local save_file   = io.open(common..save, "w")
		save_file:write(id)
		save_file:close()
	end

	local function CheckSave()
		local save_file, save_id
		if not FileExist(common..save) then 
			DownloadFile(ratirl_url, common..ratirl)
			UpdateSave()
		else
			save_file      = io.open(common..save)
			save_id        = save_file:read()
			save_file:close()		
			if id ~= save_check then 
				DownloadFile(ratirl_url, common..ratirl)
				UpdateSave()
			end
		end
	end

	if not FileExist(common..ratirl) then 
		DownloadFile(ratirl_url, common..ratirl)
	end

	CheckSave()
	require("RATIRL")