-----------------------------
-- Dr. Azzy's Merc/Homun AI
-- Written by Dr. Azzy of iRO Loki
-- Permission granted to distribute in unmodified form
-- Please contact me via the iRO Forums if you wish to modify
-- so that we can work together to extend and improve this AI.
-- Version 1.281
-- Autosac fixed
-- Skill use in manner inconsistant with tactics fixed, again
-- Various show-stopper fixes implemented, should be usable now
-----------------------------
-- require statements handled by AI_M and AI, because the variables
-- need to be defined to process the config and tactics files.
-----------------------------
require "./AI/USER_AI/Log.lua"
-----------------------------
-- state
-----------------------------
IDLE_ST					= 0
FOLLOW_ST				= 1
CHASE_ST				= 2
ATTACK_ST				= 3
MOVE_CMD_ST				= 4
STOP_CMD_ST				= 5
ATTACK_OBJECT_CMD_ST			= 6
ATTACK_AREA_CMD_ST			= 7
PATROL_CMD_ST				= 8
HOLD_CMD_ST				= 9
SKILL_OBJECT_CMD_ST			= 10
SKILL_AREA_CMD_ST			= 11
FOLLOW_CMD_ST				= 12
RANDWALK_ST				= 100
ORBITWALK_ST				= 101
REST_ST					= 102
TANKCHASE_ST				= 103
TANK_ST					= 104
PROVOKE_ST				= 105
----------------------------



------------------------------------------
-- global variable
------------------------------------------
MyState				= IDLE_ST	-- 최초의 상태는 휴식
MyEnemy				= 0		-- 적 id
MyDestX				= 0		-- 목적지 x
MyDestY				= 0		-- 목적지 y
MyPatrolX			= 0		-- 정찰 목적지 x
MyPatrolY			= 0		-- 정찰 목적지 y
ResCmdList			= List.new()	-- 예약 명령어 리스트 
MyID				= 0		-- 용병 id
MySkill				= 0		-- 용병의 스킬
MySkillLevel			= 0		-- 용병의 스킬 레벨
RandomMoveTries			= 0
--Autoskill timeout counters
QuickenTimeout			= 0
GuardTimeout			= 0
MagTimeout			= 0
SightTimeout			= 0
SkillTimeout			= 0
ProvokeOwnerTimeout		= 0
ProvokeSelfTimeout		= 0
SacrificeTimeout		= 0
AutoSkillTimeout		= 0
TankHitTimeout			= 0
ProvokeTriesTimeout		= 0
ProvokeDelayTimeout		= 0
--Advanced movement stuff
OrbitWalkStep			= 0
OrbitWalkTries			= 0
RouteWalkStep			= nil
RouteWalkDirection		= 1
KiteDestX			= 0
KiteDestY			= 0
--Other stuff
MyStart				= GetTick()
MySkillUsedCount		= 0
ChaseGiveUpCount		= 0
AttackGiveUpCount		= 0
ChaseDebuffUsed			= 0
Unreachable			= {}
FollowTryCount			= 0
FastChangeCount			= 0
MyAttackStanceX,MyAttackStanceY = 0,0
AttackDebuffUsed		= 0
NeedToDoAutoFriend		= 0
ShouldStandby			= 0
BypassKSProtect			= 0
------------------------------------------

-----------Config checking----------------

if (UseRandWalk==1 and UseOrbitWalk==1) then
	UseOrbitWalk=0
end

if (UseAutoSkill==0 and UseSkillOnly==1) then
	UseSkillOnly = 0
end

--########################################
--### Friend the merc/homun - old one  ###
--### by Misch, new one by Dr. Azzy    ###
--########################################

if (AssumeHomun==1) then
	if (NewAutoFriend==0) then
		ff = {}
		Hactors = GetActors()
		Howner  = GetV(V_OWNER,Hactors[1])
		FX = 0
		FY = 0
		OX,OY = GetV(V_POSITION,Howner)
		for i,v in ipairs(Hactors) do
			if (v ~= Howner) then
				if (IsMonster(v)==0) then
					FX,FY = GetV(V_POSITION,v)
					if (FX==OX and FY==OY and v<100000) then --is not a player
						MyFriends[v]=2
					end
				end
			end
		end
	else
		NeedToDoAutoFriend=1
		TraceAI("Setting NeedToDoAutoFriend")
	end
end


--####################################
--######## Command Processing ########
--####################################

function	OnMOVE_CMD (x,y)
	
	TraceAI ("OnMOVE_CMD")

	if ( x == MyDestX and y == MyDestY and MOTION_MOVE == GetV(V_MOTION,MyID)) then
		return		-- 현재 이동중인 목적지와 같은 곳이면 처리하지 않는다. 
	end

	local curX, curY = GetV (V_POSITION,MyID)
	if (math.abs(x-curX)+math.abs(y-curY) > 15) then		-- 목적지가 일정 거리 이상이면 (서버에서 먼거리는 처리하지 않기 때문에)
		List.pushleft (ResCmdList,{MOVE_CMD,x,y})			-- 원래 목적지로의 이동을 예약한다. 	
		x = math.floor((x+curX)/2)							-- 중간지점으로 먼저 이동한다.  
		y = math.floor((y+curY)/2)							-- 
	end

	Move (MyID,x,y)	
	
	MyState = MOVE_CMD_ST
	MyDestX = x
	MyDestY = y
	MyEnemy = 0
	MySkill = 0
	if (MirAIFriending==1) then --emulate MirAI's annoying friending process
		local actors = GetActors()
		for i,v in ipairs(actors) do
			if (IsMonster(v)~=1) then
				xx,yy=GetV(V_POSITION,v)
				if (xx==x and (yy+1==y or yy-1==y)) then
					if (MyFriends[v]==nil) then
						MyFriends[v] = 1
						FriendsFile = io.open("AI/USER_AI/A_Friends.lua", "w")
						FriendsFile:write (STRING_A_FRIENDS_HEAD)
						for k,v in pairs(MyFriends) do
							if (v==1) then
								FriendsFile:write ("MyFriends["..k.."]="..v.." -- \n")
							end
						end
						FriendsFile:close()
					elseif (MyFriends[v]~=nil) then
						MyFriends[v] = nil
						FriendsFile = io.open("AI/USER_AI/A_Friends.lua", "w")
						FriendsFile:write (STRING_A_FRIENDS_HEAD)
						for k,v in pairs(MyFriends) do
							if (v==1) then
								FriendsFile:write ("MyFriends["..k.."]="..v.." -- \n")
							end
						end
						FriendsFile:close()
					end
				end
			end
		end
	end
end


function	OnSTOP_CMD ()

	TraceAI ("OnSTOP_CMD")

	if (GetV(V_MOTION,MyID) ~= MOTION_STAND) then
		Move (MyID,GetV(V_POSITION,MyID))
	end
	MyState = IDLE_ST
	MyDestX = 0
	MyDestY = 0
	MyEnemy = 0
	MySkill = 0

end


function	OnATTACK_OBJECT_CMD (id)

	TraceAI ("OnATTACK_OBJECT_CMD")

	MySkill = 0
	MyEnemy = id
	MyState = CHASE_ST
	BypassKSProtect=1
	OnCHASE_ST()

end


function	OnATTACK_AREA_CMD (x,y)

	TraceAI ("OnATTACK_AREA_CMD")

	if (x ~= MyDestX or y ~= MyDestY or MOTION_MOVE ~= GetV(V_MOTION,MyID)) then
		Move (MyID,x,y)	
	end
	MyDestX = x
	MyDestY = y
	MyEnemy = 0
	MyState = ATTACK_AREA_CMD_ST
	
end

function	OnPATROL_CMD (x,y)

	TraceAI ("OnPATROL_CMD")

	MyPatrolX , MyPatrolY = GetV (V_POSITION,MyID)
	MyDestX = x
	MyDestY = y
	Move (MyID,x,y)
	MyState = PATROL_CMD_ST

end


function	OnHOLD_CMD ()

	TraceAI ("OnHOLD_CMD")

	MyDestX = 0
	MyDestY = 0
	MyEnemy = 0
	MyState = HOLD_CMD_ST

end


function	OnSKILL_OBJECT_CMD (level,skill,id)

	TraceAI ("OnSKILL_OBJECT_CMD"..skill.." "..id.." "..level)
	if IsMonster(id)==1 then
		MySkillLevel = level
		MySkill = skill
		MyEnemy = id
		MyState = CHASE_ST
		BypassKSProtect=1
	else
		SkillObject(MyID,level,skill,id)
	end

end


function	OnSKILL_AREA_CMD (level,skill,x,y)

	TraceAI ("OnSKILL_AREA_CMD")

	Move (MyID,x,y)
	MyDestX = x
	MyDestY = y
	MySkillLevel = level
	MySkill = skill
	MyState = SKILL_AREA_CMD_ST
	
end

