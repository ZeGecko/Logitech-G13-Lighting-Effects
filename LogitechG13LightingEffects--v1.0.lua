-- Logitech G13 Lighting Effects v1.0
-- By Ze Gecko

-- Lighting Effect:
-- 0 = Start script without any effects active.
-- 1 = Color Cycle. (You can hit Ctrl + G20 to turn on when no effect is active)
-- 2 = Breathing Effect. (Color must be set below. Ctrl + G21 to turn on w/no active effect)
LightingEffect = 0

-- LED Brightness from 0 to 255:
LEDBrightness = 128

-- LED Rate for a full color cycle (i.e. red to red) in seconds:
LEDRate = 10.8

-- Breathing Effect color (values must be between 0 - 255):
R = 255
G = 255
B = 255

-- Lighting sleep timer in minutes (0 for off):
-- Note: Due to limitations timer is based off mouse movement.
LEDSleep = 0

-- Allow changing M key to stop active effect (true or false):
-- From what I gather this is the only way to break out of a loop.
AllowKillSwitch = true



----- Below allows you to fine tune the color changing speeds -----
----- Note: LEDRate must be set to 0 for these to take effect -----

-- Color change rate in miliseconds:
-- Warning: The lower the change rate the more unstable & prone to crashing LGS becomes.
-- Do not have the script auto run at start until you find a level you are happy with
-- which doesn't crash LGS (for me anything below 25ms caused problems but YMMV)
ChangeRate = 27

-- Color step rate from 1 to 255:
-- How many color levels do you want to advance with each color change.
StepRate = 1



-----------------------------------------------------
-- Only alter below if you know what you are doing --
-----------------------------------------------------

IsRunning = false
SleepTimer = 0
MouseX = 0
MouseY = 0

-- The function called whenever a button is pressed.
-- Note: With the nature of how loops are handled this function
-- will never be called when an effect is active.
function OnEvent(event, arg, family)
	-- Run at startup.
	if event == "PROFILE_ACTIVATED" then
		FormatVariables()
		if LightingEffect == 1 then ColorCycle()
		elseif LightingEffect == 2 then ColorBreathe()
		end
	end
	
	-- Run when profile shuts down.
	if event == "PROFILE_DEACTIVATED" then
		IsRunning = false
	end
	
	-- Press Ctrl + G20 to turn on Color Cycle.
	if (event == "G_PRESSED" and arg == 20 and IsModifierPressed("ctrl")) then
		ColorCycle()
	end

	-- Press Ctrl + G21 to turn on Breathing Effect.
	if (event == "G_PRESSED" and arg == 21 and IsModifierPressed("ctrl")) then
		ColorBreathe()
	end

end

-- Make sure User input is within bounds.
function FormatVariables()
	LEDBrightness = math.floor(LEDBrightness)
	ChangeRate = math.floor(ChangeRate)
	StepRate = math.floor(StepRate)
	if LEDBrightness < 0 then LEDBrightness = 0; end
	if LEDBrightness > 255 then LEDBrightness = 255; end
	if ChangeRate < 1 then ChangeRate = 1; end
	if ChangeRate > 255 then ChangeRate = 255; end
	if StepRate < 1 then StepRate = 1; end
	if StepRate > 255 then StepRate = 255; end
	R, G, B = RGBCheck(math.floor(R), math.floor(G), math.floor(B))
end

-- Determine the optimal Change Rate and Step Rate automatically.
function RateCalc(LEi)
	bcr = 255
	bsr = 1
	bf = 1
	LEi = 4 - LEi
	-- Try to find best step rate which keeps change rate closest to integer.
	-- We will cycle through step rate (how many colors to advance)
	-- in attempt to find the optimal change rate (how many ms to show each color).
	for tsr = 1, LEDBrightness do
		-- Change Rate = Step Rate times how long we want to take to show every color
		-- Divided by the number of colors we want to show.
		-- My algebra is dusty but this appears to get close to time aiming for.
		tcr = (tsr * (LEDRate * 1000)) / (LEDBrightness * LEi)
		i, f = math.modf(tcr)
		-- We check to see lowest change rate without going under 30 for stability
		-- whilst makeing sure it is closest to whole number in attempt for accuracy.
		if i < bcr and i > 30 and f < bf then
			bcr = i
			bsr = tsr
			bf = f
		end
	end
	-- Set our ChangeRate & StepRate to values we deemed most accurate.
	ChangeRate = bcr
	StepRate = bsr
end

-- Make sure RGB input is within range (0 - 255) and return modified values.
function RGBCheck(Ri, Gi, Bi)
	if Ri < 0 then Ri = 0; end; if Ri > 255 then Ri = 255; end
	if Gi < 0 then Gi = 0; end; if Gi > 255 then Gi = 255; end
	if Bi < 0 then Bi = 0; end; if Bi > 255 then Bi = 255; end
	return Ri, Gi, Bi
