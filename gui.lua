local Native = (function()
local UIS = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")

local MyUILib = {}

local function create(className, properties)
    local object = Instance.new(className)
    for property, value in pairs(properties) do
        object[property] = value
    end
    return object
end

local function loadFont()
    local ok, result = pcall(function()
        local asset = "posipaka_WindowsXPTAHOMA.ttf"
        local family = "posipaka_WindowsXPTAHOMA.font"

        if not isfile(asset) then
            writefile(asset, game:HttpGet(
                "https://github.com/sametexe001/luas/raw/refs/heads/main/fonts/windows-xp-tahoma.ttf"
            ))
        end

        writefile(family, HttpService:JSONEncode({
            name = "WindowsXPTAHOMA",
            faces = {{
                name = "WindowsXPTAHOMA",
                weight = 400,
                style = "Regular",
                assetId = getcustomasset(asset)
            }}
        }))

        return Font.new(getcustomasset(family))
    end)

    if ok then return result end
    return Font.fromEnum(Enum.Font.SourceSans)
end

MyUILib.Font = loadFont()
MyUILib.FontSize = 12

function MyUILib:CreateWindow(options)
    options=options or {}
    local background = Color3.fromRGB(22, 22, 22)
    local emptyColor = Color3.fromRGB(34, 34, 34)
    local accent = typeof(options.Accent)=="Color3" and options.Accent or Color3.fromRGB(205, 113, 145)
    local accentBindings = {}
    local controlOutline = Color3.fromRGB(55, 55, 55)
    local panelOutline = Color3.fromRGB(39, 39, 39)

    local connections = {}
    local tweens = {}
    local popups = {}
    local destroyed = false
    local openId, tabId = 0, 0

    local function connect(signal, callback)
        local connection = signal:Connect(callback)
        table.insert(connections, connection)
        return connection
    end

    local function cancelTween(object)
        local tween = tweens[object]
        if tween then
            tweens[object] = nil
            tween:Cancel()
        end
    end

    local function animate(object, properties, duration, style, direction)
        cancelTween(object)

        local tween = TweenService:Create(
            object,
            TweenInfo.new(
                duration or 0.12,
                style or Enum.EasingStyle.Quart,
                direction or Enum.EasingDirection.Out
            ),
            properties
        )

        tweens[object] = tween

        tween.Completed:Once(function()
            if tweens[object] == tween then
                tweens[object] = nil
            end
        end)

        tween:Play()
        return tween
    end

    local function gradient(parent, bottom)
        return create("UIGradient", {
            Rotation = 90,
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(
                    0, Color3.fromRGB(255, 255, 255)
                ),
                ColorSequenceKeypoint.new(
                    1, bottom or Color3.fromRGB(195, 195, 195)
                )
            }),
            Parent = parent
        })
    end

    local function layer(parent, name, inset, color, zIndex)
        return create("Frame", {
            Name = name,
            Position = UDim2.fromOffset(inset, inset),
            Size = UDim2.new(1, -inset * 2, 1, -inset * 2),
            BackgroundColor3 = color,
            BorderSizePixel = 0,
            ZIndex = zIndex,
            Parent = parent
        })
    end

    local function text(parent, name, value, size, zIndex)
        return create("TextLabel", {
            Name = name,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            FontFace = MyUILib.Font,
            TextSize = size or MyUILib.FontSize,
            TextScaled = false,
            Text = tostring(value),
            TextColor3 = Color3.fromRGB(205, 205, 205),
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Center,
            ZIndex = zIndex or 11,
            Parent = parent
        })
    end

    local function notify(callback, value)
        if type(callback) ~= "function" then return end

        local ok, err = pcall(callback, value)
        if not ok then
            warn("[posipaka] Callback: " .. tostring(err))
        end
    end

    local gui = create("ScreenGui", {
        Name = "PosipakaUI",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        DisplayOrder = 2147483646,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    })

    local coreGui=game:GetService("CoreGui")
    local candidates={}
    if type(gethui)=="function" then
        local ok,parent=pcall(gethui)
        if ok and typeof(parent)=="Instance" and (parent==coreGui or parent:IsDescendantOf(coreGui)) then
            candidates[#candidates+1]=parent
        end
    end
    candidates[#candidates+1]=coreGui
    for _,parent in ipairs(candidates) do
        local ok=pcall(function() gui.Parent=parent end)
        if ok and gui.Parent==parent then break end
    end
    if not gui.Parent or not gui:IsDescendantOf(coreGui) then
        gui:Destroy()
        error("[posipaka] CoreGui unavailable; menu was not created")
    end

    for _, existing in ipairs(gui.Parent:GetChildren()) do
        if existing ~= gui and existing.Name == gui.Name then
            existing:Destroy()
        end
    end

    local width, height = options.Width or 560, options.Height or 440
    local manuallyPositioned = false

    local outer = create("CanvasGroup", {
        Name = "OutlineOuter",
        Size = UDim2.fromOffset(width, height),
        BackgroundColor3 = Color3.fromRGB(65, 65, 65),
        BorderSizePixel = 0,
        GroupTransparency = 1,
        ZIndex = 1,
        Parent = gui
    })

    local function keepOnScreen(x, y)
        local size = gui.AbsoluteSize

        return math.floor(math.clamp(
            x, 0, math.max(0, size.X - width)
        )), math.floor(math.clamp(
            y, 0, math.max(0, size.Y - height)
        ))
    end

    local function updateWindowPosition()
        local viewport = gui.AbsoluteSize
        if viewport.X > 0 and viewport.Y > 0 then
            width = math.min(options.Width or 560, math.max(1, viewport.X - 24))
            height = math.min(options.Height or 440, math.max(1, viewport.Y - 24))
            outer.Size = UDim2.fromOffset(width, height)
        end
        if manuallyPositioned then
            local x, y = keepOnScreen(
                outer.Position.X.Offset,
                outer.Position.Y.Offset
            )
            outer.Position = UDim2.fromOffset(x, y)
        else
            local size = gui.AbsoluteSize
            outer.Position = UDim2.fromOffset(
                math.floor((size.X - width) / 2),
                math.floor((size.Y - height) / 2)
            )
        end
    end

    updateWindowPosition()

    connect(
        gui:GetPropertyChangedSignal("AbsoluteSize"),
        updateWindowPosition
    )

    layer(outer, "OutlineDark", 1, Color3.fromRGB(35, 35, 35), 2)
    layer(outer, "OutlineInner", 2, Color3.fromRGB(65, 65, 65), 3)

    local frame = layer(outer, "MainFrame", 3, background, 4)

    local tabPanel = create("Frame", {
        Name = "TabPanel",
        Position = UDim2.fromOffset(4, 4),
        Size = UDim2.fromOffset(2, 20),
        BackgroundColor3 = panelOutline,
        BorderSizePixel = 0,
        ZIndex = 5,
        Parent = frame
    })

    local tabBar = create("Frame", {
        Name = "Tabs",
        Position = UDim2.fromOffset(1, 1),
        Size = UDim2.fromOffset(0, 18),
        BackgroundColor3 = background,
        BorderSizePixel = 0,
        ZIndex = 6,
        Parent = tabPanel
    })

    local brandPanel = create("Frame", {
        Name = "BrandPanel",
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -4, 0, 4),
        Size = UDim2.fromOffset(80, 20),
        BackgroundColor3 = panelOutline,
        BorderSizePixel = 0,
        Active = true,
        ZIndex = 5,
        Parent = frame
    })

    local brandBody = layer(
        brandPanel, "Background", 1, background, 6
    )

    local title=options.Title or "posipaka.cc"
    local brandTitle,brandTail=title:match("^(.-)(%.[^%.]+)$")
    local brandName = text(brandBody, "Name", brandTitle or title, 12, 7)
    brandName.Position = UDim2.fromOffset(3, -1)
    brandName.Size = UDim2.fromOffset(0, 18)
    brandName.TextColor3 = Color3.fromRGB(255, 255, 255)
    gradient(brandName, Color3.fromRGB(190, 190, 190))

    local brandSuffix = text(brandBody, "Suffix", brandTail or "", 12, 7)
    brandSuffix.Size = UDim2.fromOffset(0, 18)
    brandSuffix.TextColor3 = accent
    gradient(brandSuffix, Color3.fromRGB(205, 205, 205))

    local function fitBrand()
        if destroyed then return end

        local a = math.ceil(brandName.TextBounds.X)
        local b = math.ceil(brandSuffix.TextBounds.X)

        if a <= 0 then a = 48 end
        if b <= 0 then b = 16 end

        brandName.Position = UDim2.fromOffset(3, -1)
        brandName.Size = UDim2.fromOffset(a, 18)

        brandSuffix.Position = UDim2.fromOffset(3 + a, -1)
        brandSuffix.Size = UDim2.fromOffset(b, 18)

        brandPanel.Size = UDim2.fromOffset(a + b + 8, 20)
    end

    connect(brandName:GetPropertyChangedSignal("TextBounds"), fitBrand)
    connect(brandSuffix:GetPropertyChangedSignal("TextBounds"), fitBrand)
    fitBrand()

    local window = {
        Gui = gui,
        Frame = frame,
        Pages = {},
        Tabs = {},
        TabLabels = {},
        Contents = {},
        SelectedTab = nil,
        OpenPopup = nil,
        IsOpen = false
    }

    window.Animate = animate
    window.Accent = accent
    window.Title = options.Title or "posipaka.cc"
    function window:GetAccent()
        return accent
    end
    function window:BindAccent(object,property,resolver)
        assert(typeof(object)=="Instance","BindAccent expects an Instance")
        resolver=resolver or function(color) return color end
        accentBindings[#accentBindings+1]={Object=object,Property=property,Resolve=resolver}
        object[property]=resolver(accent)
        return object
    end
    function window:SetAccent(color)
        assert(typeof(color)=="Color3","Accent must be Color3")
        if destroyed then return end
        accent=color;self.Accent=color
        for i=#accentBindings,1,-1 do
            local entry=accentBindings[i]
            if entry.Object.Parent then
                cancelTween(entry.Object)
                entry.Object[entry.Property]=entry.Resolve(color)
            else table.remove(accentBindings,i) end
        end
    end
    function window:AccentShade()
        return Color3.new(math.clamp(48/255+(accent.R-205/255)*.12,0,1),
            math.clamp(34/255+(accent.G-113/255)*.12,0,1),math.clamp(42/255+(accent.B-145/255)*.12,0,1))
    end
    function window:SetTitle(value)
        if destroyed then return end
        value=tostring(value or "posipaka.cc")
        local name,suffix=value:match("^(.-)(%.[^%.]+)$")
        self.Title=value
        brandName.Text=name or value;brandSuffix.Text=suffix or ""
        fitBrand()
    end
    window.SetWatermarkTitle=window.SetTitle
    window:BindAccent(brandSuffix,"TextColor3")
    function window:ClosePopups(instant)
        for _, popup in ipairs(popups) do
            if popup.IsOpen or popup.Menu.Visible then
                popup:SetOpen(false, instant)
            end
        end
    end

    local function contains(object, point)
        local p = object.AbsolutePosition
        local s = object.AbsoluteSize

        return point.X >= p.X and point.X <= p.X + s.X
            and point.Y >= p.Y and point.Y <= p.Y + s.Y
    end

    local function makePopup(
        anchor, content, preferredWidth, preferredHeight, shrink
    )
        local menu = create("CanvasGroup", {
            Name = "Popup",
            Size = UDim2.fromOffset(160, 60),
            BackgroundColor3 = controlOutline,
            BorderSizePixel = 0,
            GroupTransparency = 1,
            ClipsDescendants = true,
            Visible = false,
            Interactable = false,
            ZIndex = 100,
            Parent = outer
        })

        local body = layer(menu, "Body", 1, background, 101)

        local popup = {
            IsOpen = false,
            Menu = menu,
            PopupBody = body
        }

        local revision = 0

        function popup:Place()
            local rootPosition = outer.AbsolutePosition
            local rootSize = outer.AbsoluteSize
            local position = anchor.AbsolutePosition
            local size = anchor.AbsoluteSize

            local w = type(preferredWidth) == "function"
                and preferredWidth() or preferredWidth
            local h = type(preferredHeight) == "function"
                and preferredHeight() or preferredHeight

            w = math.max(2, math.floor(w))
            h = math.max(2, math.floor(h))

            local x = math.floor(position.X - rootPosition.X)
            local y = math.floor(position.Y - rootPosition.Y)
            local below = y + math.floor(size.Y) + 3

            local belowSpace = math.max(0, rootSize.Y - below - 4)
            local aboveSpace = math.max(0, y - 7)

            local upwards = belowSpace < h
                and aboveSpace > belowSpace

            if shrink then
                h = math.max(2, math.floor(math.min(
                    h, upwards and aboveSpace or belowSpace
                )))
            end

            x = math.clamp(
                x, 4, math.max(4, math.floor(rootSize.X) - w - 4)
            )

            local top = upwards and (y - h - 3) or below

            top = math.clamp(
                top, 4, math.max(4, math.floor(rootSize.Y) - h - 4)
            )

            menu.Position = UDim2.fromOffset(x, math.floor(top))
            menu.Size = UDim2.fromOffset(w, h)

            if self.OnLayout then
                self.OnLayout(w, h)
            end
        end

        function popup:SetOpen(open, instant)
            if destroyed then return end
            open = open == true

            if open and (
                not window.IsOpen
                or window.SelectedTab ~= content.TabName
            ) then
                return
            end

            revision = revision + 1
            local current = revision

            if open then
                for _, other in ipairs(popups) do
                    if other ~= self and (
                        other.IsOpen or other.Menu.Visible
                    ) then
                        other:SetOpen(false, true)
                    end
                end

                window.OpenPopup = self
            elseif window.OpenPopup == self then
                window.OpenPopup = nil
            end

            local wasOpen = self.IsOpen
            self.IsOpen = open
            menu.Interactable = open

            cancelTween(menu)

            if self.OnToggle then
                self.OnToggle(open, wasOpen)
            end

            if open then
                self:Place()

                if not menu.Visible then
                    menu.GroupTransparency = 1
                end

                menu.Visible = true

                if instant then
                    menu.GroupTransparency = 0
                else
                    local destination=menu.Position
                    if not wasOpen and menu.GroupTransparency>=0.999 then
                        menu.Position=destination+UDim2.fromOffset(0,4)
                    end
                    animate(menu, {GroupTransparency=0,Position=destination}, 0.18)
                end
            elseif instant then
                menu.GroupTransparency = 1
                menu.Visible = false
            else
                local tween = animate(
                    menu, {GroupTransparency=1,Position=menu.Position+UDim2.fromOffset(0,3)},
                    0.12, Enum.EasingStyle.Sine, Enum.EasingDirection.In
                )

                tween.Completed:Once(function(state)
                    if destroyed or current ~= revision then return end

                    if state == Enum.PlaybackState.Completed
                        and not self.IsOpen then
                        menu.Visible = false
                    end
                end)
            end
        end

        local function reposition()
            if not destroyed and popup.IsOpen then
                popup:Place()
            end
        end

        connect(
            anchor:GetPropertyChangedSignal("AbsolutePosition"),
            function() if popup.IsOpen then popup:SetOpen(false,true) end end
        )
        connect(
            anchor:GetPropertyChangedSignal("AbsoluteSize"),
            reposition
        )
        connect(
            outer:GetPropertyChangedSignal("AbsolutePosition"),
            reposition
        )

        connect(UIS.InputBegan, function(input)
            if not popup.IsOpen then return end

            local kind = input.UserInputType
            if kind ~= Enum.UserInputType.MouseButton1
                and kind ~= Enum.UserInputType.Touch then
                return
            end

            if not contains(anchor, input.Position)
                and not contains(menu, input.Position) then
                popup:SetOpen(false)
            end
        end)

        table.insert(popups, popup)
        return popup
    end

    local draggingWindow = false
    local dragTouch, dragStart, dragOrigin

    local function stopDraggingWindow()
        draggingWindow = false
        dragTouch = nil
    end

    connect(brandPanel.InputBegan, function(input)
        if not window.IsOpen then return end

        local kind = input.UserInputType
        if kind ~= Enum.UserInputType.MouseButton1
            and kind ~= Enum.UserInputType.Touch then
            return
        end

        window:ClosePopups(true)

        draggingWindow = true
        manuallyPositioned = true

        dragTouch = kind == Enum.UserInputType.Touch
            and input or nil

        dragStart = Vector2.new(
            input.Position.X, input.Position.Y
        )

        dragOrigin = Vector2.new(
            outer.Position.X.Offset,
            outer.Position.Y.Offset
        )
    end)

    connect(UIS.InputChanged, function(input)
        if not draggingWindow then return end

        if not window.IsOpen then
            stopDraggingWindow()
            return
        end

        if dragTouch then
            if input ~= dragTouch then return end
        elseif input.UserInputType ~= Enum.UserInputType.MouseMovement then
            return
        end

        local delta = Vector2.new(
            input.Position.X, input.Position.Y
        ) - dragStart

        local x, y = keepOnScreen(
            dragOrigin.X + delta.X,
            dragOrigin.Y + delta.Y
        )

        outer.Position = UDim2.fromOffset(x, y)
    end)

    connect(UIS.InputEnded, function(input)
        if not draggingWindow then return end

        if input == dragTouch or (
            not dragTouch
            and input.UserInputType == Enum.UserInputType.MouseButton1
        ) then
            stopDraggingWindow()
        end
    end)

    connect(UIS.WindowFocusReleased, stopDraggingWindow)

    function window:AnimateContents(tabName, opening, instant)
        for _, content in ipairs(self.Contents) do
            if content.TabName == tabName then
                local body, title = content.Body, content.Title
                local origin = content.BodyOrigin
                local duration = opening and 0.18 or 0.10
                cancelTween(body)
                cancelTween(title)
                if instant then
                    body.Position = origin
                    body.GroupTransparency = opening and 0 or 1
                    title.TextTransparency = opening and 0 or 1
                else
                    if opening and body.GroupTransparency >= 0.999 then
                        body.Position = origin + UDim2.fromOffset(0,3)
                    end
                    animate(body, {
                        GroupTransparency = opening and 0 or 1,
                        Position = opening and origin or origin + UDim2.fromOffset(0,2)
                    }, duration, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
                    animate(title, {TextTransparency=opening and 0 or 1}, duration)
                end
                for _, entry in ipairs(content.VisualCheckboxes) do
                    local transparency = opening and (entry.Control.Value and 0 or 0.22) or 1
                    cancelTween(entry.Fill)
                    entry.Fill.BackgroundColor3 = entry.Control.Value and accent or emptyColor
                    if instant then
                        entry.Fill.BackgroundTransparency = transparency
                    else
                        animate(entry.Fill, {BackgroundTransparency=transparency}, duration,
                            Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
                    end
                end
            end
        end
    end

    local restingPosition
    function window:SetOpen(open)
        if destroyed then return end

        if not tweens[outer] then restingPosition=outer.Position end
        restingPosition=restingPosition or outer.Position
        self.IsOpen = open == true
        self:AnimateContents(self.SelectedTab,self.IsOpen,false)
        openId = openId + 1
        local current = openId

        if not self.IsOpen then
            stopDraggingWindow()
            self:ClosePopups()
        end

        if self.IsOpen then
            if not gui.Enabled or outer.GroupTransparency>=0.999 then
                outer.Position=restingPosition+UDim2.fromOffset(0,6)
            end
            gui.Enabled = true
        end

        local tween = animate(outer, {
            GroupTransparency = self.IsOpen and 0 or 1,
            Position = self.IsOpen and restingPosition or restingPosition+UDim2.fromOffset(0,6)
        }, self.IsOpen and 0.22 or 0.15, Enum.EasingStyle.Quart,
            self.IsOpen and Enum.EasingDirection.Out or Enum.EasingDirection.In)

        tween.Completed:Once(function(state)
            if destroyed or current ~= openId then return end

            if state == Enum.PlaybackState.Completed then
                gui.Enabled = self.IsOpen
                if not self.IsOpen then outer.Position=restingPosition end
            end
        end)
    end

    function window:SelectTab(name, instant)
        name = string.lower(tostring(name))

        if destroyed or not self.Pages[name] then return end
        if self.SelectedTab == name then return end

        self:ClosePopups(true)

        local first = self.SelectedTab == nil
        self.SelectedTab = name
        tabId = tabId + 1
        local current = tabId

        for tabName, label in pairs(self.TabLabels) do
            local selected = tabName == name
            local page = self.Pages[tabName]

            local color = selected
                and Color3.fromRGB(255, 255, 255)
                or Color3.fromRGB(135, 135, 135)

            cancelTween(label)
            cancelTween(page)

            page.Interactable = selected
            self:AnimateContents(tabName,selected,instant or first)

            if instant or first then
                label.TextColor3 = color
                page.GroupTransparency = selected and 0 or 1
                page.Position = UDim2.fromOffset(8,30)
                page.Visible = selected
            else
                animate(label, {TextColor3 = color}, 0.12)

                if selected or page.Visible then
                    if selected and not page.Visible then page.Position=UDim2.fromOffset(8,34) end
                    page.Visible = true

                    local tween = animate(page, {
                        GroupTransparency = selected and 0 or 1,
                        Position = UDim2.fromOffset(8,selected and 30 or 32)
                    }, selected and 0.18 or 0.10)

                    tween.Completed:Once(function(state)
                        if destroyed or current ~= tabId then return end

                        if state == Enum.PlaybackState.Completed then
                            page.Visible = self.SelectedTab == tabName
                        end
                    end)
                end
            end
        end
    end

    local tabNames = {}

    local function fitTabs()
        if destroyed then return end
        local x = 0

        for _, name in ipairs(tabNames) do
            local button = window.Tabs[name]
            local label = window.TabLabels[name]

            if button and label then
                local measured = label.TextBounds.X
                if measured <= 0 then
                    measured = #name * 6
                end

                local w = math.ceil(measured) + 8

                button.Position = UDim2.fromOffset(x, 0)
                button.Size = UDim2.fromOffset(w, 18)

                label.Position = UDim2.fromOffset(0, -1)
                label.Size = UDim2.fromOffset(w, 18)

                x = x + w + 2
            end
        end

        local w = math.max(0, x - 2)
        tabBar.Size = UDim2.fromOffset(w, 18)
        tabPanel.Size = UDim2.fromOffset(w + 2, 20)
    end

    function window:AddTab(name)
        name=tostring(name):lower()
        if self.Pages[name] then return self.Pages[name] end
        table.insert(tabNames,name)
        local button = create("TextButton", {
            Name = name,
            Size = UDim2.fromOffset(50, 18),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Text = "",
            ZIndex = 7,
            Parent = tabBar
        })

        local label = text(button, "Text", name, 12, 8)
        label.Position = UDim2.fromOffset(0, -1)
        label.Size = UDim2.fromOffset(50, 18)
        label.TextXAlignment = Enum.TextXAlignment.Center
        label.TextColor3 = Color3.fromRGB(135, 135, 135)

        window.Pages[name] = create("CanvasGroup", {
            Name = name .. "Page",
            Position = UDim2.fromOffset(8, 30),
            Size = UDim2.new(1, -16, 1, -38),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            GroupTransparency = 1,
            Visible = false,
            Interactable = false,
            ZIndex = 5,
            Parent = frame
        })

        window.Tabs[name] = button
        window.TabLabels[name] = label

        connect(
            label:GetPropertyChangedSignal("TextBounds"),
            fitTabs
        )

        connect(button.Activated, function()
            if window.IsOpen then
                window:SelectTab(name)
            end
        end)
        fitTabs()
        if not self.SelectedTab then self:SelectTab(name,true) end
        return self.Pages[name]
    end

    function window:Content(tabName, titleText)
        tabName = string.lower(tabName)
        local page = self.Pages[tabName]
        assert(page, "Unknown tab: " .. tostring(tabName))

        local section = create("Frame", {
            Name = "Content",
            Position = UDim2.fromOffset(0, 8),
            Size = UDim2.fromOffset(140, 44),
            BackgroundColor3 = panelOutline,
            BorderSizePixel = 0,
            ZIndex = 6,
            Parent = page
        })

        layer(section, "Background", 1, background, 7)

        local body = create("CanvasGroup", {
            GroupTransparency = 0,
            Name = "Body",
            Position = UDim2.fromOffset(10, 16),
            Size = UDim2.new(1, -20, 1, -26),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 8,
            Parent = section
        })

        local layout = create("UIListLayout", {
            Padding = UDim.new(0, 6),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = body
        })

        local title = text(
            section, "Title", titleText or "Content", 11, 20
        )

        title.Position = UDim2.fromOffset(7, -6)
        title.Size = UDim2.fromOffset(0, 13)
        title.AutomaticSize = Enum.AutomaticSize.X
        title.BackgroundTransparency = 0
        title.BackgroundColor3 = background
        title.TextColor3 = Color3.fromRGB(220, 220, 220)

        create("UIPadding", {
            PaddingLeft = UDim.new(0, 3),
            PaddingRight = UDim.new(0, 3),
            Parent = title
        })

        local function fit()
            if destroyed then return end

            section.Size = UDim2.new(1, 0, 0,
                math.max(
                    44,
                    math.ceil(layout.AbsoluteContentSize.Y) + 26
                )
            )
        end

        connect(
            layout:GetPropertyChangedSignal("AbsoluteContentSize"),
            fit
        )
        connect(title:GetPropertyChangedSignal("TextBounds"), fit)

        local content = {
            Frame = section,
            Body = body,
            Title = title,
            Fit = fit,
            Count = 0,
            Window = self,
            TabName = tabName,
            VisualCheckboxes = {},
            BodyOrigin = body.Position
        }

        table.insert(self.Contents, content)
        fit()

        return content
    end

    local function controlRow(content, rowHeight)
        assert(
            content and content.Window == window and content.Body,
            "Pass a content created with window:Content()"
        )

        content.Count = content.Count + 1

        return create("TextButton", {
            Name = "Control",
            LayoutOrder = content.Count,
            Size = UDim2.new(1, 0, 0, rowHeight),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Text = "",
            ZIndex = 9,
            Parent = content.Body
        })
    end

    local function canUse(content)
        return window.IsOpen
            and window.SelectedTab == content.TabName
    end

    function window:Checkbox(name, content, default, callback)
        local row = controlRow(content, 20)
        row.Name = "Checkbox"

        local label = text(row, "Label", name, 12, 10)
        label.AnchorPoint = Vector2.new(0, 0.5)
        label.Position = UDim2.new(0, 0, 0.5, -1)
        label.Size = UDim2.fromOffset(0, 14)
        label.AutomaticSize = Enum.AutomaticSize.X

        local box = create("Frame", {
            Name = "Outline",
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.fromScale(1, 0.5),
            Size = UDim2.fromOffset(14, 14),
            BackgroundColor3 = controlOutline,
            BorderSizePixel = 0,
            ZIndex = 10,
            Parent = row
        })

        local fill = layer(box, "Fill", 1, emptyColor, 11)
        gradient(fill)

        local function fit()
            if destroyed then return end

            row.Size = UDim2.new(1, 0, 0, 20)
            content.Fit()
        end

        connect(label:GetPropertyChangedSignal("TextBounds"), fit)

        local checkbox = {
            Value = default == true,
            Row = row,
            Label = label,
            Box = box
        }

        table.insert(content.VisualCheckboxes, {Control=checkbox,Fill=fill})
        window:BindAccent(fill,"BackgroundColor3",function(color) return checkbox.Value and color or emptyColor end)

        function checkbox:SetValue(value, instant)
            if destroyed then return end

            value = value == true
            local changed = self.Value ~= value
            self.Value = value

            local color = value and accent or emptyColor

            if instant then
                cancelTween(fill)
                fill.BackgroundColor3 = color
                fill.BackgroundTransparency = value and 0 or 0.22
            else
                animate(fill, {BackgroundColor3=color,BackgroundTransparency=value and 0 or 0.22},
                    0.13, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
            end

            if changed then
                notify(callback, value)
            end
        end

        connect(row.Activated, function()
            if canUse(content) then
                checkbox:SetValue(not checkbox.Value)
            end
        end)

        checkbox:SetValue(checkbox.Value, true)
        fit()

        return checkbox
    end

    function window:Slider(
        name, content, minimum, maximum, default, step, callback
    )
        minimum = tonumber(minimum) or 0
        maximum = tonumber(maximum) or 100
        step = tonumber(step) or 1

        assert(maximum > minimum, "Slider maximum must exceed minimum")
        assert(step > 0, "Slider step must be positive")

        local row = controlRow(content, 36)
        row.Name = "Slider"

        local label = text(row, "Label", name, 12, 10)
        label.Size = UDim2.fromOffset(0, 14)
        label.AutomaticSize = Enum.AutomaticSize.X

        local bar = create("TextButton", {
            Name = "Outline",
            Position = UDim2.fromOffset(0, 18),
            Size = UDim2.new(1, 0, 0, 14),
            BackgroundColor3 = controlOutline,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Text = "",
            ZIndex = 10,
            Parent = row
        })

        local track = layer(bar, "Track", 1, emptyColor, 11)
        track.ClipsDescendants = true
        gradient(track)

        local fill = create("Frame", {
            Name = "Fill",
            Size = UDim2.new(0, 0, 1, 0),
            BackgroundColor3 = accent,
            BorderSizePixel = 0,
            ZIndex = 12,
            Parent = track
        })

        gradient(fill)
        window:BindAccent(fill,"BackgroundColor3")

        local valueText = text(bar, "Value", "", 11, 13)
        valueText.AnchorPoint = Vector2.new(0.5, 0.5)
        valueText.Position = UDim2.new(0.5, 0, 0.5, -1)
        valueText.Size = UDim2.new(1, -2, 0, 12)
        valueText.TextXAlignment = Enum.TextXAlignment.Center
        valueText.TextColor3 = Color3.fromRGB(240, 240, 240)

        local function fit()
            if destroyed then return end

            row.Size = UDim2.new(1, 0, 0, 36)
            content.Fit()
        end

        connect(label:GetPropertyChangedSignal("TextBounds"), fit)

        local decimals = 0

        while decimals < 6 do
            local scaled = step * 10 ^ decimals

            if math.abs(scaled - math.round(scaled)) < 0.000001 then
                break
            end

            decimals = decimals + 1
        end

        local slider = {
            Value = nil,
            Row = row,
            Label = label,
            Bar = bar,
            Min = minimum,
            Max = maximum,
            Step = step
        }

        function slider:SetValue(value, instant)
            if destroyed then return end

            value = math.clamp(
                tonumber(value) or minimum,
                minimum,
                maximum
            )

            if value > minimum and value < maximum then
                value = minimum + math.round(
                    (value - minimum) / step
                ) * step
            end

            value = math.clamp(value, minimum, maximum)

            local changed = self.Value ~= value
            if not changed and not instant then return end

            self.Value = value

            local ratio = (value - minimum) / (maximum - minimum)
            local size = UDim2.new(ratio, 0, 1, 0)

            valueText.Text = string.format(
                "%." .. decimals .. "f", value
            )

            if instant then
                cancelTween(fill)
                fill.Size = size
            else
                animate(fill, {Size = size}, 0.055, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
            end

            if changed then
                notify(callback, value)
            end
        end

        local dragging = false
        local touchInput

        local function updateFromX(x)
            local w = track.AbsoluteSize.X
            if w <= 0 then return end

            local ratio = math.clamp(
                (x - track.AbsolutePosition.X) / w,
                0,
                1
            )

            slider:SetValue(
                minimum + ratio * (maximum - minimum),
                false
            )
        end

        connect(bar.InputBegan, function(input)
            if not canUse(content) or window.OpenPopup then return end

            local kind = input.UserInputType

            if kind == Enum.UserInputType.MouseButton1
                or kind == Enum.UserInputType.Touch then
                dragging = true

                touchInput = kind == Enum.UserInputType.Touch
                    and input or nil

                updateFromX(input.Position.X)
            end
        end)

        connect(UIS.InputChanged, function(input)
            if not dragging then return end

            if not canUse(content) or window.OpenPopup then
                dragging = false
                touchInput = nil
                return
            end

            if touchInput then
                if input == touchInput then
                    updateFromX(input.Position.X)
                end
            elseif input.UserInputType == Enum.UserInputType.MouseMovement then
                updateFromX(input.Position.X)
            end
        end)

        connect(UIS.InputEnded, function(input)
            if input == touchInput or (
                not touchInput
                and input.UserInputType == Enum.UserInputType.MouseButton1
            ) then
                dragging = false
                touchInput = nil
            end
        end)

        connect(UIS.WindowFocusReleased, function()
            dragging = false
            touchInput = nil
        end)

        slider:SetValue(default or minimum, true)
        fit()

        return slider
    end

    function window:Dropdown(name, content, items, default, callback, multi)
        assert(
            type(items) == "table" and #items > 0,
            "Dropdown needs items"
        )

        local row = controlRow(content, 36)
        row.Name = "Dropdown"

        local label = text(row, "Label", name, 12, 10)
        label.Size = UDim2.fromOffset(0, 14)
        label.AutomaticSize = Enum.AutomaticSize.X

        local button = create("TextButton", {
            Name = "Outline",
            Position = UDim2.fromOffset(0, 18),
            Size = UDim2.new(1, 0, 0, 18),
            BackgroundColor3 = controlOutline,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Text = "",
            ZIndex = 10,
            Parent = row
        })

        local fill = layer(button, "Background", 1, emptyColor, 11)
        gradient(fill)

        local valueText = text(button, "Value", "", 12, 12)
        valueText.Position = UDim2.fromOffset(6, -1)
        valueText.Size = UDim2.new(1, -12, 1, 0)
        valueText.TextTruncate = Enum.TextTruncate.AtEnd

        local canvasHeight = #items * 18 + 4

        local dropdown = makePopup(
            button,
            content,
            function()
                return button.AbsoluteSize.X
            end,
            math.min(#items, 6) * 18 + 6,
            true
        )

        dropdown.Value = nil
        dropdown.Row = row
        dropdown.Label = label
        dropdown.Button = button
        dropdown.Items = items

        local list = create("ScrollingFrame", {
            Name = "Items",
            Size = UDim2.fromScale(1, 1),
            CanvasSize = UDim2.fromOffset(0, canvasHeight),
            CanvasPosition = Vector2.new(0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.None,
            ScrollBarThickness = 0,
            ScrollBarImageColor3 = Color3.fromRGB(75, 75, 75),
            ScrollingDirection = Enum.ScrollingDirection.Y,
            ElasticBehavior = Enum.ElasticBehavior.Never,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 102,
            Parent = dropdown.PopupBody
        })

        dropdown.OnLayout = function(_, h)
            local scroll = canvasHeight > h - 2
            list.ScrollingEnabled = scroll
            list.ScrollBarThickness = 0
        end

        dropdown.OnToggle = function(open)
            animate(fill, {
                BackgroundColor3 = open
                    and Color3.fromRGB(40, 40, 40)
                    or emptyColor
            })

            if open then
                list.CanvasPosition = Vector2.new(0, 0)
            end
        end

        local options = {}

        function dropdown:SetValue(value)
            if destroyed then return end
            if multi then
                local selected={}
                for _,item in ipairs(items) do
                    if type(value)=="table" and (value[item]==true or table.find(value,item)) then table.insert(selected,item) end
                end
                local changed=type(self.Value)~="table" or #self.Value~=#selected
                if not changed then for index,item in ipairs(selected) do if self.Value[index]~=item then changed=true; break end end end
                self.Value=selected
                valueText.Text=#selected>0 and table.concat(selected,", ") or "none"
                for index,option in ipairs(options) do
                    local checked=table.find(selected,items[index])~=nil
                    option.Text=tostring(items[index])
                    animate(option,{TextColor3=checked and accent or Color3.fromRGB(205,205,205)},0.12)
                end
                if changed then notify(callback,selected) end
                return
            end

            local found = false

            for _, item in ipairs(items) do
                if item == value then
                    found = true
                    break
                end
            end

            if not found then return end

            local changed = self.Value ~= value
            self.Value = value
            valueText.Text = tostring(value)

            for index, option in ipairs(options) do
                animate(option, {
                    TextColor3 = items[index] == value
                        and accent
                        or Color3.fromRGB(205, 205, 205)
                }, 0.12)
            end

            if changed then
                notify(callback, value)
            end
        end

        for index, item in ipairs(items) do
            local option = create("TextButton", {
                Name = "Option" .. index,
                Position = UDim2.fromOffset(
                    0, 2 + (index - 1) * 18
                ),
                Size = UDim2.new(1, 0, 0, 18),
                BackgroundColor3 = emptyColor,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                AutoButtonColor = false,
                FontFace = MyUILib.Font,
                TextSize = MyUILib.FontSize,
                Text = tostring(item),
                TextColor3 = Color3.fromRGB(205, 205, 205),
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 103,
                Parent = list
            })

            create("UIPadding", {
                PaddingLeft = UDim.new(0, 5),
                PaddingRight = UDim.new(0, 5),
                Parent = option
            })

            options[index] = option
            window:BindAccent(option,"TextColor3",function(color)
                local checked=multi and type(dropdown.Value)=="table" and table.find(dropdown.Value,item)
                    or not multi and dropdown.Value==item
                return checked and color or Color3.fromRGB(205,205,205)
            end)

            connect(option.MouseEnter, function()
                animate(option, {
                    BackgroundTransparency = 0
                }, 0.10)
            end)

            connect(option.MouseLeave, function()
                animate(option, {
                    BackgroundTransparency = 1
                }, 0.10)
            end)

            connect(option.Activated, function()
                if not dropdown.IsOpen or not canUse(content) then
                    return
                end

                if multi then
                    local selected={}
                    for _,value in ipairs(dropdown.Value or {}) do if value~=item then table.insert(selected,value) end end
                    if not table.find(dropdown.Value or {},item) then table.insert(selected,item) end
                    dropdown:SetValue(selected)
                else
                    dropdown:SetValue(item)
                    dropdown:SetOpen(false)
                end
            end)
        end

        local function fit()
            if destroyed then return end

            row.Size = UDim2.new(1, 0, 0, 36)

            content.Fit()

            if dropdown.IsOpen then
                dropdown:Place()
            end
        end

        connect(label:GetPropertyChangedSignal("TextBounds"), fit)

        connect(button.Activated, function()
            if canUse(content) then
                dropdown:SetOpen(not dropdown.IsOpen)
            end
        end)

        local initial = items[1]

        for _, item in ipairs(items) do
            if item == default then
                initial = item
                break
            end
        end

        dropdown:SetValue(multi and (default or {}) or initial)
        fit()

        return dropdown
    end

    function window:ColorPicker(name, content, default, callback)
        local row = controlRow(content, 20)
        row.Name = "ColorPicker"

        local label = text(row, "Label", name, 12, 10)
        label.AnchorPoint = Vector2.new(0, 0.5)
        label.Position = UDim2.new(0, 0, 0.5, -1)
        label.Size = UDim2.fromOffset(0, 14)
        label.AutomaticSize = Enum.AutomaticSize.X

        local button = create("TextButton", {
            Name = "ColorPreview",
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.fromScale(1, 0.5),
            Size = UDim2.fromOffset(24, 14),
            BackgroundColor3 = controlOutline,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Text = "",
            ZIndex = 10,
            Parent = row
        })

        local swatch = layer(button, "Color", 1, accent, 11)
        local picker = makePopup(button, content, 184, 166, false)

        picker.Row = row
        picker.Label = label
        picker.Button = button
        picker.Value = nil
        picker.H, picker.S, picker.V = 0, 1, 1

        local body = picker.PopupBody

        local svOutline = create("Frame", {
            Name = "SVOutline",
            Position = UDim2.fromOffset(7, 7),
            Size = UDim2.fromOffset(146, 130),
            BackgroundColor3 = controlOutline,
            BorderSizePixel = 0,
            ZIndex = 102,
            Parent = body
        })

        local sv = create("TextButton", {
            Name = "SaturationValue",
            Position = UDim2.fromOffset(1, 1),
            Size = UDim2.fromOffset(144, 128),
            BackgroundColor3 = Color3.fromHSV(0, 1, 1),
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Text = "",
            ZIndex = 103,
            Parent = svOutline
        })

        local saturation = create("Frame", {
            Name = "Saturation",
            Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BorderSizePixel = 0,
            ZIndex = 104,
            Parent = sv
        })

        create("UIGradient", {
            Rotation = 0,
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0),
                NumberSequenceKeypoint.new(1, 1)
            }),
            Parent = saturation
        })

        local valueShade = create("Frame", {
            Name = "Value",
            Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = Color3.fromRGB(0, 0, 0),
            BorderSizePixel = 0,
            ZIndex = 105,
            Parent = sv
        })

        create("UIGradient", {
            Rotation = 90,
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1),
                NumberSequenceKeypoint.new(1, 0)
            }),
            Parent = valueShade
        })

        local svMarker = create("Frame", {
            Name = "SVMarker",
            AnchorPoint = Vector2.new(0.5, 0.5),
            Size = UDim2.fromOffset(8, 8),
            BackgroundTransparency = 1,
            BorderSizePixel = 1,
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            ZIndex = 106,
            Parent = sv
        })

        create("Frame", {
            Position = UDim2.fromOffset(1, 1),
            Size = UDim2.fromOffset(6, 6),
            BackgroundTransparency = 1,
            BorderSizePixel = 1,
            BorderColor3 = Color3.fromRGB(255, 255, 255),
            ZIndex = 107,
            Parent = svMarker
        })

        local hueOutline = create("Frame", {
            Name = "HueOutline",
            Position = UDim2.fromOffset(159, 7),
            Size = UDim2.fromOffset(14, 130),
            BackgroundColor3 = controlOutline,
            BorderSizePixel = 0,
            ZIndex = 102,
            Parent = body
        })

        local hue = create("TextButton", {
            Name = "Hue",
            Position = UDim2.fromOffset(1, 1),
            Size = UDim2.fromOffset(12, 128),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Text = "",
            ZIndex = 103,
            Parent = hueOutline
        })

        local rainbow = {}

        for i = 0, 6 do
            table.insert(rainbow, ColorSequenceKeypoint.new(
                i / 6, Color3.fromHSV(i / 6, 1, 1)
            ))
        end

        create("UIGradient", {
            Rotation = 90,
            Color = ColorSequence.new(rainbow),
            Parent = hue
        })

        local hueMarker = create("Frame", {
            Name = "HueMarker",
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0),
            Size = UDim2.fromOffset(16, 3),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BorderSizePixel = 1,
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            ZIndex = 106,
            Parent = hue
        })

        local previewOutline = create("Frame", {
            Name = "SelectedColor",
            Position = UDim2.fromOffset(7, 144),
            Size = UDim2.fromOffset(166, 14),
            BackgroundColor3 = controlOutline,
            BorderSizePixel = 0,
            ZIndex = 102,
            Parent = body
        })

        local preview = layer(
            previewOutline, "Color", 1, accent, 103
        )

        local hexText = text(
            previewOutline, "Hex", "", 11, 104
        )

        hexText.Position = UDim2.fromOffset(0, -1)
        hexText.Size = UDim2.fromScale(1, 1)
        hexText.TextXAlignment = Enum.TextXAlignment.Center

        local function updateVisuals()
            local color = Color3.fromHSV(
                picker.H, picker.S, picker.V
            )

            swatch.BackgroundColor3 = color
            preview.BackgroundColor3 = color
            sv.BackgroundColor3 = Color3.fromHSV(picker.H, 1, 1)

            svMarker.Position = UDim2.fromOffset(
                math.floor(math.clamp(
                    picker.S * 144, 4, 140
                )),
                math.floor(math.clamp(
                    (1 - picker.V) * 128, 4, 124
                ))
            )

            hueMarker.Position = UDim2.new(
                0.5, 0, 0, math.floor(picker.H * 127)
            )

            hexText.Text = string.format(
                "#%02X%02X%02X",
                math.round(color.R * 255),
                math.round(color.G * 255),
                math.round(color.B * 255)
            )

            local brightness =
                color.R * 0.299
                + color.G * 0.587
                + color.B * 0.114

            hexText.TextColor3 = brightness > 0.6
                and Color3.fromRGB(20, 20, 20)
                or Color3.fromRGB(245, 245, 245)

            return color
        end

        function picker:SetHSV(h, s, v)
            if destroyed then return end

            self.H = math.clamp(
                tonumber(h) or self.H, 0, 1
            )
            self.S = math.clamp(
                tonumber(s) or self.S, 0, 1
            )
            self.V = math.clamp(
                tonumber(v) or self.V, 0, 1
            )

            local color = updateVisuals()
            local changed = self.Value ~= color
            self.Value = color

            if changed then
                notify(callback, color)
            end
        end

        function picker:SetValue(color)
            if destroyed or typeof(color) ~= "Color3" then return end

            local h, s, v = color:ToHSV()
            self:SetHSV(h, s, v)
        end

        local dragTarget
        local touchInput

        local function stopPaletteDrag()
            dragTarget = nil
            touchInput = nil
        end

        local function updatePalette(point)
            if dragTarget == "sv" then
                local p = sv.AbsolutePosition
                local size = sv.AbsoluteSize

                if size.X <= 0 or size.Y <= 0 then return end

                picker:SetHSV(
                    picker.H,
                    math.clamp(
                        (point.X - p.X) / size.X, 0, 1
                    ),
                    1 - math.clamp(
                        (point.Y - p.Y) / size.Y, 0, 1
                    )
                )
            elseif dragTarget == "hue" then
                local p = hue.AbsolutePosition
                local size = hue.AbsoluteSize

                if size.Y <= 0 then return end

                picker:SetHSV(
                    math.clamp(
                        (point.Y - p.Y) / size.Y, 0, 1
                    ),
                    picker.S,
                    picker.V
                )
            end
        end

        local function beginPaletteDrag(target, input)
            if not picker.IsOpen or not canUse(content) then return end

            local kind = input.UserInputType

            if kind ~= Enum.UserInputType.MouseButton1
                and kind ~= Enum.UserInputType.Touch then
                return
            end

            dragTarget = target
            touchInput = kind == Enum.UserInputType.Touch
                and input or nil

            updatePalette(input.Position)
        end

        connect(sv.InputBegan, function(input)
            beginPaletteDrag("sv", input)
        end)

        connect(hue.InputBegan, function(input)
            beginPaletteDrag("hue", input)
        end)

        connect(UIS.InputChanged, function(input)
            if not dragTarget then return end

            if not picker.IsOpen or not canUse(content) then
                stopPaletteDrag()
                return
            end

            if touchInput then
                if input == touchInput then
                    updatePalette(input.Position)
                end
            elseif input.UserInputType == Enum.UserInputType.MouseMovement then
                updatePalette(input.Position)
            end
        end)

        connect(UIS.InputEnded, function(input)
            if not dragTarget then return end

            if input == touchInput or (
                not touchInput
                and input.UserInputType == Enum.UserInputType.MouseButton1
            ) then
                stopPaletteDrag()
            end
        end)

        connect(UIS.WindowFocusReleased, stopPaletteDrag)

        picker.OnToggle = function(open)
            if not open then
                stopPaletteDrag()
            end
        end

        local function fit()
            if destroyed then return end

            row.Size = UDim2.new(1, 0, 0, 20)
            content.Fit()
        end

        connect(label:GetPropertyChangedSignal("TextBounds"), fit)

        connect(button.Activated, function()
            if canUse(content) then
                picker:SetOpen(not picker.IsOpen)
            end
        end)

        picker:SetValue(
            typeof(default) == "Color3" and default or accent
        )

        fit()
        return picker
    end

    fitTabs()

    connect(UIS.InputBegan, function(input, processed)
        if not processed and input.KeyCode == (options.MenuKey or Enum.KeyCode.RightShift) then
            window:SetOpen(not window.IsOpen)
        end
    end)

    gui.Destroying:Connect(function()
        destroyed = true
        openId = openId + 1
        tabId = tabId + 1

        stopDraggingWindow()

        for _, connection in ipairs(connections) do
            connection:Disconnect()
        end

        local active = {}

        for _, tween in pairs(tweens) do
            table.insert(active, tween)
        end

        table.clear(tweens)
        table.clear(accentBindings)

        for _, tween in ipairs(active) do
            tween:Cancel()
        end
    end)

    function window:Destroy()
        gui:Destroy()
    end

    window:SetOpen(true)
    return window
end

return MyUILib

end)()

