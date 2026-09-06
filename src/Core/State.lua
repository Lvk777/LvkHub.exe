local State = {
    UI = {Visible = true, Minimized = false, ActiveTab = "Visuals"},
    Visuals = {
        ESP = false, Chams = false, CornerBox = false, Box3D = false,
        HealthBar = false, NameDistance = false, ThermalCorner = false,
        Tracers = false, Skeleton = false, Preview = false, CarESP = false,
        FOV = 70,
    },
    World = {
        FullBrightness = false, NoFog = false, NoLeaves = false,
        NoShadows = false, FPSBoost = false, Sky = "Default",
    },
    Movement = {
        Fly = false, CarFly = false, Noclip = false, Speed = false,
        SpeedValue = 32, MouseTP = false,
    },
    Combat = {
        Aimbot = false, HitBoxes = false, SilentAim = false, AntiAim = false,
        AimPart = "Head", HitboxSize = 6,
    },
    Utility = {
        AntiAFK = false, NoMenuFog = false,
    },
    Local = {
        HitSound = false, GunChams = false, SelfChams = false, Trail = false,
    },
}

return State
