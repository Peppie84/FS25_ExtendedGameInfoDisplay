---
-- ExtendedGameInfoDisplay
--
-- Main class to extend the default gameInfoDisplay with year info
-- and temperature + trend and current/min/max temperatur.
--
-- Copyright (c) Peppie84, 2024
-- https://github.com/Peppie84/FS25_ExtendedGameInfoDisplay
--

ExtendedGameInfoDisplay = {
    STRECH_GAME_INFO_DISPLAY = 95,
    TEMPERATURE_ICON_SIZE = 40,
    L10N_SYMBOLS = {
        YEAR_TEXT = "yearinfo_current_year"
    },
    CURRENT_MOD = g_currentModName or 'unknown',
    DIRECTORY_MOD = g_currentModDirectory or '',
    WEATHER_HOURS_FORECAST = 3600000*6,
    HOURS_A_DAY = 3600000*24
}

---Overwritten HUD.createDisplayComponents()
---@param overwrittenFunc function
---@param uiScale number
function ExtendedGameInfoDisplay:hud__createDisplayComponents(overwrittenFunc, uiScale)
    overwrittenFunc(self, uiScale)
    -- Set some offsets to move the hud to the left
    self.gameInfoDisplay.calendarTextOffsetY = self.gameInfoDisplay.calendarTextOffsetY + self.gameInfoDisplay:scalePixelToScreenHeight(7)
    self.gameInfoDisplay.infoBgLeft.offsetX = -self.gameInfoDisplay:scalePixelToScreenWidth(ExtendedGameInfoDisplay.STRECH_GAME_INFO_DISPLAY)
    self.gameInfoDisplay.weatherIcon.offsetX = -self.gameInfoDisplay:scalePixelToScreenWidth(ExtendedGameInfoDisplay.STRECH_GAME_INFO_DISPLAY)
    self.gameInfoDisplay.weatherNextIcon.offsetX = -self.gameInfoDisplay:scalePixelToScreenWidth(ExtendedGameInfoDisplay.STRECH_GAME_INFO_DISPLAY)

    local posX, posY = self.gameInfoDisplay:getPosition()
    local temperaturePositionY = posY - self.gameInfoDisplay:scalePixelToScreenHeight(ExtendedGameInfoDisplay.TEMPERATURE_ICON_SIZE + 12)
    local temperatureIconWidth = self.gameInfoDisplay:scalePixelToScreenWidth(ExtendedGameInfoDisplay.TEMPERATURE_ICON_SIZE)
    local temperatureIconHeight = self.gameInfoDisplay:scalePixelToScreenHeight(ExtendedGameInfoDisplay.TEMPERATURE_ICON_SIZE)

    self.gameInfoDisplay.temperature = g_overlayManager:createOverlay("ui_elements.thermometer", 0, temperaturePositionY, temperatureIconWidth, temperatureIconHeight)
    self.gameInfoDisplay.temperature:setColor(unpack(HUD.COLOR.ACTIVE))
    self.gameInfoDisplay.temperatureUp = g_overlayManager:createOverlay("ui_elements.thermometerUp", 0, temperaturePositionY, temperatureIconWidth, temperatureIconHeight)
    self.gameInfoDisplay.temperatureUp:setColor(unpack(HUD.COLOR.ACTIVE))
    self.gameInfoDisplay.temperatureDown = g_overlayManager:createOverlay("ui_elements.thermometerDown", 0, temperaturePositionY, temperatureIconWidth, temperatureIconHeight)
    self.gameInfoDisplay.temperatureDown:setColor(unpack(HUD.COLOR.ACTIVE))
end

---Overwrite GameInfoDisplay.draw()
---@param overwrittenFunc function
function ExtendedGameInfoDisplay:gameinfodisplay__draw(overwrittenFunc)
    overwrittenFunc(self)

    local weatherType = g_currentMission.environment.weather:getCurrentWeatherType()
    local forcastDayTime = math.floor(g_currentMission.environment.dayTime + ExtendedGameInfoDisplay.WEATHER_HOURS_FORECAST )
    local forcastDay = g_currentMission.environment.currentDay
    if forcastDayTime > ExtendedGameInfoDisplay.HOURS_A_DAY then
        forcastDayTime = forcastDayTime - ExtendedGameInfoDisplay.HOURS_A_DAY
        forcastDay = forcastDay + 1
    end

    local nextWeatherType = g_currentMission.environment.weather:getNextWeatherType(forcastDay, forcastDayTime )

    -- Strech the background and render new!
    self.infoBgScale.width = self:scalePixelToScreenWidth(ExtendedGameInfoDisplay.STRECH_GAME_INFO_DISPLAY)
    self.infoBgScale.offsetX = -self:scalePixelToScreenWidth(ExtendedGameInfoDisplay.STRECH_GAME_INFO_DISPLAY)
    self.infoBgScale:render()

    -- ReRender to bring it back to top
    self.weatherIcon:render()
    self.weatherNextIcon:render()
    self.weatherNextIcon:setVisible(weatherType ~= nextWeatherType)

    ExtendedGameInfoDisplay:setTemperaturePosition(self)
    ExtendedGameInfoDisplay:setTemperatureTrendAndDraw(self)
    ExtendedGameInfoDisplay:drawYearText(self)
    ExtendedGameInfoDisplay:drawTemperatureText(self)
