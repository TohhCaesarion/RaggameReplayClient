-------------------------------
-- A collection of useful functions related to homun and mercenary scripting
-------------------------------
-- This AI file may be distributed and used in AI's freely as long as credit is given.
-- Written by Dr. Azzy of iRO Loki
-- Version 1.27 - backwards combatable. 
-------------------------------


require "./AI/USER_AI/SkillList.lua"


--[[
USAGE NOTES


GetHPPercent(id)
GetSPPercent(id)
Returns the current hp or sp of id as a percentage. This only works on things which the player can see the hp/sp of, obviously.

Closer(id,x,y)
Returns coordinants of a location 1 cell closer to actor (id) 

ClosestR(id1,id2,range)
Returns coordinants of the cell within <range> cells of <id2> that is closest to <id1>.
Intended for targeting of ranged skills.

BetterMoveToOwner(mercid,range)
Moves to the closest sell withing range cells of the owner. 

IsNotKS(id)
Returns 1 if attacking monster (id) would be a KS, 0 otherwise. 

IsFriend(id)
Returns 1 if (id) is the owner or a friend. 

@@@@@@@@@@@@@@@@@@@@@@@@@
@@@ Monster Functions @@@
@@@@@@@@@@@@@@@@@@@@@@@@@

GetMobCount(id,range,[id2])
Returns the number of monsters within range cells of the actor id, and the number of said monsters which are currently targeting id. If id2 is specified, monsters which are targeting id2 will also be included in the second value returned. 
Useful for deciding whether to use anti-mob skills.
ex:
local mobcount,aggrocount = GetMobCount(MyID,1,GetV(V_OWNER,MyID))

GetBestBrandishTarget(id)
Returns the id of the best monster adjacent to the mercenary to use brandish spear on (that is, the target that will result in the most monsters being hit). 
Assumes level 1 brandish area. 

ex:
SkillObject(MyID,MySkillLevel,ML_BRANDISH,GetBestBrandishTarget(MyID))


@@@@@@@@@@@@@@@@@@@@@@@
@@@ Skill Functions @@@
@@@@@@@@@@@@@@@@@@@@@@@

GetAtkSkill(id)
Returns a list containing skill id, skill level, and sp consumption of the mercenary's single target offencive skill. Crash is not returned in this list, because the damage output spamming crash is lower than the damage output from using normal attacks. 

ex: 
local skill,level,sp = GetAtkSkill(MyID)

GetMobSkill(merctype)
As GetAtkSkill(), but returns a fourth variable, target type:
0 - Use SkillObject() to cast the skill, targeted on mercenary (magnum break)
1 - Use SkillObject() to cast the skill, targeted on enemy
2 - Use SkillArea() to cast the skill (Arrow Shower)

ex
local skill,level,sp,targettype = GetMobSkill(MyID)

GetQuickenSkill(id)
Returns a list containing the ID of the weapon quicken skill posessed by the mercenary, the skill level, the sp consumption, and the duration. 

ex
local skill,level,sp,duration = GetQuickenSkill(MyID)

GetGuardSkill(id)
As GetQuickenSkill() only returns the ID of the guard or parry skill posessed by the mercenary. 

GetSacrificeSkill(id)
As GetQuickenSkill() only returns the ID and other perameters for the Sacrifice (aka Devotion) skill posessed by the mercenary.

GetProvokeSkill(id)
As GetQuiceknSkill() only returns the ID and other perameters for the Provoke skill posessed by the mercenary. 

GetPushbackSkill(id)
As GetMobSkill() only returns the ID and other perameters for the pushback skill (arrow repel or skid trap) posessed by the mercenary

]]--
 


--########################
--### Friend Functions ###
--########################


function IsFriend(id)
	if (id==GetV(V_OWNER,MyID)) then
		return 1
	elseif (id~= MyID) then
		friendclass=MyFriends[id]
		if (friendclass==FRIEND or friendclass==RETAINER) then
			return 1
		end
	end
	return 0
end

