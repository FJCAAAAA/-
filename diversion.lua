if not global_configs["divEnable"] then
    ngx.log(ngx.ERR,"divEnable is nonono")
    return 0;
end


local trim
trim = function (s)
 return (string.gsub(s, "^%s*(.-)%s*$", "%1"))
end

local split
split = function(s, pattern, ret)
	if not pattern then pattern = "%s+" end
	if not ret then ret = {} end
	local pos = 1
	local fstart, fend = string.find(s, pattern, pos)
	while fstart do
		table.insert(ret, string.sub(s, pos, fstart - 1))
		pos = fend + 1
		fstart, fend = string.find(s, pattern, pos)
	end
	if pos <= #s then
		table.insert(ret, string.sub(s, pos))
	end
	return ret
end



local getAbTest
getAbTest = function(uuid, cutValue)

	if not cutValue then
	 	return false
	end

	if cutValue ~= "" and tonumber(cutValue) == 1000 then
		return true
	end

	if cutValue ~= "" and tonumber(cutValue) == 0 then
		return false
	end

	if not uuid then
		return false
	end

    local uuid = tostring(uuid)

    if uuid and uuid ~= "" and cutValue ~= "" then
        local uuid_arr = split(trim(uuid), "%.")
        if uuid_arr[2] then
            local id=uuid_arr[2]
            local uuidsplit = tonumber(string.sub(id,#id-2,#id))
            ngx.log(ngx.ERR,"division start uuidsplit = : ", uuidsplit)
            if uuidsplit and uuidsplit < tonumber(cutValue) then
                return true
            end
        end
    end
	return false
end


local function urlDecode(s)
  s = string.gsub(s, '%%(%x%x)', function(h) return string.char(tonumber(h, 16)) end)
  return s
end



local redisPin = global_configs["whiteList"];

local pin = ngx.var.cookie_pt_pin

if pin ~= nil then 
	pin = urlDecode(pin)
	pin = string.gsub(pin, '-', '')
end

if redisPin ~= nil and string.len(redisPin) > 0 then
	 ngx.log(ngx.ERR,"division start userpin= : ", pin)
    if pin ~= nil and string.match(redisPin, pin) ~= nil then
        ngx.var.backend = "tomcat_abtest"
        ngx.var.isab = 1
        ngx.var.default_root = ""
        ngx.log(ngx.ERR,"division start backend= : ", ngx.var.backend)
        ngx.log(ngx.ERR,"division start isab= : ", ngx.var.isab)
        return 1
    end
end

local jda = ngx.var.cookie___jda

ngx.log(ngx.ERR,"division start whiteList jda= : ", jda)

if global_configs["divEnable"] then

    if jda ~= nil then
    	  
        local core = global_configs["newTrafficRate"]
        ngx.log(ngx.ERR,"division start core= : ", core)
        local abUser = getAbTest(jda, core)
        ngx.log(ngx.ERR,"division start abUser= : ", abUser)

        if abUser then
            ngx.var.backend = "tomcat_abtest"
            ngx.var.isab = 1
            ngx.var.default_root = ""
            return 1
        end
    end
end

return 0