end

function ExtendedGameInfoDisplay:setTemperaturePosition(gameInfoDisplay)
    local referencePositionX =  gameInfoDisplay.calendarIcon.x - gameInfoDisplay:scalePixelToScreenWidth(120)
    gameInfoDisplay.temperature.x = referencePositionX
    gameInfoDisplay.temperatureUp.x = referencePositionX
    gameInfoDisplay.temperatureDown.x = referencePositionX
end

function ExtendedGameInfoDisplay:setTemperatureTrendAndDraw(gameInfoDisplay)
    local temperaturTrend = g_currentMission.environment.weather:getCurrentTemperatureTrend()

    gameInfoDisplay.temperature:setVisible(temperaturTrend == 0)
    gameInfoDisplay.temperatureUp:setVisible(temperaturTrend > 0)
    gameInfoDisplay.temperatureDown:setVisible(temperaturTrend < 0)

    gameInfoDisplay.temperature:draw()
    gameInfoDisplay.temperatureUp:draw()
    gameInfoDisplay.temperatureDown:draw()

    local seperatorPosX = gameInfoDisplay.temperature.x - gameInfoDisplay:scalePixelToScreenWidth(5)
    local seperatorPosYStart = gameInfoDisplay.temperature.y + gameInfoDisplay:scalePixelToScreenHeight(ExtendedGameInfoDisplay.TEMPERATURE_ICON_SIZE-1)
    local seperatorPosYEnd = gameInfoDisplay.temperature.y + gameInfoDisplay:scalePixelToScreenHeight(4)

    drawLine2D(seperatorPosX, seperatorPosYStart, seperatorPosX, seperatorPosYEnd, gameInfoDisplay.separatorWidth, 1,1,1,0.2)
end

function ExtendedGameInfoDisplay:drawTemperatureText(gameInfoDisplay)
    local minTemperatureInC, maxTemperatureInC = g_currentMission.environment.weather:getCurrentMinMaxTemperatures()
    local currentTemperatureInC = g_currentMission.environment.weather:getCurrentTemperature()

    local minTemperatureExpanded =  g_i18n:getTemperature(minTemperatureInC)
    local maxTemperatureExpanded = g_i18n:getTemperature(maxTemperatureInC)
    local currentTemperatureExpanded = g_i18n:getTemperature(currentTemperatureInC)

    local scaledTextSizeForCurrentTemperature = gameInfoDisplay:scalePixelToScreenHeight(19)
    local scaledTextSizeForTemperature = gameInfoDisplay:scalePixelToScreenHeight(14)

    local temperatureTextX = gameInfoDisplay.temperature.x + gameInfoDisplay.temperature.width + gameInfoDisplay:scalePixelToScreenWidth(40)
    local temperatureTextY = gameInfoDisplay.temperature.y + gameInfoDisplay.temperature.height + gameInfoDisplay:scalePixelToScreenHeight(2)

    setTextBold(false)
    setTextAlignment(RenderText.ALIGN_RIGHT)

    renderText(temperatureTextX, temperatureTextY - gameInfoDisplay:scalePixelToScreenHeight(22), scaledTextSizeForCurrentTemperature, string.format('%d°', currentTemperatureExpanded))
    renderText(temperatureTextX, temperatureTextY - gameInfoDisplay:scalePixelToScreenHeight(38), scaledTextSizeForTemperature, string.format('%d°/%d°', maxTemperatureExpanded, minTemperatureExpanded))
end

function ExtendedGameInfoDisplay:drawYearText(gameInfoDisplay)
    local monthTextSize = gameInfoDisplay:scalePixelToScreenHeight(10)
    local scaledTextSizeForYear = gameInfoDisplay:scalePixelToScreenHeight(12)

    local gameInfoDisplayPosX, gameInfoDisplayPosY = gameInfoDisplay:getPosition()
    local posX = gameInfoDisplay.calendarIcon.x + gameInfoDisplay.calendarIcon.width + gameInfoDisplay:scalePixelToScreenWidth(2)
    local posY = gameInfoDisplayPosY - gameInfoDisplay.calendarTextOffsetY - monthTextSize

    local l10nTextYear = g_i18n:getText(ExtendedGameInfoDisplay.L10N_SYMBOLS.YEAR_TEXT, ExtendedGameInfoDisplay.CURRENT_MOD)

    setTextBold(false)
    setTextAlignment(RenderText.ALIGN_LEFT)

    renderText(posX, posY, scaledTextSizeForYear, string.format('%s %s', l10nTextYear, g_currentMission.environment.currentYear))
end

--- Initialize the mod
local function init()
    --HUD.new = Utils.prependedFunction(HUD.new, newHud)
    HUD.createDisplayComponents = Utils.overwrittenFunction(HUD.createDisplayComponents, ExtendedGameInfoDisplay.hud__createDisplayComponents)
    GameInfoDisplay.draw = Utils.overwrittenFunction(GameInfoDisplay.draw, ExtendedGameInfoDisplay.gameinfodisplay__draw)
end

init()