local Posipaka={Version="2.1.0",Font=Native.Font,FontSize=Native.FontSize,
    DefaultTitle="posipaka.cc",DefaultAccent=Color3.fromRGB(205,113,145)}
function Posipaka:SetDefaultTitle(title)
    self.DefaultTitle=tostring(title or "posipaka.cc")
    return self
end
function Posipaka:SetDefaultAccent(color)
    assert(typeof(color)=="Color3","Accent must be Color3")
    self.DefaultAccent=color
    return self
end
function Posipaka:CreateWindow(options)
    options=table.clone(options or {})
    if options.Title==nil then options.Title=self.DefaultTitle end
    if options.Accent==nil then options.Accent=self.DefaultAccent end
    local windowOptions=options
    local UILib=Native
    local UI=UILib:CreateWindow(options)
    local nativeDestroy=UI.Destroy
    local menuKey=options.MenuKey or Enum.KeyCode.RightShift
local UIS = game:GetService("UserInputService")
local Library: any = {Flags = {}, Instances = {}, Connections = {}, Controls = {}, Binds = {}, ColorMirrors = {}, Font = UILib.Font, FontSize = UILib.FontSize}
local alive = true
local capturing = nil
local captureClickUntil=0
local captureMouseRelease=nil
local bindings = {}
local focused = true
local modePopup=nil
local tabs = {}
local pages = {}
local function make(class, properties)
    local object = Instance.new(class)
    for key, value in pairs(properties) do object[key] = value end
    return object
