-- EasyWarp 开机自启动入口
local ok, err = pcall(function()
    local f = assert(loadfile("/usr/share/EasyWarp/main.lua"))
    f()
end)
if not ok then
    print("EasyWarp 启动失败: " .. tostring(err))
end