function IsPVPFriend(id)
	if (id==GetV(V_OWNER,MyID)) then
		return 1
	elseif (id~= MyID) then
		friendclass=MyFriends[id]
		if (friendclass==FRIEND or friendclass==RETAINER or friendclass==NEUTRAL or friendclass==ALLY or friendclass==NEUTRAL) then
			return 1
		end
	end
	return 0
end

function IsFriendOrSelf(id)
	if (id==GetV(V_OWNER,MyID) or id == MyID) then
		return 1
	else
		if (MyFriends[id]~=nil) then
			return 1	
		end
	end
	return 0
end

function IsPlayer(id)
	if (id>100000) then
		return 1
	else
		return 0
	end
end

function GetFriendTargets() -- returns list of targets of friends who are attacking
	local targets = {}
	for i,v in ipairs (GetActors()) do
		if (IsFriend(v) == 1) then
			motion=GetV(V_MOTION,v)
			target=GetV(V_TARGET,v)
			if (IsMonster(target)==1) then
				if (FriendAttack[motion]==1) then
					targets[target]=1
				end
			end
		end
	end
	return targets
end

--########################
--### Monster functions###
--########################


function GetMobCount(id,range,id2)
	local actors = GetActors ()
	local mobcount=0
	local aggrocount=0
	local distance = 0
	local target = -1
	if (id2==nil) then
		id2 = 0
	end
	for i,v in ipairs(actors) do
		if (IsMonster(v) == 1) then
			distance = GetDistance2(id,v)
			if (distance <= range) then
				mobcount=mobcount+1
				target = GetV(V_TARGET,v)
				if (GetV(V_TARGET,v)==id or GetV(V_TARGET,v)==id2) then
					aggrocount=aggrocount+1
				end
			end
		end
	end
	return mobcount,aggrocount
end



function GetBestBrandishTarget(myid)
	local actors = GetActors()
	local enemies = {}
	local index = 1
	for i,v in ipairs(actors) do
		if (IsMonster(v)==1) then	
			enemies[index] = v
			index = index+1
		end
	end
	local mobs =0
	local maxmobs = 0
	local besttarget= -1
	for i,v in ipairs(enemies) do
		if (GetDistance2(myid,v) <=1) then --Is a target in range to brandish
			mobs = 0
			for a,b in ipairs (enemies) do
				if (GetDistance2(myid,b)<=1 and GetDistance2(v,b) <=1) then
					mobs=mobs+1
				elseif (GetDistance2(myid,b) ==2 and GetDistance3(myid,b) < 2.5 and GetDistance3(v,b) < 2.5)then -- sides, 2 cells to either side of target/merc
					mobs=mobs+1
				end
			end
			if (mobs > maxmobs) then
				maxmobs = mobs
				besttarget = v
			end
		end
	end
	return besttarget
end

function IsHiddenOnScreen(myid) --Currently disabled - assume there is never hidden on screen.
	return 0
end

function IsHomun(myid)
	if (GetV(V_HOMUNTYPE,myid)~=nil) then
		return 1
	end
	return 0

end

function IsNotKS(myid,target)
	TraceAI("Checking for KS:"..target)
	local targettarget=GetV(V_TARGET,target)
	local motion=GetV(V_MOTION,target)
	if (target==MyEnemy and BypassKSProtect==1) then --If owner has told homun to attack explicity, let it.
		return 1
	end
	if (IsPlayer(target)==1) then
		TraceAI("PVP - not KS")
		return 1
	elseif (IsFriend(targettarget)==1 or targettarget==myid) then
		TraceAI("Not KS - "..target.." fighting friend: "..targettarget)
		return 1
	elseif (GetTact(TACT_FFA,target)==1) then
		TraceAI("It's an FFA monster - serious buisness!")
		return 1
	elseif (targettarget > 0 and (motion ~= MOTION_STANDING and (IsPlayer(targettarget)==1 or KSMercHomun ~=1))) then
		TraceAI("Is KS - "..target.." attacking player "..targettarget.." motion "..motion)
		return 0
	else
		TraceAI("Not Targeted - seeing if anyone is targeting it")
		local actors = GetActors()
		for i,v in ipairs(actors) do
			if (IsMonster(v)~=1 and IsFriendOrSelf(v)==0) then
				if (GetV(V_TARGET,v) == target and (v > 100000 or KSMercHomun ~=1)) then
					TraceAI("Is KS - "..target.." is targeted by "..v)
					return 0
				end
			end
		end
	TraceAI("Not KS - "..target.." is not targeted by any other player.")
	return 1
	end
