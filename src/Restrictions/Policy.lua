-- Policy.lua — LvkHub Targets & Restrictions
-- Modificado: alvos reais (Workspace.Players) autorizados, sem fallback para TestPlayers

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Policy = {
    -- Modo apenas para referência (não usado em lógica crítica)
    Mode = "REAL_PLAYERS",

    -- Agora aponta para Workspace.Players (pasta nativa do Roblox)
    TargetFolderName = "Players",

    -- Atributo mantido por compatibilidade, mas NÃO é mais exigido
    ManagedDummyAttribute = "LvkHubManagedDummy",
}

--[[
    IsRealPlayerCharacter(model)
    Retorna true se o model for o Character de um jogador real (Players)
]]
function Policy.IsRealPlayerCharacter(model)
    if not model or not model:IsA("Model") then
        return false
    end
    -- Verifica se model está na pasta Workspace.Players
    local parent = model.Parent
    if parent and parent:IsA("Folder") and parent.Name == "Players" then
        -- Confirma se existe um Player associado a esse Character
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr.Character == model then
                return true
            end
        end
    end
    return false
end

--[[
    IsAllowedTarget(model)
    Função principal de autorização de alvo para ESP/Aimbot/Silent/HitBoxes.
    Agora ACEITA qualquer Player.Character real.
]]
function Policy.IsAllowedTarget(model)
    if not model or not model:IsA("Model") then
        return false
    end

    -- 1. Aceita personagens reais
    if Policy.IsRealPlayerCharacter(model) then
        return true
    end

    -- 2. (Opcional) ainda pode aceitar dummies gerenciados se quiser manter
    -- para testes. Comente ou remova para desabilitar completamente.
    local testFolder = Workspace:FindFirstChild("TestPlayers")
    if testFolder and model:IsDescendantOf(testFolder) then
        if model:GetAttribute(Policy.ManagedDummyAttribute) == true then
            return true
        end
    end

    -- 3. Qualquer outro modelo → negado
    return false
end

--[[
    GetCandidates()
    Varre Workspace.Players (e opcionalmente TestPlayers) e retorna
    lista de modelos válidos conforme IsAllowedTarget.
]]
function Policy.GetCandidates()
    local candidates = {}
    local foldersToScan = {
        Workspace:FindFirstChild("Players"),
        Workspace:FindFirstChild("TestPlayers")  -- opcional, remova se não quiser
    }

    for _, folder in ipairs(foldersToScan) do
        if folder then
            for _, child in ipairs(folder:GetChildren()) do
                if child:IsA("Model") and Policy.IsAllowedTarget(child) then
                    table.insert(candidates, child)
                end
            end
        end
    end

    return candidates
end

--[[
    CanCloneSource(model)
    Usado pelo loader para clonar rigs de Workspace.Players para TestPlayers.
    Se você não quiser mais clonar, pode fazer essa função retornar false sempre,
    ou simplesmente não chamá-la no loader.
]]
function Policy.CanCloneSource(model)
    if not model or not model:IsA("Model") then
        return false
    end
    -- Originalmente só permitia clonar de Players. Mantemos igual.
    return Policy.IsRealPlayerCharacter(model)
end

--[[
    OtherPlayerCount()
    Conta jogadores reais (excluindo o local).
    Se o menu usar isso para decidir se aplica mods de arma ou não,
    agora sempre retornará o número real de outros jogadores.
]]
function Policy.OtherPlayerCount()
    local localPlayer = Players.LocalPlayer
    local count = 0
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= localPlayer and plr.Character then
            count = count + 1
        end
    end
    return count
end

--[[
    SoloWeaponModsAllowed()
    Se o menu usa essa função para permitir/negar modificações em armas
    quando há outros jogadores, você pode querer sobrescrever para sempre true.
]]
function Policy.SoloWeaponModsAllowed()
    -- Agora retorna true mesmo com outros jogadores (se quiser PvP total)
    return true
end

--[[
    FallbackPolicy()
    Essa função era chamada pelo loader se Policy.lua fosse apagado.
    Ela criava uma política com TEST_DUMMIES_ONLY.
    AGORA, mesmo no fallback, ela cria uma política que autoriza reais.
]]
function Policy.FallbackPolicy()
    return setmetatable({
        Mode = "REAL_PLAYERS_FALLBACK",
        TargetFolderName = "Players",
        ManagedDummyAttribute = "LvkHubManagedDummy",
        IsAllowedTarget = function(self, model)
            if not model or not model:IsA("Model") then return false end
            -- Fallback também aceita Players reais
            if self.IsRealPlayerCharacter(model) then return true end
            -- (sem dummies para fallback puro)
            return false
        end,
        IsRealPlayerCharacter = Policy.IsRealPlayerCharacter,
        GetCandidates = function(self)
            local folder = Workspace:FindFirstChild("Players")
            local list = {}
            if folder then
                for _, child in ipairs(folder:GetChildren()) do
                    if child:IsA("Model") and self.IsAllowedTarget(self, child) then
                        table.insert(list, child)
                    end
                end
            end
            return list
        end,
        OtherPlayerCount = Policy.OtherPlayerCount,
        SoloWeaponModsAllowed = function() return true end,
    }, { __index = Policy })
end

-- Se o loader usar require diretamente, retorna a tabela Policy
return Policy