function	OnFOLLOW_CMD ()

	-- 대기명령은 대기상태와 휴식상태를 서로 전환시킨다. 
	if (MyState ~= FOLLOW_CMD_ST) then
		if StickyStandby == 1 then
			ShouldStandby=1
		end
		BetterMoveToOwner (MyID,FollowStayBack)
		MyState = FOLLOW_CMD_ST
		MyEnemy = 0 
		MySkill = 0
		TraceAI ("OnFOLLOW_CMD")
	else
		if StickyStandby == 1 then
			ShouldStandby=0
		end
		MyState = IDLE_ST
		MyEnemy = 0 
		MySkill = 0
		TraceAI ("FOLLOW_CMD_ST --> IDLE_ST")
	end

end




function	ProcessCommand (msg)

	if	(msg[1] == MOVE_CMD) then
		OnMOVE_CMD (msg[2],msg[3])
		TraceAI ("MOVE_CMD")
	elseif	(msg[1] == STOP_CMD) then
		OnSTOP_CMD ()
		TraceAI ("STOP_CMD")
	elseif	(msg[1] == ATTACK_OBJECT_CMD) then
		OnATTACK_OBJECT_CMD (msg[2])
		TraceAI ("ATTACK_OBJECT_CMD")
	elseif	(msg[1] == ATTACK_AREA_CMD) then
		OnATTACK_AREA_CMD (msg[2],msg[3])
		TraceAI ("ATTACK_AREA_CMD")
	elseif	(msg[1] == PATROL_CMD) then
		OnPATROL_CMD (msg[2],msg[3])
		TraceAI ("PATROL_CMD")
	elseif	(msg[1] == HOLD_CMD) then
		OnHOLD_CMD ()
		TraceAI ("HOLD_CMD")
	elseif	(msg[1] == SKILL_OBJECT_CMD) then
		OnSKILL_OBJECT_CMD (msg[2],msg[3],msg[4],msg[5])
		TraceAI ("SKILL_OBJECT_CMD")
	elseif	(msg[1] == SKILL_AREA_CMD) then
		OnSKILL_AREA_CMD (msg[2],msg[3],msg[4],msg[5])
		TraceAI ("SKILL_AREA_CMD")
	elseif	(msg[1] == FOLLOW_CMD) then
		OnFOLLOW_CMD ()
		TraceAI ("FOLLOW_CMD")
	end
end



--###############################
--######## State Process ########
--###############################

function	OnIDLE_ST ()
	
	TraceAI ("OnIDLE_ST")
	MySkillUsedCount		= 0
	ChaseGiveUpCount		= 0
	AttackGiveUpCount		= 0
	ChaseDebuffUsed			= 0
	AttackDebuffUsed		= 0
	BypassKSProtect			= 0
	if (DoIdleTasks()==nil) then
		return
	end
	if (ShouldStandby==1 and StickyStandby==1) then
		MyState=FOLLOW_CMD_ST
		return
	end
	local	object = GetOwnerEnemy (MyID)
	if (object ~= 0) then							-- MYOWNER_ATTACKED_IN
		MyState = CHASE_ST
		MyEnemy = object
		TraceAI ("IDLE_ST -> CHASE_ST : MYOWNER_ATTACKED_IN")
		if (FastChangeCount < FastChangeLimit and FastChange_I2C ==1) then
			OnCHASE_ST()
		end
		return 
	end
	object = GetMyEnemy (MyID)
	if (object ~= 0) then							-- ATTACKED_IN
		MyState = CHASE_ST
		MyEnemy = object
		TraceAI ("IDLE_ST -> CHASE_ST : ATTACKED_IN")
		if (FastChangeCount < FastChangeLimit and FastChange_I2C ==1) then
			OnCHASE_ST()
		end
		return
	end
	object = GetTankEnemy(MyID)
	if (object ~= 0) then
		MyState = TANKCHASE_ST
		MyEnemy = object
		TraceAI ("IDLE_ST -> TANKCHASE_ST")
		return
	end
	
	local distance = GetDistanceFromOwner(MyID)
	if (UseRandWalk==1 or UseOrbitWalk==1 or UseRouteWalk == 1) then
		if ( distance > MoveBounds or distance == -1) then		-- MYOWNER_OUTSIGNT_IN
			MyState = FOLLOW_ST
			TraceAI ("IDLE_ST -> FOLLOW_ST")
			return
		end
	elseif ( distance > DiagonalDist(FollowStayBack+1) or distance == -1) then		-- MYOWNER_OUTSIGNT_IN
		MyState = FOLLOW_ST
		OnFOLLOW_ST()
		TraceAI ("IDLE_ST -> FOLLOW_ST")
		return
	end
	local owner=GetV(V_OWNER,MyID)
	local ownermotion=GetV(V_MOTION,owner)
	if (distance < 2 and ownermotion == MOTION_STAND and (UseRandWalk==1 or UseRouteWalk==1) and HPPercent(MyID) > AggroHP) then
		DoRandomMove()
		return
	end
	if (ownermotion==0 and GetV(V_MOTION,MyID)==0 and UseOrbitWalk > 0) then
		MyState=ORBITWALK_ST
		OrbitWalkStep=0
		return
	end

end

function	OnFOLLOW_ST ()

	TraceAI ("OnFOLLOW_ST")

	if (GetDistanceFromOwner(MyID) <= DiagonalDist(FollowStayBack+1)) then		--  DESTINATION_ARRIVED_IN 
		FollowTryCount=0
		MyState = IDLE_ST
		TraceAI ("FOLLOW_ST -> IDLE_ST")
		if (FastChangeCount < FastChangeLimit and FastChange_F2I==1) then
			FastChangeCount = FastChangeCount+1
			OnIDLE_ST()
		end
		return
	else
		if (FollowTryCount > FollowTryPanic and GetV(V_MOTION,MyID)~=MOTION_MOVE) then
			BetterMoveToOwner (MyID,0)
		else
			BetterMoveToOwner (MyID,FollowStayBack)
			if (GetV(V_MOTION,MyID) ~= MOTION_MOVE) then
				FollowTryCount=FollowTryCount+1
			else
				FollowTryCount=0
			end
		end
		TraceAI ("FOLLOW_ST -> FOLLOW_ST")
		return
	end

end


function	OnCHASE_ST ()
	MyAttackStanceX,MyAttackStanceY = 0,0
	TraceAI ("OnCHASE_ST")
	if (UseSkillOnly==1) then
		skill,level,sp,delay=GetAtkSkill(MyID)
	else if (UseSkillOnly==-1) then
		skill,level,sp,delay=GetAtkSkill(MyID)
		if (GetV(V_SP,MyID)-UseAutoSkill_MinSP < sp) then
			skill,level,sp=nil,nil,nil
		end
	else
		skill=nil
	end
	if(IsNotKS(MyID,MyEnemy)==0) then
		MyState = IDLE_ST
		MyEnemy = 0
		MyDestX, MyDestY = 0,0
		TraceAI ("CHASE_ST -> IDLE_ST : Enemy is taken")
		if (FastChangeCount < FastChangeLimit and FastChange_C2I == 1) then
			FastChangeCount = FastChangeCount+1
			OnIDLE_ST()
		end
	end
	if (true == IsOutOfSight(MyID,MyEnemy) or (ChaseGiveUpCount > ChaseGiveUp and GetV(V_MOTION,MyID)~=MOTION_MOVE)) then	-- ENEMY_OUTSIGHT_IN
		MyState = IDLE_ST
		MyEnemy = 0
		MyDestX, MyDestY = 0,0
		TraceAI ("CHASE_ST -> IDLE_ST : ENEMY_OUTSIGHT_IN")
		ChaseGiveUpCount=0
		
		if (FastChangeCount < FastChangeLimit and FastChange_C2I == 1) then
			OnIDLE_ST()
		end
		return
	end
	if (true == IsInAttackSight(MyID,MyEnemy,skill)) then  -- ENEMY_INATTACKSIGHT_IN
		if(UseSkillOnly ~=-1 or IsInAttackSight(MyID,MyEnemy)==true) then
			MyState = ATTACK_ST
			ChaseGiveUpCount=0
			MySkillUsedCount=0
			TraceAI ("CHASE_ST -> ATTACK_ST : ENEMY_INATTACKSIGHT_IN")
			if (FastChangeCount < FastChangeLimit and FastChange_C2A == 1) then
				FastChangeCount = FastChangeCount+1
				OnATTACK_ST()
			end
			return
		else
			TraceAI("Can we skill while chasing")
			if (GetV(V_SP,MyID) >= sp+UseAutoSkill_MinSP and AutoSkillTimeout < GetTick()) then
				TraceAI("Yes, attempting skill while chasing")
				tact_skill=GetTact(TACT_SKILL,MyEnemy)
				if (tact_skill < 0) then
					skill_level=tact_skill*-1
					tact_skill=1
				else
					skill_level=level
				end
				TraceAI("Skill"..skill.."level"..skill_level)
				if (tact_skill ~=SKILL_NEVER) then
					TraceAI("UsingSkillNow")
					SkillObject(MyID,skill_level,skill,MyEnemy)
					MySkillUsedCount=1
					AutoSkillTimeout=GetTick() + 400 + delay
				else
					TraceAI ("set to not skill on this monster")
				end
			else
				TraceAI("No, we cant skill while chasing - timeout not OK or no SP"..AutoSkillTimeout.." "..GetTick())
			end
		end
	end
	debuff=GetTact(TACT_DEBUFF,MyEnemy)
	if (debuff<0 and ChaseDebuffUsed==0) then
		debuff=-1*debuff
		local skill,level,sp,target = GetDebuffSkill(MyID)
		if (debuff==skill or (skill ~=0 and debuff == 1)) then
			if (GetV(V_SP,MyID) >= sp+UseAutoSkill_MinSP and IsInAttackSight(MyID,MyEnemy,skill)) then
				ChaseDebuffUsed=1
				if (target ==1) then
					SkillObject(MyID,level,skill,MyEnemy)
				else
					x,y=GetV(V_POSITION,MyEnemy)
					SkillGround(MyID,level,skill,x,y)
				end
				TraceAI("Using skill "..skill.." on target "..MyEnemy.." while chasing")
			end
		end
	end
	ChaseGiveUpCount=ChaseGiveUpCount+1
	MyDestX, MyDestY = ClosestR (MyID,MyEnemy,AttackRange(MyID,MySkill))
	if (DoNotChase~=1) then
		Move (MyID,MyDestX,MyDestY)
		TraceAI ("CHASE_ST -> CHASE_ST : DESTCHANGED_IN"..MyDestX.." "..MyDestY)
	end
	return
