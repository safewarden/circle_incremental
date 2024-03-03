local script_version = getgenv().script_version;
if script_version then getgenv().script_version += 1 else 
    getgenv().script_version = 1;
end; script_version = getgenv().script_version;

replicatedStorage = game:GetService("ReplicatedStorage");
players = game:GetService('Players');
player = players.LocalPlayer;

network = require(replicatedStorage.Modules.Networking);
library = loadstring(game:HttpGet(('https://raw.githubusercontent.com/shlexware/Orion/main/source')))();
settings_t = {
    auto_collect_circles = false;
    auto_collect_boxes = false;
    auto_skill_mastery = false;

    auto_upgrade_tree = false;
    upgrade_panel_upgrades = {};
};

boards = {
    waiting = '22',
    dilate = '21',
    time = '20',
    fighting = '19',
    sacrafice = '18',
    supersede = '16'
};

upgrades = {
    waiting = 9,
    dilate = 8,
    time = 4,
    fighting = 5,
    sacrafice = 4,
    supersede = 6
}

window = library:MakeWindow({Name = 'circle incremental farm', SaveConfig = false, ConfigFolder = 'circle_incremental'});
click_pad_positions = {Vector3.new(105, 0.25, -17.5), Vector3.new(105, 0.5, -17.5)};

auto_farm = window:MakeTab({Name = 'auto farm', Icon = 'rbxassetid://4483345998'});
auto_upgrade = window:MakeTab({Name = 'auto upgrades', Icon = 'rbxassetid://4483345998'});

auto_farm_settings = auto_farm:AddSection({Name = 'auto farm settings'});
auto_upgrade_settings = auto_upgrade:AddSection({Name = 'auto upgrade settings'});
auto_upgrade_billboard_settings = auto_upgrade:AddSection({Name = 'auto upgrade billboard settings'})

for _, setting in pairs({'auto collect circles', 'auto collect boxes', 'auto skill mastery'}) do
    auto_farm_settings:AddToggle({
        Name = setting,
        Default = true,
        Callback = function(value)
            local func = table.concat(string.split(setting, ' '), '_');
            settings_t[func] = not settings_t[func];
        end;
    });
end

auto_upgrade_settings:AddToggle({
    Name = 'auto upgrade tree',
    Default = false,
    Callback = function()
        settings_t.auto_upgrade_tree = not settings_t.auto_upgrade_tree;
    end;
});

for _, panel in pairs({'waiting', 'dilate', 'time', 'fighting', 'sacrafice', 'supersede'}) do
    auto_upgrade_billboard_settings:AddToggle({ 
        Name = 'auto ' .. panel .. ' upgrades',
        Default = false,
        Callback = function(value)
            local _panel = settings_t.upgrade_panel_upgrades[panel]
            if _panel == nil then _panel = false end;

            settings_t.upgrade_panel_upgrades[panel] = not _panel;
        end;
    });
end

in_loop = false;
auto_collect_circles = function()
    if not in_loop then
        for _, circle in pairs(workspace.Stuff:GetChildren()) do
            in_loop = true;
            if not settings_t.auto_collect_circles then break end;

            if circle.name == 'Part' then
                task.wait();
                player.Character.HumanoidRootPart.CFrame = (circle.CFrame + Vector3.new(0,2,0));
            end
        end

        in_loop = false;
    end
end

auto_collect_boxes = function()
    return;

    --[[local normal_box = BrickColor.new('Medium stone grey');
    local golden_box = BrickColor.new('New Yeller');

    for _, box in pairs(workspace.Stuff:GetChildren()) do
        if box.name == 'Box' then
            if box.BrickColor == normal_box then
                box.CFrame = workspace.BoxRing.Furnace.End.CFrame;
            elseif box.BrickColor == golden_box then
                box.CFrame = workspace.BoxRing.GoldFurnace.End.CFrame;
            end
        end
    end]] --@ detected :(
end

auto_upgrade_panel = function(type, panel)
    for _, upgrade in pairs(player.PlayerGui.Game.Upgrades:GetChildren()) do
        if upgrade:IsA('SurfaceGui') and upgrade:FindFirstChild('Buy') and upgrade.name == (boards[tostring(type)] .. '_' .. tostring(panel)) then
            pcall(function()
                if upgrade:FindFirstChild('Max') then
                    firesignal(upgrade.Max.MouseButton1Click);
                else
                    firesignal(upgrade.Buy.MouseButton1Click);
                end
            end)
        end
    end
end

auto_upgrade_tree = function()
    for _, upgrade in pairs(workspace.Tree.Buttons:GetChildren()) do
        if upgrade:FindFirstChildOfClass('SelectionBox') then
            fireclickdetector(upgrade.ClickDetector);
        end
    end
end

mastery = false
last_mastery = 0;
auto_skill_mastery = function()
    if os.time() - last_mastery >= 4 and not mastery then
        mastery = true
        last_mastery = os.time()
        network.Invoke('ClaimSkillPoints', 10)
        
        wait(4)
        mastery = false
    end
end

settings_t.auto_collect_circles = true;
settings_t.auto_collect_boxes = true;
settings_t.auto_skill_mastery = true;
settings_t.auto_upgrade_tree = false;
settings_t.upgrade_panel_upgrades = {};

teleporting = false
player.OnTeleport:Connect(function(state)
	if not teleporting and queue_on_teleport then
		teleporting = true
		queue_on_teleport("loadstring(game:HttpGet(''))()")
	end
end)

library:Init();
is_last = {};
game:GetService('RunService').Stepped:Connect(function()
    if script_version ~= getgenv().script_version then return end;

    if settings_t.auto_collect_circles then 
        player.Character.HumanoidRootPart.Anchored = true;
        auto_collect_circles()
    else
        player.Character.HumanoidRootPart.Anchored = false;
    end;

    if settings_t.auto_collect_boxes then auto_collect_boxes() end;
    if settings_t.auto_upgrade_tree then auto_upgrade_tree() end;
    if settings_t.auto_skill_mastery then auto_skill_mastery() end

    for index, upgrade in pairs(settings_t.upgrade_panel_upgrades) do
        if upgrade and not is_last[index] then
            for i = 1, upgrades[index] do
                task.spawn(function()
                    is_last[index] = true;
                    auto_upgrade_panel(index, i);
                end)
            end

            task.wait(0.5);
            is_last[index] = false;
        end
    end
end)