end
function Library:Connect(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(self.Connections, connection)
    return connection
end
function Library:Notification(_options)
end
function Library:Exit()
    if not alive then return end
    alive = false
    for _, connection in ipairs(self.Connections) do connection:Disconnect() end
    for _, object in ipairs(self.Instances) do pcall(function() object:Destroy() end) end
    if UI.Gui.Parent then nativeDestroy(UI) end
end

local function publish(options, value)
    if options.Flag then Library.Flags[options.Flag] = value end
    local mirrors=Library.ColorMirrors[options.Flag]
    if mirrors and not Library.SynchronizingColors then
        Library.SynchronizingColors=true
        for _,mirror in ipairs(mirrors) do mirror:SetValue(value) end
        Library.SynchronizingColors=false
    end
    if options.Callback then options.Callback(value) end

end
local function register(options, control)
    if options.Flag then Library.Controls[options.Flag] = {Control=control, Default=options.Default, Options=options} end
    return control
end
local function row(content, name, height)
    content.Count = content.Count + 1
    local button = make("TextButton", {
        Name = "ExtraControl", LayoutOrder = content.Count, Text = name,
        Size = UDim2.new(1,0,0,height or 28), FontFace = Library.Font, TextSize = Library.FontSize,
        TextColor3 = Color3.fromRGB(220,220,220), BackgroundColor3 = Color3.fromRGB(34,34,34),
        BorderSizePixel=1, BorderMode=Enum.BorderMode.Inset, BorderColor3 = Color3.fromRGB(55,55,55), AutoButtonColor = true, ZIndex = 10, Parent = content.Body,
    })
    content.Fit()
    return button
end
local Section = {}
Section.__index = Section
local function reuse(options)
    local entry=options.Flag and Library.Controls[options.Flag]
    if entry then
        entry.Options.Callback=options.Callback
        if options.Callback and entry.Control.Value==true then
            task.defer(function() options.Callback(true) end)
        end
        return entry.Control
    end
    return nil
end
function Section:Toggle(options)
    local existing=reuse(options); if existing then return existing end
    Library.Flags[options.Flag] = options.Default == true
    local bindFlag=options.BindFlag or options.Flag.."_bind"
    local control
    control = UI:Checkbox(options.Name, self.Content, options.Default, function(value)
        local entry=Library.Binds[bindFlag]
        if entry and entry.Control.Mode=="Always" and not value then control:SetValue(true); return end
        if entry then entry.Control.Toggled=value end
        publish(options,value)
    end)
    control.Set = control.SetValue
    control.Section = self
    register(options,control)
    local hasBind = (options.Bind==true or (windowOptions.BindByDefault and options.Bind~=false)) and not options.NoBind
    if hasBind then
    self:Label({Name=options.Name,Target=control}):Keybind({
        Flag=bindFlag,Default=options.BindDefault or (windowOptions.DefaultBinds and windowOptions.DefaultBinds[bindFlag]),
        Mode=options.BindMode or "Toggle",GetState=function() return control.Value end,Callback=function(value) control:Set(value) end,
    })
    else
        control.Box.Position=UDim2.new(1,0,0.5,0)
        control.Label.AutomaticSize=Enum.AutomaticSize.None
        control.Label.Size=UDim2.new(1,-24,0,14)
        control.Label.TextTruncate=Enum.TextTruncate.AtEnd
    end
    return control
end
function Section:Slider(options)
    local existing=reuse(options); if existing then return existing end
    Library.Flags[options.Flag] = options.Default
    local name = options.Name .. (options.Suffix and " (" .. options.Suffix .. ")" or "")
    local control = UI:Slider(name, self.Content, options.Min, options.Max, options.Default,
        options.Step or options.Decimals or 1, function(value) publish(options,value) end)
    control.Set = control.SetValue
    control.SectionContent=self.Content
    return register(options,control)
end
function Section:Dropdown(options)
    local existing=reuse(options); if existing then return existing end
    Library.Flags[options.Flag] = options.Default
    local control=UI:Dropdown(options.Name,self.Content,options.Items,options.Default,function(value) publish(options,value) end,options.Multi)
    control.Set=control.SetValue
    control.SectionContent=self.Content
    return register(options,control)
end
function Section:Button(options)
    self.Buttons=self.Buttons or {}
    if self.Buttons[options.Name] then
        self.Buttons[options.Name].Options.Callback=options.Callback
        return self.Buttons[options.Name].Button
    end
    local button = row(self.Content,options.Name)
    self.Buttons[options.Name]={Options=options,Button=button}
    Library:Connect(button.Activated,function()
        if UI.IsOpen then
            if not options.Callback then
                Library:Notification({Name=Library.RuntimeError or "Game modules are still loading"})
                return
            end
            local ok, err = pcall(options.Callback)
            if not ok then Library:Notification({Name=tostring(err)}) end
        end
    end)
    return button
end
function Section:Label(options)
    local section = self
    local label = {Name=options.Name}
    function label:Colorpicker(config)
        local existing=reuse(config); if existing then return existing end
        Library.Flags[config.Flag] = config.Default
        local control = UI:ColorPicker(options.Name,section.Content,config.Default,function(value) publish(config,value) end)
        control.Set = control.SetValue
        return register(config,control)
    end
    function label:Keybind(config)
        if Library.Binds[config.Flag] then
            local entry=Library.Binds[config.Flag]
            entry.Config.Callback=config.Callback
            entry.Config.GetState=config.GetState or entry.Config.GetState
            return entry.Control
        end
        local control = {Key=config.Default, Toggled=false, Mode=config.Mode or "Toggle", Held=false}
        Library.Binds[config.Flag]={Control=control,Config=config}
        Library.Flags[config.Flag] = control
        local target=assert(options.Target,"Inline bind needs a checkbox")
        target.Box.Position=UDim2.new(1,0,0.5,0)
        local button = make("TextButton",{
            Name="InlineBind",Text="[-]",AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-20,0.5,-1),
            Size=UDim2.fromOffset(24,18),BackgroundTransparency=1,BorderSizePixel=0,TextTruncate=Enum.TextTruncate.AtEnd,
            FontFace=Library.Font,TextSize=11,TextColor3=Color3.fromRGB(170,170,170),
            ZIndex=14,Parent=target.Row,
        })
        target.Label.AutomaticSize=Enum.AutomaticSize.None
        target.Label.Size=UDim2.new(1,-50,0,14)
        target.Label.TextTruncate=Enum.TextTruncate.AtEnd
        control.Button=button
        Library:Connect(button.MouseEnter,function() UI.Animate(button,{TextColor3=Color3.fromRGB(220,220,220)},0.10) end)
        Library:Connect(button.MouseLeave,function() UI.Animate(button,{TextColor3=Color3.fromRGB(170,170,170)},0.14) end)
        local function fitBind()
            local width=math.clamp(math.ceil(button.TextBounds.X)+4,24,64)
            button.Size=UDim2.fromOffset(width,18)
            target.Label.Size=UDim2.new(1,-(20+width+6),0,14)
        end
        Library:Connect(button:GetPropertyChangedSignal("TextBounds"),fitBind)
        local function caption()
            local name=control.Key and control.Key.Name or "-"
            name=name:gsub("MouseButton","M"):gsub("LeftControl","LCtrl"):gsub("RightControl","RCtrl")
                :gsub("LeftShift","LShift"):gsub("LeftAlt","LAlt"):gsub("RightAlt","RAlt")
            button.Text="["..name.."]"
            fitBind()
        end
        caption()
        function control:Set(key)
            if self.Held then self:Release() end
            self.Key = key
            caption()
        end
        function control:Apply(value)
            self.Toggled = value == true
            if config.Callback then config.Callback(self.Toggled) end
        end
        function control:Release()
            if not self.Held then return end
            self.Held = false
            if self.Mode=="Hold" then self:Apply(false) end
        end
        function control:Current()
            if config.GetState then return config.GetState()==true end
            return self.Toggled
        end
        function control:SetMode(mode)
            assert(mode=="Hold" or mode=="Always" or mode=="Toggle","Invalid bind mode")
            local previous=self.Mode
            self:Release()
            self.Mode=mode
            if mode=="Always" then self:Apply(true)
            elseif previous=="Always" or mode=="Hold" then self:Apply(false)
            else self.Toggled=self:Current() end
        end
        table.insert(bindings,control)
        Library:Connect(button.Activated,function()
            if captureMouseRelease or os.clock()<captureClickUntil then return end
            if capturing then capturing.Caption() end
            capturing = {Control=control, Button=button, Caption=caption}
            button.Text = "[...]"
        end)
        Library:Connect(button.MouseButton2Click,function()
            if captureMouseRelease or os.clock()<captureClickUntil then return end
            if modePopup then modePopup:Destroy(); modePopup=nil end
            if capturing then capturing.Caption(); capturing=nil end
            UI:ClosePopups(true)
            local pos=button.AbsolutePosition
            local size=UI.Gui.AbsoluteSize
            local menu=make("CanvasGroup",{
                GroupTransparency=1,Name="BindModes",Size=UDim2.fromOffset(84,61),
                Position=UDim2.fromOffset(math.clamp(pos.X+button.AbsoluteSize.X+4,0,math.max(0,size.X-84)),math.clamp(pos.Y,0,math.max(0,size.Y-61))),
                BackgroundColor3=Color3.fromRGB(24,24,24),BorderColor3=Color3.fromRGB(65,65,65),ZIndex=210,Parent=UI.Gui,
            })
            modePopup=menu
            UI.Animate(menu,{GroupTransparency=0},0.16)
            for index,mode in ipairs({"Hold","Always","Toggle"}) do
                local item=make("TextButton",{
                    Text=mode,Position=UDim2.fromOffset(3,2+(index-1)*19),Size=UDim2.fromOffset(78,19),
                    BackgroundColor3=Color3.fromRGB(32,32,32),BackgroundTransparency=1,AutoButtonColor=false,
                    TextXAlignment=Enum.TextXAlignment.Left,BorderSizePixel=0,FontFace=Library.Font,TextSize=Library.FontSize,
                    TextColor3=control.Mode==mode and UI:GetAccent() or Color3.fromRGB(220,220,220),ZIndex=211,Parent=menu,
                })
                make("UIPadding",{PaddingLeft=UDim.new(0,5),Parent=item})
                UI:BindAccent(item,"TextColor3",function(color)
                    return control.Mode==mode and color or Color3.fromRGB(220,220,220)
                end)
                Library:Connect(item.MouseEnter,function() item.BackgroundTransparency=0 end)
                Library:Connect(item.MouseLeave,function() item.BackgroundTransparency=1 end)
                Library:Connect(item.Activated,function()
                    control:SetMode(mode)
                    menu:Destroy(); if modePopup==menu then modePopup=nil end
                end)
            end
        end)
        control.SetValue=control.Set
        control:SetMode(config.Mode or "Toggle")
        return control
    end
    return label