end

--########################
--### HP/SP % functions###
--########################

function HPPercent(id)
	local maxHP=GetV(V_MAXHP,id)
	local curHP=GetV(V_HP,id)
	percHP=100*curHP/maxHP
	return percHP
end

function SPPercent(id)
	local maxSP=GetV(V_MAXSP,id)
	local curSP=GetV(V_SP,id)
	percSP=100*curSP/maxSP
	return percSP
end

--########################
--### Spacial functions###
--########################

function	GetDistance (x1,y1,x2,y2)
	return math.floor(math.sqrt((x1-x2)^2+(y1-y2)^2))
end




function	GetDistance2 (id1, id2)
	local x1, y1 = GetV (V_POSITION,id1)
	local x2, y2 = GetV (V_POSITION,id2)
	if (x1 == -1 or x2 == -1) then
		return -1
	end
	return GetDistance (x1,y1,x2,y2)
end

function GetDistance3(id1,id2) 
	local x1, y1 = GetV (V_POSITION,id1)
	local x2, y2 = GetV (V_POSITION,id2)
	if (x1 == -1 or x2 == -1) then
		return -1
	end
	return math.sqrt((x1-x2)^2+(y1-y2)^2)
end


function IsToRight(id1,id2)
	local x1,y1=GetV(V_POSITION,id1)
	local x2,y2=GetV(V_POSITION,id2)
	if (x1+1==x2 and y1==y2) then
		return 1
	else
		return 0
	end
end

function BetterMoveToOwner(myid,range)
	if (range==nil) then
		range=1
	end
	local x,y = GetV(V_POSITION,myid)
	local ox,oy = GetV(V_POSITION,GetV(V_OWNER,myid))
	local destx,desty=0,0
	if (x > ox+range) then
		destx=ox+range
	elseif (x < ox - range) then
		destx=ox-range
	else
		destx=x
	end
	if (y > oy+range) then
		desty=oy+range
	elseif (y < oy - range) then
		desty=oy-range
	else
		desty=y
	end
	MyDestX,MyDestY=destx,desty
	Move(myid,MyDestX,MyDestY)
	return
end


function	GetOwnerPosition (id)
	return GetV (V_POSITION,GetV(V_OWNER,id))
end

function	GetDistanceFromOwner (id)
	local x1, y1 = GetOwnerPosition (id)
	local x2, y2 = GetV (V_POSITION,id)
	if (x1 == -1 or x2 == -1) then
		return -1
	end
	return GetDistance (x1,y1,x2,y2)
end

function	IsOutOfSight (id1,id2)
	local x1,y1 = GetV (V_POSITION,id1)
	local x2,y2 = GetV (V_POSITION,id2)
	if (x1 == -1 or x2 == -1) then
		return true
	end
	local d = GetDistance (x1,y1,x2,y2)
	if d > 20 then
		return true
	else
		return false
	end
end


function	IsInAttackSight (id1,id2,skill)
	if (skill==nil) then
		skill=MySkill
	end
	local x1,y1 = GetV (V_POSITION,id1)
	local x2,y2 = GetV (V_POSITION,id2)
	if (x1 == -1 or x2 == -1) then
		return false
	end
	local d		= GetDistance (x1,y1,x2,y2)
	local a     = 0
	if (skill == 0) then
		mertype=GetV(V_MERTYPE,id1)
		if (mertype==nil) then
			mertype=-1
		end
		if (mertype > 10) then
			a     = 2
		else
			a     = GetV(V_ATTACKRANGE,id1)
		end
	elseif (skill==MER_CRASH or skill== HVAN_CAPRICE or skill==HFLI_MOON) then
		a = 100
	else
		a     = GetV (V_SKILLATTACKRANGE,id1,skill)
	end

	if a >= d then
		return true;
	else
		return false;
	end