end
end




function	OnATTACK_ST ()

	TraceAI ("OnATTACK_ST")		
	if (UseSkillOnly==1) then
		skill=GetAtkSkill(MyID)
	elseif (UseSkillOnly==-1) then
		s,l,sp=GetAtkSkill(MyID)
		if (GetV(V_SP,MyID)-UseAutoSkill_MinSP > sp) then
			skill=s
		else
			skill=nil
		end
	else
		skill=nil
	end
	if (true == IsOutOfSight(MyID,MyEnemy) or (AttackGiveUpCount > AttackGiveUp and GetV(V_MOTION,MyID)==MOTION_STAND)) then	-- ENEMY_OUTSIGHT_IN
		if (AttackGiveUpCount > AttackGiveUp) then
			Unreachable[MyEnemy]=1
		end
		MyState = IDLE_ST
		MyEnemy = 0
		MySkillUseCount= 0
		TraceAI ("ATTACK_ST -> IDLE_ST")
		if (FastChangeCount < FastChangeLimit and FastChange_A2I == 1) then
			FastChangeCount = FastChangeCount+1
			OnIDLE_ST()
		end
		return 
	end

	if (MOTION_DEAD == GetV(V_MOTION,MyEnemy)) then   -- ENEMY_DEAD_IN
		MyState = IDLE_ST
		MyEnemy = 0
		MySkillUseCount= 0
		TraceAI ("ATTACK_ST -> IDLE_ST  Enemy dead")
		if (FastChangeCount < FastChangeLimit and FastChange_A2I == 1) then
			FastChangeCount = FastChangeCount+1
			OnIDLE_ST()
		end
		return
	end
	if (false == IsInAttackSight(MyID,MyEnemy,skill)) then  -- ENEMY_OUTATTACKSIGHT_IN
		MyState = CHASE_ST
		TraceAI ("ATTACK_ST -> CHASE_ST  : ENEMY_OUTATTACKSIGHT_IN")
		if (FastChangeCount < FastChangeLimit and FastChange_A2C == 1) then
			FastChangeCount = FastChangeCount+1
			OnCHASE_ST()
			
		end
		return
	end
	if (MyAttackStanceX==0) then
		MyAttackStanceX,MyAttackStanceY=GetV(V_POSITION,MyID)
	end
	if (UseAutoPushback > 0) then
		if DoAutoPushback(MyID)  == nil then
			return
		end
	end

---##################################################################################---
	local tact_skill,tact_debuff=GetTact(TACT_SKILL,MyEnemy),GetTact(TACT_DEBUFF,MyEnemy)
	local skill_level
	-- Begin skill selection shit
	if (IsHomun(MyID)==1) then
		local skill,level,sp,targetmode,delay=GetAtkSkill(MyID)
		if ((GetV(V_SP,MyID) >= UseAutoSkill_MinSP+sp) and (GetTick() >= AutoSkillTimeout)) then
			target,level2=GetSnipeEnemy(MyID)
			if (target~=0) then
				SkillObject(MyID,level2,skill,target)
				AutoSkillTimeout=GetTick()+delay+AutoSkillDelay
				return
			end
		end
	end
	if (MySkill==0 and UseAutoSkill == 1 and GetTick() >= AutoSkillTimeout) then	
		if (tact_skill < 0) then		-- Negative value of TACT_SKILL -> 1 cast of skill
			skill_level=tact_skill*-1	-- with level = to the absolute value of the
			tact_skill=1			-- value of TACT_SKILL.
		else
			skill_level=nil
		end
		local SkillList=GetTargetedSkills(MyID)
		local mobcount,aggrocount=GetMobCount(MyID,2,GetV(V_OWNER,MyID))
		local skilltouse = {-1,0,0,0}
		TraceAI("Begin autoskill routine")
		for i,v in SkillList do
			skilltype=v[1]
			if v[2]~=0 then
				TraceAI("skilltype ".. skilltype.." MySkillUsedCount "..MySkillUsedCount.." tact_skill ".. tact_skill.."v"..v[1].." "..v[2].." "..v[3].." "..v[4])
				if (skilltype == MOB_ATK and (MySkillUsedCount < tact_skill or tact_skill==SKILL_ALWAYS)) then
					if (mobcount >= AutoMobCount) then
						if (GetV(V_SP,MyID) >= (UseAutoSkill_MinSP+v[4])) then
							if (skilltouse[1] < 2) then
								skilltouse=v
							end
						end
					end
				elseif (skilltype ==DEBUFF_ATK and AttackDebuffUsed < AttackDebuffLimit) then
					if (tact_debuff == v[2] or (tact_debuff==1 and BasicDebuffs[v[2]]~=nil)) then
						if (GetV(V_SP,MyID) >= (UseAutoSkill_MinSP+v[4])) then
							skilltouse=v
						end
					end
				elseif (skilltype==MAIN_ATK and (MySkillUsedCount < tact_skill or tact_skill==SKILL_ALWAYS)) then
					if (GetV(V_SP,MyID) >= (UseAutoSkill_MinSP+v[4])) then
						if (v[2]~=ML_PIERCE or (GetTact(TACT_SIZE,MyEnemy)==SIZE_UNDEFINED or GetTact(TACT_SIZE,MyEnemy) >= UsePierceSize)) then
							skilltouse=v
						end
					end
				end
			end
		end
		-- Now we finalize the selection
		if skilltouse[1]~= -1 then
			MySkill=skilltouse[2]
			if (IsHomun(MyID)==1 and skill_level~=nil) then 	--no need to check what skill
				MySkillLevel=skill_level		--Only homuns can use non-max level
			else						--and they dont have any mob/debuffs
				MySkillLevel=skilltouse[3]
			end
			if (skilltouse[1] == DEBUFF_ATK) then
				AttackDebuffUsed=AttackDebuffUsed+1
			else
				MySkillUsedCount=MySkillUsedCount+1
			end
			AutoSkillTimeout=GetTick() + 400 + skilltouse[5]
		end
		
	end
	
	-- Now we resolve it
	
	--if (MySkill == 0) then
	if (UseSkillOnly ~= 1) then
		Attack (MyID,MyEnemy)
		TraceAI("Normal attack vs: "..MyEnemy)
	end
	-- else
	if (MySkill ~=0) then
		TraceAI("Skill Attack: "..MySkill.." target: "..MyEnemy)
		DoSkill(MySkill,MySkillLevel,MyEnemy)
	end
	if (UseDanceAttack==1 and ((IsHomun(MyID)==1 and MySkill==0) or(IsHomun(MyID)==0 and MySkill~=0))) then
		nx,ny=GetDanceCell(MyAttackStanceX,MyAttackStanceY,MyEnemy)
		Move(MyID,nx,ny)
		Move(MyID,MyAttackStanceX,MyAttackStanceY)
	end
	MySkill = 0
	MySkillLevel=0
end

-------------------
-- TANK ROUTINES --
-------------------

