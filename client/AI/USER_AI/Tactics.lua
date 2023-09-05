-----------------------------------
--This file contains functions related to the tactics system. 
--This will be expanded as the tactics system is completed. 
-----------------------------------
--Current version 1.27
--Written by Dr. Azzy of iRO Loki
-----------------------------------



function 	GetTact(t,m)
	if (IsPlayer(m)==1) then
		if (PVPmode~=0) then
			return GetPVPTact(t,m)
		else
			return 0
		end
	end
	local e
	if (IsHomun(MyID)==0) then 
		if (MobID[m]==nil) then
			e=GetClass(m)
		else
			e=MobID[m]
		end
	else
		e=GetV(V_HOMUNTYPE,m)
	end
	--TraceAI("TL on mob "..t.." of type "..e)
	if (MyTact[e]==nil) then
		x=MyTact[0][t]
	elseif (MyTact[e][t]==nil) then
		x=MyTact[0][t]
	else
		x=MyTact[e][t]
	end
	if (x==nil) then
		TraceAI("###########WARNING###########")
		TraceAI("Default tactic "..t.." is undefined!")
		TraceAI("Please review default tactics in H_Tactics.lua or M_Tactics.lua")
		TraceAI("and correct the default tactics line starting in MyTact[0]= ")
		TraceAI("AI Behavior should be expected to be broken until this is resolved")
		return 0
	else
		return x
	end
end


function	GetPVPTact(t,m)
	local e = ENEMY
	if IsMonster(e)==0 then
		e= ALLY
	end
	if (MyPVPTact[m]~=nil) then
		e = m
	elseif (MyFriends[m]~=nil) then
		e = MyFriends[m]
	end
	if (MyPVPTact[e]==nil) then
		x=MyPVPTact[0][t]
	elseif (MyPVPTact[e][t]==nil) then
		x=MyPVPTact[0][t]
	else
		x=MyPVPTact[e][t]
	end
	if (x==nil) then
		TraceAI("###########WARNING###########")
		TraceAI("Default PVP tactic "..t.." is undefined!")
		TraceAI("Please review default tactics in your PVP Tactics")
		TraceAI("and correct the default tactics line starting in MyPVPTact[NEUTRAL]= ")
		TraceAI("AI Behavior should be expected to be broken until this is resolved")
		return 0
	else
		
	--TraceAI("TL on P "..m.." type "..e.."for tactic "..t.." returning "..x)
		return x
	end
end

function	GetClass(m)
	if (m < 42000) then
		return 10
	else
		return 0
	end
end