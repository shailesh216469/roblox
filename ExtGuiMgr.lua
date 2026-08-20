-- External GUI Manager - FINAL + Smooth Auto Refresh + Search
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local LP = Players.LocalPlayer
local PG = LP:WaitForChild("PlayerGui")

local function getHiddenUI()
	local ok, hui = pcall(function()
		if gethui then return gethui() end
		if get_hidden_gui then return get_hidden_gui() end
		return CoreGui
	end)
	return ok and hui or CoreGui
end

local HUI = getHiddenUI()

local function safeParent(gui)
	pcall(function()
		if syn and syn.protect_gui then syn.protect_gui(gui) end
		gui.Parent = HUI
	end)
	if not gui.Parent then pcall(function() gui.Parent = CoreGui end) end
	if not gui.Parent then gui.Parent = PG end
end

local function isExternal(sg)
	if not (sg:IsA("ScreenGui") or sg:IsA("GuiMain")) then return false end
	local parent = sg.Parent
	if not parent then return false end
	local skip = {
		RobloxGui=true, Chat=true, TopBarApp=true, BubbleChat=true,
		Backpack=true, PlayerList=true, HealthGUI=true, ChromeInterface=true,
		RobloxPromptGui=true, CaptureManager=true, CaptureOverlay=true,
		ScreenshotsCarousel=true, MomentsCreationFlow=true,
		RobloxNetworkPauseNotification=true, EmotesMenu=true, InspectMenu=true
	}
	return not (skip[sg.Name] or skip[parent.Name])
end

local function getVisibleText(gui)
	local best, score = nil, 0
	for _, obj in ipairs(gui:GetDescendants()) do
		if (obj:IsA("TextLabel") or obj:IsA("TextButton")) and obj.Visible and obj.AbsoluteSize.X > 20 then
			local t = obj.Text:match("^%s*(.-)%s*$")
			if t and #t >= 2 and #t <= 40 then
				local s = #t
				if obj:IsA("TextButton") then s = s + 20 end
				if obj.TextSize >= 14 then s = s + 10 end
				if s > score then best, score = t, s end
			end
		end
	end
	return best
end

local knownGuis, latestGuis = {}, {}
local LATEST_WINDOW = 60
local currentSearch = ""

local function collectGuis()
	local list = {}
	for _, c in ipairs({CoreGui, HUI, PG}) do
		pcall(function()
			for _, ch in ipairs(c:GetChildren()) do
				if isExternal(ch) then table.insert(list, ch) end
			end
		end)
	end
	return list
end

-- Highlight
local function highlightGui(target)
	if not target or not target.Parent then return end

	local visible = getVisibleText(target)
	local display = visible or target.Name

	local overlay = Instance.new("ScreenGui")
	overlay.Name = "HighlightOverlay"
	overlay.IgnoreGuiInset = true
	overlay.DisplayOrder = 1000001
	overlay.Parent = HUI

	local visual = target
	local maxArea = 0
	for _, obj in ipairs(target:GetDescendants()) do
		if obj:IsA("GuiObject") and obj.Visible then
			local area = obj.AbsoluteSize.X * obj.AbsoluteSize.Y
			if area > maxArea then
				maxArea = area
				visual = obj
			end
		end
	end

	local hasSize = visual.AbsoluteSize.X > 40 and visual.AbsoluteSize.Y > 20
	local screenSize = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080)

	if hasSize then
		local box = Instance.new("Frame", overlay)
		box.BackgroundColor3 = Color3.fromRGB(0, 255, 255)
		box.BackgroundTransparency = 0.55
		box.BorderSizePixel = 0
		box.Size = UDim2.fromOffset(visual.AbsoluteSize.X + 14, visual.AbsoluteSize.Y + 14)
		box.Position = UDim2.fromOffset(visual.AbsolutePosition.X - 7, visual.AbsolutePosition.Y - 7)

		local stroke = Instance.new("UIStroke", box)
		stroke.Thickness = 4
		stroke.Color = Color3.fromRGB(255, 50, 50)

		local label = Instance.new("TextLabel", overlay)
		label.Size = UDim2.fromOffset(math.clamp(visual.AbsoluteSize.X + 14, 160, 400), 28)
		label.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		label.BackgroundTransparency = 0.2
		label.Text = display
		label.TextColor3 = Color3.fromRGB(255, 255, 80)
		label.Font = Enum.Font.GothamBold
		label.TextSize = 14
		label.TextTruncate = Enum.TextTruncate.AtEnd
		Instance.new("UICorner", label).CornerRadius = UDim.new(0, 4)

		local lx = visual.AbsolutePosition.X - 7
		local ly = visual.AbsolutePosition.Y - 36
		if ly < 5 then ly = visual.AbsolutePosition.Y + visual.AbsoluteSize.Y + 10 end
		if lx < 5 then lx = 5 end
		if lx + label.Size.X.Offset > screenSize.X - 5 then
			lx = screenSize.X - label.Size.X.Offset - 5
		end
		label.Position = UDim2.fromOffset(lx, ly)
	else
		local bg = Instance.new("Frame", overlay)
		bg.Size = UDim2.fromScale(1, 1)
		bg.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
		bg.BackgroundTransparency = 0.72

		local label = Instance.new("TextLabel", overlay)
		label.Size = UDim2.new(0.85, 0, 0, 70)
		label.Position = UDim2.new(0.075, 0, 0.4, 0)
		label.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		label.BackgroundTransparency = 0.25
		label.Text = "HIGHLIGHTING\n" .. display
		label.TextColor3 = Color3.fromRGB(255, 255, 80)
		label.Font = Enum.Font.GothamBold
		label.TextSize = 20
		label.TextWrapped = true
		Instance.new("UICorner", label).CornerRadius = UDim.new(0, 8)
	end

	task.delay(3.2, function()
		if overlay and overlay.Parent then overlay:Destroy() end
	end)