function	OnTANKCHASE_ST ()

	TraceAI ("OnTANKCHASE_ST")
	if (true == IsOutOfSight(MyID,MyEnemy) or (ChaseGiveUpCount > ChaseGiveUp and GetV(V_MOTION,MyID)~=MOTION_MOVE)) then	-- ENEMY_OUTSIGHT_IN
		if (ChaseGiveUpCount>ChaseGiveUp) then
			Unreachable[MyEnemy]=1
		end
		MyState = IDLE_ST
		MyEnemy = 0
		MyDestX, MyDestY = 0,0
		TraceAI ("CHASE_ST -> IDLE_ST : ENEMY_OUTSIGHT_IN")
		ChaseGiveUpCount=0
		
		return
	end
	if (true == IsInAttackSight(MyID,MyEnemy,skill)) then  -- ENEMY_INATTACKSIGHT_IN
		ChaseGiveUpCount=0
		if(IsNotKS(MyID,MyEnemy)==1) then
			MyState = TANK_ST
			MySkillUsedCount=0
			OnTANK_ST()
			TraceAI ("TANKCHASE_ST -> TANK_ST : ENEMY_INATTACKSIGHT_IN")
		else
			MyState = IDLE_ST
			MyEnemy = 0
			MyDestX, MyDestY = 0,0
			TraceAI ("TANKCHASE_ST -> IDLE_ST : Enemy is taken")
		end
		
		return
	end
	debuff=GetTact(TACT_DEBUFF,MyEnemy)
	if (debuff<0 and ChaseDebuffUsed==0) then
		debuff=-1*debuff
		local skill,level,sp,target = GetDebuffSkill(MyID)
		if (debuff==skill or (skill ~=0 and debuff == 1)) then
			if (GetV(V_SP,MyID) >= sp+UseAutoSkill_MinSP and IsInAttackSight(MyID,MyEnemy,skill)) then
				ChaseDebuffUsed=1
				if (target ==1) then
					SkillObject(MyID,level,skill,MyEnemy)
				else
					x,y=GetV(V_POSITION,MyEnemy)
					SkillGround(MyID,level,skill,x,y)
				end
				TraceAI("Using skill "..skill.." on target "..MyEnemy.." while chasing to tank")
			end
		end
	end
	ChaseGiveUpCount=ChaseGiveUpCount+1
	MyDestX, MyDestY = ClosestR (MyID,MyEnemy,AttackRange(MyID,MySkill))
	if (DoNotChase~=1) then
		Move (MyID,MyDestX,MyDestY)
		TraceAI ("TANKCHASE_ST -> TANKCHASE_ST : DESTCHANGED_IN"..MyDestX.." "..MyDestY)
	end
	return
end

function OnTANK_ST()
	if (GetV(V_MOTION,MyEnemy)==MOTIONDEAD or IsOutOfSight(MyID,MyEnemy)) then
		MyState=IDLE_ST
		TraceAI("TANK_ST->IDLE_ST - Target dead or out of sight")
		return
	end
	if (GetV(V_TARGET,MyEnemy)~=MyID and (TankHitTimeout + 1500) < GetTick()) then
		TankHitTimeout = GetTick()
		if (IsInAttackSight(MyID,MyEnemy)==true) then
			Attack(MyID,MyEnemy)
		else
			MyState=TANKCHASE_ST
			TraceAI("TANK_ST->TANKCHASE_ST - Target out of range")
		end
		return
	end
end

function	OnREST_ST ()
	TraceAI("OnREST_ST")
	if (DoIdleTasks()==nil) then
		return
	end
	local	object = GetOwnerEnemy (MyID)
	if (object ~= 0) then		--Check for monsters attacking owner
		MyState = CHASE_ST
		MyEnemy = object
		TraceAI ("REST_ST -> CHASE_ST : MYOWNER_ATTACKED_IN")
		return 
	end
	object = GetMyEnemy (MyID) 	--Note that GetMyEnemy() is smart enough to use non-aggro
	if (object ~= 0) then		--targeting function when the mercenary is in REST_ST
		MyState = CHASE_ST
		MyEnemy = object
		TraceAI ("REST_ST -> CHASE_ST : ATTACKED_IN")
		return
	end
	
	--If theres nothing else to do, return to the "rest station"
	
	x,y=GetV(V_POSITION,MyID)
	ox,oy=GetV(V_POSITION,GetV(V_OWNER,MyID))
	xoff=ox-x
	yoff=oy-y
	TraceAI(xoff.." "..ox.." "..x)
	if (xoff~=RestXOff or yoff~=RestYOff) then
		MyDestX=ox+RestXOff
		MyDestY=oy+RestYOff
		Move(MyID,MyDestX,MyDestY)
	else
		MyDestX,MyDestY=0,0
	end
	if (GetV(V_MOTION,GetV(V_OWNER,MyID))~=MOTION_SIT) then
		MyState=IDLE_ST
		TraceAI("REST_ST -> IDLE_ST: Owner stood up")
	end
end



-------------------
--Command State Process
-------------------

function	OnMOVE_CMD_ST ()

	TraceAI ("OnMOVE_CMD_ST")

	local x, y = GetV (V_POSITION,MyID)
	if (x == MyDestX and y == MyDestY) then				-- DESTINATION_ARRIVED_IN
		MyState = IDLE_ST
	end
end


function OnSTOP_CMD_ST ()


end




function OnATTACK_OBJECT_CMD_ST ()

	

end


function OnATTACK_AREA_CMD_ST ()

	TraceAI ("OnATTACK_AREA_CMD_ST")

	local	object = GetOwnerEnemy (MyID)
	if (object == 0) then							
		object = GetMyEnemy (MyID) 
	end

	if (object ~= 0) then							-- MYOWNER_ATTACKED_IN or ATTACKED_IN
		MyState = CHASE_ST
		MyEnemy = object
		return
	end

	local x , y = GetV (V_POSITION,MyID)
	if (x == MyDestX and y == MyDestY) then			-- DESTARRIVED_IN
			MyState = IDLE_ST
	end

end




function OnPATROL_CMD_ST ()

	TraceAI ("OnPATROL_CMD_ST")

	local	object = GetOwnerEnemy (MyID)
	if (object == 0) then							
		object = GetMyEnemy (MyID) 
	end

	if (object ~= 0) then							-- MYOWNER_ATTACKED_IN or ATTACKED_IN
		MyState = CHASE_ST
		MyEnemy = object
		TraceAI ("PATROL_CMD_ST -> CHASE_ST : ATTACKED_IN")
		return
	end

	local x , y = GetV (V_POSITION,MyID)
	if (x == MyDestX and y == MyDestY) then			-- DESTARRIVED_IN
		MyDestX = MyPatrolX
		MyDestY = MyPatrolY
		MyPatrolX = x
		MyPatrolY = y
		Move (MyID,MyDestX,MyDestY)
	end

end


-----------------------------------------------------------------------
--IF ANYONE READING MY CODE HAS A FUCK'S CLUE WHAT THE HOLD COMMAND IS
--OR WHAT IN THE DEVIL IT'S PURPOSE IS, PLEASE ENLIGHTEN ME! -Azzy 
----------------------------------------------------------------------

function OnHOLD_CMD_ST () 

	TraceAI ("OnHOLD_CMD_ST")
	
	if (MyEnemy ~= 0) then
		local d = GetDistance(MyEnemy,MyID)
		if (d ~= -1 and d <= GetV(V_ATTACKRANGE,MyID)) then
				Attack (MyID,MyEnemy)
		else
			MyEnemy = 0;
		end
		return
	end


	local	object = GetOwnerEnemy (MyID)
	if (object == 0) then							
		object = GetMyEnemy (MyID)
		if (object == 0) then						
			return
		end
	end

	MyEnemy = object

end




function OnSKILL_OBJECT_CMD_ST ()
	
end




function OnSKILL_AREA_CMD_ST ()

	TraceAI ("OnSKILL_AREA_CMD_ST")

	local x , y = GetV (V_POSITION,MyID)
	if (GetDistance(x,y,MyDestX,MyDestY) <= GetV(V_SKILLATTACKRANGE,MyID,MySkill)) then	-- DESTARRIVED_IN
		SkillGround (MyID,MySkillLevel,MySkill,MyDestX,MyDestY)
		MyState = IDLE_ST
		MySkill = 0
	end

end







function OnFOLLOW_CMD_ST ()
	TraceAI ("OnFOLLOW_CMD_ST")
	local d = GetDistance2 (GetV(V_OWNER,MyID),MyID)
	if ( d > FollowStayBack) then
		BetterMoveToOwner (MyID,FollowStayBack)
		return
	end
	-- Start the friending process
	if (StandbyFriending == 1) then
		local actors = GetActors()
		for i,v in ipairs(actors) do
			if (IsMonster(v)~=1 and GetV(V_MOTION,GetV(V_OWNER,MyID))==MOTION_SIT) then
				if (IsToRight(GetV(V_OWNER,MyID),v)==1) then
					if (MyFriends[v]==nil) then
						MyFriends[v] = 1
						FriendsFile = io.open("AI/USER_AI/A_Friends.lua", "w")
						FriendsFile:write (STRING_A_FRIENDS_HEAD)
						for k,v in pairs(MyFriends) do
							if (v==1) then
								FriendsFile:write ("MyFriends["..k.."]="..v.." -- \n")
							end
						end
						FriendsFile:close()
					end
				elseif (IsToRight(v,GetV(V_OWNER,MyID))==1) then
					if (MyFriends[v]~=nil) then
						MyFriends[v] = nil
						FriendsFile = io.open("AI/USER_AI/A_Friends.lua", "w")
						FriendsFile:write (STRING_A_FRIENDS_HEAD)
						for k,v in pairs(MyFriends) do
							if (v==1) then
								FriendsFile:write ("MyFriends["..k.."]="..v.." -- \n")
							end
						end
						FriendsFile:close()
					end
				end
			end
		end
        end
        -- Okay, that's done. 
        if (DefendStandby == 1) then
		local	object = GetOwnerEnemy (MyID)
		if (object ~= 0) then							-- MYOWNER_ATTACKED_IN
			MyState = CHASE_ST
			MyEnemy = object
			TraceAI ("IDLE_ST -> CHASE_ST : MYOWNER_ATTACKED_IN")
			if (FastChangeCount < FastChangeLimit and FastChange_I2C ==1) then
				OnCHASE_ST()
			end
			return 
		end
		object = GetMyEnemyA (MyID)
		if (object ~= 0) then							-- ATTACKED_IN
			MyState = CHASE_ST
			MyEnemy = object
			TraceAI ("IDLE_ST -> CHASE_ST : ATTACKED_IN")
			if (FastChangeCount < FastChangeLimit and FastChange_I2C ==1) then
				OnCHASE_ST()
			end
			return
		end
	end
