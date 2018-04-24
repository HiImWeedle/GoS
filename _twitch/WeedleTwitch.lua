
	--[[
		WeedleTwitch.lua
		U can find the script code in Common/RATIRL.lua
	--]]

	local open            = io.open 
	local time            = os.time()
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
		local save_file   = open(common..save, "w")
		save_file:write(time)
		save_file:close()
	end

	local function CheckSave()
		local save_file, save_time
		if not FileExist(common..save) then 
			DownloadFile(ratirl_url, common..ratirl)
			UpdateSave()
		else
			save_file      = open(common..save)
			save_time      = save_file:read()
			save_file:close()		
			if time - tonumber(save_time) >= 300 then 
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