end

-- Main GUI
local screen = Instance.new("ScreenGui")
screen.Name = "ExtGuiMgr_Final"
screen.ResetOnSpawn = false
screen.IgnoreGuiInset = true
screen.DisplayOrder = 999999
safeParent(screen)

local toggle = Instance.new("TextButton", screen)
toggle.Size = UDim2.new(0, 40, 0, 40)
toggle.Position = UDim2.new(0, 10, 0, 90)
toggle.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
toggle.Text = "GUI"
toggle.TextColor3 = Color3.new(1,1,1)
toggle.Font = Enum.Font.GothamBold
toggle.TextSize = 12
toggle.BorderSizePixel = 0
toggle.Draggable = true
Instance.new("UICorner", toggle).CornerRadius = UDim.new(1, 0)

local frame = Instance.new("Frame", screen)
frame.Size = UDim2.new(0, 270, 0, 380)
frame.Position = UDim2.new(0, 60, 0, 90)
frame.BackgroundColor3 = Color3.fromRGB(16, 16, 24)
frame.BorderSizePixel = 0
frame.Visible = false
frame.Active = true
frame.Draggable = true
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

local uiScale = Instance.new("UIScale", frame)
uiScale.Scale = 1

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, -70, 0, 24)
title.Position = UDim2.new(0, 10, 0, 4)
title.BackgroundTransparency = 1
title.Text = "External GUIs"
title.TextColor3 = Color3.new(1,1,1)
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.TextXAlignment = Enum.TextXAlignment.Left

local minBtn = Instance.new("TextButton", frame)
minBtn.Size = UDim2.new(0, 26, 0, 26)
minBtn.Position = UDim2.new(1, -60, 0, 4)
minBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
minBtn.Text = "–"
minBtn.TextColor3 = Color3.new(1,1,1)
minBtn.Font = Enum.Font.GothamBold
minBtn.TextSize = 16
minBtn.BorderSizePixel = 0
Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 4)

local closeBtn = Instance.new("TextButton", frame)
closeBtn.Size = UDim2.new(0, 26, 0, 26)
closeBtn.Position = UDim2.new(1, -30, 0, 4)
closeBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.new(1,1,1)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 12
closeBtn.BorderSizePixel = 0
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 4)

local refreshBtn = Instance.new("TextButton", frame)
refreshBtn.Size = UDim2.new(0.5, -10, 0, 24)
refreshBtn.Position = UDim2.new(0, 8, 0, 32)
refreshBtn.BackgroundColor3 = Color3.fromRGB(40, 90, 160)
refreshBtn.Text = "Refresh"
refreshBtn.TextColor3 = Color3.new(1,1,1)
refreshBtn.Font = Enum.Font.Gotham
refreshBtn.TextSize = 12
refreshBtn.BorderSizePixel = 0
Instance.new("UICorner", refreshBtn).CornerRadius = UDim.new(0, 4)

local nukeBtn = Instance.new("TextButton", frame)
nukeBtn.Size = UDim2.new(0.5, -10, 0, 24)
nukeBtn.Position = UDim2.new(0.5, 2, 0, 32)
nukeBtn.BackgroundColor3 = Color3.fromRGB(160, 60, 40)
nukeBtn.Text = "Close All"
nukeBtn.TextColor3 = Color3.new(1,1,1)
nukeBtn.Font = Enum.Font.Gotham
nukeBtn.TextSize = 12
nukeBtn.BorderSizePixel = 0
Instance.new("UICorner", nukeBtn).CornerRadius = UDim.new(0, 4)

