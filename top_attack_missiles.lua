activeMainframe = 0; -- set the mainframe that this guidance system should slave to.
                     -- 0 is the first mainframe, 1 the second, 2 the next, etc..
                     -- May cause errors if an invalid mainframe was given

ascentTime = 3;      -- The time (in seconds) the missile will spend ascending to above the target.
                     -- A longer ascent time will make the missile be higher above the target
                     -- However, shorter ascent times will make the missile hit the target quicker
                     -- You should balance this with your missile's flight speed, lifetime, and thrust time

ascentHeight = 3000; -- The peak height that the missile should aim for during the ascent phase
                     -- Higher heights will result in the missile have a steeper slope during the ascent
                     -- Lower heights will have a more direct path

directHeight = 50;   -- Will fly in a direct line if the targets height is above this level
                     -- This is intended to compensate for aircraft, though missiles guided using
                     -- seeking heads will be more effective



-- Note that you CANNOT have two different lua boxes with conflicting scripts for missile guidance
-- This will affect ALL missiles with the proper lua equipment

transcieverCount = 0;
missileCount = 0;
mainframes = 0;
numberOfTargets = 0;
missilesPerTarget = 0;

function Update(I)
    GetMissileTranscieverCount(I);
    GetAvailableMissiles(I);
    GetTargetingInfo(I);    
    
    missilesPerTarget=0;

    if numberOfTargets>0 then
        missilesPerTarget = missileCount / numberOfTargets;
    end
    --I:Log("Airborne missiles per target: " .. missilesPerTarget);

    if missilesPerTarget>0 then
        missilesFired = 0;
        missilesForTarget = 0;
        currentTarget = 0;
        for ii=0,transcieverCount-1,1 do
            for m=0,I:GetLuaControlledMissileCount(ii)-1,1 do
                GuideMissile(I, ii, m, currentTarget);
                missilesFired = missilesFired + 1;
                missilesForTarget = missilesForTarget + 1;
                if missilesForTarget>=missilesPerTarget then
                    if currentTarget+1<=numberOfTargets-1 then
                        missilesForTarget = 0;
                        currentTarget = currentTarget+1;
                    end
                end
            end
        end
    end
end

function GetMissileTranscieverCount(I)
    transcieverCount = I:GetLuaTransceiverCount();
    --I:Log("Missile Lua Transcievers Found: " .. transcieverCount);
end

function GetAvailableMissiles(I)
    missileCount = 0;
    for ii=0,transcieverCount-1,1 do
        missileCount = missileCount + I:GetLuaControlledMissileCount(ii);
    end
    --I:Log("Active Missiles Countrollable by Lua: " .. missileCount);
end

function GetTargetingInfo(I)
    mainframes = I:GetNumberOfMainframes();
    numberOfTargets = I:GetNumberOfTargets(activeMainframe);
    --I:Log("Number of targets for mainframe " .. activeMainframe .. ": " .. numberOfTargets);
end

function GuideMissile(I, transciever, missile, targetIndex)
    tgt = I:GetTargetInfo(activeMainframe, targetIndex);
    tgtVel = tgt.Velocity;
    pos = tgt.Position;
    msl = I:GetLuaControlledMissileInfo(transciever,missile);

    mslPos = msl.Position;
    mslVel = msl.Velocity;

    dist = Vector3(Mathf.Abs(mslPos.x-pos.x), Mathf.Abs(mslPos.y-pos.y), Mathf.Abs(mslPos.z-pos.z));
    timeOnTarget = Mathf.Abs(dist.y / -mslVel.y);
    tgtEstimate = Vector3(EstimatePosition(pos.x, timeOnTarget, tgtVel.x), EstimatePosition(pos.y, timeOnTarget, tgtVel.y), EstimatePosition(pos.z, timeOnTarget, tgtVel.z));

    if msl.TimeSinceLaunch<=ascentTime and pos.y<directHeight then
        I:SetLuaControlledMissileAimPoint(transciever, missile, pos.x, pos.y+ascentHeight, pos.z);
    end
    if msl.TimeSinceLaunch>ascentTime or pos.y>directHeight then
        I:SetLuaControlledMissileAimPoint(transciever, missile, tgtEstimate.x, tgtEstimate.y, tgtEstimate.z);
    end
end

function EstimatePosition(initial, time, velocity)
    return initial + (velocity*time);
end
