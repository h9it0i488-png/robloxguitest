local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

local Library = {}
Library.Version = "1.0"

local BASE_COLORS = {
	Background = Color3.fromRGB(20, 20, 25), Content = Color3.fromRGB(28, 28, 34),
	Card = Color3.fromRGB(40, 40, 49), Accent = Color3.fromRGB(233, 64, 122),
	TextDim = Color3.fromRGB(120, 120, 132), Text = Color3.fromRGB(222, 222, 228),
	Stroke = Color3.fromRGB(48, 48, 58), Mute = Color3.fromRGB(58, 58, 68), Health = Color3.fromRGB(60, 200, 110),
}
local BASE_GRADIENT = ColorSequence.new({
	ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 111, 165)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(233, 64, 122)),
	ColorSequenceKeypoint.new(1.0, Color3.fromRGB(196, 38, 108)),
})
local FONT_FACE
do
	local ok, f = pcall(function() return Font.fromName("Verdana", Enum.FontWeight.Bold) end)
	FONT_FACE = (ok and f) and f or Font.fromEnum(Enum.Font.GothamBold)
end

local function corner(inst, r) local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r); c.Parent = inst; return c end
local function stroke(inst, col, thick, trans) local s = Instance.new("UIStroke"); s.Color = col; s.Thickness = thick or 1; s.Transparency = trans or 0; s.Parent = inst; return s end
local function bindDrag(frame, onMove)
	local dragging = false
	local function update(input)
		local abs, size = frame.AbsolutePosition, frame.AbsoluteSize
		if size.X <= 0 or size.Y <= 0 then return end
		onMove(math.clamp((input.Position.X - abs.X) / size.X, 0, 1), math.clamp((input.Position.Y - abs.Y) / size.Y, 0, 1))
	end
	frame.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = true; update(i) end end)
	frame.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end end)
	UIS.InputChanged:Connect(function(i) if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then update(i) end end)
end
local function makeChevron(parent, col)
	local a = Instance.new("Frame"); a.AnchorPoint = Vector2.new(0.5, 0.5); a.Size = UDim2.fromOffset(14, 14); a.BackgroundTransparency = 1; a.Parent = parent
	local function arm(rot, dx) local l = Instance.new("Frame"); l.AnchorPoint = Vector2.new(0.5, 0.5); l.Size = UDim2.fromOffset(8, 2); l.Position = UDim2.new(0.5, dx, 0.5, 1); l.BackgroundColor3 = col; l.BorderSizePixel = 0; l.Rotation = rot; corner(l, 1).CornerRadius = UDim.new(1, 0); l.Parent = a end
	arm(45, -3); arm(-45, 3); return a
end