-- Search Box
local searchBox = Instance.new("TextBox", frame)
searchBox.Size = UDim2.new(1, -16, 0, 26)
searchBox.Position = UDim2.new(0, 8, 0, 60)
searchBox.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
searchBox.TextColor3 = Color3.new(1,1,1)
searchBox.PlaceholderText = "Search GUI name..."
searchBox.PlaceholderColor3 = Color3.fromRGB(120,120,140)
searchBox.Text = ""
searchBox.Font = Enum.Font.Gotham
searchBox.TextSize = 13
searchBox.ClearTextOnFocus = false
searchBox.BorderSizePixel = 0
Instance.new("UICorner", searchBox).CornerRadius = UDim.new(0, 5)

local status = Instance.new("TextLabel", frame)
status.Size = UDim2.new(1, -16, 0, 16)
status.Position = UDim2.new(0, 8, 0, 90)
status.BackgroundTransparency = 1
status.Text = "Found: 0 | Latest: 0"
status.TextColor3 = Color3.fromRGB(160,160,180)
status.Font = Enum.Font.Gotham
status.TextSize = 11
status.TextXAlignment = Enum.TextXAlignment.Left

-- Size Slider
local sliderBg = Instance.new("Frame", frame)
sliderBg.Size = UDim2.new(1, -16, 0, 8)
sliderBg.Position = UDim2.new(0, 8, 0, 108)
sliderBg.BackgroundColor3 = Color3.fromRGB(40,40,55)
sliderBg.BorderSizePixel = 0
Instance.new("UICorner", sliderBg).CornerRadius = UDim.new(1, 0)

local sliderFill = Instance.new("Frame", sliderBg)
sliderFill.Size = UDim2.new(0.5, 0, 1, 0)
sliderFill.BackgroundColor3 = Color3.fromRGB(80,140,255)
sliderFill.BorderSizePixel = 0
Instance.new("UICorner", sliderFill).CornerRadius = UDim.new(1, 0)

local sliderBtn = Instance.new("TextButton", sliderBg)
sliderBtn.Size = UDim2.new(0, 14, 0, 14)
sliderBtn.Position = UDim2.new(0.5, -7, 0.5, -7)
sliderBtn.BackgroundColor3 = Color3.new(1,1,1)
sliderBtn.Text = ""
sliderBtn.BorderSizePixel = 0
Instance.new("UICorner", sliderBtn).CornerRadius = UDim.new(1, 0)

local scroll = Instance.new("ScrollingFrame", frame)
scroll.Size = UDim2.new(1, -16, 1, -124)
scroll.Position = UDim2.new(0, 8, 0, 120)
scroll.BackgroundColor3 = Color3.fromRGB(12,12,18)
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 4
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
Instance.new("UICorner", scroll).CornerRadius = UDim.new(0, 4)

local layout = Instance.new("UIListLayout", scroll)
layout.Padding = UDim.new(0, 4)
layout.SortOrder = Enum.SortOrder.LayoutOrder
Instance.new("UIPadding", scroll).PaddingTop = UDim.new(0, 4)

local function applySize(s)
	s = math.clamp(s, 0.4, 1.4)
	uiScale.Scale = s
	local rel = (s - 0.4) / 1.0
	sliderFill.Size = UDim2.new(rel, 0, 1, 0)
	sliderBtn.Position = UDim2.new(rel, -7, 0.5, -7)
end

