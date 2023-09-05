Log_Trace	= ""
Log_Error	= ""
Log_Output	= ""

function LogTrace(entry)
	if (entry==nil) then
		LogError("Error: Attempt to log nil value to Log_Trace")
	else
		Log_Trace = Log_Trace..entry.."\n"
	end
end

function LogTrace_2(entry)
	if (entry==nil) then
		LogError("Error: Attempt to log nil value to Log_Trace")
	else
		Log_Trace = Log_Trace..GetTick().."|"..GetStateName(MyState).."| "..entry.."\n"
	end
end

function GetStateName(state) 
	if(state==0) then
		result = "IDLE    "
	elseif (state == 1) then
		result = "FOLLOW  "
	elseif (state == 2) then
		result = "CHASE   "
	elseif (state == 3) then
		result = "ATTACK  "
	elseif (state == 4) then
		result = "MOVE CMD"
	elseif (state == 5) then
		result = "STOP CMD"
	elseif (state == 6) then
		result = "ATK OBJC"
	elseif (state == 7) then
		result = "ATK AREA"
	elseif (state == 8) then
		result = "PATROL C"
	elseif (state == 9) then
		result = "HOLD CMD"
	elseif (state == 10) then
		result = "SKILLOBJ"
	elseif (state == 11) then
		result = "SKILLARE"
	elseif (state == 12) then
		result = "STANDBY "
	elseif (state == 100) then
		result = "RANDWALK"
	elseif (state == 101) then
		result = "ORBTWALK"
	elseif (state == 102) then
		result = "REST    "
	elseif (state == 103) then
		result = "TANKCHAS"
	elseif (state == 104) then
		result = "TANK    "
	else
		result = "NO STATE"
	end
	return result
end

function LogError(entry)
	if (entry==nil) then
		LogError("Error: Attempt to log nil value to Log_Error")
	else
		Log_Error = Log_Error..entry.."\n"
	end
end

function LogOutput(entry)
	if (entry==nil) then
		LogError("Error: Attempt to log nil value to Log_Output")
	else
		Log_Output = Log_Output..entry.."\n"
	end
end

function WriteLogError()
	if (Log_Error ~= "" and Log_Error ~= nil) then
		ErrorLog=io.open("./Error.txt", "a+")
		ErrorLog:write(Log_Error)
		ErrorLog:close()
	end
	Log_Error=""
end

function WriteLogTrace()
	if (Log_Trace ~= "" and Log_Trace ~= nil) then
		TraceLog=io.open("./Trace.txt", "a+")
		TraceLog:write(Log_Trace)
		TraceLog:close()
	end
	Log_Trace=""
end

function WriteLogOutput()
	if (Log_Output ~= "" and Log_Output ~= nil) then
		OutputLog=io.open("./Output.txt", "a+")
		OutputLog:write(Log_Output)
		OutputLog:close()
	end
	Log_Output=""
end