end
local function handleBindBegan(input, _processed)
    local capture = capturing
    local key = input.KeyCode ~= Enum.KeyCode.Unknown and input.KeyCode or input.UserInputType
    if capture then
        if key==menuKey then
            Library:Notification({Name="RightShift is reserved for the menu"})
            return
        end
        if key==Enum.KeyCode.Escape then
            capture.Control:Set(nil)
        elseif key==Enum.KeyCode.Backspace or key==Enum.KeyCode.Delete then
            capture.Control:Set(nil)
        elseif input.UserInputType==Enum.UserInputType.Keyboard
            or key==Enum.UserInputType.MouseButton1 or key==Enum.UserInputType.MouseButton2
            or key==Enum.UserInputType.MouseButton3 then
            capture.Control:Set(key)
            if input.UserInputType~=Enum.UserInputType.Keyboard then
                captureMouseRelease=key;captureClickUntil=os.clock()+0.35
            end
        else return end
        capturing=nil
        return
    end
    if modePopup then
        local outside=false
        if input.Position and (input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.MouseButton2) then
            local p,s=modePopup.AbsolutePosition,modePopup.AbsoluteSize
            outside=input.Position.X<p.X or input.Position.Y<p.Y or input.Position.X>p.X+s.X or input.Position.Y>p.Y+s.Y
        end
        if key==Enum.KeyCode.Escape or outside then modePopup:Destroy(); modePopup=nil end
        return
    end
    if not focused or UIS:GetFocusedTextBox() or game:GetService("GuiService").MenuIsOpen
        or game:GetService("Players").LocalPlayer:GetAttribute("IsPlayerChatting") then return end
    if UI.IsOpen and input.Position and (key==Enum.UserInputType.MouseButton1 or key==Enum.UserInputType.MouseButton2 or key==Enum.UserInputType.MouseButton3) then
        local p,s=UI.Frame.AbsolutePosition,UI.Frame.AbsoluteSize
        if input.Position.X>=p.X and input.Position.Y>=p.Y and input.Position.X<=p.X+s.X and input.Position.Y<=p.Y+s.Y then return end
    end
    for _, bind in ipairs(bindings) do
        if bind.Mode~="Always" and bind.Key==key and not bind.Held then
            bind.Held=true
            bind:Apply(bind.Mode=="Hold" or not bind:Current())
        end
    end