end

-- Cycle through the colors.
function ColorCycle()
	-- Initialize function variables and start at Red at set brightness.
	IsRunning = true
	InitialMKey = GetMKeyState("lhc")
	R = LEDBrightness; G = 0; B = 0
	if LEDRate > 0 then RateCalc(1); end
	-- Loop through colors.
	while IsRunning do
		-- Cycle to next color to change backlight.
		if R > 0 and G >= 0 and B == 0 then
			R = R - StepRate; G = G + StepRate
		elseif G > 0 and B >= 0 and R == 0 then
			G = G - StepRate; B = B + StepRate
		elseif B > 0 and R >= 0 and G == 0 then
			B = B - StepRate; R = R + StepRate
		end
		R, G, B = RGBCheck(R, G, B)
		SetBacklightColor(R, G, B, "lhc")
		-- Check if MKey changed and stop script if allowed.
		if AllowKillSwitch and (InitialMKey ~= GetMKeyState("lhc"))	then IsRunning = false; end
		if not IsRunning then break; end
		-- Check if LEDs should be turned off.
		SleepCheck()
		-- Wait before changing to the next color.
		Sleep(ChangeRate)
	end
	-- If you're curious what color script stopped on, display values on LCD.
	ClearLCD()
	OutputLCDMessage(" R: " .. R .. " \n G: " .. G .. " \n B: " .. B, 3000)
end

-- Breathing Effect (pulsing)
function ColorBreathe()
	-- For some reason if R, G, & B are all 85, 170, or 255 the backlight goes green...
	-- This may just be my device but threw in a hotfix.
	-- You may disable it if you wish.
	HF = true
	
	-- Initialize variables.
	IsRunning = true
	InitialMKey = GetMKeyState("lhc")
	-- Determine highest color value.
	hC = math.max(R,G,B)
	if hC < 1 then hC = 1; end -- Unlikely but just so we don't accidentally divide by 0.
	-- Adjust color inputs if highest color value is below desired brightness.
	-- Note: This formula is used repeatedly to get values to change in respect to eachother.
	-- Color value = color value aiming for multiplied by
	-- the average of the original max value of that color in respect to highest color value.
	if LEDBrightness > hC then
		R = math.floor(LEDBrightness * (R / hC))
		G = math.floor(LEDBrightness * (G / hC))
		B = math.floor(LEDBrightness * (B / hC))
		hC = LEDBrightness
	end
	-- Determine brightness adjustment to account for loop
	-- since the lower the absolute number the brighter the LEDs.
	bR = math.floor(R * (LEDBrightness / 255))
	bG = math.floor(G * (LEDBrightness / 255))
	bB = math.floor(B * (LEDBrightness / 255))
	if LEDRate > 0 then RateCalc(2); end
	-- Loop through brightness levels.
	while IsRunning do
		for bval = -LEDBrightness, LEDBrightness, StepRate do
			-- Modify color values so each hit 0 and their max value at same time.
			-- This allows us to keep the light color consistant as brightness changes.
			mR = bR - math.floor(math.abs(bval) * (R / hC))
			mG = bG - math.floor(math.abs(bval) * (G / hC))
			mB = bB - math.floor(math.abs(bval) * (B / hC))
			  -- HotFix, have red run one value behind to prevent green flashes.
			  if HF and mR == mG and mR == mB and mR > 0 then mR = mR - 1; end
			mR, mG, mB = RGBCheck(mR, mG, mB)
			SetBacklightColor(mR, mG, mB, "lhc")
			-- Check if MKey changed and stop script if allowed.
			if AllowKillSwitch and (InitialMKey ~= GetMKeyState("lhc"))	then IsRunning = false; end
			if not IsRunning then break; end
			-- Check if LEDs should be turned off.
			SleepCheck()
			-- Wait before adjusting brightness again.
			Sleep(ChangeRate)
		end
		-- Wait a bit longer while LEDs are off for that breathe effect.
		Sleep(30)
	end
end

-- Check to see if LEDs should turn off
function SleepCheck()
	if LEDSleep > 0 then
		tMouseX, tMouseY = GetMousePosition()
		if tMouseX == MouseX and tMouseY == MouseY then
			SleepTimer = SleepTimer + ChangeRate
			if SleepTimer > (LEDSleep * 60000) then LEDOff(); end
		else SleepTimer = 0; end
		MouseX, MouseY = GetMousePosition()
	end
end

-- Turn off LEDs and wait for mouse movement
function LEDOff()
	MouseX, MouseY = GetMousePosition()
	SetBacklightColor(0,0,0,"lhc")
	while IsRunning do
		tMouseX, tMouseY = GetMousePosition()
		if tMouseX ~= MouseX and tMouseY ~= MouseY then break; end
		MouseX, MouseY = GetMousePosition()
		Sleep(100)
	end
end