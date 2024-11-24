---
-- ExtendedGameInfoDisplay
--
-- Main class to extend the default gameInfoDisplay with year info
-- and temperatur + trend and current/min/max temperatur.
--
-- Copyright (c) Peppie84, 2024
-- https://github.com/Peppie84/FS25_ExtendedGameInfoDisplay
--

ExtendedGameInfoDisplay = {
    STRECH_GAME_INFO_DISPLAY = 95,
    TEMPERATUR_ICON_SIZE = 40,
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
    local temperaturPositionY = posY - self.gameInfoDisplay:scalePixelToScreenHeight(ExtendedGameInfoDisplay.TEMPERATUR_ICON_SIZE + 12)
    local temperaturIconWidth = self.gameInfoDisplay:scalePixelToScreenWidth(ExtendedGameInfoDisplay.TEMPERATUR_ICON_SIZE)
    local temperaturIconHeight = self.gameInfoDisplay:scalePixelToScreenHeight(ExtendedGameInfoDisplay.TEMPERATUR_ICON_SIZE)

    self.gameInfoDisplay.temperatur = g_overlayManager:createOverlay("ui_elements.thermometer", 0, temperaturPositionY, temperaturIconWidth, temperaturIconHeight)
    self.gameInfoDisplay.temperatur:setColor(unpack(HUD.COLOR.ACTIVE))
    self.gameInfoDisplay.temperaturUp = g_overlayManager:createOverlay("ui_elements.thermometerUp", 0, temperaturPositionY, temperaturIconWidth, temperaturIconHeight)
    self.gameInfoDisplay.temperaturUp:setColor(unpack(HUD.COLOR.ACTIVE))
    self.gameInfoDisplay.temperaturDown = g_overlayManager:createOverlay("ui_elements.thermometerDown", 0, temperaturPositionY, temperaturIconWidth, temperaturIconHeight)
    self.gameInfoDisplay.temperaturDown:setColor(unpack(HUD.COLOR.ACTIVE))
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

    ExtendedGameInfoDisplay:setTemperaturPosition(self)
    ExtendedGameInfoDisplay:setTemperaturTrendAndDraw(self)
    ExtendedGameInfoDisplay:drawYearText(self)
    ExtendedGameInfoDisplay:drawTemperaturText(self)
end

function ExtendedGameInfoDisplay:setTemperaturPosition(gameInfoDisplay)
    local referencePositionX =  gameInfoDisplay.calendarIcon.x - gameInfoDisplay:scalePixelToScreenHeight(65)
    gameInfoDisplay.temperatur.x = referencePositionX
    gameInfoDisplay.temperaturUp.x = referencePositionX
    gameInfoDisplay.temperaturDown.x = referencePositionX
end

function ExtendedGameInfoDisplay:setTemperaturTrendAndDraw(gameInfoDisplay)
    local temperaturTrend = g_currentMission.environment.weather:getCurrentTemperatureTrend()

    gameInfoDisplay.temperatur:setVisible(temperaturTrend == 0)
    gameInfoDisplay.temperaturUp:setVisible(temperaturTrend > 0)
    gameInfoDisplay.temperaturDown:setVisible(temperaturTrend < 0)

    gameInfoDisplay.temperatur:draw()
    gameInfoDisplay.temperaturUp:draw()
    gameInfoDisplay.temperaturDown:draw()

    local seperatorPosX = gameInfoDisplay.temperatur.x - gameInfoDisplay:scalePixelToScreenWidth(5)
    local seperatorPosYStart = gameInfoDisplay.temperatur.y + gameInfoDisplay:scalePixelToScreenHeight(ExtendedGameInfoDisplay.TEMPERATUR_ICON_SIZE-1)
    local seperatorPosYEnd = gameInfoDisplay.temperatur.y + gameInfoDisplay:scalePixelToScreenHeight(4)

    drawLine2D(seperatorPosX, seperatorPosYStart, seperatorPosX, seperatorPosYEnd, gameInfoDisplay.separatorWidth, 1,1,1,0.2)
end

function ExtendedGameInfoDisplay:drawTemperaturText(gameInfoDisplay)
    local minTemperaturInC, maxTemperaturInC = g_currentMission.environment.weather:getCurrentMinMaxTemperatures()
    local currentTemperaturInC = g_currentMission.environment.weather:getCurrentTemperature()

    local minTemperaturExpanded =  g_i18n:getTemperature(minTemperaturInC)
    local maxTemperaturExpanded = g_i18n:getTemperature(maxTemperaturInC)
    local currentTemperaturExpanded = g_i18n:getTemperature(currentTemperaturInC)

    local scaledTextSizeForCurrentTemperatur = gameInfoDisplay:scalePixelToScreenHeight(19)
    local scaledTextSizeForTemperatur = gameInfoDisplay:scalePixelToScreenHeight(14)

    local temperaturTextX = gameInfoDisplay.temperatur.x + gameInfoDisplay.temperatur.width + gameInfoDisplay:scalePixelToScreenWidth(40)
    local temperaturTextY = gameInfoDisplay.temperatur.y + gameInfoDisplay.temperatur.height + gameInfoDisplay:scalePixelToScreenHeight(2)

    setTextBold(false)
    setTextAlignment(RenderText.ALIGN_RIGHT)

    renderText(temperaturTextX, temperaturTextY - gameInfoDisplay:scalePixelToScreenHeight(22), scaledTextSizeForCurrentTemperatur, string.format('%d°', currentTemperaturExpanded))
    renderText(temperaturTextX, temperaturTextY - gameInfoDisplay:scalePixelToScreenHeight(38), scaledTextSizeForTemperatur, string.format('%d°/%d°', maxTemperaturExpanded, minTemperaturExpanded))
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