end
Library:Connect(UIS.InputBegan,handleBindBegan)
Library:Connect(UIS.InputEnded,function(input)
    if input.UserInputType==captureMouseRelease then
        captureMouseRelease=nil;captureClickUntil=os.clock()+0.15
    end
    for _, bind in ipairs(bindings) do
        if input.KeyCode==bind.Key or input.UserInputType==bind.Key then bind:Release() end
    end
end)
local function releaseBindings()
    for _, bind in ipairs(bindings) do bind:Release() end
end
Library:Connect(UIS.WindowFocusReleased,function()
    focused=false
    captureMouseRelease=nil;captureClickUntil=0
    if capturing then capturing.Caption(); capturing=nil end
    if modePopup then modePopup:Destroy(); modePopup=nil end
    releaseBindings()
end)
Library:Connect(UIS.WindowFocused,function() focused=true end)
Library:Connect(UIS.TextBoxFocused,function()
    releaseBindings()
    if capturing then capturing.Caption(); capturing=nil end
end)
Library:Connect(UI.Gui:GetPropertyChangedSignal("Enabled"),function()
    if not UI.Gui.Enabled then
        if modePopup then modePopup:Destroy(); modePopup=nil end
        if capturing then capturing.Caption(); capturing=nil end
    end
end)
for _,button in pairs(UI.Tabs) do
    Library:Connect(button.Activated,function()
        if modePopup then modePopup:Destroy(); modePopup=nil end
        if capturing then capturing.Caption(); capturing=nil end
    end)