end



function AttackRange(myid,skill)
	if (skill==nil) then
		skill=MySkill
	end
	local a     = 0
	if (skill == 0) then
		mertype=GetV(V_MERTYPE,myid)
		if (mertype==nil) then
			mertype=-1
		end
		if (mertype > 10) then
			a     = 1
		else
			a     = GetV(V_ATTACKRANGE,myid)
		end
	elseif (skill==MER_CRASH or skill== HVAN_CAPRICE or skill==HFLI_MOON) then
		a 	= 100
	else
		a	= GetV (V_SKILLATTACKRANGE,myid,MySkill)
	end
	return a
end

function Closer(id,ox,oy)
	x,y=GetV(V_POSITION,id)
	newx,newy=0,0
	if (ox==x) then
		newx=x
	elseif (ox > x) then
		newx=ox-1
	else
		newx=ox+1
	end
	if (oy==y) then
		newy=y
	elseif (oy > y) then
		newy=oy-1
	else
		newy=oy+1
	end
	return newx,newy
end

function ClosestR(myid,target,range)
	x,y=GetV(V_POSITION,myid)
	ox,oy=GetV(V_POSITION,target)
	dx,dy=ox-x,oy-y
	newx,newy=0,0
	dist=math.sqrt(dx^2+dy^2)
	if (dist < range) then
		newx,newy=x,y
	else
		factor=range/dist
		xoff=(dx-math.ceil(dx*factor))
		yoff=(dy-math.ceil(dy*factor))
		newx,newy=x+xoff,y+yoff
	end
	return newx,newy
end

function DiagonalDist(distance)
	return math.floor(math.sqrt(distance*distance))
end

function GetDanceCell(x,y,enemy)
	distance = GetDistance2(MyID,enemy)
	ex,ey=GetV(V_POSITION,enemy)
	s=(((math.random(2)-1)*2)-1)
	t=(((math.random(2)-1)*2)-1)
	if (GetDistance(x-s,y+t,ex,ey) == distance) then
		return x-s,y+t
	elseif (GetDistance(x,y+t,ex,ey) == distance) then
		return x,y+t
	elseif (GetDistance(x+s,y+t,ex,ey) == distance) then
		return x+s,y+t
	elseif (GetDistance(x-s,y,ex,ey) == distance) then
		return x-s,y
	elseif (GetDistance(x+s,y,ex,ey) == distance) then
		return x+s,y
	elseif (GetDistance(x-s,y-t,ex,ey) == distance) then
		return x-s,y-t
	elseif (GetDistance(x,y-t,ex,ey) == distance) then
		return x,y-t
	else
		return x+s,y-t
	end
	
end

--#########################
--### GetSkill functions###
--#########################

