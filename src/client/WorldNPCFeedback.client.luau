local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local TweenService=game:GetService("TweenService")

local player=Players.LocalPlayer
local remotes=ReplicatedStorage:WaitForChild("SurvivalRemotes")
local feedback=remotes:WaitForChild("WorldNPCFeedback")

local gui=Instance.new("ScreenGui")
gui.Name="WorldNPCFeedbackHUD"
gui.ResetOnSpawn=false
gui.DisplayOrder=65
gui.Parent=player:WaitForChild("PlayerGui")

local toast=Instance.new("TextLabel")
toast.AnchorPoint=Vector2.new(0.5,1)
toast.Position=UDim2.new(0.5,0,1,-138)
toast.Size=UDim2.fromOffset(430,46)
toast.BackgroundColor3=Color3.fromRGB(20,20,24)
toast.BackgroundTransparency=0.1
toast.TextColor3=Color3.fromRGB(244,231,190)
toast.Font=Enum.Font.GothamBold
toast.TextSize=13
toast.TextWrapped=true
toast.Visible=false
toast.ZIndex=80
toast.Parent=gui
Instance.new("UICorner",toast).CornerRadius=UDim.new(0,11)
local stroke=Instance.new("UIStroke")
stroke.Color=Color3.fromRGB(255,255,255)
stroke.Transparency=0.84
stroke.Parent=toast

local token=0
feedback.OnClientEvent:Connect(function(message)
	if type(message)~="string" then return end
	token+=1
	local my=token
	toast.Text=message
	toast.TextTransparency=0
	toast.BackgroundTransparency=0.1
	toast.Visible=true
	task.delay(2.8,function()
		if token~=my then return end
		TweenService:Create(toast,TweenInfo.new(0.25),{TextTransparency=1,BackgroundTransparency=1}):Play()
		task.delay(0.28,function() if token==my then toast.Visible=false end end)
	end)
end)
