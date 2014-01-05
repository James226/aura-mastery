-------------------------------------------------------------------------------
--- Package loader and library versioning tool
-- Copyright (c) NCsoft. All rights reserved
-- Author: draftomatic
-- Parts of this code were taken from LibStub.lua by: 
--   Kaelten, Cladhaire, ckknight, Mikk, Ammo, Nevcairiel, joshborke, 
--   adapted for WildStar by Packetdancer
-------------------------------------------------------------------------------

local GeminiPackages = _G["GeminiPackages"] 

if not GeminiPackages then
	
	-- Create table
	GeminiPackages = {
		requires = {},
		callbacks = {},
		packages = {},
		patchlevels = {}
	}
	_G["GeminiPackages"] = GeminiPackages
	
	--- Package loader. 
	-- Takes a list of string package names followed by a callback function to invoke 
	-- when all packages are loaded.
	function GeminiPackages:Require(...) 
		local numArgs = select("#", ...)
		local rqr = {}
		for i=1, numArgs-1 do
			local arg = select(i, ...)
			rqr[i] = arg
		end
		table.insert(GeminiPackages.requires, rqr)
		table.insert(GeminiPackages.callbacks, select(numArgs, ...))
		
		GeminiPackages:Refresh()
	end
	
	--- Runs through all the current require lists and checks if all packages are loaded. 
	-- If so, fires the callback.
	function GeminiPackages:Refresh()
		--if self:GetTableSize(self.packages) == 0 then Print("No packages. Skipping Refresh."); return end
		if #self.callbacks == 0 then return end
		local i=1
		while i<=#self.requires do
			local rqr = self.requires[i]
			--Print("Checking require: " .. self:prnt(rqr))
			if rqr then
				local pkgs = {}
				for j=1, #rqr do
					local pkg = rqr[j]
					for k, v in pairs(self.packages) do
						if pkg == k then
							table.insert(pkgs, v)
							break
						end
					end
				end
				if #pkgs == #rqr then
					--Print("All requires found. Firing callback.")
					--Print("Number of pkgs: " .. #pkgs)
					--Print("pkg1: " .. self:prnt(pkgs[1]))
					--Print("Firing callback: " .. i)
					table.remove(self.requires, i)
					local callback = self.callbacks[i]
					table.remove(self.callbacks, i)
					callback(unpack(pkgs))
				else
					--Print("All requires NOT found. Continuing")
					i = i+1
				end
			end
		end
	end
	
	--- Registers a table as a package, firing callbacks for existing requires 
	-- if this completes their dependencies.
	-- name should be a string name for the package, such as "MyLibrary-1.3"
	-- patchlevel should be a number, which represents the patch level of the current version.
	-- Newer patchlevels will replace old patchlevels for the same name. Different names are seen as distinct libraries.
	function GeminiPackages:NewPackage(pkg, name, patchlevel)
		--Print("New Package: " .. name)
		
		assert(type(name) == "string", "Bad argument #2 to `NewLibrary' (string expected)")
		patchlevel = assert(tonumber(string.match(patchlevel, "%d+")), "patchlevel version must either be a number or contain a number.")
		
		local oldpatchlevel = self.patchlevels[name]
		if oldpatchlevel and oldpatchlevel >= patchlevel then return nil end
		
		self.patchlevels[name], self.packages[name] = patchlevel, pkg
		
		self:Refresh()
	end
	
	--- Returns a package by name. Generally you should use GeminiPackages:Require.
	-- However, if the package you're loading is a library and not an addon, you can use this directly.
	function GeminiPackages:GetPackage(name)
		--if not self.packages[name] and not silent then
		--	error(("Cannot find a library instance of %q."):format(tostring(name)), 2)
		--end
		return self.packages[name], self.patchlevels[name]
	end
	
	
	--
	-- Utility functions below that could be removed
	--
	function GeminiPackages:prnt(tbl)
		local str = "{"
		for k,v in pairs(tbl) do
			str = str .. k .. "=" .. tostring(v) .. ", "
		end
		str = str .. "}"
		return str
	end
	
	function GeminiPackages:GetTableSize(tbl)
		local count = 0
		for _ in pairs(tbl) do count = count + 1 end
		return count
	end
	
end