function Library.CreateWindow(cfg)
	cfg = cfg or {}
	local C = {}; for k, v in pairs(BASE_COLORS) do C[k] = v end
	if cfg.Theme then for k, v in pairs(cfg.Theme) do C[k] = v end end
	local GRAD = cfg.AccentGradient or BASE_GRADIENT
	local START_W = (cfg.Size and cfg.Size.X) or 620
	local START_H = (cfg.Size and cfg.Size.Y) or 430
	local PREVIEW_W = cfg.PreviewWidth or 240
	local WIN_TR, CON_TR = cfg.WindowTransparency or 0.10, cfg.ContentTransparency or 0.08
	local MIN_SIZE, MAX_SIZE = Vector2.new(480, 320), Vector2.new(1000, 760)

	local S = { closeActivePopup = nil, currentTab = nil, previewEnabled = true, espPreview = nil, espTab = nil, pages = {}, tabButtons = {}, visible = true }
	local function card(inst) inst.BackgroundColor3 = C.Card; inst.BorderSizePixel = 0; corner(inst, 8); stroke(inst, C.Stroke, 1, 0.1) end

	local gui = Instance.new("ScreenGui")
	gui.Name = cfg.GuiName or "PosipakaUI"; gui.ResetOnSpawn = false; gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling; gui.IgnoreGuiInset = true
	gui.Parent = (cfg.Parent) or player:WaitForChild("PlayerGui")

	local main = Instance.new("Frame")
	main.Name = "Main"; main.Size = UDim2.fromOffset(START_W, START_H); main.Position = UDim2.new(0.5, -START_W/2, 0.5, -START_H/2)
	main.BackgroundColor3 = C.Background; main.BackgroundTransparency = WIN_TR; main.BorderSizePixel = 0; main.ZIndex = 1; main.Parent = gui
	corner(main, 12); stroke(main, C.Stroke, 1, 0.2)
	local shadow = Instance.new("ImageLabel")
	shadow.AnchorPoint = Vector2.new(0.5, 0.5); shadow.Position = UDim2.fromScale(0.5, 0.5); shadow.Size = UDim2.new(1, 40, 1, 40); shadow.BackgroundTransparency = 1
	shadow.Image = "rbxassetid://6014261993"; shadow.ImageColor3 = Color3.fromRGB(0, 0, 0); shadow.ImageTransparency = 0.55; shadow.ScaleType = Enum.ScaleType.Slice; shadow.SliceCenter = Rect.new(49, 49, 450, 450); shadow.ZIndex = 0; shadow.Parent = main

	local header = Instance.new("Frame"); header.Size = UDim2.new(1, 0, 0, 52); header.BackgroundTransparency = 1; header.Parent = main
	local divider = Instance.new("Frame"); divider.Position = UDim2.new(0, 0, 0, 52); divider.Size = UDim2.new(1, 0, 0, 1); divider.BackgroundColor3 = C.Stroke; divider.BackgroundTransparency = 0.2; divider.BorderSizePixel = 0; divider.Parent = main
	local logo = Instance.new("ImageLabel"); logo.AnchorPoint = Vector2.new(0, 0.5); logo.Position = UDim2.new(0, 14, 0.5, 0); logo.Size = UDim2.fromOffset(28, 28); logo.BackgroundTransparency = 1; logo.Image = cfg.Logo or ""; logo.Parent = header
	if cfg.Logo then task.spawn(function() while logo.Parent do local u = TweenService:Create(logo, TweenInfo.new(1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Position = UDim2.new(0, 14, 0.5, -3) }); u:Play(); u.Completed:Wait(); if not logo.Parent then break end local d = TweenService:Create(logo, TweenInfo.new(1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Position = UDim2.new(0, 14, 0.5, 3) }); d:Play(); d.Completed:Wait() end end) end
	local title = Instance.new("TextLabel"); title.AnchorPoint = Vector2.new(0, 0.5); title.Position = UDim2.new(0, cfg.Logo and 50 or 16, 0.5, 0); title.Size = UDim2.fromOffset(200, 22); title.BackgroundTransparency = 1; title.Text = cfg.Name or "posipaka"; title.FontFace = FONT_FACE; title.TextSize = 17; title.TextColor3 = C.Text; title.TextXAlignment = Enum.TextXAlignment.Left; title.Parent = header
	local pills = Instance.new("Frame"); pills.AnchorPoint = Vector2.new(1, 0.5); pills.Position = UDim2.new(1, -12, 0.5, 0); pills.Size = UDim2.new(0.7, 0, 0, 34); pills.BackgroundTransparency = 1; pills.Parent = header
	local pl = Instance.new("UIListLayout"); pl.FillDirection = Enum.FillDirection.Horizontal; pl.VerticalAlignment = Enum.VerticalAlignment.Center; pl.HorizontalAlignment = Enum.HorizontalAlignment.Right; pl.Padding = UDim.new(0, 8); pl.SortOrder = Enum.SortOrder.LayoutOrder; pl.Parent = pills
	local content = Instance.new("Frame"); content.Position = UDim2.new(0, 12, 0, 62); content.Size = UDim2.new(1, -24, 1, -74); content.BackgroundColor3 = C.Content; content.BackgroundTransparency = CON_TR; content.BorderSizePixel = 0; content.ClipsDescendants = true; content.Parent = main
	corner(content, 10); stroke(content, C.Stroke, 1, 0.35)

	local function updatePreviewVisible() if S.espPreview then S.espPreview.Visible = S.visible and S.previewEnabled and (S.espTab == nil or S.currentTab == S.espTab) end end

	--// ==== фабрики компонентов ====
	local function attachCheckbox(row, default, onToggle)
		local box = Instance.new("TextButton"); box.AnchorPoint = Vector2.new(0, 0.5); box.Position = UDim2.new(0, 0, 0.5, 0); box.Size = UDim2.fromOffset(20, 20)
		box.BackgroundColor3 = default and Color3.fromRGB(255,255,255) or C.Content; box.AutoButtonColor = false; box.Text = ""; box.Parent = row; corner(box, 5)
		local grad = Instance.new("UIGradient"); grad.Color = GRAD; grad.Rotation = 45; grad.Enabled = default; grad.Parent = box
		local bs = stroke(box, default and C.Accent or C.Stroke, 1.5, 0)
		local check = Instance.new("TextLabel"); check.Size = UDim2.new(1, 0, 1, 0); check.BackgroundTransparency = 1; check.Text = "✓"; check.FontFace = FONT_FACE; check.TextSize = 13; check.TextColor3 = Color3.fromRGB(255,255,255); check.Parent = box
		local cs = Instance.new("UIScale"); cs.Scale = default and 1 or 0; cs.Parent = check
		local state = default
		local function set(v, fire)
			state = v; grad.Enabled = v
			local ti = TweenInfo.new(0.16, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
			TweenService:Create(box, ti, { BackgroundColor3 = v and Color3.fromRGB(255,255,255) or C.Content }):Play()
			TweenService:Create(bs, ti, { Color = v and C.Accent or C.Stroke }):Play()
			TweenService:Create(cs, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = v and 1 or 0 }):Play()
			if fire and onToggle then onToggle(v) end
		end
		box.MouseButton1Click:Connect(function() set(not state, true) end)
		return set
	end

	local function makeCollapsible(parent, titleText, order, opts)
		opts = opts or {}
		local group = Instance.new("Frame"); group.AutomaticSize = Enum.AutomaticSize.Y; group.Size = UDim2.new(1, 0, 0, 0); group.BackgroundTransparency = 1; group.LayoutOrder = order; group.Parent = parent
		local gl = Instance.new("UIListLayout"); gl.SortOrder = Enum.SortOrder.LayoutOrder; gl.Padding = UDim.new(0, 4); gl.Parent = group
		local hdr = Instance.new("TextButton"); hdr.Size = UDim2.new(1, 0, 0, opts.headerHeight or 34); hdr.BackgroundColor3 = C.Card; hdr.BackgroundTransparency = opts.headerTransparency or 0.25; hdr.AutoButtonColor = false; hdr.Text = ""; hdr.LayoutOrder = 0; hdr.Parent = group
		corner(hdr, 6); stroke(hdr, C.Stroke, 1, 0.5)
		local stripe = Instance.new("Frame"); stripe.AnchorPoint = Vector2.new(0, 0.5); stripe.Position = UDim2.new(0, 0, 0.5, 0); stripe.Size = UDim2.new(0, 3, 0.55, 0); stripe.BackgroundColor3 = C.Accent; stripe.BorderSizePixel = 0; stripe.Parent = hdr
		corner(stripe, 2).CornerRadius = UDim.new(1, 0); local sg = Instance.new("UIGradient"); sg.Color = GRAD; sg.Rotation = 90; sg.Parent = stripe
		local tl = Instance.new("TextLabel"); tl.Position = UDim2.fromOffset(14, 0); tl.Size = UDim2.new(1, -40, 1, 0); tl.BackgroundTransparency = 1; tl.Text = titleText; tl.FontFace = FONT_FACE; tl.TextSize = opts.titleSize or 14; tl.TextColor3 = opts.titleColor or C.Text; tl.TextXAlignment = Enum.TextXAlignment.Left; tl.Parent = hdr
		local chevron = makeChevron(hdr, C.TextDim); chevron.Position = UDim2.new(1, -12, 0.5, 0); chevron.Rotation = 180
		local body = Instance.new("Frame"); body.AutomaticSize = Enum.AutomaticSize.Y; body.Size = UDim2.new(1, 0, 0, 0); body.BackgroundTransparency = 1; body.ClipsDescendants = true; body.LayoutOrder = 1; body.Parent = group
		local bp = Instance.new("UIPadding"); bp.PaddingTop = UDim.new(0, 6); bp.PaddingBottom = UDim.new(0, 6); bp.PaddingLeft = UDim.new(0, opts.bodyIndent or 6); bp.PaddingRight = UDim.new(0, 4); bp.Parent = body
		local bl = Instance.new("UIListLayout"); bl.SortOrder = Enum.SortOrder.LayoutOrder; bl.Padding = UDim.new(0, opts.gap or 3); bl.Parent = body
		local open = true
		local function fh() return bl.AbsoluteContentSize.Y + 12 end
		local function setOpen(o)
			if o == open then return end
			open = o; local ti = TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out); TweenService:Create(chevron, ti, { Rotation = o and 180 or 0 }):Play()
			if o then body.Visible = true; body.AutomaticSize = Enum.AutomaticSize.None; local t = fh(); body.Size = UDim2.new(1, 0, 0, 0); local tw = TweenService:Create(body, ti, { Size = UDim2.new(1, 0, 0, t) }); tw:Play(); tw.Completed:Connect(function() if open then body.AutomaticSize = Enum.AutomaticSize.Y end end)
			else body.AutomaticSize = Enum.AutomaticSize.None; body.Size = UDim2.new(1, 0, 0, fh()); local tw = TweenService:Create(body, ti, { Size = UDim2.new(1, 0, 0, 0) }); tw:Play(); tw.Completed:Connect(function() if not open then body.Visible = false end end) end
		end
		hdr.MouseButton1Click:Connect(function() setOpen(not open) end)
		return body
	end

	local function makeToggle(parent, order, o)
		local row = Instance.new("Frame"); row.Size = UDim2.new(1, 0, 0, 32); row.BackgroundTransparency = 1; row.LayoutOrder = order; row.Parent = parent
		local set = attachCheckbox(row, o.Default, o.Callback)
		local lbl = Instance.new("TextLabel"); lbl.Position = UDim2.fromOffset(28, 0); lbl.Size = UDim2.new(1, -28, 1, 0); lbl.BackgroundTransparency = 1; lbl.Text = o.Name; lbl.FontFace = FONT_FACE; lbl.TextSize = 14; lbl.TextColor3 = o.Dim and C.TextDim or C.Text; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = row
		return { Set = function(_, v) set(v, true) end }
	end

	local function makeSlider(parent, order, o)
		local row = Instance.new("Frame"); row.Size = UDim2.new(1, 0, 0, 32); row.BackgroundTransparency = 1; row.LayoutOrder = order; row.Parent = parent
		local left = Instance.new("Frame"); left.Size = UDim2.new(0.5, -8, 1, 0); left.BackgroundTransparency = 1; left.Parent = row
		local lh = Instance.new("UIListLayout"); lh.FillDirection = Enum.FillDirection.Horizontal; lh.VerticalAlignment = Enum.VerticalAlignment.Center; lh.Padding = UDim.new(0, 8); lh.SortOrder = Enum.SortOrder.LayoutOrder; lh.Parent = left
		local nL = Instance.new("TextLabel"); nL.AutomaticSize = Enum.AutomaticSize.X; nL.Size = UDim2.new(0, 0, 1, 0); nL.BackgroundTransparency = 1; nL.Text = o.Name; nL.FontFace = FONT_FACE; nL.TextSize = 14; nL.TextColor3 = C.Text; nL.TextXAlignment = Enum.TextXAlignment.Left; nL.LayoutOrder = 0; nL.Parent = left
		local vL = Instance.new("TextLabel"); vL.AutomaticSize = Enum.AutomaticSize.X; vL.Size = UDim2.new(0, 0, 1, 0); vL.BackgroundTransparency = 1; vL.FontFace = FONT_FACE; vL.TextSize = 14; vL.TextColor3 = C.Accent; vL.TextXAlignment = Enum.TextXAlignment.Left; vL.LayoutOrder = 1; vL.Parent = left
		local track = Instance.new("Frame"); track.AnchorPoint = Vector2.new(1, 0.5); track.Position = UDim2.new(1, -2, 0.5, 0); track.Size = UDim2.new(0.42, 0, 0, 6); track.BackgroundColor3 = C.Mute; track.BorderSizePixel = 0; track.Active = true; track.Parent = row; corner(track, 3).CornerRadius = UDim.new(1, 0)
		local fill = Instance.new("Frame"); fill.Size = UDim2.new(0, 0, 1, 0); fill.BackgroundColor3 = C.Accent; fill.BorderSizePixel = 0; fill.Parent = track; corner(fill, 3).CornerRadius = UDim.new(1, 0); local fg = Instance.new("UIGradient"); fg.Color = GRAD; fg.Parent = fill
		local function set(pct, fire) pct = math.clamp(pct, 0, 1); local val = o.Min + (o.Max - o.Min) * pct; fill.Size = UDim2.new(pct, 0, 1, 0); vL.Text = tostring(math.floor(val + 0.5)) .. (o.Suffix or ""); if fire and o.Callback then o.Callback(val) end end
		set((o.Default - o.Min) / (o.Max - o.Min), false); bindDrag(track, function(x) set(x, true) end)
		return { Set = function(_, v) set((v - o.Min) / (o.Max - o.Min), true) end }
	end

	local function makeDropdown(parent, order, o)
		local row = Instance.new("Frame"); row.Size = UDim2.new(1, 0, 0, 32); row.BackgroundTransparency = 1; row.LayoutOrder = order; row.Parent = parent
		local lbl = Instance.new("TextLabel"); lbl.Size = UDim2.new(0.5, -8, 1, 0); lbl.BackgroundTransparency = 1; lbl.Text = o.Name; lbl.FontFace = FONT_FACE; lbl.TextSize = 14; lbl.TextColor3 = C.Text; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = row
		local pill = Instance.new("TextButton"); pill.AnchorPoint = Vector2.new(1, 0.5); pill.Position = UDim2.new(1, -2, 0.5, 0); pill.Size = UDim2.new(0, 128, 0, 26); pill.BackgroundColor3 = C.Card; pill.AutoButtonColor = false; pill.Text = ""; pill.Parent = row; corner(pill, 6)
		local pillStroke = stroke(pill, C.Stroke, 1, 0)
		local vL = Instance.new("TextLabel"); vL.Position = UDim2.fromOffset(10, 0); vL.Size = UDim2.new(1, -30, 1, 0); vL.BackgroundTransparency = 1; vL.Text = o.Default; vL.FontFace = FONT_FACE; vL.TextSize = 13; vL.TextColor3 = C.Text; vL.TextXAlignment = Enum.TextXAlignment.Left; vL.TextTruncate = Enum.TextTruncate.AtEnd; vL.Parent = pill
		local chevron = makeChevron(pill, C.TextDim); chevron.Position = UDim2.new(1, -12, 0.5, 0)
		local popup = Instance.new("Frame"); popup.BackgroundColor3 = C.Card; popup.BorderSizePixel = 0; popup.Visible = false; popup.ZIndex = 40; popup.ClipsDescendants = true; popup.Parent = gui; corner(popup, 8); stroke(popup, C.Stroke, 1, 0)
		local ll = Instance.new("UIListLayout"); ll.SortOrder = Enum.SortOrder.LayoutOrder; ll.Parent = popup
		local optH, open, locked = 30, false, false
		local ti = TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
		local close, openUp
		close = function() if not open then return end open = false; TweenService:Create(chevron, ti, { Rotation = 0 }):Play(); local w = popup.AbsoluteSize.X; local tw = TweenService:Create(popup, ti, { Size = UDim2.fromOffset(w, 0) }); tw:Play(); tw.Completed:Connect(function() if not open then popup.Visible = false end end); if S.closeActivePopup == close then S.closeActivePopup = nil end end
		openUp = function() if open or locked then return end if S.closeActivePopup then S.closeActivePopup(); S.closeActivePopup = nil end open = true; TweenService:Create(chevron, ti, { Rotation = 180 }):Play(); local a, sz = pill.AbsolutePosition, pill.AbsoluteSize; local w = math.max(sz.X, 128); popup.Position = UDim2.fromOffset(a.X + sz.X - w, a.Y + sz.Y + 4); popup.Size = UDim2.fromOffset(w, 0); popup.Visible = true; TweenService:Create(popup, ti, { Size = UDim2.fromOffset(w, #o.Options * optH) }):Play(); S.closeActivePopup = close end
		for i, opt in ipairs(o.Options) do
			local ob = Instance.new("TextButton"); ob.Size = UDim2.new(1, 0, 0, optH); ob.BackgroundColor3 = C.Accent; ob.BackgroundTransparency = 1; ob.AutoButtonColor = false; ob.Text = "   " .. opt; ob.FontFace = FONT_FACE; ob.TextSize = 13; ob.TextColor3 = (opt == o.Default) and C.Accent or C.Text; ob.TextXAlignment = Enum.TextXAlignment.Left; ob.ZIndex = 41; ob.LayoutOrder = i; ob.Parent = popup
			ob.MouseEnter:Connect(function() TweenService:Create(ob, TweenInfo.new(0.12), { BackgroundTransparency = 0.85 }):Play() end)
			ob.MouseLeave:Connect(function() TweenService:Create(ob, TweenInfo.new(0.12), { BackgroundTransparency = 1 }):Play() end)
			ob.MouseButton1Click:Connect(function() vL.Text = opt; for _, c in ipairs(popup:GetChildren()) do if c:IsA("TextButton") then c.TextColor3 = C.Text end end ob.TextColor3 = C.Accent; close(); if o.Callback then o.Callback(opt) end if o.LockOnce then locked = true; chevron.Visible = false; vL.TextColor3 = C.TextDim; pillStroke.Transparency = 0.55; pill.BackgroundTransparency = 0.35 end end)
		end
		pill.MouseButton1Click:Connect(function() if locked then return end if open then close() else openUp() end end)
		return { Set = function(_, opt) vL.Text = opt; if o.Callback then o.Callback(opt) end end }
	end

	local function makeButton(parent, order, o)
		local b = Instance.new("TextButton"); b.Size = UDim2.new(1, 0, 0, 32); b.AutoButtonColor = false; b.Text = o.Name; b.FontFace = FONT_FACE; b.TextSize = 13; b.TextColor3 = C.Text; b.LayoutOrder = order; b.Parent = parent; card(b)
		b.MouseButton1Down:Connect(function() TweenService:Create(b, TweenInfo.new(0.1), { BackgroundColor3 = C.Accent }):Play() end)
		b.MouseButton1Up:Connect(function() TweenService:Create(b, TweenInfo.new(0.15), { BackgroundColor3 = C.Card }):Play() end)
		b.MouseLeave:Connect(function() TweenService:Create(b, TweenInfo.new(0.15), { BackgroundColor3 = C.Card }):Play() end)
		b.MouseButton1Click:Connect(function() if o.Callback then o.Callback() end end)
		return b
	end

	local function makeLabel(parent, order, text)
		local l = Instance.new("TextLabel"); l.Size = UDim2.new(1, 0, 0, 22); l.BackgroundTransparency = 1; l.Text = text; l.TextColor3 = C.TextDim; l.FontFace = FONT_FACE; l.TextSize = 14; l.TextXAlignment = Enum.TextXAlignment.Left; l.LayoutOrder = order; l.Parent = parent
		return { Set = function(_, t) l.Text = t end }
	end

	local function makeHsvPicker(swatch, initColor, onChange)
		local h, s, v = initColor:ToHSV()
		local popup = Instance.new("Frame"); popup.Size = UDim2.fromOffset(184, 158); popup.BackgroundColor3 = C.Background; popup.BackgroundTransparency = 0.02; popup.BorderSizePixel = 0; popup.Visible = false; popup.ZIndex = 40; popup.Parent = gui; corner(popup, 10); stroke(popup, C.Stroke, 1, 0.1)
		local sv = Instance.new("Frame"); sv.Position = UDim2.fromOffset(12, 12); sv.Size = UDim2.fromOffset(120, 120); sv.BackgroundColor3 = Color3.fromHSV(h, 1, 1); sv.BorderSizePixel = 0; sv.Active = true; sv.ZIndex = 41; sv.Parent = popup; corner(sv, 6)
		local wO = Instance.new("Frame"); wO.Size = UDim2.new(1, 0, 1, 0); wO.BackgroundColor3 = Color3.fromRGB(255,255,255); wO.BorderSizePixel = 0; wO.Active = false; wO.ZIndex = 42; wO.Parent = sv; corner(wO, 6); local wg = Instance.new("UIGradient"); wg.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) }); wg.Parent = wO
		local bO = Instance.new("Frame"); bO.Size = UDim2.new(1, 0, 1, 0); bO.BackgroundColor3 = Color3.fromRGB(0,0,0); bO.BorderSizePixel = 0; bO.Active = false; bO.ZIndex = 43; bO.Parent = sv; corner(bO, 6); local bg = Instance.new("UIGradient"); bg.Rotation = 90; bg.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) }); bg.Parent = bO
		local dot = Instance.new("Frame"); dot.AnchorPoint = Vector2.new(0.5, 0.5); dot.Size = UDim2.fromOffset(10, 10); dot.BackgroundColor3 = Color3.fromRGB(255,255,255); dot.BorderSizePixel = 0; dot.Active = false; dot.ZIndex = 44; dot.Parent = sv; corner(dot, 5).CornerRadius = UDim.new(1, 0); stroke(dot, Color3.fromRGB(0,0,0), 1, 0.3)
		local hue = Instance.new("Frame"); hue.Position = UDim2.fromOffset(140, 12); hue.Size = UDim2.fromOffset(20, 120); hue.BorderSizePixel = 0; hue.Active = true; hue.ZIndex = 41; hue.Parent = popup; corner(hue, 6)
		local hg = Instance.new("UIGradient"); hg.Rotation = 90; hg.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255,0,0)), ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255,255,0)), ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0,255,0)), ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0,255,255)), ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0,0,255)), ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255,0,255)), ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255,0,0)) }); hg.Parent = hue
		local hueDot = Instance.new("Frame"); hueDot.AnchorPoint = Vector2.new(0.5, 0.5); hueDot.Size = UDim2.new(1, 6, 0, 4); hueDot.BackgroundColor3 = Color3.fromRGB(255,255,255); hueDot.BorderSizePixel = 0; hueDot.Active = false; hueDot.ZIndex = 42; hueDot.Parent = hue; corner(hueDot, 2); stroke(hueDot, Color3.fromRGB(0,0,0), 1, 0.3)
		local function refresh(fire) sv.BackgroundColor3 = Color3.fromHSV(h, 1, 1); dot.Position = UDim2.new(s, 0, 1 - v, 0); hueDot.Position = UDim2.new(0.5, 0, h, 0); local col = Color3.fromHSV(h, s, v); swatch.BackgroundColor3 = col; if fire and onChange then onChange(col) end end
		refresh(false); bindDrag(sv, function(x, y) s = x; v = 1 - y; refresh(true) end); bindDrag(hue, function(_, y) h = y; refresh(true) end)
		local closeP; closeP = function() popup.Visible = false; if S.closeActivePopup == closeP then S.closeActivePopup = nil end end
		swatch.MouseButton1Click:Connect(function() if popup.Visible then closeP() else if S.closeActivePopup then S.closeActivePopup(); S.closeActivePopup = nil end local a, sz = swatch.AbsolutePosition, swatch.AbsoluteSize; popup.Position = UDim2.fromOffset(a.X + sz.X - 184, a.Y + sz.Y + 6); popup.Visible = true; S.closeActivePopup = closeP end end)
	end

	local function makeColorToggle(parent, order, o)
		local row = Instance.new("Frame"); row.Size = UDim2.new(1, 0, 0, 32); row.BackgroundTransparency = 1; row.LayoutOrder = order; row.Parent = parent
		local hasColor = o.OnColor ~= nil
		local set = attachCheckbox(row, o.Default, o.OnToggle)
		local lbl = Instance.new("TextLabel"); lbl.Position = UDim2.fromOffset(28, 0); lbl.Size = UDim2.new(1, -28 - (hasColor and 32 or 4), 1, 0); lbl.BackgroundTransparency = 1; lbl.Text = o.Name; lbl.FontFace = FONT_FACE; lbl.TextSize = 14; lbl.TextColor3 = C.Text; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = row
		if hasColor then local sw = Instance.new("TextButton"); sw.AnchorPoint = Vector2.new(1, 0.5); sw.Position = UDim2.new(1, -2, 0.5, 0); sw.Size = UDim2.fromOffset(22, 22); sw.BackgroundColor3 = o.Color or C.Accent; sw.AutoButtonColor = false; sw.Text = ""; sw.Parent = row; corner(sw, 5); stroke(sw, C.Stroke, 1.5, 0); makeHsvPicker(sw, o.Color or C.Accent, o.OnColor); o.OnColor(o.Color or C.Accent) end
		return { Set = function(_, val) set(val, true) end }
	end

	--// section API
	local function makeSectionAPI(body)
		local count = 0; local function ord() count = count + 1; return count end
		local api = {}
		function api:AddToggle(o) return makeToggle(body, ord(), o) end
		function api:AddSlider(o) return makeSlider(body, ord(), o) end
		function api:AddDropdown(o) return makeDropdown(body, ord(), o) end
		function api:AddButton(o) return makeButton(body, ord(), o) end
		function api:AddColorToggle(o) return makeColorToggle(body, ord(), o) end
		function api:AddLabel(t) return makeLabel(body, ord(), t) end
		function api:AddSubSection(name, opts) local sub = makeCollapsible(body, name, ord(), opts or { headerHeight = 30, titleSize = 13, titleColor = C.TextDim, bodyIndent = 12 }); return makeSectionAPI(sub) end
		return api
	end

	--// tabs
	local TWEEN = TweenInfo.new(0.14, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	local pageIn
	local function playPageTransition(pg) if pageIn then pageIn:Cancel() end pg.GroupTransparency = 1; pg.Position = UDim2.fromOffset(0, 8); pageIn = TweenService:Create(pg, TweenInfo.new(0.24, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { GroupTransparency = 0, Position = UDim2.fromOffset(0, 0) }); pageIn:Play() end
	local function selectTab(name)
		if S.currentTab == name then return end
		if S.closeActivePopup then S.closeActivePopup(); S.closeActivePopup = nil end
		local prev = S.currentTab; S.currentTab = name
		for tn, d in pairs(S.tabButtons) do local active = (tn == name); TweenService:Create(d.pill, TWEEN, { BackgroundTransparency = active and 0 or 1 }):Play(); TweenService:Create(d.stroke, TWEEN, { Transparency = active and 0.4 or 1 }):Play(); TweenService:Create(d.label, TWEEN, { TextColor3 = active and Color3.fromRGB(255,255,255) or C.TextDim }):Play(); TweenService:Create(d.icon, TWEEN, { BackgroundColor3 = active and C.Accent or C.TextDim }):Play() end
		for pn, pg in pairs(S.pages) do if pn ~= name then pg.Visible = false end end
		local np = S.pages[name]; np.Visible = true; updatePreviewVisible()
		if prev ~= nil then playPageTransition(np) else np.GroupTransparency = 0; np.Position = UDim2.fromOffset(0, 0) end
	end
	local function makeColumn(parent, side)
		local sc = Instance.new("ScrollingFrame"); sc.Size = UDim2.new(0.5, 0, 1, 0); sc.Position = (side == "left") and UDim2.fromScale(0, 0) or UDim2.fromScale(0.5, 0); sc.BackgroundTransparency = 1; sc.BorderSizePixel = 0; sc.ScrollBarThickness = 3; sc.ScrollBarImageColor3 = C.Accent; sc.ScrollBarImageTransparency = 0.35; sc.CanvasSize = UDim2.new(); sc.AutomaticCanvasSize = Enum.AutomaticSize.Y; sc.ScrollingDirection = Enum.ScrollingDirection.Y; sc.Parent = parent
		local pad = Instance.new("UIPadding"); pad.PaddingTop = UDim.new(0, 10); pad.PaddingBottom = UDim.new(0, 10); pad.PaddingLeft = UDim.new(0, side == "left" and 14 or 10); pad.PaddingRight = UDim.new(0, side == "left" and 10 or 14); pad.Parent = sc
		local l = Instance.new("UIListLayout"); l.Padding = UDim.new(0, 12); l.SortOrder = Enum.SortOrder.LayoutOrder; l.Parent = sc
		return sc
	end

	local Window = {}
	function Window:CreateTab(name)
		local page = Instance.new("CanvasGroup"); page.Size = UDim2.new(1, 0, 1, 0); page.BackgroundTransparency = 1; page.BorderSizePixel = 0; page.Visible = false; page.Parent = content; corner(page, 10); S.pages[name] = page
		local leftCol = makeColumn(page, "left"); local rightCol = makeColumn(page, "right")
		local leftOrd, rightOrd = 0, 0
		local pill = Instance.new("TextButton"); pill.Name = name; pill.AutomaticSize = Enum.AutomaticSize.X; pill.Size = UDim2.fromOffset(0, 32); pill.BackgroundColor3 = C.Card; pill.BackgroundTransparency = 1; pill.AutoButtonColor = false; pill.Text = ""; pill.LayoutOrder = #gui:GetChildren(); pill.Parent = pills; corner(pill, 8)
		local ps = stroke(pill, C.Accent, 1, 1)
		local pd = Instance.new("UIPadding"); pd.PaddingLeft = UDim.new(0, 12); pd.PaddingRight = UDim.new(0, 14); pd.Parent = pill
		local lay = Instance.new("UIListLayout"); lay.FillDirection = Enum.FillDirection.Horizontal; lay.VerticalAlignment = Enum.VerticalAlignment.Center; lay.Padding = UDim.new(0, 8); lay.SortOrder = Enum.SortOrder.LayoutOrder; lay.Parent = pill
		local icon = Instance.new("Frame"); icon.Size = UDim2.fromOffset(8, 8); icon.BackgroundColor3 = C.TextDim; icon.BorderSizePixel = 0; icon.LayoutOrder = 0; icon.Parent = pill; corner(icon, 4).CornerRadius = UDim.new(1, 0)
		local label = Instance.new("TextLabel"); label.AutomaticSize = Enum.AutomaticSize.X; label.Size = UDim2.new(0, 0, 1, 0); label.BackgroundTransparency = 1; label.Text = name; label.FontFace = FONT_FACE; label.TextSize = 14; label.TextColor3 = C.TextDim; label.LayoutOrder = 1; label.Parent = pill
		S.tabButtons[name] = { pill = pill, stroke = ps, label = label, icon = icon }
		pill.MouseButton1Click:Connect(function() selectTab(name) end)
		local Tab = {}
		function Tab:AddSection(secName, side, opts) local col; local order; if side == "right" then col = rightCol; rightOrd = rightOrd + 1; order = rightOrd else col = leftCol; leftOrd = leftOrd + 1; order = leftOrd end local body = makeCollapsible(col, secName, order, opts); return makeSectionAPI(body) end
		if S.currentTab == nil then selectTab(name) end
		return Tab
	end

	function Window:AddEspPreview(o)
		o = o or {}; S.espTab = o.Tab
		local pv = Instance.new("Frame"); pv.Position = UDim2.new(1, 12, 0, 0); pv.Size = UDim2.new(0, PREVIEW_W, 1, 0); pv.BackgroundColor3 = C.Background; pv.BackgroundTransparency = WIN_TR; pv.BorderSizePixel = 0; pv.Visible = false; pv.Parent = main; corner(pv, 12); stroke(pv, C.Stroke, 1, 0.2); S.espPreview = pv
		local sh = Instance.new("ImageLabel"); sh.AnchorPoint = Vector2.new(0.5, 0.5); sh.Position = UDim2.fromScale(0.5, 0.5); sh.Size = UDim2.new(1, 40, 1, 40); sh.BackgroundTransparency = 1; sh.Image = "rbxassetid://6014261993"; sh.ImageColor3 = Color3.fromRGB(0,0,0); sh.ImageTransparency = 0.55; sh.ScaleType = Enum.ScaleType.Slice; sh.SliceCenter = Rect.new(49,49,450,450); sh.ZIndex = 0; sh.Parent = pv
		local pt = Instance.new("TextLabel"); pt.Position = UDim2.fromOffset(14, 10); pt.Size = UDim2.fromOffset(180, 18); pt.BackgroundTransparency = 1; pt.Text = o.Title or "ESP Preview"; pt.FontFace = FONT_FACE; pt.TextSize = 13; pt.TextColor3 = C.Text; pt.TextXAlignment = Enum.TextXAlignment.Left; pt.Parent = pv
		local scene = Instance.new("Frame"); scene.Position = UDim2.new(0, 8, 0, 34); scene.Size = UDim2.new(1, -16, 1, -42); scene.BackgroundColor3 = C.Content; scene.BackgroundTransparency = CON_TR; scene.BorderSizePixel = 0; scene.ClipsDescendants = true; scene.Parent = pv; corner(scene, 8); stroke(scene, C.Stroke, 1, 0.4)
		local tracer = Instance.new("Frame"); tracer.AnchorPoint = Vector2.new(0.5, 1); tracer.Position = UDim2.new(0.5, 0, 1, 0); tracer.Size = UDim2.new(0, 2, 0, 0); tracer.BackgroundColor3 = C.Accent; tracer.BorderSizePixel = 0; tracer.Visible = false; tracer.Parent = scene
		local box = Instance.new("Frame"); box.AnchorPoint = Vector2.new(0.5, 0.5); box.Position = UDim2.new(0.5, 0, 0.52, 0); box.Size = UDim2.new(0.7, 0, 0.8, 0); box.BackgroundTransparency = 1; box.Parent = scene
		local ar = Instance.new("UIAspectRatioConstraint"); ar.AspectRatio = o.Aspect or 0.66; ar.DominantAxis = Enum.DominantAxis.Height; ar.Parent = box
		local boxStroke = stroke(box, C.Accent, 1.5, 0)
		local char = Instance.new("ImageLabel"); char.AnchorPoint = Vector2.new(0.5, 0.5); char.Position = UDim2.new(0.5, 0, 0.5, 0); char.Size = UDim2.new(1, 0, 1, 0); char.BackgroundTransparency = 1; char.Image = o.Image or "rbxassetid://753015086"; char.ScaleType = Enum.ScaleType.Fit; char.ZIndex = 2; char.Parent = box
		local nameTag = Instance.new("TextLabel"); nameTag.AnchorPoint = Vector2.new(0.5, 1); nameTag.Position = UDim2.new(0.5, 0, 0, -4); nameTag.Size = UDim2.fromOffset(140, 16); nameTag.BackgroundTransparency = 1; nameTag.Text = o.Name or "Noob"; nameTag.FontFace = FONT_FACE; nameTag.TextSize = 13; nameTag.TextColor3 = Color3.fromRGB(255,255,255); nameTag.ZIndex = 3; nameTag.Parent = box
		local hpBg = Instance.new("Frame"); hpBg.AnchorPoint = Vector2.new(1, 0.5); hpBg.Position = UDim2.new(0, -4, 0.5, 0); hpBg.Size = UDim2.new(0, 4, 1, 0); hpBg.BackgroundColor3 = Color3.fromRGB(0,0,0); hpBg.BackgroundTransparency = 0.35; hpBg.BorderSizePixel = 0; hpBg.Parent = box; corner(hpBg, 2).CornerRadius = UDim.new(1, 0)
		local hpFill = Instance.new("Frame"); hpFill.AnchorPoint = Vector2.new(0.5, 1); hpFill.Position = UDim2.new(0.5, 0, 1, 0); hpFill.Size = UDim2.new(1, 0, 0.75, 0); hpFill.BackgroundColor3 = C.Health; hpFill.BorderSizePixel = 0; hpFill.Parent = hpBg; corner(hpFill, 2).CornerRadius = UDim.new(1, 0)
		local distTag = Instance.new("TextLabel"); distTag.AnchorPoint = Vector2.new(0.5, 0); distTag.Position = UDim2.new(0.5, 0, 1, 4); distTag.Size = UDim2.fromOffset(140, 14); distTag.BackgroundTransparency = 1; distTag.Text = o.Distance or "14m"; distTag.FontFace = FONT_FACE; distTag.TextSize = 12; distTag.TextColor3 = Color3.fromRGB(255,255,255); distTag.ZIndex = 3; distTag.Parent = box
		task.spawn(function() while box.Parent do local u = TweenService:Create(box, TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Position = UDim2.new(0.5, 0, 0.50, 0) }); u:Play(); u.Completed:Wait(); if not box.Parent then break end local d = TweenService:Create(box, TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Position = UDim2.new(0.5, 0, 0.54, 0) }); d:Play(); d.Completed:Wait() end end)
		local conn; conn = RunService.RenderStepped:Connect(function() if not box.Parent then conn:Disconnect() return end if not tracer.Visible then return end local sA, sS = scene.AbsolutePosition, scene.AbsoluteSize; if sS.Y <= 0 then return end local bB = box.AbsolutePosition.Y + box.AbsoluteSize.Y; local hg = math.max(0, (sA.Y + sS.Y) - bB); local rx = (box.AbsolutePosition.X + box.AbsoluteSize.X / 2) - sA.X; tracer.Position = UDim2.new(0, rx, 1, 0); tracer.Size = UDim2.new(0, 2, 0, hg) end)
		return {
			SetVisible = function(_, v) S.previewEnabled = v; updatePreviewVisible() end,
			SetBoxEnabled = function(_, v) boxStroke.Enabled = v end, SetBoxColor = function(_, c) boxStroke.Color = c end,
			SetNameVisible = function(_, v) nameTag.Visible = v end, SetNameColor = function(_, c) nameTag.TextColor3 = c end,
			SetHealthVisible = function(_, v) hpBg.Visible = v end, SetHealthColor = function(_, c) hpFill.BackgroundColor3 = c end, SetHealthPct = function(_, p) hpFill.Size = UDim2.new(1, 0, math.clamp(p, 0, 1), 0) end,
			SetTracerVisible = function(_, v) tracer.Visible = v end, SetTracerColor = function(_, c) tracer.BackgroundColor3 = c end,
			SetDistanceVisible = function(_, v) distTag.Visible = v end, SetDistanceColor = function(_, c) distTag.TextColor3 = c end,
			SetName = function(_, t) nameTag.Text = t end, SetDistance = function(_, t) distTag.Text = t end,
		}
	end

	function Window:Select(name) selectTab(name) end
	function Window:SetVisible(v) S.visible = v; main.Visible = v; updatePreviewVisible() end
	function Window:Toggle() Window:SetVisible(not S.visible) end
	function Window:Destroy() gui:Destroy() end

	--// grip + resize + drag
	local grip = Instance.new("Frame"); grip.AnchorPoint = Vector2.new(1, 1); grip.Position = UDim2.new(1, 1, 1, 2); grip.Size = UDim2.fromOffset(22, 22); grip.BackgroundTransparency = 1; grip.ZIndex = 6; grip.Parent = main
	local function gline(len, cx, cy) local l = Instance.new("Frame"); l.AnchorPoint = Vector2.new(0.5, 0.5); l.Position = UDim2.fromOffset(cx, cy); l.Size = UDim2.fromOffset(len, 2); l.BackgroundColor3 = C.TextDim; l.BackgroundTransparency = 0.15; l.BorderSizePixel = 0; l.Rotation = -45; l.ZIndex = 6; corner(l, 1).CornerRadius = UDim.new(1, 0); l.Parent = grip end
	gline(18, 14, 14); gline(11, 11, 11)
	local resize = Instance.new("TextButton"); resize.AnchorPoint = Vector2.new(1, 1); resize.Position = UDim2.new(1, 0, 1, 0); resize.Size = UDim2.fromOffset(24, 24); resize.BackgroundTransparency = 1; resize.Text = ""; resize.AutoButtonColor = false; resize.ZIndex = 7; resize.Parent = main
	local dragging, dragStart, startPos, resizing = false, nil, nil, false
	header.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = true; dragStart = i.Position; startPos = main.Position end end)
	resize.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then resizing = true end end)
	UIS.InputChanged:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then if dragging then local d = i.Position - dragStart; main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y) elseif resizing then local tl = main.AbsolutePosition; local w = math.clamp(i.Position.X - tl.X, MIN_SIZE.X, MAX_SIZE.X); local h = math.clamp(i.Position.Y - tl.Y, MIN_SIZE.Y, MAX_SIZE.Y); main.Size = UDim2.fromOffset(w, h) end end end)
	UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false; resizing = false end end)
	resize.MouseEnter:Connect(function() UIS.MouseIcon = "rbxasset://SystemCursors/SizeNWSE" end)
	resize.MouseLeave:Connect(function() if not resizing then UIS.MouseIcon = "" end end)
	if cfg.ToggleKey then UIS.InputBegan:Connect(function(i, gp) if gp then return end if i.KeyCode == cfg.ToggleKey then Window:Toggle() end end) end

	return Window
end

return Library
