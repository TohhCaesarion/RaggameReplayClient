---------------------------
--This file contains constants used by the tactics system
---------------------------
--Current version 1.21
--Written by Dr. Azzy of iRO Loki
---------------------------

---------------------------
--Constants (used in GetTact() calls)
---------------------------
TACT_BASIC	= 1
TACT_SKILL	= 2
TACT_KITE	= 3
TACT_CAST	= 4 --Assume casts are offencive?
TACT_PUSHBACK	= 5
TACT_DEBUFF	= 6
TACT_SIZE	= 7
TACT_RESCUE	= 8
TACT_FFA	= 9

---------------------------
--Tactics (responce to monster)
---------------------------
TACT_TANK	= -1
TACT_IGNORE	= 0	-- Do not attack the monster 
TACT_ATTACK_L	= 2	----
TACT_ATTACK_M	= 3	--Attack when HP > AggroHP
TACT_ATTACK_H	= 4	----
TACT_REACT_L	= 5	----
TACT_REACT_M	= 6	--Defend when attacked only
TACT_REACT_H	= 7	----
TACT_REACT_SELF = 9	--React only when attacked, not when owner attacked.
TACT_SNIPE_L	=10	-- sniping tactics
TACT_SNIPE_M	=11	-- use skill once	
TACT_SNIPE_H	=12	-- while attacking other monsters, otherwise as TACT_ATTACK


---------------------------
--Tactics (skill use)
--In tact lists, put another number in this field 
--to specify the number of skills it will use.
--if negative, will use skill of this LEVEL, only ONCE.
---------------------------

SKILL_NEVER	=0
SKILL_ALWAYS	=100

---------------------------
--Tactics (Kiting)
---------------------------

KITE_ALWAYS	= 2
KITE_REACT	= 1
KITE_NEVER	= 0

---------------------------
--Tactics (Cast react)
---------------------------

CAST_REACT	= 1
CAST_PASSIVE	= 0

---------------------------
--Tactics (Pushback)
---------------------------

PUSH_ALWAYS	= 2	--Deprecated
PUSH_FRIEND	= 2
PUSH_REACT	= 1	--Deprecated
PUSH_SELF	= 1
PUSH_NEVER	= 0

---------------------------
--Tactics (Debuffs)
---------------------------

DEBUFF_NEVER 	=0 -- To use Debuff skill, use the skill as the debuff field of the tactlist.

---------------------------
--Tactics (Size)
---------------------------

SIZE_UNDEFINED	=-1 -- default; behave as if size not known. 
SIZE_SMALL	=0
SIZE_MEDIUM	=1
SIZE_LARGE	=2


---------------------------
--Tactics (RESCUE)
---------------------------
RESCUE_NEVER =0
RESCUE_ALL = 1
RESCUE_RETAINER = 2
--
NOT_FFA=0
IS_FFA=1


---------------------------
-- PVP/Friend Crap
---------------------------

ALLY	= 13
KOS	= 12
ENEMY	= 11
NEUTRAL	= 10
RETAINER= 2
FRIEND	= 1

STRING_FRIENDNAMES={}
STRING_FRIENDNAMES[ALLY]="ALLY"
STRING_FRIENDNAMES[FRIEND]="FRIEND"
STRING_FRIENDNAMES[RETAINER]="RETAINER"
STRING_FRIENDNAMES[NEUTRAL]="NEUTRAL"
STRING_FRIENDNAMES[ENEMY]="ENEMY"
STRING_FRIENDNAMES[KOS]="KOS"


---------------------------
--Predefined tactics
--These are for backwards compatability only.
--They will crash the GUI if used.
---------------------------

TACTIC_IGNORE	= {TACT_REACT_L,SKILL_NEVER,KITE_NEVER,CAST_REACT,PUSH_NEVER,DEBUFF_NEVER,SIZE_UNDEFINED}