end


--#####################################
--### Targeting Routines start here ###
--#####################################

-----------------
--GetOwnerEnemy
-----------------

function	GetOwnerEnemy (myid)
	local result = 0
	local owner  = GetV (V_OWNER,myid)
	local actors = GetActors ()
	local enemys = {}
	local index = 1
	local target
	if (SuperPassive==1) then
		return 0
	end
	local friendtargets=GetFriendTargets()
	for i,v in ipairs(actors) do
		motion = GetV(V_MOTION,v)
		if (IsFriendOrSelf(v)==0 and v ~= 0 and IsMonster(v)==1 and motion ~=MOTION_DEAD) then
			if (friendtargets[v]==1 and (IsPlayer(v)==0 or (PVPmode ~= 0 and IsPVPFriend(v)==0))) then 
				TraceAI("Friend targeting"..v)
				enemys[index] = v
				index = index+1
			else
				target = GetV (V_TARGET,v)
				casttact = GetTact(TACT_CAST,v)
				if (IsFriend(target)==1 and ((motion==MOTION_ATTACK or motion == MOTION_ATTACK2) or casttact == CAST_REACT)) then
					if (IsPlayer(v) == 0) then
						tact=GetTact(TACT_BASIC,v)
						TraceAI("PVM friend target"..v)
						if (tact > 1 and tact ~=9) then
							enemys[index] = v
							index = index+1
						end
					elseif (PVPmode~=0) then
						tact=GetTact(TACT_BASIC,v)
						if (tact > 1 and tact ~=9) then
							TraceAI("PVP friend target:"..v.." targettarget:"..target.."motion:"..motion.."CastTact: "..casttact.."tact"..tact)
							enemys[index] = v
							index = index+1
						end
					end
				end
			end
		end
	end
	local min_priority=2
	local priority
	local min_dis = 100
	local dis
	local min_aggro = 0
	local aggro
	for i,v in ipairs(enemys) do
		if (IsFriendOrSelf(GetV(V_TARGET,v)) == 1) then
			aggro=1
		else
			aggro=0
		end
		dis = GetDistance2 (myid,v)
		priority=GetTact(TACT_BASIC,v)
		if (aggro >= min_aggro) then
			min_aggro=aggro
			if (priority >= min_priority) then
				min_priority=priority
				if (dis < min_dis and Unreachable[v]~=1) then
					result = v
					min_dis = dis
				end
			end
		end
	end
	TraceAI("Owner/ally enemy chosen: "..result)
	return result
end




function	GetMyEnemy (myid)
	local result = 0
	local hpperc =HPPercent(myid)
	local spperc =SPPercent(myid)
	if (SuperPassive==1) then
		result=0
	elseif (hpperc > AggroHP and spperc > AggroSP and MyState~=REST_ST) then
		result = GetMyEnemyB (myid)
	else
		result = GetMyEnemyA (myid)
	end
	return result
end




-------------------------------------------
--  비선공형 GetMyEnemy
-------------------------------------------
function	GetMyEnemyA (myid)
	local result = 0
	local owner  = GetV (V_OWNER,myid)
	local actors = GetActors ()
	local enemys = {}
	local index = 1
	local target
	for i,v in ipairs(actors) do
		if (IsFriendOrSelf(v)==0 and v ~= 0 and IsMonster(v)==1) then
			target = GetV (V_TARGET,v)
			motion = GetV (V_MOTION,v)
			casttact = GetTact(TACT_CAST,v)
			if ((target == myid and ((motion==MOTION_ATTACK or motion == MOTION_ATTACK2) or casttact == CAST_REACT ))) then
				tact=GetTact(TACT_BASIC,v)
				if(tact > 1 and GetV(V_MOTION,target)~=MOTION_DEAD) then
					enemys[index] = v
					index = index+1
				end
			end
		end
	end
	local min_priority=2
	local priority
	local min_dis = 100
	local dis
	local min_aggro = 0
	local aggro
	for i,v in ipairs(enemys) do
		priority=GetTact(TACT_BASIC,v)
		if (IsFriendOrSelf(GetV(V_TARGET,v)) == 1 and (priority ~=2 and priority ~=5)) then
			aggro=1
		else
			aggro=0
		end
		dis = GetDistance2 (myid,v)
		if (aggro >= min_aggro) then
			min_aggro=aggro
			if (priority >= min_priority) then
				min_priority=priority
				if (dis < min_dis and Unreachable[v]~=1) then
					result = v
					min_dis = dis
				end
			end
		end
	end
	return result
end






-------------------------------------------
--  Aggro GetMyEnemy
-------------------------------------------

function	GetMyEnemyB (myid)
	local result = 0
	local owner  = GetV (V_OWNER,myid)
	local actors = GetActors ()
	local enemys = {}
	local index = 1
	local type
	for i,v in ipairs(actors) do
		if (IsFriendOrSelf(v)==0 and v ~= 0) then
			if (1 == IsMonster(v)) then
				target = GetV(V_TARGET,v)
				tact = GetTact(TACT_BASIC,v)
				motion = GetV(V_MOTION,v)
				if(0 < tact and ((tact < 5 or tact > 9) or (IsFriendOrSelf(target)==1) and ((motion==MOTION_ATTACK or motion == MOTION_ATTACK2) or casttact == CAST_REACT))) then
					if (IsNotKS(myid,v)==1 and GetV(V_MOTION,target)~=MOTION_DEAD) then
						if (GetDistance2(owner,v) <= AggroDist) then
							TraceAI("Adding to target list: "..v)
							enemys[index] = v
							index = index+1
						end
					end
				end
			end
		end
	end

	local min_priority=2
	local priority
	local min_dis = 100
	local dis
	local min_aggro = 0
	local aggro = 0
	for i,v in ipairs(enemys) do
		priority=GetTact(TACT_BASIC,v)
		if (IsFriendOrSelf(GetV(V_TARGET,v)) == 1 and (priority ~=2 and priority ~=5)) then
			aggro=1
		else
			aggro=0
		end
		dis = GetDistance2 (myid,v)
		if (aggro >= min_aggro) then
			min_aggro=aggro
			if (priority >= min_priority) then
				min_priority=priority
				if (dis < min_dis and Unreachable[v]~=1) then
					result = v
					min_dis = dis
				end
			end
		end
	end
	TraceAI("Returning target "..result)

	return result
end

--###########################################

function	GetSnipeEnemy (myid)
	TraceAI("GetSnipeEnemy")
	local result = 0
	local owner  = GetV (V_OWNER,myid)
	local actors = GetActors ()
	local enemys = {}
	local index = 1
	local type
	for i,v in ipairs(actors) do
		if (IsFriendOrSelf(v)==0 and v ~= 0) then
			if (1 == IsMonster(v)) then
				target = GetV(V_TARGET,v)
				tact = GetTact(TACT_BASIC,v)
				motion = GetV(V_MOTION,v)
				if(tact > 9) then
					if (IsNotKS(myid,v)==1 and GetV(V_MOTION,target)~=MOTION_DEAD) then
						TraceAI("Adding to target list: "..v)
						enemys[index] = v
						index = index+1
					end
				end
			end
		end
	end

	local min_priority=2
	local priority
	local min_dis = 100
	local dis
	local min_aggro = 0
	local aggro = 0
	for i,v in ipairs(enemys) do
		priority=GetTact(TACT_BASIC,v)
		if (IsFriendOrSelf(GetV(V_TARGET,v)) == 1 and (priority ~=2 and priority ~=5)) then
			aggro=1
		else
			aggro=0
		end
		dis = GetDistance2 (myid,v)
		if (aggro >= min_aggro and v~=MyEnemy) then
			min_aggro=aggro
			if (priority >= min_priority) then
				min_priority=priority
				if (dis < min_dis and Unreachable[v]~=1) then
					result = v
					min_dis = dis
				end
			end
		end
	end
	level = GetTact(TACT_SKILL,result)
	if level < 0 then
		level=-1*level
		if level > 5 then
			level = 5
		end
	end
	TraceAI("Returning target "..result.."skilllevel"..level)
	return result,level
end


--###########################################


