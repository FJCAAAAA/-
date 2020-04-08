local start_delay = 10
local new_timer = ngx.timer.at
local log = ngx.log
local ERR = ngx.ERR
local refresh
local get_redis
local close_redis

local switch_key = "abtest:swith:pre:medicine_b2c_app"
local traffic_key = "abtest:traffic:pre:medicine_b2c_app"
local whiteList_key = "abtest:whitelist:pre:medicine_b2c_app"


get_redis = function()
  local redis = require "resty.redis"
  local red = redis:new()
  local ok, err = red:connect(global_configs['redis']['ap_host'],global_configs['redis']['ap_port'])
  if not ok then
    ngx.log(ngx.ERR,"fail to create redis connection : ", err)
  end
  if ok and global_configs['redis']['ap_key'] then
    ok, err = red:auth(global_configs['redis']['ap_key'])
  end
  return red, ok, err
end

close_redis = function(red)
        if not red then
        return
    end
    local ok, err = red:close()
    if not ok then
        ngx.log(ngx.ERR,"fail to close redis connection : ", err)
    end
end

local function do_refresh()
    local red, ok, err = get_redis()

    if not ok then
        log(ERR, "redis is not ready!")
        return
    end

    local traficLimitStr, err = red:get(traffic_key)

    -- refresh global switch
    local enable, err = red:get(switch_key)
    if err then
        log(ERR, err)
    else
        if ngx.null ~= enable then
            global_configs["divEnable"] = ("true" == enable) and true or false
            log(ERR, "update global_configs: ", global_configs["divEnable"])
        end
    end

    -- refresh traffic limit
    local trafficLimitStr, err = red:get(traffic_key)
    if err then
        log(ERR, err)
    else
        if ngx.null ~= trafficLimitStr and tonumber(trafficLimitStr) >= 0  then
            global_configs["newTrafficRate"] = tonumber(trafficLimitStr)
            log(ERR, "update newTrafficRate: ", global_configs["newTrafficRate"])
        end
    end

    -- refresh whiteList
    local whiteList, err = red:get(whiteList_key)
    if err then
        log(ERR, err)
    else
        if ngx.null ~= whiteList then
            local wlStr = tostring(whiteList)
        	  wlStr = string.gsub(wlStr, '-', '')
            global_configs["whiteList"] = wlStr
            log(ERR, "update whiteList: ", global_configs["whiteList"])
        end
    end

    return close_redis(red)
end

refresh = function(premature)
    if not premature then
        log(ERR, "rrrrrrrrrrrrrrrrrrrrrrrrrrrrrrefresh")
        do_refresh()

        local ok, e = new_timer(start_delay, refresh)
        if not ok then
            log(ERR, "failed to create timer: ", e)
            return
        end
    end
end



local ok, e = new_timer(start_delay, refresh)
if not ok then
    log(ERR, "failed to create timer: ", e)
    return
end