local dragging = false
sliderBtn.MouseButton1Down:Connect(function() dragging = true end)
UIS.InputEnded:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end)
UIS.InputChanged:Connect(function(i)
	if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
		local rel = math.clamp((i.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
		applySize(0.4 + rel * 1.0)
	end
end)

local function createHeader(text)
	local h = Instance.new("TextLabel", scroll)
	h.Size = UDim2.new(1, -8, 0, 18)
	h.BackgroundColor3 = Color3.fromRGB(130, 80, 20)
	h.Text = "  " .. text
	h.TextColor3 = Color3.new(1,1,1)
	h.Font = Enum.Font.GothamBold
	h.TextSize = 11
	h.TextXAlignment = Enum.TextXAlignment.Left
	h.BorderSizePixel = 0
	Instance.new("UICorner", h).CornerRadius = UDim.new(0, 4)
end

local function createRow(g, isLatest)
	local visible = getVisibleText(g)
	local display = visible or g.Name

	-- Search filter
	if currentSearch ~= "" then
		local lower = string.lower(display .. " " .. g.Name)
		if not string.find(lower, string.lower(currentSearch), 1, true) then
			return
		end
	end

	local row = Instance.new("Frame", scroll)
	row.Size = UDim2.new(1, -8, 0, 34)
	row.BackgroundColor3 = isLatest and Color3.fromRGB(55, 38, 22) or Color3.fromRGB(32, 32, 45)
	row.BorderSizePixel = 0
	Instance.new("UICorner", row).CornerRadius = UDim.new(0, 4)

	local name = Instance.new("TextLabel", row)
	name.Size = UDim2.new(1, -100, 1, 0)
	name.Position = UDim2.new(0, 8, 0, 0)
	name.BackgroundTransparency = 1
	name.Text = display
	name.TextColor3 = isLatest and Color3.fromRGB(255, 210, 140) or Color3.fromRGB(230, 230, 240)
	name.Font = Enum.Font.Gotham
	name.TextSize = 12
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.TextTruncate = Enum.TextTruncate.AtEnd

	local hl = Instance.new("TextButton", row)
	hl.Size = UDim2.new(0, 28, 0, 24)
	hl.Position = UDim2.new(1, -90, 0.5, -12)
	hl.BackgroundColor3 = Color3.fromRGB(30, 130, 120)
	hl.Text = "H"
	hl.TextColor3 = Color3.new(1,1,1)
	hl.Font = Enum.Font.GothamBold
	hl.TextSize = 12
	hl.BorderSizePixel = 0
	Instance.new("UICorner", hl).CornerRadius = UDim.new(0, 4)
	hl.MouseButton1Click:Connect(function()
		highlightGui(g)
	end)

	local close = Instance.new("TextButton", row)
	close.Size = UDim2.new(0, 54, 0, 24)
	close.Position = UDim2.new(1, -58, 0.5, -12)
	close.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
	close.Text = "Close"
	close.TextColor3 = Color3.new(1,1,1)
	close.Font = Enum.Font.GothamBold
	close.TextSize = 11
	close.BorderSizePixel = 0
	Instance.new("UICorner", close).CornerRadius = UDim.new(0, 4)
	close.MouseButton1Click:Connect(function()
		pcall(function() g:Destroy() end)
		knownGuis[g] = nil
		latestGuis[g] = nil
	end)
end

local function refresh(keepScroll)
	local oldScroll = keepScroll and scroll.CanvasPosition or Vector2.new(0, 0)

	for _, c in ipairs(scroll:GetChildren()) do
		if c:IsA("Frame") or c:IsA("TextLabel") then c:Destroy() end
	end

	local guis = collectGuis()
	local now = tick()
	local current = {}

	for _, g in ipairs(guis) do
		current[g] = true
		if not knownGuis[g] then
			knownGuis[g] = true
			latestGuis[g] = now
		end
	end
	for g in pairs(knownGuis) do
		if not current[g] or not g.Parent then
			knownGuis[g] = nil
			latestGuis[g] = nil
		end
	end

	local normalList = {}
	local latestList = {}

	for _, g in ipairs(guis) do
		if latestGuis[g] and (now - latestGuis[g]) <= LATEST_WINDOW then
			table.insert(latestList, g)
		else
			table.insert(normalList, g)
		end
	end

	status.Text = string.format("Found: %d | Latest: %d", #guis, #latestList)

	-- Normal GUIs first
	for _, g in ipairs(normalList) do
		createRow(g, false)
	end

	-- Latest at the bottom
	if #latestList > 0 then
		createHeader("Latest (" .. #latestList .. ")")
		for _, g in ipairs(latestList) do
			createRow(g, true)
		end
	end

	if keepScroll then
		task.defer(function()
			scroll.CanvasPosition = oldScroll
		end)
	end
end

-- Search
searchBox:GetPropertyChangedSignal("Text"):Connect(function()
	currentSearch = searchBox.Text
	refresh(true)
end)

toggle.MouseButton1Click:Connect(function()
	frame.Visible = not frame.Visible
	if frame.Visible then refresh(false) end
end)

minBtn.MouseButton1Click:Connect(function()
	frame.Visible = false
end)

closeBtn.MouseButton1Click:Connect(function()
	screen:Destroy()
end)

refreshBtn.MouseButton1Click:Connect(function()
	refresh(false)
end)

nukeBtn.MouseButton1Click:Connect(function()
	for _, g in ipairs(collectGuis()) do
		pcall(function() g:Destroy() end)
		knownGuis[g] = nil
		latestGuis[g] = nil
	end
	refresh(false)
end)

-- Keep on top
task.spawn(function()
	while screen.Parent do
		screen.DisplayOrder = 999999
		task.wait(2)
	end
end)

-- Smooth Auto Refresh (every 2 seconds, keeps scroll)
task.spawn(function()
	while screen.Parent do
		task.wait(2)
		if frame.Visible then
			refresh(true) -- keepScroll = true
		else
			-- still track new ones in background
			local guis = collectGuis()
			local now = tick()
			for _, g in ipairs(guis) do
				if not knownGuis[g] then
					knownGuis[g] = true
					latestGuis[g] = now
				end
			end
		end
	end
end)

applySize(1)

pcall(function()
	StarterGui:SetCore("SendNotification", {
		Title = "ExtGuiMgr FINAL",
		Text = "Smooth Auto + Search + Latest at bottom",
		Duration = 4
	})
end)

refresh(false)