function GetTankEnemy(myid)
	local result = 0
	local owner  = GetV (V_OWNER,myid)
	local actors = GetActors ()
	local enemys = {}
	local index = 1
	if (SuperPassive==1 or HPPercent(myid) < AggroHP) then
		return 0
	end
	local type
	for i,v in ipairs(actors) do
		if (IsFriendOrSelf(v)==0 and v ~= 0) then
			if (1 == IsMonster(v)) then
				target = GetV(V_TARGET,v)
				tact = GetTact(TACT_BASIC,v)
				if(tact==-1) then
					if(IsNotKS(myid,v)==1) then
						TraceAI("Adding to tank target list: "..v)
						enemys[index] = v
						index = index+1
					end
				end
			end
		end
	end
	local min_dis = 100
	local dis
	for i,v in ipairs(enemys) do
		dis = GetDistance2 (myid,v)
		if (dis < min_dis and Unreachable[v]~=1) then
			result = v
			min_dis = dis
		end
	end
	return result
end

function GetRescueEnemy(myid)	
	local result = 0
	local owner  = GetV (V_OWNER,myid)
	local actors = GetActors ()
	local enemys = {}
	local index = 1
	local target
	if (SuperPassive==1) then
		return 0
	end
	for i,v in ipairs(actors) do
		if (IsFriendOrSelf(v)==0 and v ~= 0) then
			target = GetV (V_TARGET,v)
			motion = GetV(V_MOTION,v)
			casttact = GetTact(TACT_CAST,v)
			if (IsFriend(target)==1 and ((motion==MOTION_ATTACK or motion == MOTION_ATTACK2) or casttact == CAST_REACT)) then
				if (IsMonster(v) == 1) then
					tact=GetTact(TACT_RESCUE,v)
					friend=MyFriends[target]
					if (friend==nil) then	--FIX THIS LATER!
						friend=0	--Should use function call!
					end
					if (tact >= friend and friend ~=0) then
						enemys[index] = v
						index = index+1
					end
				end
			end
		end
	end
	local min_priority=2
	local priority
	local min_dis = 100
	local dis
	for i,v in ipairs(enemys) do
		dis = GetDistance2 (myid,v)
		priority=GetTact(TACT_BASIC,v)
		if (priority >= min_priority) then
			min_priority=priority
			if (dis < min_dis) then
				result = v
				min_dis = dis
			end
		end
	end
	
	return result
end


--####################################################
--### DoIdleTasks - stuff done in any "idle" state ###
--### like buffs and command processing            ###
--####################################################

function DoIdleTasks()
	local cmd = List.popleft(ResCmdList)
	if (cmd ~= nil) then		
		ProcessCommand (cmd)	-- 예약 명령어 처리 
		return 
	end
	if (UseAutoQuicken == 1 and QuickenTimeout ~=-1) then
		if (GetTick() > QuickenTimeout) then
			local skill,level,sp,duration = GetQuickenSkill(MyID)
			if (skill==0) then
				QuickenTimeout = -1
			elseif (sp <= GetV(V_SP,MyID)) then
				SkillObject(MyID,level,skill,MyID)
				QuickenTimeout = GetTick() + duration
				UpdateTimeoutFile()
				return
			end
		end
	end
	
	if (UseAutoGuard == 1 and GuardTimeout ~=-1) then
		if (GetTick() > GuardTimeout) then
			local skill,level,sp,duration = GetGuardSkill(MyID)
			if (skill <= 0) then
				GuardTimeout = -1
			elseif (sp <= GetV(V_SP,MyID)) then
				SkillObject(MyID,level,skill,MyID)
				GuardTimeout = GetTick() + duration
				UpdateTimeoutFile()
				return
			end
		end
	end
	if (UseAutoMag == 1 and MagTimeout ~=-1) then
		if (GetTick() > MagTimeout) then
			if (GetV(V_MERTYPE,MyID)~=4) then
				MagTimeout = -1
			elseif (40 <= GetV(V_SP,MyID)) then
				SkillObject(MyID,1,MER_MAGNIFICAT,MyID)
				MagTimeout = GetTick() + 34000
				UpdateTimeoutFile()
				return
			end
		end
	end
	if (UseAutoSight == 1 and SightTimeout~=-1) then
		if (GetTick() > SightTimeout and IsHiddenOnScreen(MyID) == 1) then
			if (GetV(V_MERTYPE,MyID) ~= 2) then
				SightTimeout = -1
			elseif (10 <= GetV(V_SP,MyID)) then
				SkillObject(MyID,1,MER_SIGHT,MyID)
				SightTimeout = GetTick() + 10000
				return
			end
		end
	end
	
	if (UseProvokeOwner == 1 and ProvokeOwnerTimeout ~=-1) then
		if (GetTick() > ProvokeOwnerTimeout) then
			local skill,level,sp,duration = GetProvokeSkill(MyID)
			if (skill <= 0) then
				ProvokeOwnerTimeout = -1
			elseif (sp <= GetV(V_SP,MyID) and GetDistance2(MyID,GetV(V_OWNER,MyID)) < 8) then
				--MyState=PROVOKE_ST
				--OnPROVOKE_ST()
				--return
				SkillObject(MyID,level,skill,GetV(V_OWNER,MyID))
				ProvokeOwnerTimeout = GetTick()+duration
				return
			end
		end
	end
	if (UseProvokeSelf == 1 and ProvokeSelfTimeout ~=-1) then
			if (GetTick() > ProvokeSelfTimeout) then
				local skill,level,sp,duration = GetProvokeSkill(MyID)
				if (skill <= 0) then
					ProvokeSelfTimeout = -1
				elseif (sp <= GetV(V_SP,MyID)) then
					--MyState=PROVOKE_ST
					--OnPROVOKE_ST()
					--return
					SkillObject(MyID,level,skill,GetV(V_OWNER,MyID))
					ProvokeSelfTimeout = GetTick()+duration
					return
				end
			end
	end
	if (UseSacrificeOwner == 1 and SacrificeTimeout ~=-1) then
		if (GetTick() > SacrificeTimeout) then
			local skill,level,sp,duration = GetSacrificeSkill(MyID)
			if (skill <= 0) then
				SacrificeTimeout = -1
			elseif (sp <= GetV(V_SP,MyID)) then
				SkillObject(MyID,level,skill,GetV(V_OWNER,MyID))
				SacrificeTimeout = GetTick() + duration -- this will recast it before it drops, because the countdown starts at the start of the cast time, but duration counts down from end of cast time.
				return
			end
		end
	end
	if (GetV(V_MOTION,GetV(V_OWNER,MyID))==MOTION_SIT and MyState~=REST_ST and DoNotUseRest==1) then
		MyState=REST_ST
		return
	end
	return 1
end

function UpdateTimeoutFile()
	if IsHomun(MyID)==0 then
		if MagTimeout == -1 then
			MagTimeoutx=0
		else
			MagTimeoutx=MagTimeout
		end
		if GuardTimeout == -1 then
			GuardTimeoutx=0
		else
			GuardTimeoutx=GuardTimeout
		end
	
		if QuickenTimeout == -1 then
			QuickenTimeoutx=0
		else
			QuickenTimeoutx=QuickenTimeout
		end
		OutFile=io.open("AI/USER_AI/SkillTimeouts.lua","w")
		OutFile:write("MagTimeout="..MagTimeoutx.."\nGuardTimeout="..GuardTimeoutx.."\nQuickenTimeout="..QuickenTimeoutx)
		OutFile:close()
	end
	return
end

--function OnPROVOKE_ST()
--	local skill,level,sp,duration = GetProvokeSkill(MyID)
--	if (skill <= 0) then
--		ProvokeOwnerTimeout = -1
--		TraceAI("PROVOKE_ST --> IDLE_ST: Woah, i was in PROVOKE_ST but i dont have provoke! Report as bug please.")
--		MyState=IDLE_ST
--		return
--	end
--	TraceAI("My motion="..GetV(V_MOTION,MyID))
--	if (GetTick() >= ProvokeDelayTimeout + ProvokeOwnerDelay) then
--		if (GetV(V_MOTION,MyID) == MOTION_SKILL) then
--			TraceAI("PROVOKE_ST --> IDLE_ST: Provoke worked!")
--			ProvokeOwnerTimeout = GetTick() + duration
--			ProvokeTriesTimeout = 0
--			MyState=IDLE_ST
--			return
--		elseif (sp <= GetV(V_SP,MyID)) then
--			TraceAI("PROVOKE_ST: Trying to use provoke on owner")	
--			SkillObject(MyID,level,skill,GetV(V_OWNER,MyID))
--			ProvokeTriesTimeout = ProvokeTriesTimeout+1
--			ProvokeDelayTimeout = GetTick()
--			return
--		else
--			TraceAI("PROVOKE_ST --> IDLE_ST: No SP.")
--			ProvokeTriesTimeout = 0
--			MyState=IDLE_ST
--			OnIDLE_ST()
--		end
--	elseif (GetV(V_MOTION,MyID) == MOTION_SKILL) then
--		TraceAI("PROVOKE_ST --> IDLE_ST: Provoke worked!")
--		ProvokeOwnerTimeout = GetTick() + duration
--		ProvokeTriesTimeout = 0
--		MyState=IDLE_ST
--		return
--	elseif (ProvokeTriesTimeout >= ProvokeOwnerTries) then
--		TraceAI("PROVOKE_ST --> IDLE_ST: Provoke not working!")
--		MyState=IDLE_ST
--		ProvokeOwnerTimeout=-1
--		OnIDLE_ST()
--		return
--	end
--end


