local component = require("component")
local term = require("term")
local event = require("event")
local gpu = component.gpu
local unicode = require("unicode")

-- 检查飞船控制器
local shipController = component.warpdriveShipController
if not shipController then
    error("未找到飞船控制器，请检查连接！")
end

-- 屏幕尺寸
local screenWidth, screenHeight = gpu.getResolution()

-- 颜色定义
local colors = {
    bg = 0x1E1E1E,
    panel = 0x2D2D2D,
    button = 0x3C3C3C,
    buttonHover = 0x505050,
    text = 0xFFFFFF,
    accent = 0x4EC9B0,
    warning = 0xDCDCAA,
    danger = 0xF44747,
    success = 0x6A9955,
}

-- 界面布局
local layout = {
    statusPanel = {x = 2, y = 2, w = 38, h = 8},
    controlPanel = {x = 2, y = 11, w = 38, h = 10},
}

-- 按钮定义
local buttons = {
    {id = "scan", label = "扫描飞船", x = 42, y = 3, w = 18, h = 3},
    {id = "set", label = "设定参数", x = 42, y = 7, w = 18, h = 3},
    {id = "jump", label = "执行跃迁", x = 42, y = 11, w = 18, h = 3},
    {id = "exit", label = "退出程序", x = 42, y = 15, w = 18, h = 3},
}

local hoveredButton = nil

-- 跃迁参数
local jumpParams = {
    distance = 1000,
    energyNeeded = 0,
    maxDistance = 0,
}

-- 缓存的飞船数据
local shipData = {
    energyCur = 0,
    energyMax = 0,
    mass = 0,
    volume = 0,
    posX = 0, posY = 0, posZ = 0,
    inSpace = false,
    inHyperspace = false,
}

-- 绘制矩形
local function drawRect(x, y, w, h, bgColor)
    gpu.setBackground(bgColor)
    gpu.fill(x, y, w, h, " ")
end

-- 居中绘制文本
local function drawTextCenter(text, x, y, w, fgColor, bgColor)
    if bgColor then gpu.setBackground(bgColor) end
    gpu.setForeground(fgColor)
    local textLen = unicode.len(text)
    local startX = x + math.floor((w - textLen) / 2)
    gpu.set(startX, y, text)
end

-- 绘制按钮
local function drawButton(btn)
    local bg = colors.button
    if hoveredButton == btn.id then
        bg = colors.buttonHover
    end
    drawRect(btn.x, btn.y, btn.w, btn.h, bg)
    drawTextCenter(btn.label, btn.x, btn.y + 1, btn.w, colors.text, bg)
end

-- 绘制整个界面
local function drawInterface()
    gpu.setBackground(colors.bg)
    gpu.fill(1, 1, screenWidth, screenHeight, " ")

    -- 状态面板
    drawRect(layout.statusPanel.x, layout.statusPanel.y,
             layout.statusPanel.w, layout.statusPanel.h, colors.panel)
    gpu.setForeground(colors.accent)
    gpu.set(layout.statusPanel.x + 1, layout.statusPanel.y + 1, "=== 飞船状态 ===")

    gpu.setForeground(colors.text)
    gpu.set(layout.statusPanel.x + 1, layout.statusPanel.y + 2,
            "能量: " .. math.floor(shipData.energyCur) .. " / " .. math.floor(shipData.energyMax))
    gpu.set(layout.statusPanel.x + 1, layout.statusPanel.y + 3,
            "质量: " .. shipData.mass .. "  体积: " .. shipData.volume)

    local posStr = string.format("坐标: %.0f, %.0f, %.0f",
                                 shipData.posX, shipData.posY, shipData.posZ)
    gpu.set(layout.statusPanel.x + 1, layout.statusPanel.y + 4, posStr)

    local spaceStr = shipData.inSpace and "是" or "否"
    local hyperStr = shipData.inHyperspace and "是" or "否"
    gpu.set(layout.statusPanel.x + 1, layout.statusPanel.y + 5,
            "太空中: " .. spaceStr .. "  超空间: " .. hyperStr)

    -- 控制面板
    drawRect(layout.controlPanel.x, layout.controlPanel.y,
             layout.controlPanel.w, layout.controlPanel.h, colors.panel)
    gpu.setForeground(colors.accent)
    gpu.set(layout.controlPanel.x + 1, layout.controlPanel.y + 1, "=== 跃迁参数 ===")

    gpu.setForeground(colors.text)
    gpu.set(layout.controlPanel.x + 1, layout.controlPanel.y + 2,
            "跃迁距离: " .. jumpParams.distance)
    gpu.set(layout.controlPanel.x + 1, layout.controlPanel.y + 3,
            "所需能量: " .. math.floor(jumpParams.energyNeeded))
    gpu.set(layout.controlPanel.x + 1, layout.controlPanel.y + 4,
            "最大距离: " .. math.floor(jumpParams.maxDistance))

    -- 按钮
    for _, btn in ipairs(buttons) do
        drawButton(btn)
    end