end
local configBase=options.ConfigFolder or "Posipaka/UI"
local configRoot=configBase.."/configs"
local autoPath=configBase.."/autoload.txt"
local function ensureConfigFiles()
    assert(type(writefile)=="function" and type(readfile)=="function" and type(listfiles)=="function"
        and type(isfolder)=="function" and type(makefolder)=="function","Executor file API is unavailable")
    local path=""
    for part in configBase:gmatch("[^/]+") do
        path=path=="" and part or path.."/"..part
        if not isfolder(path) then makefolder(path) end
    end
    if not isfolder(configRoot) then makefolder(configRoot) end
end
local function cleanConfigName(name)
    name=tostring(name or ""):match("^%s*(.-)%s*$")
    assert(#name>0 and #name<=64 and not name:find('[/\\:%*%?"<>|%c]')
        and not name:find("%.%.",1) and not name:match("[%. ]$"),"Enter a valid config name")
    return name
end
local function configPath(name) return configRoot.."/"..cleanConfigName(name)..".json" end
function Library:ConfigNames()
    ensureConfigFiles()
    local result={}
    for _,path in ipairs(listfiles(configRoot)) do
        local name=path:match("([^/\\]+)%.json$")
        if name then table.insert(result,name) end
    end
    table.sort(result)
    return result
end
function Library:SaveConfig(name)
    ensureConfigFiles()
    local data={Version=1,Values={},Binds={}}
    for flag in pairs(self.Controls) do
        local value=self.Flags[flag]
        if typeof(value)=="Color3" then value={Type="Color3",R=value.R,G=value.G,B=value.B} end
        data.Values[flag]=value
    end
    for flag,entry in pairs(self.Binds) do
        local bind=entry.Control
        data.Binds[flag]={Mode=bind.Mode,Key=bind.Key and {Type=bind.Key.EnumType==Enum.KeyCode and "KeyCode" or "UserInputType",Name=bind.Key.Name} or nil}
    end
    writefile(configPath(name),game:GetService("HttpService"):JSONEncode(data))
end
function Library:LoadConfig(name)
    ensureConfigFiles()
    local data=game:GetService("HttpService"):JSONDecode(readfile(configPath(name)))
    assert(type(data)=="table" and data.Version==1 and type(data.Values)=="table" and type(data.Binds)=="table","Invalid config file")
    local values,bindValues={},{}
    for flag,value in pairs(data.Values) do
        local entry=self.Controls[flag]
        if entry then
            local options=entry.Options
            if typeof(options.Default)=="Color3" then
                assert(type(value)=="table" and value.Type=="Color3","Invalid color")
                for _,channel in ipairs({"R","G","B"}) do assert(type(value[channel])=="number" and value[channel]>=0 and value[channel]<=1,"Invalid color channel") end
                value=Color3.new(value.R,value.G,value.B)
            elseif options.ValueType=="StringMap" then
                assert(type(value)=="table","Invalid skin selections")
                local clean={}
                for weapon,skin in pairs(value) do
                    assert(type(weapon)=="string" and type(skin)=="string","Invalid skin selection")
                    clean[weapon]=skin
                end
                value=clean
            elseif options.ValueType=="String" then
                assert(type(value)=="string","Invalid text value")
            elseif options.Multi then
                if type(value)=="string" and table.find(options.Items,value) then value={value} end
                assert(type(value)=="table","Invalid multiple selection")
                for _,item in ipairs(value) do assert(table.find(options.Items,item),"Unknown option") end
            elseif options.Items then assert(table.find(options.Items,value),"Unknown option")
            elseif options.Min then
                assert(type(value)=="number" and value==value,"Invalid slider value")
                value=math.clamp(value,options.Min,options.Max)
            else assert(type(value)=="boolean","Invalid checkbox value") end
            table.insert(values,{Entry=entry,Value=value})
        end
    end
    for flag,saved in pairs(data.Binds) do
        local entry=self.Binds[flag]
        if entry then
            assert(type(saved)=="table" and (saved.Mode=="Hold" or saved.Mode=="Always" or saved.Mode=="Toggle"),"Invalid bind mode")
            local key=nil
            if saved.Key then
                assert(type(saved.Key)=="table" and (saved.Key.Type=="KeyCode" or saved.Key.Type=="UserInputType"),"Invalid bind")
                local ok,result=pcall(function() return Enum[saved.Key.Type][saved.Key.Name] end)
                assert(ok and result and result~=menuKey and result~=Enum.KeyCode.Unknown,"Invalid key")
                if saved.Key.Type=="UserInputType" then
                    assert(result==Enum.UserInputType.MouseButton1 or result==Enum.UserInputType.MouseButton2 or result==Enum.UserInputType.MouseButton3,"Invalid mouse bind")
                end
                key=result
            end
            table.insert(bindValues,{Control=entry.Control,Key=key,Mode=saved.Mode})
        end
    end
    for _,entry in pairs(self.Binds) do entry.Control:SetMode("Toggle") end
    for _,item in ipairs(values) do if type(item.Value)~="boolean" then item.Entry.Control:Set(item.Value) end end
    for _,item in ipairs(values) do if type(item.Value)=="boolean" then item.Entry.Control:Set(item.Value) end end
    for _,item in ipairs(bindValues) do item.Control:Set(item.Key); item.Control:SetMode(item.Mode) end
    for _,entry in pairs(self.Binds) do entry.Control.Toggled=entry.Control:Current() end