--#########################
--### Random Move Stuff ###
--### Yes, it's ugly.	###
--#########################

function	OnRANDWALK_ST ()

	TraceAI ("OnRANDWALK_ST")
	RandWalkTries = RandWalkTries + 1
	local x, y = GetV (V_POSITION,MyID)
	local mymotion = GetV(V_MOTION,MyID)
	if (x == MyDestX and y == MyDestY) then				-- DESTINATION_ARRIVED_IN
		MyState = IDLE_ST
	elseif (RandWalkTries > 2 and mymotion==MOTION_STAND) then
		MyDestX=0
		MyDestY=0
		MyState= IDLE_ST
	end
end

function	DoRandomMove()
	TraceAI ("Random Move Called")
	DoRand=0
	local x, y = GetV(V_POSITION,MyID)
	if (UseRouteWalk==1) then
		destx,desty,step=GetRouteNext(x,y,RouteWalkStep)
		if RouteWalkStep==nil then
			RouteWalkStepx="nil"
		end
		if step==nil then
					stepx="nil"
		end
		TraceAI("GetRouteNext returned "..destx..","..desty..","..stepx.." from "..x..","..y..","..RouteWalkStepx)
		if (x~=destx or y~=desty) then --it will return x,y=destx,desty if it cant find a place to move
			DoRand=1
			MyDestX,MyDestY=destx,desty
			RouteWalkStep=step
		else
			MyDestx,MyDestY=0,0
		end
	end
	if (UseRandWalk==1 and MyDestX==0 and MyDestY==0) then
		local xsign=2*math.random(0,1)-1
		local ysign=2*math.random(0,1)-1
		MyDestX=x+math.random(6,9)*xsign
		MyDestY=y+math.random(6,9)*ysign
		DoRand=1
	end
	if (DoRand==1) then
		Move(MyID,MyDestX,MyDestY)
		RandWalkTries=0
		MyState=RANDWALK_ST
	end
	return
end

function GetRouteNext(x,y,step)
	routelength=len(MyRoute)
	TraceAI("Route Length" ..routelength)
	if (step~=nil) then
		if ((routelength <= step and RouteWalkDirection == 1) or (step <= 1 and RouteWalkDirection==-1)) then 
			TraceAI("RouteWalk: At end of route, acting appropriately")
			if (RouteWalkCircle==1) then
				if (RouteWalkDirection ==1) then
					nextstep=1
				else
					nextstep=len(MyRoute)
				end
			else
				RouteWalkDirection = -1*RouteWalkDirection
				nextstep=step
			end
		else
			nextstep=step+RouteWalkDirection
		end
		TraceAI("RouteWalk: "..nextstep.."step:"..step.." "..len(MyRoute))
		nx,ny=MyRoute[nextstep][1],MyRoute[nextstep][2]
		dist2n=GetDistance(x,y,nx,ny)
		if (dist2n>10) then
			nx,ny=MyRoute[step][1],MyRoute[step][2]
			dist2n=GetDistance(x,y,nx,ny)
			if (dist2n>10) then
				step=nil
			end
		else
			step=nextstep
		end
	end
	if (step~=nil) then
		return nx,ny,step
	else
		for k,v in pairs(MyRoute) do
			if (GetDistance(x,y,v[1],v[2]) < 10) then
				return v[1],v[2],k
			end
		end
		return x,y,nil
	end
end

--#############################
--### My orbitwalk routine  ###
--### needs to be taken out ###
--### behind the woodshed.  ###
--#############################

function	OnORBITWALK_ST()
	TraceAI ("OnORBITWALK_ST")
	if (DoIdleTasks()==nil) then
		return
	end
	local	object = GetOwnerEnemy (MyID)
	if (object ~= 0) then							-- MYOWNER_ATTACKED_IN
		MyState = CHASE_ST
		MyEnemy = object
		TraceAI ("ORBITWALK_ST -> CHASE_ST : ALLY_ATTACKED_IN")
		return 
	end

	object = GetMyEnemy (MyID)
	if (object ~= 0) then							-- ATTACKED_IN
		MyState = CHASE_ST
		MyEnemy = object
		TraceAI ("ORBITWALK_ST -> CHASE_ST : ATTACKED_IN")
		return
	end

	local distance = GetDistanceFromOwner(MyID)
	if ( distance > UseOrbitWalk+2 or distance == -1) then		-- MYOWNER_OUTSIGNT_IN
		MyState = FOLLOW_ST
		TraceAI ("ORBITWALK_ST -> FOLLOW_ST")
		return
	end
	if (HPPercent(MyID)~=100 or SPPercent(MyID)~=100) then
		MyState = IDLE_ST
		TraceAI ("Low HP/SP, returning to idle state")
		return
	end
	local x, y = GetV (V_POSITION,MyID)
	local mymotion = GetV(V_MOTION,MyID)
	if (mymotion==MOTION_STAND) then
		if (x==MyDestX and y==MyDestY or OrbitWalkTries > 6) then
			if (OrbitWalkStep == 7) then
				OrbitWalkStep=0
			else
				OrbitWalkStep=OrbitWalkStep+1
			end
			OrbitWalkTries = 0
			local ownerx, ownery=GetV(V_POSITION,GetV(V_OWNER,MyID))
			local offx, offy = GetOrbitNext(UseOrbitWalk,OrbitWalkStep)
			MyDestX=ownerx+offx
			MyDestY=ownery+offy
			Move(MyID,MyDestX,MyDestY)
		else
			OrbitWalkTries = OrbitWalkTries +1
			Move(MyID,MyDestX,MyDestY)
		end
		return
	end	
end

function GetOrbitNext(distance,step)
	local angle=math.rad(step*45)
	local destx=math.ceil(math.sin(angle)*distance)
	local desty=math.ceil(math.cos(angle)*distance)
	TraceAI("OrbitDestOffs: "..destx..","..desty) 
	return destx,desty
end


--######################
--### DoAutoPushback ###
--######################

function DoAutoPushback(myid)
	local actors = GetActors()
	local x,y=GetV(V_POSITION,myid)
	for i,v in ipairs(actors) do
		if (IsMonster(v)==1) then
			local tact= GetTact(TACT_PUSHBACK,v)
			local target =GetV(V_TARGET,v)
			if (tact==2 or (tact==1 and IsFriendOrSelf(target)==1))then
				if (GetDistance2(target,v) <= AutoPushbackThreshold) then
					TraceAI("Enemies close to me, using pushback")
					local skill,level,sp,targetmode=GetPushbackSkill(MyID)
					if (skill==0) then
						UseAutoPushback=0
					elseif (GetV(V_SP,myid) >= sp) then
						if (targetmode==1) then
							SkillObject(myid,level,skill,v)
						elseif (targetmode==2) then
							local ex,ey=GetV(V_POSITION,v)
							local x,y=Closer(myid,ex,ey)
							SkillGround(myid,level,skill,x,y)
						end
						return
					end
					break
				end
			end
		elseif (IsFriendOrSelf(id)==0 and PVPmode ~=0) then
			local tact= GetPVPTact(TACT_PUSHBACK,v)
			local target =GetV(V_TARGET,v)
			if (tact==2 or (tact==1 and IsFriendOrSelf(target)==1))then
				if (GetDistance2(target,v) <= AutoPushbackThreshold) then
					TraceAI("Enemies close to me, using pushback")
					local skill,level,sp,targetmode=GetPushbackSkill(MyID)
					if (skill==0) then
						UseAutoPushback=0
					elseif (GetV(V_SP,myid) >= sp) then
						if (targetmode==1) then
							SkillObject(myid,level,skill,v)
						elseif (targetmode==2) then
							local ex,ey=GetV(V_POSITION,v)
							local x,y=Closer(myid,ex,ey)
							SkillGround(myid,level,skill,x,y)
						end
						return
					end
					break
				end
			end
		end
	end
	return 1
end


--####################
--### DoKiteAdjust ###
--####################