end

-- 刷新飞船数据
local function refreshShipData()
    local ok, cur, max = pcall(shipController.energy)
    if ok then
        shipData.energyCur = cur or 0
        shipData.energyMax = max or 0
    end

    local ok2, mass, volume = pcall(shipController.getShipSize)
    if ok2 then
        shipData.mass = mass or 0
        shipData.volume = volume or 0
    end

    local ok3, x, y, z = pcall(shipController.getLocalPosition)
    if ok3 then
        shipData.posX = x or 0
        shipData.posY = y or 0
        shipData.posZ = z or 0
    end

    local ok4, space = pcall(shipController.isInSpace)
    if ok4 then shipData.inSpace = space or false end

    local ok5, hyper = pcall(shipController.isInHyperspace)
    if ok5 then shipData.inHyperspace = hyper or false end

    local ok6, success, maxDist = pcall(shipController.getMaxJumpDistance)
    if ok6 and success then
        jumpParams.maxDistance = maxDist or 0
    end

    local ok7, success2, energyReq = pcall(shipController.getEnergyRequired)
    if ok7 and success2 then
        jumpParams.energyNeeded = energyReq or 0
    end
end

-- 处理按钮点击
local function handleButtonClick(btnId)
    if btnId == "scan" then
        refreshShipData()
        drawInterface()
    elseif btnId == "set" then
        gpu.setForeground(colors.warning)
        gpu.set(42, 20, "输入距离: ")
        term.setCursor(52, 20)
        term.setCursorBlink(true)
        local input = io.stdin:read()
        term.setCursorBlink(false)
        local dist = tonumber(input)
        if dist and dist > 0 then
            jumpParams.distance = dist
            pcall(shipController.movement, dist)
            refreshShipData()
        end
        drawInterface()
    elseif btnId == "jump" then
        if shipData.energyCur < jumpParams.energyNeeded then
            gpu.setForeground(colors.danger)
            gpu.set(42, 20, "能量不足！")
        else
            local ok, err = pcall(shipController.enable, true)
            if ok then
                gpu.setForeground(colors.success)
                gpu.set(42, 20, "跃迁指令已发送...")
            else
                gpu.setForeground(colors.danger)
                gpu.set(42, 20, "错误: " .. tostring(err))
            end
        end
        os.sleep(2)
        drawInterface()
    elseif btnId == "exit" then
        term.clear()
        os.exit()
    end
end

-- 根据坐标获取按钮
local function getButtonAt(x, y)
    for _, btn in ipairs(buttons) do
        if x >= btn.x and x < btn.x + btn.w and
           y >= btn.y and y < btn.y + btn.h then
            return btn
        end
    end
    return nil
end

-- 主循环
local function main()
    term.clear()
    refreshShipData()
    drawInterface()

    while true do
        local eventType, address, x, y, button = event.pull(1)

        if eventType == "touch" then
            local btn = getButtonAt(x, y)
            if btn then
                handleButtonClick(btn.id)
            end
        elseif eventType == "scroll" then
            if button == 1 then
                jumpParams.distance = jumpParams.distance + 100
            elseif button == -1 then
                jumpParams.distance = math.max(100, jumpParams.distance - 100)
            end
            pcall(shipController.movement, jumpParams.distance)
            refreshShipData()
            drawInterface()
        else
            refreshShipData()
            drawInterface()
        end
    end
end

-- 启动程序
main()