end
function Library:DeleteConfig(name)
    ensureConfigFiles()
    assert(type(delfile)=="function","Executor delete API is unavailable")
    name=cleanConfigName(name)
    delfile(configPath(name))
    if type(isfile)=="function" and isfile(autoPath) and readfile(autoPath)==name then delfile(autoPath) end
end
function Library:LoadAutoload()
    if type(isfile)~="function" or not isfile(autoPath) then return end
    local ok=pcall(function() self:LoadConfig(readfile(autoPath)) end)
    if not ok then self:Notification({Name="Could not load the startup config"}) end
end
local function createConfigUI(settings,listSection)
    local content=settings.Content
    content.Count=content.Count+1
    local nameBox=make("TextBox",{
        Name="ConfigName",Text="",PlaceholderText="Config name",ClearTextOnFocus=false,
        Size=UDim2.new(1,0,0,28),LayoutOrder=content.Count,BackgroundColor3=Color3.fromRGB(30,30,30),
        TextColor3=Color3.fromRGB(220,220,220),PlaceholderColor3=Color3.fromRGB(120,120,120),
        FontFace=Library.Font,TextSize=Library.FontSize,BorderSizePixel=1,BorderMode=Enum.BorderMode.Inset,BorderColor3=Color3.fromRGB(55,55,55),ZIndex=10,Parent=content.Body,
    })
    local list=make("ScrollingFrame",{
        Name="SavedConfigs",Size=UDim2.new(1,0,0,220),BackgroundTransparency=1,BorderSizePixel=0,
        CanvasSize=UDim2.fromOffset(0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,
        ScrollBarThickness=0,ScrollingDirection=Enum.ScrollingDirection.Y,ZIndex=10,Parent=listSection.Content.Body,
    })
    make("UIListLayout",{Padding=UDim.new(0,4),SortOrder=Enum.SortOrder.LayoutOrder,Parent=list})
    local refresh
    local function action(callback)
        local ok,err=pcall(callback)
        if not ok then Library:Notification({Name=tostring(err):gsub("^.-:%d+: ","")}) end
    end
    refresh=function()
        for _,child in ipairs(list:GetChildren()) do if child:IsA("TextButton") or child:IsA("TextLabel") then child:Destroy() end end
        local names=Library:ConfigNames()
        for index,name in ipairs(names) do
            local item=make("TextButton",{
                Name="Config",Text=name,LayoutOrder=index,Size=UDim2.new(1,0,0,28),
                BackgroundColor3=Color3.fromRGB(32,32,32),TextColor3=Color3.fromRGB(220,220,220),
                FontFace=Library.Font,TextSize=Library.FontSize,BorderSizePixel=0,ZIndex=11,Parent=list,
            })
            UI:BindAccent(item,"TextColor3",function(color)
                return item:GetAttribute("Selected")==true and color or Color3.fromRGB(220,220,220)
            end)
            Library:Connect(item.Activated,function()
                nameBox.Text=name
                for _,other in ipairs(list:GetChildren()) do
                    if other:IsA("TextButton") then other:SetAttribute("Selected",false);other.TextColor3=Color3.fromRGB(220,220,220) end
                end
                item:SetAttribute("Selected",true)
                item.TextColor3=UI:GetAccent()
            end)
        end
        if #names==0 then make("TextLabel",{
            Text="No saved configs",Size=UDim2.new(1,0,0,28),BackgroundTransparency=1,
            FontFace=Library.Font,TextSize=Library.FontSize,TextColor3=Color3.fromRGB(120,120,120),ZIndex=11,Parent=list,
        }) end
    end
    settings:Button({Name="Save config",Callback=function() action(function()
        local name=cleanConfigName(nameBox.Text); Library:SaveConfig(name); refresh(); Library:Notification({Name="Saved: "..name})
    end) end})
    settings:Button({Name="Load config",Callback=function() action(function()
        assert(Library.RuntimeReady,"Script is still initializing")
        local name=cleanConfigName(nameBox.Text); Library:LoadConfig(name); Library:Notification({Name="Loaded: "..name})
    end) end})
    settings:Button({Name="Delete config",Callback=function() action(function()
        local name=cleanConfigName(nameBox.Text); Library:DeleteConfig(name); nameBox.Text=""; refresh(); Library:Notification({Name="Deleted: "..name})
    end) end})
    settings:Button({Name="Refresh list",Callback=function() action(refresh) end})
    settings:Button({Name="Set startup config",Callback=function() action(function()
        ensureConfigFiles(); local name=cleanConfigName(nameBox.Text); readfile(configPath(name)); writefile(autoPath,name)
        Library:Notification({Name="Startup config: "..name})
    end) end})
    settings:Button({Name="Clear startup config",Callback=function() action(function()
        if type(isfile)=="function" and isfile(autoPath) then assert(type(delfile)=="function"); delfile(autoPath) end
        Library:Notification({Name="Startup config cleared"})
    end) end})
    pcall(refresh)
    content.Fit(); listSection.Content.Fit()
end

function Library:Window()
    function UI:Page(options)
        local name=tostring(options.Name):lower()
        tabs[name]=name
        UI:AddTab(name)
        UI.TabLabels[name].Text=options.Name
        if pages[name] then return pages[name] end
        local scrolling = make("ScrollingFrame", {
            Name="Sections", Size=UDim2.fromScale(1,1), BackgroundTransparency=1, BorderSizePixel=0,
            CanvasSize=UDim2.fromOffset(0,0), AutomaticCanvasSize=Enum.AutomaticSize.Y,
            ScrollingDirection=Enum.ScrollingDirection.Y,ScrollingEnabled=true,
            ElasticBehavior=Enum.ElasticBehavior.Never,
            ScrollBarThickness=0, ZIndex=6, Parent=self.Pages[name],
        })
        local columns = {}
        Library:Connect(scrolling:GetPropertyChangedSignal("CanvasPosition"),function()
            UI:ClosePopups(true)
            if modePopup then modePopup:Destroy(); modePopup=nil end
        end)
        local columnLayout=make("UIListLayout", {FillDirection=Enum.FillDirection.Horizontal,SortOrder=Enum.SortOrder.LayoutOrder,
            VerticalAlignment=Enum.VerticalAlignment.Top,Padding=UDim.new(0,12),Parent=scrolling})
        make("UIPadding",{PaddingTop=UDim.new(0,10),PaddingLeft=UDim.new(0,8),PaddingRight=UDim.new(0,8),PaddingBottom=UDim.new(0,10),Parent=scrolling})
        for side=1,2 do
            columns[side] = make("Frame", {
                Name="Column"..side, LayoutOrder=side, Size=UDim2.fromOffset(236,0),
                AutomaticSize=Enum.AutomaticSize.Y, BackgroundTransparency=1, ZIndex=6, Parent=scrolling,
            })
            make("UIListLayout",{Padding=UDim.new(0,12),SortOrder=Enum.SortOrder.LayoutOrder,Parent=columns[side]})
        end
        local page = {Count=0,Sections={}}
        local function fitColumns()
            local width=scrolling.AbsoluteSize.X
            local stacked=width<480
            columnLayout.FillDirection=stacked and Enum.FillDirection.Vertical or Enum.FillDirection.Horizontal
            local available=math.max(1,math.floor(width)-16)
            local columnWidth=stacked and available or math.max(1,math.floor((available-12)/2))
            for _,column in ipairs(columns) do
                column.Size=UDim2.fromOffset(columnWidth,0)
            end
            for _,section in pairs(page.Sections) do section.Content.Fit() end
        end
        Library:Connect(scrolling:GetPropertyChangedSignal("AbsoluteSize"),fitColumns)
        fitColumns()
        function page:Section(config)
            if self.Sections[config.Name] then return self.Sections[config.Name] end
            self.Count = self.Count+1
            local content = UI:Content(name,config.Name)
            content.Frame.Parent = columns[config.Side or 1]
            content.Frame.LayoutOrder = self.Count
            content.Fit()
            local section=setmetatable({Content=content},Section)
            self.Sections[config.Name]=section
            return section
        end
        pages[name] = page
        return page
    end
    function UI:InitWindow()
        if options.Configs==true and not self.ConfigUIReady then
            local settings=self:Page({Name="settings"})
            createConfigUI(settings:Section({Name="configuration",Side=1}),settings:Section({Name="saved configs",Side=2}))
            self.ConfigUIReady=true
        end
        local selected=options.DefaultTab and tostring(options.DefaultTab):lower() or self.SelectedTab
        if selected and self.Pages[selected] then self:SelectTab(selected,true) end
        if options.Autoload==true then Library:LoadAutoload() end
    end
    return UI