function GetAtkSkill(myid)
	merctype = GetV(V_MERTYPE,myid)
	local skill = 0
	local level = 0
	local sp = 0
	local targetmode = 1
	local delay = 0
	if (IsHomun(myid)==1) then
		homuntype=modulo(GetV(V_HOMUNTYPE,myid),4)
		if (homuntype==0) then -- It's a vani!
			skill=HVAN_CAPRICE
			if (VanCapriceLevel==nil) then
				level=5
			else
				level=VanCapriceLevel
			end
			delay=2000+level*200
			sp = 20+2*level
		elseif	(homuntype==3) then -- It's a filer!
			skill=HFLI_MOON
			if (FilerMoonlightLevel==nil) then
				level=5
			else
				level=FilerMoonlightLevel
			end
			delay=2250
			sp=4*level
		end
	else
		if (merctype==1) then
			skill=MA_DOUBLE
			level=2
			sp=12
		elseif (merctype==5) then
			skill=MA_DOUBLE
			level=5
			sp=12
		elseif (merctype==6) then
			skill=MA_DOUBLE
			level=7
			sp=12
		elseif (merctype==9) then
			skill=MA_DOUBLE
			level=10
			sp=12
		elseif (merctype==11) then
			skill=ML_PIERCE
			level=1
			sp=7
		elseif (merctype==13) then
			skill=ML_PIERCE
			level=2
			sp=7
		elseif (merctype==15) then
			skill=ML_PIERCE
			level=5
			sp=7
		elseif (merctype==18) then
			skill=ML_PIERCE
			level=10
			sp=7
		elseif (merctype==20) then
			skill=ML_SPIRALPIERCE
			level=5
			sp=30
		elseif (merctype==21) then
			skill=MS_BASH
			level=1
			sp=8
		elseif (merctype==25) then
			skill=MS_BASH
			level=5
			sp=8
		elseif (merctype==27) then
			skill=MS_BASH
			level=10
			sp=15
		elseif (merctype==30) then
			skill=MS_BASH
			level=10
			sp=15
		end
	end
	return skill,level,sp,targetmode,delay
end

function GetPushbackSkill(myid)
	merctype = GetV(V_MERTYPE,myid)	
	local skill = 0
	local level = 0
	local sp = 0
	local target = 1
	local delay=0
	if (IsHomun(myid)==1) then
		skill=0
	elseif (merctype==3) then
		skill=MA_CHARGEARROW
		level=1
		sp=15
		delay=1000
	elseif (merctype==6) then
		skill=MA_SKIDTRAP
		level=3
		sp=15
		target = 2
	elseif (merctype==9) then
		skill=MA_CHARGEARROW
		level=1
		sp=15	
		delay=1000
	elseif (merctype==10) then
		skill=MA_CHARGEARROW
		level=1
		sp=15
		delay=1000
	end
	return skill,level,sp,target
end


function GetDebuffSkill(myid)
	merctype = GetV(V_MERTYPE,myid)	
	local skill = 0
	local level = 0
	local sp = 0
	local target = 1
	local delay = 0
	if (IsHomun(myid)==1) then
		duration=0
	elseif (merctype==5) then
		skill=MER_PROVOKE
		level=1
		sp =4
	elseif (merctype==6) then
		skill=MER_DECAGI
		level=1
		sp =27
		delay=1000
	elseif (merctype==7) then
		skill=MA_FREEZEINGTRAP
		level=2
		sp =10
		target=2
	elseif (merctype==8) then
		skill=MA_SANDMAN
		level=3
		sp=12
		target=2
	elseif (merctype==21) then
		skill=MER_DECAGI
		level=1
		sp =27
		delay=1000
	elseif (merctype==22) then
		skill=MER_PROVOKE
		level=5
		sp=8
	elseif (merctype==24) then
		skill=MER_CRASH
		level=1
		sp =10
		delay=1000
	elseif (merctype==25) then
		skill=MER_CRASH
		level=4
		sp =10
		delay=1000
	elseif (merctype==26) then
		skill=MER_DECAGI
		level=3
		sp =31
		delay=1000
	elseif (merctype==29) then
		skill=MER_CRASH
		level=3
		sp =10
		delay=1000
	elseif (merctype==12) then
		skill=MER_LEXDIVINA
		level=1
		sp =20
	elseif (merctype==14) then
		skill=MER_CRASH
		level=1
		sp =10
		delay=1000
	elseif (merctype==18) then
		skill=MER_PROVOKE
		level=5
		sp=8
	end
	return skill,level,sp,target,delay
end

function GetProvokeSkill(myid)
	merctype = GetV(V_MERTYPE,myid)	
	local skill = 0
	local level = 0
	local sp = 0
	local duration = 30000
	if (IsHomun(myid)==1) then
		duration=0
	elseif (merctype==5) then
		skill=MER_PROVOKE
		level=1
		sp =4
	elseif (merctype==8) then
		skill=MER_PROVOKE
		level=3
		sp=6
	elseif (merctype==22) then
		skill=MER_PROVOKE
		level=5
		sp=8
	elseif (merctype==18) then
		skill=MER_PROVOKE
		level=5
		sp=8
	end
	return skill,level,sp,duration 