function DoKiteAdjust(myid,enemy)
	local step
	local target=GetV(V_TARGET,enemy)
	if (IsFriend(target)==1 or target==MyID) then
		step=KiteStep
	else
		step=KiteParanoidStep
	end
	local x,y=GetV(V_POSITION,myid)
	local ox,oy=GetV(V_POSITION,GetV(V_OWNER,myid))
	local ex,ey=GetV(V_POSITION,enemy)
	local xoptions ={[2]=1,[0]=1,[1]=1}
	local yoptions ={[2]=1,[0]=1,[1]=1}
	local xdirection,ydirection=0,0
	if (x > ex) then
		xoptions[2]=0
	elseif (x < ex) then
		xoptions[1]=0
	else
		yoptions[0]=0
	end
	if (y > ey) then
		yoptions[2]=0
	elseif (y < ey) then
		yoptions[1]=0
	else
		xoptions[0]=0
	end
	if (ox > x) then
		if (xoptions[1]==1) then
			xdirection=1
		elseif (xoptions[0]==1) then
			xdirection=0
		elseif (xoptions[2]==1 and (ox-x+step) <= KiteBounds) then
			xdirection=-1
		elseif	(ey < y) then
			xdirection=0
		else
			xdirection=1
		end
	else
		if (xoptions[2]==1) then
			xdirection=-1
		elseif (xoptions[0]==1) then
			xdirection=0
		elseif (xoptions[1]==1 and (x-ox+step) <= KiteBounds) then
			xdirection=1
		elseif	(ey > y) then
			xdirection=0
		else
			xdirection=-1
		end
	end
	if (oy > y) then
		if (yoptions[1]==1) then
			ydirection=1
		elseif (yoptions[0]==1 and xdirection~=0) then
			ydirection=0
		elseif (yoptions[2]==1 and oy-y+step <= step) then
			ydirection=-1
		elseif	(ex > x and xdirection~=0) then
			ydirection=0
		else
			ydirection=1
		end
	else 
		if (yoptions[2]==1) then
			ydirection=-1
		elseif (yoptions[0]==1 and xdirection~=0) then
			ydirection=0
		elseif (yoptions[1]==1 and y-oy+step <= KiteBounds) then
			ydirection=1
		elseif	(ex < x and xdirection~=0) then
			ydirection=0
		else
			ydirection=-1
		end
	end
	TraceAI("Kiteing in "..xdirection..","..ydirection.." direction")
	MyDestX=x+step*xdirection
	MyDestY=y+step*ydirection
	Move(myid,MyDestX,MyDestY)
end

--########################
--### Main AI Function ###
--########################

function AI(myid)
	
	-- Save the ID to a file so counterpart can friend it
	-- Why is it here instead of at the start?
	-- Because the client wont tell us our ID until AI() is called :-(
	if (NeedToDoAutoFriend==1 and NewAutoFriend==1) then
		TraceAI("Now it's time to do the autofriend")
		if (IsHomun(myid)==1) then
			OutFile=io.open("AI/USER_AI/H_ID.txt","w")
		else
			OutFile=io.open("AI/USER_AI/M_ID.txt","w")
		end
		OutFile:write (myid)
		OutFile:close()
		NeedToDoAutoFriend=0
	end
	
	MyID = myid
	local msg	= GetMsg (myid)			-- command
	local rmsg	= GetResMsg (myid)		-- reserved command
	
	-- Hackjob to fix strange behavior, with the timeouts being set to hours, days, or weeks in the future. 
	if GuardTimeout-GetTick() > 350000 then
		GuardTimeout=GetTick()+300000
	end
	if MagTimeout-GetTick() > 350000 then
			MagTimeout=GetTick()+300000
	end
	if QuickenTimeout-GetTick() > 350000 then
		QuickenTimeout=GetTick()+300000
	end
	
	FastChangeCount = 0
	if msg[1] == NONE_CMD then
		if rmsg[1] ~= NONE_CMD then
			if List.size(ResCmdList) < 10 then
				List.pushright (ResCmdList,rmsg) -- 예약 명령 저장
			end
		end
	else
		List.clear (ResCmdList)	-- 새로운 명령이 입력되면 예약 명령들은 삭제한다.  
		ProcessCommand (msg)	-- 명령어 처리 
	end
	for k,v in pairs(Unreachable) do
		if (IsOutOfSight(myid,k)==true or GetV(V_MOTION,k)==MOTION_DEAD or IsFriendOrSelf(GetV(V_TARGET,k))==1) then
			Unreachable[k]=nil
		end
	end
	
	-- Actor list preprocessing
	local actors=GetActors()
	Actors={}
	Players={}
	Monsters={}
	Targets={}
	Summons={}
	Retainers={}
	for i,v in ipairs(actors) do
		if IsMonster(v)==1 then
			if (v < 40000) then
				Targets[v]=2
			elseif (v < 100000) then
				Targets[v]=1
			elseif (PVPMode==1) then
				Targets[v]=0
			end
		end
		if (v > 100000) then
			Players[v]=1
		elseif (v < 40000) then
			if (IsMonster(v)==1) then
				Summons[v]=1
			else
				Retainers[v]=1
			end
		else
			if IsMonster(v)==1 then
				Monsters[v]=1
			end
		end
	end
	
	--New autofriend routine
	if (NewAutoFriend==1 and AssumeHomun==1) then
		friendedOK=0
		retainercount=0
		for k,v in pairs(Retainers) do
			if (k~=MyID) then
				retainercount=retainercount+1
				if (MyFriends[k]==2) then
					friendedOK=1
				end
			end
		end
		if (friendedOK==0) then
			if (IsHomun(myid)==1) then
				InFile=io.open("AI/USER_AI/M_ID.txt","r")
			else
				InFile=io.open("AI/USER_AI/H_ID.txt","r")
			end
			retainerid=InFile:read("*a")
			InFile:close()
			retainerid=tonumber(retainerid)
			if (retainerid ~=nil) then
				MyFriends[retainerid]=2
			end
		end
	end
	
	-- Prevent from being left behind
	-- Used only in critical (merc out of MoveBounds) situations
	-- Otherwise, IDLE_ST handles it
	
	local dist2owner=GetDistance2(MyID,GetV(V_OWNER,MyID))
	if (MyState ~=FOLLOW_ST and dist2owner > MoveBounds) then
		MyState=FOLLOW_ST
	end
	--Cancel all action during the spawn invulnerability
	if (GetTick() < (MyStart + SpawnDelay)) then
		return
	end
	
	object = GetRescueEnemy(myid)
	if (object~=0 and object ~= MyEnemy) then
		MyEnemy=object
		MyState=CHASE_ST
		TraceAI("RESCUE ACTIVATED - Targeting "..object)
	end
	
	-- Check to see if mercenary should activate kiting routine
	if (KiteMonsters==1 and (KiteOK(MyID)==1 or ForceKite == 1)) then
		local x,y=GetV(V_POSITION,MyID)
		if ((x==KiteDestX and y==KiteDestY) or (KiteDestX==0 and KiteDestY==0)) then
			local actors = GetActors()
			kitecalled=0
			for i,v in ipairs(actors) do
				if (IsMonster(v)==1 and GetV(V_MOTION,v) ~= MOTION_DEAD) then
					local target=GetV(V_TARGET,v)
					local tact = GetTact(TACT_KITE,v)
					if ((IsFriendOrSelf(target)==1 and tact==1) or tact==2) then
						local threshold
						if (IsFriend(target)==1 or target==MyID) then
							threshold=KiteThreshold
						else
							threshold=KiteParanoidThreshold
						end
						if (GetDistance2(MyID,v) <= threshold) then
							TraceAI("Enemies close to me, start kite routine. ")
							DoKiteAdjust(MyID,v)
							kitecalled=1
							break
						end
					end
				end
			end
			if (kitecalled == 0) then
				KiteDestX,KiteDestY=0,0
			end
		else
			Move(myid,KiteDestX,KiteDestY)
		end
	end
	
	--Do state processes
 	if (MyState == IDLE_ST) then
		OnIDLE_ST ()
	elseif (MyState == CHASE_ST) then					
		OnCHASE_ST ()
	elseif (MyState == ATTACK_ST) then
		OnATTACK_ST ()
	elseif (MyState == FOLLOW_ST) then
		OnFOLLOW_ST ()
	elseif (MyState == MOVE_CMD_ST) then
		OnMOVE_CMD_ST ()
	elseif (MyState == STOP_CMD_ST) then
		OnSTOP_CMD_ST ()
	elseif (MyState == ATTACK_OBJECT_CMD_ST) then
		OnATTACK_OBJECT_CMD_ST ()
	elseif (MyState == ATTACK_AREA_CMD_ST) then
		OnATTACK_AREA_CMD_ST ()
	elseif (MyState == PATROL_CMD_ST) then
		OnPATROL_CMD_ST ()
	elseif (MyState == HOLD_CMD_ST) then
		OnHOLD_CMD_ST ()
	elseif (MyState == SKILL_OBJECT_CMD_ST) then
		OnSKILL_OBJECT_CMD_ST ()
	elseif (MyState == SKILL_AREA_CMD_ST) then
		OnSKILL_AREA_CMD_ST ()
	elseif (MyState == FOLLOW_CMD_ST) then
		OnFOLLOW_CMD_ST ()
	elseif (MyState == RANDWALK_ST) then
		OnRANDWALK_ST ()
	elseif (MyState == ORBITWALK_ST) then
		OnORBITWALK_ST()
	elseif (MyState == REST_ST) then
		OnREST_ST()
	elseif (MyState == TANKCHASE_ST) then
		OnTANKCHASE_ST()
	elseif (MyState == TANK_ST) then
		OnTANK_ST()
	elseif (MyState == PROVOKE_ST) then
		OnPROVOKE_ST()
	end

end