end
Library:Connect(UI.Gui.Destroying,function()
    if alive then Library:Exit() end
end)
    local window=Library:Window()
    window.Flags=Library.Flags
    window.Controls=Library.Controls
    window.Binds=Library.Binds
    window.Library=Library
    window.Font=Library.Font
    window.FontSize=Library.FontSize
    window.Destroy=function() Library:Exit() end
    window.Exit=window.Destroy
    window.Tab=window.Page
    window.CreateTab=window.Page
    window.SaveConfig=function(_,name) return Library:SaveConfig(name) end
    window.LoadConfig=function(_,name) return Library:LoadConfig(name) end
    window.DeleteConfig=function(_,name) return Library:DeleteConfig(name) end
    window.ConfigNames=function() return Library:ConfigNames() end
    window.LoadAutoload=function() return Library:LoadAutoload() end
    local sequence=0
    local function prepare(config)
        config=config or {}
        sequence+=1
        config.Flag=config.Flag or "control_"..sequence
        return config
    end
    local basicToggle=Section.Toggle
    local function enhancedToggle(self,config)
        config=prepare(config)
        local target=basicToggle(self,config)
        local owner=self
        target.Flag=config.Flag
        target.Colors=target.Colors or {}
        local function fitInline()
            local bind=Library.Binds[config.BindFlag or config.Flag.."_bind"]
            local width=bind and bind.Control.Button.AbsoluteSize.X or 0
            if width==0 and bind then width=24 end
            local occupied=bind and width+26 or 22
            for i,picker in ipairs(target.Colors) do
                picker.Button.Position=UDim2.new(1,-occupied-(i-1)*30,.5,0)
            end
            target.Label.Size=UDim2.new(1,-(occupied+#target.Colors*30+8),0,14)
        end
        function target:Colorpicker(color)
            color=prepare(color)
            color.Default=color.Default or Color3.new(1,1,1)
            local picker=owner:Label({Name=config.Name}):Colorpicker(color)
            local previous=picker.Row
            picker.Button.Parent=target.Row
            picker.Button.Size=UDim2.fromOffset(24,14)
            picker.Row=target.Row;picker.Label=target.Label
            target.Colors[#target.Colors+1]=picker
            previous:Destroy()
            fitInline();owner.Content.Fit()
            return picker
        end
        target.ColorPicker=target.Colorpicker
        function target:Keybind(bind)
            bind=bind or {}
            bind.Flag=bind.Flag or config.BindFlag or config.Flag.."_bind"
            bind.GetState=bind.GetState or function() return target.Value end
            local callback=bind.Callback
            bind.Callback=function(value)
                target:SetValue(value)
                if callback then callback(value) end
            end
            local control=owner:Label({Name=config.Name,Target=target}):Keybind(bind)
            Library:Connect(control.Button:GetPropertyChangedSignal("AbsoluteSize"),fitInline)
            fitInline()
            return control
        end
        local initial=Library.Binds[config.BindFlag or config.Flag.."_bind"]
        if initial then Library:Connect(initial.Control.Button:GetPropertyChangedSignal("AbsoluteSize"),fitInline) end
        if config.Color then target:Colorpicker(config.Color) end
        return target
    end
    Section.Toggle=enhancedToggle
    Section.Checkbox=enhancedToggle
    for _,method in ipairs({"Slider","Dropdown"}) do
        local original=Section[method]
        Section[method]=function(self,config) return original(self,prepare(config)) end
    end
    function Section:Colorpicker(config)
        config=prepare(config);config.Default=config.Default or Color3.new(1,1,1)
        return self:Label({Name=config.Name or "color"}):Colorpicker(config)
    end
    Section.ColorPicker=Section.Colorpicker
    function Section:Keybind(config)
        config=prepare(config)
        local host=UI:Checkbox(config.Name or "keybind",self.Content,false,function() end)
        host.Box.Visible=false
        host.Row.Active=false
        local bind=self:Label({Name=config.Name or "keybind",Target=host}):Keybind(config)
        return bind
    end
    function Section:Settings(config)
        config=config or {}
        local parent=self.Content
        parent.Count+=1
        local frame=make("Frame",{
            Name=config.Name or "Settings",LayoutOrder=parent.Count,Size=UDim2.new(1,0,0,32),
            BackgroundColor3=Color3.fromRGB(29,29,29),BorderSizePixel=1,BorderMode=Enum.BorderMode.Inset,
            BorderColor3=Color3.fromRGB(42,42,42),ZIndex=9,Parent=parent.Body,
        })
        local body=make("Frame",{Name="Body",Position=UDim2.fromOffset(8,8),Size=UDim2.new(1,-16,1,-16),
            BackgroundTransparency=1,BorderSizePixel=0,ZIndex=9,Parent=frame})
        local layout=make("UIListLayout",{Padding=UDim.new(0,6),SortOrder=Enum.SortOrder.LayoutOrder,Parent=body})
        local nested={Frame=frame,Body=body,Window=parent.Window,TabName=parent.TabName,
            Count=0,VisualCheckboxes=parent.VisualCheckboxes}
        nested.Fit=function()
            frame.Size=UDim2.new(1,0,0,math.max(32,math.ceil(layout.AbsoluteContentSize.Y)+16))
            parent.Fit()
        end
        local section=setmetatable({Content=nested},Section)
        Library:Connect(layout:GetPropertyChangedSignal("AbsoluteContentSize"),nested.Fit)
        if config.Title then section:Text({Text=config.Title}) end
        nested.Fit()
        return section
    end
    Section.SettingsPanel=Section.Settings
    Section.Panel=Section.Settings
    function Section:Text(config)
        if type(config)=="string" then config={Text=config} end
        config=config or {}
        self.Content.Count+=1
        local label=make("TextLabel",{Name="Text",Text=config.Text or "",BackgroundTransparency=1,
            LayoutOrder=self.Content.Count,Size=UDim2.new(1,0,0,config.Height or 16),TextXAlignment=Enum.TextXAlignment.Left,
            TextColor3=config.Color or Color3.fromRGB(190,190,190),FontFace=Library.Font,TextSize=Library.FontSize,
            BorderSizePixel=0,TextWrapped=config.Wrapped==true,ZIndex=10,Parent=self.Content.Body})
        self.Content.Fit()
        return label
    end
    function Section:Textbox(config)
        config=prepare(config);config.Default=config.Default or "";config.ValueType="String"
        self.Content.Count+=1
        local box=make("TextBox",{Name="Textbox",Text=config.Default,PlaceholderText=config.Placeholder or config.Name or "",
            ClearTextOnFocus=false,Size=UDim2.new(1,0,0,28),LayoutOrder=self.Content.Count,
            BackgroundColor3=Color3.fromRGB(30,30,30),TextColor3=Color3.fromRGB(220,220,220),
            PlaceholderColor3=Color3.fromRGB(120,120,120),FontFace=Library.Font,TextSize=Library.FontSize,
            BorderSizePixel=1,BorderMode=Enum.BorderMode.Inset,BorderColor3=Color3.fromRGB(55,55,55),
            TextXAlignment=Enum.TextXAlignment.Left,ZIndex=10,Parent=self.Content.Body})
        make("UIPadding",{PaddingLeft=UDim.new(0,6),PaddingRight=UDim.new(0,6),Parent=box})
        local control={Value=config.Default,Box=box}
        function control:SetValue(value)
            self.Value=tostring(value or "");box.Text=self.Value;publish(config,self.Value)
        end
        control.Set=control.SetValue
        Library.Flags[config.Flag]=config.Default
        Library:Connect(box.FocusLost,function() control:SetValue(box.Text) end)
        self.Content.Fit()
        return register(config,control)
    end
    Section.TextBox=Section.Textbox
    function Section:List(config)
        config=prepare(config);config.ValueType="String"
        self.Content.Count+=1
        local frame=make("ScrollingFrame",{Name="SelectionList",LayoutOrder=self.Content.Count,
            Size=UDim2.new(1,0,0,config.Height or 180),CanvasSize=UDim2.fromOffset(0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,
            ScrollBarThickness=0,ScrollingDirection=Enum.ScrollingDirection.Y,ElasticBehavior=Enum.ElasticBehavior.Never,
            BackgroundColor3=Color3.fromRGB(24,24,24),BorderSizePixel=1,BorderMode=Enum.BorderMode.Inset,
            BorderColor3=Color3.fromRGB(42,42,42),ZIndex=10,Parent=self.Content.Body})
        make("UIPadding",{PaddingTop=UDim.new(0,5),PaddingBottom=UDim.new(0,5),PaddingLeft=UDim.new(0,5),PaddingRight=UDim.new(0,5),Parent=frame})
        make("UIListLayout",{Padding=UDim.new(0,4),SortOrder=Enum.SortOrder.LayoutOrder,Parent=frame})
        local control={Value=tostring(config.Default or ""),Items={},Rows={},Frame=frame}
        function control:SetValue(value)
            value=tostring(value or "")
            self.Value=value;publish(config,value)
            for key,button in pairs(self.Rows) do
                UI.Animate(button,{BackgroundColor3=key==value and UI:AccentShade() or Color3.fromRGB(32,32,32)},.12)
            end
        end
        control.Set=control.SetValue
        function control:SetItems(items)
            for _,button in pairs(self.Rows) do button:Destroy() end
            table.clear(self.Rows);self.Items=items or {}
            for i,item in ipairs(self.Items) do
                local key=tostring(type(item)=="table" and item.Value or item)
                local title=tostring(type(item)=="table" and (item.Name or item.Value) or item)
                local decorated=type(item)=="table" and (item.Image or item.Description)
                local button=make("TextButton",{Name="Item",Text=decorated and "" or title,LayoutOrder=i,Size=UDim2.new(1,0,0,config.RowHeight or (decorated and 48 or 30)),
                    BackgroundColor3=key==self.Value and UI:AccentShade() or Color3.fromRGB(32,32,32),
                    AutoButtonColor=false,BorderSizePixel=0,TextColor3=Color3.fromRGB(220,220,220),
                    FontFace=Library.Font,TextSize=Library.FontSize,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=11,Parent=frame})
                make("UIPadding",{PaddingLeft=UDim.new(0,8),Parent=button})
                if decorated then
                    local left=item.Image and 54 or 4
                    if item.Image then
                        make("ImageLabel",{Name="Icon",Image=tostring(item.Image),BackgroundTransparency=1,BorderSizePixel=0,
                            Position=UDim2.fromOffset(0,4),Size=UDim2.fromOffset(44,40),ScaleType=Enum.ScaleType.Fit,ZIndex=12,Parent=button})
                    end
                    make("TextLabel",{Name="Name",Text=title,BackgroundTransparency=1,BorderSizePixel=0,
                        Position=UDim2.fromOffset(left,7),Size=UDim2.new(1,-left-6,0,16),TextXAlignment=Enum.TextXAlignment.Left,
                        FontFace=Library.Font,TextSize=Library.FontSize,TextColor3=Color3.fromRGB(220,220,220),ZIndex=12,Parent=button})
                    if item.Description then
                        make("TextLabel",{Name="Description",Text=tostring(item.Description),BackgroundTransparency=1,BorderSizePixel=0,
                            Position=UDim2.fromOffset(left,25),Size=UDim2.new(1,-left-6,0,14),TextXAlignment=Enum.TextXAlignment.Left,
                            FontFace=Library.Font,TextSize=10,TextColor3=Color3.fromRGB(130,130,130),ZIndex=12,Parent=button})
                    end
                end
                self.Rows[key]=button
                UI:BindAccent(button,"BackgroundColor3",function()
                    return key==self.Value and UI:AccentShade() or Color3.fromRGB(32,32,32)
                end)
                Library:Connect(button.Activated,function() if UI.IsOpen then self:SetValue(key) end end)
            end
        end
        Library.Flags[config.Flag]=control.Value
        control:SetItems(config.Items)
        self.Content.Fit()
        return register(config,control)
    end
    local createPage=window.Page
    function window:Page(config)
        if type(config)=="string" then config={Name=config} end
        local page=createPage(self,config)
        page.Panel=page.Section;page.Content=page.Section
        return page
    end
    window.Tab=window.Page;window.CreateTab=window.Page
    function window:Configs(config)
        config=config or {}
        local page=self:Page({Name=config.Tab or "settings"})
        if self.ConfigUIReady then return page end
        createConfigUI(page:Section({Name=config.Name or "configuration",Side=1}),page:Section({Name="saved configs",Side=2}))
        self.ConfigUIReady=true
        return page
    end
    for _,name in ipairs(options.Tabs or {}) do window:Page({Name=name}) end
    window:InitWindow()
    return window

end
Posipaka.Window=Posipaka.CreateWindow
function Posipaka:Compatibility(options)
    options=options or {}
    if options.BindByDefault==nil then options.BindByDefault=true end
    local window=self:CreateWindow(options)
    return window.Library
end
return Posipaka