end

function GetSacrificeSkill(myid)
	merctype = GetV(V_MERTYPE,myid)	
	local skill = 0
	local level = 0
	local sp = 25
	local duration = 0
	if (IsHomun(myid)==1) then
		skill=0
	elseif (merctype==13) then
		skill=ML_DEVOTION
		level=1
		duration=30000
	elseif (merctype==17) then
		skill=ML_DEVOTION
		level=1
		duration=30000
	elseif (merctype==20) then
		skill=ML_DEVOTION
		level=3
		duration=60000
	end
	return skill,level,sp,duration
end

function GetMobSkill(myid)
	merctype = GetV(V_MERTYPE,myid)
	local skill = 0
	local level = 0
	local sp = 0
	local target = 1
	local delay = 0
	if (IsHomun(myid)==1) then
		skill=0
	elseif (merctype==2) then
		skill=MA_SHOWER
		level=2
		sp=15
		target = 2
		delay=1000
	elseif (merctype==7) then
		skill=MA_SHOWER
		level=10
		sp=15
		target = 2
		delay=1000
	elseif (merctype==10) then
		skill=MA_SHARPSHOOTING
		level=5
		sp=30
	elseif (merctype==12) then
		skill=ML_BRANDISH
		level=2
		sp=12
		delay=1000
	elseif (merctype==16) then
		skill=ML_BRANDISH
		level=5
		sp=12
		delay=1000
	elseif (merctype==19) then
		skill=ML_BRANDISH
		level=10
		sp=12
		delay=1000
	elseif (merctype==22) then
		skill=MS_MAGNUM
		level=3
		sp=30
		target=0
	elseif (merctype==24) then
		skill=MS_MAGNUM
		level=5
		sp=30
		target=0
	elseif (merctype==28) then
		skill=MS_BOWLINGBASH
		level=5
		sp=17
	elseif (merctype==29) then
		skill=MS_BOWLINGBASH
		level=8
		sp=20
	elseif (merctype==30) then
		skill=MS_BOWLINGBASH
		level=10
		sp=22
	end
	return skill,level,sp,target,delay
end


function	GetQuickenSkill(myid)
	merctype = GetV(V_MERTYPE,myid)	
	local level = 0
	local skill = 0
	local sp = 0
	local duration = 0
	if (IsHomun(myid)==1) then
		homuntype=modulo(GetV(V_HOMUNTYPE,myid),4)
		if (homuntype==1) then -- It's a lif!
			skill=HLIF_AVOID
			if (LifEscapeLevel==nil) then
				level=5
			else
				level=LifEscapeLevel
			end
			duration = 35000+5000*level
			sp = 15+5*level
		elseif	(homuntype==3) then -- It's a filer!
			skill=HFLI_FLEET
			if (LifEscapeLevel==nil) then
				level=5
			else
				level=FilerFlitLevel
			end
			duration = 60000-level*5000
			sp =20+10*level
		end
	else
		if (merctype==3) then
			level=1
		elseif (merctype==8) then
			level=2
		elseif (merctype==10) then
			level=5
		elseif (merctype==23) then
			level=1
		elseif (merctype==26) then
			level=5
		elseif (merctype==28) then
			level=10
		elseif (merctype==30) then
			level=10
		elseif (merctype==16) then
			level=2
		elseif (merctype==20) then
			level=5
		end
		if (level ~= 0) then
			skill=MER_QUICKEN -- Can't just put this in all the time, need to return skill id 0 if the merc doesnt have quicken.
			sp=10+4*level
			duration = level * 30000
		end
	end
	return skill,level,sp,duration
end

function	GetGuardSkill(myid)
	merctype = GetV(V_MERTYPE,myid)	
	local level = 0
	local skill = 0
	local duration = 300000
	local sp = 0
	if (IsHomun(myid)==1) then
		homuntype=modulo(GetV(V_HOMUNTYPE,myid),4)
		if (homuntype==2) then -- It's an amistr!
			skill=HAMI_DEFENCE
			if (AmiBulwarkLevel==nil) then
				level=5
			else
				level=AmiBulwarkLevel
			end
			duration = 45000+5000*level
			sp = 15+5*level
		end
	else
		if (merctype==15) then
			level=3	
		elseif (merctype==19) then
			level=7
		elseif (merctype==20) then
			level=10
		end
		if (level ~= 0) then
			sp=10+2*level
			skill=ML_AUTOGUARD
		elseif (merctype==28) then
			level=4
			skill=MS_PARRYING
			sp=50
			duration=30000
		end
		--In practice, one should consider turning parrying off for the level 8 sword mercenary.
	end
	return skill,level,sp,duration
end

function GetTargetMode(s)
	targetmode=1 --Assume it's target targeted
	if (s==MS_MAGNUM) then
		targetmode=0 --Self targeted
	elseif (s==MS_BOWLINGBASH or s==MA_SHOWER or s==MA_LANDMINE or s==MA_SKIDTRAP or s==MA_FREEZINGTRAP or s==MA_SANDMAN) then
		targetmode=2 --Ground targeted
	end
	return targetmode
end


function GetTargetedSkills(myid)
	s,l,sp,t,d=GetAtkSkill(myid)
	Mainatk={MAIN_ATK,s,l,sp,t,d}
	s,l,sp,t,d=GetMobSkill(myid)
	Mobatk={MOB_ATK,s,l,sp,t,d}
	s,l,sp,t,d=GetDebuffSkill(myid)
	Debuffatk={DEBUFF_ATK,s,l,sp,t,d}
	result={Mainatk,Mobatk,Debuffatk}
	return result
end
--#######################
--### Other Functions ###
--#######################

function KiteOK(myid)
	mertype=GetV(V_MERTYPE,myid)
	if (mertype==nil) then
		homuntype=modulo(GetV(V_HOMUNTYPE,myid),4)
		if ((homuntype==0 or homuntype==3 )and DoNotChase==1) then
			return 1
		else
			return 0
		end
	elseif (mertype < 11) then
		return 1
	else
		return 0
	end
end

function DoSkill(skill,level,target)
	targetmode=GetTargetMode(skill)
	if targetmode==0 then
		SkillObject(MyID,level,skill,MyID)
	elseif targetmode==1 then
		SkillObject(MyID,level,skill,target)
	elseif targetmode==2 then
		x,y=GetV(V_POSITION,target)
		SkillGround(MyID,level,skill,x,y)
	end
	return
end


-- I SHOULDNT HAVE TO CODE THIS!
function modulo(a,b)
	return a-math.floor(a/b)*b
end
-- OR THIS!
function len(listin)
	local length=0
	for k,v in pairs(listin) do
		length = length + 1
	end
	return length
end
--------------------------------------------
-- List utility
--------------------------------------------
List = {}

function List.new ()
	return { first = 0, last = -1}
end

function List.pushleft (list, value)
	local first = list.first-1
	list.first  = first
	list[first] = value;
end

function List.pushright (list, value)
	local last = list.last + 1
	list.last = last
	list[last] = value
end

function List.popleft (list)
	local first = list.first
	if first > list.last then 
		return nil
	end
	local value = list[first]
	list[first] = nil         -- to allow garbage collection
	list.first = first+1
	return value
end

function List.popright (list)
	local last = list.last
	if list.first > last then
		return nil
	end
	local value = list[last]
	list[last] = nil
	list.last = last-1
	return value 
end

function List.clear (list)
	for i,v in ipairs(list) do
		list[i] = nil
	end
--[[
	if List.size(list) == 0 then
		return
	end
	local first = list.first
	local last  = list.last
	for i=first, last do
		list[i] = nil
	end
--]]
	list.first = 0
	list.last = -1
end

function List.size (list)
	local size = list.last - list.first + 1
	return size
end

